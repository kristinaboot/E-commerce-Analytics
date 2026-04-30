-- Cohort retention analysis.

-- Cohort size by first purchase month
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS cohort_month
    FROM orders
    GROUP BY customer_id
)
SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_size
FROM first_purchase
GROUP BY cohort_month
ORDER BY cohort_month;

-- Customer activity by cohort and period number
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
customer_activity AS (
    SELECT DISTINCT
        o.customer_id,
        f.cohort_month,
        o.invoice_month,
        (
            (CAST(substr(o.invoice_month, 1, 4) AS INTEGER) - CAST(substr(f.cohort_month, 1, 4) AS INTEGER)) * 12
            + (CAST(substr(o.invoice_month, 6, 2) AS INTEGER) - CAST(substr(f.cohort_month, 6, 2) AS INTEGER))
        ) AS period_number
    FROM orders o
    JOIN first_purchase f
        ON o.customer_id = f.customer_id
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
)
SELECT
    ca.cohort_month,
    ca.period_number,
    COUNT(DISTINCT ca.customer_id) AS customers,
    cs.cohort_size,
    ROUND(COUNT(DISTINCT ca.customer_id) * 1.0 / cs.cohort_size, 4) AS retention_rate
FROM customer_activity ca
JOIN cohort_size cs
    ON ca.cohort_month = cs.cohort_month
GROUP BY ca.cohort_month, ca.period_number, cs.cohort_size
ORDER BY ca.cohort_month, ca.period_number;

-- Average retention by period
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS cohort_month
    FROM orders
    GROUP BY customer_id
),
customer_activity AS (
    SELECT DISTINCT
        o.customer_id,
        f.cohort_month,
        o.invoice_month,
        (
            (CAST(substr(o.invoice_month, 1, 4) AS INTEGER) - CAST(substr(f.cohort_month, 1, 4) AS INTEGER)) * 12
            + (CAST(substr(o.invoice_month, 6, 2) AS INTEGER) - CAST(substr(f.cohort_month, 6, 2) AS INTEGER))
        ) AS period_number
    FROM orders o
    JOIN first_purchase f
        ON o.customer_id = f.customer_id
),
cohort_size AS (
    SELECT
        cohort_month,
        COUNT(DISTINCT customer_id) AS cohort_size
    FROM first_purchase
    GROUP BY cohort_month
),
retention AS (
    SELECT
        ca.cohort_month,
        ca.period_number,
        COUNT(DISTINCT ca.customer_id) AS customers,
        cs.cohort_size,
        COUNT(DISTINCT ca.customer_id) * 1.0 / cs.cohort_size AS retention_rate
    FROM customer_activity ca
    JOIN cohort_size cs
        ON ca.cohort_month = cs.cohort_month
    GROUP BY ca.cohort_month, ca.period_number, cs.cohort_size
)
SELECT
    period_number,
    ROUND(AVG(retention_rate), 4) AS avg_retention_rate,
    COUNT(*) AS cohorts
FROM retention
WHERE period_number > 0
GROUP BY period_number
ORDER BY period_number;

-- Cohort revenue summary
WITH first_purchase AS (
    SELECT
        customer_id,
        MIN(invoice_month) AS cohort_month
    FROM orders
    GROUP BY customer_id
)
SELECT
    f.cohort_month,
    COUNT(DISTINCT f.customer_id) AS customers,
    ROUND(SUM(o.order_revenue), 2) AS total_revenue,
    ROUND(SUM(o.order_revenue) / COUNT(DISTINCT f.customer_id), 2) AS revenue_per_customer
FROM first_purchase f
JOIN orders o
    ON f.customer_id = o.customer_id
GROUP BY f.cohort_month
ORDER BY total_revenue DESC;
