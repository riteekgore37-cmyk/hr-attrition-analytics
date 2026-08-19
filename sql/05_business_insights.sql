-- ============================================================
-- LEVEL 4: BUSINESS INSIGHT QUERIES — the "so what" queries
-- These are the ones to screenshot for your resume/README.
-- ============================================================
USE hr_analytics;

-- INSIGHT 1: Which single factor combination correlates most with attrition?
SELECT
    OverTime,
    WorkLifeBalance,
    COUNT(*) AS headcount,
    SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) AS left_count,
    ROUND(SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_pct
FROM employees
GROUP BY OverTime, WorkLifeBalance
ORDER BY attrition_pct DESC;

-- INSIGHT 2: Estimated cost of attrition per department
-- (assume replacement cost = 6 months of monthly income, a common HR industry rule of thumb)
SELECT
    Department,
    SUM(CASE WHEN Attrition='Yes' THEN MonthlyIncome * 6 ELSE 0 END) AS estimated_replacement_cost,
    SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) AS employees_lost
FROM employees
GROUP BY Department
ORDER BY estimated_replacement_cost DESC;

-- INSIGHT 3: Promotion stagnation vs attrition -- does being overdue for a promotion actually drive exits?
SELECT
    CASE
        WHEN YearsSinceLastPromotion = 0 THEN '0 (Recently promoted)'
        WHEN YearsSinceLastPromotion BETWEEN 1 AND 2 THEN '1-2 years'
        WHEN YearsSinceLastPromotion BETWEEN 3 AND 4 THEN '3-4 years'
        ELSE '5+ years'
    END AS promotion_gap_bucket,
    COUNT(*) AS headcount,
    ROUND(SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_pct
FROM employees
GROUP BY promotion_gap_bucket
ORDER BY promotion_gap_bucket;

-- INSIGHT 4: Do employees who get more training stay longer? (CTE)
WITH training_buckets AS (
    SELECT
        EmployeeID, Attrition, TenureYears,
        CASE WHEN TrainingTimesLastYear >= 3 THEN 'High Training (3+)' ELSE 'Low Training (0-2)' END AS training_bucket
    FROM employees
)
SELECT
    training_bucket,
    COUNT(*) AS headcount,
    ROUND(AVG(TenureYears), 2) AS avg_tenure_years,
    ROUND(SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_pct
FROM training_buckets
GROUP BY training_bucket;

-- INSIGHT 5: Commute distance vs attrition, controlled for overtime
SELECT
    CASE
        WHEN DistanceFromHomeKM <= 10 THEN 'Near (<=10km)'
        WHEN DistanceFromHomeKM <= 25 THEN 'Medium (11-25km)'
        ELSE 'Far (25km+)'
    END AS commute_bucket,
    OverTime,
    ROUND(SUM(CASE WHEN Attrition='Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS attrition_pct,
    COUNT(*) AS headcount
FROM employees
GROUP BY commute_bucket, OverTime
ORDER BY commute_bucket, OverTime;
