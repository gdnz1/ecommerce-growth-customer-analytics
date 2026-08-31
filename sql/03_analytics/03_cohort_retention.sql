USE ecommerce_analysis;


WITH customer_first_purchase AS (
    -- her müşterinin ilk sipariş tarihini bulup tarihi ay ve yıl olarak düzenliyoruz
    SELECT
        c.customer_unique_id,
        MIN(o.order_purchase_timestamp) AS first_order_date,
        DATE_FORMAT(MIN(o.order_purchase_timestamp), '%Y-%m') AS cohort_month
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    WHERE o.order_status = 'delivered'
    GROUP BY c.customer_unique_id
),
cohort_activities AS (
    -- müşterinin siparişlerini ilk sipariş ayı ile eşleştirip farkını alıp cohort index hesaplıyoruz
    SELECT
        c.customer_unique_id,
        fp.cohort_month,
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_month,
        (YEAR(o.order_purchase_timestamp) - YEAR(fp.first_order_date)) * 12 +
        (MONTH(o.order_purchase_timestamp) - MONTH(fp.first_order_date)) AS cohort_index
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN customer_first_purchase fp
        ON fp.customer_unique_id = c.customer_unique_id
    WHERE o.order_status = 'delivered'
),
cohort_summary AS (
    -- her cohortun indeks bazında tekil aktif müşteri sayısı
    SELECT
        cohort_month,
        cohort_index,
        COUNT(DISTINCT customer_unique_id) AS active_customers
    FROM cohort_activities
    GROUP BY cohort_month, cohort_index
)
SELECT
    cohort_month,
    MAX(CASE WHEN cohort_index = 0 THEN active_customers END) AS cohort_size,
    MAX(CASE WHEN cohort_index = 1 THEN active_customers END) AS m1_users,
    MAX(CASE WHEN cohort_index = 2 THEN active_customers END) AS m2_users,
    MAX(CASE WHEN cohort_index = 3 THEN active_customers END) AS m3_users,
    MAX(CASE WHEN cohort_index = 4 THEN active_customers END) AS m4_users,
    MAX(CASE WHEN cohort_index = 5 THEN active_customers END) AS m5_users,
    MAX(CASE WHEN cohort_index = 6 THEN active_customers END) AS m6_users,

    ROUND(MAX(CASE WHEN cohort_index = 1 THEN active_customers ELSE 0 END)
     * 100 / MAX(CASE WHEN cohort_index = 0 THEN active_customers END), 2) AS m1_retention_pct,
    ROUND(MAX(CASE WHEN cohort_index = 2 THEN active_customers ELSE 0 END)
     * 100 / MAX(CASE WHEN cohort_index = 0 THEN active_customers END), 2) AS m2_retention_pct,
    ROUND(MAX(CASE WHEN cohort_index = 3 THEN active_customers ELSE 0 END)
     * 100 / MAX(CASE WHEN cohort_index = 0 THEN active_customers END), 2) AS m3_retention_pct
FROM cohort_summary
WHERE cohort_month >= '2017-01'
GROUP BY cohort_month
ORDER BY cohort_month
;