{#
    Use the schema configured on a model (+dataset / +schema) VERBATIM, instead of
    dbt's default behavior of prefixing it with the target schema
    (e.g. `olin_silver_dev_jun` rather than `<target>_olin_silver_dev_jun`).

    Models with no +dataset fall back to the profile's default dataset.
#}
{% macro generate_schema_name(custom_schema_name, node) -%}
    {%- if custom_schema_name is none -%}
        {{ target.schema }}
    {%- else -%}
        {{ custom_schema_name | trim }}
    {%- endif -%}
{%- endmacro %}
