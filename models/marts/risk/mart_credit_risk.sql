select
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    c.customer_value_segment,
    
    -- Risk Scores 
    r.composite_customer_risk_score,
    r.customer_risk_segment,
    r.avg_account_risk_score,
    
    -- Exposure Metrics 
    r.total_balance_exposure,
    r.overdraft_exposure,
    r.total_accounts,      
    r.avg_account_balance,  
    
    -- Behavioral Risk Indicators 
    r.high_risk_transaction_ratio,
    r.total_flagged_transactions,
    r.stable_cashflow,
    r.cashflow_volatility

from {{ ref('fct_customer_risk_features') }} r
left join {{ ref('int_customer_profile') }} c 
    on r.customer_id = c.customer_id
