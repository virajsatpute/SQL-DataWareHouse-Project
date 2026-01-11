/*
===============================================================================
Gold Layer Final Validation: Star Schema Quality Audit
===============================================================================
*/
USE gold_dw;

-- 1. Surrogate Key Integrity Check (The "Orphan" Audit)
-- We expect missing_customer_keys = 0.
-- We acknowledge missing_product_keys = 3238 (Pending ERP Master Data).
SELECT 
    COUNT(*) - COUNT(customer_key) AS missing_customer_keys,
    COUNT(*) - COUNT(product_key) AS missing_product_keys
FROM fact_sales;

-- 2. Dimension Uniqueness Check (The "Grain" Audit)
-- Ensures that no product or customer is duplicated in the dimensions.
SELECT 'dim_customers' AS table_name, COUNT(*) - COUNT(DISTINCT customer_key) AS duplicate_count FROM dim_customers
UNION ALL
SELECT 'dim_products', COUNT(*) - COUNT(DISTINCT product_key) FROM dim_products;

-- 3. Business Metric Sanity Check
-- Ensures no negative values exist in critical financial columns.
SELECT COUNT(*) AS invalid_sales_records
FROM fact_sales
WHERE sales_amount <= 0 OR quantity <= 0;

/*
===============================================================================
End-to-End Lineage Reconciliation: Bronze -> Silver -> Gold
===============================================================================
*/

-- Transactional Data Lineage (Should all be 60398)
SELECT '1. Bronze' AS layer, 'crm_sales' AS entity, COUNT(*) AS row_count FROM bronze_dw.crm_sales_details
UNION ALL
SELECT '2. Silver', 'crm_sales', COUNT(*) FROM silver_dw.crm_sales_details
UNION ALL
SELECT '3. Gold', 'fact_sales', COUNT(*) FROM gold_dw.fact_sales;

-- Master Data Lineage (Customer Example)
SELECT '1. Bronze', 'crm_cust', COUNT(*) FROM bronze_dw.crm_cust_info
UNION ALL
SELECT '2. Silver', 'crm_cust', COUNT(*) FROM silver_dw.crm_cust_info
UNION ALL
SELECT '3. Gold', 'dim_cust', COUNT(*) FROM gold_dw.dim_customers;

SELECT 
    c.country, 
    p.category, 
    SUM(f.sales_amount) AS total_sales,
    COUNT(f.order_number) AS order_count
FROM gold_dw.fact_sales f
JOIN gold_dw.dim_customers c ON f.customer_key = c.customer_key
JOIN gold_dw.dim_products p ON f.product_key = p.product_key
GROUP BY 1, 2
ORDER BY total_sales DESC;