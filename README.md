# 🏦 Loan Approval Prediction Using Machine Learning in Snowflake

## 📌 Project Overview

This project implements an end-to-end Machine Learning system for predicting whether a loan application will be approved or rejected.

The project uses **Snowflake** for data storage, data cleaning, exploratory data analysis, feature engineering, machine learning model training, evaluation, and prediction.

A **Streamlit application deployed in Snowflake** provides an interactive interface where users can enter applicant information and receive a predicted loan approval result with an approval probability.

---

## 🎯 Problem Statement

Loan approval decisions depend on several applicant characteristics such as income, loan amount, credit history, education, marital status, dependents, employment status, and property area.

The objective of this project is to build a **Binary Classification** model that predicts whether a loan application will be approved.

### Target Variable

- `1` = Loan Approved
- `0` = Loan Rejected

---

## 🧠 Machine Learning Problem

**Problem Type:** Binary Classification

**Machine Learning Model:** Snowflake ML Classification

**Model Name:**

`LOAN_APPROVAL_MODEL`

The model is created using Snowflake's native Machine Learning functionality.

---

## 📊 Dataset

The dataset contains **381 loan applications**.

### Dataset Features

| Feature | Description |
|---|---|
| LOAN_ID | Unique loan application identifier |
| GENDER | Applicant gender |
| MARRIED | Applicant marital status |
| DEPENDENTS | Number of dependents |
| EDUCATION | Applicant education level |
| SELF_EMPLOYED | Self-employment status |
| APPLICANTINCOME | Applicant income |
| COAPPLICANTINCOME | Co-applicant income |
| LOANAMOUNT | Requested loan amount |
| LOAN_AMOUNT_TERM | Loan repayment term |
| CREDIT_HISTORY | Credit history indicator |
| PROPERTY_AREA | Property area |
| LOAN_STATUS | Loan approval status |

---

## 🏗️ Project Architecture

```text
Loan Dataset
     │
     ▼
Snowflake Data Storage
     │
     ▼
Data Cleaning
     │
     ▼
Exploratory Data Analysis
     │
     ▼
Feature Engineering
     │
     ▼
ML-Ready Dataset
     │
     ▼
Snowflake ML Classification
     │
     ▼
Model Evaluation
     │
     ▼
Loan Predictions
     │
     ▼
Streamlit Application
