select

    c.customer_id,

    sum(a.balance) as total_balance_exposure,

    count(a.account_id) as total_accounts,

    sum(case when a.balance < 0 then a.balance else 0 end)
        as overdraft_exposure,

    avg(a.balance) as avg_account_balance,

    max(a.balance) as max_account_balance

from {{ ref('stg_customers') }} c

left join {{ ref('stg_accounts') }} a
    on c.customer_id = a.customer_id

group by c.customer_id
