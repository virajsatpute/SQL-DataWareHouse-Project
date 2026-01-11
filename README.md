# Data Warehouse Implementation: Medallion Architecture

## 📌 Project Overview
This project demonstrates the design and implementation of a modern **Data Warehouse** using the **Medallion Architecture** (Bronze, Silver, and Gold layers). The primary objective was to transform siloed raw CRM and ERP data into a high-performance, validated **Star Schema** optimized for advanced Business Intelligence (BI) reporting.

<img width="2816" height="1536" alt="Image" src="https://github.com/user-attachments/assets/ded462e1-1485-40e8-a6fb-83758fa7d423" />

### Key Technical Achievements:
* **End-to-End Data Lineage:** Successfully maintained **100% record reconciliation** across all architecture layers.
* **Advanced Data Cleansing:** Leveraged **Window Functions (`ROW_NUMBER`)** and **CTEs** to resolve a **~7% data inflation** caused by many-to-many join conditions.
* **Cross-System Integration:** Engineered a **Tiered Join Strategy** to bridge a **~5% gap** resulting from mismatched Product Key formats between CRM and ERP source systems.

---

## 🏗️ Architecture & Data Flow

1.  **Bronze Layer (Landing):** Ingested raw CSV data into a landing zone using SQL scripts to preserve original data structures.
2.  **Silver Layer (Cleansing):** Performed data standardization, handled `NULL` values via `COALESCE`, and executed deduplication logic.
3.  **Gold Layer (Curated):** Developed a dimensional model (Star Schema) utilizing **Surrogate Keys** and complex join logic to support business reporting.


---

## 📖 This project involves:

1. **Data Architecture**: Designing a Modern Data Warehouse Using Medallion Architecture **Bronze**, **Silver**, and **Gold** layers.
2. **ETL Pipelines**: Extracting, transforming, and loading data from source systems into the warehouse.
3. **Data Modeling**: Developing fact and dimension tables optimized for analytical queries.
4. **Analytics & Reporting**: Creating SQL-based reports and dashboards for actionable insights.

---
## 📊 Analytics & Reporting

The data warehouse enables analysis of:
### Customer Behavior
- Customer purchase patterns
- Repeat customers and revenue contribution
### Product Performance
- Best and worst performing products
- Category-level sales analysis
### Sales Trends
- Sales over time
- Order volume and revenue trends

---

## 💻 Tech Stack
* **Database:** MySQL 8.0.
* **SQL Concepts:** Window Functions (`ROW_NUMBER`), CTEs, Medallion Architecture, Star Schema Modeling, Surrogate Keys, Data Reconciliation.
  
---
## 🌟 Author
**Viraj Satpute**  
Data Analyst | Data Engineer

[![LinkedIn](https://img.shields.io/badge/LinkedIn-0077B5?style=for-the-badge&logo=linkedin&logoColor=white)](https://www.linkedin.com/in/virajsatpute/)
