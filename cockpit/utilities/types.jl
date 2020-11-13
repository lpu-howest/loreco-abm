module Types

export Percentage, Health

struct Percentage <: Real
    value::Float64
    Percentage(x) = x < 0 ? new(0) : x > 1 ? new(1) : new(x)
end

Base.show(io::IO, x::Percentage) = print(io, "Percentage($(x.value * 100)%)")

Base.convert(::Type{Percentage}, x::Real) = Percentage(x)
Base.convert(::Type{Percentage}, x::Percentage) = x

Base.promote_rule(::Type{T}, ::Type{Percentage}) where T <: Real = Percentage
Base.round(x::Percentage; digits::Integer = 0, base = 10) = Percentage(round(value(x), digits = digits, base = base))

mutable struct Health
    current::Percentage
    Health(current=1) = new(current)
end

value(x::Percentage) = x.value
value(x::Health) = value(x.current)

import Base: +, -, *, /, <, >, <=, >=, ==, max, min

for type in (Percentage, Health)
    for op in (:+, :-, :*, :/, :max, :min)
        eval(quote
            Base.$op(x::$type, y::$type) = $type($op(value(x), value(y)))
            Base.$op(x::$type, y::Real) = $type($op(value(x), y))
            Base.$op(x::Real, y::$type) = $type($op(x, value(y)))
        end)
    end

    for op in (:<, :<=, :>, :>=)
        eval(quote
            Base.$op(x::$type, y::$type) = $op(value(x), value(y))
            Base.$op(x::$type, y::Real) = $op(value(x), y)
            Base.$op(x::Real, y::$type) = $op(x, value(y))
        end)
    end

    eval(quote
        ==(x::$type, y::$type) = value(x) == value(y)
        ==(x::$type, y::Real) = value(x) == y
        ==(x::Real, y::$type) = x == value(y)
    end)
end

end
