module Entities

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

struct Consumable
    id::Identity

end



end
