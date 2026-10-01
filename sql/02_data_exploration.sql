-- =====================================================
-- Olist project | 02 - Data exploration
-- Goal: understand the data and find problems BEFORE analysis
-- =====================================================
USE olist;

-- 1. Which order statuses exist?
-- Finding: 96,478 of 99,441 orders (~97%) are 'delivered'.
-- The rest (canceled, unavailable, shipped, invoiced, processing, created, approved)
-- never completed, so they are excluded from delivery analysis.
SELECT order_status, COUNT(*) AS n
FROM orders
GROUP BY order_status
ORDER BY n DESC;

-- 2. Orders per month (to find incomplete months)
-- Finding: data is only complete from Jan 2017 to Aug 2018.
-- 2016 has tiny numbers (Nov 2016 is missing) and Sep/Oct 2018 have only 16 and 4 orders.
-- Nov 2017 spikes to 7,544 orders (likely Black Friday).
SELECT DATE_FORMAT(order_purchase_timestamp, '%Y-%m') AS month,
       COUNT(*) AS orders
FROM orders
GROUP BY month
ORDER BY month;

-- 3. Missing delivery dates by status
-- Finding: all non-delivered statuses have no delivery date (expected).
-- Bad records: 8 'delivered' orders have no delivery date,
-- and 6 'canceled' orders DO have a delivery date.
SELECT order_status,
       SUM(order_delivered_customer_date IS NULL) AS missing_delivery_date,
       COUNT(*) AS total
FROM orders
GROUP BY order_status;

-- 4. Customer IDs vs. unique people
-- Finding: 99,441 customer_ids but only 96,096 unique people.
-- customer_id is created per order, so people must be counted with customer_unique_id.
-- It also shows that very few customers ever bought again.
SELECT COUNT(*) AS customer_ids,
       COUNT(DISTINCT customer_unique_id) AS unique_people
FROM customers;

-- 5. Orders with more than one review
-- Finding: 547 orders have multiple reviews. Joining reviews directly would count
-- these orders twice, so only one review per order is kept (see 03_cleaning.sql).
SELECT COUNT(*) AS orders_with_multiple_reviews
FROM (
  SELECT order_id
  FROM order_reviews
  GROUP BY order_id
  HAVING COUNT(*) > 1
) t;
