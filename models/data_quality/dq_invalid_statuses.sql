select
    a.*

from {{ ref('stg_accounts') }} a
left join {{ ref('stg_account_statuses') }} s
    on a.account_status_id = s.account_status_id

where s.account_status_id is null