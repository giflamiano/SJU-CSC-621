-- CSC-621 Assignment 2

-- Safe Updates
set SQL_SAFE_UPDATES=0;
set FOREIGN_KEY_CHECKS=0;

-- Move to hw2 schema
use hw2; 
show tables;

/* *******************************************
	RELATIONAL MODEL:
	-- chefs(chefID, name, specialty)
    -- restaurants(restID, name, location)
    -- works(chefID, restID)
    -- foods(foodID, name, type, price)
    -- serves(restID, foodID, date_sold)    
******************************************* */

-- 1. Average Price of Foods at Each Restaurant
select serves.restID, restaurants.name, avg(foods.price) as avg_food_price
from foods natural join serves
join restaurants on serves.restID = restaurants.restID
group by serves.restID, restaurants.name;

-- 2. Maximum Food Price at Each Restaurant
select serves.restID, restaurants.name, max(foods.price) as max_food_price
from foods natural join serves
join restaurants on serves.restID = restaurants.restID
group by serves.restID, restaurants.name;

-- 3. Count of Different Food Types Served at Each Restaurant
select serves.restID, restaurants.name, count(distinct foods.type) as food_type_count
from foods natural join serves
join restaurants on serves.restID = restaurants.restID
group by serves.restID, restaurants.name;

-- 4. Average Price of Foods Served by Each Chef
select chefs.chefID, chefs.name, avg(foods.price) as avg_food_price
from chefs natural join works
join serves on works.restID = serves.restID
join foods on serves.foodID = foods.foodID
group by chefs.chefID, chefs.name;

-- 5. Find the Restaurant with the Highest Average Food Price
select serves.restID, restaurants.name, avg(foods.price) as avg_food_price
from foods natural join serves
join restaurants on serves.restID = restaurants.restID
group by serves.restID, restaurants.name
order by avg_food_price desc
limit 1;

-- Extra Credit: Determine which chef has the highest average price of the foods served at the restaurants where they work. 
-- Include the chef’s name, the average food price, and the names of the restaurants where the chef works. 
-- Sort the results by the average food price in descending order.
select chefs.name, avg(foods.price) as avg_food_price, group_concat(distinct restaurants.name) as restaurant_names
from chefs natural join works
inner join restaurants on works.restID = restaurants.restID
inner join serves on restaurants.restID = serves.restID
inner join foods on serves.foodID = foods.foodID
group by chefs.chefID, chefs.name
order by avg_food_price desc
limit 1;






