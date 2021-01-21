using UUIDs

import Base: ==

@enum EntryType asset liability

struct BalanceEntry
    id::UUID
    name::String
    BalanceEntry(name::String) = new(uuid4(), name)
end

EQUITY = BalanceEntry("Equity")

==(e1::BalanceEntry, e2::BalanceEntry) = e1.id == e2.id

Base.show(io::IO, entry::BalanceEntry) = print(io, "BalanceEntry($(entry.name))")

"""
    struct Balance

A balance sheet, including a history of transactions which led to the current state of the balance sheet.

* balance: the balance sheet.
* transactions: a chronological list of transaction tuples. Each tuple is constructed as follows: timestamp, entry type (asset or liability), balance entry, amount.
"""
struct Balance
    balance::Dict{EntryType, Dict{BalanceEntry, BigFloat}}
    transactions::Vector{Tuple{Int64, EntryType, BalanceEntry, BigFloat}}
    Balance() = new(Dict(asset => Dict{BalanceEntry, BigFloat}(), liability => Dict{BalanceEntry, BigFloat}(EQUITY => 0)))
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

function book_amount!(entry::BalanceEntry, dict::Dict{BalanceEntry, BigFloat}, amount::BigFloat)
    if entry in keys(dict)
        dict[entry] += amount
    else
        dict[entry] = amount
    end
end

function book_asset!(b::Balance, entry::BalanceEntry, amount::BigFloat, timestamp::Int = 0)
    book_amount!(entry, b.balance[asset], amount)
    book_amount!(EQUITY, b.balance[liability], amount)
    push!(b.transactions, (timestamp, asset, entry, amount))
    return asset_value(b, entry)
end

function book_liability!(b::Balance, entry::BalanceEntry, amount::BigFloat, timestamp::Int = 0)
    book_amount!(entry, b.balance[liability], amount)
    book_amount!(EQUITY, b.balance[liability], -amount)
    push!(b.transactions, (timestamp, liability, entry, amount))
    return liability_value(b, entry)
end

transfer_functions = Dict(asset => book_asset!, liability => book_liability!)
value_functions = Dict(asset => asset_value, liability => liability_value)

function transfer!(b1::Balance, type1::EntryType, b2::Balance, type2::EntryType, entry::BalanceEntry, amount::BigFloat, timestamp::Int = 0)
    transfer_functions[type1](b1, entry, -amount, timestamp)
    transfer_functions[type2](b2, entry, amount, timestamp)

    return value_functions[type1](b1, entry), value_functions[type2](b2, entry)
end

function transfer_asset!(b1::Balance, b2::Balance, entry::BalanceEntry, amount::BigFloat, timestamp::Int = 0)
    transfer!(b1, asset, b2, asset, entry, amount, timestamp)
end

function transfer_liability!(b1::Balance, b2::Balance, entry::BalanceEntry, amount::BigFloat, timestamp::Int = 0)
    transfer!(b1, liability, b2, liability, entry, amount, timestamp)
end
