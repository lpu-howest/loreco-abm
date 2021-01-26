using Test
using Main.Types
using Main.Production
using Main.Finance
using Main.ABM_Sim
using Agents

#@testset "Model" begin
    prices = Dict{Blueprint, BigFloat}()
    properties = Dict(:SuMSy => SuMSy(2000, 25000, 0.1, 30, seed = 5000),
                    :prices => prices,
                    :step => -1)
    model = ABM(Person, properties = properties)

    for n in 1:20
        add_agent!(model)
    end

    step!(model, agent_step!, model_step!, 100000, false)
#end
