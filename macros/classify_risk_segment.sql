{% macro classify_risk_segment(score) %}

case
    when {{ score }} >= 75 then 'high_risk'
    when {{ score }} >= 40 then 'medium_risk'
    else 'low_risk'
end

{% endmacro %}