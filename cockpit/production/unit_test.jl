include("production.jl")

using Test
using Main.Types
using Main.Production

@testset "SingleUse" begin
    @test SingleUse().used == false
    @test use(SingleUse()).used == true
    @test health(SingleUse()) == 1
    @test health(use(SingleUse())) == 0
    @test health(damage!(SingleUse())) == 0
    @test health(restore!(damage!(SingleUse()))) == 0
end

@testset "Restorable" begin
    r = Restorable()
    @test r.health == 1
    @test r.damage_thresholds == [(1, 0.01)]
    @test r.restoration_thresholds == [(1, 0.01)]

    r = Restorable(0.8,
        damage_thresholds = [(1, 1),(0.8, 2)],
        restoration_thresholds = [(1, 2), (0.6, 1), (0.2, 0)],
        wear = 0.1)
    @test health(r) == 0.8
    @test health(use!(r)) == 0.6
    @test health(restore!(r, 0.1)) == 0.7
    @test health(restore!(r, 0.1)) == 0.9
    @test health(damage!(r, 0.3)) == 0.6 # TODO change! Damage must increase as soon as health falls to 0.8
end
