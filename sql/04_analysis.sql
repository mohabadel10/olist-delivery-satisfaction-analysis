-- =====================================================
-- Olist project | 04 - Analysis
-- Goal: answer the business question using the clean views:
-- where are deliveries late, does it hurt satisfaction, and what should be done?
-- All results use orders_clean (Jan 2017 - Aug 2018, delivered orders only).
-- Lateness = delivered on a later calendar day than the estimated date.
-- =====================================================
USE olist;

-- 1. Overall summary
-- Finding: 96,203 delivered orders, 6,531 late (6.8%), 89,672 on time.
SELECT COUNT(*)                     AS total_orders,
       SUM(is_late)                 AS late_orders,
       COUNT(*) - SUM(is_late)      AS on_time_orders,
       ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM orders_clean;

-- 2. Late deliveries by customer state
-- Finding: the top 5 states by number of late orders (SP 1,817, RJ 1,495, MG 519,
-- BA 396, RS 325) make up ~70% of all late orders; SP and RJ alone ~51%.
-- SP has many late orders only because of volume (4.5% late, 8.7 days average).
-- RJ is the main problem: 12,310 orders, 12.1% late, 15.2 days average.
-- The Northeast has the highest rates: AL 21.5%, MA 17.5%, SE 15.4%, PI 13.9%,
-- CE 13.8%, BA 12.2%.
-- States with under ~100 orders (RR, AP, AC) are too small to judge.
SELECT
  customer_state,
  COUNT(*)                     AS orders,
  SUM(is_late)                 AS late_orders,
  ROUND(AVG(is_late) * 100, 1) AS late_pct,
  ROUND(AVG(delivery_days), 1) AS avg_days
FROM orders_clean
GROUP BY customer_state
ORDER BY late_orders DESC;

-- 3. Do late deliveries hurt review scores?
-- Finding: on-time orders average 4.29 stars (89,181 orders, 9.2% gave 1-2 stars);
-- late orders average 2.27 stars (6,378 orders, 62.4% gave 1-2 stars).
-- Only orders with a review are included (95,559). This is an association,
-- not proof that lateness is the only cause of low ratings.
SELECT
  o.is_late,
  COUNT(*)                               AS orders,
  ROUND(AVG(r.review_score), 2)          AS avg_review_score,
  ROUND(AVG(r.review_score <= 2) * 100, 1) AS unhappy_pct
FROM orders_clean o
JOIN reviews_clean r ON r.order_id = o.order_id
GROUP BY o.is_late;

-- 4. Review score by how late the order was
-- Finding: the later the order, the lower the rating:
-- on time 4.29 | 1-3 days late 3.29 | 4-7 days late 2.10 | 8+ days late 1.70.
-- The 8+ days group is the largest late group (2,779 orders).
SELECT
  CASE
    WHEN o.delay_days <= 0 THEN '1. On time'
    WHEN o.delay_days BETWEEN 1 AND 3 THEN '2. 1-3 days late'
    WHEN o.delay_days BETWEEN 4 AND 7 THEN '3. 4-7 days late'
    ELSE '4. 8+ days late'
  END AS delay_group,
  COUNT(*)                      AS orders,
  ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM orders_clean o
JOIN reviews_clean r ON r.order_id = o.order_id
GROUP BY delay_group
ORDER BY delay_group;

-- 5. Sellers with the highest late rate (sellers with at least 100 orders)
-- Finding: the worst seller is 19.0% late (74 of 389 orders); the 15 worst sellers
-- are 12.4%-19.0% late, versus 6.8% overall. Together they account for only ~430 late
-- orders (~6.6% of all 6,531), so lateness is spread across many sellers
-- and fixing a few sellers would not solve it.
-- COUNT(DISTINCT order_id) is used because an order can have several items.
SELECT
  oi.seller_id,
  COUNT(DISTINCT o.order_id) AS orders,
  COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_orders,
  ROUND(
    COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) * 100.0
    / COUNT(DISTINCT o.order_id), 1
  ) AS late_pct
FROM orders_clean o
JOIN order_items oi ON oi.order_id = o.order_id
GROUP BY oi.seller_id
HAVING orders >= 100
ORDER BY late_pct DESC
LIMIT 15;

-- 6. Same state vs. different state (seller vs. customer)
-- Finding: different-state orders are late 8.1% (4,969 of 61,714) vs. 4.5% for
-- same-state (1,563 of 34,735). Different-state orders produce ~76% of all late orders.
-- The two order counts add up to 96,449 (246 more than 96,203) because orders with
-- sellers in both groups appear in both.
-- Caution: "same state" is mostly SP to SP, so this also reflects SP's strong logistics.
SELECT
  CASE
    WHEN s.seller_state = o.customer_state THEN 'Same state'
    ELSE 'Different state'
  END AS shipping_type,
  COUNT(DISTINCT o.order_id) AS orders,
  COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_orders,
  ROUND(
    COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) * 100.0
    / COUNT(DISTINCT o.order_id), 1
  ) AS late_pct
