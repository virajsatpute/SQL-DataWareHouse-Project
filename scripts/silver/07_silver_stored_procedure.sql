DELIMITER $$

DROP PROCEDURE IF EXISTS silver_dw.load_silver$$

CREATE PROCEDURE silver_dw.load_silver()
BEGIN
    --  ALL DECLARE STATEMENTS COME FIRST
    DECLARE v_batch_start_time DATETIME;
    DECLARE v_batch_end_time   DATETIME;
    DECLARE v_start_time       DATETIME;
    DECLARE v_end_time         DATETIME;

    -- Error Handling
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        GET DIAGNOSTICS CONDITION 1 @p1 = MESSAGE_TEXT;
        INSERT INTO silver_load_log VALUES ('CRITICAL ERROR', 0, @p1);
        SELECT * FROM silver_load_log;
        DROP TEMPORARY TABLE IF EXISTS silver_load_log;
    END;

    -- (CREATE, TRUNCATE, SET)
    CREATE TEMPORARY TABLE IF NOT EXISTS silver_load_log (
        step_name VARCHAR(100),
        duration_sec INT,
        status VARCHAR(50)
    );
    TRUNCATE TABLE silver_load_log;

    SET v_batch_start_time = NOW();
    START TRANSACTION;

    -- 1. crm_cust_info
    SET v_start_time = NOW();
    TRUNCATE TABLE silver_dw.crm_cust_info;
    INSERT INTO silver_dw.crm_cust_info (cst_id, cst_key, cst_firstname, cst_lastname, cst_marital_status, cst_gndr, cst_create_date)
    SELECT cst_id, cst_key, TRIM(cst_firstname), TRIM(cst_lastname),
           CASE WHEN UPPER(TRIM(cst_marital_status)) = 'S' THEN 'Single' WHEN UPPER(TRIM(cst_marital_status)) = 'M' THEN 'Married' ELSE 'n/a' END,
           CASE WHEN UPPER(TRIM(cst_gndr)) = 'F' THEN 'Female' WHEN UPPER(TRIM(cst_gndr)) = 'M' THEN 'Male' ELSE 'n/a' END,
           cst_create_date
    FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY cst_id ORDER BY cst_create_date DESC) AS flag_last FROM bronze_dw.crm_cust_info WHERE cst_id IS NOT NULL) t
    WHERE flag_last = 1;
    INSERT INTO silver_load_log VALUES ('crm_cust_info', TIMESTAMPDIFF(SECOND, v_start_time, NOW()), 'SUCCESS');

    -- 2. crm_prd_info
    SET v_start_time = NOW();
    TRUNCATE TABLE silver_dw.crm_prd_info;
    INSERT INTO silver_dw.crm_prd_info (prd_id, cat_id, prd_key, prd_nm, prd_cost, prd_line, prd_start_dt, prd_end_dt)
    SELECT prd_id, REPLACE(SUBSTRING(prd_key, 1, 5), '-', '_'), prd_key, TRIM(prd_nm), COALESCE(prd_cost, 0),
           CASE WHEN UPPER(TRIM(prd_line)) = 'R' THEN 'Road' WHEN UPPER(TRIM(prd_line)) = 'S' THEN 'Other Sales' WHEN UPPER(TRIM(prd_line)) = 'M' THEN 'Mountain' WHEN UPPER(TRIM(prd_line)) = 'T' THEN 'Touring' ELSE 'n/a' END,
           prd_start_dt, prd_end_dt
    FROM bronze_dw.crm_prd_info;
    INSERT INTO silver_load_log VALUES ('crm_prd_info', TIMESTAMPDIFF(SECOND, v_start_time, NOW()), 'SUCCESS');

    -- 3. crm_sales_details
    SET v_start_time = NOW();
    TRUNCATE TABLE silver_dw.crm_sales_details;
    INSERT INTO silver_dw.crm_sales_details (sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt, sls_sales, sls_quantity, sls_price)
    SELECT sls_ord_num, sls_prd_key, sls_cust_id, sls_order_dt, sls_ship_dt, sls_due_dt,
           CASE WHEN sls_sales IS NULL OR sls_sales <= 0 THEN sls_quantity * sls_price ELSE sls_sales END,
           sls_quantity,
           CASE WHEN sls_price IS NULL OR sls_price <= 0 THEN sls_sales / NULLIF(sls_quantity, 0) ELSE sls_price END
    FROM bronze_dw.crm_sales_details WHERE sls_ord_num IS NOT NULL;
    INSERT INTO silver_load_log VALUES ('crm_sales_details', TIMESTAMPDIFF(SECOND, v_start_time, NOW()), 'SUCCESS');

    -- 4. erp_loc_a101
    SET v_start_time = NOW();
    TRUNCATE TABLE silver_dw.erp_loc_a101;
    INSERT INTO silver_dw.erp_loc_a101 (cid, cntry)
    SELECT REPLACE(cid, '-', ''), 
           CASE WHEN TRIM(cntry) = 'AU' THEN 'Australia' WHEN TRIM(cntry) = 'USA' THEN 'United States' WHEN TRIM(cntry) IS NULL OR TRIM(cntry) = '' THEN 'n/a' ELSE TRIM(cntry) END
    FROM bronze_dw.erp_loc_a101 WHERE cid IS NOT NULL;
    INSERT INTO silver_load_log VALUES ('erp_loc_a101', TIMESTAMPDIFF(SECOND, v_start_time, NOW()), 'SUCCESS');

    -- 5. erp_cust_az12
    SET v_start_time = NOW();
    TRUNCATE TABLE silver_dw.erp_cust_az12;
    INSERT INTO silver_dw.erp_cust_az12 (cid, bdate, gen)
    SELECT CASE WHEN cid LIKE 'NAS%' THEN SUBSTRING(cid, 4, LENGTH(cid)) ELSE cid END,
           CASE WHEN bdate > CURRENT_DATE OR bdate < '1920-01-01' THEN NULL ELSE bdate END,
           CASE WHEN UPPER(TRIM(gen)) IN ('M', 'MALE') THEN 'Male' WHEN UPPER(TRIM(gen)) IN ('F', 'FEMALE') THEN 'Female' ELSE 'n/a' END
    FROM bronze_dw.erp_cust_az12 WHERE cid IS NOT NULL;
    INSERT INTO silver_load_log VALUES ('erp_cust_az12', TIMESTAMPDIFF(SECOND, v_start_time, NOW()), 'SUCCESS');

    -- 6. erp_px_cat_g1v2
    SET v_start_time = NOW();
    TRUNCATE TABLE silver_dw.erp_px_cat_g1v2;
    INSERT INTO silver_dw.erp_px_cat_g1v2 (id, cat, subcat, maintenance)
    SELECT TRIM(id), TRIM(cat), TRIM(subcat), 
           CASE WHEN UPPER(TRIM(maintenance)) = 'YES' THEN 'Yes' WHEN UPPER(TRIM(maintenance)) = 'NO' THEN 'No' ELSE 'n/a' END
    FROM bronze_dw.erp_px_cat_g1v2;
    INSERT INTO silver_load_log VALUES ('erp_px_cat_g1v2', TIMESTAMPDIFF(SECOND, v_start_time, NOW()), 'SUCCESS');

    COMMIT;

    -- Return the single result set summary
    INSERT INTO silver_load_log VALUES ('TOTAL BATCH TIME', TIMESTAMPDIFF(SECOND, v_batch_start_time, NOW()), 'COMPLETE');
    SELECT * FROM silver_load_log;
    
    -- Clean up
    DROP TEMPORARY TABLE IF EXISTS silver_load_log;

END$$

DELIMITER ;

CALL silver_dw.load_silver();
