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



--- Customer Analysis ---

#1. Total number of customers
SELECT COUNT(DISTINCT(customer_unique_id))
FROM olist_customers_dataset;

#2. Average customers' product price, payment value, and shipping fee
SELECT 
ROUND((SUM(pay.payment_value))/96096, 2) AS Avg_Payment,
ROUND((SUM(orders.price))/96096, 2) AS Avg_Price,
ROUND((SUM(orders.freight_value))/96096, 2) AS Avg_ShippingFee
FROM olist_order_payments_dataset AS pay
INNER JOIN olist_order_items_dataset AS orders
ON pay.order_id = orders.order_id;


#3. Payment method
/* Column Payment_Type_updated is created for better visualization in Tableau*/
SELECT 
DISTINCT(payment_type) AS Payment_Type, 
COUNT(*) AS counts,
CASE 
	WHEN payment_type = 'credit_card' THEN 'Credit Card'
    WHEN payment_type = 'boleto' THEN 'Boleto'
	WHEN payment_type = 'voucher' THEN 'others'
	WHEN payment_type = 'debit_card' THEN 'others'
    WHEN payment_type = 'not_defined' THEN 'others'
END AS Payment_Type_updated
FROM olist_order_payments_dataset
GROUP BY Payment_Type
ORDER BY counts DESC;

#4. Purchase time
WITH Times AS
(
SELECT 
DISTINCT (SUBSTRING(order_purchase_timestamp, 12,2)) AS Purchase_time,
COUNT(*) AS counts
FROM olist_orders_dataset
GROUP BY Purchase_time
ORDER BY Purchase_time
)
SELECT 
CASE 
	WHEN Purchase_time = '00' THEN '12am'
    WHEN Purchase_time = '01' THEN '1am'
    WHEN Purchase_time = '02' THEN '2am'
    WHEN Purchase_time = '03' THEN '3am'
    WHEN Purchase_time = '04' THEN '4am'
    WHEN Purchase_time = '05' THEN '5am'
    WHEN Purchase_time = '06' THEN '6am'
    WHEN Purchase_time = '07' THEN '7am'
    WHEN Purchase_time = '08' THEN '8am'
    WHEN Purchase_time = '09' THEN '9am'
    WHEN Purchase_time = '10' THEN '10am'
    WHEN Purchase_time = '11' THEN '11am'
    WHEN Purchase_time = '12' THEN '12pm'
    WHEN Purchase_time = '13' THEN '1pm'
    WHEN Purchase_time = '14' THEN '2pm'
    WHEN Purchase_time = '15' THEN '3pm'
    WHEN Purchase_time = '16' THEN '4pm'
    WHEN Purchase_time = '17' THEN '5pm'
    WHEN Purchase_time = '18' THEN '6pm'
    WHEN Purchase_time = '19' THEN '7pm'
    WHEN Purchase_time = '20' THEN '8pm'
    WHEN Purchase_time = '21' THEN '9pm'
    WHEN Purchase_time = '22' THEN '10pm'
    WHEN Purchase_time = '23' THEN '11pm'
END AS Time_hour,
counts
FROM Times;

#5. Customers' review scores
SELECT AVG(review_score)
FROM olist_order_reviews_dataset;
-- In addition, find out the total scores for each product category
WITH cat_reviews AS
(
SELECT orders.product_id, Product_eng_name.product_category,reviews.review_score
FROM olist_order_items_dataset AS orders
LEFT JOIN olist_order_reviews_dataset AS reviews
ON orders.order_id = reviews.order_id
LEFT JOIN Product_eng_name
ON orders.product_id = Product_eng_name.product_id
)
SELECT DISTINCT(product_category), SUM(review_score) AS score_total
FROM cat_reviews
GROUP BY product_category
ORDER BY score_total DESC;

#6. Customers' locations
-- Group by states
SELECT DISTINCT(customer_state), COUNT(*)
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY COUNT(*) DESC;



