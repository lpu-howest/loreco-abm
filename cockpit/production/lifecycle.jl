using Main.Types


abstract type Lifecycle end

mutable struct SingleUse <: Lifecycle
    used::Bool
    SingleUse(used=false) = new(used)
end

function damage!(lifecycle::SingleUse)
    lifecycle.used = true
    return lifecycle
end

function restore!(lifecycle::SingleUse, damage::Real = 0)
    return lifecycle
end

function health(lifecycle::SingleUse, damage::Real = 0)
    return lifecycle.used ? Health(0) : Health(1)
end

"""
    Restorable

Indicates a lifecycle with restorability, i.e. the entity can recover from damage.

# Fields
- `health`: The current health
- `damage_thresholds`: These are tuples, ordered by percentage, holding damage multipliers. The actual inflicted damage is multiplied with the appropriate multiplier before applied to the current health.
- `restoration_thresholds`: These are tuples, ordered by percentage, holding restoration multipliers. The actual amount of damage which is restored is first multiplied with the appropriate multiplier before being applied to the current health.

# Example
`
Restorable
    health = Health(80.0%)
    damage_thresholds = [(70.0%, 0.5), (100.0%, 0.2)]
    restoration_thresholds = [(40.0%, 0.0), (70.0%, 0.2), (100.0%, 0.3)]
`
When 1 damage is done it results in 0.2 damage actually being applied. Should health drop to 70% or less, then 0.5 damage would be applied. This indicates the robustness at various levels of damage.

When i damage is restored it results in 0.3 damage actually being restored. Should health drop to 40% or below no damage is being restored. This indicates restorability. The last tier indicates a level of damage beyond which no restoration is possible anymore.
"""
struct Restorable <: Lifecycle
    health::Health
    damage_thresholds::Vector{Tuple{Percentage, Float64}}
    restoration_thresholds::Vector{Tuple{Percentage, Float64}}
    Restorable(health, damage_thresholds, restoration_thresholds) = new(health, sort(damage_thresholds), sort(restoration_thresholds))
end

function health(lifecycle::Lifecycle)
    return lifecycle.health
end

function damage!(lifecycle::Lifecycle, damage::Real = 0.01)
    multiplier = 0

    for threshold in lifecycle.damage_thresholds
        if lifecycle.health <= threshold[1]
            multiplier = threshold[2]
        else
            
end

function restore!(lifecycle::Lifecycle, damage::Real = 0.01)
end
