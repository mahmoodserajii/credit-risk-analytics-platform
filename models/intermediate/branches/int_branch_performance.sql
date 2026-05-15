with trusted_transactions as (

    select *
    from {{ ref('stg_transactions') }}

    where is_future_transaction = false
      and is_negative_amount = false

),

branch_metrics as (

    select

        branch_id,

        count(*) as total_transactions,

        sum(amount) as total_transaction_volume,

        avg(amount) as avg_transaction_amount,

        max(amount) as max_transaction_amount,

        count(distinct account_origin_id)
            as unique_origin_accounts,

        count(distinct account_destination_id)
            as unique_destination_accounts

    from trusted_transactions

    group by 1

)

select

    b.branch_id,

    b.branch_name,

    b.address_id,

    coalesce(m.total_transactions, 0)
        as total_transactions,

    coalesce(m.total_transaction_volume, 0)
        as total_transaction_volume,

    coalesce(m.avg_transaction_amount, 0)
        as avg_transaction_amount,

    coalesce(m.max_transaction_amount, 0)
        as max_transaction_amount,

    coalesce(m.unique_origin_accounts, 0)
        as unique_origin_accounts,

    coalesce(m.unique_destination_accounts, 0)
        as unique_destination_accounts,

    case
        when m.total_transaction_volume > 2500000
        then 'high_volume_branch'

        when m.total_transaction_volume > 1500000
        then 'medium_volume_branch'

        else 'low_volume_branch'
    end as branch_segment

from {{ ref('stg_branches') }} b

left join branch_metrics m
    on b.branch_id = m.branch_id