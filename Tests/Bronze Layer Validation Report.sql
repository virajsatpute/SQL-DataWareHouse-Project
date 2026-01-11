SELECT 
    c.country, 
    p.category, 
    SUM(f.sales_amount) AS total_sales
FROM gold_dw.fact_sales f
JOIN gold_dw.dim_customers c ON f.customer_key = c.customer_key
JOIN gold_dw.dim_products p ON f.product_key = p.product_key
GROUP BY c.country, p.category
ORDER BY total_sales DESC;

-- Check for orphan sales (Sales that don't match a Product or Customer)
SELECT 
    (SELECT COUNT(*) FROM silver_dw.crm_sales_details) AS total_sales_count,
    COUNT(f.order_number) AS matched_sales_count
FROM gold_dw.fact_sales f;

SELECT 
    c.country, 
    p.category, 
    SUM(f.sales_amount) AS total_sales
FROM gold_dw.fact_sales f
JOIN gold_dw.dim_customers c ON f.customer_key = c.customer_key
JOIN gold_dw.dim_products p ON f.product_key = p.product_key
GROUP BY c.country, p.category
ORDER BY total_sales DESC;

select distinct id from bronze_dw.erp_px_cat_g1v2;
select prd_key from silver_dw.crm_prd_info;
