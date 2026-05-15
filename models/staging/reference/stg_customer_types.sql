select

    cast("CustomerTypeID" as integer) as customer_type_id,
    lower(trim("TypeName")) as customer_type

from {{ source('raw', 'customer_types') }}
where "CustomerTypeID" is not null


