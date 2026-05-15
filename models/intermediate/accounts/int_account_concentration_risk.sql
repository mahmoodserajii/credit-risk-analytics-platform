select

    account_origin_id as account_id,

    sum(amount) as total_outflow,

    count(distinct account_destination_id) as unique_destinations,

    case
        when count(distinct account_destination_id) < 3 then true
        else false
    end as high_concentration_risk

from {{ ref('stg_transactions') }}

where is_future_transaction = false

group by 1
