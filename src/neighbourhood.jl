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
    neighbourhoodOffsets(radius::Float64)

Return every (unique) `CartesianIndex{2}` in a `radius`-sized circle around `index`.
"""
function neighbourhood(index::CartesianIndex{2}, radius::Float64,
                       settings::Settings = defaultSettings)
    offsets = neighbourhoodOffsets(radius)
    f(i) = i + index
    neighbours = f.(offsets)
    return unique(correctCoords(neighbours, settings))
end


"""
    neighbourhoodOffsets(radius::Float64)

Return every `CartesianIndex{2}` in a `radius`-sized circle around (0,0).
"""
function neighbourhoodOffsets(radius::Float64)
    r_int = ceil(Int, radius)
    offsets = (CartesianIndices((r_int,r_int) .* 2 .+ 1) .-
               CartesianIndex(r_int+1, r_int+1))[:]
    filter!(i -> sum(i.I.^2) <= radius^2, offsets)
    return offsets
end


"""
    directNeighbours(ind::CartesianIndex{2})

Return the eight direct neighbours of index `ind`.
"""
function directNeighbours(ind::CartesianIndex{2}, settings::Settings = defaultSettings)
    neighbours = (CartesianIndices((3,3)) .- (CartesianIndex(2,2) - ind))[:]
    # remove the index itself
    deleteat!(neighbours, 5)
    return correctCoords(neighbours, settings)
end


"""
    correctCoords(coords::AbstractVector{CartesianIndex{2}})

Remove (if the lattice is a plane) or wrap (if the lattice is a toroid)
coordinates outside of the lattice size.
"""
function correctCoords(coords::AbstractVector{CartesianIndex{2}},
                       settings::Settings = defaultSettings)
    if settings.toroid
        return wrapCoordsOnToroid(coords, settings)
    else
        return removeCoordsOutsideBounds(coords, settings)
    end
end


"""
    removeCoordsOutsideBounds(coords::AbstractVector{CartesianIndex{2}})

Remove coordinates outside of the lattice size.
"""
function removeCoordsOutsideBounds(coords::AbstractVector{CartesianIndex{2}},
                                   settings::Settings = defaultSettings)
    filter(i -> all((1,1) .<= i.I .<= settings.latticeSize), coords)
end


"""
    wrapCoordsOnToroid(coords::AbstractVector{CartesianIndex{2}},

Wrap coordinates outside of the lattice size around the torus.
"""
function wrapCoordsOnToroid(coords::AbstractVector{CartesianIndex{2}},
                            settings::Settings = defaultSettings)
    # like mod, but returns y instead of 0
    mod_replace_zero(x,y) = if (m = mod(x,y)) == 0 y else m end
    map(i -> CartesianIndex(mod_replace_zero.(i.I,settings.latticeSize)), coords)
end


"""
    latticeDistance(a::CartesianIndex{2}, b::CartesianIndex{2},

Euclidean distance on the lattice.
"""
function latticeDistance(a::CartesianIndex{2}, b::CartesianIndex{2},
                         settings::Settings = defaultSettings)
    diff = abs.((a - b).I)
    if settings.toroid
        diff = min.(diff, settings.latticeSize .- diff)
    end
    return sqrt(sum(diff))
end


@inline neighbourhoodKernel(kernel::Symbol, radius::Float64) =
    neighbourhoodKernel(Val(kernel), radius)

"""
    neighbourhoodKernel(::Val{:cone}, radius::Float64)

Returns a linear neighbourhood decay function.
"""
function neighbourhoodKernel(::Val{:cone}, radius::Float64)
    (dist::Float64) -> (radius - dist)/radius
end


"""
    neighbourhoodKernel(::Val{:gauss}, radius::Float64)

Returns a gaussian neighbourhood decay function.
"""
function neighbourhoodKernel(::Val{:gauss}, radius::Float64)
    (dist::Float64) -> exp(-(dist/radius)^2/2)
end


"""
    neighbourhoodKernel(::Val{:mexhat}, radius::Float64)

Returns a "Mexican hat" (Ricker wavelet) neighbourhood decay function.
"""
function neighbourhoodKernel(::Val{:mexhat}, radius::Float64)
    (dist::Float64) -> begin
        square = (dist/radius)^2
        (1 - square) * exp(-square/2)
    end
end
