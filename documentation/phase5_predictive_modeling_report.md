# Phase 5 — Predictive Backorder Modeling

## 1. Executive Summary

Phase 5 developed and integrated a machine-learning model to estimate backorder risk for individual inventory SKUs.

The modeling workflow used the CLU inventory dataset, PostgreSQL for data preparation and storage, Python for model development, and Power BI for risk visualization.

A sigmoid-calibrated Random Forest classifier was selected following baseline comparisons, cross-validation, hyperparameter testing, and probability calibration.

The selected model was evaluated on an untouched labelled holdout dataset before being used to score 3,810 unlabelled inventory SKUs.

Predicted probabilities were classified into Low, Medium, and High risk categories and integrated into PostgreSQL and Power BI.

The outputs support analytical SKU prioritization. They are model estimates, not verified future backorder outcomes.



## 2. Business Problem and Modeling Objectives

### Business Problem

Inventory managers need to identify products that may be vulnerable to backorders so they can prioritize investigation and replenishment planning.

Historical backorder reports explain previously observed outcomes but do not directly provide risk estimates for unlabelled SKUs.

### Modeling Objectives

1. Develop a SKU-level binary classification model for historical backorder outcomes.
2. Compare candidate models using appropriate classification metrics.
3. Evaluate model reliability through cross-validation and an untouched holdout dataset.
4. Improve probability calibration before assigning risk categories.
5. Generate model-estimated backorder probabilities for unlabelled test SKUs.
6. Integrate prediction outputs into PostgreSQL and Power BI.
7. Preserve the distinction between observed historical outcomes and model-generated predictions.

### Primary Evaluation Metric

Average Precision (PR-AUC) was selected as the primary model-selection metric because the labelled dataset contains substantially fewer positive backorder outcomes than negative outcomes.

Additional metrics included ROC-AUC, precision, recall, F1-score, Brier score, and log loss.



## 3. Dataset and Feature Preparation

### Dataset Structure

The modeling dataset contained 19,053 inventory SKUs:

- 15,243 labelled training SKUs
- 3,810 unlabelled test SKUs

The labelled records contained the historical binary target `went_on_backorder`.

Among the 15,243 labelled SKUs:

- 1,813 were positive backorder cases.
- 13,430 were negative cases.

### Development and Holdout Split

The labelled data was divided using a stratified split:

- Development dataset: 12,194 SKUs
- Untouched holdout dataset: 3,049 SKUs

The holdout was reserved for final evaluation and was not used for routine model development or hyperparameter selection.

### Feature Selection

An initial set of 18 numerical predictors was considered.

Three forecast fields were subsequently excluded because their availability at the intended prediction time had not been independently established:

- `forecast_3_month`
- `forecast_6_month`
- `forecast_9_month`

The final model used 15 predictors:

1. national_inv
2. in_transit_qty
3. min_bank
4. sales_1_month
5. sales_3_month
6. sales_6_month
7. sales_9_month
8. lead_time
9. perf_6_month_avg
10. perf_12_month_avg
11. negative_inventory_flag
12. missing_lead_time_flag
13. zero_lead_time_flag
14. perf_6m_sentinel_flag
15. perf_12m_sentinel_flag

Additional potentially leakage-prone inventory fields were excluded during feature preparation.

Missing numerical values were handled using median imputation within the modeling pipeline.

The final feature set still requires independent confirmation that all predictors would be available before a real-world backorder outcome.



## 4. Model Development and Comparison

### Candidate Models

The following approaches were compared:

- Logistic Regression baseline
- Class-weighted Logistic Regression
- Random Forest classifier

Cross-validation was performed on the development dataset.

### Model Comparison

| Model | Average Precision |
|---|---:|
| Logistic Regression baseline | 0.2821 |
| Class-weighted Logistic Regression | 0.2894 |
| Random Forest, initial 18 features | 0.7327 |
| Random Forest, reduced 15 features | 0.7314 |
| Random Forest, repeated CV | 0.7315 |

The Random Forest substantially outperformed the Logistic Regression benchmarks on the primary selection metric.

Removing the three forecast variables produced only a small reduction in Average Precision, supporting the choice of the reduced feature set.

