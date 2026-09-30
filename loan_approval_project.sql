-- ============================================================
-- LOAN APPROVAL PREDICTION USING MACHINE LEARNING IN SNOWFLAKE
-- ============================================================
-- Project Type: Binary Classification
-- Dataset Records: 381
-- Model: Snowflake ML Classification
-- Model Name: LOAN_APPROVAL_MODEL
-- ============================================================


-- ============================================================
-- 1. DATABASE AND SCHEMA SETUP
-- ============================================================

CREATE OR REPLACE DATABASE LOAN_ML_PROJECT;

USE DATABASE LOAN_ML_PROJECT;

CREATE OR REPLACE SCHEMA LOAN_ML_PROJECT.PUBLIC;

USE SCHEMA LOAN_ML_PROJECT.PUBLIC;

USE WAREHOUSE COMPUTE_WH;


-- ============================================================
-- 2. RAW DATA
-- ============================================================
-- The dataset was loaded into:
-- LOAN_ML_PROJECT.PUBLIC.LOAN_DATA
--
-- Columns:
-- LOAN_ID
-- GENDER
-- MARRIED
-- DEPENDENTS
-- EDUCATION
-- SELF_EMPLOYED
-- APPLICANTINCOME
-- COAPPLICANTINCOME
-- LOANAMOUNT
-- LOAN_AMOUNT_TERM
-- CREDIT_HISTORY
-- PROPERTY_AREA
-- LOAN_STATUS
--
-- Dataset size: 381 records
-- ============================================================


-- ============================================================
-- 3. CHECK MISSING VALUES
-- ============================================================

SELECT
    COUNT_IF(GENDER IS NULL) AS MISSING_GENDER,
    COUNT_IF(MARRIED IS NULL) AS MISSING_MARRIED,
    COUNT_IF(DEPENDENTS IS NULL) AS MISSING_DEPENDENTS,
    COUNT_IF(SELF_EMPLOYED IS NULL) AS MISSING_SELF_EMPLOYED,
    COUNT_IF(LOANAMOUNT IS NULL) AS MISSING_LOAN_AMOUNT,
    COUNT_IF(CREDIT_HISTORY IS NULL) AS MISSING_CREDIT_HISTORY,
    COUNT_IF(LOAN_STATUS IS NULL) AS MISSING_LOAN_STATUS
FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA;


-- ============================================================
-- 4. DATA CLEANING
-- ============================================================

CREATE OR REPLACE TABLE LOAN_ML_PROJECT.PUBLIC.LOAN_DATA_CLEAN AS
SELECT
    LOAN_ID,

    COALESCE(GENDER, 'Male') AS GENDER,

    MARRIED,

    COALESCE(DEPENDENTS, '0') AS DEPENDENTS,

    EDUCATION,

    COALESCE(SELF_EMPLOYED, FALSE) AS SELF_EMPLOYED,

    APPLICANTINCOME,

    COAPPLICANTINCOME,

    LOANAMOUNT,

    LOAN_AMOUNT_TERM,

    COALESCE(CREDIT_HISTORY, 1) AS CREDIT_HISTORY,

    PROPERTY_AREA,

    LOAN_STATUS

FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA;


-- ============================================================
-- 5. VERIFY CLEAN DATA
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_RECORDS,

    COUNT_IF(GENDER IS NULL) AS MISSING_GENDER,

    COUNT_IF(DEPENDENTS IS NULL) AS MISSING_DEPENDENTS,

    COUNT_IF(SELF_EMPLOYED IS NULL) AS MISSING_SELF_EMPLOYED,

    COUNT_IF(CREDIT_HISTORY IS NULL) AS MISSING_CREDIT_HISTORY

FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA_CLEAN;


-- ============================================================
-- 6. EXPLORATORY DATA ANALYSIS
-- ============================================================

-- Loan approval distribution

SELECT
    LOAN_STATUS,
    COUNT(*) AS APPLICATION_COUNT
FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA_CLEAN
GROUP BY LOAN_STATUS
ORDER BY LOAN_STATUS;


-- Education versus loan approval

SELECT
    EDUCATION,
    COUNT(*) AS TOTAL_APPLICATIONS,
    COUNT_IF(LOAN_STATUS = TRUE) AS APPROVED_APPLICATIONS
FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA_CLEAN
GROUP BY EDUCATION
ORDER BY EDUCATION;


-- Property area versus loan approval

SELECT
    PROPERTY_AREA,
    COUNT(*) AS TOTAL_APPLICATIONS,
    COUNT_IF(LOAN_STATUS = TRUE) AS APPROVED_APPLICATIONS
FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA_CLEAN
GROUP BY PROPERTY_AREA
ORDER BY PROPERTY_AREA;


-- ============================================================
-- 7. FEATURE ENGINEERING
-- ============================================================

CREATE OR REPLACE TABLE LOAN_ML_PROJECT.PUBLIC.LOAN_ML_READY AS

SELECT
    LOAN_ID,

    APPLICANTINCOME,

    COAPPLICANTINCOME,

    LOANAMOUNT,

    LOAN_AMOUNT_TERM,

    CREDIT_HISTORY,

    CASE
        WHEN GENDER = 'Male' THEN 1
        ELSE 0
    END AS GENDER_MALE,

    CASE
        WHEN MARRIED = TRUE THEN 1
        ELSE 0
    END AS MARRIED,

    CASE
        WHEN DEPENDENTS = '0' THEN 0
        WHEN DEPENDENTS = '1' THEN 1
        WHEN DEPENDENTS = '2' THEN 2
        ELSE 3
    END AS DEPENDENTS,

    CASE
        WHEN EDUCATION = 'Graduate' THEN 1
        ELSE 0
    END AS GRADUATE,

    CASE
        WHEN SELF_EMPLOYED = TRUE THEN 1
        ELSE 0
    END AS SELF_EMPLOYED,

    CASE
        WHEN PROPERTY_AREA = 'Rural' THEN 0
        WHEN PROPERTY_AREA = 'Semiurban' THEN 1
        WHEN PROPERTY_AREA = 'Urban' THEN 2
        ELSE 0
    END AS PROPERTY_AREA,

    CASE
        WHEN LOAN_STATUS = TRUE THEN 1
        ELSE 0
    END AS LOAN_APPROVED

