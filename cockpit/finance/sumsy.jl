using Main.Types
export SUMSY_DEP

SUMSY_DEP = BalanceEntry("SuMSy deposit")

"""
    struct SuMSy

Representation of the parameters of a SuMSy implementation.

* guaranteed_income: the periodical guaranteed income.
* dem_free_buffer: the size of the demurrage free buffer.
* dem_tiers: the demurrage tiers. This is a list of tuples consisting of a lower bound and a demurrage percantage. The demurrage percentage is applied to the amounts larger than the lower bound up to the the next higher lower bound.
* interval: the size of the period after which the next demurrage is calculated and the next guaranteed income is issued.
* seed: the amount whith which new accounts start.
"""
mutable struct SuMSy
    guaranteed_income::BigFloat
    dem_free_buffer::BigFloat
    dem_tiers::Vector{Tuple{BigFloat, Percentage}}
    interval::Int64
    seed::BigFloat
    SuMSy(guaranteed_income::BigFloat, dem_free_buffer::BigFloat, dem_tiers::Vector{Percentage}, interval::Int64; seed::BigFloat = 0) = new(guaranteed_income, dem_free_buffer, sort(dem_tiers), interval, seed)
end

"""
    SuMSy(guaranteed_income::BigFloat, dem_free_buffer::BigFloat, dem::Percentage)

Create a SuMSy struct with 1 demurrage tier.
"""
function SuMSy(guaranteed_income::Real, dem_free_buffer::Real, dem::Percentage)
    return SuMSy(guaranteed_income, dem_free_buffer, [(dem_free_buffer, dem)])
end

"""
    calculate_demurrage(sumsy::SuMSy, balance::Balance, timestamp::Int64)

Calculates the demurrage due at the current timestamp. This is not restricted to timestamps which correspond to multiples of the SuMSy interval.
"""
function calculate_demurrage(sumsy::SuMSy, balance::Balance, cur_time::Int)
    transactions = balance.transactions
    cur_balance = asset_value(balance, SUMSY_DEP)
    period = mod(timestamp, sumsy.interval)
    period_start = cur_time - period
    weighted_balance = 0
    i = length(transactions)

    while i > 0 && transactions[i][1] >= period_start
        t_time = transaction[i][1]
        amount = 0

        while i > 0 && tranactions[i][1] == t_time
            t = transactions[i]

            if t[2] == asset && t[3] == SUMSY_DEP
                amount += t[4]
            end

            i -= 1
        end

        weighted_balance += (cur_time - t_time) * cur_balance
        cur_balance -= amount
    end

    if t_time > period_start
        weighted_balance += (t_time - period_start) * cur_balance
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

"""
    sumsy_transfer(source::Balance, destination::Balance, amount::BigFloat)

Transfer an amount of SuMSy money from one balance sheet to another. No more than the available amount of money can e transferred.
"""
function sumsy_transfer(source::Balance, destination::Balance, amount::BigFloat, timestamp::Int = 0)
    amount = max(0, min(amount, asset_value(source, SUMSY_DEP)))
    transfer_asset!(source, destination, SUMSY_DEP, amount, timestamp)
end
