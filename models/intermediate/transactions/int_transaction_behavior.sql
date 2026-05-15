with trusted_transactions as (

    select *
    from {{ ref('stg_transactions') }}

    where is_future_transaction = false
      and is_negative_amount = false

),

daily_activity as (

    select

        account_origin_id as account_id,

        date(transaction_date) as transaction_date,

        count(*) as daily_transaction_count,

        sum(amount) as daily_transaction_volume,

        avg(amount) as avg_transaction_amount

    from trusted_transactions

    group by 1, 2

)

select

    account_id,

    count(distinct transaction_date)
        as active_transaction_days,

    avg(daily_transaction_count)
        as avg_daily_transaction_count,

    max(daily_transaction_count)
        as max_daily_transaction_count,

    avg(daily_transaction_volume)
        as avg_daily_transaction_volume,

    max(daily_transaction_volume)
        as max_daily_transaction_volume,

    avg(avg_transaction_amount)
        as avg_transaction_amount,

    case
        when avg(daily_transaction_volume) > 3000
        then true
        else false
    end as is_high_volume_account


from daily_activity

group by account_id