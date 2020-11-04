struct Percentage <: Real
    value::Float64
    Percentage(x) = x < 0 ? 0 : x > 1 ? 1 : new(round(x, digits = 6))
end

Base.show(io::IO, x::Percentage) = print(io, "$(round(x.value * 100, digits = 6))%")

Base.convert(::Type{Percentage}, x::Real) = Percentage(x)
Base.convert(::Type{Percentage}, x::Percentage) = x

Base.promote_rule(::Type{T}, ::Type{Percentage}) where T <: Real = Percentage

import Base: +, -, <, >, <=, >=, ==

+(x::Percentage, y::Percentage) = Percentage(x.value + y.value)
-(x::Percentage) = Percentage(-x.value)
-(x::Percentage, y::Percentage) = Percentage(x.value - y.value)
<(x::Percentage, y::Percentage) = x.value < y.value
<=(x::Percentage, y::Percentage) = x.value <= y.value
>(x::Percentage, y::Percentage) = x.value > y.value
>=(x::Percentage, y::Percentage) = x.value >= y.value
==(x::Percentage, y::Percentage) = x.value == y.value

Base.max(x::Percentage, y::Percentage) = Percentage(max(x.value, y.value))
Base.min(x::Percentage, y::Percentage) = Percentage(min(x.value, y.value))
