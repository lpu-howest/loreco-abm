using Test
using Main.BalanceSheet

@testset "Balance" begin
    b = Balance()
    asset1 = BalanceEntry("Asset 1")
    asset2 = BalanceEntry("Asset 2")
    liability1 = BalanceEntry("Liability 1")
    liability2 = BalanceEntry("Liability 2")

    @test assets_value(b) == 0
    @test liabilities_value(b) == 0
    @test equity(b) == 0
    @test validate(b)

    book_asset!(b, asset1, 10)
    @test asset_value(b, asset1) == 10
    @test assets_value(b) == 10
    @test liabilities_value(b) == 10
    @test liabilities_net_value(b) == 0
    @test equity(b) == 10
    @test validate(b)

    book_liability!(b, liability1, 10)
    @test liability_value(b, liability1) == 10
    @test assets_value(b) == 10
    @test liabilities_value(b) == 10
    @test liabilities_net_value(b) == 10
    @test equity(b) == 0
    @test validate(b)

    book_asset!(b, asset2, 5)
    @test asset_value(b, asset2) == 5
    @test assets_value(b) == 15
    @test liabilities_value(b) == 15
    @test liabilities_net_value(b) == 10
    @test equity(b) == 5
    @test validate(b)

    book_liability!(b, liability2, 1)
    @test liability_value(b, liability2) == 1
    @test assets_value(b) == 15
    @test liabilities_value(b) == 15
    @test liabilities_net_value(b) == 11
    @test equity(b) == 4
    @test validate(b)
end

@testset "Transfers" begin
    a = BalanceEntry("Asset")
    l = BalanceEntry("Liability")
    d = BalanceEntry("Dual")

    b1 = Balance()
    book_asset!(b1, a, 10)
    book_liability!(b1, l, 10)
    book_asset!(b1, d, 20)
    book_liability!(b1, d, 20)

    b2 = Balance()

    transfer_asset!(b1, b2, a, 5)
    @test asset_value(b1, a) == 5
    @test asset_value(b2, a) == 5

    transfer_liability!(b1, b2, l, 1)
    @test liability_value(b1, l) == 9
    @test liability_value(b2, l) == 1

    transfer!(b1, asset, b2, liability, d, 2)
    transfer!(b1, liability, b2, asset, d, 3)
    @test asset_value(b1, d) == 18
    @test liability_value(b1, d) == 17
    @test asset_value(b2, d) == 3
    @test liability_value(b2, d) == 2
end
