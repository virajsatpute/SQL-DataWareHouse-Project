/*
===============================================================================
DDL Script: Create Gold Views (MySQL)
===============================================================================
Script Purpose:
    This script creates views for the Gold layer in the 'gold_dw' database.
    It combines CRM and ERP data from the Silver layer into a Star Schema.
===============================================================================
*/

USE gold_dw;

-- =============================================================================
-- Create Dimension: gold_dw.dim_customers
-- =============================================================================
CREATE OR REPLACE VIEW gold_dw.dim_customers AS
SELECT
    -- Surrogate key generation using ROW_NUMBER()
    ROW_NUMBER() OVER (ORDER BY ci.cst_id) AS customer_key, 
    ci.cst_id                              AS customer_id,
    ci.cst_key                             AS customer_number,
    ci.cst_firstname                       AS first_name,
    ci.cst_lastname                        AS last_name,
    la.cntry                               AS country,
    ci.cst_marital_status                  AS marital_status,
    -- Gender Logic: CRM is primary; ERP is fallback
    CASE 
        WHEN ci.cst_gndr != 'n/a' THEN ci.cst_gndr 
        ELSE COALESCE(ca.gen, 'n/a')                
    END                                    AS gender,
    ca.bdate                               AS birthdate,
    ci.cst_create_date                     AS create_date
FROM silver_dw.crm_cust_info ci
LEFT JOIN silver_dw.erp_cust_az12 ca
    ON ci.cst_key = ca.cid
LEFT JOIN silver_dw.erp_loc_a101 la
    ON ci.cst_key = la.cid;

-- =============================================================================
-- Create Dimension: gold_dw.dim_products
-- =============================================================================
CREATE OR REPLACE VIEW gold_dw.dim_products AS
WITH DeduplicatedProducts AS (
    SELECT
        pn.prd_id,
        pn.prd_key AS product_number,
        pn.prd_nm AS product_name,
        pc.cat AS category,
        pc.subcat AS subcategory,
        pn.prd_cost AS cost,
        pn.prd_line AS product_line,
        pn.prd_start_dt AS start_date,
        -- Generate a rank to identify duplicates
        ROW_NUMBER() OVER (
            PARTITION BY pn.prd_key 
            ORDER BY pn.prd_start_dt DESC, pn.prd_id DESC
        ) AS row_num
    FROM silver_dw.crm_prd_info pn
    LEFT JOIN silver_dw.erp_px_cat_g1v2 pc
        ON pn.cat_id = pc.id
    WHERE pn.prd_end_dt IS NULL
)
SELECT
    -- Generate Surrogate Key on unique rows
    ROW_NUMBER() OVER (ORDER BY product_number) AS product_key,
    prd_id,
    product_number,
    product_name,
    category,
    subcategory,
    cost,
    product_line,
    start_date
FROM DeduplicatedProducts
WHERE row_num = 1;

/*
===============================================================================
Final Corrected View: gold_dw.fact_sales
===============================================================================
Strategy: 
    1. Tiered Joining: Tries specific suffix matching before fuzzy matching.
    2. Data Lineage: Forces a 1-to-1 match to maintain 60,398 rows.
    3. Cleanup: Removes prefixes from both sides to find core IDs.
===============================================================================
*/
CREATE OR REPLACE VIEW gold_dw.fact_sales AS
WITH RankedSales AS (
    SELECT
        sd.sls_ord_num,
        sd.sls_order_dt,
        sd.sls_sales,
        sd.sls_quantity,
        sd.sls_price,
        pr.product_key,
        cu.customer_key,
        -- Lock the row count at 60,398 to prevent inflation
        ROW_NUMBER() OVER (
            PARTITION BY sd.sls_ord_num, sd.sls_prd_key 
            ORDER BY pr.product_key ASC
        ) AS duplicate_check
    FROM silver_dw.crm_sales_details sd
    LEFT JOIN gold_dw.dim_customers cu
        ON sd.sls_cust_id = cu.customer_id
    LEFT JOIN gold_dw.dim_products pr
        -- TIERED JOIN LOGIC:
        -- Attempt to match the core part of the product code (e.g., 'R92B-58')
        -- This handles cases like 'BK-R93R-62' vs 'CO-RF-FR-R92B-58'
        ON (RIGHT(TRIM(pr.product_number), 7) = RIGHT(TRIM(sd.sls_prd_key), 7))
        OR (RIGHT(TRIM(pr.product_number), 5) = RIGHT(TRIM(sd.sls_prd_key), 5))
        OR (pr.product_number LIKE CONCAT('%', TRIM(sd.sls_prd_key), '%'))
)
SELECT
    sls_ord_num   AS order_number,
    product_key,
    customer_key,
    sls_order_dt  AS order_date,
    sls_sales     AS sales_amount,
    sls_quantity  AS quantity,
    sls_price     AS price
FROM RankedSales
WHERE duplicate_check = 1;