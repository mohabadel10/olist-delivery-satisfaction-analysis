-- =====================================================
-- Olist project | 03 - Cleaning
-- Goal: create clean views so the raw tables stay untouched
-- =====================================================
USE olist;

-- 1. orders_clean
-- Keeps only delivered orders with a delivery date, in the complete period
-- (Jan 2017 - Aug 2018). Adds delivery_days, delay_days and is_late.
-- Using "< 2018-09-01" instead of "<= 2018-08-31" so orders placed late
-- on Aug 31 (which have a time of day) are not lost.
CREATE OR REPLACE VIEW orders_clean AS
SELECT
  o.order_id,
  c.customer_unique_id,
  c.customer_state,
  o.order_purchase_timestamp,
  o.order_delivered_customer_date,
  o.order_estimated_delivery_date,
  DATEDIFF(o.order_delivered_customer_date, o.order_purchase_timestamp)      AS delivery_days,
  DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) AS delay_days,
  (o.order_delivered_customer_date > o.order_estimated_delivery_date)        AS is_late
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- Check. Result: 96,203 clean orders, 8.1% delivered late.
SELECT COUNT(*) AS clean_orders,
       ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM orders_clean;

-- 2. reviews_clean
-- Some orders have more than one review. Keep only the latest review per order.
-- ROW_NUMBER numbers the reviews inside each order (newest = 1); we keep rn = 1.
CREATE OR REPLACE VIEW reviews_clean AS
SELECT order_id, review_id, review_score, review_creation_date, review_answer_timestamp
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY order_id
           ORDER BY review_answer_timestamp DESC
         ) AS rn
  FROM order_reviews
) t
WHERE rn = 1;

-- Check. Result: 98,672 rows and 98,672 distinct orders = exactly one review per order.
-- (99,441 orders in total, so ~770 orders have no review at all.)
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT order_id) AS distinct_orders
FROM reviews_clean;

-- 3. Sanity check on delivery times
-- Result: fastest 0 days, slowest 210 days, average 12.5 days, 0 negative values.
SELECT MIN(delivery_days)           AS fastest_days,
       MAX(delivery_days)           AS slowest_days,
       ROUND(AVG(delivery_days), 1) AS average_days,
       SUM(delivery_days < 0)       AS negative_days
FROM orders_clean;

-- 4. How many extreme deliveries?
-- Result: 295 orders (0.3%) took over 60 days.
-- DECISION: kept them. They look like real service failures, not data errors,
-- and delivery problems are exactly what this project studies.
SELECT COUNT(*) AS orders_over_60_days
FROM orders_clean
WHERE delivery_days > 60;
