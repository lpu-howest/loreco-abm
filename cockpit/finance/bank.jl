include("financial_entity.jl")
include("balance.jl")

using UUIDs

mutable struct Debt
    id::UUID
    debtor::FinancialEntity
    amount::BigFloat
    installments::Int64
end

struct Bank <: FinancialEntity
    balance::Balance
    debts::Vector{Debt}
end

function process_debt(bank::Bank)
    for debt in bank.debts

    end
end
