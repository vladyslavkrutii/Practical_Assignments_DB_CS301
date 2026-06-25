-- PostgreSQL version
-- Create the database manually if needed:
-- CREATE DATABASE opt_db;
-- Then connect to it:
-- \c opt_db

-- DROP TABLE IF EXISTS opt_orders;
-- DROP TABLE IF EXISTS opt_products;
-- DROP TABLE IF EXISTS opt_clients;

create table opt_clients (
  id serial primary key,
  full_name varchar(100) not null,
  phone varchar(25) not null,
  status varchar(25) not null check (status in ('active', 'inactive'))
);

create table opt_cars (
  id serial primary key,
  brand varchar(50) not null,
  model varchar(50) not null,
  year int not null
);

create table opt_orders (
  id serial primary key,
  client_id int not null,
  car_id int not null,
  order_date date not null,
  price decimal(10, 2) not null,
  foreign key (client_id) references opt_clients(id),
  foreign key (car_id) references opt_cars(id)
);