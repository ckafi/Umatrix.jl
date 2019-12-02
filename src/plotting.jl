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

@userplot Plot_Matrix

@recipe function f(p::Plot_Matrix;
                   projection::Dict{Int, CartesianIndex{3}} = Dict(),
                   normalize::Bool = true,
                   colorStyle::Symbol = :umatrix)

    m = p.args[1]
    if normalize
        (min_m, max_m) = quantile(m[:], [.01, .99])
        m = (m .- min_m) ./ (max_m - min_m)
    end
    (rows, columns) = size(m)

    grid := false
    framestyle := :none
    yflip --> true
    colorbar --> true
    aspect_ratio --> 1

    @series begin
        seriestype := :contourf
        (min_m, max_m) = quantile(m[:], [.01, .99])
        levels --> round(Int, max_m / max(min_m, .05))
        seriescolor --> if colorStyle == :pmatrix colormap_pmatrix
                        else colormap_umatrix end
        linewidth --> 0.1
        [m m; m m]
    end

    if !isempty(projection)
        @series begin
            seriestype := :scatter
            widen := false
            legend := false
            colorbar_entry := false
            markercolor --> :lightgreen
            markersize --> 2.5
            markerstrokewidth --> 0.4
            v = values(projection) |> collect
            v = vcat(v, map(i -> i + CartesianIndex(rows, 0), v))
            v = vcat(v, map(i -> i + CartesianIndex(0, columns), v))
            getindex.(v,2), getindex.(v,1)
        end
    end

end

colormap_umatrix = begin
    local c = ["#3C6DF0", "#3C6DF0", "#3C6DF0", "#006602", "#006A02", "#006D01",
               "#007101", "#007501", "#007901", "#007C00", "#008000", "#068103",
               "#118408", "#0B8305", "#17860A", "#1D870D", "#228810", "#288A12",
               "#2E8B15", "#348D18", "#398E1A", "#3F8F1D", "#45911F", "#4A9222",
               "#509325", "#569527", "#5C962A", "#61982C", "#67992F", "#6D9A32",
               "#729C34", "#789D37", "#7E9F39", "#84A03C", "#89A13F", "#8FA341",
               "#95A444", "#9AA547", "#A0A749", "#A6A84C", "#ACAA4E", "#B1AB51",
               "#B7AC54", "#BDAE56", "#C3AF59", "#C8B15B", "#CEB25E", "#CBAF5C",
               "#C8AC59", "#C5A957", "#C3A654", "#C0A352", "#BDA050", "#BA9D4D",
               "#B7994B", "#B49648", "#B29346", "#AF9044", "#AC8D41", "#A98A3F",
               "#A6873C", "#A3843A", "#A08138", "#9E7E35", "#9B7B33", "#987830",
               "#95752E", "#92722B", "#8F6E29", "#8C6B27", "#8A6824", "#876522",
               "#84621F", "#815F1D", "#7E5C1B", "#7B5918", "#795616", "#765313",
               "#714E0F", "#6C480B", "#674307", "#6F4D15", "#785822", "#806230",
               "#896D3E", "#91774C", "#998159", "#A28C67", "#AA9675", "#B3A183",
               "#BBAB90", "#C3B59E", "#CCC0AC", "#D4CABA", "#DDD5C7", "#E5DFD5",
               "#E7E1D8", "#E9E4DB", "#EBE6DE", "#ECE8E1", "#EEEAE4", "#F0EDE7",
               "#F2EFEA", "#F4F1ED", "#F6F4F0", "#F8F6F3", "#F9F8F6", "#FBFAF9",
               "#FDFDFC", "#FFFFFF", "#FFFFFF", "#FEFEFE", "#FEFEFE", "#FEFEFE",
               "#FDFDFD", "#FDFDFD", "#FDFDFD", "#FCFCFC", "#FCFCFC", "#FCFCFC",
               "#FBFBFB", "#FBFBFB", "#FBFBFB", "#FAFAFA", "#FAFAFA", "#FAFAFA",
               "#F9F9F9", "#F9F9F9", "#FFFFFF", "#FFFFFF"]
    local f(s) = parse(RGB, s)
    f.(c) |> ColorGradient
end

colormap_pmatrix = begin
    local c = ["#FFFFFF", "#FFFFF7", "#FFFFEF", "#FFFFE7", "#FFFFDF", "#FFFFD7",
               "#FFFFCF", "#FFFFC7", "#FFFFBF", "#FFFFB7", "#FFFFAF", "#FFFFA7",
               "#FFFF9F", "#FFFF97", "#FFFF8F", "#FFFF87", "#FFFF80", "#FFFF78",
               "#FFFF70", "#FFFF68", "#FFFF60", "#FFFF58", "#FFFF50", "#FFFF48",
               "#FFFF40", "#FFFF38", "#FFFF30", "#FFFF28", "#FFFF20", "#FFFF18",
               "#FFFF10", "#FFFF08", "#FFFF00", "#FFFA00", "#FFF400", "#FFEF00",
               "#FFEA00", "#FFE400", "#FFDF00", "#FFDA00", "#FFD400", "#FFCF00",
               "#FFCA00", "#FFC500", "#FFBF00", "#FFBA00", "#FFB500", "#FFAF00",
               "#FFAA00", "#FFA500", "#FF9F00", "#FF9A00", "#FF9500", "#FF8F00",
               "#FF8A00", "#FF8500", "#FF8000", "#FF7A00", "#FF7500", "#FF7000",
               "#FF6A00", "#FF6500", "#FF6000", "#FF5A00", "#FF5500", "#FF5000",
               "#FF4A00", "#FF4500", "#FF4000", "#FF3A00", "#FF3500", "#FF3000",
               "#FF2B00", "#FF2500", "#FF2000", "#FF1B00", "#FF1500", "#FF1000",
               "#FF0B00", "#FF0500", "#FF0000", "#FA0000", "#F40000", "#EF0000",
               "#EA0000", "#E40000", "#DF0000", "#DA0000", "#D40000", "#CF0000",
               "#CA0000", "#C50000", "#BF0000", "#BA0000", "#B50000", "#AF0000",
               "#AA0000", "#A50000", "#9F0000", "#9A0000", "#950000", "#8F0000",
               "#8A0000", "#850000", "#800000", "#7A0000", "#750000", "#700000",
               "#6A0000", "#650000", "#600000", "#5A0000", "#550000", "#500000",
               "#4A0000", "#450000", "#400000", "#3A0000", "#350000", "#300000",
               "#2B0000", "#250000", "#200000", "#1B0000", "#150000", "#100000",
               "#0B0000", "#050000"]
    local f(s) = parse(RGB, s)
    f.(c) |> ColorGradient
end

