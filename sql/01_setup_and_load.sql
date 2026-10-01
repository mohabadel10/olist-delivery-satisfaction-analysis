-- =====================================================
-- Olist project | 01 - Setup and load
-- Goal: create the database and bulk-load the Kaggle CSV files
-- Dataset: https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce
--
-- BEFORE RUNNING: replace C:/olist/ with the folder where you saved the CSVs
-- (use forward slashes and keep the trailing slash).
-- Requires local_infile enabled on the server and in the Workbench connection
-- (Edit Connection > Advanced > Others: OPT_LOCAL_INFILE=1).
-- The geolocation file is not used in this project.
-- =====================================================

SET GLOBAL local_infile = 1;

DROP DATABASE IF EXISTS olist;
CREATE DATABASE olist CHARACTER SET utf8mb4;
USE olist;

-- ---------- TABLES ----------
CREATE TABLE customers (
  customer_id              VARCHAR(50) NOT NULL,
  customer_unique_id       VARCHAR(50),
  customer_zip_code_prefix VARCHAR(10),
  customer_city            VARCHAR(100),
  customer_state           CHAR(2),
  PRIMARY KEY (customer_id)
);

CREATE TABLE orders (
  order_id                      VARCHAR(50) NOT NULL,
  customer_id                   VARCHAR(50),
  order_status                  VARCHAR(20),
  order_purchase_timestamp      DATETIME,
  order_approved_at             DATETIME,
  order_delivered_carrier_date  DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME,
  PRIMARY KEY (order_id)
);

CREATE TABLE order_items (
  order_id            VARCHAR(50) NOT NULL,
  order_item_id       INT NOT NULL,
  product_id          VARCHAR(50),
  seller_id           VARCHAR(50),
  shipping_limit_date DATETIME,
  price               DECIMAL(10,2),
  freight_value       DECIMAL(10,2),
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
  order_id             VARCHAR(50) NOT NULL,
  payment_sequential   INT NOT NULL,
  payment_type         VARCHAR(30),
  payment_installments INT,
  payment_value        DECIMAL(10,2),
  PRIMARY KEY (order_id, payment_sequential)
);

-- review_id is NOT unique in this dataset, so there is no primary key here
CREATE TABLE order_reviews (
  review_id               VARCHAR(50),
  order_id                VARCHAR(50),
  review_score            INT,
  review_comment_title    TEXT,
  review_comment_message  TEXT,
  review_creation_date    DATETIME,
  review_answer_timestamp DATETIME
);

CREATE TABLE products (
  product_id                 VARCHAR(50) NOT NULL,
  product_category_name      VARCHAR(100),
  product_name_lenght        INT,
  product_description_lenght INT,
  product_photos_qty         INT,
  product_weight_g           INT,
  product_length_cm          INT,
  product_height_cm          INT,
  product_width_cm           INT,
  PRIMARY KEY (product_id)
);

CREATE TABLE sellers (
  seller_id              VARCHAR(50) NOT NULL,
  seller_zip_code_prefix VARCHAR(10),
  seller_city            VARCHAR(100),
  seller_state           CHAR(2),
  PRIMARY KEY (seller_id)
);

CREATE TABLE category_translation (
  product_category_name         VARCHAR(100) NOT NULL,
  product_category_name_english VARCHAR(100),
  PRIMARY KEY (product_category_name)
);

-- ---------- LOAD DATA ----------
-- NULLIF turns empty cells into NULL for date and number columns.
LOAD DATA LOCAL INFILE 'C:/olist/olist_customers_dataset.csv'
INTO TABLE customers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/olist_orders_dataset.csv'
INTO TABLE orders CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(order_id, customer_id, order_status, @purchase, @approved, @carrier, @delivered, @estimated)
SET order_purchase_timestamp      = NULLIF(@purchase, ''),
    order_approved_at             = NULLIF(@approved, ''),
    order_delivered_carrier_date  = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@delivered, ''),
    order_estimated_delivery_date = NULLIF(@estimated, '');

LOAD DATA LOCAL INFILE 'C:/olist/olist_order_items_dataset.csv'
INTO TABLE order_items CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/olist_order_payments_dataset.csv'
INTO TABLE order_payments CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/olist_products_dataset.csv'
INTO TABLE products CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES
(product_id, product_category_name, @nl, @dl, @ph, @w, @l, @h, @wd)
SET product_name_lenght        = NULLIF(@nl, ''),
    product_description_lenght = NULLIF(@dl, ''),
    product_photos_qty         = NULLIF(@ph, ''),
    product_weight_g           = NULLIF(@w, ''),
    product_length_cm          = NULLIF(@l, ''),
    product_height_cm          = NULLIF(@h, ''),
    product_width_cm           = NULLIF(@wd, '');

LOAD DATA LOCAL INFILE 'C:/olist/olist_sellers_dataset.csv'
INTO TABLE sellers CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

LOAD DATA LOCAL INFILE 'C:/olist/product_category_name_translation.csv'
INTO TABLE category_translation CHARACTER SET utf8mb4
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n' IGNORE 1 LINES;

-- ---------- VERIFY ----------
-- Expected: customers 99,441 | orders 99,441 | order_items 112,650 | order_payments 103,886
--           order_reviews 99,223 | products 32,951 | sellers 3,095 | category_translation 71
SELECT 'customers' AS tbl, COUNT(*) AS n FROM customers
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments
UNION ALL SELECT 'order_reviews', COUNT(*) FROM order_reviews
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'sellers', COUNT(*) FROM sellers
UNION ALL SELECT 'category_translation', COUNT(*) FROM category_translation;
