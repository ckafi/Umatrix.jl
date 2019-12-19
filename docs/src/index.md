# Umatrix.jl

A Julia port of the [Umatrix R package](https://cran.r-project.org/web/packages/Umatrix/).

---

From the documentation of the R package:
> By gaining the property of emergence through self-organization, the
> enhancement of SOMs (self organizing maps) is called Emergent SOM (ESOM). The
> result of the projection by ESOM is a grid of neurons which can be visualised
> as a three-dimensional landscape in form of the U-matrix.

This package offers functionality for training an ESOM as well generating U-,
P- and U*-matrices.

For further details see [Visualization and 3D Printing of Multivariate Data of
Biomarkers](http://wscg.zcu.cz/wscg2016/short/A43-full.pdf).

### Installation

Umatrix.jl is not yet registered in the official registry of general Julia packages.

To install the *development version* from a Julia REPL type `]` to enter Pkg REPL mode and run
```julia
pkg> add https://github.com/ckafi/Umatrix.jl
```

### License

Umatrix.jl is licensed under the Apache License v2.0.
For the full license text see [LICENSE](https://github.com/ckafi/Umatrix.jl/blob/master/LICENSE).
