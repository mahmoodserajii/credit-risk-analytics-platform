with trusted_loans as (

    select *
    from {{ ref('stg_loans') }}

    where is_invalid_loan_amount = false
      and is_invalid_interest_rate = false
      and is_invalid_date_range = false

)

select

    loan_status_id,

    count(*) as total_loans,

    sum(loan_amount) as total_loan_amount,

    avg(loan_amount) as avg_loan_amount,

    avg(interest_rate) as avg_interest_rate,

    min(start_date) as earliest_loan_date,

    max(estimated_end_date) as latest_estimated_end_date,

    case
        when avg(interest_rate)*100 > 15 then 'high_interest_portfolio'
        when avg(interest_rate)*100 > 8 then 'medium_interest_portfolio'
        else 'low_interest_portfolio'
    end as portfolio_risk_segment

from trusted_loans

group by loan_status_id