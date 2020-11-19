module Production

include("entities.jl")

export Direction, down, up
export Lifecycle, SingleUse, Restorable
export Identity
export Entity, Product, Enhancer, Consumable, Tool, Producer
export BluePrint, ConsumableBluePrint, ToolBluePrint, ProducerBluePrint
export health, id, type_id, name_of, use!, produce!, do_maintenance!

end
