# A base for KRPC connection and spacecenter managements.

"""
Represents connection to KRPC. Should persist while the game is running.

**fields**
- `conn` -- a KRPC.KRPCConnection object for talking to KSP.
- `time` -- a time server that will provide updated in-game universal time.
- `crafts` -- a list of Spacecrafts to be controlled.
"""
struct SpaceCenter
    conn::KRPC.KRPCConnection
    center::SCR.SpaceCenter
    ts::Timeserver
    crafts::Array{Spacecraft, 1}
end

function SpaceCenter(name::String, host::String, port::Integer, stream_port::Integer)
    conn = kerbal_connect(name, host, port, stream_port)
    crafts = Array{Spacecraft, 1}()
    return SpaceCenter(conn, SCR.SpaceCenter(conn), Timeserver(conn), crafts)
end

function Base.show(io::IO, sc::SpaceCenter)
    status = isopen(sc.conn.conn) ? "open" : "closed"
    print(io, "SpaceCenter ($status)")
    for sp in sc.crafts
        print(io, "\n  - $sp")
    end
end

function Base.close(sc::SpaceCenter)
    close(sc.ts)
    close(sc.conn.conn)
end

@enum RPCError::UInt8 IOError OtherError

function connect(name="Julia", host="127.0.0.1", port=50000, stream_port=50001)::Result{SpaceCenter, RPCError}
    sc = nothing
    try
        sc = SpaceCenter(name, host, port, stream_port)
        return Ok(sc)
    catch e
        @error "Error while connecting to SpaceCenter" exception=(e, catch_backtrace()) _group=:conn
        isa(e, Base.IOError) && return Err(IOError)
        return Err(OtherError)
    end
end
