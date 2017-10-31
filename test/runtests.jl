using Stheno
using Base.Test
using BenchmarkTools

@testset "Stheno" begin

    @testset "Kernel" begin
        include("kernel/base.jl")
        include("kernel/compose.jl")
        include("kernel/transform.jl")
        include("kernel/input_transform.jl")
        include("kernel/finite.jl")
        include("kernel/posterior.jl")
    end

    include("gp.jl")
    include("lin_ops.jl")
    include("covariance_matrices.jl")
end
