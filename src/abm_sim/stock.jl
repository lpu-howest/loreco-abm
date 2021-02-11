using ..Utilities
using ..Production

struct Stock
    stock::Entities
    stock_limits::Dict{Blueprint, Tuple{Int64, Int64}}
    Stock() = new(Entities(), Dict{Blueprint, Tuple{Int64, Int64}}())
end

current_stock(stock::Stock, bp::Blueprint) = num_entities(stock.stock, bp)

function stock_limits(stock::Stock, bp::Blueprint)
    stock_limits = stock.stock_limits

    if bp in keys(stock_limits)
        return stock_limits[bp]
    else
        return (0, INF)
    end
end

stock_limits!(stock::Stock, bp::Blueprint, min_units::Integer, max_units::Integer) = stock.stock_limits[bp] = (min_units, max_units)

min_stock(stock::Stock, bp::Blueprint) = stock_limits(stock, bp)[1]
min_stock!(stock::Stock, bp::Blueprint, units::Integer) = stock_limits!(stock, bp, units, max_stock(stock, bp))

max_stock(stock::Stock, bp::Blueprint) = stock_limits(stock, bp)[2]
max_stock!(stock::Stock, bp::Blueprint, units::Integer) = stock_limits!(stock, bp, min_stock(stock, bp), units)

function add_stock!(stock::Stock, products::Set{E}) where E <: Entity
    for product in collect(products)
        bp = get_blueprint(product)

        if current_stock(stock, bp) < max_stock(stock, bp)
            pop!(products, product)
            push!(stock.stock, product)
        end
    end

    return stock
end

function add_stock!(stock::Stock, products::AbstractVector{E}) where {E <: Entity}
    product_set = Set(products)
    add_stock!(stock, product_set)
    empty!(products)
    union!(products, product_set)

    return stock
end

add_stock!(stock::Stock, product::Entity) = add_stock!(stock, Set([product]))

function retrieve_stock!(stock::Stock, bp::Blueprint, units::Integer)
    products = Set{Entity}()

    if bp in keys(stock.stock)
        i = 0

        for product in collect(stock.stock[bp])
            if i >= units
                break
            end

            delete!(stock.stock, product)
            push!(products, product)
            i += 1
        end
    end

    return products
end

stocked(stock::Stock, bp::Blueprint) = current_stock(stock, bp) >= min_stock(stock, bp)
overstocked(stock::Stock, bp::Blueprint) = current_stock(stock, bp) > max_stock(stock, bp)

Base.isempty(stock::Stock) = isempty(stock.stock)
Base.empty(stock::Stock) = empty(stock.stock)
Base.empty!(stock::Stock) = empty!(stock.stock)

function reset(stock::Stock)
    empty!(stock)
    empty!(stock.stock_limits)

    return stock
end