FROM orders_clean o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN sellers s ON s.seller_id = oi.seller_id
GROUP BY shipping_type;

-- 7. Worst routes (seller state to customer state), routes with 300+ orders
-- Finding: SP to SP has the most late orders (1,427) only because of volume (4.6% late).
-- SP to RJ is the main problem route: 8,171 orders, 1,152 late, 14.1% late,
-- almost 3x SP to MG (7,450 orders, 5.3% late) although both neighbor SP.
-- Other routes into RJ are also high (PR to RJ 12.0%, MG to RJ 8.2%),
-- which points to the destination, not the seller.
-- Long-distance routes are high too (SP to MA 19.2%, SP to CE 13.8%, SP to BA 12.9%).
SELECT
  s.seller_state,
  o.customer_state,
  COUNT(DISTINCT o.order_id) AS orders,
  COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) AS late_orders,
  ROUND(
    COUNT(DISTINCT CASE WHEN o.is_late = 1 THEN o.order_id END) * 100.0
    / COUNT(DISTINCT o.order_id), 1
  ) AS late_pct
FROM orders_clean o
JOIN order_items oi ON oi.order_id = o.order_id
JOIN sellers s ON s.seller_id = oi.seller_id
GROUP BY s.seller_state, o.customer_state
HAVING orders >= 300
ORDER BY late_orders DESC
LIMIT 15;

-- 8. Is RJ slow, or is the promise too tight? (orders from SP sellers)
-- Finding: RJ takes 16.2 days on average vs. 12.3 for MG (4 days slower), but is
-- promised only 27.0 days vs. 24.9 for MG (2.1 days more). Compared with RS,
-- RJ has the same real time (16.2 vs 16.1 days) but a shorter promise (27.0 vs 30.3),
-- and a late rate of 14.1% vs 6.6%. Deliveries into RJ are slower than neighbouring
-- MG and the promised time is tight relative to RS; this data cannot say which matters more.
WITH sp_orders AS (
  SELECT DISTINCT
    o.order_id,
    o.customer_state,
    o.delivery_days,
    DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp) AS promised_days,
    o.is_late
  FROM orders_clean o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN sellers s ON s.seller_id = oi.seller_id
  WHERE s.seller_state = 'SP'
)
SELECT
  customer_state,
  COUNT(*)                     AS orders,
  ROUND(AVG(promised_days), 1) AS avg_promised_days,
  ROUND(AVG(delivery_days), 1) AS avg_actual_days,
  ROUND(AVG(is_late) * 100, 1) AS late_pct
FROM sp_orders
GROUP BY customer_state
HAVING orders >= 300
ORDER BY late_pct DESC;

-- 9. Late rate and reviews by product category (categories with 500+ orders)
-- Finding: category is a weak driver of lateness: the 10 highest late rates are only
-- 7.3%-8.1% vs. 6.8% overall. By volume, the biggest categories (bed_bath_table 689 late,
-- health_beauty 647, sports_leisure 495) have ordinary late rates of 6.6%-7.5%.
-- office_furniture has the lowest review average (3.65) with 8.1% late.
-- 'unknown' (1,390 orders) are products with no category.
-- An order with items in two categories is counted once in each,
-- so category counts do not add up to the total.
WITH order_categories AS (
  SELECT DISTINCT
    o.order_id,
    COALESCE(t.product_category_name_english, NULLIF(p.product_category_name, ''), 'unknown') AS category,
    o.is_late,
    r.review_score
  FROM orders_clean o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN products p ON p.product_id = oi.product_id
  LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name
  LEFT JOIN reviews_clean r ON r.order_id = o.order_id
)
SELECT
  category,
  COUNT(*)                     AS orders,
  SUM(is_late)                 AS late_orders,
  ROUND(AVG(is_late) * 100, 1) AS late_pct,
  ROUND(AVG(review_score), 2)  AS avg_review_score
FROM order_categories
GROUP BY category
HAVING orders >= 500
ORDER BY late_pct DESC
LIMIT 10;

-- 10. Dataset for Power BI (one row per order)
-- seller_state and category come from the FIRST item of each order (order_item_id = 1);
-- for multi-item orders this is an approximation.
-- All joins are LEFT JOINs so no order is dropped.
CREATE OR REPLACE VIEW powerbi_orders AS
SELECT
  o.order_id,
  o.customer_unique_id,
  o.customer_state,
  DATE(o.order_purchase_timestamp)                  AS purchase_date,
  DATE_FORMAT(o.order_purchase_timestamp, '%Y-%m')  AS purchase_month,
  o.delivery_days,
  DATEDIFF(o.order_estimated_delivery_date, o.order_purchase_timestamp) AS promised_days,
  o.delay_days,
  o.is_late,
  CASE
    WHEN o.delay_days <= 0 THEN '1. On time'
    WHEN o.delay_days BETWEEN 1 AND 3 THEN '2. 1-3 days late'
    WHEN o.delay_days BETWEEN 4 AND 7 THEN '3. 4-7 days late'
    ELSE '4. 8+ days late'
  END AS delay_group,
  r.review_score,
  it.items,
  it.revenue,
  it.freight,
  s.seller_state,
  CASE
    WHEN s.seller_state IS NULL THEN 'Unknown'
    WHEN s.seller_state = o.customer_state THEN 'Same state'
    ELSE 'Different state'
  END AS shipping_type,
  COALESCE(t.product_category_name_english, NULLIF(p.product_category_name, ''), 'unknown') AS category
