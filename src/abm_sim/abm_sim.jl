module ABM_Sim
    include("marginality.jl")
    export Marginality, process

    include("needs.jl")
    export Needs
    export want, usage
    export push_usage!, push_want!, delete_usage!, delete_want!
    export is_prioritised, usage_prioritised, wants_prioritised

    include("actor.jl")
    export Actor
    export push_producer!, delete_producer!, produce!, purchase!
    export get_posessions, get_production_output, process_needs, process_usage, process_wants
end
