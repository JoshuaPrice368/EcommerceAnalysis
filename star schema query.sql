-- E-Commerce sales analysis


-- Questions we want the analysis to answer:

-- What is our ovearall sales performance? Total revenue, average order value, and top selling products?

-- Which category is performing the best?

-- What is our best region revenue wise?, what regions should we focus more in?

-- Does age or gender impact what people buy or how much they spend?



-- INITIAL SCREENING
-- Checks for NULL values across collumns, found none. Checks for duplicates using a CTE, also found none - dataset appears to have been pre cleaned or has good engineering/warehousing practices
/*
SELECT * 
FROM ecommerce_sales_large
SELECT * 
FROM ecommerce_sales_large
WHERE 
    `Transaction ID` IS NULL OR `Transaction ID` = '' OR `Transaction ID` = 'ERROR' OR `Transaction ID` = 'UNKNOWN'
    OR `Product ID` IS NULL OR `Product ID` = '' OR `Product ID` = 'ERROR' OR `Product ID` = 'UNKNOWN'
    OR `Product Name` IS NULL OR `Product Name` = '' OR `Product Name` = 'ERROR' OR `Product Name` = 'UNKNOWN'
    OR Category IS NULL OR Category = '' OR Category = 'ERROR' OR Category = 'UNKNOWN'
    OR Price IS NULL OR Price = '' OR Price = 'ERROR' OR Price = 'UNKNOWN'
    OR `Quantity Sold` IS NULL OR `Quantity Sold` = '' OR `Quantity Sold` = 'ERROR' OR `Quantity Sold` = 'UNKNOWN'
    OR `Customer Age` IS NULL OR `Customer Age` = '' OR `Customer Age` = 'ERROR' OR `Customer Age` = 'UNKNOWN'
    OR `Customer Gender` IS NULL OR `Customer Gender` = '' OR `Customer Gender` = 'ERROR' OR `Customer Gender` = 'UNKNOWN'
    OR `Transaction Date` IS NULL OR `Transaction Date` = '' OR `Transaction Date` = 'ERROR' OR `Transaction Date` = 'UNKNOWN'
    OR `Payment Method` IS NULL OR `Payment Method` = '' OR `Payment Method` = 'ERROR' OR `Payment Method` = 'UNKNOWN'
    OR Discount IS NULL OR Discount = '' OR Discount = 'ERROR' OR Discount = 'UNKNOWN'
    OR Region IS NULL OR Region = '' OR Region = 'ERROR' OR Region = 'UNKNOWN'
    OR `Membership Status` IS NULL OR `Membership Status` = '' OR `Membership Status` = 'ERROR' OR `Membership Status` = 'UNKNOWN';
WITH dupe_check_cte AS (
SELECT *,
ROW_NUMBER() OVER(PARTITION BY
		`Transaction ID`,
        `Product ID`,
        `Product Name`,
        Category,
        Price,
        `Quantity Sold`,
        `Customer Age`,
        `Customer Gender`,
        `Transaction Date`,
        `Payment Method`, 
        Discount,
        Region,
        `Membership Status`
        ) AS row_num

FROM ecommerce_sales_large)
SELECT * FROM dupe_check_cte
WHERE row_num > 1;
*/


DROP VIEW IF EXISTS ecom_fact_table;
DROP VIEW IF EXISTS dim_product;
DROP VIEW IF EXISTS dim_region;
DROP VIEW IF EXISTS dim_payment_method;
DROP VIEW IF EXISTS dim_age_group;
DROP VIEW IF EXISTS dim_gender;
-- Drop views to make checks in MySQL faster

/* 
-----------------------------------------
------------STAR SCHEMA------------------
-----------------------------------------
*/

-- Fact table
CREATE VIEW ecom_fact_table AS
SELECT
`Transaction ID`,
`Product ID`,
`Product Name`,
CASE
	WHEN `Customer AGE` < 18 THEN 'UNDER 18'
    WHEN `Customer AGE` BETWEEN 18 AND 30 THEN '18-30'
    WHEN `Customer AGE` BETWEEN 31 AND 40 THEN '31-40'
    WHEN `Customer AGE` BETWEEN 41 AND 50 THEN '41-50'
    ELSE '50+'
