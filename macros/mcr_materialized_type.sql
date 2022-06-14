{% macro materialized_type() %}
    {%- if  target.name == "dev" -%}
        table
    {%- else -%}
        incremental
    {%- endif -%}
{% endmacro %}