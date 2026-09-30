import streamlit as st
import json

st.set_page_config(
    page_title="Loan Approval Predictor",
    page_icon="🏦",
    layout="centered"
)

st.title("🏦 Loan Approval Prediction")
st.write("Machine Learning prediction powered by Snowflake")

st.subheader("Applicant Information")

applicant_income = st.number_input(
    "Applicant Income",
    min_value=0.0,
    value=5000.0
)

coapplicant_income = st.number_input(
    "Coapplicant Income",
    min_value=0.0,
    value=0.0
)

loan_amount = st.number_input(
    "Loan Amount",
    min_value=0.0,
    value=150.0
)

loan_term = st.number_input(
    "Loan Amount Term",
    min_value=1,
    value=360
)

credit_history = st.selectbox(
    "Credit History",
    ["Good", "Poor"]
)

gender = st.selectbox(
    "Gender",
    ["Male", "Female"]
)

married = st.selectbox(
    "Married",
    ["Yes", "No"]
)

dependents = st.selectbox(
    "Dependents",
    ["0", "1", "2", "3+"]
)

education = st.selectbox(
    "Education",
    ["Graduate", "Not Graduate"]
)

self_employed = st.selectbox(
    "Self Employed",
    ["No", "Yes"]
)

property_area = st.selectbox(
    "Property Area",
    ["Rural", "Semiurban", "Urban"]
)

if st.button("Predict Loan Approval", type="primary"):

    gender_male = 1 if gender == "Male" else 0
    married_value = 1 if married == "Yes" else 0

    dependents_value = {
        "0": 0,
        "1": 1,
        "2": 2,
        "3+": 3
    }[dependents]

    graduate_value = 1 if education == "Graduate" else 0
    employed_value = 1 if self_employed == "Yes" else 0

    property_value = {
        "Rural": 0,
        "Semiurban": 1,
        "Urban": 2
    }[property_area]

    credit_value = 1 if credit_history == "Good" else 0

    query = f"""
    SELECT
        LOAN_APPROVAL_MODEL!PREDICT(
            INPUT_DATA => {{
                'APPLICANTINCOME': {applicant_income},
                'COAPPLICANTINCOME': {coapplicant_income},
                'LOANAMOUNT': {loan_amount},
                'LOAN_AMOUNT_TERM': {loan_term},
                'CREDIT_HISTORY': {credit_value},
                'GENDER_MALE': {gender_male},
                'MARRIED': {married_value},
                'DEPENDENTS': {dependents_value},
                'GRADUATE': {graduate_value},
                'SELF_EMPLOYED': {employed_value},
                'PROPERTY_AREA': {property_value}
            }}
        ) AS PREDICTION
    """

    session = st.connection("snowflake").session()

    session.sql("USE DATABASE LOAN_ML_PROJECT").collect()
    session.sql("USE SCHEMA PUBLIC").collect()

    result = session.sql(query).collect()[0]["PREDICTION"]

    if isinstance(result, str):
        result = json.loads(result)

    predicted_class = result["class"]
    probability = result["probability"]

    approval_probability = float(probability["1"])

    if predicted_class == "1":
        st.success("✅ Loan is predicted to be APPROVED")
    else:
        st.error("❌ Loan is predicted to be REJECTED")

    st.metric(
        "Approval Probability",
        f"{approval_probability * 100:.2f}%"
    )