Repeated cross-validation provided an additional stability check.



## 5. Hyperparameter Tuning and Model Selection

### Hyperparameter Optimization

Random Forest hyperparameter optimization was performed on the development data.

The best tuned configuration achieved an Average Precision of approximately 0.7296, below the original reduced-feature configuration.

The tuned candidate also underperformed the original model in 13 out of 15 fold-level comparisons.

Therefore, the original reduced-feature Random Forest configuration was retained.

### Selected Random Forest Configuration

| Parameter | Selected Value |
|---|---|
| n_estimators | 200 |
| max_depth | 12 |
| min_samples_leaf | 5 |
| class_weight | balanced |
| random_state | 42 |
| n_jobs | -1 |
| Missing-value handling | Median imputation |
| Number of predictors | 15 |

Model selection was based on development-set evidence rather than the final holdout results.



## 6. Probability Calibration and Risk Thresholds

### Probability Calibration

Out-of-fold evaluation indicated that the original Random Forest probabilities were systematically high relative to the observed positive rate.

Before calibration:

- Mean predicted probability: approximately 25.34%
- Observed positive rate: approximately 11.89%
- Brier score: approximately 0.0821
- Log loss: approximately 0.2786

Sigmoid probability calibration was applied using cross-validation within the development workflow.

After calibration:

- Mean predicted probability: approximately 12.11%
- Brier score: approximately 0.0532
- Log loss: approximately 0.1797
- Average Precision: approximately 0.7310

Calibration improved the probability-based evaluation metrics on development out-of-fold predictions.

### Classification Threshold

A provisional classification threshold of 0.25 was selected using an illustrative assumption that missing a backorder could be approximately three times as costly as a false alarm.

This cost ratio was hypothetical and was not established using verified operational cost data.

The threshold therefore requires business validation before operational deployment.

### Risk Categories

| Category | Predicted Probability |
|---|---|
| Low | Below 0.10 |
| Medium | 0.10 to below 0.25 |
| High | 0.25 or above |

SKUs in the High category receive a predicted backorder flag of 1. Low- and Medium-risk SKUs receive a flag of 0.

These categories are analytical prioritization bands, not guarantees of future outcomes.



## 7. Final Holdout Evaluation

### Evaluation Method

The selected sigmoid-calibrated Random Forest was trained using
the 12,194-record development dataset.

Final performance was evaluated on the untouched stratified
holdout dataset containing 3,049 labelled inventory SKUs.

The holdout was reserved for final evaluation and was not
used for routine model selection or hyperparameter tuning.

### Final Holdout Performance

| Evaluation Metric | Result |
|---|---:|
| Holdout Records | 3,049 |
| Average Precision (PR-AUC) | 0.7235 |
| ROC-AUC | 0.9441 |
| Precision | 0.5957 |
| Recall | 0.7713 |
| F1-Score | 0.6723 |
| Brier Score | 0.0545 |
| Log Loss | 0.1834 |

Average Precision was the primary model-selection metric.

The final holdout Average Precision of 0.7235 was broadly
consistent with the development cross-validation results,
providing evidence of performance on unseen labelled records.

### Confusion Matrix

The final model was evaluated using the provisional
classification threshold of 0.25.

| Actual / Predicted | Predicted Negative | Predicted Positive |
|---|---:|---:|
| Actual Negative | 2,496 | 190 |
| Actual Positive | 83 | 280 |

The confusion matrix contained:

- True Negatives: 2,496
- False Positives: 190
- False Negatives: 83
- True Positives: 280

The model correctly identified 280 of the 363 actual
backorder cases in the holdout dataset.

It missed 83 actual backorder cases and incorrectly
flagged 190 non-backorder cases.

The final recall was approximately 77.13%, while
precision was approximately 59.57%.

### Evaluation Interpretation

The model demonstrated strong ranking performance on the
labelled holdout dataset.

However, false positives and false negatives remain
operationally important.

The selected threshold reflects an illustrative cost
assumption rather than verified replenishment economics.

The final holdout results should not be reused for
additional threshold tuning or model selection.

