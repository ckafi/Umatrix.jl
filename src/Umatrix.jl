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
using Random

include("Settings.jl")

function bestMatch(dataPoint::Vector{<:Real}, weights::Matrix{<:Real})
    @assert size(dataPoint, 1) == size(weights, 2)
    dist(v1,v2) = (v1 .- v2).^2 |> sum
    return map(row -> dist(row, dataPoint), eachrow(weights)) |> argmin
end

function bestMatches(data::Matrix{<Real}, weights::Matrix{<:Real})
    @todo
end

function esomInit(data::Matrix{<:Real}, settings = defaultSettings)
    @unpack rows, columns, init_method
    randcol = if init_method == :uniform_min_max
                  col -> rand(Uniform(minimum(col), maximum(col)), rows * columns)
              elseif init_method == :uniform_mean_std
                  col -> rand(Uniform(mean(col), std(col)), rows * columns)
              elseif init_method == :normal_mean_std
                  col -> rand(Normal(mean(col), std(col)), rows * columns)
              elseif init_method == :zeros
                  col -> zeros(rows * columns)
              else
                  throw(ArgumentError("$(init_method) is not a valid initialization method"))
              end
    return mapslices(randcol, data, dims = 1)
end

function esomTrainOnline(data::Matrix{<:Real}, weights::Matrix{<:Real}, settings = defaultSettings)
    @assert size(data, 2) == size(weights, 2)
    @todo
end

function pmatrixForEsom(args...)
    @todo
end

function shiftedNeurons(args...)
    @todo
end

function esomTrain(data::Matrix{<:Real}, key = 1:size(data,1), settings = defaultSettings;
                   shiftToHighestDensity = false)
    @todo
    @assert size(data, 2) == size(key, 1)
    grid = esomInit(data, settings)
    weights = esomTrainOnline(data, grid, settings)
    if shiftToHighestDensity && settings.toroid
        println("Shift to point of highest density")
        radius = filter(!iszero, pairwise(Euclidean(), data, dims=1)) |> mean
        pmatrix = pmatrixForEsom(data, weights, radius, settings)
        pos = findall(isequal(maximum(pmatrix)), pmatrix)[1]
        weights = shiftedNeurons(Weights, Lines, Columns, -pos[1], -pos[2])
    end
    projection = bestMatches(data, weights, settings.columns)
    umatrix = umatrixForEsom(weights, settings)
    return projection, weights, umatrix
end

end # module
