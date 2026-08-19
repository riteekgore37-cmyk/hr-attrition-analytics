-- ============================================================
-- LEVEL 3: ADVANCED QUERIES — Window Functions & CTEs
-- ============================================================
USE hr_analytics;

-- 1. Rank employees by MonthlyIncome within their own department
SELECT
    EmployeeID, Department, JobRole, MonthlyIncome,
    RANK()       OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS income_rank_in_dept,
    NTILE(4)     OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS income_quartile
FROM employees;

-- 2. Running total of headcount hired over time (CTE + window function)
WITH monthly_hires AS (
    SELECT
        DATE_FORMAT(HireDate, '%Y-%m') AS hire_month,
        COUNT(*) AS hires
    FROM employees
    GROUP BY DATE_FORMAT(HireDate, '%Y-%m')
)
SELECT
    hire_month,
    hires,
    SUM(hires) OVER (ORDER BY hire_month) AS running_headcount
FROM monthly_hires
ORDER BY hire_month;

-- 3. Year-over-year performance rating change per employee (LAG window function)
WITH ranked_reviews AS (
    SELECT
        EmployeeID, ReviewYear, PerformanceRating,
        LAG(PerformanceRating) OVER (PARTITION BY EmployeeID ORDER BY ReviewYear) AS prev_year_rating
    FROM performance_reviews
)
SELECT
    EmployeeID, ReviewYear, PerformanceRating, prev_year_rating,
    (PerformanceRating - prev_year_rating) AS rating_change
FROM ranked_reviews
WHERE prev_year_rating IS NOT NULL
ORDER BY rating_change ASC   -- biggest performance drops first
LIMIT 20;

-- 4. Attrition-risk score using a CTE that layers multiple risk flags, then buckets employees
WITH risk_flags AS (
    SELECT
        EmployeeID, Department, JobRole, MonthlyIncome,
        (CASE WHEN OverTime = 'Yes' THEN 1 ELSE 0 END) +
        (CASE WHEN WorkLifeBalance = 1 THEN 1 ELSE 0 END) +
        (CASE WHEN JobSatisfaction <= 2 THEN 1 ELSE 0 END) +
        (CASE WHEN YearsSinceLastPromotion >= 4 THEN 1 ELSE 0 END) +
        (CASE WHEN DistanceFromHomeKM > 25 THEN 1 ELSE 0 END) AS risk_score
    FROM employees
    WHERE Attrition = 'No'   -- only current employees are candidates for prediction
)
SELECT
    EmployeeID, Department, JobRole, MonthlyIncome, risk_score,
    CASE
        WHEN risk_score >= 4 THEN 'High Risk'
        WHEN risk_score >= 2 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS risk_category
FROM risk_flags
ORDER BY risk_score DESC;

-- 5. Department-level attrition rate compared to company-wide rate (window function, no self-join)
SELECT DISTINCT
    Department,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) OVER (PARTITION BY Department) * 100, 2) AS dept_attrition_pct,
    ROUND(AVG(CASE WHEN Attrition = 'Yes' THEN 1.0 ELSE 0 END) OVER () * 100, 2) AS company_attrition_pct
FROM employees
ORDER BY dept_attrition_pct DESC;

-- 6. Top 3 highest-paid employees in every department (ROW_NUMBER + CTE)
WITH ranked AS (
    SELECT
        EmployeeID, Department, JobRole, MonthlyIncome,
        ROW_NUMBER() OVER (PARTITION BY Department ORDER BY MonthlyIncome DESC) AS rn
    FROM employees
)
SELECT * FROM ranked WHERE rn <= 3;
