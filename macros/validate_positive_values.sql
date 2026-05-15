{% macro validate_positive_values(column) %}

case
    when {{ column }} < 0 then false
    else true
end

{% endmacro %}