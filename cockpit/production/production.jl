module Production

include("entities.jl")

export Direction, down, up
export Lifecycle, SingleUse, Restorable
export Identity
export Entities, Entity, Product, Enhancer, Consumable, Tool, Producer
export push!, pop!
export Blueprint, ConsumableBlueprint, ToolBlueprint, ProducerBlueprint
export health, id, type_id, get_name, is_type
export use!, produce!, damage!, restore!

end
