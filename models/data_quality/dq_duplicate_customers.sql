select

    customer_id,
    count(*) as duplicate_count

from {{ ref('stg_customers') }}

group by customer_id
having count(*) > 1