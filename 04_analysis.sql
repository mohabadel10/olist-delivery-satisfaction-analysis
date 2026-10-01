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

-- Finding: (add after we review the results together)
