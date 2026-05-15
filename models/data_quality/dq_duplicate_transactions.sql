select

    transaction_id,
    count(*) as duplicate_count

from {{ ref('stg_transactions') }}

group by transaction_id
having count(*) > 1