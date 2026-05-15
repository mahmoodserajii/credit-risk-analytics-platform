select

    cast("AddressID" as integer) as address_id,

    {{ clean_text('"Street"') }} as Street,
    {{ clean_text('"City"') }} as city,
    upper(trim("Country")) as country

from {{ source('raw', 'addresses') }}
where "AddressID" is not null



