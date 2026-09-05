USE ecommerce_analysis;


-- indexleme yapmadan önce elimizdeki join ile yapılmış sorgunun maaliyetinin analiz edilmesi
EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_city,
    c.customer_state
FROM orders o
JOIN customers c 
    ON o.customer_id = c.customer_id 
WHERE o.order_purchase_timestamp BETWEEN '2017-11-01' AND '2017-11-30'
    AND c.customer_state = 'SP'
;

-- b-tree index oluşturuyoruz

-- tarih aramalarını hızlandırmak için
CREATE INDEX idx_orders_purchase_timestamp 
    ON orders(order_purchase_timestamp)
;

-- müşteri bazlı sipariş aramalarını hızlandırmak için
CREATE INDEX idx_orders_customer_id 
    ON orders(customer_id(32))
;

-- eyalet bazlı aramaları hızlandırmak için
CREATE INDEX idx_customers_state 
    ON customers(customer_state(10))
;

-- ürün ve satıcı bağlantılarını hızlandırmak için
CREATE INDEX idx_order_items_product_id 
    ON order_items(product_id(32))
;

CREATE INDEX idx_order_items_seller_id 
    ON order_items(seller_id(32))
;


-- indeksleme sonrasında tekrardan performans ölçümü yapıyoruz

EXPLAIN ANALYZE
SELECT
    o.order_id,
    o.order_status,
    o.order_purchase_timestamp,
    c.customer_city,
    c.customer_state
FROM orders o 
JOIN customers c 
    ON o.customer_id = c.customer_id 
WHERE o.order_purchase_timestamp BETWEEN '2017-11-01' AND '2017-11-30'
AND c.customer_state = 'SP'
;