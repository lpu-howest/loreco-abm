include("lifecycle.jl")

import Base: ==

using Main.Types
using UUIDs

INF = -1 # Indicates infinity for Ints

abstract type Entity end
abstract type Enhancer <: Entity end

abstract type Blueprint end

struct ConsumableBlueprint <: Blueprint
    type_id::UUID
    name::String
    ConsumableBlueprint(name::String) = new(uuid4(), name)
end

Base.show(io::IO, bp::ConsumableBlueprint) =
    print(io, "ConsumableBlueprint(Name: $(get_name(bp)))")

struct ProductBlueprint <: Blueprint
    type_id::UUID
    name::String
    lifecycle::Restorable
    restore_res::Dict{<:Blueprint,Int64}
    restore::Float64
    ProductBlueprint(name::String,
        lifecycle::Restorable = Restorable();
        restore_res::Dict{<:Blueprint,Int64} = Dict{<:Blueprint,Int64}(),
        restore::Real = 0) = new(uuid4(), name, lifecycle, restore_res, restore)
end

Base.show(io::IO, bp::ProductBlueprint) =
    print(io, "ProductBlueprint(Name: $(get_name(bp)), $(bp.lifecycle), Restore res: $(bp.restore_res), Restore: $(bp.restore))")

struct ProducerBlueprint <: Blueprint
    type_id::UUID
    name::String
    lifecycle::Restorable
    restore_res::Dict{<:Blueprint,Int64}
    restore::Float64
    batch_req::Dict{<:Blueprint,Int64} # Required input per batch
    batch::Dict{<:Blueprint,Int64} # batch per batch. The Blueprint and the number of items per blueprint.
    max_production::Int64 # Max number of batches per production cycle

    ProducerBlueprint(
        name::String,
        lifecycle::Restorable = Restorable();
        restore_res::Dict{<:Blueprint,Int64} = Dict{<:Blueprint,Int64}(),
        restore::Real = 0,
        batch_req::Dict{<:Blueprint,Int64} = Dict{<:Blueprint,Int64}(),
        batch::Dict{<:Blueprint,Int64} = Dict{<:Blueprint,Int64}(),
        max_production::Int64 = INF
    ) = new(uuid4(), name, lifecycle, restore_res, restore, batch_req, batch, max_production)
end

Base.show(io::IO, bp::ProducerBlueprint) = print(
    io,
    "ProducerBlueprint(Name: $(get_name(bp)), $(bp.lifecycle), Restore res: $(bp.restore_res), Restore: $(bp.restore), Input: $(bp.batch_req), batch: $(bp.batch), Max batches: $(bp.max_production == INF ? "INF" : bp.max_production)")

type_id(blueprint::Blueprint) = blueprint.type_id
get_name(blueprint::Blueprint) = blueprint.name
get_lifecycle(blueprint::Blueprint) = deepcopy(blueprint.lifecycle)

==(x::Blueprint, y::Blueprint) = type_id(x) == type_id(y)

"""
    Entities
"""

struct Entities
    entities::Dict{<:Blueprint,Vector{Entity}}
    Entities() = new(Dict{<:Blueprint,Vector{Entity}}())
end

Base.keys(entities::Entities) = keys(entities.entities)
Base.values(entities::Entities) = values(entities.entities)
Base.getindex(entities::Entities, index::Blueprint) = entities.entities[index]
Base.setindex!(entities::Entities, e::Array{Entity,1}, index::Blueprint) = (entities.entities[index] = e)

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

struct Product <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::Restorable
    Product(blueprint) = new(uuid4(), blueprint, get_lifecycle(blueprint))
end

Base.show(io::IO, e::Product) = print(io, "Product(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(e.blueprint)))")

"""
    Producer

An Entity with the capability to produce other Entities.

# Fields
- `id`: The id of the Producer.
- `lifecycle`: The lifecycle of the Producer.
- `blueprint`: The blueprint the producer is based on.
"""
struct Producer <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::Restorable
    Producer(
        blueprint::Blueprint
    ) = new(uuid4(), blueprint, get_lifecycle(blueprint))
end

Base.show(io::IO, e::Producer) = print(
    io,
    "Producer(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(e.blueprint))",
)

==(x::Entity, y::Entity) = x.id == y.id

blueprint(entity::Entity) = entity.blueprint
type_id(entity::Entity) = type_id(blueprint(entity))
is_type(entity::Entity, blueprint::Blueprint) = type_id(entity) == type_id(blueprint)
get_name(entity::Entity) = get_name(blueprint(entity))
id(entity::Entity) = entity.id
health(entity::Entity) = health(entity.lifecycle)

ENTITY_CONSTRUCTORS = Dict(ConsumableBlueprint => Consumable, ProductBlueprint => Product, ProducerBlueprint => Producer)

function use!(entity::Entity)
    use!(entity.lifecycle)
    return entity
end

function extract!(requirements::Dict{Blueprint,Int64}, source::Entities, max::Int = INF)
    extracting = true
    extracted = 0

    while (max == INF || extracted < max) && extracting
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

Produces batch based on the producer and the provided resouces. The maximum possible batch is generated. The used resources are removed from the resources Dict and produced Entities are added to the products Dict.

# Returns
- produced entities
- leftover resources
"""
function produce!(producer::Producer, resources::Entities = Entities())
    products = Entities()

    if health(producer) > 0
        production = extract!(blueprint(producer).batch_req, resources, blueprint(producer).max_batches)

        if production > 0
            for i in range(production)
                for blueprint in keys(blueprint(producer).batch)
                    for j in blueprint(producer).batch[blueprint]
                        push!(products, ENTITY_CONSTRUCTORS[typeof(blueprint)](blueprint))
                    end
                end
            end

            use!(producer)
        end
    end

    return products, resources
end

function damage!(entity::Entity, damage::Real)
    damage!(entity.lifecycle, damage)

    return entity
end

function restore!(consumable::Consumable, resources::Entities = Entities())
    return consumable
end

function restore!(entity::Entity, resources::Entities = Entities())
    if extract!(blueprint(entity).res_rec, entities, 1) > 0
        restore!(entity.lifecycle, blueprint(entity).res_amount)
    end

    return entity
end