These results establish retrospective holdout performance,
not independently verified future forecasting accuracy.



## 8. Model Export and Unlabelled SKU Scoring

### Final Model Export

The selected fitted model was saved as:

`python/model_outputs/calibrated_random_forest.joblib`

Model metadata was saved separately in:

`python/model_outputs/calibrated_random_forest_metadata.json`

The exported model retained:

- Sigmoid-calibrated Random Forest classification
- Median imputation within the preprocessing pipeline
- The final set of 15 predictors
- A provisional classification threshold of 0.25

The saved model was reloaded and its predictions were
compared with the original fitted model.

The maximum observed floating-point difference was
approximately 6.66e-16, confirming numerical
reproducibility of the saved predictions.

### Unlabelled SKU Scoring

The saved model was applied to 3,810 unlabelled test SKUs.

These SKUs were not used as labelled examples in the
training or holdout evaluation process.

### Prediction Summary

| Prediction Metric | Result |
|---|---:|
| Total Scored SKUs | 3,810 |
| Minimum Predicted Probability | 0.0047 |
| Maximum Predicted Probability | 0.8601 |
| Mean Predicted Probability | 0.1237 |
| Flagged SKUs | 641 |
| Unflagged SKUs | 3,169 |
| Flagged SKU Percentage | 16.82% |

The highest-scoring SKU was:

- SKU: 1944734
- Estimated Backorder Probability: 86.01%
- Risk Category: High
- Prediction Flag: 1

### Risk Category Distribution

| Risk Category | SKUs | Share |
|---|---:|---:|
| Low | 2,947 | 77.35% |
| Medium | 222 | 5.83% |
| High | 641 | 16.82% |
| Total | 3,810 | 100.00% |

The categories were assigned using the following
provisional probability thresholds:

- Low: probability below 0.10
- Medium: probability from 0.10 to below 0.25
- High: probability of 0.25 or above

All High-risk SKUs received a predicted flag of 1.

### Prediction Export

The prediction output was exported to:

`python/model_outputs/sku_backorder_risk_predictions.csv`

The file contained 3,810 rows and six columns:

1. sku
2. predicted_backorder_probability
3. predicted_backorder_flag
4. classification_threshold
5. model_name
6. risk_category

The exported SKU identifiers were checked against
the original unlabelled test dataset.

No missing or additional SKUs were identified.

### Interpretation

The prediction file provides SKU-level estimated
backorder probabilities for analytical prioritization.

Because the 3,810 test SKUs do not have observed
backorder labels, their actual prediction accuracy
cannot be evaluated from this dataset.

The flagged SKU count represents the number selected
by the provisional model threshold, not the number
of backorders confirmed to have occurred.



## 9. PostgreSQL Prediction Integration

### Integration Objective

The Python-generated SKU-level predictions were
integrated into the existing PostgreSQL database
to support reproducible reporting in Power BI.

The integration preserved the original inventory
records and historical backorder labels.

### Source and Destination

Source file:
`python/model_outputs/sku_backorder_risk_predictions.csv`

PostgreSQL database:
`supply_chain_analytics`

Destination table:
`mart.sku_backorder_predictions`

### Prediction Table Structure

The PostgreSQL prediction table contains six fields:

| Column | PostgreSQL Data Type |
|---|---|
| sku | TEXT PRIMARY KEY |
| predicted_backorder_probability | NUMERIC(14,10) |
| predicted_backorder_flag | SMALLINT |
| classification_threshold | NUMERIC(14,10) |
| model_name | TEXT |
| risk_category | TEXT |

The table includes NOT NULL constraints and
validation checks for valid probabilities,
classification thresholds, prediction flags,
and risk categories.

The SKU identifier is the primary key, preventing
duplicate prediction records.

### Import and Validation

The exported CSV was imported into the
PostgreSQL prediction table.

The following checks were performed:

| Validation Check | Result |
|---|---:|
| Prediction records | 3,810 |
| Unique prediction SKUs | 3,810 |
| High-risk / flagged SKUs | 641 |
| Unflagged SKUs | 3,169 |
| Low-risk SKUs | 2,947 |
| Medium-risk SKUs | 222 |
| Unmatched inventory SKUs | 0 |
| Predictions linked to training SKUs | 0 |
| Missing predictions for test SKUs | 0 |

