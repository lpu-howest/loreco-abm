using Test
using Main.Types
using Main.Production
using Main.Finance
using Main.ABM_Sim
using Agents
using DataStructures

@testset "Marginality" begin
    m = Marginality([(5, 0.1), (1, 1)])

    @test typeof(m) == SortedSet{Tuple{Int64,Percentage},Base.Order.ForwardOrdering}
    @test length(m) == 2
    @test first(m) == (1, 1)
    @test last(m) == (5, 0.1)
end

@testset "Actor" begin
    cb = ConsumableBlueprint("C")
    pb1 = ProducerBlueprint("P1")
    p1 = Producer(pb1)
    pb2 = ProducerBlueprint("P2")
    p2 = Producer(pb2)
    needs = Dict(cb => ())
    wants = Dict(cb => [(2, 1), (5, 0.5)])
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
    prices = Dict{Blueprint, BigFloat}()
    properties = default_properties()
    properties[:SuMSy] = SuMSy(2000, 25000, 0.1, 30, seed = 5000)
    properties[:prices] = prices
    properties = Dict(:SuMSy => ,
                    :prices => prices,
                    :step => -1)
    model = ABM(Person, properties = properties)

    for n in 1:20
        add_agent!(model)
    end

    step!(model, agent_step!, model_step!, 100000, false)
end
