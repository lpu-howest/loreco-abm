module Production

include("entities.jl")

export Direction, down, up
export Lifecycle, SingleUse, Restorable
export Identity
export Entities, Entity, Enhancer, Consumable, Product, Producer
export push!, pop!
export Blueprint, ConsumableBlueprint, ProductBlueprint, ProducerBlueprint
export health, id, get_blueprint, type_id, get_name, is_type
export use!, produce!, damage!, restore!

end
