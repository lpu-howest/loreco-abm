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
    maintenance_res::Dict{BluePrint,Int64}
    maintenance::Float64
    Tool(id, lifecycle = Restorable(); maintenance_res = Dict{BluePrint,Int64}(), maintenance = 0) = new(id, lifecycle, maintenance_res, maintenance)
end

Tool(blueprint::ToolBluePrint; maintenance_res::Dict{BluePrint,Int64} = Dict{BluePrint,Int64}(), maintenance::Real = 0) =
    Tool(Identity(blueprint.type_id, blueprint.name), blueprint.lifecycle, maintenance_res, maintenance)

Base.show(io::IO, e::Consumable) = print(io, "Tool(Name: $(e.name), $(e.lifecycle))")

struct Producer <: Entity
    id::Identity
    lifecycle::Restorable
    res_input::Dict{BluePrint,Int64} # Required input per batch
    output::Dict{BluePrint,Int64} # Output per batch
    max_batches::Int64
    maintenance_res::Dict{BluePrint,Int64}
    maintenance::Float64
    Producer(
        id,
        lifecycle = Restorable();
        res_input = Dict{BluePrint,Int64}(),
        output = Dict{BluePrint,Int64}(),
        max_batches = 1,
        maintenance_res = Dict{BluePrint,Int64}(),
        maintenance = 0
    ) = new(id, lifecycle, res_input, output, max_batches, maintenance_res, maintenance)
end

Producer(blueprint::ProducerBluePrint; maintenance_res::Dict{BluePrint,Int64} = Dict{BluePrint,Int64}(), maintenance::Real = 0) = Producer(
    Identity(blueprint.type_id, blueprint.name),
    blueprint.lifecycle,
    res_input = blueprint.res_input,
    output = blueprint.output,
    max_batches = blueprint.max_batches,
    maintenance_res = maintenance_res,
    maintenance = maintenance
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

function do_maintenance!(consumable::Comsumable, resources::Dict{BluePrint,Vector{Entity}} = Dict{BluePrint,Vector{Entity}}())
    return consumable
end

function do_maintenance!(entity::Entity, resources::Dict{BluePrint,Vector{Entity}} = Dict{BluePrint,Vector{Entity}}())

    return entity
end
