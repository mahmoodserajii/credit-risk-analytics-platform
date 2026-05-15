with normalized_transactions as (
    select
        transaction_id,
        account_origin_id,
        account_destination_id,
        amount,
        transaction_date,
        -- Rule 1: Round the amount to strip out small cent variances
        round(amount) as rounded_amount
    from {{ ref('stg_transactions') }}
    where is_future_transaction = false
),

transaction_intervals as (
    select
        *,
        -- Rule 2: Find the previous occurrence to the same recipient with the same rounded price
        lag(transaction_date) over(
            partition by account_origin_id, account_destination_id, rounded_amount
            order by transaction_date
        ) as previous_transaction_date
    from normalized_transactions
),

calculated_gaps as (
    select
        *,
        (transaction_date - previous_transaction_date) as days_since_last
    from transaction_intervals
)

select
    account_origin_id,
    account_destination_id,
    rounded_amount,
    count(*) as total_occurrences,
    avg(amount) as clean_avg_amount,
    
    -- Rule 3: Validate standard intervals (e.g., Monthly or Weekly cadences)
    case
        when count(*) >= 3 and avg(days_since_last) between 27 and 33 then 'monthly_recurring'
        when count(*) >= 4 and avg(days_since_last) between 6 and 8 then 'weekly_recurring'
        else 'irregular_pattern'
    end as recurring_cadence

from calculated_gaps
group by 1, 2, 3
