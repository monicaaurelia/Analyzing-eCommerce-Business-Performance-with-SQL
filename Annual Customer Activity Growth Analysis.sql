/* Menampilkan rata-rata jumlah customer aktif bulanan (monthly active user) untuk setiap tahun*/

WITH MAU AS(
	SELECT
				DATE_PART('month', o.order_purchase_timestamp) AS month,
				DATE_PART('year', o.order_purchase_timestamp) AS year,
				COUNT(DISTINCT c.customer_unique_id) AS monthly_active_user
	FROM orders_dataset AS o
	JOIN customers_dataset AS c ON c.customer_id = o.customer_id
	GROUP BY 1, 2
			)
SELECT
	year,
	ROUND(AVG(monthly_active_user), 2) AS average_mau
FROM mau
GROUP BY 1
ORDER BY 1 ASC;

/*Menampilkan jumlah customer baru pada masing-masing tahun*/
WITH new_customers AS(SELECT
					  	MIN(o.order_purchase_timestamp) AS first_order,
					 	c.customer_unique_id
					  FROM orders_dataset AS o
					  JOIN customers_dataset AS c ON c.customer_id = o.customer_id
					  GROUP BY 2
					 )	
SELECT
	DATE_PART('year', first_order) AS year,
	COUNT(1) AS new_customers
FROM new_customers
GROUP BY 1
ORDER BY 1 ASC;

/*Menampilkan jumlah customer yang melakukan pembelian lebih dari satu kali (repeat order) pada masing-masing tahun*/
WITH repeat_order AS(SELECT
						DATE_PART('year', o.order_purchase_timestamp) AS year,
					 	c.customer_unique_id AS customer_repeat,
						COUNT(o.order_id) AS total_order
					FROM orders_dataset AS o
					JOIN customers_dataset AS c ON c.customer_id = o.customer_id
					GROUP BY 1, 2
					HAVING COUNT(o.order_id) > 1
					)
SELECT
	year,
	COUNT(DISTINCT customer_repeat) AS repeat_customers
FROM repeat_order
GROUP BY 1;


/*Menampilkan rata-rata jumlah order yang dilakukan customer untuk masing-masing tahun*/
WITH orders AS(SELECT
			  	c.customer_unique_id AS customer,
			   	DATE_PART('year', o.order_purchase_timestamp) AS year,
			   	COUNT(1) AS frequency_purchase
			  FROM orders_dataset AS o
			  JOIN customers_dataset AS c ON c.customer_id = o.customer_id
			  GROUP BY 1, 2
			  )
SELECT
	year,
	ROUND(AVG(frequency_purchase), 3) AS average_orders
FROM orders
GROUP BY 1
ORDER BY 1 ASC;


WITH mau AS(SELECT
				year,
				ROUND(AVG(monthly_active_user), 1) AS average_mau
			FROM(SELECT
				 	DATE_PART('month', o.order_purchase_timestamp) AS month,
				 	DATE_PART('year', o.order_purchase_timestamp) AS year,
				 	COUNT(DISTINCT c.customer_unique_id) AS monthly_active_user
				 FROM orders_dataset AS o
				 JOIN customers_dataset AS c ON c.customer_id = o.customer_id
				 GROUP BY 1, 2
				 ) AS subq
			GROUP BY 1
),
new_customers AS(SELECT
				 	year,
				 	COUNT(new_customers) AS new_customers
				 FROM(SELECT
					  	MIN(DATE_PART('year', o.order_purchase_timestamp)) AS year,
					 	c.customer_unique_id AS new_customers
					  FROM orders_dataset AS o
					  JOIN customers_dataset AS c ON c.customer_id = o.customer_id
					  GROUP BY 2
					  ) AS subq
				 GROUP BY 1
),
repeat_order AS(SELECT
					year,
					COUNT(DISTINCT customer_repeat) AS repeat_customers
				FROM(SELECT
					 	DATE_PART('year', o.order_purchase_timestamp) AS year,
					 	c.customer_unique_id AS customer_repeat,
						COUNT(o.order_id) AS total_order
					 FROM orders_dataset AS o
					 JOIN customers_dataset AS c ON c.customer_id = o.customer_id
					 GROUP BY 1, 2
					 HAVING COUNT(o.order_id) > 1
					 ) AS subq
				GROUP BY 1
),
avg_orders AS(SELECT
			  	year,
			  	AVG(total_order) AS average_orders
			  FROM(SELECT
				   	DISTINCT c.customer_unique_id AS customer,
				   	DATE_PART('year', o.order_purchase_timestamp) AS year,
			   		COUNT(DISTINCT o.order_id) AS total_order
				   FROM orders_dataset AS o
				   JOIN customers_dataset AS c ON c.customer_id = o.customer_id
				   GROUP BY 1, 2
				   ) AS subq
			  GROUP BY 1
)
SELECT 
	m.year AS year,
	average_mau,
	new_customers,
	repeat_customers,
	average_orders
FROM mau AS m
JOIN new_customers AS nc ON nc.year = m.year
JOIN repeat_order AS ro ON ro.year = m.year
JOIN avg_orders AS ao ON ao.year = m.year
GROUP BY 1, 2, 3, 4, 5;
