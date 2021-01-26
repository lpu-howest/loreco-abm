using Agents
using Main.Types
using Main.Finance
using Main.Production

"""
A Person agent representing an individual.

* id::Int - the id of the agent.
* balance::Balance - the balance sheet of the agent.
* posessions::Entities - the entities in posession of the agent.
* production::Producer - the production facilities of the agent.
* needs::Dict{Blueprint, Vector{Tuple{Int, Percentage}}}
    Indicates how needs are fulfilled.
    The Blueprints indicate the entities the agent is interested in. The tuples in the vector define thresholds of quantities and probabilities the agent will try to acquire an extra unit of the entity.

    # Example:
    If an agent has a NeedFullfillment consisting of one Blueprint "A" and the following Vector of Tuples associated with this Blueprint:
    [(1, 1.0), (3, 0.5), (5, 0.0)]
    The the agent has a 100% chance to try to acquire one extra item if the agent posseses 1 or less units, 50% chance of acquiring an extra item when posessing 3 or less units and 0% chance when posessing 5 units. When determining the probability for an acquirement the highest possible probability in accordance with the amount of posessed units is chosen.
    In the give example posession of 4 units would result in a 50% probability to acquire an extra unit.
"""
mutable struct Person <: AbstractAgent
    id::Int
    balance::Balance
    posessions::Entities
    production::Vector{Producer}
    needs::Dict{Blueprint, Vector{Tuple{Int, Percentage}}}
end

function Person(id::Int,
            production::Vector{Producer} = Vector{Producer}(),
            needs::Dict{Blueprint, Vector{Tuple{Int, Percentage}}} = Dict{Blueprint, Vector{Tuple{Int, Percentage}}}())
    for need in keys(needs)
        sort(needs[need])
    end

    return Person(id, Balance(), Entities(), production, needs)
end

function get_production(person::Person)
    production = Set{Blueprint}()

    for producer in person.production
        production = union(Set(keys(get_blueprint(producer).batch)), production)
    end

    return production
end

function get_needs(person::Person)
    return keys(person.needs)
end

function get_posessions(person::Person, bp::Blueprint)
    if bp in keys(person.posessions)
        return length(person.posessions[bp])
    else
        return 0
    end
end

"""
    determine_desire(person::Person, bp::Blueprint)

Determines the number of units a Person will try to acquire based on its needs.
As long as the check for acquisition results in a desire to acquire an extra unit, another check will be executed to see whether yet another unit would be attempted to be acquired.

# Example:
Given a Person with the following NeedFulfillment and no posessions:
(Blueprint("A") => [(2, 1.0), (5, 0.5)])

Tuples denote a number of units and the probability to desire another one if the person has less than the indicated number.
In the example above the probability for attemptoing to acquire the first unit is 100% if the person posesses no units.
A check for acquiring a second unit is executed and since the probability for this is also 100%, a check for acquiring a third unit is executed.
The probability for a third unit is 50% (the agent now posesses 2 units thus the next tuple is used). If this check results in the attempt to acquire a third unit, a check for acquiring a fourth unit will be made and so on.
Once 5 units are in posession the check will always be negative in this example and therefor the maximum number of units desired is 5.
"""
function get_desire(person::Person, bp::Blueprint)
    cur_posessions = get_posessions(person, bp)
    acquisitions = 0
    needs_pattern = person.needs[bp]
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

function get_desires(person::Person)
    desires = Dict{Blueprint, Int}()

    for bp in keys(person.needs)
        desires[bp] = get_desire(person, bp)
    end

    return desires
end

function agent_step!(agent, model)
    target = agent

    while target.id == agent.id
        target = random_agent(model)
    end

    amount = round(rand(), digits = 2) * sumsy_balance(agent.balance) / 10
    sumsy_transfer!(agent.balance, target.balance, amount, model.step)
end

function model_step!(model)
    sumsy = model.SuMSy
    model.step += 1

    for agent in allagents(model)
        process_sumsy!(sumsy, agent.balance, model.step)
    end
end
