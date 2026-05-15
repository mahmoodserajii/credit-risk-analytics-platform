select

    cast("TransactionTypeID" as integer) as transaction_type_id,
    lower(trim("TypeName")) as transaction_type

from {{ source('raw', 'transaction_types') }}

