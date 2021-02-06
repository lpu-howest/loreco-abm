using Agents
using DataStructures

using ..Utilities
using ..Finance
using ..Production

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
    produce!(agent)
    wants = process_wants(agent)
    usage = process_usage(agent)

    # TODO
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
