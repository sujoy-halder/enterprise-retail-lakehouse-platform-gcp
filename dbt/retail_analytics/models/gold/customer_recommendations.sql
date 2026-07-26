{{ config(
    materialized='table',
    cluster_by=['customer_id']
) }}

with customer_product as (
    select
        customer_id,
        product_id,
        count(*) as interaction_count,
        max(event_time) as last_interaction_time
    from {{ ref('stg_pos_transactions') }}
    where customer_id is not null
    group by 1, 2
),

scored as (
    select
        customer_id,
        product_id,
        safe_divide(interaction_count, max(interaction_count) over (partition by customer_id)) as score,
        last_interaction_time
    from customer_product
)

select * from scored

