{% macro validate_date_not_future(column) %}

case
    when {{ column }} > current_timestamp then false
    else true
end

{% endmacro %}