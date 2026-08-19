-- ============================================================
-- LEVEL 2: INTERMEDIATE QUERIES — joins, subqueries, multi-table logic
-- ============================================================
USE hr_analytics;

-- 1. Employees whose latest performance rating dropped vs. their average
-- (subquery + join)
SELECT
    e.EmployeeID, e.Department, e.JobRole,
    pr.ReviewYear, pr.PerformanceRating AS latest_rating,
    avg_tbl.avg_rating
FROM employees e
JOIN performance_reviews pr
    ON e.EmployeeID = pr.EmployeeID AND pr.ReviewYear = 2026
JOIN (
    SELECT EmployeeID, ROUND(AVG(PerformanceRating), 2) AS avg_rating
    FROM performance_reviews
    GROUP BY EmployeeID
) AS avg_tbl ON avg_tbl.EmployeeID = e.EmployeeID
WHERE pr.PerformanceRating < avg_tbl.avg_rating;

-- 2. Employees with above-average monthly income for their department (correlated subquery)
SELECT e.EmployeeID, e.Department, e.MonthlyIncome
FROM employees e
WHERE e.MonthlyIncome > (
    SELECT AVG(e2.MonthlyIncome) FROM employees e2 WHERE e2.Department = e.Department
)
ORDER BY e.Department, e.MonthlyIncome DESC;

-- 3. Average leaves taken per month by employees who eventually left vs stayed (JOIN + aggregation)
SELECT
    e.Attrition,
    ROUND(AVG(a.LeavesTaken), 2) AS avg_monthly_leaves,
    ROUND(AVG(a.LateMarks), 2) AS avg_monthly_late_marks,
    ROUND(AVG(a.WFHDays), 2) AS avg_monthly_wfh_days
FROM employees e
JOIN attendance a ON e.EmployeeID = a.EmployeeID
GROUP BY e.Attrition;

-- 4. Salary growth: first vs latest salary per employee (self-join style using subqueries)
SELECT
    s.EmployeeID,
    MIN(s.MonthlyIncome) AS starting_salary,
    MAX(s.MonthlyIncome) AS latest_salary,
    ROUND((MAX(s.MonthlyIncome) - MIN(s.MonthlyIncome)) * 100.0 / MIN(s.MonthlyIncome), 1) AS pct_growth
FROM salary_history s
GROUP BY s.EmployeeID
HAVING pct_growth < 10  -- employees whose salary barely grew (flight-risk indicator)
ORDER BY pct_growth ASC
LIMIT 20;

-- 5. Department + JobRole combinations with the highest average manager feedback score
SELECT
    e.Department, e.JobRole,
    ROUND(AVG(pr.ManagerFeedbackScore), 2) AS avg_feedback_score,
    COUNT(DISTINCT e.EmployeeID) AS headcount
FROM employees e
JOIN performance_reviews pr ON e.EmployeeID = pr.EmployeeID
GROUP BY e.Department, e.JobRole
ORDER BY avg_feedback_score DESC
LIMIT 10;
