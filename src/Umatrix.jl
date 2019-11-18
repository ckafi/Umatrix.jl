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

using Distributions

function esomInit(data::Matrix{Float64}; init_method = :uniform_min_max, rows = 50, columns = 82)
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
    return mapslices(randcol, data, dims = 1)
end

end # module
