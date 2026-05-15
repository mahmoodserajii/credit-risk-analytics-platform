select

    cast("LoanStatusID" as integer) as loan_status_id,
    lower(trim("StatusName")) as loan_status

from {{ source('raw', 'loan_statuses') }}

