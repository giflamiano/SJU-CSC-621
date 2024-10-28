/** CSC-621 Assignment 4 */

-- Safe Updates
set SQL_SAFE_UPDATES=0;
set FOREIGN_KEY_CHECKS=0;

/** RELATIONAL MODEL:
	-- actor(actor_id, first_name, last_name)	PK: actor_id
    -- address(address_id, address, address2, district, city_id, postal_code, phone)	PK: address_id FK: city_id
    -- category(category_id, name)	PK: category_id
    -- city(city_id, city, country_id) 	PK: city_id FK: country_id
    -- country(country_id, country)	PK: country_id
    -- customer(customer_id, store_id, first_name, last_name, email, address_id, active) 	PK: customer_id FK: store_id, address_id
    -- film(film_id, title, description, release_year, language_id, rental_duration, rental_rate, length, replacement_cost, rating, special_features)	PK: film_id FK: language_id
    -- film_actor(actor_id, film_id)	(PK, FK): actor_id, film_id
    -- film_category(film_id, category_id) 	(PK, FK): film_id, category_id
    -- inventory(inventory_id, film_id, store_id) 	PK: inventory_id FK: film_id, store_id
    -- language(language_id, name) 	PK: language_id
    -- payment(payment_id, customer_id, staff_id, rental_id, amount, payment_date) 	PK: payment_id FK: customer_id, staff_id, rental_id
    -- rental(rental_id, rental_date, inventory_id, customer_id, return_date, staff_id) 	PK: rental_id FK: staff_id U: rental_date (U, FK): inventory_id, customer_id
    -- staff(staff_id, first_name, last_name, address_id, email, store_id, active, username, password) 	PK: staff_id FK: address_id, store_id
    -- store(store_id, address_id) PK: store_id FK: address_id
*/

/** ADDING REQUIRED CONSTRAINTS */
-- actor		PK: actor_id
ALTER TABLE actor ADD PRIMARY KEY (actor_id);

-- address		PK: address_id 		FK: city_id
ALTER TABLE address ADD PRIMARY KEY (address_id);
ALTER TABLE address ADD CONSTRAINT FK_CityAddress FOREIGN KEY (city_id) REFERENCES city(city_id) ON DELETE CASCADE;

-- category 	PK: category_id
ALTER TABLE category ADD PRIMARY KEY (category_id);

-- city 		PK: city_id 		FK: country_id
ALTER TABLE city ADD PRIMARY KEY (city_id);
ALTER TABLE city ADD CONSTRAINT FK_CountryCity FOREIGN KEY (country_id) REFERENCES country(country_id) ON DELETE CASCADE;

-- country 		PK: country_id
ALTER TABLE country ADD PRIMARY KEY (country_id);

-- customer 	PK: customer_id 	FK: store_id, address_id
ALTER TABLE customer ADD PRIMARY KEY (customer_id);
ALTER TABLE customer ADD CONSTRAINT FK_Storecustomer FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE CASCADE;
ALTER TABLE customer ADD CONSTRAINT FK_Addresscustomer FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE CASCADE;

-- film 		PK: film_id 		FK: language_id
ALTER TABLE film ADD PRIMARY KEY (film_id);
ALTER TABLE film ADD CONSTRAINT FK_LanguageFilm FOREIGN KEY (language_id) REFERENCES language(language_id) ON DELETE CASCADE;

-- film_actor 		(PK, FK): actor_id, film_id
ALTER TABLE film_actor ADD PRIMARY KEY (actor_id, film_id);
ALTER TABLE film_actor ADD CONSTRAINT FK_ActorFilm_Actor FOREIGN KEY (actor_id) REFERENCES actor(actor_id) ON DELETE CASCADE;
ALTER TABLE film_actor ADD CONSTRAINT FK_FilmFilm_Actor FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE CASCADE;

-- film_category 	(PK, FK): film_id, category_id
ALTER TABLE film_category ADD PRIMARY KEY (film_id, category_id);
ALTER TABLE film_category ADD CONSTRAINT FK_FilmFilm_Category FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE CASCADE;
ALTER TABLE film_category ADD CONSTRAINT FK_CategoryFilm_Category FOREIGN KEY (category_id) REFERENCES category(category_id) ON DELETE CASCADE;

