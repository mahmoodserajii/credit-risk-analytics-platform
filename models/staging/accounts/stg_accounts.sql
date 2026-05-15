with source as (

    select *
    from {{ source('raw', 'accounts') }}

),

dedup as (

    select *,
        row_number() over (
            partition by "AccountID"
            order by "AccountID"
        ) as rn
    from source

)

select

    cast("AccountID" as integer) as account_id,
    cast("CustomerID" as integer) as customer_id,

    cast("AccountTypeID" as integer) as account_type_id,
    cast("AccountStatusID" as integer) as account_status_id,

    {{ clean_numeric_str('"Balance"') }} as balance,

    {{ clean_date('"OpeningDate"') }} as opened_date,

    case
        when {{ clean_numeric_str('"Balance"') }} < 0 then true
        else false
    end as is_negative_balance

from dedup
where rn = 1
  and "AccountID" is not null