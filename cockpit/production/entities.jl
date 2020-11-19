include("lifecycle.jl")

import Base: ==

using Main.Types
using UUIDs

struct Identity
    id::UUID
    type_id::UUID
    name::String
    Identity(type_id, name) = new(uuid4(), type_id, name)
end

Base.show(io::IO, id::Identity) = print(io, "Identity($(id.name))")

==(x::Identity, y::Identity) = x.id == y.id

abstract type Entity end
abstract type Enhancer <: Entity end

abstract type BluePrint end

struct ConsumableBluePrint <: BluePrint
    type_id::UUID
    name::String
    ConsumableBluePrint(name) = new(uuid4(), name)
end

Base.show(io::IO, bp::ConsumableBluePrint) =
    print(io, "ConsumableBluePrint(Name: $(bp.name))")

struct ToolBluePrint <: BluePrint
    type_id::UUID
    name::String
    lifecycle::Restorable
    ToolBluePrint(name, lifecycle = Restorable()) = new(uuid4(), name, lifecycle)
end

Base.show(io::IO, bp::ToolBluePrint) =
    print(io, "ToolBluePrint(Name: $(bp.name), $(bp.lifecycle))")

struct ProducerBluePrint <: BluePrint
    type_id::UUID
    name::String
    lifecycle::Restorable
    res_input::Dict{BluePrint,Int64} # Required input per batch
    output::Dict{BluePrint,Int64} # Output per batch. The BluePrint and the number of items per BluePrint.
    max_batches::Int64
    ProducerBluePrint(
        name,
        lifecycle = Restorable();
        res_input = Dict{BluePrint,Int64}(),
        output = Dict{BluePrint,Int64}(),
        max_batches::Int = 1,
    ) = new(uuid4(), name, lifecycle, res_input, output, max_batches)
end

Base.show(io::IO, bp::ProducerBluePrint) = print(
    io,
    "ProducerBluePrint(Name: $(bp.name), $(bp.lifecycle), Input: $(bp.res_input), Output: $(bp.output), Max batches: $(bp.max_batches))",
)

==(x::BluePrint, y::BluePrint) = x.type_id == y.type_id

function type_id(blueprint::BluePrint)
    return blueprint.type_id
end

function name_of(blueprint::BluePrint)
    return blueprint.name
end

struct Consumable <: Entity
    id::Identity
    lifecycle::SingleUse
    Consumable(id) = new(id, SingleUse())
end

Consumable(blueprint::ConsumableBluePrint) =
    Consumable(Identity(blueprint.type_id, blueprint.name))

Base.show(io::IO, e::Consumable) = print(io, "Consumable(Name: $(e.name))")

struct Tool <: Entity
    id::Identity
    lifecycle::Restorable
    restore_res::Dict{BluePrint,Int64}
    restore::Float64
    Tool(id, lifecycle = Restorable(); restore_res = Dict{BluePrint,Int64}(), restore = 0) = new(id, lifecycle, restore_res, restore)
end

Tool(blueprint::ToolBluePrint; restore_res::Dict{BluePrint,Int64} = Dict{BluePrint,Int64}(), restore::Real = 0) =
    Tool(Identity(blueprint.type_id, blueprint.name), blueprint.lifecycle, restore_res, restore)

Base.show(io::IO, e::Consumable) = print(io, "Tool(Name: $(e.name), $(e.lifecycle))")

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
    id::Identity
    lifecycle::Restorable
    res_input::Dict{BluePrint,Int64} # Required input per batch
    output::Dict{BluePrint,Int64} # Output per batch
    max_batches::Int64
    restore_res::Dict{BluePrint,Int64}
    restore::Float64
    Producer(
        id,
        lifecycle = Restorable();
        res_input = Dict{BluePrint,Int64}(),
        output = Dict{BluePrint,Int64}(),
        max_batches = 1,
        restore_res = Dict{BluePrint,Int64}(),
        restore = 0
    ) = new(id, lifecycle, res_input, output, max_batches, restore_res, restore)
end

Producer(blueprint::ProducerBluePrint; restore_res::Dict{BluePrint,Int64} = Dict{BluePrint,Int64}(), restore::Real = 0) = Producer(
    Identity(blueprint.type_id, blueprint.name),
    blueprint.lifecycle,
    res_input = blueprint.res_input,
    output = blueprint.output,
    max_batches = blueprint.max_batches,
    restore_res = restore_res,
    restore = restore
)

Base.show(io::IO, e::Consumable) = print(
    io,
    "Producer(Name: $(e.name), $(e.lifecycle), Input: $(e.res_input), Output: $(e.output), Max batches: $(e.max_batches))",
)

==(x::Entity, y::Entity) = x.id == y.id

is_type(e::Entity, b::BluePrint) = e.id.type_id == b.type_id

function id(entity::Entity)
    return entity.id.id
end

function type_id(entity::Entity)
    return entity.id.type_id
end

function name_of(entity::Entity)
    return entity.id.name
end

function health(entity::Entity)
    return health(entity.lifecycle)
end

function use!(entity::Entity)
    use!(entity.lifecycle)
    return entity
end

"""
    produce!

Produces output based on the producer and the provided resouces. The maximum possible output is generated. The used resources are removed from the resources Dict and produced Entities are added to the products Dict.

# Returns
- produced entities
- leftover resources
"""
function produce!(producer::Producer, resources::Dict{BluePrint,Vector{Entity}} = Dict())
    products = Dict{BluePrint,Vector{Entity}}()

    if isempty(setdiff(keys(producer.res_input), keys(resources)))
        production_done = false

        while !production_done # TODO eliminate keys with empty vectors

        end
    end

    use!(producer)

    return products, resources
end

function restore!(consumable::Consumable, resources::Dict{BluePrint,Vector{Entity}} = Dict{BluePrint,Vector{Entity}}())
    return consumable
end

function restore!(entity::Entity, resources::Dict{BluePrint,Vector{Entity}} = Dict{BluePrint,Vector{Entity}}())

    return entity
end
