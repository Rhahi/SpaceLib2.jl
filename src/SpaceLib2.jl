module SpaceLib2

using ErrorTypes
using KRPC
import KRPC.Interface.SpaceCenter as SC
import KRPC.Interface.SpaceCenter.RemoteTypes as SCR
import KRPC.Interface.SpaceCenter.Helpers as SCH
import Base: close, show

include("errors.jl")
include("time.jl")
include("spacecraft.jl")
include("spacecenter.jl")

export SpaceCenter, Spacecraft, ControlChannels, Timeserver, SLError
export connect, ut_stream, ut_periodic_stream, delay, add_active_vessel!

end # module SpaceLib2
