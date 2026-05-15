with customer_transactions as (
    select
        date_trunc('month', t.transaction_date)::date as report_month,
        cp.customer_id,
        cp.customer_risk_segment,
        cp.composite_customer_risk_score
    from {{ ref('mart_customer_360') }} cp
    
    inner join {{ ref('stg_accounts') }} sa 
        on cp.customer_id = sa.customer_id
    inner join {{ ref('stg_transactions') }} t 
        on sa.account_id = t.account_origin_id
    group by 1, 2, 3, 4
),

monthly_customers as (
    select
        report_month,
        count(distinct customer_id) as active_customers,
        percentile_cont(0.5) within group (order by composite_customer_risk_score) as median_customer_risk_score,
        count(distinct case when customer_risk_segment = 'high_risk' then customer_id end) as high_risk_customers,
        round(
            (count(distinct case when customer_risk_segment = 'high_risk' then customer_id end)::numeric 
            / nullif(count(distinct customer_id), 0) * 100), 2
        ) as high_risk_ratio_pct
    from customer_transactions
    group by 1
),

monthly_loans as (
    select
       
        loan_month::date as report_month,
        total_loan_volume,
        avg_interest_rate,
        high_interest_loan_ratio,
        portfolio_risk_segment
    from {{ ref('int_loan_portfolio_trends') }}
)

select
    coalesce(c.report_month, l.report_month) as report_month,
    coalesce(c.active_customers, 0) as active_customers,
    c.median_customer_risk_score,
    coalesce(c.high_risk_customers, 0) as high_risk_customers,
    coalesce(c.high_risk_ratio_pct, 0.00) as high_risk_ratio_pct,
    coalesce(l.total_loan_volume, 0.00) as total_loan_volume,
    l.avg_interest_rate,
    l.high_interest_loan_ratio,
    coalesce(l.portfolio_risk_segment, 'no_loans_period') as portfolio_risk_segment
from monthly_customers c
full outer join monthly_loans l 
    on c.report_month = l.report_month
order by 1 desc
