--------------------------------
--Data Cleaning--
--------------------------------


--Author: Temitayo Ipinlaiye
--Date: 16/12/2022 
--Tool used: PostgreSQL

-- Selecting the schema I'm working in

SET search_path TO pizza_runner;
  
-- Create a new table containing my cleaned data from customer_orders
-- Functions used: CASE WHEN
-- Cleaning the null values & null string in the exclusions & extras column

DROP TABLE IF EXISTS cl_customer_orders;

CREATE TABLE cl_customer_orders AS(
	SELECT order_id
	   , customer_id
	   , pizza_id
	   , CASE 
	   	   WHEN exclusions IS null OR exclusions LIKE 'null'
		   THEN ''
	       ELSE exclusions
	     END exclusions
	   , CASE 
	   	   WHEN extras IS null OR extras LIKE 'null'
		   THEN ''
	       ELSE extras
	     END extras
	   , order_time
FROM pizza_runner.customer_orders);

-- Create a new table containing my cleaned data from runner_orders
-- Functions used: CASE WHEN, TRIM, Wildcards (%), ALTER table, ALTER data types
-- Cleaning the null values & null string in the pickup_time, distance & duration
-- Trim the distance metric unit (km) and duration unit (minute, etc) from their respective columns


DROP TABLE IF EXISTS cl_runner_orders;

CREATE TABLE cl_runner_orders AS(
	SELECT order_id
	   , runner_id
	   , CASE 
	   	   WHEN pickup_time IS null OR pickup_time LIKE 'null' THEN null
	       ELSE pickup_time
	     END pickup_time
	   , CASE 
	   	   WHEN distance IS null OR distance LIKE 'null' THEN null
	       WHEN distance LIKE '%km' THEN TRIM('km' from distance)
	       ELSE distance
	     END distance
	   , CASE 
	   	  WHEN duration IS null OR duration LIKE 'null' THEN null
	      WHEN duration LIKE '%mins' THEN TRIM('mins' from duration)
	      WHEN duration LIKE '%minute' THEN TRIM('minute' from duration)
	      WHEN duration LIKE '%minutes' THEN TRIM('minutes' from duration)
	      ELSE duration 
	     END duration
	   , CASE 
	   	   WHEN cancellation IS null OR cancellation LIKE 'null'
		   THEN ''
	       ELSE cancellation
	     END cancellation
FROM pizza_runner.runner_orders);

-- Alter table & columns to change the data types of the above cleaned columns for better analysis

ALTER TABLE cl_runner_orders
	ALTER COLUMN pickup_time TYPE timestamp without time zone
		USING pickup_time::timestamp,
    ALTER COLUMN distance TYPE NUMERIC
		USING distance::numeric,
	ALTER COLUMN duration TYPE INT
		USING duration::integer;
