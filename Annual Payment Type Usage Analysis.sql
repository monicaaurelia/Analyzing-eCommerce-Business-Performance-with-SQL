/*Membuat tabel yang berisi informasi pendapatan/revenue perusahaan total untuk masing-masing tahun*/
CREATE TABLE revenue_per_year AS
SELECT
	DATE_PART('year', o.order_purchase_timestamp) AS year,
	SUM(oi.price + oi.freight_value) AS revenue
FROM orders_dataset AS o
JOIN order_items_dataset AS oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY 1
ORDER BY year ASC;

/*Membuat tabel yang berisi informasi jumlah cancel order total untuk masing-masing tahun*/
CREATE TABLE cancel_per_year AS
SELECT
	DATE_PART('year', order_purchase_timestamp) AS year,
	COUNT(order_id) AS canceled_order
FROM orders_dataset
WHERE order_status = 'canceled'
GROUP BY 1
ORDER BY year ASC;

/*Membuat tabel yang berisi nama kategori produk yang memberikan pendapatan total tertinggi untuk masing-masing tahun*/
CREATE TABLE most_product_category_by_revenue_per_year AS
SELECT
	year,
	most_product_category_by_revenue,
	product_category_revenue
FROM(SELECT
		DATE_PART('year', o.order_purchase_timestamp) AS year,
	 	p.product_category_name AS most_product_category_by_revenue,
	 	SUM(price + freight_value) AS product_category_revenue,
	 	RANK() OVER(PARTITION BY DATE_PART('year', o.order_purchase_timestamp)
				    ORDER BY SUM(oi.price + oi.freight_value) DESC
					) AS rank
	 FROM orders_dataset AS o
	 JOIN order_items_dataset AS oi ON oi.order_id = o.order_id
	 JOIN product_dataset AS p ON p.product_id = oi.product_id
	 WHERE order_status = 'delivered'
	 GROUP BY 1, 2
	 ) AS subq
WHERE rank = 1;

/*Membuat tabel yang berisi nama kategori produk yang memiliki jumlah cancel order terbanyak untuk masing-masing tahun*/
CREATE TABLE most_canceled_product_category_by_per_year AS
SELECT
	year,
	most_canceled_product_category,
	canceled_product_category
FROM(SELECT
		DATE_PART('year', o.order_purchase_timestamp) AS year,
	 	p.product_category_name AS most_canceled_product_category,
	 	COUNT(o.order_id) AS canceled_product_category,
	 	RANK() OVER(PARTITION BY DATE_PART('year', order_purchase_timestamp)
				    ORDER BY COUNT(o.order_id) DESC
					) AS rank
	 FROM orders_dataset AS o
	 JOIN order_items_dataset AS oi ON oi.order_id = o.order_id
	 JOIN product_dataset AS p ON p.product_id = oi.product_id
	 WHERE order_status = 'canceled'
	 GROUP BY 1, 2
	 ) AS subq
WHERE rank = 1;

/*Menggabungkan informasi-informasi yang telah didapatkan ke dalam satu tampilan tabel*/
SELECT
	rpy.year,
	mpcbrpy.most_product_category_by_revenue,
	mpcbrpy.product_category_revenue,
	rpy.revenue AS total_revenue,
	mcpcbpy.most_canceled_product_category,
	mcpcbpy.canceled_product_category,
	cpy.canceled_order AS total_canceled_order
FROM revenue_per_year AS rpy
JOIN cancel_per_year AS cpy ON cpy.year = rpy.year
JOIN most_product_category_by_revenue_per_year AS mpcbrpy ON mpcbrpy.year = rpy.year
JOIN most_canceled_product_category_by_per_year AS mcpcbpy ON mcpcbpy.year = rpy.year;