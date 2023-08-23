Use film_rental;
/* 1. What is the total revenue generated from all rentals in the database? */

Select sum(amount) as Total_revenue from payment;

/* 2. How many rentals were made in each month_name? */

SELECT monthname(rental_date) as Month_name,count(*) as Rental_per_month from rental GROUP BY month_name order by Rental_per_month desc;

/* 3. What is the rental rate of the film with the longest title in the database? */

SELECT Title,Rental_rate,length(title) as Title_length from film where length(title)=(SELECT max(length(title)) from film);

/* 4. What is the average rental rate for films that were taken from the last 30 days from the date("2005-05-05 22:04:30") ?  */

Select avg(rental_rate) as Avg_Rental_Rate from film f join rental r on f.film_id=r.rental_id where r.rental_date>=date_sub(date('2005-05-05 22:04:30'),interval '30' day);

/* 5. What is the most popular category of films in terms of the number of rentals? */

Select fc.Category_id,c.Name,count(*) as Most_rantal from film_category fc join category c on fc.category_id=c.category_id join film f on fc.film_id=f.film_id join inventory i on f.film_id=i.film_id
join rental r on i.inventory_id=r.inventory_id GROUP BY fc.category_id,c.name order by most_rantal desc limit 1;

/* 6. Find the longest movie duration from the list of films that have not been rented by any customer. */

SELECT MAX(film.length) AS longest_duration
FROM film WHERE film.film_id NOT IN (SELECT DISTINCT inventory.film_id FROM rental JOIN inventory ON rental.inventory_id = inventory.inventory_id);

/* 7.What is the average rental rate for films, broken down by category? */

SELECT c.name AS Category_name, AVG(f.rental_rate) AS Avg_rental_rate FROM film f JOIN film_category fc ON f.film_id = fc.film_id JOIN category c ON fc.category_id = c.category_id GROUP BY c.category_id;

/* 8. What is the total revenue generated from rentals for each actor in the database? */

SELECT actor.Actor_id, actor.First_name, actor.Last_name, SUM(film.rental_rate) AS Total_revenue FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id JOIN film ON film_actor.film_id = film.film_id 
JOIN inventory ON film.film_id = inventory.film_id JOIN rental ON inventory.inventory_id = rental.inventory_id 
GROUP BY actor.actor_id ORDER BY total_revenue DESC;

/* 9. Show all the actresses who worked in a film having a "Wrestler" in the description. */

SELECT DISTINCT actor.First_name, actor.Last_name FROM actor
JOIN film_actor ON actor.actor_id = film_actor.actor_id JOIN film ON film_actor.film_id = film.film_id
WHERE film.description LIKE '%Wrestler%';

/* 10. Which customers have rented the same film more than once? */

SELECT r.Customer_id,concat(first_name," ",last_name) as Customer_name,COUNT(*) as Rental_count
FROM rental r JOIN customer c ON r.customer_id = c.customer_id GROUP BY r.customer_id HAVING COUNT(*) > 1;

/* 11. How many films in the comedy category have a rental rate higher than the average rental rate? */

SELECT count(name) as Comedy_movies from category c join film_category fc on c.category_id=fc.category_id join film f on fc.film_id=f.film_id join inventory i on f.film_id=i.film_id join rental r on i.inventory_id=r.inventory_id
where f.rental_rate>(Select avg(rental_rate) from film) and c.name = "Comedy"; 

/* 12. Which films have been rented the most by customers living in each city? */

SELECT f.Title,c.City,count(f.film_id) as Most_rental From city c  join address ad on c.city_id=ad.city_id 
join customer cs on ad.address_id=cs.address_id join rental r on cs.customer_id=r.customer_id 
join inventory i on r.inventory_id=i.inventory_id join film f on i.film_id=f.film_id
GROUP BY f.title,c.city HAVING count(f.film_id)=(select max(Most_rental) as Most_rental FROM ( Select count(*) as Most_rental from city c 
join address ad on c.city_id=ad.city_id join customer cs on ad.address_id=cs.address_id join rental r on cs.customer_id=r.customer_id 
join inventory i on r.inventory_id=i.inventory_id join film f on i.film_id=f.film_id GROUP BY f.title,c.city) as Most_rental);

