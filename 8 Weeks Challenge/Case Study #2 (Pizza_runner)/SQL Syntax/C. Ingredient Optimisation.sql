SET SEARCH_PATH = pizza_runner;

-- 1. What are the standard ingredients for each pizza?

WITH toppings AS (
	SELECT pizza_id
       , string_to_table(toppings, ', ')::INT topping_id
	FROM pizza_recipes),
	
	topping_name AS(
		SELECT pizza_id
		   , topping_id
		   , topping_name
	FROM toppings
	JOIN pizza_toppings
	USING(topping_id)
    ORDER BY 1,2)
	
	SELECT pizza_name
	       , STRING_AGG(topping_name, ', ') ingredients
	FROM topping_name
	JOIN pizza_names
	USING(pizza_id)
	GROUP BY 1;
    
-- 2. What was the most commonly added extra?

WITH split_extras AS (
			SELECT *
				   , STRING_TO_TABLE(extras, ',')::INT topping_id
			FROM cl_customer_orders
			WHERE extras != '')
		
SELECT topping_id
	   , topping_name
	   , COUNT(topping_id) count_extra
FROM split_extras
JOIN pizza_toppings
USING(topping_id)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1;

-- 3. What was the most common exclusion?

SELECT topping_id
	   , topping_name
	   , COUNT(topping_id) count_exclusions
FROM (
	SELECT *
	   , STRING_TO_TABLE(exclusions, ',')::INT topping_id
	FROM cl_customer_orders
	WHERE exclusions != ''
	) split_exclusions
	
JOIN pizza_toppings
USING(topping_id)
GROUP BY 1,2
ORDER BY 3 DESC
LIMIT 1;

-- 4. Generate an order item for each record in the customers_orders table in the format of one of the following:
-- Meat Lovers
-- Meat Lovers - Exclude Beef
-- Meat Lovers - Extra Bacon
-- Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers

WITH orders AS (
    SELECT
    row_number() OVER() AS id
    , co.*
    , pn.pizza_name
       , CASE
            WHEN LENGTH(co.exclusions) = 0 THEN null
            ELSE string_to_array(co.exclusions,',')::int[]
        END exclusion
       , CASE
            WHEN LENGTH(co.extras) = 0 THEN null
            ELSE string_to_array(co.extras,',')::int[]
        END extra
FROM  pizza_runner.cl_customer_orders co
JOIN pizza_runner.pizza_names pn
USING(pizza_id)
ORDER BY id, order_id
),

results AS (SELECT
    id
    , order_id
    , pizza_name
    , (
        SELECT 
            string_agg(topping_name, ', ')
        from pizza_runner.pizza_toppings pt
        where pt.topping_id IN (SELECT unnest(exclusion) FROM orders o WHERE o.id = orders.id)
    ) exclusions
    , (
        SELECT 
            string_agg(topping_name, ', ')
        from pizza_toppings pt
        where pt.topping_id IN (SELECT unnest(extra) FROM orders o WHERE o.id = orders.id)
    ) extras
    , order_time
FROM orders)

SELECT
    id
    , pizza_name || CASE
        WHEN exclusions IS NULL THEN ''
        ELSE ' - Exclude ' || exclusions
        END || CASE
        WHEN extras IS NULL THEN ''
        ELSE ' - Extras ' || extras
        END order_items
FROM results; 

-- 5. Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
-- For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"

WITH pd AS (
			SELECT ROW_NUMBER() OVER () id
				   , order_id
				   , co.pizza_id
				   , pizza_name
				   , STRING_TO_TABLE(exclusions,',')::INT exclusions
				   , STRING_TO_TABLE(extras,',')::INT extras
				   , STRING_TO_TABLE(toppings,',')::INT topping_id
			FROM cl_customer_orders co
			JOIN pizza_names pn
			USING (pizza_id)
			JOIN pizza_recipes pt
			USING (pizza_id)
			),
			
	naming AS(
		SELECT id
			   , order_id
			   , pizza_id
			   , pizza_name
			   , topping_name
			   , (SELECT topping_name FROM pizza_toppings p WHERE p.topping_id = pd.extras ORDER BY 1) extras
			   , (SELECT topping_name FROM pizza_toppings p WHERE p.topping_id = pd.exclusions) exclusions
		FROM  pd
		JOIN pizza_toppings pt
		USING (topping_id)
		ORDER BY topping_name
			),
		
	orders AS (
		SELECT id
		   , order_id
		   , pizza_name
		   , CASE 
		   		WHEN extras IN (SELECT topping_name FROM naming n) 
				THEN '2x ' || topping_name
				ELSE topping_name 
			END ingredients
	FROM naming
	ORDER BY order_id,topping_name
	)
	
	SELECT order_id
		   , pizza_name || ': ' || STRING_AGG(ingredients, ', ' ORDER BY ingredients) ingredients		   
	FROM orders
	GROUP BY id, order_id, pizza_name
	ORDER BY order_id;
