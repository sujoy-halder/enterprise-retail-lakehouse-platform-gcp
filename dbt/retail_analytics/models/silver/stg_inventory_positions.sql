{{ config(
    materialized='incremental',
    unique_key=['store_id', 'sku'],
    partition_by={'field': 'snapshot_date', 'data_type': 'date', 'granularity': 'day'},
    cluster_by=['store_id', 'sku']
) }}

select
    inventory_event_id,
    store_id,
    sku,
    on_hand_quantity,
    reserved_quantity,
    timestamp(snapshot_time) as snapshot_time,
    date(timestamp(snapshot_time)) as snapshot_date,
    record_hash
from {{ source('silver', 'inventory_positions') }}
where store_id is not null
  and sku is not null
  and on_hand_quantity >= 0
{% if is_incremental() %}
  and timestamp(snapshot_time) > (
    select coalesce(max(snapshot_time), timestamp('1970-01-01')) from {{ this }}
  )
{% endif %}

