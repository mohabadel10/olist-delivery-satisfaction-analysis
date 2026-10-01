-- =====================================================
-- Olist project | 03 - Cleaning
-- Goal: create clean views so the raw tables stay untouched
-- =====================================================
USE olist;

-- 1. orders_clean
-- Keeps only delivered orders with a delivery date, in the complete period
-- (Jan 2017 - Aug 2018). Adds delivery_days, delay_days and is_late.
-- "< 2018-09-01" is used instead of "<= 2018-08-31" so orders placed late
-- on Aug 31 (which carry a time of day) are not lost.
--
-- is_late FIX: the first version compared date AND time
-- (delivered > estimated), which flagged orders delivered on the promised day
-- as late, because the estimated date is stored at midnight.
-- 1,291 orders were affected. The fix compares whole calendar days
-- (DATEDIFF > 0). Late orders changed from 7,822 (8.1%) to 6,531 (6.8%).
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
  (DATEDIFF(o.order_delivered_customer_date, o.order_estimated_delivery_date) > 0) AS is_late
FROM orders o
JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
  AND o.order_delivered_customer_date IS NOT NULL
  AND o.order_purchase_timestamp >= '2017-01-01'
  AND o.order_purchase_timestamp <  '2018-09-01';

-- Check. Result: 96,203 clean orders | 6,531 late | 89,672 on time | 6.8% late
SELECT COUNT(*)                   AS total_orders,
       SUM(is_late)               AS late_orders,
       COUNT(*) - SUM(is_late)    AS on_time_orders,
       ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM orders_clean;

-- Validation of the fix: orders flagged late but delivered on or before the
-- promised calendar day. Expected result: 0 (it was 1,291 with the old definition).
SELECT COUNT(*) AS suspicious_orders
FROM orders_clean
WHERE is_late = 1 AND delay_days <= 0;

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
-- DECISION: kept. They look like real service failures, not data errors,
-- and delivery problems are exactly what this project studies.
SELECT COUNT(*) AS orders_over_60_days
FROM orders_clean
WHERE delivery_days > 60;

-- 5. Product categories: NULL vs empty text
-- Result: 0 NULL categories, 610 empty-text categories (of 32,951 products).
-- COALESCE skips NULL but not '', so analysis queries use
-- NULLIF(product_category_name, '') to turn blanks into NULL
-- and label them 'unknown'. The raw table is not changed.
SELECT SUM(product_category_name IS NULL) AS null_category,
       SUM(product_category_name = '')    AS empty_category,
       COUNT(*)                           AS total_products
FROM products;
