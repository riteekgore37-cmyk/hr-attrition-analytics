-- ============================================================
-- HR Attrition & Performance Analytics — Database Schema
-- Target: MySQL 8.0+ (also works in MySQL Workbench)
-- ============================================================

DROP DATABASE IF EXISTS hr_analytics;
CREATE DATABASE hr_analytics;
USE hr_analytics;

-- ---------------------------------------------------
-- 1. EMPLOYEES  (core dimension table)
-- ---------------------------------------------------
CREATE TABLE employees (
    EmployeeID              INT PRIMARY KEY,
    Age                     INT NOT NULL,
    Gender                  VARCHAR(10),
    MaritalStatus           VARCHAR(15),
    Department              VARCHAR(30),
    JobRole                 VARCHAR(40),
    Education               VARCHAR(20),
    HireDate                DATE,
    TenureYears             INT,
    BusinessTravel          VARCHAR(20),
    DistanceFromHomeKM      INT,
    MonthlyIncome           INT,
    YearsSinceLastPromotion INT,
    NumCompaniesWorked      INT,
    WorkLifeBalance         TINYINT,   -- 1=Bad .. 4=Best
    EnvironmentSatisfaction TINYINT,   -- 1=Low .. 4=High
    JobSatisfaction         TINYINT,   -- 1=Low .. 4=High
    OverTime                VARCHAR(3),
    PerformanceRating       TINYINT,   -- 1..5
    TrainingTimesLastYear   INT,
    Attrition               VARCHAR(3)  -- Yes / No
);

-- ---------------------------------------------------
-- 2. PERFORMANCE_REVIEWS (fact table, one row per review)
-- ---------------------------------------------------
CREATE TABLE performance_reviews (
    ReviewID              INT PRIMARY KEY,
    EmployeeID            INT,
    ReviewYear            INT,
    PerformanceRating     TINYINT,
    GoalsMetPercent       INT,
    ManagerFeedbackScore  TINYINT,
    FOREIGN KEY (EmployeeID) REFERENCES employees(EmployeeID)
);

-- ---------------------------------------------------
-- 3. ATTENDANCE (fact table, monthly grain)
-- ---------------------------------------------------
CREATE TABLE attendance (
    AttendanceID  INT PRIMARY KEY,
    EmployeeID    INT,
    Month         TINYINT,
    Year          INT,
    LeavesTaken   INT,
    LateMarks     INT,
    WFHDays       INT,
    WorkingDays   INT,
    FOREIGN KEY (EmployeeID) REFERENCES employees(EmployeeID)
);

-- ---------------------------------------------------
-- 4. SALARY_HISTORY (fact table, slowly changing)
-- ---------------------------------------------------
CREATE TABLE salary_history (
    SalaryChangeID  INT PRIMARY KEY,
    EmployeeID      INT,
    EffectiveDate   DATE,
    MonthlyIncome   INT,
    ChangeType      VARCHAR(15),  -- Joining / Hike
    FOREIGN KEY (EmployeeID) REFERENCES employees(EmployeeID)
);

-- ---------------------------------------------------
-- Load data (adjust path / use MySQL Workbench's Table Data Import Wizard)
-- ---------------------------------------------------
-- LOAD DATA LOCAL INFILE 'data/employees.csv' INTO TABLE employees
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'data/performance_reviews.csv' INTO TABLE performance_reviews
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'data/attendance.csv' INTO TABLE attendance
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
-- LOAD DATA LOCAL INFILE 'data/salary_history.csv' INTO TABLE salary_history
--   FIELDS TERMINATED BY ',' ENCLOSED BY '"' LINES TERMINATED BY '\n' IGNORE 1 ROWS;
