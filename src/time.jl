"""
A universal time of the space center. The basis of time-based operations.
Maintain a list of clients that listens to the time server, acting as a caching
layer, so that a stream with KRPC does not have to made every sleep.

**fields**
- `ut` -- universal time in seconds.
- `clients` -- clients that are subscribed to the time server.
"""
mutable struct Timeserver
    time::Float64
    clients::Vector{Channel{Float64}} # the first client is a controller.
    function Timeserver(stream::Union{Channel{Tuple{Float64}}, KRPC.Listener})
        signal = Channel{Float64}(1)
        clients = Vector{Channel{Float64}}()
        push!(clients, signal)
        ts = new(-1, clients)
        start_time_server!(stream, ts)
    end
end

"Start timeserver using KRPC's universal time"
function Timeserver(conn::KRPC.KRPCConnection)
    stream = KRPC.add_stream(conn, (SC.get_UT(),))
    Timeserver(stream)
end

"Start timeserver using Vessel's internal mission time."
function Timeserver(ves::SCR.Vessel)
    stream = KRPC.add_stream(conn, (SC.get_MET(ves),))
    Timeserver(stream)
end

"Start a local time server for testing"
function Timeserver()
    stream = Channel{Tuple{Float64}}()
    @async begin
        try
            while true
                put!(stream, (time(),))
                sleep(0.005)
            end
        finally
            close(stream)
        end
    end
    Timeserver(stream)
end

Base.close(ts::Timeserver) = close(ts.clients)

"Fetch updated timestamp and publish it to clients"
function start_time_server!(ts::Timeserver, stream::Union{Channel{Tuple{Float64}}, KRPC.Listener})
    @async begin
        try
            running = true
            while running
                ts.ut, = take!(stream)
                index_offset = 0
                for (index, client) in enumerate(ts.clients)
                    if index == 0 && !isopen(client)
                        # control channel has been closed. Shutdown timeserver.
                        running = false
                        break
                    end
                    try
                        !isready(client) && put!(client, ts.ut)
                    catch e
                        # if a client is closed, we will get InvalidStateException.
                        # then remove the client from the list and proceed.
                        # otherwise, we have a different problem.
                        if !isa(e, InvalidStateException)
                            @error "Time server has crashed" ts.ut
                            error(e)
                        end
                        client = popat!(ts.clients, index - index_offset)
                        index_offset += 1
                        close(client)
                        @debug "Time channel closed."
                    end
                end
            end
        finally
            # this block will run if clients list itself has been closed.
            for client in ts.clients
                close(client)
            end
            close(stream)
        end
    end
end

"""
    ut_stream(ts::Timeserver)

Subscribe to the time server. To unsubscribe, close the returned channel.
"""
function ut_stream(ts::Timeserver)
    @debug "Time channel created"
    channel = Channel{Float64}(1)
    push!(ts.clients, channel)
    channel
end

"""
    ut_stream(f::Function, ts::Timeserver)

ut_stream that closes itself after `f` finishes.

```julia
ut_stream(ts) do chan
    while true
        now = take!(chan)
        # do something
    end
end

ut_stream(ts) do chan
    for now in chan
        # do something
        yield()
    end
end
```
"""
function ut_stream(f::Function, ts::Timeserver)
    channel = ut_stream(ts)
    try
        f(channel)
    finally
        close(channel)
    end
end

"""
    ut_periodic_stream(ts::Timeserver, period::Real)

ut_stream that updates time only periodically.
Useful for polling data periodically.
"""
function ut_periodic_stream(ts::Timeserver, period::Real)
    coarse_channel = Channel{Float64}(1)
    fine_channel = ut_stream(ts)
    last_update = 0.
    @async begin
        try
            for now in fine_channel
                if now - last_update > period
                    # skip sending if client hasn't received the time.
                    # this makes sure that every new time update is up to date
                    if !isready(coarse_channel)
                        put!(coarse_channel, now)
                        last_update = now
                    end
                end
            end
        finally
            close(fine_channel)
        end
    end
    coarse_channel
end

"""
    ut_periodic_stream(f::Function, ts::Timeserver, period::Real)

ut_stream that closes itself after `f` finishes.
"""
function ut_periodic_stream(f::Function, ts::Timeserver, period::Real)
    coarse_channel = ut_periodic_stream(ts, period)
    try
        f(coarse_channel)
    finally
        close(coarse_channel)
    end
end