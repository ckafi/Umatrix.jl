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

"""
    esomTrain(data::AbstractMatrix{Float64})

Train an ESOM for the given data set.

Uses on-line learning per default. (Batch is not yet implemented)
"""
function esomTrain(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)
    return esomTrainOnline(data, settings)
end


"""
    esomTrainOnline(data::AbstractMatrix{Float64})

Train an ESOM on-line for the given data set.
"""
function esomTrainOnline(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)
    weights = esomInit(data, settings)
    return esomTrainOnline!(data, weights, settings)
end


"""
    esomTrainOnline!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64})

Train the ESOM weights on-line for the given data set.

This function mutates `weights`
"""
function esomTrainOnline!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                         settings::Settings = defaultSettings)
    @assert size(data, 2) == size(weights, 1)
    s = settings
    coolDownRadius = coolDown(s.radiusCooling, s.radius, s.epochs)
    coolDownLearningrate = coolDown(s.learningRateCooling, s.learningRate, s.epochs)
    for i in 1:s.epochs
        radius = coolDownRadius(i)
        learningRate = coolDownLearningrate(i)
        esomTrainEpoch!(data, weights, radius, learningRate, settings)
    end
    if settings.shiftToHighestDensity && settings.toroid
        weights = shiftToHighestDensity(data, weights)
    end
    return weights
end


"""
    esomInit(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)

Initilize an ESOM with values based on `settings.initMethod`.
"""
function esomInit(data::AbstractMatrix{Float64}, settings::Settings = defaultSettings)
    f = initMethod(settings)
    result::Matrix{Float64} = hcat(f.(Slices(data, 1))...)
    return reshape(permutedims(result), (size(data,2), settings.latticeSize...))
end


"""
    esomTrainEpoch!(data, weights, radius, learningRate)

Train the ESOM for a single epoch.

This function mutates `weights`
"""
function esomTrainEpoch!(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                         radius::Float64, learningRate::Float64,
                         settings::Settings = defaultSettings)
    data_view = view(data, randperm(size(data, 1)), :)
    for dataPoint in eachrow(data_view)
        esomTrainStep!(dataPoint, weights, radius, learningRate, settings)
    end
    return weights
end


"""
    esomTrainStep!(dataPoint, weights, radius, learningRate)

Train the ESOM with a single data point.

This function mutates `weights`
"""
function esomTrainStep!(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64},
                        radius::Float64, learningRate::Float64,
                        settings::Settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    bestMatch_index = bestMatch(dataPoint, weights, settings)
    neighbours = neighbourhood(bestMatch_index, radius, settings)
    kernel = neighbourhoodKernel(settings.neighbourhoodKernel, radius)
    distances = map(i -> latticeDistance(i, bestMatch_index, settings), neighbours)
    weights[:,neighbours] += (learningRate .* kernel.(distances))' .*
                             (dataPoint .- weights[:, neighbours])
    return weights
end


"""
    projection(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64})

Generate a projection from each data point to the best matching ESOM neuron.
"""
function projection(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                    settings::Settings = defaultSettings;
                    key::AbstractVector{Int} = 1:size(data,1))
    @assert length(key) == size(data, 1)
    @assert allunique(key)
    @assert all(i -> 1 <= i <= size(data, 1), key)
    return (i -> i => bestMatch(data[i,:], weights)).(key) |> Dict
end


# compatability with DataIO.LRNData
function projection(data::LRNData, args...; kwargs...)
    projection(data.data, args...; key=data.key, kwargs...)
end


"""
    bestMatch(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64})

Search for the best matching ESOM neuron for the given data point.
"""
function bestMatch(dataPoint::AbstractVector{Float64}, weights::EsomWeights{Float64},
                   settings::Settings = defaultSettings)
    @assert size(dataPoint, 1) == size(weights, 1)
    dist = settings.distance
    slice = Slices(weights, 1)
    index::CartesianIndex{2} = _findmin(weight -> dist(weight, dataPoint), slice)[2]
    return index
end


"""
    shiftWeights(weights::EsomWeights{Float64}, pos::CartesianIndex{2})

Shift the ESOM so the given `pos` is in the middle.

This makes only sense for a toroidal map.
"""
function shiftWeights(weights::EsomWeights{Float64}, pos::CartesianIndex{2},
                      settings::Settings = defaultSettings)
    # since the plot shos the matrix four times, the midpoint of the plot is
    # equal to the latticeSize
    offset = CartesianIndex(settings.latticeSize...) - pos
    indices = CartesianIndices(Slices(weights, 1))
    new_indices = (indices .- offset)[:]
    new_indices = wrapCoordsOnToroid(new_indices)
    result = similar(weights)
    for (old, new) in zip(indices, new_indices)
        result[:,new] = weights[:,old]
    end
    return result
end


"""
    shiftToHighestDensity(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64})

Shift the ESOM so the point of highest density is centered.
"""
function shiftToHighestDensity(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                               settings = defaultSettings)
    if !settings.toroid return weights end
    radius = filter(!iszero, pairwise(Euclidean(), data, dims=1)) |> mean
    p = pmatrix(data, weights, settings, radius = radius)
    pos = findfirst(isequal(maximum(p)), p)
    return shiftWeights(weights, pos, settings)
end


# compatability with DataIO.LRNData
for f in (:esomTrain, :esomTrainOnline, :esomTrainOnline!, :esomInit,
          :shiftToHighestDensity)
    @eval @inline ($f)(data::LRNData, args...; kwargs...) = ($f)(data.data, args...; kwargs...)
end
