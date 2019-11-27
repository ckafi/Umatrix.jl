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
    @assert radius >= 0
    radius_i = ceil(Int, radius)
    flipV(i) = (-i[1], i[2])
    flipH(i) = (i[1], -i[2])
    quad1 = [(x,y) for x in 0:radius_i, y in 0:radius_i
             if ((x,y).^2 |> sum) <= radius^2]
    quad2 = flipV.(quad1)
    quad3 = flipH.(quad2)
    quad4 = flipV.(quad3)
    result = vcat(quad1,quad2,quad3,quad4) |> unique
    return map(CartesianIndex, result)
end

function neighbourhoodFromOffsets(index::CartesianIndex{2}, offsets::AbstractVector{CartesianIndex{2}},
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
