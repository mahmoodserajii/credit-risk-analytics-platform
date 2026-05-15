{% macro standardize_dates(column) %}

case
    when {{ column }} in ('NaT', '', 'null') then null
    else cast({{ column }} as timestamp)
end

{% endmacro %}