All prediction SKUs matched inventory records
belonging to the unlabelled test dataset.

The original `mart.fact_inventory` table retained
19,053 unique SKUs:

- 15,243 labelled training SKUs
- 3,810 unlabelled test SKUs

No original inventory records were removed
or overwritten during integration.

### Integration Interpretation

The prediction table is a separate analytical
output linked to inventory records by SKU.

The model-estimated probabilities are not
historical backorder outcomes.

This distinction was maintained throughout
the Power BI reporting workflow.



## 10. Power BI Predictive Dashboard

### Dashboard Objective

The predicted SKU backorder probabilities were
integrated into the existing Power BI project
to support SKU-level inventory risk analysis.

The predictive dashboard was developed separately
from the historical backorder dashboard.

### Power BI Data Model

The PostgreSQL table
`mart.sku_backorder_predictions`
was imported into Power BI.

The query was named:
`sku_backorder_predictions`

The six source columns were assigned the
appropriate Text, Decimal Number, and Whole
Number data types.

A relationship was established between:

`sku_backorder_predictions[sku]`

and

`mart fact_inventory[sku]`

The relationship was configured as:

- Cardinality: One-to-one (1:1)
- Cross-filter direction: Both
- Relationship status: Active

Both tables contained unique SKU identifiers.

The prediction table covered only the
3,810 unlabelled test SKUs, whereas the
inventory table contained all 19,053 SKUs.

### Predictive Dashboard

A dedicated report page was created:

`06 | Predicted Backorder Risk`

The page was titled:

PREDICTED BACKORDER RISK & SKU PRIORITIZATION

Its subtitle identified the CLU inventory
dataset and calibrated Random Forest model.

### KPI Measures

Ten permanent predictive DAX measures
were created and verified:

1. Total Predicted SKUs
2. High-Risk Predicted SKUs
3. High-Risk SKU Percentage
4. Average Predicted Backorder Probability
5. Medium-Risk Predicted SKUs
6. Low-Risk Predicted SKUs
7. Predicted Backorder Flagged SKUs
8. Predicted Backorder Flag Rate
9. Highest Predicted Backorder Probability
10. Unflagged Predicted SKUs

The dashboard displays six primary KPI Cards.

### Dashboard Visualizations

The predictive dashboard contains:

- Predicted Backorder Risk Distribution chart
- Top 10 SKUs by Predicted Backorder Risk chart
- SKU-Level Backorder Risk Predictions table
- Predicted Risk Category slicer

The SKU-level table includes:

- SKU identifier
- Predicted backorder probability
- Risk category
- Predicted backorder flag

The Top 10 chart ranks SKUs by model-estimated
backorder probability.

### Dashboard Interaction Testing

Risk-category filtering was tested for
High, Medium, and Low risk.

Cross-highlighting was corrected to
cross-filtering where required so that
the Top 10 SKU chart updates when a user
selects a risk category.

The interaction between the risk distribution
chart and the SKU-level prediction table
was also verified.

### Historical and Predictive Separation

The historical report page:

`05 | Backorder Risk`

was preserved.

The predictive report page:

`06 | Predicted Backorder Risk`

was created separately.

Historical outcomes and model-estimated risk
were not combined into one backorder metric.

### Formatting Scope

Final dashboard visual styling, spacing,
alignment, and presentation refinements
were deferred to Phase 6.



## 11. Validation and Quality Assurance

### Quality Assurance Objective

Validation was performed to confirm that
prediction outputs were imported correctly,
matched the inventory data model, and
produced consistent Power BI results.

### Prediction Import Validation

| Check | Expected | Result |
|---|---:|---|
| Prediction rows | 3,810 | PASS |
| Unique predicted SKUs | 3,810 | PASS |
| High-risk predictions | 641 | PASS |
| Low-risk predictions | 2,947 | PASS |
| Medium-risk predictions | 222 | PASS |
| Total inventory SKUs | 19,053 | PASS |

### Relationship Integrity

The prediction table was linked to the
inventory fact table through the SKU field.

