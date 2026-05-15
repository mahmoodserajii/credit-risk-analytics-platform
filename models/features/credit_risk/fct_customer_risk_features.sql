with customer_profile as (

    select *
    from {{ ref('int_customer_profile') }}

),

cashflow as (

    select *
    from {{ ref('int_cashflow_stability') }}

),

fraud_profile as (

    select *
    from {{ ref('int_customer_fraud_profile') }}

),

customer_exposure as (

    select *
    from {{ ref('int_customer_financial_exposure') }}

),

account_risk_summary as (

    select
        a.customer_id,
        coalesce(avg(ar.risk_score), 0) as avg_account_risk_score
    from {{ ref('stg_accounts') }} a
    left join {{ ref('int_account_risk_profile') }} ar
        on a.account_id = ar.account_id
    group by 1

),

pre_scored as (

    select
        cp.customer_id,
        cp.total_accounts,
        cp.total_amount_sent,
        cp.total_amount_received,
        cp.net_transaction_flow,
        cp.customer_value_segment,

        ce.total_balance_exposure,
        ce.overdraft_exposure,
        ce.avg_account_balance,

        cf.cashflow_volatility,
        avg_monthly_cashflow,
        cf.stable_cashflow,

        fp.total_flagged_transactions,
        fp.high_risk_transaction_ratio,

        ara.avg_account_risk_score,

        -- Convert raw dollar volatility to a 0-100 scale using a safety cap (e.g., $10,000 max volatility)
        case 
            when cf.cashflow_volatility >= 10000 then 100.0
            else (coalesce(cf.cashflow_volatility, 0) / 10000.0) * 100.0
        end as scaled_volatility_score

    from customer_profile cp
    left join customer_exposure ce on cp.customer_id = ce.customer_id
    left join cashflow cf on cp.customer_id = cf.customer_id
    left join fraud_profile fp on cp.customer_id = fp.customer_id
    left join account_risk_summary ara on cp.customer_id = ara.customer_id

),

composite_scoring as (

    select
        *,
        (
            (avg_account_risk_score * 0.6) +
            (coalesce(high_risk_transaction_ratio, 0) * 0.2) +
            (scaled_volatility_score * 0.2)
        ) as composite_customer_risk_score
    from pre_scored

)

select
    customer_id,
    total_accounts,
    total_amount_sent,
    total_amount_received,
    net_transaction_flow,
    customer_value_segment,
    total_balance_exposure,
    overdraft_exposure,
    avg_account_balance,
    cashflow_volatility,
    avg_monthly_cashflow,
    stable_cashflow,
    total_flagged_transactions,
    high_risk_transaction_ratio,
    avg_account_risk_score,
    composite_customer_risk_score,

    case
        when composite_customer_risk_score >= 80 then 'high_risk'
        when composite_customer_risk_score >= 50 then 'medium_risk'
        else 'low_risk'
    end as customer_risk_segment

from composite_scoring
