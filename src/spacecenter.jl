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
    sc::SCR.SpaceCenter
    ts::Timeserver
    crafts::Array{Spacecraft, 1}
end

function SpaceCenter(name::String, host::String, port::Integer, stream_port::Integer)
    conn = kerbal_connect(name, host, port, stream_port)
    crafts = Array{Spacecraft, 1}()
    return SpaceCenter(conn, SCR.SpaceCenter(conn), Timeserver(conn), crafts)
end
