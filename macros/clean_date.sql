{% macro clean_date(column) %}

case
    -- 1. Handle Nulls and common "bad string" indicators
    when {{ column }} is null 
      or {{ column }}::text in ('NaN', 'NaT', '', 'null', 'NULL') then null

    -- 2. Extract first 10 chars and check YYYY-MM-DD format
    when left({{ column }}::text, 10) !~ '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$'
        then null

    -- 3. Prevent 31st on 30-day months
    when split_part(left({{ column }}::text, 10), '-', 2) in ('04', '06', '09', '11') 
         and split_part(left({{ column }}::text, 10), '-', 3) = '31' then null

    -- 4. Prevent Feb 30th and 31st
    when split_part(left({{ column }}::text, 10), '-', 2) = '02' 
         and split_part(left({{ column }}::text, 10), '-', 3) > '29' then null

    -- 5. Safe to cast the original column to DATE
    else cast({{ column }} as date)

end

{% endmacro %}
