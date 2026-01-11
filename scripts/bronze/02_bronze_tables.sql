
-- CRM Customer Information
-- Select the Bronze database
USE bronze_dw;

-- CRM Customer Info
DROP TABLE IF EXISTS crm_cust_info;
CREATE TABLE IF NOT EXISTS crm_cust_info (
    cst_id             INT,
    cst_key            VARCHAR(50),
    cst_firstname      VARCHAR(100),
    cst_lastname       VARCHAR(100),
    cst_marital_status VARCHAR(50),
    cst_gndr           VARCHAR(10),
    cst_create_date    DATE
) ENGINE=InnoDB;

-- 2. CRM Product Info
DROP TABLE IF EXISTS crm_prd_info;
CREATE TABLE crm_prd_info (
    prd_id INT AUTO_INCREMENT PRIMARY KEY,
    prd_key VARCHAR(50),
    prd_nm VARCHAR(100),
    prd_cost DECIMAL(18, 2),
    prd_line VARCHAR(50),
    prd_start_dt DATETIME,
    prd_end_dt DATETIME
) ENGINE=InnoDB;

-- 3. CRM Sales Details
DROP TABLE IF EXISTS crm_sales_details;
CREATE TABLE crm_sales_details (
    sls_ord_num     VARCHAR(50),
    sls_prd_key     VARCHAR(50),
    sls_cust_id     INT,
    sls_order_dt    DATE,
    sls_ship_dt     DATE,
    sls_due_dt      DATE,
    sls_sales       DECIMAL(18, 2),
    sls_quantity    INT,
    sls_price       DECIMAL(18, 2)
) ENGINE=InnoDB;


-- 4. ERP Location Data
DROP TABLE IF EXISTS erp_loc_a101;
CREATE TABLE erp_loc_a101 (
    cid   VARCHAR(50) PRIMARY KEY,
    cntry VARCHAR(100)
) ENGINE=InnoDB;

-- 5. ERP Customer Extra Info
DROP TABLE IF EXISTS erp_cust_az12;
CREATE TABLE erp_cust_az12 (
    cid   VARCHAR(50) PRIMARY KEY,
    bdate DATE,
    gen   VARCHAR(10)
) ENGINE=InnoDB;

-- 6. ERP Product Categories
DROP TABLE IF EXISTS erp_px_cat_g1v2;
CREATE TABLE erp_px_cat_g1v2 (
    id VARCHAR(50) PRIMARY KEY,
    cat VARCHAR(100),
    subcat VARCHAR(100),
    maintenance VARCHAR(50)
) ENGINE=InnoDB;