CREATE DATABASE IF NOT EXISTS dannys_diner;
USE dannys_diner;
SELECT database();

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
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
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
  SELECT * FROM sales;
  SELECT * FROM menu;
  SELECT * FROM members;
  
  -- 1. What is the total amount each customer spent at the restaurant?
  SELECT s.customer_id,SUM(m.price) AS TOT_AMOUNT
  FROM sales s
  JOIN menu m ON s.product_id=m.product_id
  GROUP BY 1;
  
  -- 2. How many days has each customer visited the restaurant?
  SELECT customer_id,COUNT(DISTINCT order_date)
  FROM sales
  GROUP BY 1;
  
  -- 3. What was the first item from the menu purchased by each customer?
  WITH CTE AS(
 SELECT s.customer_id,s.order_date,m.product_name,
 ROW_NUMBER() OVER(PARTITION BY s.customer_id ORDER BY s.order_date) AS FIRST_ORDER
 FROM sales s
 JOIN menu m ON s.product_id=m.product_id)
SELECT customer_id,order_date,product_name
FROM CTE
WHERE FIRST_ORDER=1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT m.product_name,COUNT(s.product_id) AS MOST_PURCHASED
FROM sales s
JOIN menu m ON s.product_id=m.product_id
GROUP BY 1
ORDER BY 2 DESC;


-- 5. Which item was the most popular for each customer?

WITH CTE AS
(SELECT s.customer_id,
COUNT(m.product_name) AS A,
m.product_name,
DENSE_RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(m.product_name)DESC) AS B
FROM sales s
JOIN menu m ON s.product_id=m.product_id
GROUP BY 1,3)
SELECT customer_id,product_name,A
FROM CTE
WHERE B=1
ORDER BY 3 DESC;

-- 6. Which item was purchased first by the customer after they became a member?
WITH CTE AS
(SELECT a.customer_id,b.join_date,a.order_date,c.product_name,DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY a.order_date) AS AB
FROM sales a
JOIN members b ON a.customer_id=b.customer_id
JOIN menu c ON a.product_id=c.product_id
WHERE a.order_date>=b.join_date)
SELECT customer_id,product_name
FROM CTE
WHERE AB=1;

-- 7. Which item was purchased just before the customer became a member?
WITH CTE AS
(SELECT a.customer_id,a.order_date,b.join_date,c.product_name,DENSE_RANK() OVER(PARTITION BY a.customer_id ORDER BY a.order_date DESC) AS AB
FROM sales a
JOIN members b ON a.customer_id=b.customer_id
JOIN menu c ON a.product_id=c.product_id
WHERE a.order_date<b.join_date)
SELECT customer_id,product_name
FROM CTE 
WHERE AB=1;

-- 8. What is the total items and amount spent for each member before they became a member?
WITH CTE AS
(SELECT a.customer_id,
c.product_id,
c.price
FROM sales a
JOIN members b ON a.customer_id=b.customer_id
JOIN menu c ON a.product_id=c.product_id
WHERE a.order_date<b.join_date)
SELECT customer_id,COUNT(product_id),SUM(price)
FROM CTE
GROUP BY 1
ORDER BY 1;


SELECT a.customer_id,
COUNT(c.product_id) AS TOTAL_ITEMS,
SUM(c.price) AS AMOUNT_SPENT
FROM sales a
JOIN members b ON a.customer_id=b.customer_id
JOIN menu c ON a.product_id=c.product_id
WHERE a.order_date<b.join_date
GROUP BY 1
ORDER BY 1;


-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH CTE AS
(SELECT product_id,
CASE
	WHEN product_id=1 THEN price * 20
    ELSE price * 10
END AS AB
FROM menu)
SELECT a.customer_id,SUM(AB)
FROM CTE
JOIN sales a ON CTE.product_id=a.product_id
GROUP BY 1;


-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH CTE AS
(SELECT a.customer_id,a.order_date,b.product_id,
CASE
	WHEN a.order_date - c.join_date >=0 AND a.order_date - c.join_date <=6 THEN price * 20
    WHEN b.product_id = 1 THEN price * 20
    ELSE price * 10
END AS AB
FROM sales a
JOIN menu b ON a.product_id=b.product_id
JOIN members c ON a.customer_id=c.customer_id
WHERE EXTRACT(MONTH FROM a.order_date)=1 AND EXTRACT(YEAR FROM a.order_date)=2021)
SELECT customer_id,SUM(AB) AS TOTAL_SPENT
FROM CTE
GROUP BY 1
ORDER BY 1;


-- BONUS QUESTION
-- Join All The Things
SELECT a.customer_id,a.order_date,b.product_name,b.price,
CASE
	WHEN c.join_date>a.order_date THEN 'N'
    WHEN c.join_date<=a.order_date THEN 'Y' 
    ELSE 'N'
END AS member
FROM sales a 
JOIN menu b ON a.product_id=b.product_id
LEFT JOIN members c ON a.customer_id=c.customer_id
ORDER BY 1,2;

-- Rank All The Things

WITH CTE AS(
SELECT a.customer_id,a.order_date,b.product_name,b.price,
CASE
	WHEN c.join_date>a.order_date THEN 'N'
    WHEN c.join_date<=a.order_date THEN 'Y' 
    ELSE 'N'
END AS member
FROM sales a 
JOIN menu b ON a.product_id=b.product_id
LEFT JOIN members c ON a.customer_id=c.customer_id
ORDER BY 1,2)
SELECT customer_id,order_date,product_name,price,member,
CASE
	WHEN member = 'N' THEN NULL
    ELSE DENSE_RANK() OVER(PARTITION BY customer_id,member ORDER BY order_date)
END AS ranking
FROM CTE;
