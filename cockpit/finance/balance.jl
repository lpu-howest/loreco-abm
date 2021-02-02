using UUIDs
using Main.Types

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
* transactions: a chronological list of transaction tuples. Each tuple is constructed as follows: timestamp, entry type (asset or liability), balance entry, amount, comment.
* properties: a dict with user defined properties. If the key of the dict is a Symbol, the value can be retrieved/set by balance.symbol.
"""
struct Balance
    balance::Dict{EntryType, Dict{BalanceEntry, Float64}}
    transactions::Vector{Tuple{Int64, EntryType, BalanceEntry, Float64, String}}
    properties::Dict
    Balance(;properties = Dict()) = new(Dict(asset => Dict{BalanceEntry, Float64}(), liability => Dict{BalanceEntry, Float64}(EQUITY => 0)), Vector{Tuple{Int64, EntryType, BalanceEntry, Float64}}(), properties)
end

Base.show(io::IO, b::Balance) = print(io, "Balance(\nAssets:\n$(b.balance[asset]) \nLiabilities:\n$(b.balance[liability]) \nTransactions:\n$(b.transactions))")

function Base.getproperty(balance::Balance, s::Symbol)
    properties = getfield(balance, :properties)

    if s in keys(properties)
        return properties[s]
    elseif s in fieldnames(Balance)
        return getfield(balance, s)
    else
        return nothing
    end
end

function Base.setproperty!(balance::Balance, s::Symbol, value)
    if s in fieldnames(Balance)
        setfield!(balance, s, value)
    else
        balance.properties[s] = value
    end

    return value
end

validate(b::Balance) = sum(values(b.balance[asset])) == sum(values(b.balance[liability]))
asset_value(b::Balance, entry::BalanceEntry) = entry_value(b.balance[asset], entry)
liability_value(b::Balance, entry::BalanceEntry) = entry_value(b.balance[liability], entry)
assets(b::Balance) = collect(keys(b.balance[asset]))
liabilities(b::Balance) = collect(keys(b.balance[liability]))
assets_value(b::Balance) = sum(values(b.balance[asset]))
liabilities_value(b::Balance) = sum(values(b.balance[liability]))
liabilities_net_value(b::Balance) = liabilities_value(b) - equity(b)
equity(b::Balance) = b.balance[liability][EQUITY]

function entry_value(dict::Dict{BalanceEntry, Float64}, entry::BalanceEntry)
    if entry in keys(dict)
        return dict[entry]
    else
        return Float64(0)
    end
end

function book_amount!(entry::BalanceEntry, dict::Dict{BalanceEntry, Float64}, amount::Real; digits = 2)
    if entry in keys(dict)
        dict[entry] += round(amount, digits = digits)
    else
        dict[entry] = round(amount, digits = digits)
    end
end

function book_asset!(b::Balance, entry::BalanceEntry, amount::Real, timestamp::Int = 0; comment = "", digits = 2)
    book_amount!(entry, b.balance[asset], amount, digits = digits)
    book_amount!(EQUITY, b.balance[liability], amount, digits = digits)
    push!(b.transactions, (timestamp, asset, entry, amount, comment))
    return asset_value(b, entry)
end

function book_liability!(b::Balance, entry::BalanceEntry, amount::Real, timestamp::Int = 0; comment = "", digits = 2)
    book_amount!(entry, b.balance[liability], amount, digits = digits)
    book_amount!(EQUITY, b.balance[liability], -amount, digits = digits)
    push!(b.transactions, (timestamp, liability, entry, amount, comment))
    return liability_value(b, entry)
end

transfer_functions = Dict(asset => book_asset!, liability => book_liability!)
value_functions = Dict(asset => asset_value, liability => liability_value)

function transfer!(b1::Balance, type1::EntryType, b2::Balance, type2::EntryType, entry::BalanceEntry, amount::Real, timestamp::Int = 0; comment = "", digits = 2)
    transfer_functions[type1](b1, entry, -amount, timestamp, comment = comment, digits = digits)
    transfer_functions[type2](b2, entry, amount, timestamp, comment = comment, digits = digits)

    return value_functions[type1](b1, entry), value_functions[type2](b2, entry)
end

function transfer_asset!(b1::Balance, b2::Balance, entry::BalanceEntry, amount::Real, timestamp::Int = 0; comment = "", digits = 2)
    transfer!(b1, asset, b2, asset, entry, amount, timestamp, comment = comment, digits = digits)
end

function transfer_liability!(b1::Balance, b2::Balance, entry::BalanceEntry, amount::Real, timestamp::Int = 0; comment = "", digits = 2)
    transfer!(b1, liability, b2, liability, entry, amount, timestamp, comment = comment, digits = digits)
end
