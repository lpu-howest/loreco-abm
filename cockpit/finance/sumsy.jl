using Main.Types

SUMSY_DEP = BalanceEntry("SuMSy deposit")

"""
    struct SuMSy

Representation of the parameters of a SuMSy implementation.

* guaranteed_income: the periodical guaranteed income.
* dem_tiers: the demurrage tiers. This is a list of tuples consisting of a lower bound and a demurrage percantage. The demurrage percentage is applied to the amounts larger than the lower bound up to the the next higher lower bound.
* interval: the size of the period after which the next demurrage is calculated and the next guaranteed income is issued.
* seed: the amount whith which new accounts start.
"""
mutable struct SuMSy
    guaranteed_income::BigFloat
    dem_tiers::Vector{Tuple{BigFloat, Percentage}}
    interval::Int64
    seed::BigFloat
    SuMSy(guaranteed_income::Real,
        dem_tiers::Vector{Tuple{T1, T2}},
        interval::Integer;
        seed::Real = 0) where {T1, T2 <: Real} = new(guaranteed_income,
                        sort(Vector{Tuple{BigFloat, Percentage}}(dem_tiers)),
                        interval,
                        seed)
end

"""
    SuMSy(guaranteed_income::BigFloat, dem_free_buffer::BigFloat, dem::Percentage)

Create a SuMSy struct with 1 demurrage tier.
"""
function SuMSy(guaranteed_income::Real,
            dem_free_buffer::Real,
            dem::Real,
            interval::Integer;
            seed::Real = 0)
    return SuMSy(guaranteed_income, Vector{Tuple{Real, Real}}([(dem_free_buffer, dem)]), interval, seed = seed)
end

"""
    calculate_demurrage(sumsy::SuMSy, balance::Balance, timestamp::Int64)

Calculates the demurrage due at the current timestamp. This is not restricted to timestamps which correspond to multiples of the SuMSy interval.
"""
function calculate_demurrage(sumsy::SuMSy, balance::Balance, step::Int)
    transactions = balance.transactions
    cur_balance = asset_value(balance, SUMSY_DEP)
    period = mod(step, sumsy.interval)
    period_start = step - period
    weighted_balance = 0
    i = length(transactions)
    t_step = step

    while i > 0 && transactions[i][1] >= period_start
        t_step = transaction[i][1]
        amount = 0

        while i > 0 && tranactions[i][1] == t_step
            t = transactions[i]

            if t[2] == asset && t[3] == SUMSY_DEP
                amount += t[4]
            end

            i -= 1
        end

        weighted_balance += (step - t_step) * cur_balance
        step = t_step
        cur_balance -= amount
    end

    if t_step > period_start
        weighted_balance += (t_step - period_start) * cur_balance
    end

    avg_balance = weighted_balance / period
    demurrage = 0
    dem_tiers = sumsy.dem_tiers
    i = length(dem_tiers)

    while i > 0
        tier = dem_tiers[i]
        i -= 1

        if avg_balance > tier[1]
            demurrage += (avg_balance - tier[1]) * tier[2]
            avg_balance = tier[1]
        end
    end

    return demurrage
end

"""
    process_sumsy!(sumsy::SuMSy, timestamp::Int64, balance::Balanace)

Processes demurrage and guaranteed income if the timestamp is a multiple of the SuMSy interval. Otherwise this function does nothing. Returns the deposited guaranteed income amount and the subtracted demurrage. When this function is called with timestamp == 0, the balance will be 'seeded'. The seed amount is added to the returned income.

* sumsy: the SuMSy implementation to use for calculations.
* balance: the balance on which to apply SuMSy.
* timestamp: the current timestamp. Used to determine whether action needs to be taken.
"""
function process_sumsy!(sumsy::SuMSy, balance::Balance, cur_time::Int)
    income = 0
    demurrage = 0

    if mod(cur_time, sumsy.interval) == 0
        if cur_time == 0
            income += sumsy.seed
        end

        income += sumsy.guaranteed_income
        demurrage = calculate_demurrage(sumsy, balance, cur_time)

        book_asset!(balance, SUMSY_DEP, income, cur_time)
        book_asset!(balance, SUMSY_DEP, demurrage, cur_time)
    end

    return income, demurrage
end

function sumsy_balance(balance)
    return asset_value(balance, SUMSY_DEP)
end

"""
    sumsy_transfer(source::Balance, destination::Balance, amount::BigFloat)

Transfer an amount of SuMSy money from one balance sheet to another. No more than the available amount of money can e transferred.
"""
function sumsy_transfer!(source::Balance, destination::Balance, amount::Real, timestamp::Int = 0)
    amount = max(0, min(amount, asset_value(source, SUMSY_DEP)))
    transfer_asset!(source, destination, SUMSY_DEP, amount, timestamp)
end
