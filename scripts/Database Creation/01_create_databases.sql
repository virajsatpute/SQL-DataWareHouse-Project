/*
=============================================================
Create Databases for Medallion Architecture (MySQL)
=============================================================
Script Purpose:
    This script creates three databases representing the 
    Bronze, Silver, and Gold layers of a modern data warehouse.

    If the databases already exist, they are dropped and 
    recreated to ensure a clean environment.

WARNING:
    Running this script will permanently delete all data
    in the listed databases.
    Ensure backups are taken before execution.
=============================================================
*/

-- Drop databases if they exist
DROP DATABASE IF EXISTS bronze_dw;
DROP DATABASE IF EXISTS silver_dw;
DROP DATABASE IF EXISTS gold_dw;

-- Create Bronze Layer Database (Raw Data)
CREATE DATABASE bronze_dw
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Create Silver Layer Database (Cleaned & Transformed Data)
CREATE DATABASE silver_dw
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

-- Create Gold Layer Database (Analytics & Reporting)
CREATE DATABASE gold_dw
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;
