with customers as (

    select *
    from {{ ref('stg_customers') }}

),

transaction_summary as (

    select *
    from {{ ref('int_customer_transaction_summary') }}

),

accounts as (

    select *
    from {{ ref('stg_accounts') }}

)

select

    c.customer_id,

    c.first_name,
    c.last_name,
    c.date_of_birth,

    c.customer_type_id,
    c.address_id,

    count(distinct a.account_id)
        as total_accounts,

    avg(a.balance)
        as avg_account_balance,

    sum(a.balance)
        as total_customer_balance,

    coalesce(ts.total_outgoing_transactions, 0)
        as total_outgoing_transactions,

    coalesce(ts.total_incoming_transactions, 0)
        as total_incoming_transactions,

    coalesce(ts.total_amount_sent, 0)
        as total_amount_sent,

    coalesce(ts.total_amount_received, 0)
        as total_amount_received,

    coalesce(ts.net_transaction_flow, 0)
        as net_transaction_flow,

    case
        when avg(a.balance) < 0 then true
        else false
    end as has_negative_avg_balance,

    case
        when sum(a.balance) > 100000 then 'high_value_customer'
        when sum(a.balance) > 25000 then 'mid_value_customer'
        else 'standard_customer'
    end as customer_value_segment,

    {{ generate_audit_columns() }}

from customers c

left join accounts a
    on c.customer_id = a.customer_id

left join transaction_summary ts
    on c.customer_id = ts.customer_id

group by
    c.customer_id,
    c.first_name,
    c.last_name,
    c.date_of_birth,
    c.customer_type_id,
    c.address_id,
    ts.total_outgoing_transactions,
    ts.total_incoming_transactions,
    ts.total_amount_sent,
    ts.total_amount_received,
    ts.net_transaction_flow