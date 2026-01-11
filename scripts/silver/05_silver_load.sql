/*
===============================================================================
Silver Layer Transformation: crm_cust_info
===============================================================================
Purpose: 
    1. Deduplicate records using ROW_NUMBER().
    2. Normalize gender and marital status codes.
    3. Clean strings by removing leading/trailing spaces.
===============================================================================
*/

USE silver_dw;

-- Step 1: Clear the table for a fresh load (Idempotent operation)
TRUNCATE TABLE silver_dw.crm_cust_info;

-- Step 2: Insert cleaned and deduplicated data from Bronze
INSERT INTO silver_dw.crm_cust_info (
    cst_id, 
    cst_key, 
    cst_firstname, 
    cst_lastname, 
    cst_marital_status, 
    cst_gndr,
    cst_create_date
)
SELECT
    cst_id,
    cst_key,
    TRIM(cst_firstname) AS cst_firstname,
    TRIM(cst_lastname) AS cst_lastname,
    CASE 
        WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single'
        WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married'
        ELSE 'n/a'
    END AS cst_marital_status,
    CASE 
        WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female'
        WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male'
        ELSE 'n/a'
    END AS cst_gndr,
    cst_create_date
FROM (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last
    FROM bronze_dw.crm_cust_info
    WHERE cst_id IS NOT NULL
) t
WHERE flag_last = 1; -- Ensures only the most recent record per customer is loaded

/*
===============================================================================
Silver Layer Transformation: crm_prd_info
===============================================================================
*/

USE silver_dw;

-- Clear the table for a fresh load
TRUNCATE TABLE crm_prd_info;

-- Insert cleaned data from Bronze
INSERT INTO crm_prd_info (
    prd_id,
    cat_id,
    prd_key,
    prd_nm,
    prd_cost,
    prd_line,
    prd_start_dt,
    prd_end_dt
)
SELECT
    prd_id,
    -- Extracting Category ID (assumed first part of prd_key or handled by logic)
    REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_') AS cat_id, 
    prd_key,
    TRIM(prd_nm) AS prd_nm,
    -- Handling potential NULL costs from Bronze
    COALESCE(prd_cost, 0) AS prd_cost,
    CASE 
        WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road'
        WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales'
        WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain'
        WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring'
        ELSE 'n/a'
    END AS prd_line,
    CAST(prd_start_dt AS DATE) AS prd_start_dt,
    -- Ensuring end date logic handles the '9999' or NULL cases if present
    CAST(prd_end_dt AS DATE) AS prd_end_dt
FROM bronze_dw.crm_prd_info;

/*
===============================================================================
Silver Layer Transformation: crm_sales_details
===============================================================================
Purpose: 
    1. Clean and normalize sales transaction data.
    2. Handle missing or invalid customer/product keys.
    3. Standardize pricing and quantity metrics.
===============================================================================
*/

USE silver_dw;

-- Step 1: Clear the table for a fresh load
TRUNCATE TABLE silver_dw.crm_sales_details;

-- Step 2: Insert cleaned data from Bronze
INSERT INTO silver_dw.crm_sales_details (
    sls_ord_num, 
    sls_prd_key, 
    sls_cust_id, 
    sls_order_dt, 
    sls_ship_dt, 
    sls_due_dt, 
    sls_sales, 
    sls_quantity, 
    sls_price
)
SELECT 
    sls_ord_num,
    sls_prd_key,
    sls_cust_id,
    sls_order_dt,
    sls_ship_dt,
    sls_due_dt,
    -- Check for negative sales or nulls (standardize to 0 or null)
    CASE 
        WHEN sls_sales IS NULL OR sls_sales <= 0 THEN sls_quantity * sls_price
        ELSE sls_sales
    END AS sls_sales,
    sls_quantity,
    -- Ensure price is populated correctly
    CASE 
        WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0)
        ELSE sls_price
    END AS sls_price
FROM bronze_dw.crm_sales_details
WHERE sls_ord_num IS NOT NULL; -- Exclude records with missing order numbers

/*
===============================================================================
Silver Layer Transformation: erp_loc_a101
===============================================================================
Purpose: 
    1. Standardize country names to a consistent format.
    2. Remove leading/trailing whitespaces.
    3. Filter out invalid or missing CID (Customer ID) records.
===============================================================================
*/

USE silver_dw;

-- Step 1: Clear the table for a fresh load
TRUNCATE TABLE silver_dw.erp_loc_a101;

-- Step 2: Insert cleaned data from Bronze
INSERT INTO silver_dw.erp_loc_a101 (
    cid, 
    cntry
)
SELECT 
    REPLACE(cid, '-', '') AS cid, -- Standardizing ID format to match CRM IDs
    CASE 
        WHEN TRIM(cntry) = 'AU' THEN 'Australia'
        WHEN TRIM(cntry) = 'USA' THEN 'United States'
        WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a'
        ELSE TRIM(cntry)
    END AS cntry
FROM bronze_dw.erp_loc_a101
WHERE cid IS NOT NULL;

/*
===============================================================================
Silver Layer Transformation: erp_cust_az12
===============================================================================
Purpose: 
    1. Standardize Customer ID (CID) by removing prefixes.
    2. Normalize Gender (GEN) values.
    3. Filter out unrealistic birthdates (data hygiene).
===============================================================================
*/

USE silver_dw;

-- Step 1: Clear the table for a fresh load
TRUNCATE TABLE silver_dw.erp_cust_az12;

-- Step 2: Insert cleaned data from Bronze
INSERT INTO silver_dw.erp_cust_az12 (
    cid, 
    bdate, 
    gen
)
SELECT 
    -- Remove the 'NAS' prefix if it exists to match CRM key format
    CASE 
        WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) 
        ELSE cid 
    END AS cid,
    -- Ensure birthdate is not in the future or impossibly old
    CASE 
        WHEN bdate > CURRENT_DATE THEN NULL
        WHEN bdate < '1920-01-01' THEN NULL
        ELSE bdate
    END AS bdate,
    -- Standardize Gender: Male, Female, or n/a
    CASE 
        WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male'
        WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female'
        ELSE 'n/a'
    END AS gen
FROM bronze_dw.erp_cust_az12
WHERE cid IS NOT NULL;

/*
===============================================================================
Silver Layer Transformation: erp_px_cat_g1v2
===============================================================================
Purpose: 
    1. Clean and standardize product category and subcategory names.
    2. Normalize the maintenance flag.
    3. Ensure data consistency for the Product Dimension.
===============================================================================
*/

USE silver_dw;

-- Step 1: Clear the table for a fresh load
TRUNCATE TABLE silver_dw.erp_px_cat_g1v2;

-- Step 2: Insert cleaned data from Bronze
INSERT INTO silver_dw.erp_px_cat_g1v2 (
    id, 
    cat, 
    subcat, 
    maintenance
)
SELECT 
    TRIM(id) AS id,
    TRIM(cat) AS cat,
    TRIM(subcat) AS subcat,
    -- Standardize maintenance flag to 'Yes' / 'No'
    CASE 
        WHEN UPPER(TRIM(maintenance)) = 'YES' THEN 'Yes'
        WHEN UPPER(TRIM(maintenance)) = 'NO' THEN 'No'
        ELSE 'n/a'
    END AS maintenance
FROM bronze_dw.erp_px_cat_g1v2;
