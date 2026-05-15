{% macro remove_special_characters(column) %}

regexp_replace({{ column }}, '[^a-zA-Z0-9 ]', '', 'g')

{% endmacro %}