@enum SLError::UInt8 IOError KRPCError OtherError

"""
    @sort_krpc_error(e)

Given an error in a `catch` block, return an item belonging to SLError.
This macro is used to catch all KRPC-produced errors to act on them.
KRPC errors can be recoverable (bad methods used) or irrecoverable (EOF).

# Example
```
try
    ves = SCH.ActiveVessel(sc.center)
    return Ok(ves)
catch e
    @error "Error while connecting" exception=(e, catch_backtrace()) _group=:conn
    Err(@sort_krpc_error e)
end
```
"""
macro sort_krpc_error(err)
    quote
        e = $err
        e isa Base.IOError && return IOError
        e isa KRPC.KRPCError && return KRPCError
        @warn "Unsorted KRPC error" exception=e
        return OtherError
    end
end
