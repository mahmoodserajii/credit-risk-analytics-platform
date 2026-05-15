select *

from {{ ref('stg_loans') }}

where loan_amount <= 0
   or loan_amount is null