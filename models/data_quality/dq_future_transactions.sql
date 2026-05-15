select *

from {{ ref('stg_transactions') }}

where transaction_date > current_timestamp