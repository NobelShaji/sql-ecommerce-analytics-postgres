-- Daily revenue with 7-day moving average
WITH daily AS (
  SELECT order_date, SUM(gross_revenue) AS rev
  FROM marts.v_order_revenue
  WHERE order_status IN ('paid','shipped')
  GROUP BY 1
)
SELECT
  order_date,
  ROUND(rev,2) AS revenue,
  ROUND(AVG(rev) OVER (ORDER BY order_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS revenue_ma7
FROM daily
ORDER BY order_date;

-- Top categories (last 30 days)
SELECT c.category_name, ROUND(SUM(oi.qty * oi.unit_price),2) AS revenue
FROM core.order_items oi
JOIN core.orders o   ON o.order_id = oi.order_id
JOIN core.products p ON p.product_id = oi.product_id
JOIN core.categories c ON c.category_id = p.category_id
WHERE o.order_status IN ('paid','shipped')
  AND o.order_ts >= NOW() - INTERVAL '30 days'
GROUP BY 1
ORDER BY revenue DESC;

-- Basket pairs (co-occurrence)
WITH lines AS (
  SELECT order_id, product_id FROM core.order_items
),
pairs AS (
  SELECT l1.product_id AS a, l2.product_id AS b, COUNT(*) AS together
  FROM lines l1
  JOIN lines l2 ON l1.order_id = l2.order_id AND l1.product_id < l2.product_id
  GROUP BY 1,2
)
SELECT pa.product_name AS product_a, pb.product_name AS product_b, together
FROM pairs
JOIN core.products pa ON pa.product_id = a
JOIN core.products pb ON pb.product_id = b
ORDER BY together DESC
LIMIT 15;

-- RFM leaders
SELECT c.customer_id, c.email, rfm_score, freq, COALESCE(monetary,0) AS monetary
FROM marts.mv_rfm r
JOIN core.customers c USING (customer_id)
ORDER BY rfm_score ASC, monetary DESC
LIMIT 20;
