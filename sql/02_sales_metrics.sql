-- Sales metrics: revenue, orders, countries, products and seasonality.

-- Overall sales KPI
SELECT
    ROUND(SUM(order_revenue), 2) AS total_revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(SUM(order_revenue) / COUNT(DISTINCT invoice_no), 2) AS avg_order_value,
    ROUND(SUM(order_revenue) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM orders;

-- Monthly sales dynamics
SELECT
    invoice_month,
    ROUND(SUM(order_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM orders
GROUP BY invoice_month
ORDER BY invoice_month;

-- Monthly sales dynamics, full months only
SELECT
    invoice_month,
    ROUND(SUM(order_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM orders
WHERE invoice_month <> '2011-12'
GROUP BY invoice_month
ORDER BY invoice_month;

-- Country performance
SELECT
    country,
    ROUND(SUM(order_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM orders
GROUP BY country
ORDER BY revenue DESC;

-- Top countries excluding United Kingdom
SELECT
    country,
    ROUND(SUM(order_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM orders
WHERE country <> 'United Kingdom'
GROUP BY country
ORDER BY revenue DESC
LIMIT 10;

-- United Kingdom revenue share
WITH total AS (
    SELECT SUM(order_revenue) AS total_revenue
    FROM orders
),
uk AS (
    SELECT SUM(order_revenue) AS uk_revenue
    FROM orders
    WHERE country = 'United Kingdom'
)
SELECT
    ROUND(uk.uk_revenue, 2) AS uk_revenue,
    ROUND(total.total_revenue, 2) AS total_revenue,
    ROUND(uk.uk_revenue * 1.0 / total.total_revenue, 4) AS uk_revenue_share
FROM uk
CROSS JOIN total;

-- Top products by revenue
SELECT
    stock_code,
    description,
    ROUND(SUM(line_revenue), 2) AS revenue,
    SUM(quantity) AS quantity,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers,
    ROUND(AVG(unit_price), 2) AS avg_unit_price
FROM online_retail_clean
GROUP BY stock_code, description
ORDER BY revenue DESC
LIMIT 20;

-- Top products by quantity sold
SELECT
    stock_code,
    description,
    SUM(quantity) AS quantity,
    ROUND(SUM(line_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    COUNT(DISTINCT customer_id) AS customers
FROM online_retail_clean
GROUP BY stock_code, description
ORDER BY quantity DESC
LIMIT 20;

-- Revenue by day of week
SELECT
    day_of_week,
    ROUND(SUM(line_revenue), 2) AS revenue,
    COUNT(DISTINCT invoice_no) AS orders,
    ROUND(SUM(line_revenue) / COUNT(DISTINCT invoice_no), 2) AS avg_order_value
FROM online_retail_clean
GROUP BY day_of_week
ORDER BY
    CASE day_of_week
        WHEN 'Monday' THEN 1
        WHEN 'Tuesday' THEN 2
        WHEN 'Wednesday' THEN 3
        WHEN 'Thursday' THEN 4
        WHEN 'Friday' THEN 5
        WHEN 'Saturday' THEN 6
        WHEN 'Sunday' THEN 7
    END;

-- Orders by hour
SELECT
    invoice_hour,
    COUNT(DISTINCT invoice_no) AS orders,
    ROUND(SUM(line_revenue), 2) AS revenue
FROM online_retail_clean
GROUP BY invoice_hour
ORDER BY invoice_hour;
