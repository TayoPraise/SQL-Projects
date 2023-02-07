SET SEARCH_PATH = pizza_runner;


-- 1. How many pizzas were ordered?

SELECT COUNT(pizza_id) "Number of pizzas ordered"
FROM cl_customer_orders;

-- 2. How many unique customer orders were made?

SELECT COUNT(DISTINCT order_id) "Number of unique order"
FROM cl_customer_orders;

-- 3. How many successful orders were delivered by each runner?

SELECT runner_id
	   , COUNT(order_id) "Numbers of orders delivered"
FROM cl_runner_orders
WHERE cancellation = ''
GROUP BY 1;

-- 4. How many of each type of pizza was delivered?

WITH delivery AS (
      SELECT order_id
           , cancellation
      FROM cl_runner_orders
      WHERE cancellation = ''
      )

SELECT pizza_name
	   , COUNT(pizza_id) "Number of pizzas delivered"
FROM delivery
JOIN cl_customer_orders co
USING(order_id)
JOIN pizza_names pn
USING(pizza_id)
GROUP BY 1
ORDER BY 1;

-- 5. How many Vegetarian and Meatlovers were ordered by each customer?

SELECT customer_id
   , pizza_name
   , count(pizza_id) "number of pizzas ordered"
FROM cl_customer_orders
JOIN pizza_names
USING(pizza_id)
GROUP BY 1, 2
ORDER BY 1;

-- 6. What was the maximum number of pizzas delivered in a single order?

WITH pizza_count AS (
		SELECT order_id
			  , Count(pizza_id) "pizza_count"
		FROM cl_runner_orders
		JOIN cl_customer_orders
		USING(order_id)
		WHERE cancellation = ''
		GROUP BY 1
	     )	 
	
	SELECT MAX(pizza_count)"max pizzas delivered in a single order"
	FROM pizza_count;

-- 7. For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

SELECT customer_id
	   , SUM(CASE WHEN exclusions <> '' OR extras <> ''
				THEN 1 ELSE 0
			 END) "order with changes"
	   , SUM(CASE WHEN exclusions = '' AND extras = ''
				THEN 1 ELSE 0
			 END) "orders without changes"
FROM cl_customer_orders
JOIN cl_runner_orders
USING (order_id)
WHERE cancellation = ''
GROUP BY 1
ORDER BY 1;

-- 8. How many pizzas were delivered that had both exclusions and extras?

SELECT SUM(CASE WHEN exclusions <> '' AND extras <> ''
			THEN 1 ELSE 0
		 END) "order with both exclusions & extra"
FROM cl_customer_orders
JOIN cl_runner_orders
USING (order_id)
WHERE cancellation = '';

-- 9. What was the total volume of pizzas ordered for each hour of the day?

SELECT EXTRACT(HOURS FROM order_time) hours
	 , COUNT(order_id) "pizza ordered"
FROM cl_customer_orders
GROUP BY 1
ORDER BY 1;

-- 10. What was the volume of orders for each day of the week?

SELECT to_char(order_time, 'DAY')
	 , COUNT(order_id) "pizza ordered"
FROM cl_customer_orders
GROUP BY 1
ORDER BY 2 DESC;