/* 13. What is the total amount spent by customers whose rental payments exceed $200? */

SELECT concat(first_name," ",last_name) as Customer_name,sum(amount) as Total_amount FROM customer c join payment p on c.customer_id=p.customer_id GROUP BY concat(first_name," ",last_name) having sum(amount)>200;

/* 14. Display the fields which are having foreign key constraints related to the "rental" table.[Hint: using Information_schema] */

SELECT CONSTRAINT_NAME, TABLE_NAME, COLUMN_NAME, REFERENCED_TABLE_NAME, REFERENCED_COLUMN_NAME 
FROM INFORMATION_SCHEMA.KEY_COLUMN_USAGE  WHERE REFERENCED_TABLE_NAME = 'rental';

/* 15. Create a View for the total revenue generated by each staff member, broken down by store city with the country name. */

CREATE VIEW Staff_revenue AS
SELECT s.Staff_id, concat(s.first_name," ",s.last_name) AS Name, c.City, co.Country, SUM(p.amount) AS Total_revenue FROM staff s
JOIN store st ON s.store_id = st.store_id JOIN address AS a ON st.address_id = a.address_id
JOIN city c ON a.city_id = c.city_id JOIN country AS co ON c.country_id = co.country_id
JOIN customer cust ON s.staff_id = cust.store_id JOIN payment AS p ON cust.customer_id = p.customer_id
GROUP BY s.staff_id, c.city ORDER BY s.staff_id, total_revenue DESC;
SELECT * FROM Staff_revenue;

/* 16. Create a view based on rental information consisting of visiting_day, customer_name, the title of the film,  no_of_rental_days, the amount paid by the customer along with the percentage of customer spending */

CREATE VIEW Rental_info AS SELECT DATE_FORMAT(r.rental_date, '%Y-%m-%d') AS Visiting_day, 
CONCAT(c.first_name, ' ', c.last_name) AS Customer_name,f.title AS Film_Title, 
DATEDIFF(r.return_date, r.rental_date) AS No_of_rental_days,p.amount AS Paid_amount, 
ROUND(p.amount / (SELECT SUM(amount) FROM payment WHERE customer_id = c.customer_id) * 100, 2) AS Percentage_spending
FROM rental r JOIN customer c ON r.customer_id = c.customer_id JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id JOIN payment p ON r.rental_id = p.rental_id;
SELECT * FROM rental_info;

/* 17.Display the customers who paid 50% of their total rental costs within one day. */

SELECT c.customer_id,concat(c.first_name," ",c.last_name) as customer_name,amount,r.rental_id FROM customer c JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id JOIN (SELECT rental_id,SUM(amount) AS total_rental_cost, DATEDIFF(MAX(payment_date), MIN(payment_date)) AS rental_duration FROM payment GROUP BY rental_id) AS rental_summary ON p.rental_id = rental_summary.rental_id
WHERE p.amount >= (0.5 * rental_summary.total_rental_cost) AND rental_summary.rental_duration = 0 ORDER BY customer_id;

SELECT c.customer_id,concat(c.first_name," ",c.last_name) as customer_name,amount,r.rental_id FROM customer c JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id where amount>=(0.5*amount) and datediff(payment_date,rental_date)=0 ORDER BY customer_id;

SELECT c.customer_id,concat(c.first_name," ",c.last_name) as customer_name,amount,r.rental_id FROM customer c JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id where amount>=(0.5*amount) and datediff(payment_date,rental_date)=0 group by c.customer_id,customer_name ORDER BY customer_id;

SELECT c.customer_id,concat(c.first_name," ",c.last_name) as customer_name FROM customer c JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id where amount>=(0.5*amount) and datediff(payment_date,rental_date)=0 group by c.customer_id,customer_name ORDER BY customer_id;

SELECT * FROM customer c JOIN payment p ON c.customer_id = p.customer_id
JOIN rental r ON p.rental_id = r.rental_id JOIN (SELECT rental_id,SUM(amount) AS total_rental_cost, DATEDIFF(MAX(payment_date), MIN(payment_date)) AS rental_duration FROM payment GROUP BY rental_id) AS rental_summary ON p.rental_id = rental_summary.rental_id
WHERE p.amount >= (0.5 * rental_summary.total_rental_cost) AND rental_summary.rental_duration = 0;