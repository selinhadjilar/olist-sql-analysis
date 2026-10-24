   CREATE TABLE orders (
     order_id TEXT PRIMARY KEY,
     customer_id TEXT,
     order_status TEXT,
     order_purchase_timestamp TIMESTAMP,
     order_approved_at TIMESTAMP,
     order_delivered_carrier_date TIMESTAMP,
     order_delivered_customer_date TIMESTAMP,
     order_estimated_delivery_date TIMESTAMP
   );

CREATE TABLE customers (
  customer_id TEXT PRIMARY KEY,
  customer_unique_id TEXT,
  customer_zip_code_prefix TEXT,
  customer_city TEXT,
  customer_state TEXT
);

CREATE TABLE order_items (
  order_id TEXT,
  order_item_id INT,
  product_id TEXT,
  seller_id TEXT,
  shipping_limit_date TIMESTAMP,
  price NUMERIC(10,2),
  freight_value NUMERIC(10,2),
  PRIMARY KEY (order_id, order_item_id)
);

CREATE TABLE order_payments (
  order_id TEXT,
  payment_sequential INT,
  payment_type TEXT,
  payment_installments INT,
  payment_value NUMERIC(10,2),
  PRIMARY KEY (order_id, payment_sequential)
);

CREATE TABLE order_reviews (
  review_id TEXT,
  order_id TEXT,
  review_score INT,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date TIMESTAMP,
  review_answer_timestamp TIMESTAMP
);

SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'order_payments', COUNT(*) FROM order_payments;
SELECT COUNT(*) FROM order_reviews;

WITH monthly AS (
  SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
    SUM(oi.price) AS revenue,
    COUNT(DISTINCT o.order_id) AS orders
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status = 'delivered'
    AND o.order_purchase_timestamp >= '2017-01-01'
    AND o.order_purchase_timestamp <  '2018-09-01'
  GROUP BY 1
)
SELECT
  month,
  revenue,
  orders,
  ROUND(100.0 * (revenue - LAG(revenue) OVER (ORDER BY month))
        / LAG(revenue) OVER (ORDER BY month), 1) AS pct_change
FROM monthly
ORDER BY month;

SELECT
  DATE(o.order_purchase_timestamp) AS day,
  COUNT(DISTINCT o.order_id) AS orders,
  SUM(oi.price) AS revenue
FROM orders o
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND o.order_purchase_timestamp >= '2017-11-01'
  AND o.order_purchase_timestamp <  '2017-12-01'
GROUP BY 1
ORDER BY revenue DESC
LIMIT 5;


SELECT 
	c.customer_state, 
	COUNT(DISTINCT c.customer_unique_id) AS customers,
	COUNT(DISTINCT o.order_id) AS orders,
  	SUM(oi.price) AS revenue,
	ROUND(SUM(oi.price) / COUNT(DISTINCT o.order_id), 2) AS revenue_per_order
FROM orders o 
JOIN customers c ON c.customer_id = o.customer_id
JOIN order_items oi ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY revenue DESC;

WITH delivered AS (
  SELECT order_id,
         order_delivered_customer_date > order_estimated_delivery_date AS is_late
  FROM orders
  WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
),
rev AS (
  SELECT order_id, AVG(review_score) AS score
  FROM order_reviews
  GROUP BY order_id
)
SELECT
  d.is_late,
  COUNT(*) AS orders,
  ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 1) AS pct_of_orders,
  ROUND(AVG(r.score), 2) AS avg_review_score
FROM delivered d
LEFT JOIN rev r ON r.order_id = d.order_id
GROUP BY d.is_late;

WITH d AS (
  SELECT o.order_id,
         EXTRACT(EPOCH FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)) / 86400.0 AS days_late
  FROM orders o
  WHERE o.order_status = 'delivered' AND o.order_delivered_customer_date IS NOT NULL
),
rev AS (SELECT order_id, AVG(review_score) AS score FROM order_reviews GROUP BY order_id)
SELECT
  CASE WHEN days_late <= 0 THEN '0 on time/early'
       WHEN days_late <= 3 THEN '1-3 late'
       WHEN days_late <= 7 THEN '4-7 late'
       ELSE '8+ late' END AS bucket,
  COUNT(*) AS orders,
  ROUND(AVG(r.score), 2) AS avg_score
FROM d LEFT JOIN rev r ON r.order_id = d.order_id
GROUP BY 1 ORDER BY 1;

SELECT
  p.payment_type,
  COUNT(DISTINCT p.order_id) AS orders,
  ROUND(SUM(p.payment_value), 0) AS total_paid,
  ROUND(AVG(p.payment_value), 2) AS avg_payment,
  ROUND(AVG(p.payment_installments), 1) AS avg_installments
FROM order_payments p
JOIN orders o ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY p.payment_type
ORDER BY total_paid DESC;

WITH per_customer AS (
  SELECT c.customer_unique_id, COUNT(DISTINCT o.order_id) AS orders
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
)
SELECT
  COUNT(*) AS customers,
  COUNT(*) FILTER (WHERE orders > 1) AS repeat_customers,
  ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1) / COUNT(*), 1) AS repeat_pct
FROM per_customer;

WITH spend AS (
  SELECT c.customer_unique_id,
         SUM(oi.price) AS total_spend
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
),
ranked AS (
  SELECT *, NTILE(10) OVER (ORDER BY total_spend DESC) AS decile
  FROM spend
)
SELECT
  decile,
  COUNT(*) AS customers,
  ROUND(SUM(total_spend), 0) AS revenue,
  ROUND(100.0 * SUM(total_spend) / SUM(SUM(total_spend)) OVER (), 1) AS pct_of_revenue,
  ROUND(AVG(total_spend), 2) AS avg_spend
FROM ranked
GROUP BY decile
ORDER BY decile;

WITH per_customer AS (
  SELECT c.customer_unique_id,
         COUNT(DISTINCT o.order_id) AS orders,
         SUM(oi.price) AS total_spend
  FROM orders o
  JOIN customers c ON c.customer_id = o.customer_id
  JOIN order_items oi ON oi.order_id = o.order_id
  WHERE o.order_status = 'delivered'
  GROUP BY 1
),
ranked AS (
  SELECT *, NTILE(10) OVER (ORDER BY total_spend DESC) AS decile
  FROM per_customer
)
SELECT
  decile,
  ROUND(100.0 * COUNT(*) FILTER (WHERE orders > 1) / COUNT(*), 1) AS repeat_pct
FROM ranked
WHERE decile IN (1, 10)
GROUP BY decile
ORDER BY decile;