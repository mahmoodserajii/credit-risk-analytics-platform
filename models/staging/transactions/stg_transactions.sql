with source as (

    select *
    from {{ source('raw', 'transactions') }}

),

accounts as (

    select 
        account_id, 
        customer_id
    from {{ ref('stg_accounts') }}

),

dedup as (

    select *,
        row_number() over (
            partition by "TransactionID"
            order by "TransactionID"
        ) as rn
    from source

)

select
    cast(t."TransactionID" as bigint) as transaction_id,
    cast(t."AccountOriginID" as integer) as account_origin_id,
    cast(t."AccountDestinationID" as integer) as account_destination_id,
    cast(t."TransactionTypeID" as integer) as transaction_type_id,
    cast(t."BranchID" as integer) as branch_id,
    

    a.customer_id, 


    {{ clean_numeric_str('t."Amount"') }} as amount,

    trim(t."Description") as description,

    {{ clean_date('t."TransactionDate"') }} as transaction_date,

    
    case
        when {{ clean_date('t."TransactionDate"') }} is null then true
        when {{ clean_date('t."TransactionDate"') }} > current_date then true
        else false
    end as is_future_transaction,

    case
        when {{ clean_numeric_str('t."Amount"') }} < 0 then true
        else false
    end as is_negative_amount

from dedup t
left join accounts a 
    on cast(t."AccountOriginID" as integer) = a.account_id
where t.rn = 1
  and t."TransactionID" is not null
