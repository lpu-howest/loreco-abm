module Production

include("lifecycle.jl")
export Direction, down, up
export Thresholds, Lifecycle, SingleUse, Restorable
export health, use!, damage!, restore!

include("blueprint.jl")
export Blueprint, ConsumableBlueprint, ProductBlueprint, ProducerBlueprint
export type_id, get_name

include("entities.jl")
export Entities, Entity
export num_entities

include("stock.jl")
export Stock
export current_stock, stocked, overstocked, add_stock!, retrieve_stock!, min_stock, min_stock!, max_stock, max_stock!, stock_limits, stock_limits!

include("products.jl")
export Enhancer, Consumable, Product, Producer
export id, get_blueprint, is_type, produce!
export push!, pop!

end
