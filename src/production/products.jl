
using UUIDs

INF = 2^63 - 1 # Indicates infinity for Int64

abstract type Enhancer <: Entity end

struct Consumable <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::SingleUse
    Consumable(blueprint) = new(uuid4(), blueprint, SingleUse())
end

Base.show(io::IO, e::Consumable) = print(io, "Consumable(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(e.blueprint)))")

struct Product <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::Restorable
    Product(blueprint) = new(uuid4(), blueprint, copy_lifecycle(blueprint))
end

Base.show(io::IO, e::Product) = print(io, "Product(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(e.blueprint)))")

"""
    Producer

An Entity with the capability to produce other Entities.

# Fields
- `id`: The id of the Producer.
- `lifecycle`: The lifecycle of the Producer.
- `blueprint`: The blueprint the producer is based on.
"""
struct Producer <: Entity
    id::UUID
    blueprint::Blueprint
    lifecycle::Restorable
    Producer(
        blueprint::Blueprint
    ) = new(uuid4(), blueprint, copy_lifecycle(blueprint))
end

Base.show(io::IO, e::Producer) = print(
    io,
    "Producer(Name: $(get_name(e)), Health: $(health(e)), Blueprint: $(e.blueprint))",
)

==(x::Entity, y::Entity) = x.id == y.id

get_blueprint(entity::Entity) = entity.blueprint
type_id(entity::Entity) = type_id(get_blueprint(entity))
is_type(entity::Entity, blueprint::Blueprint) = type_id(entity) == type_id(blueprint)
get_name(entity::Entity) = get_name(get_blueprint(entity))
id(entity::Entity) = entity.id
health(entity::Entity) = health(entity.lifecycle)

ENTITY_CONSTRUCTORS = Dict(ConsumableBlueprint => Consumable, ProductBlueprint => Product, ProducerBlueprint => Producer)

function use!(entity::Entity)
    use!(entity.lifecycle)
    return entity
end

function extract!(requirements::Dict{B,Int64}, source::Entities, max::Int = INF) where {B <: Blueprint}
    extracting = true
    extracted = 0

    if !isempty(requirements)
        while extracted < max && extracting
            res_available = true

            for bp in keys(requirements)
                res_available &= bp in keys(source) && length(source[bp]) >= requirements[bp]
            end

            if res_available
                for bp in keys(requirements)
                    i = 1

                    for product in collect(source[bp])
                        if i <= requirements[bp]
                            use!(product)
                            i += 1

                            if health(product) == 0
                                delete!(source, product)
                            end
                        else
                            break
                        end
                    end
                end

                extracted += 1
            else
                extracting = false
            end
        end
    end

    return extracted
end

"""
    produce!

Produces batch based on the producer and the provided resouces. The maximum possible batch is generated. The used resources are removed from the resources Dict and produced Entities are added to the products Dict.

# Returns
A named tuple {products::Entities, resources::Entities, batches::Int64} where
* products = produced entities
* resources = leftover resources
* batches = number of produced batches
"""
function produce!(producer::Producer,
                resources::Entities = Entities();
                max_production = INF)
    products = Entities()

    if health(producer) > 0
        bp = get_blueprint(producer)

        if isempty(bp.batch_req)
            production = min(max_production, bp.max_production)
        else
            production = extract!(bp.batch_req, resources, min(bp.max_production, max_production))
        end

        if production > 0
            for i in 1:production
                for prod_bp in keys(bp.batch)
                    for j in 1:bp.batch[prod_bp]
                        product = ENTITY_CONSTRUCTORS[typeof(prod_bp)](prod_bp)
                        push!(products, ENTITY_CONSTRUCTORS[typeof(prod_bp)](prod_bp))
                    end
                end
            end

            use!(producer)
        end
    end

    return (products = products, batches = production)
end

function damage!(entity::Entity, damage::Real)
    damage!(entity.lifecycle, damage)

    return entity
end

function restore!(consumable::Consumable, resources::Entities = Entities())
    return consumable
end

function restore!(entity::Entity, resources::Entities = Entities())
    bp = get_blueprint(entity)

    if isempty(bp.restore_res) || extract!(bp.restore_res, resources, 1) > 0
        restore!(entity.lifecycle, bp.restore)
    end

    return entity
end
