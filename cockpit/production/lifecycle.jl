using Main.Types

abstract type Lifecycle end

mutable struct SingleUse <: Lifecycle
    used::Bool
    SingleUse(used=false) = new(used)
end

function use!(lifecycle::SingleUse)
    lifecycle.used = true
    return lifecycle
end

function damage!(lifecycle::SingleUse, damage::Real = 1)
    use(lifecycle)
    return lifecycle
end

function restore!(lifecycle::SingleUse, damage::Real = 0)
    return lifecycle
end

function health(lifecycle::SingleUse)
    return lifecycle.used ? Health(0) : Health(1)
end

"""
    Restorable

Indicates a lifecycle with restorability, i.e. the entity can recover from damage.
Thresholds determine the multiplier for health at and below the threshold.

# Fields
- `health`: The current health
- `damage_thresholds`: These are tuples, ordered by percentage, holding damage multipliers. The actual inflicted damage is multiplied with the appropriate multiplier before applied to the current health.
- `restoration_thresholds`: These are tuples, ordered by percentage, holding restoration multipliers. The actual amount of damage which is restored is first multiplied with the appropriate multiplier before being applied to the current health.
- `wear`: damage which occurs from each use.

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
    wear::Float64
    Restorable(
        health=1;
        damage_thresholds=[(1, 1)],
        restoration_thresholds=[(1, 1)],
        wear=0) = new(Health(health),
                    complete(damage_thresholds),
                    complete(restoration_thresholds),
                    wear)
end

"""
Sort the thresholds and make sure there is a threshold where the percentage == 100%. If the 100% threshold is added, use the same multiplier as the highest threshold. If no threshold is present, add (1, 1).
"""
function complete(thresholds::Vector)
    thresholds = sort(thresholds)

    if length(thresholds) == 0
        push!(thresholds, (1, 1))
    elseif thresholds[end][1] != 1
        push!(thresholds, (1, thresholds[end][2]))
    end

    return thresholds
end

"""
Returns the current health.
"""
function health(lifecycle::Lifecycle)
    return lifecycle.health
end

@enum Direction up down

function change_health(lifecycle::Lifecycle, change::Real, direction::Direction)
    if direction == up
        thresholds = lifecycle.restoration_thresholds
    else
        thresholds = lifecycle.damage_thresholds
    end

    # It's easy when there is only the 100% threshold
    if length(thresholds) == 1
        real_change = thresholds[1][2] * change
        surplus_change = nothing
    else
        multiplier = nothing
        max_change = nothing
        index = length(thresholds) - 1

        while index > 0 && multiplier == nothing
            if lifecycle.health > thresholds[index][1]
                multiplier = thresholds[index + 1][2]

                if direction == up && index + 1 < length(thresholds)
                    # No surplus change can happen above 100%
                    max_change = thresholds[index + 1][1] - lifecycle.health.current
                elseif direction == down
                    max_change = lifecycle.health.current - thresholds[index][1]
                end
            end

            index -= 1
        end

        if multiplier == nothing
            # Health is below lowest threshold
            real_change = thresholds[1][2] * change
        else
            real_change = change * multiplier
        end

        if max_change != nothing && real_change > max_change
            surplus_change = (real_change - max_change) / multiplier
            real_change = max_change
        else
            surplus_change = nothing
        end
    end

    if direction == up
        lifecycle.health.current += real_change
    else
        lifecycle.health.current -= real_change
    end

    return change_health(lifecycle, surplus_change, direction)
end

function change_health(lifecycle::Lifecycle, change::Nothing, direction::Direction)
    return lifecycle
end

function use!(lifecycle::Restorable)
    damage!(lifecycle, lifecycle.wear)
end

"""
Applies damage according to the damage thresholds.
"""
function damage!(lifecycle::Lifecycle, damage::Real = 0.01)
    change_health(lifecycle, damage, down)
end


"""
Restores damage according to the restoration thresholds.
"""
function restore!(lifecycle::Lifecycle, damage::Real = 0.01)
    change_health(lifecycle, damage, up)
end
