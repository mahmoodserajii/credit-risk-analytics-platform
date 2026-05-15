select

    cast("BranchID" as integer) as branch_id,

    initcap(trim("BranchName")) as branch_name,

    cast("AddressID" as integer) as address_id

from {{ source('raw', 'branches') }}


