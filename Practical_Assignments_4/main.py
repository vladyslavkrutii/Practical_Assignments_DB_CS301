import random
from datetime import datetime, timedelta, date

import psycopg2
from psycopg2 import Error
from psycopg2.extras import execute_values
from faker import Faker

HOST = 'localhost'
USER = 'postgres'
PASSWORD = '123456'
DATABASE = 'audi_db'
PORT = '5432'

fake = Faker()

CUSTOMERS_COUNT = 100_000
ORDERS_COUNT = 500_000
CHUNK_SIZE = 20_000 

MODELS = ['RS7', 'RS6', 'A6', 'A8', 'A5', 'Q5', 'Q7', 'Q8', 'e-tron']
COLORS = ['Black', 'White', 'Yellow', 'Gray', 'Blue', 'Green']
STATUSES = ['pending', 'confirmed', 'cancelled', 'completed']


def create_connection():
    try:
        connection = psycopg2.connect(
            host=HOST, port=PORT, user=USER, password=PASSWORD, dbname=DATABASE
        )
        print("Connection to PostgreSQL DB successful")
        return connection
    except Error as e:
        print(f"The error '{e}' occurred")
        return None


def insert_data():
    connection = create_connection()
    if connection is None:
        return

    try:
        with connection.cursor() as cur:

            # послуги
            cur.execute(
                "insert into services (service_name, price) values "
                "('Діагностика', 1500), ('Заміна мастила', 2550), ('Детейлінг', 6700);"
            )

            # співробітники
            cur.execute(
                "insert into employees (first_name, last_name, position) values "
                "('Ілля', 'Байдук', 'manager'), ('Максим', 'Пономаренко', 'mechanic');"
            )

            # автомобілі Audi
            print("Generating 5000 cars......")
            cars_data = []
            for _ in range(5000):
                cars_data.append((
                    random.choice(MODELS),
                    random.randint(2014, 2025),
                    random.choice(COLORS),
                    round(random.uniform(30000, 150000), 2),
                    fake.bothify(text='WA1##############').upper()
                ))
            execute_values(cur, "insert into cars (model, year, color, price, vin) values %s", cars_data)

           # клієнти
            print(f"Generating {CUSTOMERS_COUNT} customers.....")
            email_counter = 1
            for start in range(0, CUSTOMERS_COUNT, CHUNK_SIZE):
                cust_data = []
                for _ in range(CHUNK_SIZE):
                    f_name = fake.first_name()
                    l_name = fake.last_name()
                    email = f"{f_name.lower()}.{l_name.lower()}{email_counter}@audi-test"
                    email_counter += 1
                    cust_data.append((
                        f_name,
                        l_name,
                        email,
                        fake.phone_number()[:25],
                        fake.city()[:50]
                    ))
                execute_values(cur, "insert into customers (first_name, last_name, email, phone, city) values %s", cust_data)
            cur.execute("select customer_id from customers limit 20000;")
            customer_ids = [r[0] for r in cur.fetchall()]

            cur.execute("select car_id from cars;")
            car_ids = [r[0] for r in cur.fetchall()]

            cur.execute("select employee_id from employees;")
            emp_ids = [r[0] for r in cur.fetchall()]

            print(f"Generating {ORDERS_COUNT} orders......")
            date_start = date(2020, 1, 1)
            for start in range(0, ORDERS_COUNT, CHUNK_SIZE):
                order_data = []
                for _ in range(CHUNK_SIZE):
                    order_data.append((
                        random.choice(customer_ids),
                        random.choice(car_ids),
                        random.choice(emp_ids),
                        date_start + timedelta(days=random.randint(0, 1500)),
                        random.choice(STATUSES),
                        round(random.uniform(30000, 150000), 2)
                    ))
                execute_values(cur, "insert into orders (customer_id, car_id, employee_id, order_date, status, total_price) values %s", order_data)

            cur.execute("select order_id from orders limit 30000;")
            order_ids = [r[0] for r in cur.fetchall()]

            cur.execute("select service_id from services;")
            service_ids = [r[0] for r in cur.fetchall()]

            # order_services many:many
            print("Mapping services to orders...")
            os_data = [(oid, random.choice(service_ids), 1) for oid in order_ids[:10000]]
            execute_values(cur, "insert into order_services (order_id, service_id, quantity) values %s on conflict do nothing", os_data)

            # test_drives 1:1
            print("Generating test drives...")
            td_data = [(oid, datetime.now() - timedelta(days=random.randint(1, 500))) for oid in order_ids[10000:20000]]
            execute_values(cur, "insert into test_drives (order_id, scheduled_at) values %s on conflict do nothing", td_data)

        connection.commit()
        print("All data generated good !!!!!")

    except Error as e:
        connection.rollback()
        print(f"Database error :: {e}")
    finally:
        connection.close()

if __name__ == "__main__":
    insert_data()