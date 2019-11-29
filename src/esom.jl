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


function esomTrain(data::AbstractMatrix{Float64}, settings = defaultSettings)
    return esomTrainOnline(data, settings)
end

function esomTrainOnline(data::AbstractMatrix{Float64}, settings = defaultSettings)
    weights = esomInit(data, settings)
    return esomTrainOnline!(data, weights, settings)
end

function esomInit(data::AbstractMatrix{Float64}, settings = defaultSettings)
    result = mapslices(initMethod(settings), data, dims = 1)
    return reshape(result', (size(data,2), settings.rows, settings.columns))
end

function esomTrainOnline!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                         settings = defaultSettings)
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

function esomTrainEpoch!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                         radius::Float64, learningRate::Float64, settings = defaultSettings)
    data_view = view(data, randperm(size(data, 1)), :)
    for dataPoint in eachrow(data_view)
        esomTrainStep!(dataPoint, weights, radius, learningRate, settings)
    end
    return weights
end

function esomTrainStep!(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64},
                        radius::Float64, learningRate::Float64, settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    offsets = neighbourhoodOffsets(radius)
    bestMatch_index = bestMatch(dataPoint, weights, settings)
    neighbourhood = neighbourhoodFromOffsets(bestMatch_index, offsets, settings)
    kernel = neighbourhoodKernel(settings.neighbourhoodKernel)
    dist(i) = sqrt(sum(i.I.^2))
    for i in 1:size(neighbourhood, 1)
        index = neighbourhood[i]
        distance = dist(offsets[i])
        weights[:,index] +=  learningRate * kernel(distance, radius) *
                             (dataPoint - weights[:,index]);
    end
end

function bestMatch(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64},
                   settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    dist = settings.distance
    slice = Slices(weights, 1)
    index = _findmin(weight -> dist(weight, dataPoint), slice)[2]
    return CartesianIndex(index)
end
