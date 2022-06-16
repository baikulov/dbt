{% test is_pageview_hit(model, column_name) %}

with validation as (

    select
        {{ column_name }} as even_field,
        hitType        
    from {{ model }}
    where {{ column_name }} = 1

),

validation_errors as (

    select
        even_field
    from validation
    WHERE hitType != 'pageview'
)

select *
from validation_errors
{% endtest %}