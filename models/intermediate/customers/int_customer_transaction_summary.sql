with account_totals as (
    select
        customer_id,
        count(distinct account_id) as total_accounts,
        sum(total_outgoing_transactions) as total_outgoing_transactions,
        sum(total_incoming_transactions) as total_incoming_transactions,
        sum(total_amount_sent) as total_amount_sent,
        sum(total_amount_received) as total_amount_received,
        sum(net_transaction_flow) as net_transaction_flow
    from {{ ref('int_account_activity') }}
    group by 1
),

customer_behavior as (

    select
        t.customer_id,
    
        avg(t.amount) as avg_transaction_amount,
        
        -- High volume flag at customer level
        bool_or(t.amount > 10000) as has_high_volume_activity 
    from {{ ref('stg_transactions') }} t
    where t.is_future_transaction = false
    group by 1
)

select
    act.customer_id,
    act.total_accounts,
    act.total_outgoing_transactions,
    act.total_incoming_transactions,
    act.total_amount_sent,
    act.total_amount_received,
    act.net_transaction_flow,
    
    cb.avg_transaction_amount,
    cb.has_high_volume_activity

from account_totals act
left join customer_behavior cb
    on act.customer_id = cb.customer_id
