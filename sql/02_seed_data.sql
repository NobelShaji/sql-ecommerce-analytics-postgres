INSERT INTO core.categories (category_name)
SELECT unnest(ARRAY['Electronics','Home','Toys','Books','Beauty'])
ON CONFLICT DO NOTHING;

INSERT INTO core.products (sku, product_name, category_id, unit_price)
SELECT
  'SKU-' || lpad(g::text,4,'0'),
  CASE WHEN (g % 5)=0 THEN 'Wireless Headphones '||g
       WHEN (g % 5)=1 THEN 'Vacuum Cleaner '||g
       WHEN (g % 5)=2 THEN 'Action Figure '||g
       WHEN (g % 5)=3 THEN 'Paperback Novel '||g
       ELSE 'Face Serum '||g END,
  (g % 5)+1,
  (random()*150 + 5)::NUMERIC(10,2)
FROM generate_series(1,60) g
ON CONFLICT (sku) DO NOTHING;

INSERT INTO core.inventory (product_id, on_hand)
SELECT p.product_id, (random()*500)::INT + 100
FROM core.products p
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO core.customers (email, full_name, country, created_at)
SELECT
  'user' || g || '@example.com',
  'Customer ' || g,
  (ARRAY['US','CA','UK','IN','DE'])[1 + (random()*4)::INT],
  NOW() - ((random()*240)::INT || ' days')::INTERVAL
FROM generate_series(1,500) g
ON CONFLICT (email) DO NOTHING;

WITH dates AS (
  SELECT generate_series(
    date_trunc('day', NOW() - INTERVAL '180 days'),
    date_trunc('day', NOW()),
    '1 day'::interval
  ) AS d
)
INSERT INTO core.orders (customer_id, order_ts, order_status)
SELECT
  (SELECT customer_id FROM core.customers ORDER BY random() LIMIT 1),
  d + ((random()*23)::INT || ' hours')::INTERVAL
    + ((random()*59)::INT || ' minutes')::INTERVAL,
  (ARRAY['placed','paid','shipped','cancelled'])[1 + (random()*3)::INT]
FROM dates, generate_series(1,10) g
WHERE random() < 0.35;

INSERT INTO core.order_items (order_id, product_id, qty, unit_price)
SELECT
  o.order_id,
  (SELECT product_id FROM core.products ORDER BY random() LIMIT 1),
  1 + (random()*3)::INT,
  (SELECT unit_price FROM core.products p WHERE p.product_id =
     (SELECT product_id FROM core.products ORDER BY random() LIMIT 1)
  )
FROM core.orders o;

-- Add extra line to ~40% orders (for basket pairs)
INSERT INTO core.order_items (order_id, product_id, qty, unit_price)
SELECT
  o.order_id,
  p.product_id,
  1 + (random()*2)::int,
  p.unit_price
FROM core.orders o
JOIN LATERAL (
  SELECT product_id, unit_price
  FROM core.products
  ORDER BY random()
  LIMIT 1
) p ON true
WHERE random() < 0.4;

INSERT INTO core.payments (order_id, paid_ts, amount, method)
SELECT
  o.order_id,
  o.order_ts + ((random()*6)::INT || ' hours')::INTERVAL,
  (SELECT SUM(oi.qty*oi.unit_price) FROM core.order_items oi WHERE oi.order_id=o.order_id),
  (ARRAY['card','paypal','cod'])[1 + (random()*2)::INT]
FROM core.orders o
WHERE o.order_status IN ('paid','shipped');
