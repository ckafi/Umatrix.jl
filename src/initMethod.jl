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

@inline initMethod(settings::Settings = defaultSettings) =
    initMethod(Val(settings.initMethod), settings)

function initMethod(::Val{:uniform_min_max}, settings::Settings = defaultSettings)
    col -> rand(Uniform(minimum(col), maximum(col)), prod(settings.latticeSize))
end

function initMethod(::Val{:uniform_mean_std}, settings::Settings = defaultSettings)
    col -> rand(Uniform(mean(col), std(col)), prod(settings.latticeSize))
end

function initMethod(::Val{:normal_mean_std}, settings::Settings = defaultSettings)
    col -> rand(Uniform(mean(col), std(col)), prod(settings.latticeSize))
end

function initMethod(::Val{:zeros}, settings::Settings = defaultSettings)
    col -> zeros(prod(settings.latticeSize))
end