The following checks were completed:

| Relationship Check | Result |
|---|---:|
| Matched prediction SKUs | 3,810 |
| Predicted training SKUs | 0 |
| Test SKUs missing predictions | 0 |
| Total inventory SKUs retained | 19,053 |

These checks confirmed complete coverage
of the 3,810 unlabelled test SKUs and
preservation of the complete inventory dataset.

### Classification Consistency

The prediction flag and risk-category rules
were validated against the exported
model-estimated probabilities.

Classification rules:

- Low: probability below 0.10, flag 0
- Medium: probability from 0.10 to below 0.25, flag 0
- High: probability of at least 0.25, flag 1

A Power BI calculated column was created:

`Classification Validation Status`

It classified each prediction record as
Valid or Mismatch.

A supporting measure was created:

`Prediction Classification Mismatches`

Final result:

- Valid prediction records: 3,810
- Classification mismatches: 0

### Predictive KPI Validation

With no risk-category filters applied,
the dashboard displayed:

| KPI | Validated Value |
|---|---:|
| Total Predicted SKUs | 3,810 |
| High-Risk Predicted SKUs | 641 |
| High-Risk SKU Percentage | 16.82% |
| Average Predicted Backorder Probability | 12.37% |
| Predicted Backorder Flagged SKUs | 641 |
| Highest Predicted Probability | 86.01% |

The highest-risk SKU was 1944734.

### Filter and Interaction Validation

High-risk filtering produced:

- 641 SKUs
- Average probability: 60.65%
- Highest probability: 86.01%

Medium-risk filtering produced:

- 222 SKUs
- Average probability: 16.77%
- Highest probability: 24.99%

Low-risk filtering produced:

- 2,947 SKUs
- Average probability: approximately 1.54%

The Top 10 SKU chart and SKU-level
prediction table were verified to respond
to risk-category filtering.

### Historical Data Preservation

The original historical Backorder Risk page
remained unchanged.

The existing inventory fact table retained
all 19,053 records.

The predictive outputs were maintained
separately from historical backorder outcomes.

### Final Validation Status

The recorded prediction import, model
relationship, classification consistency,
KPI, and report interaction checks passed.

The dashboard is ready for the final
Phase 5 evidence audit and sign-off.

This validation confirms analytical data
consistency, not prospective model accuracy.



## 12. Model Limitations and Assumptions

### 12.1 Retrospective Evaluation

Model performance was evaluated on historical labelled
CLU inventory records.

The final holdout evaluation provides evidence of
generalization within the available dataset.

It does not establish performance on future operational
inventory observations.

### 12.2 Prediction-Time Feature Availability

Although potentially leakage-prone fields and three
forecast variables were excluded, the availability of
all remaining predictors at the intended prediction
time has not been independently confirmed.

A production implementation would require feature
timestamp checks and a defined prediction horizon.

### 12.3 Dataset Limitations

The CLU inventory dataset does not establish complete
real-world operational context, including actual
replenishment decisions, verified backorder costs,
or future observed outcomes for the unlabelled SKUs.

The CLU inventory records and Olist e-commerce records
originate from separate datasets.

No shared real-world SKU or transaction relationship
between those datasets has been established.

Therefore, predictions should not be presented as
product-level forecasts for Olist orders.

### 12.4 Classification Threshold

The 0.25 classification threshold was selected using
an illustrative cost assumption.

The assumed relative cost of missed backorders and
false alarms was not independently validated.

Threshold selection should be revisited using
verified business costs and operational requirements
before deployment.

### 12.5 Probability Calibration

Sigmoid calibration improved probability-based
evaluation metrics during development.

Nevertheless, calibrated probabilities may become
unreliable if the inventory population, backorder
frequency, or operational environment changes.

Periodic calibration monitoring and prospective
validation would be required in production.

### 12.6 Model Errors

The final holdout contained:

- 190 false positives
- 83 false negatives

False positives may generate unnecessary investigation
or replenishment activity.

False negatives may cause genuine backorder risks
to be overlooked.

The model should support, rather than replace,
human inventory-management decisions.

### 12.7 Deployment Scope

