USE ecommerce_analysis;



-- sipariş durumu log tablosu oluşturuyoruz
CREATE TABLE IF NOT EXISTS order_status_audit_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id VARCHAR(32) NOT NULL,
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    changed_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    changed_by VARCHAR(50) DEFAULT (CURRENT_USER())
)
;


-- otomatik denetim tetikleyicisi (audit trigger)
DROP TRIGGER IF EXISTS trg_order_status_update_audit;

DELIMITER //

CREATE TRIGGER trg_order_status_update_audit
AFTER UPDATE ON orders 
FOR EACH ROW
BEGIN
    IF OLD.order_status <> NEW.order_status THEN 
        INSERT INTO order_status_audit_log (
            order_id,
            old_status,
            new_status,
            changed_at,
            changed_by
        )
        VALUES (
            OLD.order_id,
            OLD.order_status,
            NEW.order_status,
            NOW(),
            CURRENT_USER()
        )
        ;
    END IF;
END //

DELIMITER ;



-- test ediyoruz
UPDATE orders 
SET order_status = 'delivered'
WHERE order_id = '136cce7faa42fdb2cefd53fdc79a6098'
;


SELECT *
FROM order_status_audit_log
;