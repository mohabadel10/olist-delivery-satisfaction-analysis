-- =====================================================
-- Olist project | 04 - Analysis
-- Goal: answer the business question using the clean views
-- (We add one block here for every analysis step.)
-- =====================================================
USE olist;

-- 1. Late deliveries by state
-- Which states have the highest late rate and slowest deliveries?
-- Note: check the "orders" column too, small states can give misleading percentages.
SELECT
  customer_state,
  COUNT(*)                     AS orders,
  ROUND(AVG(is_late) * 100, 1) AS late_pct,
  ROUND(AVG(delivery_days), 1) AS avg_days
FROM orders_clean
GROUP BY customer_state
ORDER BY late_pct DESC;

-- Finding: the 6 worst states by late rate are all in the Northeast (AL 24.0%, MA 19.6%,
-- PI 16.0%, CE 15.4%, SE 15.4%, BA 14.0%) versus 8.1% overall. RJ is the key high-volume
-- problem (12,310 orders, 13.5% late). SP is the best performer (5.9% late, 8.7 days).
-- States with under ~100 orders (RR, AP, AC) are too small to judge.
