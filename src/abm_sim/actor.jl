using Agents

using ..Utilities
using ..Finance
using ..Production

"""
    Actor - agent representing an economic actor.

* id::Int - the id of the agent.
* type::Symbol - the type of actor.
* balance::Balance - the balance sheet of the agent.
* posessions::Entities - the entities in posession of the agent.
* producers::Vector{Producer} - the production facilities of the agent.
* needs::Dict{Blueprint, Vector{Tuple{Int, Percentage}}}
    Indicates how needs are fulfilled.
    The Blueprints indicate the entities the agent is interested in. The tuples in the vector define thresholds of quantities and probabilities the agent will try to acquire an extra unit of the entity.

    # Example:
    If an agent has a NeedFullfillment consisting of one Blueprint "A" and the following Vector of Tuples associated with this Blueprint:
    [(1, 1.0), (3, 0.5), (5, 0.0)]
    The the agent has a 100% chance to try to acquire one extra item if the agent posseses 1 or less units, 50% chance of acquiring an extra item when posessing 3 or less units and 0% chance when posessing 5 units. When determining the probability for an acquirement the highest possible probability in accordance with the amount of posessed units is chosen.
    In the given example posession of 4 units would result in a 50% probability to acquire an extra unit.
"""
mutable struct Actor <: AbstractAgent
    id::Int
    type::Symbol
    balance::Balance
    posessions::Entities
    producers::Set{Producer}
    needs::Needs
end

function Actor(id::Int,
            type::Symbol,
            producers::Vector{Producer} = Vector{Producer}(),
            needs::Needs = Needs();
            posessions = Entities(),
            balance = Balance()) where {B <: Blueprint, T <: Tuple{Int, Real}}
    return Actor(id, type, balance, posessions, Set(producers), needs)
end

function push_producer!(actor::Actor, producer::Producer)
    push!(actor.producers, producer)

    return actor
end

function delete_producer!(actor::Actor, producer::Producer)
    delete!(actor.producers, producer)

    return actor
end

function push_usage!(actor::Actor,
                    bp::Blueprint,
                    marginality::Marginality,
                    priority::Int64 = 0)
    push_usage!(actor.needs, bp, marginality, priority)

    return actor
end

function push_want!(actor::Actor,
                    bp::Blueprint,
                    marginality::Marginality,
                    priority::Int64 = 0)
    push_want!(actor.needs, bp, marginality, priority)

    return actor
end

function delete_usage!(actor::Actor,
                    bp::Blueprint,
                    priority::Int64 = nothing)
    delete_usage!(actor.needs, bp, priority)

    return actor
end

function delete_want!(actor::Actor,
                    bp::Blueprint,
                    priority::Int64 = nothing)
    delete_want!(actor.needs, bp, priority)

    return actor
end

function get_posessions(actor::Actor, bp::Blueprint)
    if bp in keys(actor.posessions)
        return length(actor.posessions[bp])
    else
        return 0
    end
end

"""
    get_production_output(actor::Actor)

Get the set of all blueprints produced by the actor.
"""
function get_production_output(actor::Actor)
    production = Set{Blueprint}()

    for producer in keys(actor.producers)
        production = union(Set(keys(get_blueprint(producer).batch)), production)
    end

    return production
end

"""
    process_needs(actor::Actor, type::NeedType)

Get a vector of all the needs of the actor of the specified need type. The vector contains named tuples {blueprint::Blueprint, units::Int}. If the need type is prioritised the list is in order of priority, otherwise it is randomized.
"""
function process_needs(actor::Actor, type::NeedType)
    process_needs(actor.needs, type, actor.posessions)
end

process_usage(actor::Actor) = process_needs(actor, usage)
process_wants(actor::Actor) = process_needs(actor, want)

"""
    produce!(actor::Actor)

Convert as many posessions into new products as possible.
"""
function Production.produce!(actor::Actor)
    # Create max production dictionary
    max_production = Dict{Producer, Int64}()

    for producer in actor.producers
        max_production[procucer] = producer.max_production
    end

    # Loop until max production has been reached
    while sum(values(actor.producers)) > 0
        batches = 0

        for producer in actor.producers
            production = produce!(producer, actor.possessions)
            merge!(actor.posessions, production.products)
            batches += production.batches
        end

        # If no more production is possible, end loop.
        if batches == 0
            break
        end
    end

    return actor
end

function purchase!(buyer::Actor,
                seller::Actor,
                bp::Blueprint,
                amount::Int64,
                price::Price)
    # TODO
end
