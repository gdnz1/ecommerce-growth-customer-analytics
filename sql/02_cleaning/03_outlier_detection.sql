USE ecommerce_analysis;

-- aykırı değer tespiti cte
WITH price_quartiles AS (
    SELECT
        price, 
        NTILE(4) OVER(ORDER BY price) AS quartile
    FROM order_items
),
iqr_bounds AS (
    SELECT
        MAX(CASE WHEN quartile = 1 THEN price END) AS q1,
        MAX(CASE WHEN quartile = 3 THEN price END) AS q3,
        MAX(CASE WHEN quartile = 3 THEN price END) - MAX(CASE WHEN quartile = 1 THEN price END) AS iqr
    FROM price_quartiles
),
outlier_thresholds AS (
    SELECT 
        q1,
        q3,
        iqr,
        ROUND(q1 - (1.5 * iqr), 2) AS lower_bound,
        ROUND(q3 + (1.5 * iqr), 2) AS upper_bound
    FROM iqr_bounds
)
SELECT
    ot.q1,
    ot.q3,
    ot.iqr,
    ot.lower_bound,
    ot.upper_bound,
    COUNT(CASE WHEN oi.price > ot.upper_bound THEN 1 END) AS high_outlier_count,
    COUNT(CASE WHEN oi.price < ot.lower_bound THEN 1 END) AS low_outlier_count,
    COUNT(*) AS total_items,
    ROUND(COUNT(CASE WHEN oi.price > ot.upper_bound OR oi.price < ot.lower_bound THEN 1 END) * 100 / COUNT(*), 2) AS outlier_percentage_pct
FROM order_items oi
CROSS JOIN outlier_thresholds ot
GROUP BY ot.q1, ot.q3, ot.lower_bound, ot.upper_bound
;


-- operasyonel ve mantıksal veri anomalileri


-- sıfır tutar'ı olan ödemeler
SELECT 
    order_id,
    payment_type,
    payment_value
FROM order_payments
WHERE payment_value = 0
;

-- sıfır taksit sayısı olan ödemeler
SELECT
    order_id,
    payment_type,
    payment_installments,
    payment_value
FROM order_payments
WHERE payment_installments = 0
;


-- aşırı yüksek kargo ücreti olan siparişler
SELECT 
    order_id,
    product_id,
    price,
    freight_value,
    ROUND(freight_value / price, 2) AS freight_to_price_ratio
FROM order_items
WHERE freight_value > (price *3)
ORDER BY freight_to_price_ratio DESC
LIMIT 20
;

-- yanıt tarihi yorum tarihinden önce olan yorumlar
SELECT 
    review_id,
    order_id,
    review_score,
    review_creation_date,
    review_answer_timestamp
FROM order_reviews
WHERE review_answer_timestamp < review_creation_date
;


