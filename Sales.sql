--- Data understanding ---
SELECT * FROM olist_customers_dataset;
SELECT * FROM olist_geolocation_dataset2;
SELECT * FROM olist_order_items_dataset;
SELECT * FROM olist_order_payments_dataset;
SELECT * FROM olist_order_reviews_dataset;
SELECT * FROM olist_orders_dataset;
SELECT * FROM olist_products_dataset;
SELECT * FROM olist_sellers_dataset;
SELECT * FROM product_category_name_translation2;


--- Sales Analysis ---

#1. Total number of sales
SELECT COUNT(order_purchase_timestamp) AS sales
FROM olist_orders_dataset
WHERE order_status = 'delivered';

#2. Total revenue
SELECT FORMAT(ROUND(SUM(items.price),2), 'C') AS sales_profit_total
FROM olist_order_items_dataset AS items
RIGHT JOIN olist_orders_dataset AS orders
ON items.order_id = orders.order_id
WHERE orders.order_status = 'delivered';

#3. The highest sales diuring the period
SELECT DISTINCT(LEFT(order_purchase_timestamp,7)) AS YearMonth, COUNT(*) AS sales
FROM olist_orders_dataset
WHERE order_status = 'delivered'
GROUP BY YearMonth
ORDER BY sales DESC
LIMIT 1;

#4. Delivery rate
SELECT no_of_delivery/order_status_total AS delivery_rate FROM
(
SELECT COUNT(*) AS no_of_delivery
FROM olist_orders_dataset
WHERE order_status = 'delivered' 
) AS sub1,
(
SELECT COUNT(order_status) AS order_status_total
FROM olist_orders_dataset
WHERE order_status IS NOT NULL OR order_status != ''
) AS sub2;

#5. Top 10 popular product categories
-- Step 1: Translate the product names in English 
SELECT Products.product_id, Products_eng_name.product_category_name_english AS product_category
FROM olist_products_dataset AS Products
LEFT JOIN product_category_name_translation2 AS Products_eng_name
ON Products.product_category_name = Products_eng_name.product_category_name
WHERE Products_eng_name.product_category_name_english IS NOT NULL;

-- Step 2: Create a temporary relation of Step 1 and merge it with the ordered items' table
WITH Pro AS
(
SELECT Products.product_id, Products_eng_name.product_category_name_english AS product_category
FROM olist_products_dataset AS Products
LEFT JOIN product_category_name_translation2 AS Products_eng_name
ON Products.product_category_name = Products_eng_name.product_category_name
WHERE Products_eng_name.product_category_name_english IS NOT NULL
)

SELECT DISTINCT(Pro.product_category) AS Category, COUNT(*) AS counts
FROM olist_order_items_dataset
LEFT JOIN Pro
ON olist_order_items_dataset.product_id = Pro.product_id
GROUP BY Category
ORDER BY counts DESC
LIMIT 10;

#6. Sales trend during the period
SELECT DISTINCT(LEFT(order_purchase_timestamp,7)) AS YearMonth, COUNT(*) AS sales
FROM olist_orders_dataset
WHERE order_status = 'delivered'
GROUP BY YearMonth
ORDER BY YearMonth;

#7. Revenue by product categories
WITH Pro AS
(
SELECT Products.product_id, Products_eng_name.product_category_name_english AS product_category
FROM olist_products_dataset AS Products
LEFT JOIN product_category_name_translation2 AS Products_eng_name
ON Products.product_category_name = Products_eng_name.product_category_name
WHERE Products_eng_name.product_category_name_english IS NOT NULL
)

SELECT DISTINCT(Pro.product_category) AS Category, ROUND(SUM(items.price),2) AS revenue_total
FROM olist_order_items_dataset AS items
LEFT JOIN Pro
ON items.product_id = Pro.product_id
RIGHT JOIN olist_orders_dataset AS orders
ON items.order_id = orders.order_id
WHERE orders.order_status = 'delivered'
GROUP BY Category
ORDER BY revenue_total DESC
LIMIT 5;