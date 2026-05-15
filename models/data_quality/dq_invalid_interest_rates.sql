select *

from {{ ref('stg_loans') }}

where interest_rate < 0
   or interest_rate > 100
   or interest_rate is null