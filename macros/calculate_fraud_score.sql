{% macro calculate_fraud_score(
    future_transaction,
    negative_amount,
    abnormal_amount
) %}

(
    (case when {{ future_transaction }} then 40 else 0 end)
  + (case when {{ negative_amount }} then 30 else 0 end)
  + (case when {{ abnormal_amount }} then 30 else 0 end)
)

{% endmacro %}