-- ============================================================
-- INVENTORY MANAGEMENT PROJECT
-- Recovered & cleaned from query history
-- ============================================================


-- ============================================================
-- SECTION 1: BASIC EXPLORATORY QUERIES
-- ============================================================

-- View all suppliers
SELECT * FROM suppliers;

-- View key supplier contact info
SELECT supplier_name, contact_name, email, phone
FROM suppliers;

-- Products joined with their suppliers
SELECT p.product_name, s.supplier_name, p.stock_quantity, p.reorder_level
FROM products AS p
JOIN suppliers s ON p.supplier_id = s.supplier_id
ORDER BY p.product_name;

-- Products that are below their reorder level (low stock alert)
SELECT product_id, product_name, stock_quantity, reorder_level
FROM products
WHERE stock_quantity < reorder_level;

-- View all shipments
SELECT * FROM shipments;

-- View all products
SELECT * FROM products;

-- View all product IDs
SELECT product_id FROM products;


-- ============================================================
-- SECTION 2: STORED PROCEDURE - Add New Product (with manual/auto ID)
-- Inserts into products, shipments, and stock_entries together
-- ============================================================

DROP PROCEDURE IF EXISTS AddNewProductManualID;

DELIMITER $$

CREATE PROCEDURE AddNewProductManualID(
    IN p_name VARCHAR(255),
    IN p_category VARCHAR(100),
    IN p_price DECIMAL(10,2),
    IN p_stock INT,
    IN p_reorder INT,
    IN p_supplier INT
)
BEGIN

    DECLARE new_prod_id INT;
    DECLARE new_shipment_id INT;
    DECLARE new_entry_id INT;

    -- Generate new product ID
    SELECT COALESCE(MAX(product_id), 0) + 1
    INTO new_prod_id
    FROM products;

    INSERT INTO products
    (
        product_id,
        product_name,
        category,
        price,
        stock_quantity,
        reorder_level,
        supplier_id
    )
    VALUES
    (
        new_prod_id,
        p_name,
        p_category,
        p_price,
        p_stock,
        p_reorder,
        p_supplier
    );

    -- Generate new shipment ID
    SELECT COALESCE(MAX(shipment_id), 0) + 1
    INTO new_shipment_id
    FROM shipments;

    INSERT INTO shipments
    (
        shipment_id,
        product_id,
        supplier_id,
        quantity_received,
        shipment_date
    )
    VALUES
    (
        new_shipment_id,
        new_prod_id,
        p_supplier,
        p_stock,
        CURDATE()
    );

    -- Generate new stock entry ID
    SELECT COALESCE(MAX(entry_id), 0) + 1
    INTO new_entry_id
    FROM stock_entries;

    INSERT INTO stock_entries
    (
        entry_id,
        product_id,
        change_quantity,
        change_type,
        entry_date
    )
    VALUES
    (
        new_entry_id,
        new_prod_id,
        p_stock,
        'Restock',
        CURDATE()
    );

END $$

DELIMITER ;

-- Example calls:
-- CALL AddNewProductManualID('Smart Watch', 'Electronics', 99.00, 100, 23, 5);
-- CALL AddNewProductManualID('Mobile', 'Electronics', 99.00, 100, 25, 5);


-- ============================================================
-- SECTION 3: STOCK ENTRY SUMMARY QUERIES
-- ============================================================

-- Count of stock entries grouped by change type
SELECT change_type, COUNT(*) AS total
FROM stock_entries
GROUP BY change_type;

-- Date range and count per change type
SELECT
    change_type,
    MIN(entry_date) AS first_date,
    MAX(entry_date) AS last_date,
    COUNT(*) AS total
FROM stock_entries
GROUP BY change_type;


-- ============================================================
-- SECTION 4: VIEW - Product Inventory History
-- Combines shipments + stock_entries into a single history feed
-- ============================================================

CREATE OR REPLACE VIEW product_inventory_history AS
SELECT
    pih.product_id,
    pih.record_type,
    pih.record_date,
    pih.quantity,
    pih.change_type,
    pr.supplier_id
FROM
(
    SELECT
        product_id,
        'Shipment' AS record_type,
        shipment_date AS record_date,
        quantity_received AS quantity,
        NULL AS change_type
    FROM shipments

    UNION ALL

    SELECT
        product_id,
        'Stock Entry' AS record_type,
        entry_date AS record_date,
        change_quantity AS quantity,
        change_type
    FROM stock_entries
) pih
JOIN products pr ON pr.product_id = pih.product_id;

-- View full history
SELECT * FROM product_inventory_history;

-- View history for a specific product
SELECT * FROM product_inventory_history
WHERE product_id = 123
ORDER BY record_date DESC;


-- ============================================================
-- SECTION 5: REORDERS
-- ============================================================

-- Insert a new reorder record
INSERT INTO reorders
(
    reorder_id,
    product_id,
    reorder_quantity,
    reorder_date,
    status
)
SELECT
    COALESCE(MAX(reorder_id), 0) + 1,
    101,
    200,
    CURDATE(),
    'Ordered'
FROM reorders;

-- View reorders for a specific product
SELECT * FROM reorders
WHERE product_id = 101
ORDER BY reorder_id DESC;

-- View all reorders
SELECT * FROM reorders;


-- ============================================================
-- SECTION 6: STORED PROCEDURE - Mark Reorder As Received
-- Updates reorder status, restocks product, and logs shipment + stock entry
-- ============================================================

DROP PROCEDURE IF EXISTS MarkReorderAsReceived;

DELIMITER $$

CREATE PROCEDURE MarkReorderAsReceived(
    IN in_reorder_id INT
)
BEGIN

    DECLARE prod_id INT;
    DECLARE qty INT;
    DECLARE sup_id INT;
    DECLARE new_shipment_id INT;
    DECLARE new_entry_id INT;

    START TRANSACTION;

    -- Get product ID and reorder quantity
    SELECT product_id, reorder_quantity
    INTO prod_id, qty
    FROM reorders
    WHERE reorder_id = in_reorder_id;

    -- Get supplier ID from products
    SELECT supplier_id
    INTO sup_id
    FROM products
    WHERE product_id = prod_id;

    -- Update reorder status
    UPDATE reorders
    SET status = 'Received'
    WHERE reorder_id = in_reorder_id;

    -- Update product stock quantity
    UPDATE products
    SET stock_quantity = stock_quantity + qty
    WHERE product_id = prod_id;

    -- Generate new shipment ID
    SELECT COALESCE(MAX(shipment_id), 0) + 1
    INTO new_shipment_id
    FROM shipments;

    -- Insert shipment record
    INSERT INTO shipments
    (
        shipment_id,
        product_id,
        supplier_id,
        quantity_received,
        shipment_date
    )
    VALUES
    (
        new_shipment_id,
        prod_id,
        sup_id,
        qty,
        CURDATE()
    );

    -- Generate new stock entry ID
    SELECT COALESCE(MAX(entry_id), 0) + 1
    INTO new_entry_id
    FROM stock_entries;

    -- Insert restock record
    INSERT INTO stock_entries
    (
        entry_id,
        product_id,
        change_quantity,
        change_type,
        entry_date
    )
    VALUES
    (
        new_entry_id,
        prod_id,
        qty,
        'Restock',
        CURDATE()
    );

    COMMIT;

END $$

DELIMITER ;

-- Example call:
-- CALL MarkReorderAsReceived(1);
