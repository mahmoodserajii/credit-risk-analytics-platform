with trusted_transactions as (

    select *
    from {{ ref('stg_transactions') }}

    where is_future_transaction = false
      and is_negative_amount = false

),

money_sent as (

    select

        account_origin_id as account_id,

        count(*) as total_outgoing_transactions,

        sum(amount) as total_amount_sent,

        avg(amount) as avg_outgoing_amount,

        max(amount) as max_outgoing_amount

    from trusted_transactions
    group by 1

),

money_received as (

    select

        account_destination_id as account_id,

        count(*) as total_incoming_transactions,

        sum(amount) as total_amount_received,

        avg(amount) as avg_incoming_amount,

        max(amount) as max_incoming_amount

    from trusted_transactions
    group by 1

)

select

    a.account_id,
    a.customer_id,
    a.balance,
    a.account_type_id,
    a.account_status_id,

    coalesce(ms.total_outgoing_transactions, 0)
        as total_outgoing_transactions,

    coalesce(ms.total_amount_sent, 0)
        as total_amount_sent,

    coalesce(mr.total_incoming_transactions, 0)
        as total_incoming_transactions,

    coalesce(mr.total_amount_received, 0)
        as total_amount_received,

    (
        coalesce(mr.total_amount_received, 0)
        -
        coalesce(ms.total_amount_sent, 0)
    ) as net_transaction_flow,

    case
        when a.balance < 0 then true
        else false
    end as has_negative_balance

from {{ ref('stg_accounts') }} a

left join money_sent ms
    on a.account_id = ms.account_id

left join money_received mr
    on a.account_id = mr.account_id