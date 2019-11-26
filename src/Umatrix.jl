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

const EsomWeights{T<:Real} = Array{T,3}

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
    result = mapslices(randcol, data, dims = 1)
    return reshape(result', (size(data,2), rows, columns)) |> collect
end

function bestMatch(dataPoint::Vector{<:Real}, weights::EsomWeights{<:Real})
    @assert size(dataPoint, 1) == size(weights, 1)
    dist = SqEuclidean()
    index_3d = mapslices(weight -> dist(weight, dataPoint), weights, dims=1) |> argmin
    return CartesianIndex(index_3d[2], index_3d[3])
end

function bestMatches(args...)
    @todo
end

@inline coolDown(method::Symbol, args...) = coolDown(Val(method), args...)

function coolDown(::Val{:linear}, (start, stop), steps)
    return step -> start - ((start - stop) / steps) * (step - 1)
end

function coolDown(::Val{:leadInOut}, (start, stop), steps; leadIn = 0.1, leadOut = 0.95)
    @assert leadIn < leadOut
    @assert leadOut - leadIn >= 0
    return step -> if (step/steps <= leadIn) start
                   elseif (step/steps >= leadOut) stop
                   else start - ((start - stop) / steps) * (step - 1)
                   end
end

function neighbourhoodOffsets(radius::T) where {T<:Real}
    @assert radius >= 0
    flipV(i) = CartesianIndex(-i[1], i[2])
    flipH(i) = CartesianIndex(i[1], -i[2])
    quad1 = [CartesianIndex(x,y) for x in 0:radius, y in 0:radius
             if ((x,y).^2 |> sum) <= radius^2]
    quad2 = flipV.(quad1)
    quad3 = flipH.(quad2)
    quad4 = flipV.(quad3)
    return vcat(quad1,quad2,quad3,quad4) |> unique
end

function neighbourhoodFromOffsets(index::CartesianIndex{2}, offsets::Vector{CartesianIndex{2}},
                                  settings = defaultSettings)
    @unpack toroid, rows, columns
    neighbourhood = map(i -> i + index, offsets)
    if toroid
        mod_replace_zero(x,y) = if (m = mod(x,y)) == 0 y else m end
        neighbourhood = map(i -> CartesianIndex(mod_replace_zero.(i.I,(rows,columns))), neighbourhood)
    else
        neighbourhood = filter(i -> 1 <= i.I[1] <= rows && 1 <= i.I[2] <= columns, neighbourhood)
    end
    return unique(neighbourhood)
end

@inline neighbourhoodKernel(kernel::Symbol) = neighbourhoodKernel(Val(kernel))

function neighbourhoodKernel(::Val{:cone})
    (dist, radius) -> (radius - dist)/radius
end

function neighbourhoodKernel(::Val{:gauss})
    (dist, radius) -> exp(-(dist/radius)^2/2)
end

function neighbourhoodKernel(::Val{:mexhat})
    (dist,radius) -> begin
        square = (dist/radius)^2
        (1 - square) * exp(-square/2)
    end
end

function esomTrainWeights!(dataPoint::Vector{<:Real}, weights::EsomWeights{<:Real},
                           radius::Real, learningRate::Float64, settings = defaultSettings)
    offsets = neighbourhoodOffsets(radius)
    dist(x,y) = (x,y).^2 |> sum |> sqrt
    distances = map(i -> dist(i.I...), offsets)
    bm_index = bestMatch(dataPoint, weights)
    neighbourhood = neighbourhoodFromOffsets(bm_index, offsets, settings)
    kernel = neighbourhoodKernel(:mexhat)
    for i in 1:size(neighbourhood, 1)
        index = neighbourhood[i]
        weights[:,index] +=  learningRate * kernel(distances[i], radius) * (dataPoint - weights[:,index]);
    end
end

function esomTrainOnline(data::Matrix{<:Real}, weights::EsomWeights{<:Real}, settings = defaultSettings)
    @assert size(data, 2) == size(weights, 2)
    s = settings
    coolDownRadius = coolDown(s.radiusCooling, s.radius, s.epochs)
    coolDownLearningrate = coolDown(s.learningRateCooling, s.learningRate, e.epochs)

    for i in 1:s.epochs
        data_view = view(data, randperm(size(data, 1)), :)
        radius = coolDownRadius(i)
        learningRate = coolDownLearningrate(i)
        println("Epoch $(i) started.")
        for dataPoint in eachrow(data_view)
            weights = esomTrainWeights!(dataPoint, weights, radius, learningRate, settings)
        end
    end

    println("---- Esom Training Finished ----")
    return weights
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

function esomTrain(data::Matrix{<:Real}, key = 1:size(data,1), settings = defaultSettings;
                   shiftToHighestDensity = false) # shift normally true
    @assert size(data, 2) == size(key, 1)
    grid = esomInit(data, settings)
    weights = esomTrainOnline(data, grid, settings)
    if shiftToHighestDensity && settings.toroid
        println("Shift to point of highest density")
        radius = filter(!iszero, pairwise(Euclidean(), data, dims=1)) |> mean
        pmatrix = pmatrixForEsom(data, weights, radius, settings)
        pos = findall(isequal(maximum(pmatrix)), pmatrix)[1]
        weights = shiftedNeurons(weights, -pos[1], -pos[2], settings)
    end
    projection = bestMatches(data, weights, settings)
    umatrix = umatrixForEsom(weights, settings)
    return projection, weights, umatrix
end

end # module
