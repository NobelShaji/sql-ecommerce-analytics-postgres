CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS marts;

CREATE TABLE IF NOT EXISTS core.categories (
  category_id SERIAL PRIMARY KEY,
  category_name TEXT UNIQUE NOT NULL
);

CREATE TABLE IF NOT EXISTS core.products (
  product_id SERIAL PRIMARY KEY,
  sku TEXT UNIQUE NOT NULL,
  product_name TEXT NOT NULL,
  category_id INT NOT NULL REFERENCES core.categories(category_id),
  unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE IF NOT EXISTS core.customers (
  customer_id SERIAL PRIMARY KEY,
  email TEXT UNIQUE NOT NULL,
  full_name TEXT NOT NULL,
  country TEXT NOT NULL DEFAULT 'US',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS core.orders (
  order_id SERIAL PRIMARY KEY,
  customer_id INT NOT NULL REFERENCES core.customers(customer_id),
  order_ts TIMESTAMPTZ NOT NULL,
  order_status TEXT NOT NULL CHECK (order_status IN ('placed','paid','shipped','cancelled'))
);

CREATE TABLE IF NOT EXISTS core.order_items (
  order_item_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES core.orders(order_id),
  product_id INT NOT NULL REFERENCES core.products(product_id),
  qty INT NOT NULL CHECK (qty > 0),
  unit_price NUMERIC(10,2) NOT NULL CHECK (unit_price >= 0)
);

CREATE TABLE IF NOT EXISTS core.payments (
  payment_id SERIAL PRIMARY KEY,
  order_id INT NOT NULL REFERENCES core.orders(order_id),
  paid_ts TIMESTAMPTZ NOT NULL,
  amount NUMERIC(10,2) NOT NULL CHECK (amount >= 0),
  method TEXT NOT NULL CHECK (method IN ('card','paypal','cod'))
);

CREATE TABLE IF NOT EXISTS core.inventory (
  product_id INT PRIMARY KEY REFERENCES core.products(product_id),
  on_hand INT NOT NULL CHECK (on_hand >= 0),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_orders_customer ON core.orders (customer_id);
CREATE INDEX IF NOT EXISTS idx_order_items_product ON core.order_items (product_id);
CREATE INDEX IF NOT EXISTS idx_orders_ts ON core.orders (order_ts);
CREATE INDEX IF NOT EXISTS idx_customers_created ON core.customers (created_at);