FROM LOAN_ML_PROJECT.PUBLIC.LOAN_DATA_CLEAN;


-- ============================================================
-- 8. VERIFY ML-READY DATA
-- ============================================================

SELECT
    COUNT(*) AS TOTAL_APPLICATIONS,

    SUM(LOAN_APPROVED) AS APPROVED_APPLICATIONS,

    COUNT(*) - SUM(LOAN_APPROVED) AS REJECTED_APPLICATIONS

FROM LOAN_ML_PROJECT.PUBLIC.LOAN_ML_READY;


-- ============================================================
-- 9. CREATE TRAINING VIEW
-- ============================================================

CREATE OR REPLACE VIEW LOAN_ML_PROJECT.PUBLIC.LOAN_TRAINING_VIEW AS

SELECT *
FROM LOAN_ML_PROJECT.PUBLIC.LOAN_ML_READY;


-- ============================================================
-- 10. CREATE SNOWFLAKE ML CLASSIFICATION MODEL
-- ============================================================

USE DATABASE LOAN_ML_PROJECT;

USE SCHEMA PUBLIC;

USE WAREHOUSE COMPUTE_WH;


CREATE OR REPLACE SNOWFLAKE.ML.CLASSIFICATION LOAN_APPROVAL_MODEL(
    INPUT_DATA => SYSTEM$REFERENCE(
        'VIEW',
        'LOAN_TRAINING_VIEW'
    ),

    TARGET_COLNAME => 'LOAN_APPROVED',

    CONFIG_OBJECT => {
        'evaluate': TRUE
    }
);


-- ============================================================
-- 11. CHECK MODEL
-- ============================================================

SHOW SNOWFLAKE.ML.CLASSIFICATION;


-- ============================================================
-- 12. MODEL EVALUATION
-- ============================================================

CALL LOAN_APPROVAL_MODEL!SHOW_EVALUATION_METRICS();


-- Evaluation results obtained during the project:
--
-- Evaluation samples: 77
--
-- Class 0:
-- Precision: 0.9000
-- Recall:    0.4286
-- F1 Score:  0.5806
--
-- Class 1:
-- Precision: 0.8209
-- Recall:    0.9821
-- F1 Score:  0.8943
--
-- Confusion Matrix:
--
-- Actual 0 / Predicted 0 = 9
-- Actual 0 / Predicted 1 = 12
-- Actual 1 / Predicted 0 = 1
-- Actual 1 / Predicted 1 = 55
--
-- Calculated held-out evaluation accuracy:
-- (9 + 55) / 77 = 83.12%


-- ============================================================
-- 13. FEATURE IMPORTANCE
-- ============================================================

CALL LOAN_APPROVAL_MODEL!SHOW_FEATURE_IMPORTANCE();


-- Feature importance observed during the project:
--
-- APPLICANTINCOME    = 0.341563786
-- LOANAMOUNT         = 0.255829904
-- COAPPLICANTINCOME  = 0.152263375
-- PROPERTY_AREA      = 0.061728395
-- DEPENDENTS         = 0.044581619
-- CREDIT_HISTORY     = 0.039780521
-- LOAN_AMOUNT_TERM   = 0.028120713
-- MARRIED            = 0.027434842
-- GRADUATE           = 0.022633745
-- GENDER_MALE        = 0.020576132
-- SELF_EMPLOYED      = 0.005486968


-- ============================================================
-- 14. GENERATE PREDICTIONS
-- ============================================================

CREATE OR REPLACE TABLE LOAN_ML_PROJECT.PUBLIC.LOAN_PREDICTIONS AS

SELECT
    *,
    LOAN_APPROVAL_MODEL!PREDICT(
        INPUT_DATA => {*}
    ) AS PREDICTION

FROM LOAN_ML_PROJECT.PUBLIC.LOAN_ML_READY;


-- ============================================================
-- 15. VIEW SAMPLE PREDICTIONS
-- ============================================================

SELECT
    LOAN_ID,

    LOAN_APPROVED AS ACTUAL_STATUS,

    PREDICTION

FROM LOAN_ML_PROJECT.PUBLIC.LOAN_PREDICTIONS

LIMIT 20;


-- ============================================================
-- 16. PREDICTION DISTRIBUTION
-- ============================================================

SELECT
    PREDICTION:"class"::STRING AS PREDICTED_STATUS,
    COUNT(*) AS COUNT
FROM LOAN_ML_PROJECT.PUBLIC.LOAN_PREDICTIONS
GROUP BY PREDICTION:"class"::STRING
ORDER BY PREDICTED_STATUS;


-- ============================================================
-- PROJECT SUMMARY
-- ============================================================
--
-- Dataset records:             381
-- Approved applications:       271
-- Rejected applications:       110
-- Evaluation samples:           77
-- Held-out evaluation accuracy: 83.12%
-- Class 1 recall:               98.21%
-- Class 0 recall:               42.86%
--
-- Full-data prediction agreement:
-- 379 / 381 = 99.48%
--
-- NOTE:
-- 99.48% is an in-sample/full-data prediction agreement.
-- It should NOT be presented as independent test accuracy.
--
-- Model:
-- LOAN_APPROVAL_MODEL
--
-- Application:
-- Snowflake Streamlit
--
-- ============================================================
