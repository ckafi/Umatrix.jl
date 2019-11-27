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

function _findmin(f, a)
    p = pairs(a)
    (mi, mv), _ = iterate(p)
    i = mi
    f_mv = f(mv)
    for (i, v) in p
        f_v = f(v)
        if f_v < f_mv
            f_mv = f_v
            mi = i
        end
    end
    return (f_mv, mi)
end
