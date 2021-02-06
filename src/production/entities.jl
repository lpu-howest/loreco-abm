abstract type Entity end

"""
    Entities
"""

struct Entities
    entities::Dict{Blueprint,Set{Entity}}
    Entities() = new(Dict{Blueprint,Set{Entity}}())
end

function Entities(resources::Dict{B,Vector{E}}) where {B <: Blueprint, E <: Entity}
    entities = Entities()

    for blueprint in keys(resources)
        for entity in resources[blueprint]
            push!(entities, entity)
        end
    end

    return entities
end

Base.keys(entities::Entities) = keys(entities.entities)
Base.values(entities::Entities) = values(entities.entities)
Base.getindex(entities::Entities, index::Blueprint) = entities.entities[index]
Base.setindex!(entities::Entities, e::Set{Entity}, index::Blueprint) = (entities.entities[index] = e)

function Base.push!(entities::Entities, entity::Entity)
    if entity.blueprint in keys(entities)
        push!(entities[entity.blueprint], entity)
    else
        entities[entity.blueprint] = Set{Entity}([entity])
    end

    return entities
end

function Base.pop!(entities::Entities, bp::Blueprint)
    e = nothing

    if bp in keys(entities)
        if !isempty(entities[bp])
            e = pop!(entities[bp])
        end

        if isempty(entities[bp])
            pop!(entities.entities, bp)
        end
    end

    return e
end

function Base.delete!(entities::Entities, entity::Entity)
    bp = get_blueprint(entity)
    delete!(entities[bp], entity)

    if isempty(entities[bp])
        pop!(entities, bp)
    end

    return entities
end

"""
    num_entities(entities::Entities, bp::Blueprint)
"""
function num_entities(entities::Entities, bp::Blueprint)
    if bp in keys(entities)
        return length(entities[bp])
    else
        return 0
    end
end
