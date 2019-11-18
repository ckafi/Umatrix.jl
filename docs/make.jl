push!(LOAD_PATH,"../src/")

using Documenter
using Umatrix

makedocs(
    sitename = "Umatrix.jl",
    authors = "Tobias Frilling",
    format = Documenter.HTML(),
    modules = [Umatrix]
)

deploydocs(
    repo = "github.com/ckafi/Umatrix.jl"
)
