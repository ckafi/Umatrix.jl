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

function neighbourhoodOffsets(radius::T) where {T<:Real}
    r_int = ceil(Int, radius)
    result = CartesianIndices((r_int,r_int) .* 2 .+ 1) .-
             CartesianIndex(r_int+1, r_int+1)
    filter(i -> sum(i.I.^2) <= radius^2, result)
end

function neighbourhoodFromOffsets(index::CartesianIndex{2},
                                  offsets::AbstractVector{CartesianIndex{2}},
                                  settings = defaultSettings)
    neighbourhood = map(i -> i + index, offsets)
    return unique(correctCoords(neighbourhood, settings))
end

function directNeighbours(ind::CartesianIndex{2}, settings = defaultSettings)
    neighbours = (CartesianIndices((3,3)) .- (CartesianIndex(2,2) - ind))[:]
    deleteat!(neighbours, 5)
    return correctCoords(neighbours, settings)
end

function correctCoords(coords::AbstractVector{CartesianIndex{2}}, settings = defaultSettings)
    if settings.toroid
        return wrapCoordsOnToroid(coords, settings)
    else
        return removeCoordsOutsideBounds(coords, settings)
    end
end

function removeCoordsOutsideBounds(coords::AbstractVector{CartesianIndex{2}}, settings = defaultSettings)
    filter(i -> (1 <= i.I[1] <= settings.rows) && (1 <= i.I[2] <= settings.columns), coords)
end

function wrapCoordsOnToroid(coords::AbstractVector{CartesianIndex{2}}, settings = defaultSettings)
    mod_replace_zero(x,y) = if (m = mod(x,y)) == 0 y else m end
    map(i -> CartesianIndex(mod_replace_zero.(i.I,(settings.rows,settings.columns))), coords)
end

@inline neighbourhoodKernel(kernel::Symbol) = neighbourhoodKernel(Val(kernel))

function neighbourhoodKernel(::Val{:cone})
    (dist::Float64, radius::Float64) -> (radius - dist)/radius
end

function neighbourhoodKernel(::Val{:gauss})
    (dist::Float64, radius::Float64) -> exp(-(dist/radius)^2/2)
end

function neighbourhoodKernel(::Val{:mexhat})
    (dist::Float64,radius::Float64) -> begin
        square = (dist/radius)^2
        (1 - square) * exp(-square/2)
    end
end
