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

using Distances
using Distributions
using JuliennedArrays
using Random

const EsomWeights{T} = AbstractArray{T,3}

include("utils.jl")
include("settings.jl")
include("initMethod.jl")
include("coolDowns.jl")
include("neighbourhood.jl")
include("esom.jl")

function umatrixForEsom(weights::EsomWeights{Float64}, settings = defaultSettings)
    (_, k, m) = size(weights)
    result = Array{Float64, 2}(undef, k, m)
    for index in CartesianIndices((k,m))
        weight = weights[:,index]
        neighbours = directNeighbours(index, settings)
        dist(w) = settings.distance(w, weight)
        result[index] = mean(map(dist, Slices(weights[:,neighbours], 1)))
    end
    result
end

function pmatrixForEsom(args...)
    @todo
end

function shiftedNeurons(args...)
    @todo
end

function shiftToHighestDensity(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                               settings = defaultSettings)
    if !settings.toroid return weights end
    radius = filter(!iszero, pairwise(Euclidean(), data, dims=1)) |> mean
    pmatrix = pmatrixForEsom(data, weights, radius, settings)
    pos = findfirst(isequal(maximum(pmatrix)), pmatrix)
    weights = shiftedNeurons(weights, -pos[1], -pos[2], settings)
end

end # module
