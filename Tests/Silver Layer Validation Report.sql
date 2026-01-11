/*
===============================================================================
Validation Script: silver_dw.crm_cust_info
===============================================================================
Purpose: Verify data quality and transformation logic after Bronze-to-Silver load.
===============================================================================
*/

-- 1. Check for Duplicate IDs (Must return 0 rows)
-- This ensures the ROW_NUMBER() deduplication worked correctly.
SELECT cst_id, COUNT(*)
FROM silver_dw.crm_cust_info
GROUP BY cst_id
HAVING COUNT(*) > 1;

-- 2. Check for Unexpected 'n/a' in Gender (Data Quality)
-- Verifies if the CASE statement missed any source codes.
SELECT DISTINCT cst_gndr 
FROM silver_dw.crm_cust_info;

-- 3. Check for Unexpected 'n/a' in Marital Status (Data Quality)
SELECT DISTINCT cst_marital_status 
FROM silver_dw.crm_cust_info;

-- 4. Check for Nulls in Primary Key (Must return 0 rows)
SELECT COUNT(*) AS null_id_count
FROM silver_dw.crm_cust_info
WHERE cst_id IS NULL;

-- 5. Data Lineage Check (Verify dwh_create_date)
-- Ensures the timestamp was applied correctly.
SELECT MIN(dwh_create_date), MAX(dwh_create_date) 
FROM silver_dw.crm_cust_info;

-- 6. Check for leading/trailing spaces (Must return 0 rows)
-- Verifies the TRIM() function worked.
SELECT cst_firstname, cst_lastname
FROM silver_dw.crm_cust_info
WHERE cst_firstname LIKE ' %' 
   OR cst_firstname LIKE '% '
   OR cst_lastname LIKE ' %' 
   OR cst_lastname LIKE '% ';
   
/*
===============================================================================
Validation Script: silver_dw.crm_prd_info
===============================================================================
Purpose: 
    1. Verify cost values (no negatives or incorrect zeros).
    2. Check for overlapping product dates.
    3. Validate product line normalization.
===============================================================================
*/

USE silver_dw;

-- 1. Check for Duplicate Product Keys (Must return 0 rows)
-- This ensures each product key is unique in our standardized table.
SELECT prd_key, COUNT(*)
FROM silver_dw.crm_prd_info
GROUP BY prd_key
HAVING COUNT(*) > 1;

-- 2. Check for Invalid Costs (Negative or NULL)
-- Based on the Bronze load, some costs were empty; verify they are now 0 or valid.
SELECT COUNT(*) AS invalid_cost_count
FROM silver_dw.crm_prd_info
WHERE prd_cost < 0 OR prd_cost IS NULL;

-- 3. Validate Product Line Normalization
-- Ensure 'R', 'M', 'S', 'T' were correctly mapped to full names.
SELECT DISTINCT prd_line 
FROM silver_dw.crm_prd_info;

-- 4. Check for Logic Errors in Dates
-- The Start Date must always be before or equal to the End Date.
SELECT * FROM silver_dw.crm_prd_info
WHERE prd_end_dt < prd_start_dt;

-- 5. Category ID Pattern Check
-- Verify if cat_id follows the expected 'XX_XX' format extracted from prd_key.
SELECT cat_id, COUNT(*) 
FROM silver_dw.crm_prd_info
GROUP BY cat_id;

-- 6. Check for leading/trailing spaces in Product Names
SELECT prd_nm
FROM silver_dw.crm_prd_info
WHERE prd_nm LIKE ' %' OR prd_nm LIKE '% ';

/*
===============================================================================
Validation Script: silver_dw.crm_sales_details
===============================================================================
*/

-- 1. Check for Invalid Dates (Ship date before Order date)
-- This identifies potential data entry errors in the source system.
SELECT * FROM silver_dw.crm_sales_details
WHERE sls_ship_dt < sls_order_dt OR sls_due_dt < sls_order_dt;