END AS age_group,
`Customer Gender`,
STR_TO_DATE(`Transaction Date`, '%Y-%m-%d') AS purchase_date,
`Discount`,
`Payment Method`,
`Region`,
`Price`,
`Quantity Sold`,
Price * `Quantity Sold` AS sale_value
FROM ecommerce_sales_large;
	
SELECT * FROM ecom_fact_table;

-- Dimensions


-- Product Dimension table
CREATE VIEW dim_product AS 
	SELECT DISTINCT
		`Product ID`,
        `Product Name`,
        `Category` 
	FROM ecommerce_sales_large;
    

CREATE VIEW dim_age_group AS
	SELECT DISTINCT 
		CASE
	WHEN `Customer AGE` < 18 THEN 'UNDER 18'
    WHEN `Customer AGE` BETWEEN 18 AND 30 THEN '18-30'
    WHEN `Customer AGE` BETWEEN 31 AND 40 THEN '31-40'
    WHEN `Customer AGE` BETWEEN 41 AND 50 THEN '41-50'
    ELSE '50+'
END AS age_group
FROM ecommerce_sales_large;

CREATE VIEW dim_region AS
SELECT DISTINCT
REGION 
FROM 
ecommerce_sales_large;

CREATE VIEW dim_payment_method AS
SELECT DISTINCT 
`Payment Method`
FROM ecommerce_sales_large;

CREATE VIEW dim_gender AS 
SELECT DISTINCT
`Customer Gender`
FROM ecommerce_sales_large;


/* 
-----------------------------------------
----------------ANALYSIS-----------------
-----------------------------------------
*/
-- 1. -- Monthly & Total Sales Revenue
SELECT
    MONTH(STR_TO_DATE(`purchase_date`, '%Y-%m-%d')) AS transact_date,
    MONTHNAME(STR_TO_DATE(`purchase_date`, '%Y-%m-%d')) AS transact_month,
    SUM(sale_value) AS total_sales_revenue,
    SUM(sale_value) / COUNT(`Transaction ID`) AS avg_order_val
FROM ecom_fact_table
GROUP BY 
    transact_date, transact_month

UNION ALL

SELECT
    '' AS transact_date,
    'TOTAL' AS transact_month,
    SUM(sale_value) AS total_sales_revenue,
    SUM(sale_value) / COUNT(`Transaction ID`) AS avg_order_val
FROM ecom_fact_table 
ORDER BY transact_date ASC;
-- 2. -- Top performing product
SELECT 
    `Product Name`,
    SUM(Price * `Quantity Sold`) AS total_value,
    (SUM(Price * `Quantity Sold`) / (SELECT SUM(Price * `Quantity Sold`) FROM ecom_fact_table)) * 100 AS percentage_of_total
FROM ecom_fact_table
GROUP BY `Product Name`
ORDER BY total_value DESC;

-- 3. -- Category Perofrmance
SELECT 
    p.Category,
    SUM(f.Price * f.`Quantity Sold`) AS total_value
FROM ecom_fact_table f
JOIN dim_product p ON f.`Product ID` = p.`Product ID`
GROUP BY p.Category
ORDER BY total_value DESC;

-- 4. -- Region anaalysis

SELECT 
    Region,
    SUM(Price * `Quantity Sold`) AS total_value
FROM ecom_fact_table
GROUP BY Region
ORDER BY total_value DESC;

-- 5. -- Demographic Analysis

SELECT
	`Customer Gender`,
	`age_group`,
	SUM(sale_value) / COUNT(`Transaction ID`) AS avg_order_val,
    SUM(sale_value) AS total_spend
FROM ecom_fact_table
GROUP BY `Customer Gender`, `age_group`
ORDER BY avg_order_val
