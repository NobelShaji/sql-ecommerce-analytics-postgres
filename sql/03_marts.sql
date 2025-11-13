CREATE OR REPLACE VIEW marts.v_order_revenue AS
SELECT
  o.order_id,
  o.customer_id,
  date_trunc('day', o.order_ts)::date AS order_date,
  COALESCE(SUM(oi.qty*oi.unit_price),0)::numeric(12,2) AS gross_revenue,
  o.order_status
FROM core.orders o
LEFT JOIN core.order_items oi ON oi.order_id=o.order_id
GROUP BY 1,2,3,5;

DROP MATERIALIZED VIEW IF EXISTS marts.mv_rfm;
CREATE MATERIALIZED VIEW marts.mv_rfm AS
WITH base AS (
  SELECT
    c.customer_id,
    MAX(o.order_ts) AS last_order_ts,
    COUNT(DISTINCT o.order_id) FILTER (WHERE o.order_status IN ('paid','shipped')) AS freq,
    SUM(oi.qty*oi.unit_price) FILTER (WHERE o.order_status IN ('paid','shipped'))::numeric(12,2) AS monetary
  FROM core.customers c
  LEFT JOIN core.orders o ON o.customer_id=c.customer_id
  LEFT JOIN core.order_items oi ON oi.order_id=o.order_id
  GROUP BY 1
),
scores AS (
  SELECT *,
    ntile(5) OVER (ORDER BY EXTRACT(EPOCH FROM (NOW()-last_order_ts))) AS r_score,
    ntile(5) OVER (ORDER BY freq) AS f_score,
    ntile(5) OVER (ORDER BY monetary) AS m_score
  FROM base
)
SELECT *, (r_score + f_score + m_score) AS rfm_score FROM scores;

DROP MATERIALIZED VIEW IF EXISTS marts.mv_cohort_retention;
CREATE MATERIALIZED VIEW marts.mv_cohort_retention AS
WITH firsts AS (
  SELECT customer_id, date_trunc('month', created_at)::date AS cohort_month
  FROM core.customers
),
activity AS (
  SELECT o.customer_id, date_trunc('month', o.order_ts)::date AS act_month
  FROM core.orders o
  WHERE o.order_status IN ('paid','shipped')
),
joined AS (
  SELECT f.cohort_month, a.act_month, COUNT(DISTINCT a.customer_id) AS active
  FROM firsts f
  JOIN activity a ON a.customer_id=f.customer_id
  WHERE a.act_month BETWEEN f.cohort_month AND (f.cohort_month + INTERVAL '6 months')
  GROUP BY 1,2
),
denom AS (
  SELECT date_trunc('month', created_at)::date AS cohort_month, COUNT(*) AS cohort_size
  FROM core.customers
  GROUP BY 1
)
SELECT
  j.cohort_month,
  j.act_month,
  (j.active::numeric / d.cohort_size)::numeric(6,4) AS retention
FROM joined j
JOIN denom d ON d.cohort_month = j.cohort_month;

CREATE OR REPLACE FUNCTION marts.refresh_all() RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW marts.mv_rfm;
  REFRESH MATERIALIZED VIEW marts.mv_cohort_retention;
END;
$$ LANGUAGE plpgsql;
