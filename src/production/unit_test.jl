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
    @test r.damage_thresholds == Thresholds([(1, 1.0)])
    @test r.restoration_thresholds == Thresholds([(1, 1.0)])

    r = Restorable(
        0.8,
        damage_thresholds = [(1, 1), (0.8, 2)],
        restoration_thresholds = [(1, 2), (0.6, 1), (0.2, 0)],
        wear = 0.1,
    )
    @test health(r) == 0.8
    @test health(use!(r)) == 0.6
    @test health(use!(r)) == 0.4
    @test health(restore!(r, 0.1)) == 0.5
    @test health(restore!(r, 0.2)) == 0.8
    @test health(damage!(r, 0.1)) == 0.6
end

@testset "Consumable" begin
    name = "Food"
    bp = ConsumableBlueprint(name)
    f1 = Consumable(bp)
    f2 = Consumable(bp)
    @test get_blueprint(f1).name == name
    @test get_name(f1) == name
    @test typeof(id(f1)) == Base.UUID
    @test typeof(type_id(f1)) == Base.UUID
    @test id(f1) != type_id(f1)
    @test type_id(f1) == type_id(f2)
    @test id(f1) != id(f2)
    @test health(f1) == 1
    @test health(use!(f1)) == 0
    @test health(restore!(f1)) == 0
    @test health(f2) == 1
    @test health(restore!(f2)) == 1
    @test health(use!(f2)) == 0
end

@testset "Product" begin
    name = "Hammer"
    bp = ProductBlueprint(name, Restorable(1, wear = 0.1), restore = 0.1)
    t1 = Product(bp)
    t2 = Product(bp)
    @test get_blueprint(t1).name == name
    @test get_name(t1) == name
    @test typeof(id(t1)) == Base.UUID
    @test typeof(type_id(t1)) == Base.UUID
    @test id(t1) != type_id(t1)
    @test type_id(t1) == type_id(t2)
    @test id(t1) != id(t2)
    @test health(t1) == 1
    @test health(use!(t1)) == 0.9
    @test health(restore!(t1)) == 1
end


@testset "Producer" begin
    labour_bp = ConsumableBlueprint("Labour")
    machine_bp = ProductBlueprint("Machine", Restorable(wear = 0.1))
    food_bp = ConsumableBlueprint("Food")
    factory_bp = ProducerBlueprint(
        "Factory",
        batch_req = Dict(labour_bp => 2, machine_bp => 1),
        batch = Dict(food_bp => 1)
    )

    resources = Entities(Dict{Blueprint,Vector{Entity}}(labour_bp => [Consumable(labour_bp), Consumable(labour_bp)], machine_bp => [Product(machine_bp)]))
    factory = Producer(factory_bp)

    products = produce!(factory, resources)

    @test !(labour_bp in keys(resources))
    @test machine_bp in keys(resources)
    @test health(resources[machine_bp][1]) == 0.9
    @test length(products[food_bp]) == 1
    @test get_name(products[food_bp][1]) == "Food"
    @test typeof(products[food_bp][1]) == Consumable
end

@testset "Entities" begin
    e = Entities()
    cb = ConsumableBlueprint("Consumable")
    pb = ProductBlueprint("Product", Restorable(wear = 0.1))
    c = Consumable(cb)
    p1 = Product(pb)
    p2 = Product(pb)
    push!(e, c)
    push!(e, p1)
    push!(e, p2)
    @test length(e[cb]) == 1
    @test length(e[pb]) == 2
    use!(e[pb][1])
    @test health(e[pb][1]) == 0.9
end

@testset "extract!" begin
    e = Entities()
    cb = ConsumableBlueprint("Consumable")
    pb = ProductBlueprint("Product", Restorable(wear = 0.1))
    c = Consumable(cb)
    p1 = Product(pb)
    p1.lifecycle.health.current = 0.1
    @test health(p1) == 0.1
    p2 = Product(pb)
    push!(e, c)
    push!(e, p1)
    push!(e, p2)
    req = Dict(cb => 1, pb => 2)
    @test Production.extract!(req, e) == 1
    @test length(keys(e)) == 1
    @test !(cb in keys(e))
    @test health(e[pb][end]) == 0.9
end
