using Agents
using DataStructures

using Main.Types
using Main.Finance
using Main.Production

"""
    Marginality - a progressive marginal use structure.

* marginality::Vector{Tuple{Int64, Percentage}} - a sorted list of tuples consisting of a number of units and a probability resulting in an extra unit if the number of available units is below the indicated number.
"""
Marginality = SortedSet{Tuple{Int64, Percentage}}

"""
    process(marginality::Marginality, units::Int64)

Determines the marginal number of units, given a current number of units.
As long as the check for a supplementary unit returns true, another check will be executed for yet another unit.

# Example:
Given a marginality: [(2, 1.0), (5, 0.5)]

Tuples denote a number of units and the probability an extra unit if the available number of units is less than the given number.
In the example above the probability for the first unit is 100% if no units are available.
A check for a second unit is executed and since the probability for this is also 100%, a check for a third unit is executed.
The probability for a third unit is 50% (2 units are available thus the next tuple is used). If this check results in a third unit, a check for a fourth unit will be made and so on.
Once 5 units are available the check will always return false in this example and therefor the maximum number of units is 5.

# Returns
The number of marginal units.
"""
function process(marginality::Marginality, units::Int64)
    desire = 0

    for entry in marginality
        if units >= entry[1]
            continue
        end

        if rand() <= entry[2]
            units += 1
        else
            break
        end
    end

    return units
end

"""
    Needs - indicates the needs of an Actor.

* use::Dict{Blueprint, Marginality} - indicates what the actor will use each cycle.
* wants::Dict{Blueprint, Marginality} - indicates what the actor will try to purchase each cycle.
"""
mutable struct Needs
    use::Dict{Blueprint, Marginality}
    wants::Dict{Blueprint, Marginality}
end

"""
    Actor - agent representing an economic actor.

* id::Int - the id of the agent.
* type::Symbol - the type of actor.
* balance::Balance - the balance sheet of the agent.
* posessions::Entities - the entities in posession of the agent.
* production::Vector{Producer} - the production facilities of the agent.
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
    producers::Vector{Producer}
    needs::Needs
end

function Actor(id::Int,
            type::Symbol,
            production::Vector{Producer} = Vector{Producer}(),
            needs::Dict{B, Vector{T}} = Dict{Blueprint, Vector{Tuple{Int, Percentage}}}();
            posessions = Entities(),
            balance = Balance()) where {B <: Blueprint, T <: Tuple{Int, Real}}
    for need in keys(needs)
        sort(needs[need])
    end

    return Actor(id, type, balance, posessions, production, needs)
end

function get_production_output(actor::Actor)
    production = Set{Blueprint}()

    for producer in actor.producers
        production = union(Set(keys(get_blueprint(producer).batch)), production)
    end

    return production
end

function get_needs(actor::Actor)
    return keys(actor.needs)
end

function get_posessions(actor::Actor, bp::Blueprint)
    if bp in keys(actor.posessions)
        return length(actor.posessions[bp])
    else
        return 0
    end
end

"""
    determine_desire(actor::Actor, bp::Blueprint)

Determines the number of units a Actor will try to acquire based on its needs.
As long as the check for acquisition results in a desire to acquire an extra unit, another check will be executed to see whether yet another unit would be attempted to be acquired.

# Example:
Given a Actor with the following NeedFulfillment and no posessions:
(Blueprint("A") => [(2, 1.0), (5, 0.5)])

Tuples denote a number of units and the probability to desire another one if the person has less than the indicated number.
In the example above the probability for attemptoing to acquire the first unit is 100% if the person posesses no units.
A check for acquiring a second unit is executed and since the probability for this is also 100%, a check for acquiring a third unit is executed.
The probability for a third unit is 50% (the agent now posesses 2 units thus the next tuple is used). If this check results in the attempt to acquire a third unit, a check for acquiring a fourth unit will be made and so on.
Once 5 units are in posession the check will always be negative in this example and therefor the maximum number of units desired is 5.
"""
function get_desire(actor::Actor, bp::Blueprint)
    cur_posessions = get_posessions(actor, bp)
    acquisitions = 0
    needs_pattern = actor.needs[bp]
    desire = 0
    acquire = true

    while acquire
        i = 1

        while i < length(needs_pattern) && cur_posessions + acquisitions >= needs_pattern[i][1]
            i += 1
        end

        acquire = cur_posessions + acquisitions < needs_pattern[i][1] && rand() <= needs_pattern[i][2]

        if acquire
            acquisitions += 1
        end
    end

    return acquisitions
end

function get_desires(actor::Actor)
    desires = Dict{Blueprint, Int}()

    for bp in keys(actor.needs)
        desires[bp] = get_desire(actor, bp)
    end

    return desires
end

"""
    produce!(actor::Actor)

Convert as many posessions into new products as possible.
"""
function Production.produce!(actor::Actor)

    for producer in actor.production
    end
end

"""
    FUNCTIONS

The property name for actor type specific functions which are called upon agent activation.

# Default actor types.

These pre-defined types have default functions associated with them which are called when the agent is activated. The following list indicates which function is associated with which type. To use these functions upon agent activation, add the dictionary created by the default_functions() function as the value of the FUNCTIONS property.

* PERSON - person_step!
"""
FUNCTIONS = :functions

PERSON = :person

# Default properties
STEP = :step

function default_properties()
    properties = Dict()
    properties[FUNCTIONS] = default_functions()
    properties[STEP] = -1
end

function default_functions()
    f_dict = Dict{Symbol, Function}

    f_dict[PERSON] = person_step!

    return f_dict
end

function person_step!(agent, model)
    target = agent

    while target.id == agent.id
        target = random_agent(model)
    end

    amount = rand() * sumsy_balance(agent.balance) / 10
    sumsy_transfer!(agent.balance, target.balance, amount, model.step)
end

function agent_step!(agent, model)
    if agent.type in model.functions
        model.functions[agent.type](agent, model)
    end
end

function model_step!(model)
    sumsy = model.SuMSy
    model.step += 1

    for agent in allagents(model)
        process_sumsy!(sumsy, agent.balance, model.step)
    end
end
