USE ecommerce_analysis;

-- dinamik aylık yönetici raporu prosedürü oluşturma
DROP PROCEDURE IF EXISTS sp_get_monthly_executive_report;

DELIMITER //

CREATE PROCEDURE sp_get_monthly_executive_report(
    IN p_year INT,
    IN p_month INT
)
BEGIN
    DECLARE target_period VARCHAR(7);
    SET target_period = CONCAT(p_year, '-', LPAD(p_month, 2, '0'));

    SELECT
        target_period AS report_month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END) AS delivered_orders,
        ROUND(SUM(p.payment_value), 2) AS total_revenue,
        ROUND(SUM(p.payment_value) / COUNT(DISTINCT o.order_id), 2) AS avg_order_value,
        ROUND(AVG(o.actual_delivery_days), 1) AS avg_delivery_days,
        COUNT(CASE WHEN o.is_delayed = 'delayed' THEN 1 END) AS delayed_orders,
        ROUND(COUNT(CASE WHEN o.is_delayed = 'delayed' THEN 1 END) * 100 / NULLIF(COUNT(CASE WHEN o.order_status = 'delivered' THEN 1 END), 0), 2) AS delay_rate_pct
    FROM vw_orders_enriched o
    JOIN order_payments p 
        ON o.order_id = p.order_id 
    WHERE o.order_year_month = target_period
    ;
END
//
DELIMITER ;

-- prosedür çağırıyoruz
CALL sp_get_monthly_executive_report(2017, 11);

CALL sp_get_monthly_executive_report(2018, 3);

