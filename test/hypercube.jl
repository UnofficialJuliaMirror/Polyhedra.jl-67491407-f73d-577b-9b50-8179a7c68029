using JuMP
using Combinatorics

# Inspired from Joey Huchette's test in ConvexHull.jl
function hypercubetest(lib::PolyhedraLibrary, n)
    m = Model()
    @variable(m, 0 ≤ x[1:n] ≤ 1)

    lphrep = LPHRepresentation(m)
    poly = polyhedron(lphrep, lib)

    @fact npoints(poly) --> 2^n
    @fact nrays(poly) --> 0

    row = 0
    V = zeros(Int, 2^n, n)
    for k in 0:n
        for p in combinations(1:n, k)
            row += 1
            V[row, p] = ones(Int, length(p))
        end
    end
    generator_fulltest(poly, V)
end