{{ config(
    materialized='table',
    partition_by={'field': 'snapshot_date', 'data_type': 'date', 'granularity': 'day'},
    cluster_by=['store_id', 'sku']
) }}

select
    snapshot_date,
    store_id,
    sku,
    on_hand_quantity,
    reserved_quantity,
    greatest(on_hand_quantity - reserved_quantity, 0) as available_quantity,
    avg(on_hand_quantity) over (
        partition by store_id, sku
        order by snapshot_date
        rows between 6 preceding and current row
    ) as trailing_7_snapshot_avg
from {{ ref('stg_inventory_positions') }}

