push!(LOAD_PATH,"../src/")

using Documenter
using Umatrix

makedocs(
    sitename = "Umatrix.jl",
    authors = "Tobias Frilling",
    format = Documenter.HTML(),
    modules = [Umatrix],
    pages = [
             "Home" => "index.md",
             "ESOM Training" => "esom.md",
             "Matrices" => "matrices.md",
             "Plotting" => "plotting.md",
             "Settings" => "settings.md",
             "API" => "api.md"
            ]
)

deploydocs(
    repo = "github.com/ckafi/Umatrix.jl"
)
