{% test is_exist_date(model, column_name) %}

with validation as (

    select
        {{ column_name }} as even_field,
        1 as type        
    from {{ model }}
    where {{ column_name }} = {{ var('execution_date') }}

),

t as (
    SELECT toDate32({{ var('execution_date') }}) as even_field
),

validation_errors as (

    select
        even_field,
        type
    from t
    left join validation using(even_field)
)

select *
from validation_errors
where type = 0
{% endtest %}