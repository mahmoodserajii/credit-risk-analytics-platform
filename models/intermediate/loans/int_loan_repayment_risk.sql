with trusted_loans as (

    select *
    from {{ ref('stg_loans') }}
    where is_invalid_loan_amount = false
      and is_invalid_interest_rate = false
      and is_invalid_date_range = false

),

scored_loans as (

    select
        loan_id,
        loan_status_id,
        loan_amount,
        interest_rate,
        start_date,
        estimated_end_date,

        (estimated_end_date - start_date) as loan_duration_days,

        case
            when (interest_rate * 100) > 15 then true
            else false
        end as is_high_interest_loan,

        case
            when loan_amount > 100000 then true
            else false
        end as is_large_exposure_loan,

        {{ calculate_risk_score(
            'false',
            'false',
            '(interest_rate * 100) > 15',
            'loan_amount > 100000'
        ) }} as loan_risk_score

    from trusted_loans

)

select
    *,
    case
        when loan_risk_score >= 80 then 'high_risk'
        when loan_risk_score >= 50 then 'medium_risk'
        else 'low_risk'
    end as loan_risk_segment
from scored_loans
