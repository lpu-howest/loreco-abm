module Production

include("lifecycle.jl")
# include "entities.jl"
# include "blueprint.jl"

export Direction, down, up, Lifecycle, SingleUse, Restorable, health, use!, damage!, restore!
export Identity, Entity, Product, Producer, Enhancer

end
