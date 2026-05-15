with loan_base as (
    select * from {{ ref('int_loan_repayment_risk') }}
),

loan_features as (
    select * from {{ ref('fct_loan_risk_features') }}
),

loan_statuses as (
    select * from {{ ref('stg_loan_statuses') }}
),

portfolio_trends as (
    select * from {{ ref('int_loan_portfolio_trends') }}
)

select
    lb.loan_id,
    lb.loan_status_id,
    ls.loan_status,
    
    lb.loan_amount,
    lb.interest_rate,
    lb.start_date,
    lb.estimated_end_date,
    lb.loan_duration_days,
    
    lf.loan_risk_score,
    lf.loan_risk_segment,
    lf.loan_size_segment,
    lf.high_interest_flag,
    lf.high_default_probability,
    
    lb.is_large_exposure_loan,

    pt.loan_month,
    pt.total_loan_volume,
    pt.avg_loan_amount,
    pt.avg_interest_rate,
    pt.high_interest_loan_ratio,
    pt.portfolio_risk_segment,


    case 
        when lb.loan_amount > coalesce(pt.avg_loan_amount, 0) * 1.5 
            then true 
        else false 
    end as is_significantly_large_loan

from loan_base lb
left join loan_features lf 
    on lb.loan_id = lf.loan_id
left join loan_statuses ls 
    on lb.loan_status_id = ls.loan_status_id
left join portfolio_trends pt 
    on date_trunc('month', lb.start_date)::date = pt.loan_month
