import Base: ==

using UUIDs

abstract type Blueprint end

struct ConsumableBlueprint <: Blueprint
    type_id::UUID
    name::String
    ConsumableBlueprint(name::String) = new(uuid4(), name)
end

Base.show(io::IO, bp::ConsumableBlueprint) =
    print(io, "ConsumableBlueprint(Name: $(get_name(bp)))")

struct ProductBlueprint <: Blueprint
    type_id::UUID
    name::String
    lifecycle::Restorable
    restore_res::Dict{<:Blueprint,Int64}
    restore::Float64
    ProductBlueprint(name::String,
        lifecycle::Restorable = Restorable();
        restore_res::Dict{<:Blueprint,Int64} = Dict{Blueprint,Int64}(),
        restore::Real = 0) = new(uuid4(), name, lifecycle, restore_res, restore)
end

Base.show(io::IO, bp::ProductBlueprint) =
    print(io, "ProductBlueprint(Name: $(get_name(bp)), $(bp.lifecycle), Restore res: $(bp.restore_res), Restore: $(bp.restore))")

struct ProducerBlueprint <: Blueprint
    type_id::UUID
    name::String
    lifecycle::Restorable
    restore_res::Dict{<:Blueprint,Int64}
    restore::Float64
    batch_req::Dict{<:Blueprint,Int64} # Required input per batch
    batch::Dict{<:Blueprint,Int64} # output per batch. The Blueprint and the number of items per blueprint.
    max_production::Int64 # Max number of batches per production cycle

    ProducerBlueprint(
        name::String,
        lifecycle::Restorable = Restorable();
        restore_res::Dict{<:Blueprint,Int64} = Dict{Blueprint,Int64}(),
        restore::Real = 0,
        batch_req::Dict{<:Blueprint,Int64} = Dict{Blueprint,Int64}(),
        batch::Dict{<:Blueprint,Int64} = Dict{Blueprint,Int64}(),
        max_production::Int64 = 1
    ) = new(uuid4(), name, lifecycle, restore_res, restore, batch_req, batch, max_production)
end

Base.show(io::IO, bp::ProducerBlueprint) = print(
    io,
    "ProducerBlueprint(Name: $(get_name(bp)), $(bp.lifecycle), Restore res: $(bp.restore_res), Restore: $(bp.restore), Input: $(bp.batch_req), batch: $(bp.batch), Max batches: $(bp.max_production == INF ? "INF" : bp.max_production)")

type_id(blueprint::Blueprint) = blueprint.type_id
get_name(blueprint::Blueprint) = blueprint.name
copy_lifecycle(blueprint::Blueprint) = deepcopy(blueprint.lifecycle)

==(x::Blueprint, y::Blueprint) = type_id(x) == type_id(y)