#7. RFM analysis
-- Step 1: Recency
-- Find out the days since the last purchase (I use December 31st 2018 as the end of the period to ensure all values in recency are positive)
SELECT 
DISTINCT(customer_unique_id) AS Customer_Unique_ID, 
LEFT((MAX(orders.order_purchase_timestamp)),10) AS Last_Purchase,
DATEDIFF('2018-12-31',LEFT((MAX(orders.order_purchase_timestamp)),10)) AS Recency
FROM olist_orders_dataset AS orders
LEFT JOIN olist_customers_dataset AS customers
ON orders.customer_id = customers.customer_id
GROUP BY customer_unique_id;

-- Step 2: Frequency
SELECT DISTINCT(customer_unique_id) AS Customer_Unique_ID , COUNT(*) AS Frequency
FROM olist_customers_dataset
GROUP BY Customer_Unique_ID;

-- Step 3: Monetary
WITH PaymentByCustomer AS
(
SELECT orders.customer_id, pay.payment_value
FROM olist_orders_dataset AS orders
LEFT JOIN olist_order_payments_dataset AS pay
ON orders.order_id = pay.order_id
)
SELECT 
DISTINCT(customers.customer_unique_id) AS Customer_Unique_ID, 
SUM(PaymentByCustomer.payment_value) AS Monetary
FROM olist_customers_dataset AS customers
LEFT JOIN PaymentByCustomer
ON customers.customer_id = PaymentByCustomer.customer_id
GROUP BY Customer_Unique_ID;

-- Step 5: Join the columns
SELECT 
sub1.customer_unique_id AS Customer_Unique_ID , 
sub1.Recency, 
sub2.Frequency, 
sub3.Monetary
FROM 
(
SELECT 
DISTINCT(customer_unique_id) AS Customer_Unique_ID, 
LEFT((MAX(orders.order_purchase_timestamp)),10) AS Last_Purchase,
DATEDIFF('2018-09-01',LEFT((MAX(orders.order_purchase_timestamp)),10)) AS Recency
FROM olist_orders_dataset AS orders
LEFT JOIN olist_customers_dataset AS customers
ON orders.customer_id = customers.customer_id
GROUP BY customer_unique_id
) AS sub1
INNER JOIN 
(
SELECT DISTINCT(customer_unique_id) AS Customer_Unique_ID , COUNT(*) AS Frequency
FROM olist_customers_dataset
GROUP BY Customer_Unique_ID
) AS sub2
ON sub1.customer_unique_id = sub2.customer_unique_id
INNER JOIN
(
WITH PaymentByCustomer AS
(
SELECT orders.customer_id, pay.payment_value
FROM olist_orders_dataset AS orders
LEFT JOIN olist_order_payments_dataset AS pay
ON orders.order_id = pay.order_id
)
SELECT 
DISTINCT(customers.customer_unique_id) AS Customer_Unique_ID, 
SUM(PaymentByCustomer.payment_value) AS Monetary
FROM olist_customers_dataset AS customers
LEFT JOIN PaymentByCustomer
ON customers.customer_id = PaymentByCustomer.customer_id
GROUP BY Customer_Unique_ID
) AS sub3
ON sub2.customer_unique_id = sub3.customer_unique_id;
#For convenience sake, I created a table for the queries and named it as RFM
CREATE TABLE RFM AS
SELECT 
sub1.customer_unique_id AS Customer_Unique_ID , 
sub1.Recency, 
sub2.Frequency, 
sub3.Monetary
FROM 
(
SELECT 
DISTINCT(customer_unique_id) AS Customer_Unique_ID, 
LEFT((MAX(orders.order_purchase_timestamp)),10) AS Last_Purchase,
DATEDIFF('2018-12-31',LEFT((MAX(orders.order_purchase_timestamp)),10)) AS Recency
FROM olist_orders_dataset AS orders
LEFT JOIN olist_customers_dataset AS customers
ON orders.customer_id = customers.customer_id
GROUP BY customer_unique_id
) AS sub1
INNER JOIN 
(
SELECT DISTINCT(customer_unique_id) AS Customer_Unique_ID , COUNT(*) AS Frequency
FROM olist_customers_dataset
GROUP BY Customer_Unique_ID
) AS sub2
ON sub1.customer_unique_id = sub2.customer_unique_id
INNER JOIN
(
WITH PaymentByCustomer AS
(
SELECT orders.customer_id, pay.payment_value
FROM olist_orders_dataset AS orders
LEFT JOIN olist_order_payments_dataset AS pay
ON orders.order_id = pay.order_id
)
SELECT 
DISTINCT(customers.customer_unique_id) AS Customer_Unique_ID, 
SUM(PaymentByCustomer.payment_value) AS Monetary
FROM olist_customers_dataset AS customers
LEFT JOIN PaymentByCustomer
ON customers.customer_id = PaymentByCustomer.customer_id
GROUP BY Customer_Unique_ID
) AS sub3
ON sub2.customer_unique_id = sub3.customer_unique_id;

