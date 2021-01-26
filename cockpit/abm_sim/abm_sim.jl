module ABM_Sim
    include("model.jl")
    export Person
    export get_production, get_needs, get_posessions, get_desire, get_desires
    export agent_step!, model_step!
end
