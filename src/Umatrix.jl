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

const EsomWeights{T<:Real} = AbstractArray{T,3}

include("Settings.jl")
include("coolDowns.jl")
include("neighbourhood.jl")

function esomInit(data::AbstractMatrix{<:Real}, settings = defaultSettings)
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
    result = mapslices(randcol, data, dims = 1)
    return reshape(result', (size(data,2), rows, columns))
end

function bestMatch(dataPoint::AbstractVector{<:Real}, weights::EsomWeights{<:Real})
    @assert size(dataPoint, 1) == size(weights, 1)
    dist = SqEuclidean()
    slice = Slices(weights, 1)
    index = map(weight -> dist(weight, dataPoint), slice) |> argmin
    return CartesianIndex(index)
end

function bestMatches(args...)
    @todo
end

function esomTrainWeights!(dataPoint::AbstractVector{<:Real}, weights::EsomWeights{<:Real},
                           radius::Real, learningRate::Float64, settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    offsets = neighbourhoodOffsets(radius)
    dist(x,y) = (x,y).^2 |> sum |> sqrt
    distances = map(i -> dist(i.I...), offsets)
    bm_index = bestMatch(dataPoint, weights)
    neighbourhood = neighbourhoodFromOffsets(bm_index, offsets, settings)
    kernel = neighbourhoodKernel(:mexhat)
    for i in 1:size(neighbourhood, 1)
        index = neighbourhood[i]
        weights[:,index] +=  learningRate * kernel(distances[i], radius) *
                             (dataPoint - weights[:,index]);
    end
end

function esomTrainOnline!(data::AbstractMatrix{<:Real}, weights::EsomWeights{<:Real},
                         settings = defaultSettings)
    @assert size(data, 2) == size(weights, 1)
    s = settings
    coolDownRadius = coolDown(s.radiusCooling, s.radius, s.epochs)
    coolDownLearningrate = coolDown(s.learningRateCooling, s.learningRate, s.epochs)

    for i in 1:s.epochs
        data_view = view(data, randperm(size(data, 1)), :)
        radius = coolDownRadius(i)
        learningRate = coolDownLearningrate(i)
        println("Epoch $(i) started.")
        for dataPoint in eachrow(data_view)
            esomTrainWeights!(dataPoint, weights, radius, learningRate, settings)
        end
    end

    println("---- Esom Training Finished ----")
end

function umatrixForEsom(args...)
    @todo
end

function pmatrixForEsom(args...)
    @todo
end

function shiftedNeurons(args...)
    @todo
end

function shiftToHighestDensity(data::AbstractMatrix{<:Real}, weights::EsomWeights{<:Real},
                               settings = defaultSettings)
    if !settings.toroid return weights end
    radius = filter(!iszero, pairwise(Euclidean(), data, dims=1)) |> mean
    pmatrix = pmatrixForEsom(data, weights, radius, settings)
    pos = findfirst(isequal(maximum(pmatrix)), pmatrix)
    weights = shiftedNeurons(weights, -pos[1], -pos[2], settings)
end

function esomTrain(data::AbstractMatrix{<:Real}, key = 1:size(data,1), settings = defaultSettings)
    @assert size(data, 2) == size(key, 1)
    weights = esomInit(data, settings)
    weights = esomTrainOnline(data, weights, settings)
    projection = bestMatches(data, weights, settings)
    umatrix = umatrixForEsom(weights, settings)
    return projection, weights, umatrix
end

end # module
