{% macro validate_ratio_range(column, min_value, max_value) %}

case
    when {{ column }} between {{ min_value }} and {{ max_value }}
    then true
    else false
end

{% endmacro %}