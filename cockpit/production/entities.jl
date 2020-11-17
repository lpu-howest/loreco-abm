include("lifecycle.jl")

using Main.Types
using UUIDs

struct Identity
    id::UUID
    type_id::UUID
    name::String
    Identity(type_id::UUID, name::String) = new(uuid4(), type_id, name)
end

abstract type Entity end
abstract type Enhancer <: Entity end

abstract type BluePrint end

struct ConsumableBluePrint <: BluePrint
    type_id::UUID
    name::String
    ConsumableBluePrint(name::String) = new(uuid4(), name)
end

struct ToolBluePrint <: BluePrint
    type_id::UUID
    name::String
    lifecycle::Restorable
    ToolBluePrint(name::String, lifecycle::Restorable = Restorable()) = new(uuid4(), name, lifecycle)
end

struct ProducerBluePrint <: BluePrint
    type_id::UUID
    name::String
    lifecycle::Restorable
    res_input::Dict{UUID, Int64} # Required input per batch
    output::Dict{BluePrint, Int64} # Output per batch. The BluePrint and the number of items per BluePrint.
    max_batches::Int64
    ProducerBluePrint(name::String, lifecycle::Restorable = Restorable(); res_input::Dict{UUID, Integer} = Dict(), output = Dict(), max_batches::Integer = 1) = new(uuid4(), name, lifecycle, res_input, output, max_batches)
end

struct Consumable <: Entity
    id::Identity
    lifecycle::SingleUse
    Consumable(id::Identity) = new(id, SingleUse())
end

Consumable(blueprint::ConsumableBluePrint) = Consumable(Identity(blueprint.type_id, blueprint.name))

struct Tool <: Entity
    id::Identity
    lifecycle::Restorable
    Tool(id::Identity, lifecycle::Restorable = Restorable()) = new(id, lifecycle)
end

Tool(blueprint::ToolBluePrint) = Tool(Identity(blueprint.type_id, blueprint.name), blueprint.lifecycle)

struct Producer <: Entity
    id::Identity
    lifecycle::Restorable
    res_input::Dict{UUID, Int64} # Required input per batch
    output::Dict{BluePrint, Int64} # Output per batch
    max_batches::Int64
    Producer(id, lifecycle = Restorable(); res_input::Dict{UUID, Integer} = Dict(), output::Dict{BluePrint, Integer} = Dict(), max_batches = 1) = new(id, lifecycle, res_input, output, max_batches)
end

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

function damage!(entity::Entity, damage::Real)
    damage!(entity.lifecycle, damage)
    return entity
end

function restore!(entity::Entity, damage::Real)
    restore!(entity.lifecycle, damage)
    return entity
end

function produce(producer::Producer, resources::Dict{UUID, Vector{Entity}} = Dict())
end
