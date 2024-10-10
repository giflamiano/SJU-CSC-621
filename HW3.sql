-- CSC-621 Assignment 2

-- Safe Updates
set SQL_SAFE_UPDATES=0;
set FOREIGN_KEY_CHECKS=0;

/** ******************************************************************************
	RELATIONAL MODEL:
    -- merchants(mid, name, city, state) 				PK: mid
	-- products(pid, name, category, description) 		PK: pid
	-- sell(mid, pid, price, quantity_available)		FK: mid, pid
	-- orders(oid, shipping_method, shipping_cost)		PK: oid
	-- contain(oid, pid)								FK: oid, pid
	-- customers(cid, fullname, city, state)			PK: cid
	-- place(cid, oid, order_date)						FK: cid, oid
********************************************************************************** */

/** ALTERING MERCHANTS TABLE */
-- Adding PK: mid
ALTER TABLE merchants ADD PRIMARY KEY (mid);

/** ALTERING PRODUCTS TABLE */
-- Adding PK: pid
ALTER TABLE products ADD PRIMARY KEY (pid);

-- Adding products name constraint: Printer, Ethernet Adapter, Desktop, Hard Drive, Laptop, Router, Network Card, Super Drive, Monitor
ALTER TABLE products 
ADD CONSTRAINT Chk_ProductsName 
CHECK (name IN ('Printer', 'Ethernet Adapter', 'Desktop', 'Hard Drive', 'Laptop', 'Router', 'Network Card', 'Super Drive', 'Monitor'));

-- Adding products category constraint: Peripheral, Networking, Computer
ALTER TABLE products
ADD CONSTRAINT Chk_ProductsCategory 
CHECK (category IN ('Peripheral', 'Networking', 'Computer'));

/** ALTERING SELL TABLE */
-- Adding FK: mid, pid
ALTER TABLE sell
ADD CONSTRAINT FK_MerchantsSell
FOREIGN KEY (mid) REFERENCES merchants(mid)
ON DELETE CASCADE;

ALTER TABLE sell
ADD CONSTRAINT FK_ProductsSell
FOREIGN KEY (pid) REFERENCES products(pid)
ON DELETE CASCADE;

-- Adding sell price constraint: between 0 and 100,000
ALTER TABLE sell
ADD CONSTRAINT Chk_SellPrice
CHECK (price>0 AND price<100000);

-- Adding sell quantity_available constraint: between 0 and 1,000
ALTER TABLE sell
ADD CONSTRAINT Chk_SellQuantity
CHECK (quantity_available>=0 AND quantity_available<1000);

/** ALTERING ORDERS TABLE */
-- Adding PK: oid
ALTER TABLE orders ADD PRIMARY KEY (oid);

-- Adding orders shipping_method constraint: UPS, FedEx, USPS
ALTER TABLE orders
ADD CONSTRAINT Chk_OrdersShippingMethod
CHECK (shipping_method IN ('UPS', 'FedEx', 'USPS'));

-- Adding orders shipping_cost constraint: between 0 and 500
ALTER TABLE orders
ADD CONSTRAINT Chk_OrdersShippingCost
CHECK (shipping_cost>0 AND shipping_cost<500);

/** ALTERING CONTAIN TABLE */
-- Adding FK: oid, pid
ALTER TABLE contain
ADD CONSTRAINT FK_OrdersContain
FOREIGN KEY (oid) REFERENCES orders(oid)
ON DELETE CASCADE;

ALTER TABLE contain
ADD CONSTRAINT FK_ProductsContain
FOREIGN KEY (pid) REFERENCES products(pid)
ON DELETE CASCADE;

/** ALTERING CUSTOMERS TABLE */
-- Adding PK: cid
ALTER TABLE customers ADD PRIMARY KEY (cid);

/** ALTERING PLACE TABLE */
-- Adding FK: cid, oid
ALTER TABLE place
ADD CONSTRAINT FK_CustomersPlace
FOREIGN KEY (cid) REFERENCES customers(cid)
ON DELETE CASCADE;

ALTER TABLE place
ADD CONSTRAINT FK_OrdersPlace
FOREIGN KEY (oid) REFERENCES orders(oid)
ON DELETE CASCADE;

-- Adding valid dates constraint
ALTER TABLE place MODIFY order_date date;

/** ************ QUERIES ************ */
-- 1. List names and sellers of products that are no longer available (quantity=0)
SELECT p.name as Pname, m.name AS seller
FROM products p
INNER JOIN sell s ON p.pid = s.pid
INNER JOIN merchants m ON s.mid = m.mid
WHERE s.quantity_available=0;

-- 2. List names and descriptions of products that are not sold.
SELECT p.name, p.description
FROM products p
WHERE p.pid NOT IN
(
	SELECT p.pid
	FROM products p 
	INNER JOIN sell s ON p.pid = s.pid
);

