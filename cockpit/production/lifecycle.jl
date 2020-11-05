module Entities

using Main.Types

export Health, Lifecycle, Mechanical

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
    SingleUse(used=false, leaves_trash=false) = new(used, leaves_trash)
end

struct Mechanical <: Lifecycle
    health::Health
    damage_thresholds::Vector{Tuple{Percentage, Float64}}
    repair_thresholds::Vector{Tuple{Percentage, Float64}}
end

Mechanical(
    health::Real = 1;
    damage_thresholds::Vector = Vector{Tuple{Percentage,Real}}(),
    repair_thresholds::Vector = Vector{Tuple{Percentage,Real}}(),
) = Mechanical(Health(health), damage_thresholds, repair_thresholds)

end
