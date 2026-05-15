select
    t.*

from {{ ref('stg_transactions') }} t
left join {{ ref('stg_accounts') }} a
    on t.account_origin_id = a.account_id

where a.account_id is null