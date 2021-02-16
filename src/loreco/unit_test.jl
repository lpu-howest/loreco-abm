using Test
using Agents
using DataStructures
using ..Utilities
using ..Production
using ..Finance
using ..Econo_Sim
using ..Loreco

@testset "Loreco model" begin
    model = init_loreco_model()
    # step!(model, actor_step!, loreco_model_step!, 100000, false)
end
