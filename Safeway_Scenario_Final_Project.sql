CREATE SCHEMA `Final_Project`;
USE `Final_Project`;

ALTER TABLE customer
ADD CONSTRAINT PKCustomer_id PRIMARY KEY customer (CustomerID);

ALTER TABLE orders
ADD CONSTRAINT PKOrder_id PRIMARY KEY orders (OrderID),
ADD CONSTRAINT FK1 FOREIGN KEY (CustomerID) REFERENCES customer (CustomerID);

ALTER TABLE product
ADD CONSTRAINT PKProduct_id PRIMARY KEY product (ProductID);

ALTER TABLE orderline
ADD CONSTRAINT PKBuys PRIMARY KEY (OrderID, ProductID),
ADD CONSTRAINT FK2 FOREIGN KEY (OrderID) REFERENCES orders (OrderID),
ADD CONSTRAINT FK3 FOREIGN KEY (ProductID) REFERENCES product (ProductID);

SELECT * FROM customer;
SELECT * FROM orders;
SELECT * FROM product;
SELECT * FROM orderline;
SELECT * FROM denormalized;

-- 5 queries without join
-- 1. How many customers have membership?
SELECT COUNT(*) AS 'Count'
FROM customer
WHERE MemberID > 0;

-- 2. How many different orders did occur?
SELECT COUNT(*)
FROM orders;

-- 3. How many days do these orders expand?
SELECT DATEDIFF(MAX(OrderDate),MIN(OrderDate)) AS 'date expand'
FROM orders;

-- 4. What's the average unit price of all the products?
SELECT AVG(UnitPrice) AS 'avg unit price'
FROM product;

-- 5. What's the total volume does orderId 13 purchased?
SELECT SUM(Volume) AS 'total volume'
FROM orderline
GROUP BY OrderID
HAVING OrderID = 13;

-- 10 queries with join
-- 1. What are customer names for each order?
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer Name', OrderID, OrderDate
FROM orders o
LEFT JOIN customer c ON o.CustomerID = c.CustomerID;

-- 2. Which customer has the most orders?
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer Name', COUNT(OrderID) AS 'Count'
FROM orders o
LEFT JOIN customer c ON o.CustomerID = c.CustomerID
GROUP BY o.CustomerID
ORDER BY 2 DESC
LIMIT 1;

-- 3. What's the daily revenue?
SELECT o.OrderDate, SUM((ol.Volume * p.UnitPrice)) AS 'Revenue'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
GROUP BY 1
ORDER BY 1;

-- 4. Which customer spent the most?
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer Name', SUM((ol.Volume * p.UnitPrice)) AS 'Revenue'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
LEFT JOIN customer c ON c.CustomeriD = o.CustomerID
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 5. Which product is the most popular?
SELECT Descriptions, COUNT(ol.OrderID) AS 'Count'
FROM orderline ol
INNER JOIN product p ON ol.ProductID = p.ProductID
GROUP BY p.ProductID
ORDER BY 2 DESC
LIMIT 1;

-- 6. Which customers purchased 'Tofu'?
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer Name'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
LEFT JOIN customer c ON c.CustomeriD = o.CustomerID
WHERE p.ProductID = 10;

-- 7. Which product contributes the most to revenue?
SELECT Descriptions, SUM((ol.Volume * p.UnitPrice)) AS 'Revenue'
FROM orderline ol
INNER JOIN product p ON ol.ProductID = p.ProductID
GROUP BY 1
ORDER BY 2 DESC
LIMIT 1;

-- 8. What product did each member purchase?
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer Name', Descriptions
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
LEFT JOIN customer c ON c.CustomeriD = o.CustomerID
WHERE MemberID > 0;

-- 9. How much money did memberID 1 spend?
SELECT SUM((ol.Volume * p.UnitPrice)) AS 'Revenue'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
LEFT JOIN customer c ON c.CustomeriD = o.CustomerID
WHERE MemberID = 1;

-- 10. What is the average payment of all the orders?
SELECT AVG(ol.Volume * p.UnitPrice) AS 'Average Revenue'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID;

-- 2 views
CREATE VIEW revenue AS
SELECT c.CustomerID, o.OrderID, p.ProductID, (ol.Volume * p.UnitPrice) AS 'Revenue'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
LEFT JOIN customer c ON c.CustomeriD = o.CustomerID;

SELECT * FROM revenue;

CREATE VIEW time_revenue AS
SELECT OrderDate, SUM(ol.Volume * p.UnitPrice) AS 'Revenue'
FROM orderline ol
LEFT JOIN product p ON ol.ProductID = p.ProductID
LEFT JOIN orders o ON o.OrderID = ol.OrderID
GROUP BY 1
ORDER BY 1;

SELECT * FROM time_revenue;

-- 1 trigger
CREATE TABLE ProductUpdates 
(
ProductID 		INT,
Descriptions 	VARCHAR(50),
UnitPrice		DECIMAL(5,2)
);

CREATE TRIGGER ProductUpdateTrigger 
AFTER UPDATE ON product 
FOR EACH ROW
	INSERT INTO ProductUpdates
		SELECT ProductID, Descriptions, UnitPrice FROM product;

SET SQL_SAFE_UPDATES = 0;
UPDATE product
SET UnitPrice = 3.99 
WHERE ProductID = 1;

SELECT * FROM ProductUpdates;
SELECT * FROM product;

-- procedure
DELIMITER // 
CREATE PROCEDURE UpdateCust(IN id INT, IN f_name CHAR(20))
BEGIN
UPDATE customer
SET FirstName = f_name
WHERE CustomerID = id;
END //

CALL UpdateCust(1,'Amanda');
CALL UpdateCust(2,'April');

SELECT * FROM customer;

-- 3 advanced SQL
-- 1.Union - return max and min revenue for each customer
WITH t1 AS (
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer_Name', SUM((ol.Volume * p.UnitPrice)) AS 'Revenue'
	FROM orderline ol, product p, orders o, customer c
	WHERE ol.ProductID = p.ProductID
		AND o.OrderID = ol.OrderID
		AND c.CustomeriD = o.CustomerID
GROUP BY 1
)
SELECT t1.Customer_Name, Revenue
FROM t1
WHERE t1.Revenue = (SELECT MAX(Revenue) FROM t1)

UNION

SELECT t1.Customer_Name, Revenue
FROM t1
WHERE t1.Revenue = (SELECT MIN(Revenue) FROM t1);

-- 2.Date function - How many orders in each month?
SELECT MONTHNAME(OrderDate) AS 'Month', COUNT(*)
FROM orders
GROUP BY 1;

-- 3.RANK - rank each customer's revenue
SELECT CONCAT(FirstName,' ',LastName) AS 'Customer Name', SUM(ol.Volume * p.UnitPrice) AS 'Revenue',
RANK () OVER(ORDER BY SUM(ol.Volume * p.UnitPrice) DESC) amount_rank
FROM orderline ol, product p, orders o, customer c
WHERE ol.ProductID = p.ProductID
AND o.OrderID = ol.OrderID
AND c.CustomeriD = o.CustomerID
GROUP BY 1;

-- 4.CASE - classify revenue
SELECT Descriptions, SUM(o.Volume * p.UnitPrice) AS 'Revenue',
	CASE
		WHEN SUM(o.Volume * p.UnitPrice) > 15 THEN 'high revenue'
	ELSE 'low revenue'
END AS revenue_class
FROM orderline o
LEFT JOIN product p ON o.ProductID = p.ProductID
GROUP BY 1
ORDER BY 2 DESC;








