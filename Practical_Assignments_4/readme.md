# Practical Assignment 4 (Audi Dealership)


Таблиці

customers клієнтів на 100.000 записів
employees механіки та менеджери
cars автомобілі Audi
services послуги сервісу
orders транзакції (1:many з customers, 500.000 записів)
order_services таблиця для зв'язку послуг із замовленнями (зв'язок many:many)
test_drives тест-драйв (1:1 через unique)

![table](img/table.jpg)

## relationships
1. customers | orders 1:many
2. cars | orders 1:many
3. employees | orders 1:many
4. orders | services many:many (order_services)
5. orders | test_drives 1:1 (unique order_id)

## ERD
![ERD](img/erd.jpg)


Генерація данних(main.py)

Успішне наповнення бази даних
![Генерація бази](img/data_generation.jpg)

![наповнення cars](img/data_cars.jpg)

![наповнення customers](img/data_customers.jpg)

![наповнення orders](img/data_orders.jpg)


EXPLAIN_ANALYZE

Запит знаходить completed замовлення за травень 2023 з інформацією про клієнта і авто

Без індексів +- 94 ms
![Без індексів](img/without_index.jpg)


З індексами +- 31 ms 
![З індексами](img/with_index.jpg)

AI using
Використовувався ШІ для пошуку багів і фікса їх