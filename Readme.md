![dbt](https://img.shields.io/badge/dbt-1.11-orange)
![Postgres](https://img.shields.io/badge/PostgreSQL-16-blue)
![Status](https://img.shields.io/badge/status-production--style-success)
![Tests](https://img.shields.io/badge/tests-passing-brightgreen)

# Credit Risk Analytics & Transaction Surveillance Platform

Production-grade financial analytics platform built with dbt Core and PostgreSQL for credit risk modeling, fraud detection, customer behavioral analytics, and executive risk reporting.

## Key Capabilities

* Layered analytics engineering architecture (staging → intermediate → feature store → marts)
* Automated financial data quality validation
* Customer 360 analytical modeling
* Fraud velocity and anomaly detection
* Credit risk segmentation and exposure analysis
* Portfolio-level lending risk monitoring
* Reusable Jinja macro framework
* End-to-end dbt testing and lineage tracking

## Tech Stack

| Layer          | Technology        |
| -------------- | ----------------- |
| Transformation | dbt Core 1.11     |
| Warehouse      | PostgreSQL        |
| Orchestration  | dbt DAG           |
| Testing        | dbt Tests         |
| Documentation  | dbt Docs          |
| Analytics      | SQL + Jinja       |
| Architecture   | Modern Data Stack |

---
## Engineering Highlights

- 50+ dbt models
- Layered medallion architecture
- Feature engineering layer for ML systems
- Fraud velocity detection using SQL window functions
- Percentile-based anomaly detection
- Defensive casting and malformed data handling
- Automated referential integrity testing
- Customer segmentation and behavioral analytics

---

# 1. Core Architectural & Risk Principles

Financial pipelines require strict reliability guarantees. A single malformed value can corrupt aggregations, distort statistical calculations, or break orchestration workflows entirely.

This platform follows three foundational engineering principles:

---

## Defensive Cast Gating

Raw source fields are treated as inherently untrusted.

External ingestion systems frequently introduce malformed values such as:

* `'NaN'`
* `'NaT'`
* `'null'`
* empty strings
* invalid date formats
* currency-contaminated numeric values

To prevent downstream failures, all staging models apply centralized Jinja cleaning macros before type casting.

This guarantees:

* safe date parsing
* deterministic numeric calculations
* stable aggregation logic
* statistically reliable analytical layers

---

## Multi-Tiered Logical Gating for Credit Risk

Traditional segmentation models often rely heavily on:

```text
Net Transaction Flow = Gross Inflow - Gross Outflow
```

as the primary customer scale indicator.

This introduces critical logical edge cases.

Example:

* A customer earning €100,000 monthly and reinvesting €95,000 may incorrectly appear financially weak.
* A customer with high gross inflow but structurally negative balances may appear financially healthy.

To eliminate these inconsistencies, the platform applies a prioritized sequential risk funnel.

```text
[Raw Ingestion Target]
          │
          ▼
┌──────────────────┐
│  Staging Layer   │ ──► Typographical & String Cleaning
└──────────────────┘
          │
          ▼
┌──────────────────┐
│ Intermediate     │ ──► Behavioral Analysis & Time-Series Framing
└──────────────────┘
          │
          ▼
┌──────────────────┐
│ Feature Store    │ ──► Dynamic Risk Scoring
└──────────────────┘
          │
          ▼
┌──────────────────┐
│ Marts Layer      │ ──► Business Risk Segmentation
└──────────────────┘
```

### Sequential Risk Funnel

1. **Risk Exclusion Gating**
   Accounts with structurally negative balances or persistent negative cashflows are immediately classified as `financially_risky`.

2. **Gross Scale Tracking**
   Remaining accounts are evaluated using gross inflows to determine processing scale and customer value tiers.

3. **Relative Stability Verification**
   Qualified accounts are then evaluated using relative cashflow volatility metrics to validate premium-tier classification.

---

# 2. Terminology & Core Financial Metrics

## Gross Inflow (`total_amount_received`)

The total sum of all incoming ledger credits processed by an entity during a defined timeframe.

Primary uses:

* customer value segmentation
* account scale tracking

---

## Gross Outflow (`total_amount_sent`)

The total sum of all outgoing debits initiated by an entity.

---

## Net Transaction Flow (`net_transaction_flow`)

```text
Net Transaction Flow = Gross Inflow - Gross Outflow
```

Measures directional capital movement.

---

## Cashflow Volatility (`cashflow_volatility`)

Historical standard deviation of monthly net cashflows.

```text
σ = √( Σ(x - μ)² / N )
```

Used to evaluate financial stability over time.

---

## Coefficient of Variation (CV)

Absolute volatility alone is scale-blind.

A €1,000 fluctuation is significant for a student account but negligible for a corporation.

The platform therefore measures relative volatility:

```text
CV = Cashflow Volatility / |Average Monthly Cashflow|
```

Accounts are classified as `stable_cashflow` when:

```text
CV < 0.50
```

---

## Portfolio Risk Segments

Monthly lending cohorts are segmented using weighted average interest rates.

| Risk Segment       | Condition                |
| ------------------ | ------------------------ |
| High Risk Period   | Interest Rate > 15%      |
| Medium Risk Period | 8% < Interest Rate ≤ 15% |
| Low Risk Period    | Interest Rate ≤ 8%       |

---

## Anomalous Transaction Ceiling

Upper statistical threshold used to detect transactional outliers.

```text
Ceiling = μ_account + (3 × σ_account)
```

---

# 3. Custom Global Jinja Macros

The platform uses centralized Jinja macros to standardize data-cleaning logic across staging models.

---

## `clean_date(column)`

Prevents malformed date strings from generating parsing failures.

```sql
{% macro clean_date(column) %}

case
    when {{ column }} is null
      or {{ column }}::text in ('NaN', 'NaT', '', 'null', 'NULL') then null

    when left({{ column }}::text, 10)
         !~ '^\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])$'
    then null

    when split_part(left({{ column }}::text, 10), '-', 2)
         in ('04', '06', '09', '11')
         and split_part(left({{ column }}::text, 10), '-', 3) = '31'
    then null

    when split_part(left({{ column }}::text, 10), '-', 2) = '02'
         and split_part(left({{ column }}::text, 10), '-', 3) > '29'
    then null

    else cast({{ column }} as date)

end

{% endmacro %}
```

---

## `clean_numeric_str(column)`

Removes whitespace, currency symbols, and invalid characters before numeric casting.

```sql
{% macro clean_numeric_str(column) %}

cast(
    nullif(
        regexp_replace(
            {{ column }}::text,
            '[^0-9.-]',
            '',
            'g'
        ),
        ''
    ) as numeric
)

{% endmacro %}
```

---

# 4. DAG & Model Lineage

```text
 [stg_transactions] ──► [int_transaction_velocity] ─┐
                    ──► [int_transaction_outliers] ─┼──► [fct_fraud_features]
                    ──► [int_transaction_behavior] ─┘              │
                                                                   ▼
                                                [mart_fraud_risk_monitoring]

 [stg_accounts] ──► [int_customer_profile] ─────┐
                 ──► [int_cashflow_stability] ──┼──► [fct_customer_risk_features]
                                                 │                │
                                                 ▼                ▼
                                          [mart_customer_360] [mart_credit_risk]

 [stg_loans] ──► [int_loan_repayment_risk] ──► [fct_loan_risk_features]
               ─► [int_loan_portfolio_trends] ─────────────────────────► [mart_loan_portfolio]
```

---

# 5. Model Directory & Specifications

# 5.1 Staging Layer

### Grain: Raw Source Ingestion

---

## `stg_transactions`

Cleans and standardizes raw transaction records using centralized macros.

### Primary Key

* `transaction_id`

### Responsibilities

* clean malformed timestamps
* sanitize numeric amounts
* validate identifiers
* expose normalized transaction grain

---

## `stg_accounts`

Processes customer account metadata and safely casts system identifiers.

### Primary Key

* `account_id`

---

## `stg_loans`

Normalizes loan issuance records and filters invalid entries.

### Primary Key

* `loan_id`

---

# 5.2 Intermediate Layer

### Grain: Historical Entity Aggregations

---

## `int_transaction_behavior`

Tracks account-level transaction activity patterns.

### Grain

* `account_id`

### Features

* active transaction days
* average daily activity
* peak transaction volume

```sql
select
    account_origin_id as account_id,
    count(distinct date(transaction_date)) as active_transaction_days,
    avg(daily_count) as avg_daily_transaction_count,
    max(daily_volume) as max_daily_transaction_volume
```

---

## `int_transaction_outliers`

Detects anomalous transaction sizes using percentile-based thresholds.

### Grain

* `transaction_id`

```sql
percentile_cont(0.99)
within group (order by amount)
```

---

## `int_transaction_velocity`

Detects fraud velocity spikes using rolling one-hour transaction windows.

### Grain

* `transaction_id`

```sql
count(*) over (
    partition by account_origin_id
    order by transaction_date
    range between interval '1 hour' preceding and current row
) as txn_count_last_hour
```

---

## `int_cashflow_stability`

Computes customer-level financial stability metrics.

### Grain

* `customer_id`

### Core Features

* monthly net cashflow aggregation
* volatility calculations
* coefficient of variation scoring
* stable cashflow classification

---

## `int_loan_portfolio_trends`

Tracks lending portfolio behavior across monthly cohorts.

### Grain

* `loan_month`

### Features

* weighted interest rate trends
* portfolio segmentation
* macro risk classification

---

# 5.3 Feature Store Layer

### Grain: Analytical Entity Features

---

## `fct_fraud_features`

Transaction-level fraud scoring feature store.

### Grain

* `transaction_id`

### Risk Weight Matrix

| Feature                      | Weight |
| ---------------------------- | ------ |
| Abnormally Large Transaction | 30     |
| High Velocity Flag           | 25     |
| High Frequency Connection    | 25     |
| Outlier Detection            | 20     |

### Risk Segments

| Score | Segment             |
| ----- | ------------------- |
| ≥ 70  | `high_fraud_risk`   |
| ≥ 40  | `medium_fraud_risk` |
| < 40  | `low_fraud_risk`    |

---

## `fct_customer_risk_features`

Centralized customer risk feature store.

### Grain

* `customer_id`

### Volatility Normalization

```sql
case
    when cashflow_volatility >= 10000 then 100.0
    else (cashflow_volatility / 10000.0) * 100.0
end
```

---

## `fct_loan_risk_features`

Evaluates individual loan records against portfolio-level standards.

### Grain

* `loan_id`

---

# 5.4 Marts Layer

### Grain: Business Delivery Layer

---

## `mart_customer_360`

Primary operational mart for customer analytics and segmentation.

### Grain

* `customer_id`

### Priority Segmentation Matrix

The `priority_segment` classification combines customer value tiers, behavioral stability, and credit risk indicators into operational business categories used for underwriting, monitoring, retention, and escalation workflows.

| Customer Value Segment  | Customer Risk Segment     | Behavioral Segment   | Priority Segment       |
| ----------------------- | ------------------------- | -------------------- | ---------------------- |
| `high_value_customer`   | `high_risk`               | Any                  | `high_value_high_risk` |
| `mid_value_customer`    | `high_risk`               | Any                  | `mid_value_high_risk`  |
| `standard_customer`     | `high_risk`               | Any                  | `low_value_high_risk`  |
| Any                     | `low_risk`                | `premium_stable`     | `premium_growth`       |
| `high_value_customer`   | `medium_risk`             | Any                  | `high_value_monitored` |
| `mid_value_customer`    | `low_risk`                | Any                  | `mid_market_stable`    |
| `standard_customer`     | `medium_risk`             | Any                  | `early_warning_risk`   |
| `mid_value_customer`    | Any                       | Any                  | `standard_mid_tier`    |
| All Remaining Customers | All Remaining Risk States | All Remaining States | `standard_retail`      |



# 6. Testing & Data Quality Standards

The platform uses automated dbt validation layers to enforce financial data integrity.

---

## Test Architecture

```yaml
columns:
  - name: fraud_risk_segment
    tests:
      - not_null
      - accepted_values:
          arguments:
            values:
              - low_fraud_risk
              - medium_fraud_risk
              - high_fraud_risk
```

---

## Mandatory Data Protections

### 1. Primary Key Integrity

All primary keys enforce:

* `unique`
* `not_null`

---

### 2. Referential Integrity

Foreign keys are validated using `relationships` tests to prevent orphaned records.

Examples:

* `customer_id`
* `account_id`
* `branch_id`

---

### 3. Controlled Categorical Domains

Risk labels and behavioral flags are protected using strict `accepted_values` validation tests.

---

# 7. Operational Deployment & Orchestration

## Environment Setup

```bash
python -m venv venv

# Linux / macOS
source venv/bin/activate

# Windows Powershell
.\venv\Scripts\activate

pip install dbt-core==1.11.9 dbt-postgres==1.10.0
```

---

## Production Execution

```bash
# Clean local artifacts
dbt clean

# Compile dependency graph
dbt compile

# Execute full pipeline
dbt build --no-partial-parse

# Execute monitoring-only pipeline
dbt build --select tag:monitoring --no-partial-parse
```

---

## Source Freshness Monitoring

```yaml
sources:
  - name: raw
    freshness:
      warn_after:
        count: 12
        period: hour

      error_after:
        count: 24
        period: hour

    loaded_at_field: ingestion_timestamp
```

Run freshness validation:

```bash
dbt source freshness
```

---

## Business Problems Solved

This platform addresses critical financial analytics challenges:

- Detects high-risk transactional anomalies
- Identifies unstable customer cashflow behavior
- Tracks portfolio-level lending exposure
- Supports underwriting and credit risk workflows
- Generates executive-level banking KPIs
- Creates reusable ML-ready feature stores

# Final Notes

If scoring logic, macro validations, or segmentation thresholds are modified, the corresponding `.yml` documentation and automated tests should also be updated to maintain consistency across:

* lineage tracking
* validation rules
* model documentation
* downstream reporting
* orchestration workflows
