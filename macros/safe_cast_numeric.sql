{% macro safe_cast_numeric(column) %}

case
    when {{ column }} in ('NaN', 'NaT', '', 'null') then null
    else cast({{ column }} as numeric)
end

{% endmacro %}