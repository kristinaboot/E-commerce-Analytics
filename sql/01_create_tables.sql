-- The actual SQLite database can be created from CSV files using src/build_sqlite_db.py.

DROP TABLE IF EXISTS online_retail_clean;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers_rfm;
DROP TABLE IF EXISTS cohort_retention;
DROP TABLE IF EXISTS rfm_segment_summary;

CREATE TABLE online_retail_clean (
    invoice_no TEXT,
    stock_code TEXT,
    description TEXT,
    quantity INTEGER,
    invoice_date TEXT,
    unit_price REAL,
    customer_id TEXT,
    country TEXT,
    is_cancelled INTEGER,
    line_revenue REAL,
    invoice_day TEXT,
    invoice_month TEXT,
    invoice_year INTEGER,
    invoice_hour INTEGER,
    day_of_week TEXT
);

CREATE TABLE orders (
    invoice_no TEXT PRIMARY KEY,
    customer_id TEXT,
    country TEXT,
    invoice_date TEXT,
    invoice_month TEXT,
    total_quantity INTEGER,
    order_revenue REAL,
    unique_products INTEGER
);

CREATE TABLE customers_rfm (
    customer_id TEXT PRIMARY KEY,
    first_purchase_date TEXT,
    last_purchase_date TEXT,
    recency INTEGER,
    frequency INTEGER,
    monetary REAL,
    avg_order_value REAL,
    total_quantity INTEGER,
    unique_products INTEGER,
    customer_lifetime_days INTEGER,
    r_score INTEGER,
    f_score INTEGER,
    m_score INTEGER,
    rfm_score TEXT,
    rfm_total_score INTEGER,
    segment TEXT
);

CREATE TABLE cohort_retention (
    cohort_month TEXT,
    period_number INTEGER,
    customers INTEGER,
    cohort_size INTEGER,
    retention_rate REAL
);

CREATE TABLE rfm_segment_summary (
    segment TEXT PRIMARY KEY,
    customers INTEGER,
    avg_recency REAL,
    avg_frequency REAL,
    total_revenue REAL,
    avg_revenue_per_customer REAL,
    avg_order_value REAL,
    customer_share REAL,
    revenue_share REAL
);
