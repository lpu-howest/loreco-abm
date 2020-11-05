module Entities

using Main.Types

export Health, Lifecycle, SingleUse, Mechanical

mutable struct Health
    current::Percentage
    Health(current=1.0) = new(current)
end

Base.convert(::Type{Health}, x::Real) = Health(x)
Base.convert(::Type{Health}, x::Health) = x

Base.promote_rule(::Type{T}, ::Type{Health}) where T <: Real = Health

abstract type Lifecycle end

mutable struct SingleUse <: Lifecycle
    used::Bool
    SingleUse(used=false) = new(used)
end

function damage!(lifecycle::SingleUse)
    lifecycle.used = true
    return lifecycle
end

function repair!(lifecycle::SingleUse)
    return lifecycle
end

function health(lifecycle::SingleUse)
    return lifecycle.used ? Health(0) : Health(1)
end

struct Repairable <: Lifecycle
    health::Health
    damage_thresholds::Vector{Tuple{Percentage, Float64}}
    repair_thresholds::Vector{Tuple{Percentage, Float64}}
end

Repairable(
    health::Real = 1;
    damage_thresholds::Vector = Vector{Tuple{Percentage,Real}}(),
    repair_thresholds::Vector = Vector{Tuple{Percentage,Real}}(),
) = Mechanical(Health(health), damage_thresholds, repair_thresholds)

function health(lifecycle::Lifecycle)
    return lifecycle.health
end

function damage(lifecycle::Lifecycle)
end

function repair!(repairable)
end


end
