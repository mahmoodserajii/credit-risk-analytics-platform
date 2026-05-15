with account_risk as (

    select *
    from {{ ref('int_account_risk_profile') }}

),

accounts as (

    select *
    from {{ ref('stg_accounts') }}

),

txn_risk as (

    select *
    from {{ ref('int_transaction_risk_features') }}

)

select

    a.customer_id,

    count(distinct ar.account_id)
        as risky_accounts_count,

    avg(ar.risk_score)
        as avg_customer_risk_score,

    max(ar.risk_score)
        as max_customer_risk_score,

    bool_or(ar.has_extreme_cash_flow)
        as has_extreme_cash_flow,

    bool_or(ar.has_negative_balance)
        as has_negative_balance,

    bool_or(ar.is_high_volume_account)
        as has_high_volume_activity,

    case
        when avg(ar.risk_score) >= 75 then 'high_risk_customer'
        when avg(ar.risk_score) >= 40 then 'medium_risk_customer'
        else 'low_risk_customer'
    end as customer_risk_segment,

    count(tx.transaction_id)
        as total_flagged_transactions,

    round(
        (
            sum(
                case
                    when tx.fraud_score >= 70 then 1
                    else 0
                end
            )::numeric
            /
            nullif(count(tx.transaction_id), 0)
        ) * 100,
        2
    ) as high_risk_transaction_ratio,

    {{ generate_audit_columns() }}

from account_risk ar

left join accounts a
    on ar.account_id = a.account_id

left join txn_risk tx
    on ar.account_id = tx.account_origin_id

group by a.customer_id