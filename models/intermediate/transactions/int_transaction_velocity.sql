with rolling_counts as (
    select
        transaction_id,
        account_origin_id as account_id,
        transaction_date,
        amount,

        -- Count transactions for THIS account in the last 1 rolling hour
        count(*) over(
            partition by account_origin_id
            order by transaction_date
            range between interval '1 hour' preceding and current row
        ) as txn_count_last_hour,

        -- Sum volume for THIS account in the last 1 rolling hour
        sum(amount) over(
            partition by account_origin_id
            order by transaction_date
            range between interval '1 hour' preceding and current row
        ) as volume_last_hour

    from {{ ref('stg_transactions') }}
    where is_future_transaction = false
)

select
    transaction_id,
    account_id,
    transaction_date,
    amount,
    txn_count_last_hour,
    volume_last_hour,

    -- Flag if the account hits more than 20 transactions within ANY 60-minute window
    case
        when txn_count_last_hour > 20 then true
        else false
    end as high_velocity_flag

from rolling_counts