-- 2. Check for Relationship Integrity (Must return 0 rows)
-- Ensure every sale has a valid product and customer ID.
SELECT COUNT(*) FROM silver_dw.crm_sales_details
WHERE sls_prd_key IS NULL OR sls_cust_id IS NULL;

-- 3. Consistency Check: Sales = Quantity * Price
-- Check for significant discrepancies in calculation.
SELECT sls_ord_num, sls_sales, (sls_quantity * sls_price) AS calculated_sales
FROM silver_dw.crm_sales_details
WHERE sls_sales <> (sls_quantity * sls_price);

-- 4. Data Completeness Check
SELECT 
    (SELECT COUNT(*) FROM bronze_dw.crm_sales_details) AS bronze_count,
    (SELECT COUNT(*) FROM silver_dw.crm_sales_details) AS silver_count;
    
/*
===============================================================================
Validation Script: silver_dw.erp_loc_a101
===============================================================================
*/

-- 1. Check for Unique IDs (Must return 0 rows)
-- Ensures the replacement of hyphens didn't create duplicate keys.
SELECT cid, COUNT(*)
FROM silver_dw.erp_loc_a101
GROUP BY cid
HAVING COUNT(*) > 1;

-- 2. Check for Non-Standardized Country Names
-- Verifies if the CASE statement caught all expected abbreviations.
SELECT DISTINCT cntry 
FROM silver_dw.erp_loc_a101;

-- 3. Verify CID format
-- Ensures hyphens were successfully removed.
SELECT cid 
FROM silver_dw.erp_loc_a101 
WHERE cid LIKE '%-%' 
LIMIT 5;

-- 4. Check for Nulls or Empty Strings in critical columns
SELECT COUNT(*) 
FROM silver_dw.erp_loc_a101
WHERE cid IS NULL OR cntry IS NULL;

/*
===============================================================================
Validation Script: silver_dw.erp_cust_az12
===============================================================================
*/

-- 1. Check for successfully stripped prefixes (Must return 0 rows)
-- This ensures 'NAS' is gone.
SELECT cid 
FROM silver_dw.erp_cust_az12 
WHERE cid LIKE 'NAS%';

-- 2. Verify Gender Normalization
-- Should only show 'Male', 'Female', or 'n/a'.
SELECT DISTINCT gen 
FROM silver_dw.erp_cust_az12;

-- 3. Check for Date Logic Errors
-- Returns any rows where the bdate check set values to NULL.
SELECT * FROM silver_dw.erp_cust_az12 
WHERE bdate IS NULL 
AND cid IN (SELECT cid FROM bronze_dw.erp_cust_az12 WHERE bdate IS NOT NULL);

-- 4. Check for Duplicate CIDs
-- Since this is an extension of the customer profile, keys must be unique.
SELECT cid, COUNT(*)
FROM silver_dw.erp_cust_az12
GROUP BY cid
HAVING COUNT(*) > 1;

/*
===============================================================================
Validation Script: silver_dw.erp_px_cat_g1v2
===============================================================================
*/

-- 1. Check for Unique IDs (Must return 0 rows)
-- Each ID represents a unique Category/Subcategory combination.
SELECT id, COUNT(*)
FROM silver_dw.erp_px_cat_g1v2
GROUP BY id
HAVING COUNT(*) > 1;

-- 2. Verify Maintenance Flag Normalization
-- Should only show 'Yes', 'No', or 'n/a'.
SELECT DISTINCT maintenance 
FROM silver_dw.erp_px_cat_g1v2;

-- 3. Check for Empty Category or Subcategory Names
SELECT COUNT(*) 
FROM silver_dw.erp_px_cat_g1v2
WHERE cat IS NULL OR subcat IS NULL OR cat = '' OR subcat = '';

-- 4. Cross-Reference Check (Optional)
-- Check if all Category IDs exist in your Product table
-- (Note: This depends on if you've loaded crm_prd_info recently)
SELECT DISTINCT id 
FROM silver_dw.erp_px_cat_g1v2 
WHERE id NOT IN (SELECT DISTINCT cat_id FROM silver_dw.crm_prd_info);