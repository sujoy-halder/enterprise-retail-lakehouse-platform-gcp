{{ config(materialized='view') }}

select
    current_date() as business_date,
    'placeholder' as carrier,
    0 as shipments_in_transit,
    0 as delayed_shipments,
    0.0 as delay_rate

