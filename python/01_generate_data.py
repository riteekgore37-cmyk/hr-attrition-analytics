"""
HR Analytics Project - Synthetic Data Generator
-------------------------------------------------
Generates a realistic, internally-consistent HR dataset across 4 tables:
    1. employees.csv          - core employee records
    2. performance_reviews.csv - yearly performance review history
    3. attendance.csv          - monthly attendance/leave summary
    4. salary_history.csv      - salary change history (promotions/raises)

The data is synthetic but built with realistic correlations (e.g. low
satisfaction + long commute + no promotion in 3+ years => higher attrition
probability), so ML models trained on it produce meaningful, explainable
results instead of random noise.
"""

import numpy as np
import pandas as pd
from datetime import datetime, timedelta

np.random.seed(42)

N_EMPLOYEES = 1500

departments = {
    "Sales": 0.22, "Engineering": 0.20, "Customer Support": 0.15,
    "Marketing": 0.10, "Human Resources": 0.08, "Finance": 0.10,
    "Operations": 0.15
}
job_roles = {
    "Sales": ["Sales Executive", "Sales Manager", "Account Manager"],
    "Engineering": ["Software Engineer", "Senior Engineer", "QA Engineer", "Engineering Manager"],
    "Customer Support": ["Support Associate", "Support Team Lead"],
    "Marketing": ["Marketing Associate", "Marketing Manager", "Content Specialist"],
    "Human Resources": ["HR Associate", "HR Manager", "Recruiter"],
    "Finance": ["Financial Analyst", "Accountant", "Finance Manager"],
    "Operations": ["Operations Associate", "Operations Manager", "Logistics Coordinator"]
}
education = ["High School", "Bachelor's", "Master's", "PhD"]
education_weights = [0.15, 0.50, 0.30, 0.05]
marital_status = ["Single", "Married", "Divorced"]
business_travel = ["Non-Travel", "Travel_Rarely", "Travel_Frequently"]

today = datetime(2026, 1, 1)

rows = []
for emp_id in range(1, N_EMPLOYEES + 1):
    dept = np.random.choice(list(departments.keys()), p=list(departments.values()))
    role = np.random.choice(job_roles[dept])
    age = int(np.clip(np.random.normal(34, 8), 21, 60))
    tenure_years = int(np.clip(np.random.exponential(4), 0, min(age - 20, 25)))
    hire_date = today - timedelta(days=int(tenure_years * 365.25 + np.random.randint(0, 365)))
    gender = np.random.choice(["Male", "Female"], p=[0.57, 0.43])
    edu = np.random.choice(education, p=education_weights)
    marital = np.random.choice(marital_status, p=[0.45, 0.42, 0.13])
    travel = np.random.choice(business_travel, p=[0.30, 0.55, 0.15])
    distance_km = int(np.clip(np.random.exponential(8), 1, 45))

    role_level = job_roles[dept].index(role)
    base_pay = {"Sales": 480000, "Engineering": 700000, "Customer Support": 380000,
                "Marketing": 450000, "Human Resources": 420000, "Finance": 520000,
                "Operations": 400000}[dept]
    monthly_income = int(base_pay/12 * (1 + 0.35*role_level) * (1 + 0.04*tenure_years) * np.random.normal(1, 0.08))
    monthly_income = max(monthly_income, 20000)

    years_since_promotion = int(np.clip(np.random.exponential(2.2), 0, tenure_years) if tenure_years > 0 else 0)
    num_companies_worked = int(np.clip(np.random.poisson(2), 0, 8))
    work_life_balance = np.random.choice([1, 2, 3, 4], p=[0.08, 0.22, 0.45, 0.25])
    env_satisfaction = np.random.choice([1, 2, 3, 4], p=[0.10, 0.20, 0.40, 0.30])
    job_satisfaction = np.random.choice([1, 2, 3, 4], p=[0.10, 0.20, 0.35, 0.35])
    overtime = np.random.choice(["Yes", "No"], p=[0.30, 0.70])
    performance_rating = np.random.choice([1, 2, 3, 4, 5], p=[0.03, 0.10, 0.45, 0.32, 0.10])
    training_times_last_year = int(np.clip(np.random.poisson(2.2), 0, 6))

    score = (
        -2.05
        + 0.90 * (overtime == "Yes")
        + 0.65 * (work_life_balance == 1)
        + 0.55 * (job_satisfaction <= 2)
        + 0.45 * (env_satisfaction <= 2)
        + 0.55 * (years_since_promotion >= 4)
        + 0.40 * (distance_km > 25)
        + 0.30 * (num_companies_worked >= 4)
        + 0.35 * (monthly_income < 28000)
        + 0.25 * (marital == "Single")
        - 0.45 * (tenure_years >= 8)
        - 0.35 * (performance_rating >= 4)
        + np.random.normal(0, 0.45)
    )
    prob_attrition = 1 / (1 + np.exp(-score))
    attrition = "Yes" if np.random.rand() < prob_attrition else "No"

    rows.append(dict(
        EmployeeID=emp_id, Age=age, Gender=gender, MaritalStatus=marital,
        Department=dept, JobRole=role, Education=edu, HireDate=hire_date.date().isoformat(),
        TenureYears=tenure_years, BusinessTravel=travel, DistanceFromHomeKM=distance_km,
        MonthlyIncome=monthly_income, YearsSinceLastPromotion=years_since_promotion,
        NumCompaniesWorked=num_companies_worked, WorkLifeBalance=work_life_balance,
        EnvironmentSatisfaction=env_satisfaction, JobSatisfaction=job_satisfaction,
        OverTime=overtime, PerformanceRating=performance_rating,
        TrainingTimesLastYear=training_times_last_year, Attrition=attrition
    ))

