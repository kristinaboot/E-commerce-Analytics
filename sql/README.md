# SQL Analysis

This folder contains analytical SQL queries for the E-commerce Sales Analytics project.

The queries are designed for SQLite because it is simple to run locally and does not require a separate database server.

## How to create the SQLite database

Run from the project root:

```bash
python src/build_sqlite_db.py
```

The script creates:

```text
data/processed/ecommerce_analytics.sqlite
```

## Main tables

```text
online_retail_clean     cleaned transaction-level data
orders                  order-level data
customers_rfm           customer-level RFM table
cohort_retention        cohort retention table
rfm_segment_summary     RFM segment-level summary
```

## SQL files

```text
01_create_tables.sql        reference schema
02_sales_metrics.sql        revenue, orders, AOV, countries, products
03_customer_metrics.sql     repeat customers, top customers, customer concentration
04_cohort_retention.sql     cohort and retention queries
05_rfm_segmentation.sql     RFM and segment queries
```
