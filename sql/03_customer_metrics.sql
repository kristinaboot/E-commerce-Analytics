-- Customer behavior: repeat customers, top customers and revenue concentration.

-- Customer-level metrics
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders,
        ROUND(SUM(order_revenue), 2) AS revenue,
        MIN(invoice_date) AS first_purchase_date,
        MAX(invoice_date) AS last_purchase_date
    FROM orders
    GROUP BY customer_id
)
SELECT
    COUNT(*) AS customers,
    ROUND(AVG(orders), 2) AS avg_orders_per_customer,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_customer,
    ROUND(SUM(revenue), 2) AS total_revenue
FROM customer_metrics;

-- One-time vs repeat customers
WITH customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders,
        SUM(order_revenue) AS revenue
    FROM orders
    GROUP BY customer_id
),
customer_type AS (
    SELECT
        CASE
            WHEN orders = 1 THEN 'One-time customer'
            ELSE 'Repeat customer'
        END AS customer_type,
        customer_id,
        orders,
        revenue
    FROM customer_metrics
)
SELECT
    customer_type,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (), 4) AS customer_share,
    COUNT(CASE WHEN orders > 1 THEN 1 END) AS repeat_customers,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) * 1.0 / SUM(SUM(revenue)) OVER (), 4) AS revenue_share,
    ROUND(AVG(orders), 2) AS avg_orders_per_customer,
    ROUND(AVG(revenue), 2) AS avg_revenue_per_customer
FROM customer_type
GROUP BY customer_type
ORDER BY revenue DESC;

-- Repeat purchase rate
WITH customer_orders AS (
    SELECT
        customer_id,
        COUNT(DISTINCT invoice_no) AS orders
    FROM orders
    GROUP BY customer_id
)
SELECT
    COUNT(CASE WHEN orders > 1 THEN 1 END) AS repeat_customers,
    COUNT(*) AS customers,
    ROUND(COUNT(CASE WHEN orders > 1 THEN 1 END) * 1.0 / COUNT(*), 4) AS repeat_purchase_rate
FROM customer_orders;

-- Top customers by revenue
SELECT
    customer_id,
    COUNT(DISTINCT invoice_no) AS orders,
    ROUND(SUM(order_revenue), 2) AS revenue,
    ROUND(AVG(order_revenue), 2) AS avg_order_value,
    MIN(invoice_date) AS first_purchase_date,
    MAX(invoice_date) AS last_purchase_date
FROM orders
GROUP BY customer_id
ORDER BY revenue DESC
LIMIT 20;

-- Customer revenue concentration by customer rank
WITH customer_revenue AS (
    SELECT
        customer_id,
        SUM(order_revenue) AS revenue
    FROM orders
    GROUP BY customer_id
),
ranked_customers AS (
    SELECT
        customer_id,
        revenue,
        ROW_NUMBER() OVER (ORDER BY revenue DESC) AS customer_rank,
        COUNT(*) OVER () AS total_customers,
        SUM(revenue) OVER () AS total_revenue
    FROM customer_revenue
),
segments AS (
    SELECT
        CASE
            WHEN customer_rank <= total_customers * 0.01 THEN 'Top 1%'
            WHEN customer_rank <= total_customers * 0.05 THEN 'Top 5%'
            WHEN customer_rank <= total_customers * 0.10 THEN 'Top 10%'
            WHEN customer_rank <= total_customers * 0.20 THEN 'Top 20%'
            ELSE 'Other 80%'
        END AS customer_group,
        revenue,
        total_revenue
    FROM ranked_customers
)
SELECT
    customer_group,
    ROUND(SUM(revenue), 2) AS revenue,
    ROUND(SUM(revenue) * 1.0 / MAX(total_revenue), 4) AS revenue_share
FROM segments
GROUP BY customer_group
ORDER BY
    CASE customer_group
        WHEN 'Top 1%' THEN 1
        WHEN 'Top 5%' THEN 2
        WHEN 'Top 10%' THEN 3
        WHEN 'Top 20%' THEN 4
        ELSE 5
    END;

-- New vs returning customers by month
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS first_purchase_month
    FROM orders
    GROUP BY customer_id
),
monthly_customers AS (
    SELECT DISTINCT
        o.invoice_month,
        o.customer_id,
        f.first_purchase_month
    FROM orders o
    JOIN first_purchase f
        ON o.customer_id = f.customer_id
)
SELECT
    invoice_month,
    COUNT(CASE WHEN invoice_month = first_purchase_month THEN 1 END) AS new_customers,
    COUNT(CASE WHEN invoice_month > first_purchase_month THEN 1 END) AS returning_customers,
    COUNT(*) AS active_customers
FROM monthly_customers
GROUP BY invoice_month
ORDER BY invoice_month;

-- Revenue from new vs returning customers
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS first_purchase_month
    FROM orders
    GROUP BY customer_id
),
orders_with_customer_type AS (
    SELECT
        o.invoice_month,
        o.customer_id,
        o.order_revenue,
        CASE
            WHEN o.invoice_month = f.first_purchase_month THEN 'New'
            ELSE 'Returning'
        END AS customer_type
    FROM orders o
    JOIN first_purchase f
        ON o.customer_id = f.customer_id
)
SELECT
    invoice_month,
    customer_type,
    ROUND(SUM(order_revenue), 2) AS revenue,
    COUNT(DISTINCT customer_id) AS customers,
    COUNT(*) AS orders
FROM orders_with_customer_type
GROUP BY invoice_month, customer_type
ORDER BY invoice_month, customer_type;
