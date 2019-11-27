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

@inline coolDown(method::Symbol, args...) = coolDown(Val(method), args...)

function coolDown(::Val{:linear}, (start, stop), steps)
    return step -> start - ((start - stop) / steps) * (step - 1)
end

function coolDown(::Val{:leadInOut}, (start, stop), steps; leadIn = 0.1, leadOut = 0.95)
    @assert leadIn < leadOut
    @assert leadOut - leadIn >= 0
    return step -> if (step/steps <= leadIn) start
                   elseif (step/steps >= leadOut) stop
                   else start - ((start - stop) / steps) * (step - 1)
                   end
end
