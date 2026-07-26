select *
from {{ ref('fct_daily_sales') }}
where units_sold < 0
   or gross_revenue < 0

