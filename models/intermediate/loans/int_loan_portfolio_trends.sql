with trusted_loans as (

    select *
    from {{ ref('stg_loans') }}

    where is_invalid_loan_amount = false
      and is_invalid_interest_rate = false
      and is_invalid_date_range = false

),

monthly_loans as (

    select
        date_trunc('month', start_date) as loan_month,

        count(*) as total_loans,

        sum(loan_amount) as total_loan_volume,

        avg(loan_amount) as avg_loan_amount,

        avg(interest_rate) * 100 as avg_interest_rate_pct,

        sum(
            case
                when interest_rate * 100 > 15 then 1
                else 0
            end
        ) as high_interest_loans

    from trusted_loans

    group by 1

)

select
    loan_month,
    total_loans,
    total_loan_volume,
    avg_loan_amount,
    avg_interest_rate_pct as avg_interest_rate,
    high_interest_loans,

    round(
        (
            high_interest_loans::numeric
            /
            nullif(total_loans, 0)
        ) * 100,
        2
    ) as high_interest_loan_ratio,

    case
        when avg_interest_rate_pct > 15 then 'high_risk_period'
        when avg_interest_rate_pct > 8 then 'medium_risk_period'
        else 'low_risk_period'
    end as portfolio_risk_segment

from monthly_loans