The project demonstrates an analytical workflow
connecting Python, PostgreSQL, and Power BI.

It is not a live production prediction service.

The exported scores are a static scoring snapshot
and will not update automatically when inventory
records change.

A production system would require scheduled scoring,
data-quality monitoring, model monitoring, and
appropriate operational controls.

### 12.8 Recommended Future Improvements

Future development could include:

- Verification of prediction-time feature availability
- Prospective evaluation on newly observed outcomes
- Business-validated classification thresholds
- Monitoring for data and model drift
- Scheduled model scoring and dashboard refresh
- Operational testing of SKU prioritization decisions

These improvements were outside the completed Phase 5
implementation scope.



## 13. Final Deliverables and Phase 5 Sign-off

### 13.1 Phase 5 Deliverables

Phase 5 produced the following deliverables:

1. A Python notebook documenting inventory data preparation,
   feature selection, model development, and evaluation.

2. A fitted sigmoid-calibrated Random Forest classification
   pipeline using 15 numerical predictors.

3. Cross-validation and final holdout evaluation results.

4. A serialized machine-learning model and supporting
   configuration and metadata files.

5. SKU-level model-estimated backorder probabilities for
   3,810 unlabelled inventory SKUs.

6. A PostgreSQL prediction table containing the scored
   inventory records.

7. A dedicated Power BI predictive backorder risk dashboard.

8. A Power BI quality assurance page containing model
   integration and classification validation checks.

9. This Phase 5 predictive modeling documentation report.

### 13.2 Final Model Summary

| Item | Final Result |
|---|---|
| Selected Model | Sigmoid-Calibrated Random Forest |
| Final Predictors | 15 |
| Development Records | 12,194 |
| Holdout Records | 3,049 |
| Holdout Average Precision | 0.7235 |
| Holdout ROC-AUC | 0.9441 |
| Holdout F1-Score | 0.6723 |
| Classification Threshold | 0.25 |
| Scored Unlabelled SKUs | 3,810 |
| High-Risk SKUs | 641 |
| Medium-Risk SKUs | 222 |
| Low-Risk SKUs | 2,947 |

### 13.3 Final Quality Assurance

The following validation checks were completed:

- All 3,810 predicted SKUs matched inventory records.
- No training SKUs appeared in the prediction table.
- All 3,810 test SKUs had prediction records.
- No prediction classification mismatches remained.
- The complete inventory dataset retained 19,053 SKUs.
- Power BI risk-category filters and visual interactions
  were tested.
- Historical backorder reporting remained separate
  from model-estimated predictive risk.

### 13.4 Known Limitations

The model was evaluated retrospectively using labelled
inventory records.

Its ability to predict future operational backorders
has not been independently established.

The 0.25 classification threshold and risk categories
are provisional analytical choices.

Complete prediction-time feature availability has not
been independently verified.

The model output is a static scoring snapshot rather
than a live production forecasting system.

These limitations are documented in Section 12.

### 13.5 Phase 5 Acceptance Criteria

Phase 5 is eligible for sign-off when:

- All required Python modeling artifacts exist.
- Final holdout results match the saved evaluation files.
- The PostgreSQL prediction table contains 3,810 unique SKUs.
- The Power BI predictive dashboard displays the expected
  results without validation errors.
- Historical and predicted outcomes remain separate.
- All 13 sections of this documentation report are complete.
- The final Power BI project is saved.

### 13.6 Phase 5 Sign-off

Status: COMPLETE — subject to final artifact verification

Phase 5 established a reproducible analytical workflow
for estimating SKU-level backorder risk using Python,
PostgreSQL, and Power BI.

The developed model achieved a holdout Average Precision
of 0.7235 and produced calibrated risk estimates for
3,810 unlabelled inventory SKUs.

The prediction outputs were integrated into the existing
analytical environment and validated through data-quality,
relationship-integrity, classification-consistency, and
dashboard-interaction checks.

The deliverables are ready for final presentation and
portfolio preparation, subject to the documented modeling
limitations.

Next Phase:

Phase 6 — Final Dashboard Formatting, Full-Project Audit,
Documentation Review, and Portfolio Preparation.
