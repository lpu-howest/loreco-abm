using Test
using Main.Types
using Main.Production

@testset "SingleUse" begin
    @test SingleUse().used == false
    @test use!(SingleUse()).used == true
    @test health(SingleUse()) == 1
    @test health(use!(SingleUse())) == 0
    @test health(damage!(SingleUse(), 0.01)) == 0
    @test health(restore!(damage!(SingleUse(), 0.01))) == 0
end

@testset "Restorable" begin
    r = Restorable()
    @test r.health == 1
    @test r.damage_thresholds == [(1, 1.0)]
    @test r.restoration_thresholds == [(1, 1.0)]

    r = Restorable(0.8,
        damage_thresholds = [(1, 1),(0.8, 2)],
        restoration_thresholds = [(1, 2), (0.6, 1), (0.2, 0)],
        wear = 0.1)
    @test health(r) == 0.8
    @test health(use!(r)) == 0.6
    @test health(use!(r)) == 0.4
    @test health(restore!(r, 0.1)) == 0.5
    @test health(restore!(r, 0.2)) == 0.8
    @test health(damage!(r, 0.1)) == 0.6
end

@testset "Consumable" begin
    name = "Food"
    blueprint = ConsumableBluePrint(name)
    f1 = Consumable(blueprint)
    f2 = Consumable(blueprint)
    @test f1.id.name == name
    @test name_of(f1) == name
    @test typeof(id(f1)) == Base.UUID
    @test typeof(type_id(f1)) == Base.UUID
    @test id(f1) != type_id(f1)
    @test type_id(f1) == type_id(f2)
    @test id(f1) != id(f2)
    @test health(f1) == 1
    @test health(use!(f1)) == 0
    @test health(restore!(f1, 0.1)) == 0
    @test health(f2) == 1
    @test health(restore!(f2, 0.1)) == 1
    @test health(damage!(f2, 0.1)) == 0
end

@testset "Tool" begin
    name = "Hammer"
    blueprint = ToolBluePrint(name, Restorable(1, wear = 0.1))
    t1 = Tool(blueprint)
    t2 = Tool(blueprint)
    @test t1.id.name == name
    @test name_of(t1) == name
    @test typeof(id(t1)) == Base.UUID
    @test typeof(type_id(t1)) == Base.UUID
    @test id(t1) != type_id(t1)
    @test type_id(t1) == type_id(t2)
    @test id(t1) != id(t2)
    @test health(t1) == 1
    @test health(use!(t1)) == 0.9
    @test health(restore!(t1, 0.1)) == 1
    @test health(damage!(t1, 0.1)) == 0.9
end