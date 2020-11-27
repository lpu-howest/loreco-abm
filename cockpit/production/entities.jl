include("lifecycle.jl")

import Base: ==

using Main.Types
using UUIDs

abstract type Entity end
abstract type Enhancer <: Entity end

abstract type Blueprint end

struct ConsumableBlueprint <: Blueprint
    type_id::UUID
    name::String
    ConsumableBlueprint(name) = new(uuid4(), name)
end

Base.show(io::IO, bp::ConsumableBlueprint) =
    print(io, "ConsumableBlueprint(Name: $(get_name(bp)))")

struct ToolBlueprint <: Blueprint
    type_id::UUID
    name::String
    lifecycle::Restorable
    restore_res::Dict{Blueprint,Int64}
    restore::Float64
    ToolBlueprint(name,
        lifecycle = Restorable();
        restore_res::Dict{Blueprint,Int64} = Dict{Blueprint,Int64}(),
        restore::Float64 = 0) = new(uuid4(), name, lifecycle, restore_res, restore)
end

Base.show(io::IO, bp::ToolBlueprint) =
    print(io, "ToolBlueprint(Name: $(get_name(bp)), $(bp.lifecycle), Restore res: $(restore_res), Restore: $(restore))")

struct ProducerBlueprint <: Blueprint
    type_id::UUID
    name::String
    lifecycle::Restorable
    restore_res::Dict{Blueprint,Int64}
    restore::Float64
    res_input::Dict{Blueprint,Int64} # Required input per batch
    output::Dict{Blueprint,Int64} # Output per batch. The Blueprint and the number of items per blueprint.
    max_batches::Int64
    ProducerBlueprint(
        name,
        lifecycle = Restorable();
        restore_res::Dict{Blueprint,Int64} = Dict{Blueprint,Int64}(),
        restore::Float64 = 0,
        res_input = Dict{Blueprint,Int64}(),
        output = Dict{Blueprint,Int64}(),
        max_batches::Int = 1,
    ) = new(uuid4(), name, lifecycle, restore_res, restore, res_input, output, max_batches)
end

Base.show(io::IO, bp::ProducerBlueprint) = print(
    io,
    "ProducerBlueprint(Name: $(get_name(bp)), $(bp.lifecycle), Restore res: $(restore_res), Restore: $(restore), Input: $(bp.res_input), Output: $(bp.output), Max batches: $(bp.max_batches))",
)

type_id(blueprint::Blueprint) = blueprint.type_id
get_name(blueprint::Blueprint) = blueprint.name
get_lifecycle(blueprint::Blueprint) = deepcopy(blueprint.lifecycle)

==(x::Blueprint, y::Blueprint) = type_id(x) == type_id(y)

"""
    Entities
"""

struct Entities
    entities::Dict{Blueprint,Vector{Entity}}
    Entities() = new(Dict{Blueprint,Vector{Entity}}())
end

Base.keys(entities::Entities) = keys(entities.entities)
Base.values(entities::Entities) = values(entities.entities)
Base.getindex(entities::Entities, index::Blueprint) = entities.entities[index]
Base.setindex!(entities::Entities, e::Array{Entity,1}, index::Blueprint) = (entities.entities[index] = e)
# Base.setindex!(entities::Entities, e::Entity, index::Blueprint) = (entities.entities[index] = e)

function Base.push!(entities::Entities, entity::Entity)
    if entity.blueprint in keys(entities)
        push!(entities[entity.blueprint], entity)
    else
        entities[entity.blueprint] = Vector{Entity}([entity])
    end

    return entities
end

function Base.pop!(entities::Entities, blueprint::Blueprint)
    if blueprint in keys(entities)
        e = pop!(entities[blueprint])

        if length(entities[blueprint]) == 0
            pop!(entities.entities, blueprint)
        end

        return e
    else
        return nothing
    end
end

struct Consumable <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::SingleUse
    Consumable(blueprint) = new(uuid4(), blueprint, SingleUse())
end

Base.show(io::IO, e::Consumable) = print(io, "Consumable(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(e.blueprint)))")

struct Tool <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::Restorable
    Tool(blueprint) = new(uuid4(), blueprint, get_lifecycle(blueprint))
end

Base.show(io::IO, e::Tool) = print(io, "Tool(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(blueprint)))")

"""
    Producer

An Entity with the capability to produce other Entities.

# Fields
- `id`: The id of the Producer.
- `lifecycle`: The lifecycle of the Producer.
- `res_input`: The resources needed to produce 1 batch.
- `output`: The output generated in one batch.
- `max_batches`: The maximum amount of batches that can be produced.
- `restore_res`: The resources needed to restore possible damage.
- 'restore': The amount of damage restored per 'batch' of resources. This
"""
struct Producer <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::Restorable
    res_input::Dict{Blueprint,Int64} # Required input per batch
    output::Dict{Blueprint,Int64} # Output per batch
    max_batches::Int64
    Producer(
        blueprint::Blueprint;
        res_input = Dict{Blueprint,Int64}(),
        output = Dict{Blueprint,Int64}(),
        max_batches = Inf
    ) = new(uuid4(), blueprint, res_input, output, max_batches)
end

Base.show(io::IO, e::Producer) = print(
    io,
    "Producer(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(blueprint)), Input: $(e.res_input), Output: $(e.output), Max batches: $(e.max_batches))",
)

==(x::Entity, y::Entity) = x.id == y.id

type_id(entity::Entity) = type_id(entity.blueprint)
is_type(entity::Entity, blueprint::Blueprint) = type_id(entity) == type_id(blueprint)
get_name(entity::Entity) = get_name(entity.blueprint)
id(entity::Entity) = entity.id
health(entity::Entity) = health(entity.lifecycle)

ENTITY_CONSTRUCTORS = Dict(ConsumableBlueprint => Consumable, ToolBlueprint => Tool, ProducerBlueprint => Producer)

function use!(entity::Entity)
    use!(entity.lifecycle)
    return entity
end

function extract!(requirements::Dict{Blueprint,Int64}, source::Entities, max::Int = Inf)
    extracting = true
    extracted = 0

    while extracted < max && extracting
        res_available = true

        for blueprint in keys(requirements)
            res_available &= length(source[blueprint]) >= requirements[blueprint]
        end

        if res_available
            for blueprint in keys(requirements)
                for i in range(requirements[blueprint])
                    pop!(entities[blueprint])
                end
            end

            extracted += 1
        else
            extracting = false
        end
    end

    return extracted
end

"""
    produce!

Produces output based on the producer and the provided resouces. The maximum possible output is generated. The used resources are removed from the resources Dict and produced Entities are added to the products Dict.

# Returns
- produced entities
- leftover resources
"""
function produce!(producer::Producer, resources::Entities = Entities())
    products = Entities()
    production = extract!(producer.res_input, resources, producer.max_batches)

    if production > 0
        for i in range(production)
            for blueprint in keys(producer.output)
                for j in producer.output[blueprint]
                    push!(products, ENTITY_CONSTRUCTORS[typeof(blueprint)](blueprint))
                end
            end
        end

        use!(producer)
    end

    return products, resources
end

function restore!(consumable::Consumable, resources::Entities = Entities())
    return consumable
end

function restore!(entity::Entity, resources::Entities = Entities())

    return entity
end
