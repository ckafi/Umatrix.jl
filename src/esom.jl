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


function esomTrain(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)
    return esomTrainOnline(data, settings)
end

function esomTrainOnline(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)
    weights = esomInit(data, settings)
    return esomTrainOnline!(data, weights, settings)
end

function esomTrainOnline!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                         settings::Settings = defaultSettings)
    @assert size(data, 2) == size(weights, 1)
    s = settings
    coolDownRadius = coolDown(s.radiusCooling, s.radius, s.epochs)
    coolDownLearningrate = coolDown(s.learningRateCooling, s.learningRate, s.epochs)
    for i in 1:s.epochs
        println("Epoch $(i) started")
        radius = coolDownRadius(i)
        learningRate = coolDownLearningrate(i)
        esomTrainEpoch!(data, weights, radius, learningRate, settings)
    end
    println("---- Esom Training Finished ----")
    return weights
end

function esomInit(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)
    f = initMethod(settings)
    result::Matrix{Float64} = hcat(f.(Slices(data, 1))...)
    return reshape(permutedims(result), (size(data,2), settings.latticeSize...))
end

function esomTrainEpoch!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                         radius::Float64, learningRate::Float64,
                         settings::Settings = defaultSettings)
    data_view = view(data, randperm(size(data, 1)), :)
    for dataPoint in eachrow(data_view)
        esomTrainStep!(dataPoint, weights, radius, learningRate, settings)
    end
    return weights
end

function esomTrainStep!(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64},
                        radius::Float64, learningRate::Float64,
                        settings::Settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    bestMatch_index = bestMatch(dataPoint, weights, settings)
    neighbours = neighbourhood(bestMatch_index, radius, settings)
    kernel = neighbourhoodKernel(settings.neighbourhoodKernel)
    dist(i) = latticeDistance(i, bestMatch_index, settings)
    for i in 1:size(neighbours, 1)
        index = neighbours[i]
        distance = dist(neighbours[i])
        weights[:,index] +=  learningRate * kernel(distance, radius) *
                             (dataPoint - weights[:,index])
    end
    return weights
end

function projection(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                    settings::Settings = defaultSettings;
                    key::AbstractVector{Int} = 1:size(data,1))
    @assert length(key) == size(data, 1)
    @assert allunique(key)
    @assert all(i -> 1 <= i <= size(data, 1), key)
    f(i) = i => bestMatch(data[i,:], weights)
    f.(key) |> Dict
end

function projection(data::LRNData, args...; kwargs...)
    projection(data.data, args...; key=data.key, kwargs...)
end

function bestMatch(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64},
                   settings::Settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    dist = settings.distance
    slice = Slices(weights, 1)
    index = _findmin(weight -> dist(weight, dataPoint), slice)[2]
    return CartesianIndex(index)
end

for f in (:esomTrain, :esomTrainOnline, :esomTrainOnline!, :esomInit)
    @eval @inline ($f)(data::LRNData, args...; kwargs...) = ($f)(data.data, args...; kwargs...)
end
