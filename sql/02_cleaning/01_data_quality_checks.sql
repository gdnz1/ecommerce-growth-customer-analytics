USE ecommerce_analysis;


SELECT product_id, product_category_name
FROM products
WHERE product_category_name IS NULL
;

SELECT order_id, order_purchase_timestamp, order_delivered_customer_date
FROM orders
WHERE order_status = 'delivered' 
    AND order_delivered_customer_date < order_purchase_timestamp
;

SELECT DISTINCT pr.product_category_name
FROM products pr
LEFT JOIN product_category_name_translation ct
    ON pr.product_category_name = ct.product_category_name
WHERE ct.product_category_name IS NULL
    AND pr.product_category_name IS NOT NULL
;

------------------------------------------------
-- veri kalite kontrol skor kartı (birleşim)


SELECT 
    'Missing Product Categories' as check_name,
    COUNT(*) AS failed_records,
    'Products table has NULL category values' AS issue_description
FROM products
WHERE product_category_name IS NULL

UNION ALL

SELECT 
    'Delivery Date Anomalies' as check_name,
    COUNT(*) AS failed_records,
    'Delivered date is earlier than purchase date' AS issue_description
FROM orders
WHERE order_status = 'delivered' 
    AND order_delivered_customer_date < order_purchase_timestamp

UNION ALL

SELECT 
    'Missing Category Translations' AS check_name,
    COUNT(DISTINCT pr.product_category_name) AS failed_records,
    'Categories with no English translation available' AS issue_description
FROM products pr
LEFT JOIN product_category_name_translation ct
    ON pr.product_category_name = ct.product_category_name
WHERE ct.product_category_name IS NULL
    AND pr.product_category_name IS NOT NULL
;