module BalanceSheet

using UUIDs

import Base: ==

export EntryType, BalanceEntry, Balance, EQUITY
export validate, asset, liability, assets, liabilities, asset_value, assets_value, liability_value, liabilities_value, liabilities_net_value, equity
export book_asset!, book_liability!, transfer!, transfer_asset!, transfer_liability!

@enum EntryType asset liability

struct BalanceEntry
    id::UUID
    name::String
    BalanceEntry(name::String) = new(uuid4(), name)
end

EQUITY = BalanceEntry("Equity")

==(e1::BalanceEntry, e2::BalanceEntry) = e1.id == e2.id

Base.show(io::IO, entry::BalanceEntry) = print(io, "BalanceEntry($(entry.name))")

struct Balance
    balance::Dict{EntryType, Dict{BalanceEntry, Float64}}
    Balance() = new(Dict(asset => Dict{BalanceEntry, Float64}(), liability => Dict{BalanceEntry, Float64}(EQUITY => 0)))
end

Base.show(io::IO, b::Balance) = print(io, "Balance(Assets: $(b.balance[asset]), Liabilities: $(b.balance[liability]))")

validate(b::Balance) = sum(values(b.balance[asset])) == sum(values(b.balance[liability]))
asset_value(b::Balance, entry::BalanceEntry) = b.balance[asset][entry]
liability_value(b::Balance, entry::BalanceEntry) = b.balance[liability][entry]
assets(b::Balance) = collect(keys(b.balance[asset]))
liabilities(b::Balance) = collect(keys(b.balance[liability]))
assets_value(b::Balance) = sum(values(b.balance[asset]))
liabilities_value(b::Balance) = sum(values(b.balance[liability]))
liabilities_net_value(b::Balance) = liabilities_value(b) - equity(b)
equity(b::Balance) = b.balance[liability][EQUITY]

function book_amount!(entry::BalanceEntry, dict::Dict{BalanceEntry, Float64}, amount::Real)
    if entry in keys(dict)
        dict[entry] += amount
    else
        dict[entry] = amount
    end
end

function book_asset!(b::Balance, entry::BalanceEntry, amount::Real)
    book_amount!(entry, b.balance[asset], amount)
    book_amount!(EQUITY, b.balance[liability], amount)
    return asset_value(b, entry)
end

function book_liability!(b::Balance, entry::BalanceEntry, amount::Real)
    book_amount!(entry, b.balance[liability], amount)
    book_amount!(EQUITY, b.balance[liability], -amount)
    return liability_value(b, entry)
end

transfer_functions = Dict(asset => book_asset!, liability => book_liability!)
value_functions = Dict(asset => asset_value, liability => liability_value)

function transfer!(b1::Balance, type1::EntryType, b2::Balance, type2::EntryType, entry::BalanceEntry, amount::Real)
    transfer_functions[type1](b1, entry, -amount)
    transfer_functions[type2](b2, entry, amount)

    return value_functions[type1](b1, entry), value_functions[type2](b2, entry)
end

function transfer_asset!(b1::Balance, b2::Balance, entry::BalanceEntry, amount::Real)
    transfer!(b1, asset, b2, asset, entry, amount)
end

function transfer_liability!(b1::Balance, b2::Balance, entry::BalanceEntry, amount::Real)
    transfer!(b1, liability, b2, liability, entry, amount)
end

end
