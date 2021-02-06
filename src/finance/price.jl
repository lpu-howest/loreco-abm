"""
    Price - a composite price consisting of one or more price components, each associated with a specific balance entry.

Price is a type alias for Dict{BalanceEntry, Real}
"""
Price = Dict{BalanceEntry, Real}

"""
    pay!(buyer::Balance,
        seller::Balance,
        price::Price,
        timestamp::Integer;
        comment::String = "")

# Returns
A boolean indicating whether the price was paid in full.
"""
function pay!(buyer::Balance,
            seller::Balance,
            price::Price,
            timestamp::Integer = 0;
            comment::String = "")
    for entry in keys(price)
        queue_asset_transfer!(buyer, seller, entry, price[entry])
    end

    return execute_transfers!(buyer)
end
