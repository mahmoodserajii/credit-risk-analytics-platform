with activity as (

    select *
    from {{ ref('int_account_activity') }}

),

behavior as (

    select *
    from {{ ref('int_transaction_behavior') }}

),

scored as (

    select

        a.account_id,
        a.customer_id,

        a.balance,

        a.total_outgoing_transactions,
        a.total_incoming_transactions,

        a.total_amount_sent,
        a.total_amount_received,

        a.net_transaction_flow,

        b.avg_daily_transaction_count,
        b.max_daily_transaction_volume,

        a.has_negative_balance,

        coalesce(b.is_high_volume_account, false)
            as is_high_volume_account,

        case
            when abs(a.net_transaction_flow) > 100000
            then true
            else false
        end as has_extreme_cash_flow,

        {{ calculate_risk_score(
            'a.has_negative_balance',
            'coalesce(b.is_high_volume_account, false)',
            'false',
            'abs(a.net_transaction_flow) > 100000'
        ) }} as risk_score

    from activity a

    left join behavior b
        on a.account_id = b.account_id

)

select

    *,

    {{ classify_risk_segment('risk_score') }}
        as risk_segment

from scored