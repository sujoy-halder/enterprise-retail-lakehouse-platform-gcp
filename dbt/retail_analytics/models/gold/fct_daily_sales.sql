{{ config(
    materialized='incremental',
    unique_key=['business_date', 'store_id', 'product_id'],
    partition_by={'field': 'business_date', 'data_type': 'date', 'granularity': 'day'},
    cluster_by=['store_id', 'product_id']
) }}

select
    event_date as business_date,
    store_id,
    product_id,
    sum(quantity) as units_sold,
    sum(quantity * unit_price) as gross_revenue,
    sum(quantity * unit_price) as net_revenue,
    current_timestamp() as updated_at
from {{ ref('stg_pos_transactions') }}
{% if is_incremental() %}
where event_date >= date_sub(current_date(), interval 3 day)
{% endif %}
group by 1, 2, 3

