using Test
using Main.Types
using Main.Production
using Main.Finance
using Main.ABM_Sim
using Agents

@testset "Model" begin
    properties = Dict(:SuMSy => SuMSy(2000, 25000, 0.02, 30, seed = 5000),
                    :step => -1)
    model = ABM(Person, properties = properties)

    for n in 1:100
        add_agent!(model)
    end

    step!(model, agent_step!, model_step!, 100, false)
end
