with lifecycle as (

    select *
    from {{ ref('int_customer_lifecycle') }}

),

txn_summary as (

    select *
    from {{ ref('int_customer_transaction_summary') }}

),

cashflow as (

    select *
    from {{ ref('int_cashflow_stability') }}

),

segmentation as (

    select *
    from {{ ref('int_customer_segmentation') }}

)

select
    lc.customer_id,
    lc.customer_tenure_days,
    lc.account_lifetime_count,

    
    (
        coalesce(ts.total_outgoing_transactions, 0) + 
        coalesce(ts.total_incoming_transactions, 0)
    ) as total_transactions,

    ts.total_amount_sent,
    ts.total_amount_received,
    ts.net_transaction_flow,

    cf.cashflow_volatility,
    cf.stable_cashflow,

    sg.customer_segment,

    
    case
        when lc.customer_tenure_days >= 3640 then 'long_term_customer'
        when lc.customer_tenure_days >= 365 then 'mid_term_customer'
        else 'new_customer'
    end as tenure_segment,

    
    case
        when (coalesce(ts.total_outgoing_transactions, 0) + coalesce(ts.total_incoming_transactions, 0)) > 500 
        then 'high_activity'
        when (coalesce(ts.total_outgoing_transactions, 0) + coalesce(ts.total_incoming_transactions, 0)) > 100 
        then 'medium_activity'
        else 'low_activity'
    end as activity_segment

from lifecycle lc

left join txn_summary ts
    on lc.customer_id = ts.customer_id

left join cashflow cf
    on lc.customer_id = cf.customer_id

left join segmentation sg
    on lc.customer_id = sg.customer_id