-- inventory	PK: inventory_id FK: film_id, store_id
ALTER TABLE inventory ADD PRIMARY KEY (inventory_id);
ALTER TABLE inventory ADD CONSTRAINT FK_FilmInventory FOREIGN KEY (film_id) REFERENCES film(film_id) ON DELETE CASCADE;
ALTER TABLE inventory ADD CONSTRAINT FK_StoreInventory FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE CASCADE;

-- language 	PK: language_id
ALTER TABLE language ADD PRIMARY KEY (language_id);

-- payment 		PK: payment_id 		FK: customer_id, staff_id, rental_id
ALTER TABLE payment ADD PRIMARY KEY (payment_id);
ALTER TABLE payment ADD CONSTRAINT FK_customerPayment FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE;
ALTER TABLE payment ADD CONSTRAINT FK_StaffPayment FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE;
ALTER TABLE payment ADD CONSTRAINT FK_RentalPayment FOREIGN KEY (rental_id) REFERENCES rental(rental_id) ON DELETE CASCADE; 

-- rental 		PK: rental_id 		FK: staff_id 		U: rental_date 		(U, FK): inventory_id, customer_id
ALTER TABLE rental ADD PRIMARY KEY (rental_id);
ALTER TABLE rental ADD CONSTRAINT FK_StaffRental FOREIGN KEY (staff_id) REFERENCES staff(staff_id) ON DELETE CASCADE;
ALTER TABLE rental ADD CONSTRAINT UC_Rental UNIQUE (rental_date);
ALTER TABLE rental ADD CONSTRAINT UC_InventoryCustomer UNIQUE (inventory_id, customer_id);
ALTER TABLE rental ADD CONSTRAINT FK_InventoryRental FOREIGN KEY (inventory_id) REFERENCES inventory(inventory_id) ON DELETE CASCADE;
ALTER TABLE rental ADD CONSTRAINT FK_customerRental FOREIGN KEY (customer_id) REFERENCES customer(customer_id) ON DELETE CASCADE;

-- staff		PK: staff_id 		FK: address_id, store_id
ALTER TABLE staff ADD PRIMARY KEY (staff_id);
ALTER TABLE staff ADD CONSTRAINT FK_AddressStaff FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE CASCADE;
ALTER TABLE staff ADD CONSTRAINT FK_StoreStaff FOREIGN KEY (store_id) REFERENCES store(store_id) ON DELETE CASCADE;

-- store		PK: store_id 		FK: address_id
ALTER TABLE store ADD PRIMARY KEY (store_id);
ALTER TABLE store ADD CONSTRAINT FK_AddressStore FOREIGN KEY (address_id) REFERENCES address(address_id) ON DELETE CASCADE;

-- Category names come from the set {Animation, Comedy, Family, Foreign, Sci-Fi, Travel, Children, Drama, Horror, Action, Classics, Games, New, Documentary, Sports, Music}
ALTER TABLE category ADD CONSTRAINT Chk_CategoryName 
CHECK (name IN ('Animation', 'Comedy', 'Family', 'Foreign', 'Sci-Fi', 'Travel', 'Children', 'Drama', 'Horror', 'Action', 'Classics', 'Games', 'New', 'Documentary', 'Sports', 'Music'));

-- A film’s special_features attribute comes from the set {Behind the Scenes, Commentaries, Deleted Scenes, Trailers}
ALTER TABLE film ADD CONSTRAINT Chk_FilmSpecialFeatures
CHECK (special_features IN ('Behind the Scenes', 'Commentaries', 'Deleted Scenes', 'Trailers'));

-- All dates must be valid
ALTER TABLE payment MODIFY COLUMN payment_date DATETIME;
ALTER TABLE rental MODIFY COLUMN rental_date DATETIME;
ALTER TABLE rental MODIFY COLUMN return_date DATETIME;

-- Active is from the set {0,1} where 1 means active and 0 inactive
ALTER TABLE customer ADD CONSTRAINT Chk_CustomerActive CHECK (active IN (0, 1));

-- Rental duration is a positive number of days between 2 and 8
ALTER TABLE film ADD CONSTRAINT Chk_FilmRentalDuration CHECK (rental_duration >= 2 AND rental_duration <= 8);

-- Rental rate per day is between 0.99 and 6.99 
ALTER TABLE film ADD CONSTRAINT Chk_FilmRentalRate CHECK (rental_rate >= 0.99 AND rental_rate <= 6.99);

