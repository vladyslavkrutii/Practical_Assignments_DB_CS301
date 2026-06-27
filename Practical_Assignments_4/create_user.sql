-- PostgreSQL version. Run as a superuser or database owner.
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'order_reader1') THEN
        CREATE ROLE order_reader1 LOGIN PASSWORD '123456Aa@AUDI';
    END IF;
END
$$;

GRANT CONNECT ON DATABASE audi_db TO order_reader1;
GRANT USAGE ON SCHEMA public TO order_reader1;
GRANT SELECT ON order_summary TO order_reader1;

-- Check grants:
-- \dp order_summary