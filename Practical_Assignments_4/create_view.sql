CREATE OR REPLACE VIEW order_summary AS
SELECT
    customer.first_name AS customer_first_name,
    customer.last_name AS customer_last_name,
    customer.email AS customer_email,
    car.model AS car_model,
    car.year AS car_year,
    car.color AS car_color,
    employee.first_name AS employee_first_name,
    employee.last_name AS employee_last_name,
    employee.position AS employee_position,
    orders.order_date,
    orders.status AS order_status,
    orders.total_price
FROM orders
JOIN customers customer
    ON orders.customer_id = customer.customer_id
JOIN cars car
    ON orders.car_id = car.car_id
JOIN employees employee
    ON orders.employee_id = employee.employee_id;

-- To check performance, run separately, not inside CREATE VIEW:
-- EXPLAIN ANALYZE SELECT * FROM order_summary;