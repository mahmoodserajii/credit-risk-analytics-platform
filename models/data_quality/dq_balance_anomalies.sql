select *

from {{ ref('stg_accounts') }}

where balance < 0
   or balance > 100000000