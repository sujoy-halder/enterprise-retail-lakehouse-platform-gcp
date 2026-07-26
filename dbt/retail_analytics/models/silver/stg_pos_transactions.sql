{{ config(
    materialized='incremental',
    unique_key='transaction_id',
    partition_by={'field': 'event_date', 'data_type': 'date', 'granularity': 'day'},
    cluster_by=['store_id', 'product_id']
) }}

with source as (
    select
        cast(transaction_id as string) as transaction_id,
        cast(store_id as string) as store_id,
        cast(customer_id as string) as customer_id,
        cast(product_id as string) as product_id,
        cast(quantity as int64) as quantity,
        cast(unit_price as numeric) as unit_price,
        cast(currency as string) as currency,
        timestamp(event_time) as event_time,
        date(timestamp(event_time)) as event_date,
        timestamp(ingestion_time) as ingestion_time,
        {{ retail_surrogate_key(['transaction_id', 'store_id', 'product_id', 'event_time']) }} as record_hash
    from {{ source('bronze', 'pos_transactions') }}
    where transaction_id is not null
      and store_id is not null
      and product_id is not null
      and quantity >= 0
    {% if is_incremental() %}
      and timestamp(ingestion_time) > (
        select coalesce(max(ingestion_time), timestamp('1970-01-01')) from {{ this }}
      )
    {% endif %}
),

deduped as (
    select * except(row_number)
    from (
        select
            source.*,
            row_number() over (
                partition by transaction_id
                order by ingestion_time desc
            ) as row_number
        from source
    )
    where row_number = 1
)

select * from deduped