-- Film length is between 30 and 200 minutes 
ALTER TABLE film ADD CONSTRAINT Chk_FilmLength CHECK (length >= 30 AND length <= 200);

-- Ratings are {PG, G, NC-17, PG-13, R}
ALTER TABLE film ADD CONSTRAINT Chk_FilmRating CHECK (rating IN ('PG', 'G', 'NC-17', 'PG-13', 'R'));

-- Replacement cost is between 5.00 and 100.00 
ALTER TABLE film ADD CONSTRAINT Chk_FilmReplacementCost CHECK (replacement_cost >= 5.00 AND replacement_cost <= 100.00);

-- Amount should be >= 0 
ALTER TABLE payment ADD CONSTRAINT Chk_PaymentAmount CHECK (amount >= 0);

/** QUERIES */
-- 1. What is the average length of films in each category? List the results in alphabetic order of categories. 
SELECT c.name, ROUND(AVG(f.length), 2) AS avg_length 
FROM film f 
JOIN film_category fc ON f.film_id = fc.film_id
JOIN category c ON fc.category_id = c.category_id
GROUP BY c.name
ORDER BY c.name;

-- 2. Which categories have the longest and shortest average film lengths? 
WITH MaxFilmLength AS (
	SELECT c.name AS category, ROUND(AVG(f.length), 2) AS avg_film_length, 'Longest' AS length_type
    FROM film f 
	JOIN film_category fc ON f.film_id = fc.film_id
	JOIN category c ON fc.category_id = c.category_id
	GROUP BY c.name
	ORDER BY avg_film_length DESC
	LIMIT 1
), MinFilmLength AS (
	SELECT c.name AS category, ROUND(AVG(f.length), 2) AS avg_film_length, 'Shortest' AS length_type
	FROM film f 
	JOIN film_category fc ON f.film_id = fc.film_id
	JOIN category c ON fc.category_id = c.category_id
	GROUP BY c.name
	ORDER BY avg_film_length
	LIMIT 1
) SELECT * FROM MaxFilmLength UNION SELECT * FROM MinFilmLength;

-- 3. Which customers have rented action but not comedy or classic movies? 
WITH CustomersAction AS (
	SELECT r.customer_id 
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Action'
    GROUP BY r.customer_id
), CustomersComedyClassic AS (
	SELECT r.customer_id 
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    JOIN category c ON fc.category_id = c.category_id
    WHERE c.name = 'Comedy' OR c.name = 'Classic'
    GROUP BY r.customer_id
) 
SELECT ca.customer_id, c.last_name, c.first_name 
FROM CustomersAction ca 
JOIN customer c ON ca.customer_id = c.customer_id 
WHERE ca.customer_id NOT IN (SELECT * FROM CustomersComedyClassic) 
ORDER BY ca.customer_id;

-- 4. Which actor has appeared in the most English-language movies? 
WITH EnglishMovies AS (
	SELECT f.film_id 
    FROM film f 
    JOIN language l ON f.language_id = l.language_id
    WHERE l.name = 'English'
) 
SELECT fa.actor_id, a.last_name, a.first_name, COUNT(fa.film_id) AS num_english_movies 
FROM film_actor fa
JOIN actor a ON fa.actor_id = a.actor_id
WHERE film_id IN (SELECT * FROM EnglishMovies) 
GROUP BY actor_id 
ORDER BY num_english_movies DESC LIMIT 1;

-- 5. How many distinct movies were rented for exactly 10 days from the store where Mike works? 
SELECT DISTINCT COUNT(i.film_id) AS num_movies
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
WHERE DATEDIFF(r.return_date, r.rental_date) = 10
AND i.store_id IN (SELECT store_id FROM staff WHERE first_name = 'Mike');

-- 6. Alphabetically list actors who appeared in the movie with the largest cast of actors.
WITH LargestCast AS (
	SELECT film_id, COUNT(actor_id) AS cast_num 
    FROM film_actor 
    GROUP BY film_id 
    ORDER BY cast_num DESC LIMIT 1
)
SELECT a.last_name, a.first_name
FROM actor a 
JOIN film_actor fa ON a.actor_id = fa.actor_id
WHERE fa.film_id IN (SELECT film_id FROM LargestCast)
ORDER BY a.last_name;
