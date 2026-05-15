with loan_risk as (

    select *
    from {{ ref('int_loan_repayment_risk') }}

)

select
    lr.loan_id,
    lr.loan_amount,
    lr.interest_rate,
    lr.loan_risk_score,
    lr.loan_risk_segment,

    case
        when lr.loan_amount >= 100000 then 'large_loan'
        when lr.loan_amount >= 25000 then 'medium_loan'
        else 'small_loan'
    end as loan_size_segment,

    case
        when (lr.interest_rate * 100) > 15 then true
        else false
    end as high_interest_flag,

    case
        when lr.loan_risk_segment = 'high_risk' then true
        else false
    end as high_default_probability,

    {{ generate_audit_columns() }}

from loan_risk lr
