SQL E-commerce Analytics (PostgreSQL)
====================================

A mini analytics warehouse on PostgreSQL 16: realistic schema, synthetic data, materialized views (RFM, cohort retention), a daily revenue view, an inventory trigger, and showcase queries.

Quickstart (Docker)
-------------------
1) docker compose -f docker/docker-compose.yml up -d
2) Connect with psql and run:
   \i sql/01_schema_tables.sql
   \i sql/02_seed_data.sql
   \i sql/03_marts.sql
   \i sql/04_triggers_permissions.sql
   SELECT marts.refresh_all();

What’s inside
-------------
- Core: customers, orders, order_items, products, categories, payments, inventory
- Marts:
  - marts.v_order_revenue
  - marts.mv_rfm
  - marts.mv_cohort_retention
- Trigger:
  - core.decrement_inventory() + trg_inv_decrement
- Showcase queries: sql/99_queries_showcase.sql

Screenshots
-----------
Add PNGs to docs/screenshots (daily revenue MA7, top categories 30d, basket pairs, RFM leaders)

License
-------
MIT
