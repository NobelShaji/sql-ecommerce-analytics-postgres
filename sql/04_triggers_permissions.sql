CREATE OR REPLACE FUNCTION core.decrement_inventory() RETURNS TRIGGER AS $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM core.orders
    WHERE order_id = NEW.order_id
      AND order_status IN ('paid','shipped')
  ) THEN
    UPDATE core.inventory
       SET on_hand = GREATEST(0, on_hand - NEW.qty),
           updated_at = NOW()
     WHERE product_id = NEW.product_id;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_inv_decrement ON core.order_items;
CREATE TRIGGER trg_inv_decrement
AFTER INSERT ON core.order_items
FOR EACH ROW
EXECUTE FUNCTION core.decrement_inventory();

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'analyst') THEN
    CREATE ROLE analyst NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'etl') THEN
    CREATE ROLE etl NOLOGIN;
  END IF;
END $$;

GRANT USAGE ON SCHEMA core, marts TO analyst, etl;
GRANT SELECT ON ALL TABLES IN SCHEMA core, marts TO analyst;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA core TO etl;

ALTER DEFAULT PRIVILEGES IN SCHEMA core GRANT SELECT ON TABLES TO analyst;
ALTER DEFAULT PRIVILEGES IN SCHEMA marts GRANT SELECT ON TABLES TO analyst;
