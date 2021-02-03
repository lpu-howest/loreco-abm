module ABM_Sim
    include("model.jl")
    export Marginality, marginality
    export Needs, Actor
    export FUNCTIONS, PERSON
    export get_production_output, get_needs, get_posessions, get_desire, get_desires, produce!
    export agent_step!, model_step!
end
