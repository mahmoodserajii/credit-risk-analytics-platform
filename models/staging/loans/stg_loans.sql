with source as (

    select *
    from {{ source('raw', 'loans') }}

),

dedup as (

    select *,
        row_number() over (
            partition by "LoanID"
            order by "LoanID"
        ) as rn
    from source

)

select
    cast("LoanID" as integer) as loan_id,
    cast("AccountID" as integer) as account_id,
 
    cast("LoanStatusID" as integer) as loan_status_id,

    {{ clean_numeric_str('"PrincipalAmount"') }} as loan_amount,
    {{ clean_numeric_str('"InterestRate"') }} as interest_rate,

    {{ clean_date('"StartDate"') }} as start_date,
    {{ clean_date('"EstimatedEndDate"') }} as estimated_end_date,

    case
        when {{ clean_numeric_str('"PrincipalAmount"') }} <= 0 then true
        else false
    end as is_invalid_loan_amount,

    case
        when {{ clean_numeric_str('"InterestRate"') }} < 0
          or {{ clean_numeric_str('"InterestRate"') }} > 100
        then true
        else false
    end as is_invalid_interest_rate,

    case
        when "EstimatedEndDate" < "StartDate" then true
        else false
    end as is_invalid_date_range

from dedup
where rn = 1