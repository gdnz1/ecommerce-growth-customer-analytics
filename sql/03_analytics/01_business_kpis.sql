USE ecommerce_analysis;

-- Genel platform sağlık metrikleri
WITH order_metrics AS(
    SELECT 
        COUNT(o.order_id) AS total_orders,
        COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) AS delivered_orders,
        COUNT(CASE WHEN o.order_status = 'canceled' THEN 1 END) AS canceled_orders,
        COUNT(DISTINCT c.customer_unique_id) AS unique_customers
    FROM orders o
    JOIN customers c
        ON o.customer_id = c.customer_id
),
payment_metrics AS (
    SELECT 
        SUM(payment_value) AS total_revenue
    FROM order_payments
)

SELECT 
    om.total_orders,
    om.delivered_orders,
    om.canceled_orders,
    om.unique_customers,
    ROUND(pm.total_revenue, 2) AS total_revenue,
    ROUND(pm.total_revenue / om.total_orders, 2) AS avg_order_value,
    ROUND(om.total_orders * 1.0 / om.unique_customers, 2) AS avg_orders_per_customer,
    ROUND((om.canceled_orders * 100) / om.total_orders, 2) AS cancellation_rate_pct

FROM order_metrics om
CROSS JOIN payment_metrics pm
;


--Sipariş durumları ve iptal/kayıp oranı

SELECT
    order_status,
    COUNT(*) AS order_count,
    ROUND(COUNT(*) * 100 / SUM(COUNT(*)) OVER(), 2) AS percentage_pct
FROM orders
GROUP BY order_status
ORDER BY order_count DESC
;

-- Same thing with cte
/*
WITH status_counts AS(
    SELECT order_status, COUNT(*) AS order_count 
    FROM orders
    GROUP BY order_status
),
total_metrics AS(
    SELECT COUNT(*) AS total_orders
    FROM orders
)
SELECT sc.order_status, sc.order_count, ROUND((sc.order_count * 100) / tm.total_orders, 2) AS percentage_pct
FROM status_counts sc
CROSS JOIN total_metrics tm
ORDER BY sc.order_count DESC
;
*/


--Aylık satış trendi ve büyüme

WITH monthly_sales AS(

    SELECT 
        DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS year_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        ROUND(SUM(p.payment_value), 2) AS monthly_revenue
    FROM orders o
    JOIN order_payments p
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY year_month
),
monthly_with_lag AS(

    SELECT 
        year_month,
        total_orders,
        monthly_revenue,
        LAG(monthly_revenue, 1) OVER(ORDER BY year_month) AS prev_month_revenue
    FROM monthly_sales
)

SELECT 
    year_month,
    total_orders,
    monthly_revenue,
    prev_month_revenue,
    ROUND((monthly_revenue - prev_month_revenue) * 100 / prev_month_revenue, 2) AS mom_growth_pct
FROM monthly_with_lag
ORDER BY year_month
;