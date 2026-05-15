with source as (

    select *
    from {{ source('raw', 'customers') }}

),

dedup as (

    select *,
        row_number() over (
            partition by "CustomerID"
            order by "CustomerID"
        ) as rn
    from source

)

select

    cast("CustomerID" as integer) as customer_id,

    {{ clean_text('"FirstName"') }} as first_name,
    {{ clean_text('"LastName"') }} as last_name,

    {{ clean_date('"DateOfBirth"') }} as date_of_birth,

    cast("CustomerTypeID" as integer) as customer_type_id,
    cast("AddressID" as integer) as address_id

from dedup
where rn = 1
  and "CustomerID" is not null