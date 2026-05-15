{% macro calculate_risk_score(
    negative_balance,
    high_transaction_volume,
    invalid_loan,
    fraud_signal
) %}

(
    (case when {{ negative_balance }} then 25 else 0 end)
  + (case when {{ high_transaction_volume }} then 25 else 0 end)
  + (case when {{ invalid_loan }} then 25 else 0 end)
  + (case when {{ fraud_signal }} then 25 else 0 end)
)

{% endmacro %}