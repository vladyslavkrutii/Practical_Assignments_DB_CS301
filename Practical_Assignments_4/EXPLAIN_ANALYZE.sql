-- explain analyze (порівняння результату з і без індексів)

-- видалення індексів
drop index if exists idx_orders_order_date;
drop index if exists idx_orders_customer_id;
drop index if exists idx_orders_car_id;
drop index if exists idx_cars_status;
drop index if exists idx_customers_email;

-- без індексів
explain analyze
select
    customer.first_name,
    customer.last_name,
    car.model,
    orders.order_date,
    orders.status,
    orders.total_price
from orders
join customers customer on orders.customer_id = customer.customer_id
join cars car on orders.car_id = car.car_id
where orders.order_date >= '2023-05-01' and orders.order_date <= '2023-06-01' and orders.status = 'completed';

-- створюємо
create index if not exists idx_orders_order_date on orders(order_date);
create index if not exists idx_orders_customer_id on orders(customer_id);
create index if not exists idx_orders_car_id on orders(car_id);
create index if not exists idx_cars_status on cars(status);
create index if not exists idx_customers_email on customers(email);

-- з індексами
explain analyze
select
    customer.first_name,
    customer.last_name,
    car.model,
    orders.order_date,
    orders.status,
    orders.total_price
from orders
join customers customer on orders.customer_id = customer.customer_id
join cars car on orders.car_id = car.car_id
where orders.order_date >= '2023-05-01' and orders.order_date <= '2023-06-01' and orders.status = 'completed';