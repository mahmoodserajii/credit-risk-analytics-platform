select
    a.*

from {{ ref('stg_accounts') }} a
left join {{ ref('stg_customers') }} c
    on a.customer_id = c.customer_id

where c.customer_id is null