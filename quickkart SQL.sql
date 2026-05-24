create database quickkart;

use quickkart;

CREATE TABLE customers(

customer_id VARCHAR(50),
signup_date DATE,
city VARCHAR(100),
state VARCHAR(100),
segment VARCHAR(50)

);

CREATE TABLE sellers(

seller_id INT,
seller_name VARCHAR(255),
primary_city VARCHAR(100),
rating FLOAT

);

CREATE TABLE products(

product_id INT,
category VARCHAR(100),
subcategory VARCHAR(100),
base_price DECIMAL(10,2)

);

CREATE TABLE orders(

order_id INT,
customer_id INT,
created_at DATETIME,
status VARCHAR(50),
payment_method VARCHAR(100),
promised_delivery_date DATETIME,
is_fast_delivery_eligible BOOLEAN

);

CREATE TABLE order_items(

order_item_id INT,
order_id INT,
product_id INT,
seller_id INT,
quantity INT,
unit_price DECIMAL(10,2),
discount_pct FLOAT,
platform_fee_pct FLOAT

);


CREATE TABLE shipments(

shipment_id INT,
order_id INT,
carrier VARCHAR(100),
shipped_at DATETIME,
delivered_at DATETIME,
ship_from_city VARCHAR(100),
ship_to_city VARCHAR(100),
shipping_cost DECIMAL(10,2),
delivery_status VARCHAR(50)

);

CREATE TABLE monthly_gmv(

month VARCHAR(7),
city VARCHAR(50),
category VARCHAR(50),
GMV BIGINT,
orders INT

);

create table monthly_orders(

month VARCHAR(7),
orders INT,
customers INT

);

create table repeat_rate(

created_at VARCHAR(7),
repeat_rate FLOAT

);

create table delay_share(

ship_to_city VARCHAR(50),
carrier VARCHAR(50),
is_delayed FLOAT

);

alter table delay_share
modify column is_delayed decimal(12,10)

alter table repeat_rate
modify column repeat_rate decimal(12,10)

LOAD DATA INFILE 'monthly_orders.csv'
INTO TABLE monthly_orders
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;


SELECT COUNT(*) FROM monthly_gmv
UNION ALL
SELECT COUNT(*) FROM monthly_orders
UNION ALL
SELECT COUNT(*) FROM repeat_rate
UNION ALL
SELECT COUNT(*) FROM delay_share;


#B1 — Monthly Marketplace Metrics

SELECT
    g.month,
    g.city,
    SUM(g.GMV)          AS total_gmv,
    SUM(g.orders)       AS total_orders,
    o.customers         AS unique_customers
FROM monthly_gmv g
JOIN monthly_orders o ON g.month = o.month
GROUP BY g.month, g.city, o.customers
ORDER BY g.month, g.city;

#B2 — Impact of First-Order Delay on Repeat Rate

SELECT
    r.created_at                        AS month,
    ROUND(r.repeat_rate * 100, 2)       AS repeat_rate_pct,
    ROUND(AVG(d.is_delayed) * 100, 2)   AS avg_delay_rate_pct
FROM repeat_rate r
CROSS JOIN delay_share d
GROUP BY r.created_at, r.repeat_rate
ORDER BY r.created_at;


#B3 — Seller–Carrier Delay Performance

SELECT
    carrier,
    ship_to_city,
    ROUND(is_delayed * 100, 2)  AS delay_rate_pct,
    CASE
        WHEN is_delayed >= 0.50 THEN 'Critical (>=50%)'
        WHEN is_delayed >= 0.30 THEN 'High (30-50%)'
        WHEN is_delayed >= 0.20 THEN 'Medium (20-30%)'
        ELSE 'Low (<20%)'
    END                         AS delay_category
FROM delay_share
ORDER BY is_delayed DESC;


#B4 — GMV and Repeat Rate by Category


-- Total GMV and orders by category across all months and cities

SELECT
    category,
    SUM(GMV)                                    AS total_gmv,
    SUM(orders)                                 AS total_orders,
    ROUND(SUM(GMV) / SUM(SUM(GMV)) OVER () * 100, 1)  AS gmv_share_pct,
    ROUND(SUM(GMV) / SUM(orders), 0)            AS avg_order_value
FROM monthly_gmv
GROUP BY category
ORDER BY total_gmv DESC;


