with trusted_transactions as (

    select *
    from {{ ref('stg_transactions') }}
    where is_future_transaction = false

),

transaction_stats as (

    select
        *,
        -- Calculate the "Normal" behavior for each specific account
        avg(amount) over (partition by account_origin_id) as account_avg_amount,
        stddev(amount) over (partition by account_origin_id) as account_std_amount

    from trusted_transactions

),

final as (

    select
        transaction_id,
        account_origin_id,
        account_destination_id,
        transaction_type_id,
        amount,
        transaction_date,

        -- Reference the contextual stats
        account_avg_amount,
        account_std_amount,

        -- Flag if the amount is > 3 standard deviations from THIS account's mean
        case
            when amount > (account_avg_amount + (3 * coalesce(account_std_amount, 0)))
            then true
            else false
        end as is_abnormally_large_transaction,

        case
            when amount <= 0 then true
            else false
        end as is_invalid_transaction_amount,

        {{ calculate_fraud_score(
            'false',
            'amount < 0',
            'amount > (account_avg_amount + (3 * coalesce(account_std_amount, 0)))'
        ) }} as fraud_score

    from transaction_stats

)

select *
from final