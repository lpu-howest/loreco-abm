using DataStructures
using ..Utilities

@enum Direction up down

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
    use!(lifecycle)
    return lifecycle
end

function restore!(lifecycle::SingleUse, damage::Real = 0)
    return lifecycle
end

function health(lifecycle::SingleUse)
    return lifecycle.used ? Health(0) : Health(1)
end

Thresholds = SortedSet{Tuple{Percentage, Float64}}

"""
    Restorable

Indicates a lifecycle with restorability, i.e. the entity can recover from damage.
Thresholds determine the multiplier for health at and below the threshold.

# Fields
- `health`: The current health
- `damage_thresholds`: These are tuples, ordered by percentage, holding damage multipliers. The applied multiplier corresponds with the lowest threshold which is higher than the health of the lifecycle.
- `restoration_thresholds`: These are tuples, ordered by percentage, holding restoration multipliers. The applied multiplier corresponds with the lowest threshold which is higher than the health of the lifecycle.
- `wear`: damage which occurs from each use. Succeptable to multipliers.

# Example
`
Restorable
    health = Health(80.0%)
    damage_thresholds = [(70.0%, 0.5), (100.0%, 0.2)]
    restoration_thresholds = [(40.0%, 0.0), (70.0%, 0.2), (100.0%, 0.3)]
`
When 1 damage is done it results in 0.2 damage actually being applied. Should health drop to 70% or less, then 0.5 damage would be applied. This indicates the robustness at various levels of damage.

When 1 damage is restored it results in 0.3 damage actually being restored. Should health drop to 40% or below no damage is being restored. This indicates restorability. The last tier indicates a level of damage beyond which no restoration is possible anymore.
"""
struct Restorable <: Lifecycle
    health::Health
    damage_thresholds::Thresholds
    restoration_thresholds::Thresholds
    wear::Float64
    Restorable(
        health::Real=1;
        damage_thresholds::AbstractVector{<:Tuple{<:Real, <:Real}}=[(1, 1)],
        restoration_thresholds::AbstractVector{<:Tuple{<:Real, <:Real}}=[(1, 1)],
        wear=0) = new(Health(health),
                    complete(Thresholds(damage_thresholds), down),
                    complete(Thresholds(restoration_thresholds), up),
                    wear)
end



"""
    complete

Make sure there is a threshold where the percentage == 100%. If the 100% threshold is added, use the same multiplier as the highest threshold. If no threshold is present, add (1, 1).
"""
function complete(thresholds::Thresholds, direction::Direction)
    if isempty(thresholds)
        push!(thresholds, (1, 1))
    elseif last(thresholds)[1] != 1
        push!(thresholds, (1, last(thresholds)[2]))
    end

    return thresholds
end

"""
    health

Returns the current health.
"""
function health(lifecycle::Lifecycle)
    return lifecycle.health
end

function change_health(lifecycle::Lifecycle, change::Real, direction::Direction)
    if direction == up
        thresholds = lifecycle.restoration_thresholds
    else
        thresholds = lifecycle.damage_thresholds
    end

    # It's easy when there is only the 100% threshold
    if length(thresholds) == 1
        real_change = first(thresholds)[2] * change
        surplus_change = nothing
    elseif (health(lifecycle) == 1 && direction == up) ||
        (health(lifecycle) == 0 && direction == down)
        return lifecycle
    else
        multiplier = nothing
        max_change = nothing
        previous = nothing
        before_previous = nothing

        for threshold in thresholds
            if health(lifecycle) < threshold[1]
                multiplier = threshold[2]

                if direction == up && threshold != last(thresholds)
                    max_change = threshold[1] - value(health(lifecycle))
                elseif direction == down && previous != nothing
                    if health(lifecycle) != previous[1]
                        max_change = value(health(lifecycle)) - previous[1]
                    else
                        multiplier = previous[2]

                        if before_previous != nothing
                            max_change = value(health(lifecycle)) - before_previous[1]
                        end
                    end
                end
            end

            if multiplier != nothing
                break
            end

            before_previous = previous
            previous = threshold
        end

        if multiplier == nothing
            # Health is below lowest threshold
            real_change = first(thresholds)[2] * change
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
