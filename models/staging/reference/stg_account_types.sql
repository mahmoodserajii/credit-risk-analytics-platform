select

    cast("AccountTypeID" as integer) as account_type_id,
    lower(trim("TypeName")) as account_type

from {{ source('raw', 'account_types') }}



