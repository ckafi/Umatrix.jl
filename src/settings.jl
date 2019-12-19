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

@doc """
    mutable struct Settings

A struct that encapsulates commonly used settings for Umatrix.

If no explicit settings are given, most functions implicitly use
`Umatrix.defaultSettings`. There are a couple of ways to change settings:

```julia
# change default settings for all function calls
Umatrix.defaultSettings.some_setting = 20
# create new settings with the kw constructor
s1 = Umatrix.Settings(setting1 = 23, setting2 = 42)
some_function(..., settings = s1)
# copy existing settings and change it
s2 = copy(s1)
s2.setting3 = 99
some_function(..., settings = s2)
```

# Fields and defaults
```julia
latticeSize           :: Tuple{Int64,Int64}     = (50, 80)
toroid                :: Bool                   = true
epochs                :: Int64                  = 24
learningRate          :: Tuple{Float64,Float64} = (0.5, 0.1)
learningRateCooling   :: Symbol                 = :linear
radius                :: Tuple{Int64,Int64}     = (24, 1)
radiusCooling         :: Symbol                 = :linear
initMethod            :: Symbol                 = :uniform_min_max
neighbourhoodKernel   :: Symbol                 = :gauss
distance              :: Distances.PreMetric    = Distances.Euclidean()
shiftToHighestDensity :: Bool                   = true
```
""" Settings
Base.@kwdef mutable struct Settings
    latticeSize::Tuple{Int, Int}         = (50,80)
    toroid::Bool                         = true
    epochs::Int                          = 24
    learningRate::Tuple{Float64,Float64} = (0.5,0.1)
    learningRateCooling::Symbol          = :linear
    radius::Tuple{Int,Int}               = (24, 1)
    radiusCooling::Symbol                = :linear
    initMethod::Symbol                   = :uniform_min_max
    neighbourhoodKernel::Symbol          = :gauss
    distance::PreMetric                  = Euclidean()
    shiftToHighestDensity::Bool          = true
end


const defaultSettings = Settings()


# macro to unpack a settings value into local scope
macro unpack(exp)
    keys = isa(exp, Symbol) ? [exp] : exp.args
    assigments = [:( $key = getproperty(settings, $(Expr(:quote, key))) ) for key in keys]
    esc(Expr(:block, assigments...))
end


Base.copy(s::Settings) = deepcopy(s)


function Base.show(io::IO, ::MIME"text/plain", settings::Settings)
    print(io, "Umatrix settings:")
    for name in fieldnames(Settings)
        print(io, "\n$(name) = ", getproperty(settings, name))
    end
end
