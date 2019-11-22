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

Base.@kwdef mutable struct Settings
    rows::Int                     = 50
    columns::Int                  = 82
    toroid::Bool                  = true
    epochs::Int                   = 24
    startLearningRate::Float64    = 0.5
    endLearningRate::Float64      = 0.1
    learningRateCooling::Symbol   = :linear
    startRadius::Float64          = 24
    endRadius::Float64            = 1
    radiusCooling::Symbol         = :linear
    init_method::Symbol           = :uniform_min_max
    neighbourhoodFunction::Symbol = :gauss
end

const defaultSettings = Settings()

macro unpack(exp)
    keys = isa(exp, Symbol) ? [exp] : exp.args
    assigments = [:( $key = getproperty(settings, $(Expr(:quote, key))) ) for key in keys]
    esc(Expr(:block, assigments...))
end

function Base.show(io::IO, ::MIME"text/plain", settings::Settings)
    print(io, "Umatrix settings:")
    for name in fieldnames(Settings)
        print(io, "\n$(name) = ", getproperty(settings, name))
    end
end
