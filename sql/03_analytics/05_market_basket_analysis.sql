USE ecommerce_analysis;


CREATE INDEX idx_order_items_order_id
    ON order_items(order_id(32))
;

SELECT 
    LEAST(
        COALESCE(t1.product_category_name_english, p1.product_category_name, 'unknown'),
        COALESCE(t2.product_category_name_english, p2.product_category_name, 'unknown')
    ) AS category_a,
    GREATEST(
        COALESCE(t1.product_category_name_english, p1.product_category_name, 'unknown'),
        COALESCE(t2.product_category_name_english, p2.product_category_name, 'unknown')
    ) AS category_b,
    COUNT(DISTINCT oi1.order_id) AS times_bought_together
FROM order_items oi1
JOIN order_items oi2 
    ON oi1.order_id = oi2.order_id 
   AND oi1.order_item_id < oi2.order_item_id
JOIN products p1 ON oi1.product_id = p1.product_id
JOIN products p2 ON oi2.product_id = p2.product_id
LEFT JOIN product_category_name_translation t1 ON p1.product_category_name = t1.product_category_name
LEFT JOIN product_category_name_translation t2 ON p2.product_category_name = t2.product_category_name
JOIN orders o ON oi1.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND COALESCE(t1.product_category_name_english, p1.product_category_name, 'unknown') <> 
      COALESCE(t2.product_category_name_english, p2.product_category_name, 'unknown')
  AND COALESCE(t1.product_category_name_english, p1.product_category_name, 'unknown') <> 'unknown'
  AND COALESCE(t2.product_category_name_english, p2.product_category_name, 'unknown') <> 'unknown'
GROUP BY category_a, category_b
ORDER BY times_bought_together DESC
LIMIT 15;
