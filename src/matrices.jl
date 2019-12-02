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

function umatrix(weights::EsomWeights{Float64}, settings::Settings = defaultSettings)
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

function pmatrix(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                 settings::Settings = defaultSettings;
                 radius::Union{Real, Nothing} = nothing)
    @assert size(data, 2) == size(weights, 1)

    if radius == nothing
        # described in 'Visualization and 3D Printing of Multivariate Data of
        # Biomarkers', Thrun et al., 2016a
        # produces rather flat maps, may chose a different algo?
        distances = begin
            d = pairwise(settings.distance, data, dims=1)
            (x,y) = size(d)
            [d[i,j] for j in 1:x for i in (j+1):y]
        end
        p20 = quantile(distances, 20/100)
        abc = ABCanalysis(distances)
        v = maximum(distances[abc.c_indices]) / minimum(distances[abc.a_indices])
        radius = v * p20
        println(radius)
    end

    (_, k, m) = size(weights)
    result = fill(0, (k, m))
    for index in CartesianIndices((k,m))
        weight = weights[:,index]
        for row in eachrow(data)
            if settings.distance(row, weight) <= radius
                result[index] += 1
            end
        end
    end
    return result
end

function shiftWeights(weights::EsomWeights{Float64}, pos::CartesianIndex{2},
                      settings::Settings = defaultSettings)
    # since plot show the matrix four time, the midpoint of the plot is equal to
    # the latticeSize
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

function shiftToHighestDensity(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                               settings = defaultSettings)
    if !settings.toroid return weights end
    radius = filter(!iszero, pairwise(Euclidean(), data, dims=1)) |> mean
    p = pmatrix(data, weights, settings, radius = radius)
    pos = findfirst(isequal(maximum(p)), p)
    return shiftWeights(weights, pos, settings)
end
