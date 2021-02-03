module Finance

include("balance.jl")
export EntryType, BalanceEntry, Balance
export EQUITY, asset, liability
export validate, assets, liabilities, asset_value, assets_value, liability_value, liabilities_value, liabilities_net_value, equity
export book_asset!, book_liability!, transfer!, transfer_asset!, transfer_liability!

include("sumsy.jl")
export SUMSY_DEP
export SuMSy
export calculate_demurrage, process_sumsy!, sumsy_balance, sumsy_transfer!
export set_guaranteed_income!, has_guaranteed_income, dem_free, transfer_dem_free

include("debt.jl")
export DEPOSIT, DEBT
export Debt, borrow, process_debt!

end