-- Step 6: Assign RFM score
/* As the frequency is skewed, I applied CASE() function to define the scale*/
SELECT *,
NTILE(5) OVER (ORDER BY Recency DESC) AS Recency_score,
CASE
	WHEN Frequency = 1 THEN 1
    WHEN Frequency = 2 THEN 2
    WHEN Frequency = 3 OR Frequency = 4 THEN 3
    WHEN Frequency >= 5 THEN 4
END AS Frequency_score,
NTILE(5) OVER (ORDER BY Monetary) AS Monetary_score
FROM RFM;
#For convenience sake, I created a table for the queries and named it as RFM_score
CREATE TABLE RFM_score AS
SELECT *,
NTILE(5) OVER (ORDER BY Recency DESC) AS Recency_score,
CASE
	WHEN Frequency = 1 THEN 1
    WHEN Frequency = 2 THEN 2
    WHEN Frequency = 3 OR Frequency = 4 THEN 3
    WHEN Frequency >= 5 THEN 4
END AS Frequency_score,
NTILE(5) OVER (ORDER BY Monetary) AS Monetary_score
FROM RFM;

-- Step 7: Combine the scores as a string
SELECT *, CONCAT(Recency_score, Frequency_score, Monetary_score) AS Overall_score
FROM RFM_score;
#For convenience sake, I created a table for the queries and named it as RFM_score_string
CREATE TABLE RFM_score_string AS
SELECT *, CONCAT(Recency_score, Frequency_score, Monetary_score) AS Overall_score
FROM RFM_score;

-- Step 8: Segment the overall score and define the customers
SELECT *,
CASE
	WHEN Overall_score = 444 THEN 'Best Customers'
    WHEN Overall_score LIKE '4%' THEN 'Recent Customers' 
    WHEN Overall_score LIKE '_4_' THEN 'Loyal Customers'
    WHEN Overall_score LIKE '%4' THEN 'Best Spinders'
    WHEN Overall_score LIKE 244 THEN 'Almost Lost'
    WHEN Overall_score LIKE 144 THEN 'Lost Customers'
    WHEN Overall_score LIKE 111 THEN 'Lost Cheap Customers'
    ELSE 'Others'
END AS Segment
FROM RFM_score_string;
#For convenience sake, I created a table for the queries and named it as RFM_customer_segments
CREATE TABLE RFM_customer_segments AS
SELECT *,
CASE
	WHEN Overall_score = 444 THEN 'Best Customers'
    WHEN Overall_score LIKE '4%' THEN 'Recent Customers' 
    WHEN Overall_score LIKE '_4_' THEN 'Loyal Customers'
    WHEN Overall_score LIKE '%4' THEN 'Best Spinders'
    WHEN Overall_score LIKE 244 THEN 'Almost Lost'
    WHEN Overall_score LIKE 144 THEN 'Lost Customers'
    WHEN Overall_score LIKE 111 THEN 'Lost Cheap Customers'
    ELSE 'Others'
END AS Segment
FROM RFM_score_string;

-- Step 9: Find out the numebr of customers in each segment
SELECT DISTINCT(Segment), COUNT(*)
FROM RFM_customer_segments
GROUP BY Segment
ORDER BY COUNT(*) DESC;


