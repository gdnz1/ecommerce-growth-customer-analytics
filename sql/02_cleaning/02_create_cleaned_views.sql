USE ecommerce_analysis;


-- temiz ürün ve kategori görünümü
CREATE OR REPLACE VIEW vw_cleaned_products AS
SELECT 
    pr.product_id,
    COALESCE(ct.product_category_name_english, pr.product_category_name,
     'unknown') AS category_name,
    COALESCE(pr.product_weight_g, 0) AS product_weight_g,
    COALESCE(pr.product_length_cm, 0) AS product_length_cm,
    COALESCE(pr.product_height_cm, 0) AS product_height_cm,
    COALESCE(pr.product_width_cm, 0) AS product_width_cm,
    COALESCE(pr.product_photos_qty, 0) AS product_photos_qty
FROM products pr
LEFT JOIN product_category_name_translation ct
    ON pr.product_category_name = ct.product_category_name
;


-- zenginleştirilmiş sipariş ve lojistik görünümü

CREATE OR REPLACE VIEW vw_orders_enriched AS
SELECT 
    o.order_id,
    o.customer_id,
    o.order_status,
    o.order_purchase_timestamp,
    o.order_approved_at,
    o.order_delivered_carrier_date,
    o.order_delivered_customer_date,
    o.order_estimated_delivery_date,
    DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m') AS order_year_month,
    -- gün cinsinden lojistik süre hesaplamaları
    DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp)
     AS estimated_delivery_days,
    DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)
     AS actual_delivery_days,
    -- gecikme durumu
    CASE
        WHEN order_delivered_customer_date IS NULL THEN 'not delivered'
        WHEN order_delivered_customer_date > order_estimated_delivery_date
             THEN 'delayed'
        ELSE 'on time'
    END AS is_delayed
FROM orders o
;