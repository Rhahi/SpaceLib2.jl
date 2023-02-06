module SpaceLib2

using KRPC
import KRPC.Interface.SpaceCenter as SC
import KRPC.Interface.SpaceCenter.RemoteTypes as SCR
import KRPC.Interface.SpaceCenter.Helpers as SCH
import Base: close

include("time.jl")
include("spacecraft.jl")
include("spacecenter.jl")

export SpaceCenter

end # module SpaceLib2
