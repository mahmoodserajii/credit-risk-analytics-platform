with txn_risk as (

    select *
    from {{ ref('int_transaction_risk_features') }}

),

txn_velocity as (

    select *
    from {{ ref('int_transaction_velocity') }}

),

network_flow as (

    select *
    from {{ ref('int_transaction_network_flow') }}

),

outliers as (

    select *
    from {{ ref('int_transaction_outliers') }}

),

joined_features as (

    select
        tr.transaction_id,
        tr.account_origin_id,
        tr.account_destination_id,
        tr.amount,
        tr.fraud_score,
        tr.is_abnormally_large_transaction,

    
        tv.txn_count_last_hour,
        tv.high_velocity_flag,

        nf.transaction_count,
        nf.total_flow,
        nf.high_frequency_connection,

        o.is_outlier

    from txn_risk tr
    left join txn_velocity tv
        on tr.transaction_id = tv.transaction_id

    left join network_flow nf
        on tr.account_origin_id = nf.account_origin_id
       and tr.account_destination_id = nf.account_destination_id

    left join outliers o
        on tr.transaction_id = o.transaction_id

),

scored_features as (

    select
        *,
        (
            case when is_abnormally_large_transaction then 30 else 0 end +
            case when high_velocity_flag then 25 else 0 end +
            case when high_frequency_connection then 25 else 0 end +
            case when is_outlier then 20 else 0 end
        ) as composite_fraud_risk_score
    from joined_features

)

select
    transaction_id,
    account_origin_id,
    account_destination_id,
    amount,
    fraud_score,
    is_abnormally_large_transaction,
    txn_count_last_hour,
    high_velocity_flag,
    transaction_count,
    total_flow,
    high_frequency_connection,
    is_outlier,
    composite_fraud_risk_score,

    case
        when composite_fraud_risk_score >= 70 then 'high_fraud_risk'
        when composite_fraud_risk_score >= 40 then 'medium_fraud_risk'
        else 'low_fraud_risk'
    end as fraud_risk_segment

from scored_features
