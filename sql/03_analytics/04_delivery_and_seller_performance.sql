USE ecommerce_analysis;

-- siparişlerin eyaletlere oranla sayısını, ortalama gerçek ve beklenen teslimat süresini ve eyaletlere göre gecikme oranlarını listeleyen sorgu
SELECT
    c.customer_state,
    COUNT(*) AS total_orders,
    COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) AS delivered_orders,
    ROUND(AVG(CASE WHEN o.order_status = 'delivered' THEN o.estimated_delivery_days END), 1) AS avg_estimated_days,
    ROUND(AVG(CASE WHEN o.order_status = 'delivered' THEN o.actual_delivery_days END), 1) AS avg_delivery_days,
    COUNT(CASE WHEN o.is_delayed = 'delayed' THEN 1 END) AS delayed_orders_count,
    ROUND(COUNT(CASE WHEN o.is_delayed = 'delayed' THEN 1 END) * 100 / COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END), 2) AS delay_pct

FROM vw_orders_enriched o
JOIN customers c
    ON o.customer_id = c.customer_id
GROUP BY c.customer_state
ORDER BY delay_pct DESC
;


WITH category_revenue AS (
    -- her kategorinin toplam cirosunu ve sipariş sayısını hesaplıyoruz
    SELECT
        pr.category_name,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM vw_cleaned_products pr
    JOIN order_items oi
        ON pr.product_id = oi.product_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY pr.category_name
)
-- kümülatif toplam ve kümülatif yüzde hesaplıyoruz
SELECT
    category_name,
    total_orders,
    total_revenue,
    SUM(total_revenue) OVER(ORDER BY total_revenue DESC) AS cumulative_revenue,
    ROUND(SUM(total_revenue) OVER(ORDER BY total_revenue DESC) * 100 / SUM(total_revenue) OVER(), 2) AS cumulative_pct
FROM category_revenue
ORDER BY total_revenue DESC
;


WITH seller_revenue AS (
    -- satıcıların toplam siparişlerini ve toplam cirolarını yazdırıyoruz
    SELECT
        oi.seller_id,
        COUNT(DISTINCT oi.order_id) AS total_orders,
        ROUND(SUM(oi.price), 2) AS total_revenue
    FROM order_items oi
    JOIN orders o 
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.seller_id
)
SELECT
    -- cirolarına oranla satıcıları hem ulusal düzeyde hem de eyalet düzeyinde sıralıyoruz
    sr.seller_id,
    s.seller_state,
    sr.total_orders,
    sr.total_revenue,
    DENSE_RANK() OVER (ORDER BY sr.total_revenue DESC) AS national_rank,
    DENSE_RANK() OVER (PARTITION BY s.seller_state ORDER BY sr.total_revenue DESC) AS state_rank
FROM seller_revenue sr
JOIN sellers s 
    ON sr.seller_id = s.seller_id
ORDER BY total_revenue DESC
;