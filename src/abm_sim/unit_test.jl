using Test
using Agents
using DataStructures
using ..Utilities
using ..Production
using ..Finance
using ..ABM_Sim

@testset "Marginality" begin
    m = Marginality([(5, 0.1), (1, 1)])

    @test typeof(m) == SortedSet{Tuple{Int64,Percentage},Base.Order.ForwardOrdering}
    @test length(m) == 2
    @test first(m) == (1, 1)
    @test last(m) == (5, 0.1)
    @test 1 <= process(m) <= 5
end

@testset "Needs" begin
    # Blueprints
    cb = ConsumableBlueprint("Consumable")
    pb = ProductBlueprint("Product")

    needs = Needs()

    # usage
    push_usage!(needs, cb, Marginality([(2, 1), (5, 0.5)]), priority = 1)
    push_usage!(needs, pb, Marginality([(1, 1), (2, 0.1)]), priority = 2)

    # wants
    push_want!(needs, cb, Marginality([(1, 1), (2, 0.5)]), priority = 2)
    push_want!(needs, pb, Marginality([(1, 1)]), priority = 1)

    usages = process_usage(needs)
    @test length(usages) == 2
    @test usages[1].blueprint == cb
    @test 2 <= usages[1].units <= 5
    @test usages[2].blueprint == pb
    @test 1 <= usages[2].units <= 2

    wants = process_wants(needs, Entities())
    @test length(wants) == 2
    @test wants[1].blueprint == pb
    @test wants[1].units == 1
    @test wants[2].blueprint == cb
    @test 1 <= wants[2].units <= 2
end

@testset "Actor" begin
    # Blueprints
    cb = ConsumableBlueprint("Consumable")
    pb = ProductBlueprint("Product")

    #Products
    pb1 = ProducerBlueprint("Producer 1", max_production = 1)
    pb1.batch[cb] = 3
    p1 = Producer(pb1)

    pb2 = ProducerBlueprint("Producer 2", max_production = 1)
    pb2.batch[pb] = 1
    p2 = Producer(pb2)

    # Needs
    needs = Needs()
    push_usage!(needs, cb, Marginality([(2, 1), (5, 0.5)]), priority = 1)
    push_usage!(needs, pb, Marginality([(1, 1), (2, 0.1)]), priority = 2)

    posessions = Entities()
    push!(posessions, Consumable(cb))
    balance = Balance()
    book_asset!(balance, BalanceEntry("C"), 100)
    person = Actor(1, PERSON, [p1, p2], needs, posessions = posessions, balance = balance)

    @test length(person.producers) == 2
    @test p1 in person.producers
    @test p2 in person.producers
end

@testset "Model" begin
    # prices = Dict{Blueprint, Price}()
    # properties = default_properties()
    # properties[:SuMSy] = SuMSy(2000, 25000, 0.1, 30, seed = 5000)
    # properties[:prices] = prices
    # model = ABM(Person, properties = properties)
    #
    # for n in 1:20
    #     add_agent!(model)
    # end

    # step!(model, agent_step!, model_step!, 100000, false)
end