FROM orders_clean o
LEFT JOIN reviews_clean r ON r.order_id = o.order_id
LEFT JOIN (
  SELECT order_id,
         COUNT(*)           AS items,
         SUM(price)         AS revenue,
         SUM(freight_value) AS freight
  FROM order_items
  GROUP BY order_id
) it ON it.order_id = o.order_id
LEFT JOIN order_items oi1 ON oi1.order_id = o.order_id AND oi1.order_item_id = 1
LEFT JOIN sellers s ON s.seller_id = oi1.seller_id
LEFT JOIN products p ON p.product_id = oi1.product_id
LEFT JOIN category_translation t ON t.product_category_name = p.product_category_name;

-- Check. Result: 96,203 rows, 96,203 distinct orders, 6,531 late orders
-- (one row per order, matches orders_clean).
SELECT COUNT(*)                 AS total_rows,
       COUNT(DISTINCT order_id) AS distinct_orders,
       SUM(is_late)             AS late_orders
FROM powerbi_orders;

-- 11. Late rate by purchase month
-- Finding: late rate is ~3-7% in most months, with three spikes: Nov 2017 (12.4%),
-- Feb 2018 (14.1%) and Mar 2018 (19.0%). These 3 months hold 3,158 late orders (~48% of all
-- 6,531) while containing 20,846 orders (~22% of 96,203).
-- Nov 2017: average delivery time rose from 11.7 to 15.1 days while the promise stayed
-- about the same (23.7 vs 23.2 days), and volume peaked (7,288 orders).
-- Dec 2017: the promise was lengthened to 28.3 days and the late rate fell to 7.5%.
-- Feb-Mar 2018: slowest deliveries (16.9 and 16.2 days) without higher volume than Jan;
-- Mar 2018 also had the shortest promise (22.7 days). April 2018 recovers to 4.5%.
-- Caution: only delivered orders are included, so Jun-Aug 2018 may look better than they were.
SELECT
  purchase_month,
  COUNT(*)                     AS orders,
  SUM(is_late)                 AS late_orders,
  ROUND(AVG(is_late) * 100, 1) AS late_pct,
  ROUND(AVG(delivery_days), 1) AS avg_days,
  ROUND(AVG(promised_days), 1) AS avg_promised_days
FROM powerbi_orders
GROUP BY purchase_month
ORDER BY purchase_month;

-- 12. Late rate by state: spike months vs. other months (states with 500+ orders)
-- Spike months = Nov 2017, Feb 2018, Mar 2018 (chosen because they had the highest late
-- rates, so a gap versus other months is expected by construction).
-- Finding: every state is worse in the spike months (SP 7.9% vs 3.6%, MG 12.0% vs 2.4%,
-- RJ 31.2% vs 6.6%), so the spikes were a system-wide shock.
-- In the other months the Northeast is still higher: PB 9.9%, MA 9.7%, BA 9.6%, PE 8.3%
-- versus MG 2.4%, PR 2.3%, DF 3.3%, RS 3.5%, SP 3.6%.
-- AL, SE and PI are not shown (under 500 orders).
SELECT
  customer_state,
  COUNT(*) AS orders,
  ROUND(AVG(CASE WHEN purchase_month IN ('2017-11','2018-02','2018-03')
                 THEN is_late END) * 100, 1) AS late_pct_spike_months,
  ROUND(AVG(CASE WHEN purchase_month NOT IN ('2017-11','2018-02','2018-03')
                 THEN is_late END) * 100, 1) AS late_pct_other_months
FROM powerbi_orders
GROUP BY customer_state
HAVING orders >= 500
ORDER BY orders DESC;

-- 13. Share of each state's late orders that fall in the spike months
-- Finding: overall ~48%. RJ 57.5% (860 of 1,495), MG 59.2%, CE 60.8%, PR 55.8%, RS 54.8%.
-- BA 37.9%, SP 37.1% and PE 33.3% are below average: their lateness is spread across
-- all months, which fits a structural (not peak-season) problem.
SELECT
  customer_state,
  SUM(is_late) AS late_orders,
  SUM(CASE WHEN purchase_month IN ('2017-11','2018-02','2018-03')
           THEN is_late ELSE 0 END) AS late_in_spike_months,
  ROUND(
    SUM(CASE WHEN purchase_month IN ('2017-11','2018-02','2018-03')
             THEN is_late ELSE 0 END) * 100.0 / SUM(is_late), 1
  ) AS pct_of_late_in_spike
FROM powerbi_orders
GROUP BY customer_state
ORDER BY late_orders DESC
LIMIT 10;
