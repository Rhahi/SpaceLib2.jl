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

function Base.close(sp::Spacecraft)
    for fname in fieldnames(typeof(sp))
        close(getfield(sp, fname))
    end
    close(sp.ts)
end
