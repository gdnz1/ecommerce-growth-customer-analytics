USE ecommerce_analysis;


WITH customer_rfm_raw AS (
    -- müşterinin ne kadar yakın zamanda, ne sıklıkla ve ne kadar fiyat harcayarak sipariş yaptığını buluyoruz
    SELECT 
        c.customer_unique_id,
        DATEDIFF(
            (SELECT MAX(order_purchase_timestamp) FROM orders), 
            MAX(o.order_purchase_timestamp)
        ) AS recency,
        COUNT(DISTINCT o.order_id) AS frequency,
        ROUND(SUM(p.payment_value), 2) AS monetary
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_payments p
        ON p.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
rfm_scores AS (
    -- bulduğumuz değerler ile 1 ile 5 arasında bu 3 kategoriyi puanlandırıyoruz
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        NTILE(5) OVER(ORDER BY recency DESC) AS r_score,
        NTILE(5) OVER(ORDER BY frequency ASC) AS f_score,
        NTILE(5) OVER(ORDER BY monetary ASC) AS m_score
    FROM customer_rfm_raw
),
customer_segments AS (
    -- skorlara göre müşterileri segmentliyoruz
    SELECT
        customer_unique_id,
        recency,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score,f_score,m_score) AS rfm_score_combo,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'Potential Loyalists'
            WHEN r_score <= 2 AND f_score >= 3 THEN 'At Risk'
            WHEN r_score = 1 AND f_score <= 2 THEN 'Lost Customers'
            ELSE 'Regular Customers'
        END AS customer_segment
    FROM rfm_scores
)
SELECT 
    customer_segment,
    COUNT(*) AS customer_count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(), 2) AS customer_pct,
    ROUND(SUM(monetary), 2) AS total_revenue,
    ROUND(SUM(monetary) * 100 / SUM(SUM(monetary)) OVER(), 2) AS revenue_pct,
    ROUND(AVG(monetary), 2) AS avg_customer_spend,
    ROUND(AVG(recency), 0) AS avg_days_since_last_order
FROM customer_segments
GROUP BY customer_segment
ORDER BY total_revenue DESC
;