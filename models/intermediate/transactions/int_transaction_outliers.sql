with account_percentiles as (
    -- Step 1: Calculate the 99th percentile per account using the correct Postgres syntax
    select
        account_origin_id,
        percentile_cont(0.99) within group (order by amount) as account_99th_percentile
    from {{ ref('stg_transactions') }}
    where is_future_transaction = false
    group by 1
),

final as (
    -- Step 2: Join the thresholds back to individual transactions
    select
        t.transaction_id,
        t.account_origin_id,
        t.amount,
        ap.account_99th_percentile,

        case
            when t.amount > ap.account_99th_percentile then true
            else false
        end as is_outlier

    from {{ ref('stg_transactions') }} t
    left join account_percentiles ap
        on t.account_origin_id = ap.account_origin_id
    where t.is_future_transaction = false
)

select *
from final
