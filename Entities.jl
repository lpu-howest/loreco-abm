module Entities



abstract type Entity

abstract type Lonegvity

struct Identity
    id::Int
    category::String
    name::String
end

struct SingleUse <: Longevity
    used::Bool
end

struct Mechanical <: Longevity



struct Product <: Entity
    id::Identity
    health::Longevity
end


struct Producer <: Entity
    id::Identity
    health::Longevity
    input
    output
end





end
