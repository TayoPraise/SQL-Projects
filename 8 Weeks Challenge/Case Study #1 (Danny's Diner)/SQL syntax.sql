--------------------------------
--CASE STUDY #1: DANNY'S DINER--
--------------------------------

--Author: Temitayo Ipinlaiye
--Date: 16/12/2022 
--Tool used: PostgreSQL


CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

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
  
  
  
  
  /* --------------------
   Case Study Questions
   --------------------*/

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id AS customer
       , '$'|| SUM(price) AS total_spent 
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY 1
ORDER BY customer_id;


-- 2. How many days has each customer visited the restaurant?

SELECT customer_id customer
       , COUNT(DISTINCT order_date) AS "number of days visited"
FROM dannys_diner.sales s
GROUP BY 1;

-- 3. What was the first item from the menu purchased by each customer?

WITH order_cte AS(
		SELECT customer_id
			   , product_name
			   , price
			   , order_date
			   , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) as count
		FROM dannys_diner.sales s
		LEFT JOIN dannys_diner.menu m
		USING(product_id)
	    	GROUP BY 1,2,3,4
		ORDER BY customer_id
		)

	SELECT customer_id AS customer
	       , STRING_AGG(product_name,', ') AS first_order
	FROM order_cte
	WHERE count = 1
	GROUP BY 1;
-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT m.product_name "product name"
       , COUNT(s.product_id) "number of orders"
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
USING(product_id)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?

WITH sales_cte as(
		SELECT s.customer_id
			   , m.product_name 
			   , COUNT(product_name) volume
			   , RANK() OVER (PARTITION BY s.customer_id ORDER BY COUNT(product_name) DESC)
		FROM dannys_diner.sales s
		JOIN dannys_diner.menu m
		USING( product_id)
		GROUP BY 1,2
		ORDER BY 1
		)


SELECT customer_id AS customer
       , STRING_AGG(product_name, ', ') AS "product name"
       , volume AS "number of times ordered"
FROM sales_cte
WHERE rank = 1
GROUP BY 1,3;

-- 6. Which item was purchased first by the customer after they became a member?

WITH firstOrder_cte AS(
		SELECT *
			   , RANK() OVER (PARTITION BY customer_id ORDER BY order_date) AS RANK	
		FROM dannys_diner.members m
		JOIN dannys_diner.sales s
		USING(customer_id)
		WHERE join_date < order_date
		)

SELECT customer_id AS customer
	, join_date
	, order_date
	, STRING_AGG(product_name, ', ')
FROM firstOrder_cte
JOIN dannys_diner.menu
USING(product_id)
WHERE rank = 1
GROUP BY 1,2,3
ORDER BY 1;


-- 7. Which item was purchased just before the customer became a member?

WITH orderBefore_cte AS(
			SELECT *
				   , RANK() OVER (PARTITION BY customer_id ORDER BY order_date DESC) AS RANK	
			FROM dannys_diner.members m
			JOIN dannys_diner.sales s
			USING(customer_id)
			WHERE join_date > order_date
			)

SELECT customer_id AS customer
	, join_date
	, order_date
	, STRING_AGG(product_name, ', ')			  
FROM orderBefore_cte
JOIN dannys_diner.menu
USING(product_id)
WHERE rank = 1
GROUP BY 1,2,3
ORDER BY 1;


-- 8. What is the total items and amount spent for each member before they became a member?

SELECT s.customer_id AS customer
       , COUNT(product_id) AS "number of items"
       , SUM(price)
FROM dannys_diner.sales s
JOIN dannys_diner.members m
USING(customer_id)
JOIN dannys_diner.menu me
USING(product_id)
WHERE join_date > order_date
GROUP BY 1
ORDER BY 1;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT customer_id AS customer
       , SUM(CASE
		WHEN product_name = 'sushi' THEN price * 20
		ELSE price * 10
	 END) points
FROM dannys_diner.menu me
JOIN dannys_diner.sales s
USING(product_id)
GROUP BY 1
ORDER BY 1;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH promo_peroid AS (
		SELECT *
			   , (join_date + INTERVAL '6 days')::date as promo_date
			   , (DATE_TRUNC('month', join_date) + INTERVAL '1 month - 1 day')::date as eom
		FROM dannys_diner.members m
		)

SELECT customer_id AS customer
       , SUM(CASE
		WHEN  product_name = 'sushi'
		 THEN price * 20
		WHEN order_date BETWEEN join_date AND promo_date
		 THEN price * 20
		ELSE price * 10
	 END) points
FROM promo_peroid pp
JOIN dannys_diner.sales s
USING(customer_id)
JOIN dannys_diner.menu me
USING(product_id)
WHERE order_date <= eom
GROUP BY 1
ORDER BY 1;

-- BONUS QUESTIONS

-- 1 Create joined tables with membership status

SELECT s.customer_id
       , s.order_date
       , me.product_name
       , me.price
       , CASE 
          WHEN order_date < join_date OR join_date is null
            THEN 'N'
          ELSE 'Y'
         END member
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.members m
USING(customer_id)
LEFT JOIN dannys_diner.menu me
USING (product_id)
ORDER BY 1, 2;


-- 2. Ranking  member products

WITH memeber_status AS (
		SELECT s.customer_id
		   , s.order_date
		   , me.product_name
		   , me.price
		   , CASE 
				WHEN order_date < join_date OR join_date is null
					THEN 'N'
				ELSE 'Y'
			 END member
		FROM dannys_diner.sales s
		LEFT JOIN dannys_diner.members m
		USING(customer_id)
		LEFT JOIN dannys_diner.menu me
		USING (product_id)
		ORDER BY 1, 2
		)

SELECT *
       , CASE
	   WHEN member = 'N'
	     THEN null
	   ELSE DENSE_RANK() OVER (PARTITION BY customer_id, member ORDER BY order_date)							 
	 END ranking
FROM memeber_status ms;
