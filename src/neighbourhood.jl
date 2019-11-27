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

function neighbourhoodOffsets(radius::Float64)
    @assert radius >= 0
    radius_i = ceil(Int, radius)
    result = Set{CartesianIndex{2}}()
    sizehint!(result, 4*radius_i^2)
    for x in 1:radius_i, y in 1:radius_i
        if x^2 + y^2 <= radius^2
            push!(result, CartesianIndex(x,y))
        end
    end
    return collect(result)
end

function neighbourhoodFromOffsets(index::CartesianIndex{2},
                                  offsets::AbstractVector{CartesianIndex{2}},
                                  settings = defaultSettings)
    @unpack rows, columns
    neighbourhood = map(i -> i + index, offsets)
    if settings.toroid
        mod_replace_zero(x,y) = if (m = mod(x,y)) == 0 y else m end
        neighbourhood = map(i -> CartesianIndex(mod_replace_zero.(i.I,(rows,columns))), neighbourhood)
    else
        neighbourhood = filter(i -> 1 <= i.I[1] <= rows && 1 <= i.I[2] <= columns, neighbourhood)
    end
    return unique(neighbourhood)
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