employees = pd.DataFrame(rows)

perf_rows = []
review_id = 1
for _, e in employees.iterrows():
    years_to_generate = min(e.TenureYears, 5) if e.TenureYears > 0 else 1
    for y in range(years_to_generate):
        review_year = 2026 - y
        rating = int(np.clip(e.PerformanceRating + np.random.choice([-1, 0, 0, 1]), 1, 5))
        goals_met_pct = int(np.clip(np.random.normal(70 + rating*5, 12), 30, 100))
        perf_rows.append(dict(
            ReviewID=review_id, EmployeeID=e.EmployeeID, ReviewYear=review_year,
            PerformanceRating=rating, GoalsMetPercent=goals_met_pct,
            ManagerFeedbackScore=int(np.clip(np.random.normal(rating*2, 1), 1, 10))
        ))
        review_id += 1
performance_reviews = pd.DataFrame(perf_rows)

att_rows = []
att_id = 1
for _, e in employees.iterrows():
    for month in range(1, 13):
        if e.Attrition == "Yes" and np.random.rand() < 0.3:
            continue
        wfb = e.WorkLifeBalance
        leaves_taken = int(np.clip(np.random.poisson(1.5 if wfb >= 3 else 2.5), 0, 8))
        late_marks = int(np.clip(np.random.poisson(1 if wfb >= 3 else 2), 0, 10))
        wfh_days = int(np.clip(np.random.poisson(3), 0, 20))
        att_rows.append(dict(
            AttendanceID=att_id, EmployeeID=e.EmployeeID, Month=month, Year=2025,
            LeavesTaken=leaves_taken, LateMarks=late_marks, WFHDays=wfh_days,
            WorkingDays=22
        ))
        att_id += 1
attendance = pd.DataFrame(att_rows)

sal_rows = []
sal_id = 1
for _, e in employees.iterrows():
    n_changes = min(e.TenureYears, 6)
    salary = e.MonthlyIncome / (1.06 ** max(n_changes, 0))
    change_date = pd.to_datetime(e.HireDate)
    for i in range(max(n_changes, 1)):
        change_type = "Hike" if i > 0 else "Joining"
        sal_rows.append(dict(
            SalaryChangeID=sal_id, EmployeeID=e.EmployeeID,
            EffectiveDate=change_date.date().isoformat(),
            MonthlyIncome=round(salary, 0), ChangeType=change_type
        ))
        salary *= np.random.normal(1.07, 0.02)
        change_date += timedelta(days=365)
        sal_id += 1
salary_history = pd.DataFrame(sal_rows)

employees.to_csv("../data/employees.csv", index=False)
performance_reviews.to_csv("../data/performance_reviews.csv", index=False)
attendance.to_csv("../data/attendance.csv", index=False)
salary_history.to_csv("../data/salary_history.csv", index=False)

print("Employees:", employees.shape)
print("Attrition rate: {:.1f}%".format((employees.Attrition == "Yes").mean() * 100))
print("Performance reviews:", performance_reviews.shape)
print("Attendance:", attendance.shape)
print("Salary history:", salary_history.shape)