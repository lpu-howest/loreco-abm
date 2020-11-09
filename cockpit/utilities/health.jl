include("percentage.jl")

mutable struct Health <: Real
    current::Percentage
    Health(current=1) = new(current)
end

Base.convert(::Type{Health}, x::Real) = Health(x)
Base.convert(::Type{Health}, x::Health) = x

Base.promote_rule(::Type{T}, ::Type{Health}) where T <: Real = Health
Base.promote_rule(::Type{Health}, ::Type{Percentage}) = Health

import Base: +, -, <, >, <=, >=, ==

+(x::Health, y::Health) = Health(x.current + y.current)
-(x::Health) = Health(-x.current)
-(x::Health, y::Health) = Health(x.current - y.current)
<(x::Health, y::Health) = x.current < y.current
<=(x::Health, y::Health) = x.current <= y.current
>(x::Health, y::Health) = x.current > y.current
>=(x::Health, y::Health) = x.current >= y.current
==(x::Health, y::Health) = x.current == y.current

Base.max(x::Health, y::Health) = Health(max(x.current, y.current))
Base.min(x::Health, y::Health) = Health(min(x.current, y.current))
