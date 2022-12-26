## 🍜 Case Study #1: [Danny's Diner](https://8weeksqlchallenge.com/case-study-1/)

## Solutions

Click [here](https://github.com/TayoPraise/SQL-Projects/blob/main/8%20Weeks%20Challenge/Case%20Study%20%231%20(Danny's%20Diner)/SQL%20syntax.sql) for the query syntax 

***

### 1. What is the total amount each customer spent at the restaurant?

````sql
SELECT customer_id AS customer
       , '$'|| SUM(price) AS total_spent 
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.menu m
USING(product_id)
GROUP BY 1
ORDER BY customer_id;
````

#### Steps:
- Create a join to connect the ```sales table``` to the ```menu table``` using ```product_id``` with product details in the ```menu table``` including the ```product name``` and ```price```
- **SUM** the product ```price``` and **GROUP BY** the ```customer_id```

#### Answer:

| customer |  total_spent |
| :------: |   :-------:  |
|   A      |	$76       |
|   B      |	$74       |
|   C      |	$36       |

***

### 2. How many days has each customer visited the restaurant?

````sql
SELECT customer_id customer
       , COUNT(DISTINCT order_date) AS "number of days visited"
FROM dannys_diner.sales s
GROUP BY 1;
````
#### Steps:
- Apply **Distinct** function on the ```order_date```. This is done due to customers visiting the store more than once on the same day which would be counted as 2 days.
- Wrapped the above step in the **COUNT** function to get the actual number of times a customer visited the restaurant. 
- **GROUP BY** the ```customer_id```

#### Answer:

| customer |  number of days visited |
| :------: |    -------:    |
|   A      |	4           |
|   B      |	6           |
|   C      |	2           |

***

### 3. What was the first item from the menu purchased by each customer?

````sql
WITH order_cte AS(
		SELECT customer_id
		       , product_name
		       , price
		       , order_date
		       , DENSE_RANK() OVER (PARTITION BY customer_id ORDER BY order_date) as rank
		FROM dannys_diner.sales s
		LEFT JOIN dannys_diner.menu m
		USING(product_id)
	    	GROUP BY 1,2,3,4
		ORDER BY customer_id
		)

SELECT customer_id AS customer
       , STRING_AGG(product_name,', ') AS first_order
FROM order_cte
WHERE rank = 1
GROUP BY 1;
````

#### Steps:
- Create **TEMP TABLE** called ```order_cte``` which ```joins``` the **sales table** with the **menu table** using ```product_id``` to get the **product_name**
- In the **order_cte**, add a ```windows function``` that **DENSE_RANK** customer's orders by their order date
- From the **order_cte**, select the **customer_id** and ```string_agg``` **product_name** for items that were ordered on the same day that meet the criteria
- Apply a ```where clause``` on the **rank** column to filter value of **1**

#### Answer:

| customer |  first_order  |
| :------: |   :-------:   |
|   A      |	sushi, curry |
|   B      |	curry        |
|   C      |	ramen        |

***


### 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

````sql
SELECT m.product_name "product name"
       , COUNT(s.product_id) "number of orders"
FROM dannys_diner.sales s
JOIN dannys_diner.menu m
USING(product_id)
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;
````

#### Steps:
- Create a join to connect the ```sales table``` to the ```menu table``` using ```product_id``` to identify the product witht he most orders
- **COUNT** the  ```product_id``` and **GROUP BY** the ```product_name```
- We use the ```Order by``` clause to **sort** the result in descending order 
- Then ```LIMIT``` the final output to the **first row** ie **1**

#### Answer:

| product name |  number or orders |
| :------:     |   -------:        |
|   ramen      |	8          |

***


### 5. Which item was the most popular for each customer?

````sql
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
````

#### Steps:
- Create **TEMP TABLE** called ```sales_cte``` which ```joins``` the **sales table** with the **menu table** using ```product_id``` to get the **product_name**
- In the **slaes_cte**, add a ```windows function``` that **RANK** customer's orders and **orders* it by the **COUNT** of product_name in ```DESC``` order
- From the **sales_cte**, select the **customer_id**, ```string_agg``` **product_name** for items with equal number of orders and the volume of orders placed for the item
- Apply a ```where clause``` on the **rank** column to filter value of **1**


#### Answer:

| customer |  product name        |  number of times ordered  |
| :------: |   :-------:          |     :--------:	      |
|   A      |	ramen             |	3		      |
|   B      |	sushi,curry,ramen |	2                     | 
|   C      |	ramen             |	3                     |

***


### 6. Which item was purchased first by the customer after they became a member?

````sql
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
	, product_name
FROM firstOrder_cte
JOIN dannys_diner.menu
USING(product_id)
WHERE rank = 1
ORDER BY 1;
````

#### Steps:
- Create **TEMP TABLE** called ```firstOrder_cte``` which ```joins``` the **sales table** with the **members table** using ```customer_id``` to get the **customer join date** where the **join_date** is less than the **order_date**
- In the **firstOrder_cte**, add a ```windows function``` that **RANK** customers and **orders* it by their **order_date**
- Create a join on the **firstOrder_cte** with the **menu table** using ```product_id``` to get the **product_name***
- From the **firstOrder_cte**, select the **customer_id**, **join_date**, **order_date** and **product_name** 
- Apply a ```where clause``` on the **rank** column to filter value of **1**

#### Answer:

| customer | join_date	      |  order_date    |  product name	|
| :------: |   :-------:      |    :--------:  |   :------:	|
|   A      |	2021-01-07    |	  2021-01-10   |    ramen	|
|   B      |	2021-01-07    |	  2021-01-11   |    sushi	|

***

### 7. Which item was purchased just before the customer became a member?

````sql
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
````

#### Steps:
- Create **TEMP TABLE** called ```orderBefore_cte``` which ```joins``` the **sales table** with the **members table** using ```customer_id``` to get the **customer join date**
- In the **orderBefore_cte**, add a ```windows function``` that **RANK** customers and **orders* it by their **order_date** in ```DESC
- Create a join on the **orderBefore_cte** with the **menu table** using ```product_id``` to get the **product_name***
- From the **orderBefore_cte**, select the **customer_id**, **join_date**, **order_date** and ```string_agg``` **product_name** for **order_date** with more than 1 item 
- Apply a ```where clause``` on the **rank** column to filter value of **1**

#### Answer:

| customer | join_date	   |  order_date     |  product name	|
| :------: |   :-------:   |    :--------:   |	:------:	|
|   A      |	2021-01-07 |	2021-01-01   |	sushi, curry	|
|   B      |	2021-01-07 |	2021-01-04   | 	sushi		|

***

### 8. What is the total items and amount spent for each member before they became a member?

````sql
SELECT s.customer_id AS customer
       , COUNT(product_id) AS "number of items"
       , SUM(price) "amount spent ($)"
FROM dannys_diner.sales s
JOIN dannys_diner.members m
USING(customer_id)
JOIN dannys_diner.menu me
USING(product_id)
WHERE join_date > order_date
GROUP BY 1
ORDER BY 1;
````

#### Steps:
- Create a **join** to connect the ```sales table``` to the ```members table``` using ```customer_id```and also join the ```menu table``` using the ```product_id```
- **COUNT** the ```product_id``` and **SUM** the ```price``` **where** the customer join_date is greater than the order_date
-  **GROUP BY** the ```customer_id``` 

#### Answer:

| customer | number of items  | amount spent ($)|
| :------: |   :-------:      |    :--------:	|
|   A      |	2	      |		25	|
|   B      |	3	      |		40	|

***


### 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

````sql
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
````

#### Steps:
- Create a join to connect the ```sales table``` to the ```menu table``` using ```product_id``` with product details in the ```menu table``` including the ```product name``` and ```price```
- Write a **CASE STATEMENT** which identifies the **product_name** ```sushi``` & multiplies the price by 20 and other items price by 10 
- **SUM** the above case statement which was names  ```points``` 
-  **GROUP BY** the ```customer_id```

#### Answer:

| customer |  	points	  |
| :------: |   :-------:  |
|   A      |	860	  |
|   B      |	940       |
|   C      |	360       |

***


### 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

````sql
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
````
 
 #### Steps:
- Create **TEMP TABLE** called ```promo_period``` from the **members table**
- using the **join_date**, calculate the first week after the customer becomes a member as the ```promo_date```
- **Date_trunc** ```month``` from **join_date** add the **1 month interval and take 1 day** from it to find the last day of the month as ```eom```
- Join the **promo_period** cte to the ```sales table```using the **customer_id** then join the ```menu table``` using ```product_id``` 
- Write a **CASE STATEMENT** which identifies the **product_name** ```sushi``` & multiply the price by 20, also to identify orders that were within the **promo_date** & multiply all items bought by 20 and other items bought outside the **promo_date** by 10 
- **SUM** the above case statement which was names  ```points``` 
- **GROUP BY** the ```customer_id```

#### Answer:

| customer |  points	  |
| :------: |   :-------:  |
|   A      |	1370      |
|   B      |	820       |


***
  
### Bonus Questions:

### 1. Create joined tables with membership status (Y/N)

```sql
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
```

 #### Steps:
- Left Join the **sales table** to the **members table** using ```customer_id``` 
- join the **menu table** to the **sales table** using ```product_id```
- Select the required columns 
- Write a **CASE STATEMENT** which compares the ```order_date``` to the ```join_date```, and where the **order_date** is less than the **join_date** or the **join_date** is null, return **N** else return **Y**
 

#### Answer:

| customer_id | order_date | product_name | price | member |
| ----------- | ---------- | -------------| ----- | ------ |
| A           | 2021-01-01 | sushi        | 10    | N      |
| A           | 2021-01-01 | curry        | 15    | N      |
| A           | 2021-01-07 | curry        | 15    | Y      |
| A           | 2021-01-10 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| A           | 2021-01-11 | ramen        | 12    | Y      |
| B           | 2021-01-01 | curry        | 15    | N      |
| B           | 2021-01-02 | curry        | 15    | N      |
| B           | 2021-01-04 | sushi        | 10    | N      |
| B           | 2021-01-11 | sushi        | 10    | Y      |
| B           | 2021-01-16 | ramen        | 12    | Y      |
| B           | 2021-02-01 | ramen        | 12    | Y      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-01 | ramen        | 12    | N      |
| C           | 2021-01-07 | ramen        | 12    | N      |

***
### 2. Ranking  member products

```sql
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
```

 #### Steps:
- Create **TEMP TABLE** called ```member_status``` from the Bonus Question 1 staps
- Select all from the **member_status** cte
- Write a **CASE STATEMENT** which identifies a customer membership stauts as **N** and return null on it if not,
- write a **WINDOW FUNCTION** that ```DENSE_RANK``` **customer_id** and **member** columns then **order by** the ```order_date```


#### Answer:

| customer_id | order_date | product_name | price | member | ranking | 
| ----------- | ---------- | -------------| ----- | ------ |-------- |
| A           | 2021-01-01 | sushi        | 10    | N      | NULL		 |
| A           | 2021-01-01 | curry        | 15    | N      | NULL    |
| A           | 2021-01-07 | curry        | 15    | Y      | 1       |
| A           | 2021-01-10 | ramen        | 12    | Y      | 2       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| A           | 2021-01-11 | ramen        | 12    | Y      | 3       |
| B           | 2021-01-01 | curry        | 15    | N      | NULL    |
| B           | 2021-01-02 | curry        | 15    | N      | NULL    |
| B           | 2021-01-04 | sushi        | 10    | N      | NULL    |
| B           | 2021-01-11 | sushi        | 10    | Y      | 1       |
| B           | 2021-01-16 | ramen        | 12    | Y      | 2       |
| B           | 2021-02-01 | ramen        | 12    | Y      | 3       |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-01 | ramen        | 12    | N      | NULL    |
| C           | 2021-01-07 | ramen        | 12    | N      | NULL    |


