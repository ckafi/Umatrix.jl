# Copyright 2019 Tobias Frilling
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

module Umatrix

macro todo()
    :(error("not implemented"))
end

using DataIO
using CalculatedABC
using Distances
using Distributions
using JuliennedArrays
using Plots
using Random

const EsomWeights{T} = AbstractArray{T,3}

include("settings.jl")

include("coolDowns.jl")
include("esom.jl")
include("initMethod.jl")
include("matrices.jl")
include("neighbourhood.jl")
include("plotting.jl")
include("utils.jl")

end # module
