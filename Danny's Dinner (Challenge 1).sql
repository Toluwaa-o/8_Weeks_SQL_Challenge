-- Setting up tables
CREATE TABLE sales (
  "customer_id" VARCHAR(1),
  "order_date" DATE,
  "product_id" INTEGER
);

INSERT INTO sales
  ("customer_id", "order_date", "product_id")
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  "product_id" INTEGER,
  "product_name" VARCHAR(5),
  "price" INTEGER
);

INSERT INTO menu
  ("product_id", "product_name", "price")
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  "customer_id" VARCHAR(1),
  "join_date" DATE
);

INSERT INTO members
  ("customer_id", "join_date")
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');

--What is the total amount each customer spent at the restaurant?
SELECT customer_id, SUM(price) AS Amount_Spent
FROM sales sal
JOIN menu men
ON sal.product_id = men.product_id
GROUP BY customer_id
ORDER BY Amount_Spent DESC



--How many days has each customer visited the restaurant?
SELECT customer_id, COUNT(DISTINCT order_date) AS Visit_days
FROM sales sal
JOIN menu men
ON sal.product_id = men.product_id
GROUP BY customer_id
ORDER BY Visit_days DESC



--What was the first item from the menu purchased by each customer?
SELECT customer_id, order_date AS Date, product_name
FROM (
    SELECT
        customer_id,
        order_date,
        product_name,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS row_num
    FROM sales sal
    JOIN menu men ON sal.product_id = men.product_id
) AS ranked
WHERE row_num = 1;



--What is the most purchased item on the menu and how many times was it purchased by all customers?

--Items ranked based on how many times they have been bought:
SELECT product_name, COUNT(product_name) AS Amt
FROM sales sal
JOIN menu men ON sal.product_id = men.product_id
GROUP BY product_name
ORDER BY Amt DESC

--How many times has each customer bought the most purchased item?
WITH ProdCount as (
SELECT product_name, COUNT(product_name) AS Amt
FROM sales sal
JOIN menu men ON sal.product_id = men.product_id
GROUP BY product_name
)

SELECT customer_id, COUNT(men.product_name) as Ord_Amt
FROM sales sal
JOIN menu men ON sal.product_id = men.product_id
JOIN ProdCount prod on men.product_name = prod.product_name
WHERE men.product_name = (
SELECT product_name
FROM ProdCount
WHERE Amt = (
SELECT MAX(Amt)
FROM ProdCount))
GROUP BY customer_id



--Which item was the most popular for each customer?
WITH ProdAmounts AS (
SELECT COUNT(product_id) as Amt, customer_id, product_id
FROM sales
GROUP BY customer_id, product_id
)

SELECT prod.customer_id, TimesPurchased, product_name
FROM ProdAmounts prod
RIGHT JOIN (SELECT customer_id, MAX(Amt) AS TimesPurchased
FROM ProdAmounts
GROUP BY customer_id) Tbl
ON prod.Amt = Tbl.TimesPurchased AND prod.customer_id = Tbl.customer_id
JOIN menu men ON prod.product_id = men.product_id



--Which item was purchased first by the customer after they became a member?
WITH FirstDateTable AS (
SELECT order_date, sal.customer_id, product_name
FROM sales sal
JOIN members mem ON sal.customer_id = mem.customer_id
JOIN menu men ON sal.product_id = men.product_id
WHERE order_date > join_date
)

SELECT sal.customer_id, subTable.order_date, product_name
FROM sales sal
JOIN (
SELECT customer_id, MIN(order_date) as order_date
FROM FirstDateTable
GROUP BY customer_id
) subTable ON sal.order_date = subTable.order_date AND sal.customer_id = subTable.customer_id
JOIN menu men ON sal.product_id = men.product_id



--Which item was purchased just before the customer became a member?

WITH LasDateTable AS (
SELECT order_date, sal.customer_id, product_name
FROM sales sal
JOIN members mem ON sal.customer_id = mem.customer_id
JOIN menu men ON sal.product_id = men.product_id
WHERE join_date >= order_date
)

SELECT sal.customer_id, subTable.order_date, product_name
FROM sales sal
JOIN (
SELECT customer_id, MAX(order_date) as order_date
FROM LasDateTable
GROUP BY customer_id
) subTable ON sal.order_date = subTable.order_date AND sal.customer_id = subTable.customer_id
JOIN menu men ON sal.product_id = men.product_id



--What is the total items and amount spent for each member before they became a member?
WITH Total_tbl AS (
	SELECT order_date, sal.customer_id, price
	FROM sales sal
		JOIN members mem ON sal.customer_id = mem.customer_id
		JOIN menu men ON sal.product_id = men.product_id
	WHERE join_date >= order_date
)

SELECT SUM(price) as Spent, COUNT(customer_id) as Amount, customer_id
FROM Total_tbl
GROUP BY customer_id



--If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CalcTable AS (
SELECT sal.product_id, customer_id, product_name, price,
		CASE product_name
			WHEN 'sushi' THEN price*20
			ELSE price*10
		END as CalcPoints
FROM sales sal
JOIN menu men ON sal.product_id = men.product_id
)

SELECT customer_id, SUM(CalcPoints) as TotalPoints
FROM CalcTable
GROUP BY customer_id



--In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
WITH Points_Table AS (
SELECT sal.customer_id, 
		CASE
			WHEN order_date <= DATEADD(DAY, 7, order_date) THEN price*20
			ELSE price
		END as Points
FROM sales sal
JOIN members mem ON sal.customer_id = mem.customer_id
JOIN menu men ON sal.product_id = men.product_id
WHERE order_date >= join_date AND order_date < '2021-02-01'
)

SELECT customer_id, SUM(Points) as TotalPoints
FROM Points_Table
GROUP BY customer_id