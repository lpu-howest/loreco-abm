using Agents
using DataStructures

using ..Utilities
using ..Finance
using ..Production
using ..Econo_Sim

# Default properties
SUMSY = :sumsy
STEP = :step

# Actor types
CONSUMER = :consumer
MERCHANT = :merchant
GOVERNANCE = :governance

container_ticket = ConsumableBlueprint("Container park ticket")
swim_ticket = ConsumableBlueprint("Swim ticket")
bread = ConsumableBlueprint("Bread")
tv = ProductBlueprint("TV", Restorable(wear = 0.1))

function init_loreco_model(sumsy::SuMSy = SuMSy(2000, 25000, 0.1, 30, seed = 5000),
                        consumers::Integer = 380,
                        bakers::Integer = 15,
                        tv_merchants::Integer = 5)
    model = create_econo_model()
    model.properties[:sumsy] = sumsy

    add_consumers(model, consumers)
    add_bakers(model, bakers)
    add_tv_merchants(model, tv_merchants)
    add_governance(model, consumers + bakers + tv_merchants)

    return model
end

function add_consumers(model, consumers::Integer)
    needs = Needs()
    push_want!(needs, container_ticket, Marginality([(1, 0.1)]))
    push_want!(needs, swim_ticket, Marginality([(1, 0.25)]))
    push_want!(needs, bread, Marginality([(1, 1), (2, 0.5)]))
    push_want!(needs, tv, Marginality([(1, 0.4)]))

    push_usage!(needs, container_ticket, Marginality([(1, 1)]))
    push_usage!(needs, swim_ticket, Marginality([(1, 1)]))
    push_usage!(needs, bread, Marginality([(1, 1)]))
    push_usage!(needs, tv, Marginality([(1, 0.8)]))

    for n in 1:consumers
        add_agent!(make_loreco(model, Actor(type = CONSUMER), needs), model)
    end
end

function add_bakers(model, bakers::Integer)
    needs = Needs()
    push_want!(needs, container_ticket, Marginality([(1, 0.3)]))
    push_want!(needs, swim_ticket, Marginality([(1, 0.2)]))
    push_want!(needs, bread, Marginality([(1, 1)]))
    push_want!(needs, tv, Marginality([(1, 0.6)]))

    push_usage!(needs, container_ticket, Marginality([(1, 1)]))
    push_usage!(needs, swim_ticket, Marginality([(1, 1)]))
    push_usage!(needs, bread, Marginality([(1, 1)]))
    push_usage!(needs, tv, Marginality([(1, 0.5)]))

    set_price!(model, bread, 5)
    bakery = ProducerBlueprint("Bakery", batch = Dict(bread => 1))

    for n in 1:bakers
        baker = make_loreco(model, Actor(type = MERCHANT, producers = [Producer(bakery)]), needs)

        min_stock!(baker.stock, bread, 35)
        add_agent!(baker, model)
    end
end

function add_tv_merchants(model, tv_merchants::Integer)
    needs = Needs()
    push_want!(needs, container_ticket, Marginality([(1, 1)]))
    push_want!(needs, swim_ticket, Marginality([(1, 1)]))
    push_want!(needs, bread, Marginality([(1, 1), (2, 0.5), (3, 0.25)]))
    push_want!(needs, tv, Marginality([(1, 1)]))

    push_usage!(needs, container_ticket, Marginality([(1, 0.4)]))
    push_usage!(needs, swim_ticket, Marginality([(1, 0.3)]))
    push_usage!(needs, bread, Marginality([(1, 1)]))
    push_usage!(needs, tv, Marginality([(1, 0.9)]))

    set_price!(model, tv, 1000)
    tv_factory = ProducerBlueprint("TV factory", batch = Dict(tv => 1))

    for n in 1:tv_merchants
        tv_merchant = make_loreco(model, Actor(type = MERCHANT, producers = [Producer(tv_factory)]), needs)

        min_stock!(tv_merchant.stock, tv, 10)
        add_agent!(tv_merchant, model)
    end
end

function add_governance(model, citizens::Integer)
    set_price!(model, container_ticket, 10)
    set_price!(model, swim_ticket, 3)

    container_park = ProducerBlueprint("Container park", batch = Dict(container_ticket => 1))
    swimming_pool = ProducerBlueprint("Swimming pool", batch = Dict(swim_ticket => 1))

    governance = make_loreco(model, Actor(type = GOVERNANCE, producers = [Producer(container_park), Producer(swimming_pool)]))

    min_stock!(governance.stock, container_ticket, citizens)
    min_stock!(governance.stock, swim_ticket, citizens)
    governance.balance.dem_free = Inf
    add_agent!(governance, model)
end

Finance.sumsy_balance(actor::Actor) = sumsy_balance(actor.balance)

function sumsy_price(model, bp::Blueprint)
    price(model)[SUMSY_DEP]
end

function Econo_Sim.set_price!(model, bp::Blueprint, sumsy_price::Real, euro_price::Real = 0)
    price = Price()
    price[SUMSY_DEP] = sumsy_price
    price[DEPOSIT] = euro_price

    return set_price!(model, bp, price)
end

process_sumsy!(model, agent) = process_sumsy!(model.sumsy, agent.balance, get_step(model))

function make_loreco(model, actor, needs = nothing)
    if !has_type(actor, CONSUMER)
        add_model_behavior!(actor, produce_stock!)
    end

    if !has_type(actor, GOVERNANCE)
        add_model_behavior!(actor, Loreco.process_sumsy!)
    end

    return isnothing(needs) ? actor : make_marginal(actor, needs)
end
