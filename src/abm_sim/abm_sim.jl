module ABM_Sim
    include("marginality.jl")
    export Marginality, process

    include("needs.jl")
    export Needs, Need
    export want, usage
    export push_usage!, push_want!, delete_usage!, delete_want!
    export is_prioritised, usage_prioritised, wants_prioritised

    include("actor.jl")
    export Actor
    export push_producer!, delete_producer!, produce!, purchase!
    export get_posessions, get_production_output
    export actor_step!

    include("marginal_actor.jl")
    export marginal_actor
    export process_needs, process_usage, process_wants
end