-- 3. How many customers bought SATA drives but not any routers?
WITH customers_with_SATA AS ( 		-- Gets customer IDs who have bought SATA drives
	SELECT DISTINCT c.cid
    FROM customers c
    INNER JOIN place p ON c.cid = p.cid
    INNER JOIN orders o ON p.oid = o.oid
    INNER JOIN contain ON o.oid = contain.oid
    WHERE contain.pid IN (SELECT pid FROM products WHERE name='Hard Drive' OR name='Super Drive')
), 
customers_with_routers AS (			-- Gets customer IDs who have bought routers
	SELECT DISTINCT c.cid
    FROM customers c 
    INNER JOIN place p ON c.cid = p.cid
    INNER JOIN orders o ON p.oid = o.oid
    INNER JOIN contain ON o.oid = contain.oid
    WHERE contain.pid IN (SELECT pid FROM products WHERE name='Router')
) 
-- Main query that gets count of customers who bought SATA drives but not routers
SELECT COUNT(*) AS customer_count FROM customers_with_SATA WHERE cid NOT IN (SELECT cid FROM customers_with_routers);

-- 4. HP has a 20% sale on all its Networking products.
SELECT m.name AS Mname, p.category, p.name AS Pname, sell.price AS original_price, ROUND(sell.price * 0.8, 2) AS sale_price
FROM merchants m
INNER JOIN sell ON m.mid = sell.mid
INNER JOIN products p ON sell.pid = p.pid
WHERE m.name='HP' AND p.category='Networking';

-- 5. What did Uriel Whitney order from Acer? (make sure to at least retrieve product names and prices).
SELECT c.fullname AS Cname, m.name AS Mname, p.name AS product_name, sell.price
FROM customers c 
INNER JOIN place ON c.cid = place.cid
INNER JOIN contain ON place.oid = contain.oid
INNER JOIN products p ON contain.pid = p.pid
INNER JOIN sell ON p.pid = sell.pid
INNER JOIN merchants m ON sell.mid = m.mid
WHERE c.fullname='Uriel Whitney' AND m.name='Acer'
GROUP BY CName, Mname, product_name, sell.price;

-- 6. List the annual total sales for each company (sort the results along the company and the year attributes).
SELECT m.name as company, ROUND(SUM(sell.price), 2) AS total_sales, YEAR(place.order_date) AS year
FROM merchants m 
INNER JOIN sell ON m.mid = sell.mid
INNER JOIN contain ON sell.pid = contain.pid
INNER JOIN place ON contain.oid = place.oid
GROUP BY m.mid, year
ORDER BY company, year;

-- 7. Which company had the highest annual revenue and in what year?
SELECT m.name AS company, ROUND(SUM(sell.price), 2) AS total_revenue, YEAR(place.order_date) AS year
FROM merchants m 
INNER JOIN sell ON m.mid = sell.mid
INNER JOIN contain ON sell.pid = contain.pid
INNER JOIN place ON contain.oid = place.oid
GROUP BY m.mid, year
ORDER BY total_revenue DESC
LIMIT 1;

-- 8. On average, what was the cheapest shipping method used ever?
SELECT shipping_method
FROM orders 
GROUP BY shipping_method 
ORDER BY AVG(shipping_cost) 
LIMIT 1;

-- 9. What is the best sold ($) category for each company?
WITH category_sales AS ( 	-- gets total sales by category by merchant
    SELECT m.mid, m.name AS merchant_name, p.category, SUM(sell.price) AS total_sales
    FROM merchants m
    INNER JOIN sell ON m.mid = sell.mid
    INNER JOIN products p ON sell.pid = p.pid
    GROUP BY m.mid, m.name, p.category
),
max_category AS (			-- gets category with the highest sales by merchant
    SELECT mid, MAX(total_sales) AS max_sales
    FROM category_sales
    GROUP BY mid
)
SELECT sales.merchant_name, sales.category, ROUND(sales.total_sales, 2) AS best_sales
FROM category_sales sales
INNER JOIN max_category max ON sales.mid = max.mid AND sales.total_sales = max.max_sales;

-- 10. For each company find out which customers have spent the most and the least amounts.
WITH customer_spending AS (		-- gets the list of how much each customer spent at each merchant
    SELECT m.mid, m.name AS merchant_name, c.cid, c.fullname AS customer_name, SUM(sell.price) AS total_spent
    FROM customers c
    INNER JOIN place ON c.cid = place.cid
    INNER JOIN contain ON place.oid = contain.oid
    INNER JOIN products p ON contain.pid = p.pid
    INNER JOIN sell ON p.pid = sell.pid
    INNER JOIN merchants m ON sell.mid = m.mid
    GROUP BY m.mid, m.name, c.cid, c.fullname
),
max_min_spent AS (				-- gets the max and min total spent by merchant
    SELECT mid, MAX(total_spent) AS max_spent, MIN(total_spent) AS min_spent
    FROM customer_spending
    GROUP BY mid
)
SELECT cs.merchant_name, cs.customer_name, ROUND(cs.total_spent, 2) AS total_spent, 
       CASE WHEN cs.total_spent = mm.max_spent THEN 'Max'
            WHEN cs.total_spent = mm.min_spent THEN 'Min'
       END AS spending_type
FROM customer_spending cs
INNER JOIN max_min_spent mm ON cs.mid = mm.mid
WHERE cs.total_spent = mm.max_spent OR cs.total_spent = mm.min_spent
ORDER BY cs.merchant_name;
