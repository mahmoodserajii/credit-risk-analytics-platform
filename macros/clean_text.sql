{% macro clean_text(column) %}

case
    when {{ column }} is null then null
    when trim({{ column }}) in ('NaN', 'NaT', '', 'null') then null
    else trim(initcap({{ column }}))
end

{% endmacro %}