with fraud_features as (
    select * from {{ ref('fct_fraud_features') }}
),

transactions as (
    select * from {{ ref('stg_transactions') }}
),

accounts as (
    select * from {{ ref('stg_accounts') }}
),

transaction_types as (
    select * from {{ ref('stg_transaction_types') }}
)

select
    f.transaction_id,
    f.account_origin_id,
    f.account_destination_id,
    a.customer_id as origin_customer_id,
    
    t.transaction_date,
    t.amount,
    t.description,
    t.branch_id,
    tt.transaction_type,
    
    f.fraud_score,
    f.composite_fraud_risk_score,
    f.fraud_risk_segment,
    
    f.is_abnormally_large_transaction,
    f.high_velocity_flag,
    f.high_frequency_connection,
    f.is_outlier

from fraud_features f
left join transactions t 
    on f.transaction_id = t.transaction_id
left join accounts a 
    on f.account_origin_id = a.account_id
left join transaction_types tt 
    on t.transaction_type_id = tt.transaction_type_id
