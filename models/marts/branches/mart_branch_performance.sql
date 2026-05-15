with branch_performance as (
    select * from {{ ref('int_branch_performance') }}
),

addresses as (
    select * from {{ ref('stg_addresses') }}
)

select
    bp.branch_id,
    bp.branch_name,
    a.city,
    a.country,                    
    
    -- Performance Metrics
    bp.total_transactions,
    bp.total_transaction_volume,
    bp.avg_transaction_amount,
    bp.max_transaction_amount,
    bp.unique_origin_accounts,
    bp.unique_destination_accounts,
    bp.branch_segment

from branch_performance bp
left join addresses a 
    on bp.address_id = a.address_id
