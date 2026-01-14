
/*
===============================================================================
Bronze Layer Ingestion Script (MySQL Version)
===============================================================================
Description: 
    This script loads raw CSV data into the Bronze layer tables.
    It truncates existing data before loading to ensure a "Full Load" strategy.
    
Note: Ensure all CSV files are placed in the 'Uploads' folder specified below.
===============================================================================
*/
USE bronze_dw;

-- CRM Customer Info

TRUNCATE TABLE crm_cust_info;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/source_crm/cust_info.csv'
INTO TABLE crm_cust_info
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@v_id, cst_key, @v_firstname, @v_lastname, cst_marital_status, cst_gndr, @v_date)
SET 
    cst_id = NULLIF(TRIM(@v_id), ''),
    cst_firstname = NULLIF(TRIM(@v_firstname), ''),
    cst_lastname = NULLIF(TRIM(@v_lastname), ''),
    cst_create_date = STR_TO_DATE(NULLIF(TRIM(REPLACE(@v_date, '\r', '')), ''), '%Y-%m-%d');
-- ===========================================================================================

-- 2. CRM Product Info
TRUNCATE TABLE crm_prd_info;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/source_crm/prd_info.csv'
INTO TABLE crm_prd_info
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@v_id, prd_key, @v_nm, @v_cost, @v_line, @v_start_dt, @v_end_dt)
SET 
    -- 1. Handle ID
    prd_id = NULLIF(TRIM(@v_id), ''),

    -- 2. Handle Name and Line (with Trimming)
    prd_nm = NULLIF(TRIM(@v_nm), ''),
    prd_line = NULLIF(TRIM(@v_line), ''),

    -- 3. Handle Cost (Decimal)
    prd_cost = NULLIF(TRIM(@v_cost), ''),

    -- 4. Handle Dates using the safe STR_TO_DATE pattern
    prd_start_dt = STR_TO_DATE(NULLIF(TRIM(REPLACE(@v_start_dt, '\r', '')), ''), '%Y-%m-%d'),
    prd_end_dt   = STR_TO_DATE(NULLIF(TRIM(REPLACE(@v_end_dt, '\r', '')), ''), '%Y-%m-%d');
-- ===========================================================================================

-- 3. CRM Sales Details

TRUNCATE TABLE crm_sales_details;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/source_crm/sales_details.csv'
INTO TABLE crm_sales_details
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@v_ord_num, @v_prd_key, @v_cust_id, @v_order_dt, @v_ship_dt, @v_due_dt, @v_sales, @v_qty, @v_price)
SET 
    sls_ord_num  = NULLIF(TRIM(@v_ord_num), ''),
    sls_prd_key  = NULLIF(TRIM(@v_prd_key), ''),
    sls_cust_id  = NULLIF(TRIM(@v_cust_id), ''),
    
    
    sls_order_dt = CASE WHEN LENGTH(TRIM(@v_order_dt)) = 8 THEN STR_TO_DATE(TRIM(@v_order_dt), '%Y%m%d') ELSE NULL END,
    sls_ship_dt  = CASE WHEN LENGTH(TRIM(@v_ship_dt)) = 8 THEN STR_TO_DATE(TRIM(@v_ship_dt), '%Y%m%d') ELSE NULL END,
    sls_due_dt   = CASE WHEN LENGTH(TRIM(REPLACE(@v_due_dt, '\r', ''))) = 8 THEN STR_TO_DATE(TRIM(REPLACE(@v_due_dt, '\r', '')), '%Y%m%d') ELSE NULL END,
    
    sls_sales    = CASE WHEN TRIM(@v_sales) = '' THEN NULL ELSE CAST(TRIM(@v_sales) AS DECIMAL(18,2)) END,
    sls_quantity = CASE WHEN TRIM(@v_qty)   = '' THEN NULL ELSE CAST(TRIM(@v_qty)   AS SIGNED)       END,
    sls_price    = CASE WHEN TRIM(REPLACE(@v_price, '\r', '')) = '' THEN NULL ELSE CAST(TRIM(REPLACE(@v_price, '\r', '')) AS DECIMAL(18,2)) END;
    
-- ===========================================================================================

-- 4. ERP Location Data

TRUNCATE TABLE erp_loc_a101;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/source_erp/loc_a101.csv'
INTO TABLE erp_loc_a101
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@v_cid, @v_cntry)
SET 
    cid   = NULLIF(TRIM(@v_cid), ''),
    
    cntry = NULLIF(TRIM(REPLACE(@v_cntry, '\r', '')), '');
-- ===========================================================================================
    
-- 5. ERP Customer Extra Info
  
TRUNCATE TABLE erp_cust_az12;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/source_erp/cust_az12.csv'
INTO TABLE erp_cust_az12
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@v_cid, @v_bdate, @v_gen)
SET 
    cid   = NULLIF(TRIM(@v_cid), ''),
    
    bdate = STR_TO_DATE(NULLIF(TRIM(@v_bdate), ''), '%Y-%m-%d'),
    
    gen   = NULLIF(TRIM(REPLACE(@v_gen, '\r', '')), '');
    
-- ===========================================================================================

-- 6. ERP Product Categories

TRUNCATE TABLE erp_px_cat_g1v2;

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/source_erp/px_cat_g1v2.csv'
INTO TABLE erp_px_cat_g1v2
FIELDS TERMINATED BY ',' 
OPTIONALLY ENCLOSED BY '"' 
LINES TERMINATED BY '\n' 
IGNORE 1 ROWS
(@v_id, @v_cat, @v_subcat, @v_maint)
SET 
    id          = NULLIF(TRIM(@v_id), ''),
    cat         = NULLIF(TRIM(@v_cat), ''),
    subcat      = NULLIF(TRIM(@v_subcat), ''),
    maintenance = NULLIF(TRIM(REPLACE(@v_maint, '\r', '')), '');
