select

    cast("AccountStatusID" as integer) as account_status_id,
    lower(trim("StatusName")) as account_status

from {{ source('raw', 'account_statuses') }}

