with monthly_history as (
    select
        customer_id,
        date_trunc('month', transaction_date) as transaction_month,
        sum(case when amount > 0 then amount else 0 end) as monthly_received,
        sum(case when amount < 0 then abs(amount) else 0 end) as monthly_sent,
        (sum(case when amount > 0 then amount else 0 end) - sum(case when amount < 0 then abs(amount) else 0 end)) as net_cashflow
    from {{ ref('stg_transactions') }}
    where is_future_transaction = false
    group by 1, 2
)

select
    customer_id,
    stddev(net_cashflow) as cashflow_volatility,
    avg(net_cashflow) as avg_monthly_cashflow,

    case
    -- If variation is less than 50% of their average monthly flow, they are stable
    when stddev(net_cashflow) / nullif(avg(net_cashflow), 0) < 0.50 then true
        else false
    end as stable_cashflow

from monthly_history
group by 1
