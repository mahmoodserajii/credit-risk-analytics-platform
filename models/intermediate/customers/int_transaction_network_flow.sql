select

    account_origin_id,
    account_destination_id,

    count(*) as transaction_count,
    sum(amount) as total_flow,

    avg(amount) as avg_flow,

    case
        when count(*) > 50 then true
        else false
    end as high_frequency_connection

from {{ ref('stg_transactions') }}

where is_future_transaction = false
  and is_negative_amount = false

group by 1,2
