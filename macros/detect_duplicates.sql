{% macro detect_duplicates(column) %}

count(*) over (
    partition by {{ column }}
) > 1

{% endmacro %}