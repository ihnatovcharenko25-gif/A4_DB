DROP TABLE IF EXISTS deliveries CASCADE;
DROP TABLE IF EXISTS drone_inspections CASCADE;
DROP TABLE IF EXISTS order_manifests CASCADE;
DROP TABLE IF EXISTS maintenance_crew CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS delivery_hubs CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS drones CASCADE;

-----------------------------------------------------------------------------------


CREATE TABLE IF NOT EXISTS drones (
    id INT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    max_weight NUMERIC(6, 2) NOT NULL CHECK (max_weight > 0)
);

CREATE TABLE IF NOT EXISTS customers (
    id INT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    surname VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS delivery_hubs (
    id INT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    country VARCHAR(100) NOT NULL,
    city VARCHAR(100) NOT NULL
);

CREATE TABLE IF NOT EXISTS orders (
    id INT PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    weight NUMERIC(6, 2) NOT NULL CHECK (weight > 0),
    deadline TIMESTAMP NOT NULL
);

CREATE TABLE IF NOT EXISTS maintenance_crew (
    id INT PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    workers_num INT NOT NULL CHECK (workers_num > 0) 
);

-----------------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS drone_inspections (
    crew_id INT NOT NULL REFERENCES maintenance_crew(id) ON DELETE CASCADE,
    drone_id INT NOT NULL REFERENCES drones(id) ON DELETE CASCADE,
    PRIMARY KEY (crew_id, drone_id)
);

CREATE TABLE IF NOT EXISTS deliveries (
    id INT PRIMARY KEY,
    drone_id INT REFERENCES drones(id) ON DELETE SET NULL,
    order_id INT UNIQUE REFERENCES orders(id) ON DELETE CASCADE,
    hub_id INT REFERENCES delivery_hubs(id) ON DELETE RESTRICT,
    customer_id INT REFERENCES customers(id) ON DELETE CASCADE,
    dispatch_time TIMESTAMP NOT NULL,
    delivery_status VARCHAR(50) NOT NULL 
    	CHECK(delivery_status IN ('Pending', 'Delivered', 'Canceled')) 
    	DEFAULT 'Pending'
);

--------------------------------------------------------------------------------------

INSERT INTO drones (id, name, max_weight)
SELECT 
    i, 
    'Model-' || (i % 10), 
    ROUND((1.0 + (i % 10)::NUMERIC + RANDOM()::NUMERIC), 2)
FROM generate_series(1, 200000) AS i;

INSERT INTO customers (id, name, surname, email)
SELECT 
    i, 
    'CustomerName' || i, 
    'CustomerSurname' || i, 
    'user' || i || '@gmail.com'
FROM generate_series(1, 5000) AS i;

INSERT INTO delivery_hubs (id, name, country, city)
SELECT 
    i, 
    'DeliveryHub' || i, 
    'Country' || (i % 67), 
    'City_' || (i % 666)
FROM generate_series(1, 10000) AS i;

INSERT INTO maintenance_crew (id, name, workers_num)
SELECT 
    i, 
    'MaintenanceCrew' || i, 
    (3 + (i % 10))
FROM generate_series(1, 10000) AS i;

INSERT INTO orders (id, customer_id, weight, deadline)
SELECT 
    i, 
    1 + FLOOR(RANDOM() * 4999)::INT, 
    ROUND((0.1 + (i % 5)::NUMERIC + RANDOM()::NUMERIC), 2),
    NOW() + (i || ' minutes')::INTERVAL
FROM generate_series(1, 550000) AS i;

INSERT INTO drone_inspections (crew_id, drone_id)
SELECT 
    1 + FLOOR(RANDOM() * 9999)::INT, 
    i
FROM generate_series(1, 100000) AS i
ON CONFLICT DO NOTHING;

INSERT INTO deliveries (id, drone_id, order_id, hub_id, customer_id, dispatch_time, delivery_status)
SELECT 
    i,
    1 + FLOOR(RANDOM() * 199999)::INT, 
    i,                                  
    1 + FLOOR(RANDOM() * 9999)::INT,   
    1 + FLOOR(RANDOM() * 4999)::INT, 
    NOW() - (i || ' seconds')::INTERVAL,
    'Pending'
FROM generate_series(1, 550000) AS i;

-----------------------------------------------------------------------------------------------------

DROP INDEX IF EXISTS idx_deliveries_drone_id;
DROP INDEX IF EXISTS idx_deliveries_customer_id;
DROP INDEX IF EXISTS idx_deliveries_hub_id;
DROP INDEX IF EXISTS idx_customers_email;

CREATE INDEX IF NOT EXISTS idx_deliveries_drone_id ON deliveries(drone_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_customer_id ON deliveries(customer_id);
CREATE INDEX IF NOT EXISTS idx_deliveries_hub_id ON deliveries(hub_id);
CREATE INDEX IF NOT EXISTS idx_customers_email ON customers(email);


DROP INDEX IF EXISTS idx_orders_customer_id;

CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);

EXPLAIN ANALYZE
SELECT 
    c.id AS customer_id,
    c.name || ' ' || c.surname AS customer_name,
    o.id AS order_id,
    o.weight AS package_weight,
    o.deadline,
    d.id AS delivery_id,
    d.delivery_status,
    d.dispatch_time
FROM customers c
JOIN orders o ON c.id = o.customer_id
LEFT JOIN deliveries d ON o.id = d.order_id
WHERE o.customer_id = 2500
ORDER BY o.deadline DESC;