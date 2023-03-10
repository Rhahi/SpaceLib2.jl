"""
Shared spacecraft controls. This struct acts as a single access point for
spacecraft control. Note that this struct does not specify which reference
frame the vectors use - it should be defined in the control loop.

**fields**
- `engage` -- toggles autopilot or manual control
- `throttle` -- throttle value of the spacecraft between 0 and 1. May not have
    an effect if the engine does not support throttling.
- `roll` -- desired roll for the spacecraft.
- `direction` -- desired vector for the spacecraft to point at.
- `rcs` -- desired RCS input between -1 and 1, in three directions.
"""
struct ControlChannels
    engage::Channel{Bool}
    throttle::Channel{Float32}
    roll::Channel{Float32}
    direction::Channel{NTuple{3, Float64}}
    rcs::Channel{NTuple{3, Float64}}
    function ControlChannels()
        e = Channel{Bool}(1)
        t = Channel{Float32}(1)
        r = Channel{Float32}(1)
        d = Channel{NTuple{3, Float64}}(1)
        rcs = Channel{NTuple{3, Float64}}(1)
        new(e, t, r, d, rcs)
    end
end

function Base.close(contch::ControlChannels)
    close(contch.engage)
    close(contch.throttle)
    close(contch.roll)
    close(contch.direction)
    close(contch.rcs)
end

"""
Spacecraft to be controlled.

**fields**
- `name` -- Cached name of the spacecraft. Can be used for namespacing logs.
- `ves` -- KRPC Vessel. Most control actions act on this object.
- `parts` -- Cached dictionary of spacecraft's parts. Since many parts have
    names not seen on the VAB, saving the values here saves trouble travering
    the part tree.
- `events` -- A directory for global function synchronization.
    May be removed later.
- `contch` -- A set of global control input channels for the spacecraft.
- `ts` -- MET timeserver to access vehicle's specific mission elapsed time.
    Useful for resuming mission from save, as MET is not volatile.
"""
struct Spacecraft
    name::String
    ves::SCR.Vessel
    parts::Dict{Symbol, SCR.Part}
    events::Dict{Symbol, Condition}
    contch::ControlChannels
    ts::Timeserver
end

function Spacecraft(conn::KRPC.KRPCConnection, ves::SCR.Vessel;
    name = nothing,
    parts = Dict{Symbol, SCR.Part}(),
    events = Dict{Symbol, Condition}(),
    contch = ControlChannels(),
    ts = nothing,
)
    name = isnothing(name) ? SCH.Name(ves) : name
    ts = isnothing(ts) ? Timeserver(conn, ves) : ts
    @async begin
        try
            # if time server closes or gets stop signal,
            # the spacecraft will no longer be controllable.
            wait(ts.clients[1])
        finally
            # close the control channels.
            @warn "Spacecraft $name has been shut down." _group=:system ts=ts.clients[1]
            close(contch)
        end
    end
    Spacecraft(name, ves, parts, events, contch, ts)
end

function Base.close(sp::Spacecraft)
    close(sp.contch)
    close(sp.ts)
end

function Base.show(io::IO, sp::Spacecraft)
    name = nothing
    try
        name = SCH.Name(sp.ves)
        print(io, name)
    catch
        print(io, "Unknown spacecraft")
    end
    print(io, " ($(sp.ts.time))")
end
