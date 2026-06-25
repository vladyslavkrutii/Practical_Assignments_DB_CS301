import uuid
import random
from datetime import datetime, timedelta

import psycopg2
from psycopg2.extras import execute_values
from faker import Faker


# Connection settings
HOST = 'localhost' # put your credentials here
USER = 'postgres' # put your credentials here
PASSWORD = '123456' # put your credentials here
DATABASE = 'carservice' # put your credentials here
PORT = '5432' # put your credentials here

# Data volume settings
CLIENTS_COUNT = 100_000
PRODUCTS_COUNT = 1_000
ORDERS_COUNT = 1_000_000
CHUNK_SIZE = 10_000

fake = Faker()


def insert_clients(cursor):
    print("Inserting into opt_clients...")

    client_insert_query = """
        INSERT INTO opt_clients
            (full_name, phone, status)
        VALUES %s
        RETURNING id
    """

    client_ids = []

    for start in range(0, CLIENTS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, CLIENTS_COUNT - start)

        clients_data = []
        for _ in range(current_chunk_size):
            clients_data.append(
                (
                    fake.name(),
                    fake.phone_number(),
                    random.choice(["active", "inactive"]),
                )
            )

        execute_values(cursor, client_insert_query, clients_data)
        print(f"Inserted {start + current_chunk_size} rows into opt_clients...")

        generated_id = [row[0] for row in cursor.fetchall()]
        client_ids.extend(generated_id)

    print("Inserted into opt_clients.")
    return client_ids

def insert_cars(cursor):
    print("Inserting into opt_cars...")

    car_insert_query = """
        INSERT INTO opt_cars
            (brand, model, year)
        VALUES %s
        RETURNING id
    """

    brands = ['Audi', 'BMW', 'Mercedes', 'Toyota', 'Ford', 'Honda', 'Nissan', 'Volkswagen']

    car_data = [
        (
            random.choice(brands),
            fake.word(),
            random.randint(2008, 2026),
        )
        for _ in range(PRODUCTS_COUNT)
    ]

    execute_values(cursor, car_insert_query, car_data)

    car_ids = [row[0] for row in cursor.fetchall()]

    print("Inserted into opt_cars.")
    return car_ids


def insert_orders(cursor, client_ids, car_ids):
    print("Inserting into opt_orders...")

    order_insert_query = """
        INSERT INTO opt_orders
            (order_date, client_id, car_id, price)
        VALUES %s
    """

    order_date_start = datetime.now() - timedelta(days=365 * 5)

    for start in range(0, ORDERS_COUNT, CHUNK_SIZE):
        current_chunk_size = min(CHUNK_SIZE, ORDERS_COUNT - start)

        orders_data = [
            (
                order_date_start + timedelta(days=random.randint(0, 365 * 5)),
                random.choice(client_ids),
                random.choice(car_ids),
                random.randint(200, 10000),
            )
            for _ in range(current_chunk_size)
        ]

        execute_values(cursor, order_insert_query, orders_data)
        print(f"Inserted {start + current_chunk_size} rows into opt_orders...")

    print("Inserted into opt_orders.")


def main():
    connection = psycopg2.connect(
        host=HOST,
        user=USER,
        password=PASSWORD,
        dbname=DATABASE,
        port=PORT,
    )

    try:
        with connection:
            with connection.cursor() as cursor:
                client_ids = insert_clients(cursor)
                car_ids = insert_cars(cursor)
                insert_orders(cursor, client_ids, car_ids)

    finally:
        connection.close()


if __name__ == "__main__":
    main()