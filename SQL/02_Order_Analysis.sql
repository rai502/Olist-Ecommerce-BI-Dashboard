/*
===========================================================
Project : Olist Brazilian E-commerce Analysis
Section : Order Analysis
Database: PostgreSQL
===========================================================
*/

-- ===========================================================
-- Q1. How has delivered order volume changed month by month over time?
-- Purpose: Track monthly delivered order volume to identify business growth trends and seasonality.
-- ===========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
    COUNT(o.order_id) AS total_orders
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY month;

-- ===========================================================
-- Q2. Which month had the highest delivered order volume?
-- Purpose: Identify the month with the highest number of delivered orders.
-- ===========================================================

SELECT
    DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
    COUNT(o.order_id) AS total_orders
FROM orders o
WHERE o.order_status = 'delivered'
GROUP BY month
ORDER BY total_orders DESC
LIMIT 1;

-- ===========================================================
-- Q3. What percentage of total orders are delivered, cancelled, unavailable, shipped, or in other statuses?
-- Purpose: Analyze the distribution of order statuses to evaluate operational performance.
-- ===========================================================

SELECT
    order_status,
    COUNT(*) AS total_orders,
    ROUND(
        (COUNT(*) * 100.0) / SUM(COUNT(*)) OVER (),
        2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY total_orders DESC;

-- ===========================================================
-- Q4. Which months experienced the largest month-over-month drop in delivered order volume?
-- Purpose: Identify periods with significant declines in delivered orders.
-- ===========================================================

WITH monthly_orders AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
        COUNT(o.order_id) AS total_orders
    FROM orders o
    WHERE o.order_status = 'delivered'
    GROUP BY month
)

SELECT
    month,
    total_orders,
    LAG(total_orders) OVER (ORDER BY month) AS previous_month_order,
    total_orders - LAG(total_orders) OVER (ORDER BY month) AS order_change
FROM monthly_orders
ORDER BY order_change ASC;

-- ===========================================================
-- Q5. Which months had high order volume but below-average Average Order Value (AOV)?
-- Purpose: Identify months with strong order volume but weaker revenue per order.
-- ===========================================================

WITH monthly_order_volume AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
        COUNT(DISTINCT o.order_id) AS total_orders,
        SUM(oi.price) AS total_revenue,
        SUM(oi.price) / COUNT(o.order_id) AS monthly_aov
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY month
)

SELECT *
FROM monthly_order_volume
WHERE total_orders > (
    SELECT AVG(total_orders)
    FROM monthly_order_volume
)
AND monthly_aov < (
    SELECT AVG(monthly_aov)
    FROM monthly_order_volume
)
ORDER BY total_orders DESC;

-- ===========================================================
-- Q6. Which day of the week receives the highest number of delivered orders?
-- Purpose: Identify the busiest purchasing day of the week.
-- ===========================================================

SELECT
    TO_CHAR(order_purchase_timestamp::timestamp, 'Day') AS day_of_the_week,
    COUNT(order_id) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY day_of_the_week
ORDER BY total_orders DESC
LIMIT 1;

-- ===========================================================
-- Q7. Which hour of the day receives the highest number of delivered orders?
-- Purpose: Identify the busiest purchasing hour of the day.
-- ===========================================================

SELECT
    EXTRACT(HOUR FROM order_purchase_timestamp::timestamp) AS hour_of_the_day,
    COUNT(order_id) AS total_orders
FROM orders
WHERE order_status = 'delivered'
GROUP BY hour_of_the_day
ORDER BY total_orders DESC
LIMIT 1;

-- ===========================================================
-- Q8. What is the average number of orders placed per day?
-- Purpose: Measure the average daily order volume.
-- ===========================================================

WITH orders_per_day AS (
    SELECT
        order_purchase_timestamp::timestamp::date AS order_date,
        COUNT(*) AS total_orders
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY order_date
)

SELECT
    AVG(total_orders) AS average_orders_per_day
FROM orders_per_day;

-- ===========================================================
-- Q9. Which dates had unusually high order volume compared with the average daily order volume?
-- Purpose: Identify days with significantly higher order volume than the daily average.
-- ===========================================================

WITH orders_per_day AS (
    SELECT
        order_purchase_timestamp::timestamp::date AS order_date,
        COUNT(*) AS total_orders
    FROM orders
    WHERE order_status = 'delivered'
    GROUP BY order_date
)

SELECT
    order_date,
    total_orders
FROM orders_per_day
WHERE total_orders > (
    SELECT AVG(total_orders)
    FROM orders_per_day
)
ORDER BY total_orders DESC;

-- ===========================================================
-- Q10. How many orders contain multiple items versus only one item?
-- Purpose: Compare single-item and multi-item orders to understand customer purchasing behavior.
-- ===========================================================

WITH order_item_counts AS (
    SELECT
        order_id,
        COUNT(order_item_id) AS total_items
    FROM order_items
    GROUP BY order_id
),
order_classification AS (
    SELECT
        order_id,
        CASE
            WHEN total_items = 1 THEN 'Single_item_order'
            WHEN total_items > 1 THEN 'Multiple_item_order'
        END AS order_type
    FROM order_item_counts
)

SELECT
    order_type,
    COUNT(order_id) AS total_orders
FROM order_classification
GROUP BY order_type
ORDER BY total_orders DESC;

-- ===========================================================
-- Q11. What is the average number of items per delivered order?
-- Purpose: Measure the average basket size of delivered orders.
-- ===========================================================

WITH delivered_order_items AS (
    SELECT
        oi.order_id,
        COUNT(oi.order_item_id) AS total_items
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.order_id
)

SELECT
    AVG(total_items) AS avg_basket_size
FROM delivered_order_items;

-- ===========================================================
-- Q12. Calculate the average basket size for each month.
-- Purpose: Analyze monthly purchasing behavior by measuring the average number of items per delivered order.
-- ===========================================================

WITH order_items_count AS (
    SELECT
        oi.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
        COUNT(oi.order_item_id) AS total_items
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        oi.order_id,
        month
)

SELECT
    month,
    AVG(total_items) AS avg_basket_size
FROM order_items_count
GROUP BY month
ORDER BY month;

-- ===========================================================
-- Q13. Which months had the highest percentage of multi-item orders?
-- Purpose: Identify months where customers were most likely to purchase multiple items in a single order.
-- ===========================================================

WITH order_items_count AS (
    SELECT
        oi.order_id,
        DATE_TRUNC('month', o.order_purchase_timestamp::timestamp) AS month,
        COUNT(oi.order_item_id) AS total_items
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        oi.order_id,
        month
)

SELECT
    month,
    COUNT(*) AS total_orders,
    COUNT(
        CASE
            WHEN total_items > 1 THEN 1
        END
    ) AS multi_item_orders,
    ROUND(
        COUNT(
            CASE
                WHEN total_items > 1 THEN 1
            END
        ) * 100.0 / COUNT(*),
        2
    ) AS multi_item_percentage
FROM order_items_count
GROUP BY month
ORDER BY multi_item_percentage DESC;
