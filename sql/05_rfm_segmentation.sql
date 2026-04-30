-- RFM customer segmentation queries.
-- The customers_rfm table is generated in 05_rfm_segmentation.ipynb.

-- Overall RFM overview
SELECT
    COUNT(*) AS customers,
    ROUND(AVG(recency), 2) AS avg_recency,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_monetary,
    ROUND(SUM(monetary), 2) AS total_revenue
FROM customers_rfm;

-- Segment summary
SELECT
    segment,
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 1.0 / SUM(COUNT(*)) OVER (), 4) AS customer_share,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(SUM(monetary) * 1.0 / SUM(SUM(monetary)) OVER (), 4) AS revenue_share,
    ROUND(AVG(recency), 2) AS avg_recency,
    ROUND(AVG(frequency), 2) AS avg_frequency,
    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer,
    ROUND(AVG(avg_order_value), 2) AS avg_order_value
FROM customers_rfm
GROUP BY segment
ORDER BY total_revenue DESC;

-- Champions and Loyal Customers combined
SELECT
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 1.0 / (SELECT COUNT(*) FROM customers_rfm), 4) AS customer_share,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(SUM(monetary) * 1.0 / (SELECT SUM(monetary) FROM customers_rfm), 4) AS revenue_share
FROM customers_rfm
WHERE segment IN ('Champions', 'Loyal Customers');

-- Low-value and lost customers
SELECT
    COUNT(*) AS customers,
    ROUND(COUNT(*) * 1.0 / (SELECT COUNT(*) FROM customers_rfm), 4) AS customer_share,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(SUM(monetary) * 1.0 / (SELECT SUM(monetary) FROM customers_rfm), 4) AS revenue_share
FROM customers_rfm
WHERE segment = 'Lost / Low Value';

-- Top customers by RFM score and revenue
SELECT
    customer_id,
    segment,
    recency,
    frequency,
    ROUND(monetary, 2) AS monetary,
    r_score,
    f_score,
    m_score,
    rfm_score,
    rfm_total_score
FROM customers_rfm
ORDER BY rfm_total_score DESC, monetary DESC, frequency DESC
LIMIT 20;

-- RFM matrix by recency and frequency
SELECT
    r_score,
    f_score,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS revenue,
    ROUND(AVG(monetary), 2) AS avg_revenue_per_customer
FROM customers_rfm
GROUP BY r_score, f_score
ORDER BY r_score DESC, f_score;

-- Revenue concentration among top RFM customers
WITH ranked_customers AS (
    SELECT
        customer_id,
        monetary,
        ROW_NUMBER() OVER (ORDER BY rfm_total_score DESC, monetary DESC, frequency DESC) AS customer_rank,
        SUM(monetary) OVER () AS total_revenue
    FROM customers_rfm
)
SELECT
    'Top 10 RFM customers' AS customer_group,
    ROUND(SUM(monetary), 2) AS revenue,
    ROUND(SUM(monetary) * 1.0 / MAX(total_revenue), 4) AS revenue_share
FROM ranked_customers
WHERE customer_rank <= 10;
