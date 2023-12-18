
--Project by: Eniola Orehin
--TABLES

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
  
  



	--QUESTIONS

	  -- 1. What is the total amount each customer spent at the restaurant?

	  --To write this query i summed the price to get the total and i joined the sales and menu table based on mutual colums.
SELECT S.customer_id, SUM(price) AS total_sales
FROM menu M
LEFT JOIN sales S ON M.product_id = S.product_id
GROUP BY S.customer_id
ORDER BY total_sales DESC




-- 2. How many days has each customer visited the restaurant?
-- To solve this i counted the neccesary colmns gave it an alias,and group it by the customer id in order to avoid repeated count of the ids
SELECT COUNT(*) AS no_of_times_visited, customer_id 
FROM sales
group by customer_id
Order by no_of_times_visited DESC  


-- 3. What was the first item from the menu purchased by each customer?
--To solve this i used window functions and joins as well as passing on some alias.
SELECT X.*, M.product_name
FROM (
    SELECT s.*,
           ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date) AS first_item_ordered
    FROM sales s
) X
JOIN menu M ON X.product_id = M.product_id
WHERE X.first_item_ordered = 1;


-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

--i counted how many times a product name  showed up, and i joined it with the menu table so it can extract the names of the product using the product id 
SELECT product_name, COUNT(*) AS purchase_count
FROM sales
INNER JOIN menu
        ON sales.product_id = menu.product_id
GROUP BY product_name 
ORDER BY COUNT(*) DESC; 


-- 5. Which item was the most popular for each customer?
--To achive the correct result for this question I thought the best approach will be to use subquery or nested query as well as some window and aggregates functions with the appropriate arrangement 
 
 SELECT customer_id, product_count,product_name
FROM (
  SELECT
    customer_id,
	product_name,
    COUNT(*) AS product_count,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY COUNT(*) DESC) AS row_num
  FROM sales, menu
  GROUP BY customer_id, product_name
) x
WHERE row_num = 1; 


-- 6) Which item was purchased first by the customer after they became a member?

-- This  is  a ranking question but before using window function to get the result it would be best if  i created a common table expression to hold the function and then use it later on after joing the nessecary tables

  WITH cte AS (SELECT ROW_NUMBER () OVER (PARTITION BY dbo.members.customer_id ORDER BY dbo.sales.order_date) AS row_id, 
	dbo.sales.customer_id, dbo.sales.order_date, dbo.menu.product_name 
	FROM dbo.sales 
    	JOIN dbo.menu
    	ON dbo.sales.product_id = dbo.menu.product_id
    	JOIN dbo.members
    	ON dbo.members.customer_id = dbo.sales.customer_id
	WHERE dbo.sales.order_date >= dbo.members.join_date)

	SELECT * 
	FROM cte 
	WHERE row_id = 1


--7)Which item was purchased just before the customer became a member?
   
   --i also used Common table expression , window functions, and  join to get this result 
  WITH cte AS (SELECT ROW_NUMBER () OVER (PARTITION BY dbo.members.customer_id ORDER BY dbo.sales.order_date) AS row_id, 
	dbo.sales.customer_id, dbo.sales.order_date, dbo.menu.product_name 
	FROM dbo.sales 
    	JOIN menu
    	ON dbo.sales.product_id = dbo.menu.product_id
    	JOIN members
    	ON members.customer_id = dbo.sales.customer_id
	WHERE dbo.sales.order_date < dbo.members.join_date)

	SELECT * 
	FROM cte 
	WHERE row_id = 1



--8) What is the total items and amount spent for each member before they became a member?

--i used sum and count along side the distinct keyword to first to sum the price, and to count the product id without duplication of count, and then i joined the neccesary tables and grouped by the customer id.

	SELECT  s.customer_id, 
SUM(m.price) AS total_price, 
COUNT (distinct s.product_id) AS total_items
FROM sales s
  JOIN menu m
 ON m.product_id= s.product_id
 JOIN members
 ON s.customer_id = members.customer_id
WHERE s.order_date < members.join_date
GROUP BY  s.customer_id


		 
--9)If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

--case statements is the most efficient for a question like this because we want to get a certain result if the condition meets a certain criteria. 
--so after the case statement i joined the neccesary table to get ther required result

	SELECT sales.customer_id,
	SUM(
    	CASE
      	WHEN menu.product_name = 'sushi' THEN 20 * price
      	ELSE 10 * PRICE
    	END
  	) AS Points
	FROM sales
    	JOIN menu
    	ON sales.product_id = menu.product_id
	GROUP BY
  	sales.customer_id
	ORDER BY
  sales.customer_id;
	




---10) In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January
-- i also used case statement and join for this question 
SELECT sales.customer_id,
	SUM(
    CASE
   	WHEN menu.product_name IN('sushi', 'curry', 'ramen')
		and sales.order_date BETWEEN '2021-01-07' AND  '2021-01-14' THEN 20 * price       	
   else 10*price
		END
  	) AS Points
	FROM sales
    	JOIN menu
    	ON sales.product_id = menu.product_id
	GROUP BY
  	sales.customer_id
	ORDER BY
  sales.customer_id;
	

		
		
	






































































































 




















































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































































-- 6. Which item was purchased first by the customer after they became a member?
-- 7. Which item was purchased just before the customer became a member?
-- 8. What is the total items and amount spent for each member before they became a member?
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
