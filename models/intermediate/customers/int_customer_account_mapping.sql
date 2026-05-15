select

    customer_id,
    account_id,
    account_type_id,
    account_status_id,

    case
        when account_status_id = 1 then true
        else false
    end as is_active_account

from {{ ref('stg_accounts') }}