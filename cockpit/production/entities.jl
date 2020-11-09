using Main.Types
using UUIDs

struct Identity
    id::UUID
    name::String
    Identity(name::String) = new(uuid4(), name)
end

abstract type Entity end
abstract type Product <: Entity end
abstract type Producer <: Entity end
abstract type Enhancer <: Entity end

struct Consumable <: Product
    id::Identity
    lifecycle::SingleUse
end

struct Tool <: Product
    id::Identity
    lifecycle::Restorable
end

struct Producer <: Producer
    id::Identity
    lifecycle::Restorable
end
