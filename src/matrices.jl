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
    umatrix(weights::EsomWeights{Float64})

Generate a U-matrix for the given ESOM weights.
"""
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


"""
    pmatrix(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64}; radius = nothing)

Generate a P-matrix for the given data and ESOM weights.

If no pareto radius is given, a suitable one is estimated.
"""
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


"""
    ustarmatrix(um::AbstractMatrix{Float64}, pm::AbstractMatrix{Int})

Generate a U*-matrix from the given U- and P-matrices.
"""
function ustarmatrix(um::AbstractMatrix{Float64}, pm::AbstractMatrix{Int},
                     settings::Settings = defaultSettings)
    @assert size(um) == size(pm)
    # Using the calculation form 'U*-matrix: a tool to visualize clusters in
    # high dimensional data' (Ultsch 2003)
    scaleFactor(p::Int) = (p - mean(pm)) / (mean(pm) - maximum(pm)) + 1
    return um .* scaleFactor.(pm)
end


"""
    ustarmatrix(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64})

Generate a U*-matrix for the given data and ESOM weights.
"""
function ustarmatrix(data::AbstractMatrix{Float64}, weights::EsomWeights{Float64},
                     settings::Settings = defaultSettings)
    um = umatrix(weights, settings)
    pm = pmatrix(data, weights, settings)
    return ustarmatrix(um, pm, settings)
end


# compatability with DataIO.LRNData
for f in (:pmatrix, :ustarmatrix)
    @eval @inline ($f)(data::LRNData, args...; kwargs...) = ($f)(data.data, args...; kwargs...)
end
