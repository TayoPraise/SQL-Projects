SET SEARCH_PATH = pizza_runner;

--1  How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)

SELECT to_char(registration_date::date, 'ww')::int AS weeks
	   , COUNT(runner_id) "Signed up runners"
FROM runners
GROUP BY 1
ORDER BY 1;

--2 What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?

WITH pickup_diff as (
		SELECT runner_id
			   , EXTRACT(minutes FROM pickup_time - order_time) pickup_diff
		FROM cl_runner_orders ro
		JOIN cl_customer_orders co
		USING (order_id)
		WHERE pickup_time is not null
		)
		

SELECT runner_id
	   , AVG(pickup_diff)::INT AS "avg pickup time"
FROM pickup_diff
GROUP BY 1
ORDER BY 1;

--3 Is there any relationship between the number of pizzas and how long the order takes to prepare?

SELECT order_id
	   , COUNT(pizza_id) items_in_order
	   , EXTRACT(minutes FROM pickup_time - order_time) "order_pickup (mins)"
	   , (EXTRACT(minutes FROM pickup_time - order_time) / COUNT(pizza_id))::INT AS "avg_time_per_order (mins)"
FROM cl_customer_orders
JOIN cl_runner_orders
USING(order_id)
WHERE pickup_time is not null
GROUP BY 1,3
ORDER BY 2 DESC, 3 DESC;

--4 What was the average distance travelled for each customer?

SELECT customer_id
	   , ROUND(AVG(distance), 2) "average distance tavelled"
FROM cl_customer_orders co
JOIN cl_runner_orders
USING (order_id)
WHERE distance is not null
GROUP BY 1
ORDER BY 1;

--5 What was the difference between the longest and shortest delivery times for all orders?

SELECT MAX(duration) "longest delivery time"
	   , MIN(duration) "shortest delivery time"
	   , MAX(duration) - MIN(duration) "delivery time difference"
FROM cl_runner_orders;

--6 What was the average speed for each runner for each delivery and do you notice any trend for these values?

WITH duration_hr AS (
			SELECT runner_id
				   , order_id
				   , order_time
				   , distance
				   , duration
				   , ROUND(duration::numeric / 60, 2) duration_hr
			FROM cl_runner_orders
			JOIN cl_customer_orders
			USING(order_id)
			WHERE cancellation = ''
	 		)
			
	SELECT runner_id
		   , order_id
		   , order_time
		   , distance
		   , duration_hr
		   , ROUND(distance / duration_hr, 2) avg_speed
	FROM duration_hr
	GROUP BY 1, 2, 3, 4, 5
	ORDER BY 1, 3;
	
/* From the result of this query, we can see a trend in the speed of delivery 
as the runners fulfill more orders. This can be due ot better understanding of the product
or familarity of the delivery routes.
*/
	
--7 What is the successful delivery percentage for each runner?

WITH fulfilled_orders AS (
	SELECT runner_id
	   , COUNT(order_id)::numeric total_orders
	   , COUNT(CASE
	   	 WHEN cancellation = ''
		 THEN order_id
	     END) fulfilled_orders 
FROM cl_runner_orders
GROUP BY runner_id)


SELECT runner_id
	   , (fulfilled_orders / total_orders * 100)::INT  AS "%_completed"
FROM fulfilled_orders 
GROUP BY 1,2;


