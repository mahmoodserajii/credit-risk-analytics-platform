{% macro clean_numeric_str(column) %}

case
    when {{ column }}::text in ('NaN', 'NaT', '', 'null') then null
    when {{ column }} is null then null
    else cast({{ column }} as numeric)
end

{% endmacro %}