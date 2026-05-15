with customer_profile as (

    select *
    from {{ ref('int_customer_profile') }}

),

cashflow as (

    select *
    from {{ ref('int_cashflow_stability') }}

)

select

    cp.customer_id,

    cp.total_accounts,

    cp.total_amount_sent,
    cp.total_amount_received,

    cp.net_transaction_flow,

    cf.cashflow_volatility,

    case
        -- 1. Premium Stable: Massive wealth passing through, predictable behavior
        when cp.total_amount_received > 100000
        and cp.net_transaction_flow > 0
        and cf.stable_cashflow = true 
        then 'premium_stable'

        -- 2. High Value: Significant money moving, but erratic/volatile
        when cp.total_amount_received > 50000 
        and cp.net_transaction_flow > 0
        then 'high_value'

        -- 3. Financially Risky: Structurally draining their accounts (independent of volume)
        when cp.net_transaction_flow < 0 
        then 'financially_risky'

        else 'standard'
    end as customer_segment

from customer_profile cp

left join cashflow cf
    on cp.customer_id = cf.customer_id
