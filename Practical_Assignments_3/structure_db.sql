-- Practical_Assignment_3

create table customers (
    customer_id serial primary key,
    full_name varchar(100) not null,
    email varchar(100) unique not null,
    balance numeric(10,2) default 0
);

create table products (
    product_id serial primary key,
    product_name varchar(100) not null,
    price numeric(10,2) not null,
    stock_quantity int not null
);

create table orders (
    order_id serial primary key,
    customer_id int references customers(customer_id),
    order_date timestamp default current_timestamp,
    total_amount numeric(10,2) default 0
);

create table order_items (
    order_item_id serial primary key,
    order_id int references orders(order_id),
    product_id int references products(product_id),
    quantity int not null,
    price numeric(10,2) not null
);

create table order_log (
    log_id serial primary key,
    order_id int,
    customer_id int,
    action varchar(50),
    log_date timestamp default current_timestamp
);

-- task 1 

create or replace function calculate_order_total(p_order_id int)
returns decimal(10,2) 
as $$
    select coalesce(sum(quantity * price), 0)
    from order_items
    where order_id = p_order_id;
$$ language sql;

-- task 2
create or replace procedure create_order(p_customer_id int)
as $$
begin
    insert into orders(customer_id, order_date, total_amount)
    values(p_customer_id, current_timestamp, 0);
end;
$$ language plpgsql;

-- task 3
create or replace procedure add_product_to_order(
    p_order_id int,
    p_product_id int,
    p_quantity int
)
as $$
declare
    v_price decimal(10,2);
    v_stock int;
begin
    if p_quantity < 0 then raise exception 'error quantity';
    end if;

    select price, stock_quantity into v_price, v_stock 
    from products 
    where product_id = p_product_id;

    if v_stock < p_quantity then raise exception 'no stock';
    end if;

    insert into order_items(order_id, product_id, quantity, price)
    values(p_order_id, p_product_id, p_quantity, v_price);

    update products 
    set stock_quantity = stock_quantity - p_quantity 
    where product_id = p_product_id;
end;
$$ language plpgsql;

-- task 4

create or replace function update_order_total()
returns trigger as $$
begin
    update orders
    set total_amount = calculate_order_total(coalesce(new.order_id, old.order_id))
    where order_id = coalesce(new.order_id, old.order_id);
    return null;
end;
$$ language plpgsql;

create trigger total_trigger
after insert or update or delete on order_items
for each row
execute function update_order_total();

-- task 5

create or replace function log_order()
returns trigger as $$
begin
    insert into order_log(order_id, customer_id, action)
    values(new.order_id, new.customer_id, 'create');
    return new;
end;
$$ language plpgsql;

create trigger log_trigger
after insert on orders
for each row
execute function log_order();