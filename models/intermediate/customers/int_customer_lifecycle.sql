select

    c.customer_id,

    min(a.opened_date) as first_account_date,

    max(a.opened_date) as last_account_date,

    (current_date - min(a.opened_date)) as customer_tenure_days,

    count(distinct a.account_id) as account_lifetime_count

from {{ ref('stg_customers') }} c

left join {{ ref('stg_accounts') }} a
    on c.customer_id = a.customer_id

group by c.customer_id
