module ABM_Sim
    include("model.jl")
    export Actor
    export FUNCTIONS, PERSON
    export get_production, get_needs, get_posessions, get_desire, get_desires, produce!
    export agent_step!, model_step!
end
