With customer_360 as (
    select * from {{ ref('mart_customer_360') }}
),

aggregated_metrics as (
    select
        count(distinct customer_id) as total_customers,
        sum(total_customer_balance) as total_deposits,
        sum(net_transaction_flow) as net_system_flow,
        
        count(distinct case when priority_segment = 'premium_growth' then customer_id end) as premium_growth_customers,
        count(distinct case when priority_segment = 'high_value_high_risk' then customer_id end) as high_value_high_risk_customers,
        count(distinct case when priority_segment = 'early_warning_risk' then customer_id end) as early_warning_risk_customers,
        count(distinct case when priority_segment = 'low_value_high_risk' then customer_id end) as toxic_loss_customers,
        
        count(distinct case when has_negative_balance_flag = true then customer_id end) as customers_with_negative_balance,
        sum(total_outgoing_transactions + total_incoming_transactions) as total_transactions,
        sum(total_amount_sent + total_amount_received) as total_transaction_volume
        
    from customer_360
)

select
    date_trunc('month', current_date)::date as snapshot_month,
    
    total_customers,
    premium_growth_customers,
    high_value_high_risk_customers,
    early_warning_risk_customers,
    toxic_loss_customers,
    
    total_deposits,
    net_system_flow,
    total_transactions,
    total_transaction_volume,
    customers_with_negative_balance,

    round(total_deposits / nullif(total_customers, 0), 2) as avg_balance_per_customer,
    round(high_value_high_risk_customers::numeric / nullif(total_customers, 0) * 100, 2) as high_value_risk_concentration_pct

from aggregated_metrics
