-- PostgreSQL version
-- Run once outside the database if needed:
-- CREATE DATABASE uni_db;
-- Then connect to uni_db and run the rest of this file.

-- створення нової бд
--  CREATE DATABASE audi_db;

drop table if exists customers cascade;
drop table if exists employees cascade;
drop table if exists cars cascade;
drop table if exists services cascade;
drop table if exists orders cascade;
drop table if exists order_services cascade;
drop table if exists test_drives cascade;
 
--  customers наші клієнти які можуть купить авто
create table customers (
    customer_id serial primary key,
    first_name varchar(255) not null,
    last_name varchar(255) not null,
    email varchar(50) not null unique,
    phone varchar(25)  not null,
    city varchar(50)
);
 
-- employees механіки та менеджери
create table employees (
    employee_id serial primary key,
    first_name varchar(255) not null,
    last_name varchar(255) not null,
    position varchar(25)  not null check(position in ('mechanic', 'manager')),
    email varchar(50) unique
);
 

-- cars автомобілі(AUDI) які є в наявності або вже продані
create table cars (
    car_id serial primary key,
    model varchar(100) not null,  
    year int not null check(year >= 2008 and year <= 2027),
    color varchar(50),
    price decimal(12, 2) not null check(price > 0),
    vin varchar(20) not null unique, 
    status varchar(20) not null default 'available' check(status in ('available', 'sold'))
);
 
-- services послуги салону
create table services (
    service_id serial primary key,
    service_name varchar(100) not null,
    price decimal(10, 2) not null check(price >= 0),
    description text
);
 
-- orders замовлення на придбання авто (1:many з customers) один клієнт може мати кілька замовлень
create table orders (
    order_id serial primary key,
    customer_id int not null references customers(customer_id),
    car_id int not null references cars(car_id),
    employee_id int references employees(employee_id),--менеджер який оформив замовлення
    order_date date not null default current_date,
    status varchar(25) not null default 'pending' check(status in ('pending', 'confirmed', 'cancelled', 'completed')),
    total_price decimal(10, 2)-- фінальна ціна
);
 

-- order_services (many:many між orders і services) одне замовлення може мати кілька послуг і навпаки
create table order_services (
    order_id int not null references orders(order_id) on delete cascade,
    service_id int not null references services(service_id),
    quantity int not null default 1 check(quantity > 0),
    primary key(order_id, service_id)
);
 
-- test_drives (1:1 з orders) тест-драйв зв'язанний до конкретного замовлення
create table test_drives (
    test_drive_id serial primary key,
    order_id int not null unique references orders(order_id),
    scheduled_at timestamp not null,
    duration_min int not null default 45 check(duration_min > 0),
    feedback varchar(255)
);
 

-- індекси для оптимізації
create index if not exists idx_orders_order_date on orders(order_date);
create index if not exists idx_orders_customer_id on orders(customer_id);
create index if not exists idx_orders_car_id on orders(car_id);
create index if not exists idx_cars_status on cars(status);
create index if not exists idx_customers_email on customers(email);