{{ config(
    materialized='table',
    tags=['mart', 'customer', '360']
) }}

with customer_profile as (
    select * from {{ ref('int_customer_profile') }}
),

risk_features as (
    select * from {{ ref('fct_customer_risk_features') }}
),

behavior_features as (
    select * from {{ ref('fct_customer_behavior_features') }}
)

select
    -- 1. Customer Identifiers & Demographics
    cp.customer_id,
    cp.first_name,
    cp.last_name,
    cp.date_of_birth,
    date_part('year', age(cp.date_of_birth)) as age,
    cp.address_id,
    
    -- 2. Account Summary & Tiering
    cp.total_accounts,
    cp.total_customer_balance,
    rf.avg_account_balance, 
    coalesce(cp.has_negative_avg_balance, false) as has_negative_balance_flag,
    cp.customer_value_segment,
    
    -- 3. Transaction Volume Metrics
    cp.total_outgoing_transactions,
    cp.total_incoming_transactions,
    cp.total_amount_sent,
    cp.total_amount_received,
    cp.net_transaction_flow,
    
    -- 4. Risk & Fraud Profile Features
    rf.composite_customer_risk_score,
    rf.customer_risk_segment,
    rf.avg_account_risk_score,
    rf.total_flagged_transactions,
    rf.high_risk_transaction_ratio,
    rf.total_balance_exposure,
    rf.overdraft_exposure,

    -- 5. Behavioral Analytics & Cashflow Features
    bf.customer_tenure_days,
    bf.account_lifetime_count,
    bf.tenure_segment,
    bf.activity_segment,
    bf.customer_segment as customer_behavior_segment, 
    bf.stable_cashflow,
    bf.cashflow_volatility,

    -- 6. Comprehensive Operational Priority Matrix
    case 
        -- Tier 1: Systemic High Risks (Actionable Collections Routing)
        when rf.customer_risk_segment = 'high_risk' 
         and cp.customer_value_segment = 'high_value_customer'
            then 'high_value_high_risk'
            
        when rf.customer_risk_segment = 'high_risk' 
         and cp.customer_value_segment = 'mid_value_customer'
            then 'mid_value_high_risk'

        when rf.customer_risk_segment = 'high_risk' 
            then 'low_value_high_risk'

        -- Tier 2: Core Profit Centers (VIP & Premium Management)
        when rf.customer_risk_segment = 'low_risk' 
         and cp.customer_value_segment = 'high_value_customer'
            then 'premium_growth'

        when cp.customer_value_segment = 'high_value_customer'
            then 'high_value_monitored'

        when rf.customer_risk_segment = 'low_risk' 
         and cp.customer_value_segment = 'mid_value_customer'
            then 'mid_market_stable'

        -- Tier 3: Early Warning Indicators (Preventative Underwriting)
        when rf.customer_risk_segment = 'medium_risk' 
         and cp.customer_value_segment = 'mid_value_customer'
            then 'early_warning_risk'

        -- Tier 4: Base Retail Layers
        when cp.customer_value_segment = 'mid_value_customer'
            then 'standard_mid_tier'
            
        else 'standard_retail'
    end as priority_segment

from customer_profile cp
left join risk_features rf          on cp.customer_id = rf.customer_id
left join behavior_features bf      on cp.customer_id = bf.customer_id
