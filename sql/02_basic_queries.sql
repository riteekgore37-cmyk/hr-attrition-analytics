-- ============================================================
-- LEVEL 1: BASIC QUERIES — filtering, aggregation, GROUP BY/HAVING
-- ============================================================
USE hr_analytics;

-- 1. Overall attrition rate
SELECT
    COUNT(*) AS total_employees,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM employees;

-- 2. Attrition rate by department (sorted worst first)
SELECT
    Department,
    COUNT(*) AS headcount,
    SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS left_count,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM employees
GROUP BY Department
ORDER BY attrition_rate_pct DESC;

-- 3. Average monthly income by job role
SELECT JobRole, ROUND(AVG(MonthlyIncome), 0) AS avg_income, COUNT(*) AS headcount
FROM employees
GROUP BY JobRole
ORDER BY avg_income DESC;

-- 4. Departments with more than 20% attrition (HAVING clause)
SELECT
    Department,
    ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS attrition_rate_pct
FROM employees
GROUP BY Department
HAVING attrition_rate_pct > 20
ORDER BY attrition_rate_pct DESC;

-- 5. Employees who did overtime AND have low work-life balance (at-risk list)
SELECT EmployeeID, Department, JobRole, MonthlyIncome, WorkLifeBalance, OverTime
FROM employees
WHERE OverTime = 'Yes' AND WorkLifeBalance = 1 AND Attrition = 'No'
ORDER BY Department;

-- 6. Headcount and average tenure by education level
SELECT Education, COUNT(*) AS headcount, ROUND(AVG(TenureYears), 1) AS avg_tenure_years
FROM employees
GROUP BY Education
ORDER BY avg_tenure_years DESC;
