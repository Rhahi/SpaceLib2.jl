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
