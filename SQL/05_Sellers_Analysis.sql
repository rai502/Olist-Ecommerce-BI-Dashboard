/*
===========================================================
Project : Olist Brazilian E-commerce Analysis
Section : Seller Analysis
Database: PostgreSQL
===========================================================
*/

-- ===========================================================
-- Q1. Which 10 sellers generated the highest revenue from delivered orders?
-- Purpose: Identify the top revenue-generating sellers.
-- ===========================================================

SELECT
    s.seller_id,
    SUM(oi.price) AS total_revenue
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
ORDER BY total_revenue DESC
LIMIT 10;

-- ===========================================================
-- Q2. Which 10 sellers fulfilled the highest number of delivered orders?
-- Purpose: Identify sellers with the highest delivered order volume.
-- ===========================================================

SELECT
    s.seller_id,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
ORDER BY total_delivered_orders DESC
LIMIT 10;

-- ===========================================================
-- Q3. Which 10 sellers sold the highest number of products in delivered orders?
-- Purpose: Identify sellers with the highest product sales volume.
-- ===========================================================

SELECT
    s.seller_id,
    COUNT(oi.order_item_id) AS total_products_sold
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
ORDER BY total_products_sold DESC
LIMIT 10;

-- ===========================================================
-- Q4. What is the Average Order Value (AOV) for each seller?
-- Purpose: Measure the average revenue generated per delivered order for each seller.
-- ===========================================================

WITH orders_value AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS seller_revenue,
        COUNT(DISTINCT o.order_id) AS seller_orders
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id
)

SELECT
    seller_id,
    seller_revenue,
    seller_orders,
    ROUND(
        (seller_revenue / seller_orders)::numeric,
        2
    ) AS average_order_value
FROM orders_value;

-- ===========================================================
-- Q5. What is the Average Selling Price (ASP) for each seller?
-- Purpose: Measure the average selling price of products sold by each seller.
-- ===========================================================

WITH selling_price AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS seller_revenue,
        COUNT(oi.order_item_id) AS products_sold
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id
)

SELECT
    seller_id,
    seller_revenue,
    products_sold,
    ROUND(
        (seller_revenue / products_sold)::numeric,
        2
    ) AS average_selling_price
FROM selling_price;

-- ===========================================================
-- Q6. Which sellers generated above-average seller revenue?
-- Purpose: Identify sellers whose revenue exceeds the marketplace average.
-- ===========================================================

WITH seller_revenue AS (
    SELECT
        s.seller_id,
        SUM(oi.price) AS total_revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY s.seller_id
)

SELECT
    seller_id,
    total_revenue
FROM seller_revenue
WHERE total_revenue > (
    SELECT AVG(total_revenue)
    FROM seller_revenue
)
ORDER BY total_revenue DESC;

-- ===========================================================
-- Q7. Which sellers have fulfilled more than 100 delivered orders?
-- Purpose: Identify high-volume sellers based on delivered orders.
-- ===========================================================

SELECT
    s.seller_id,
    COUNT(DISTINCT o.order_id) AS total_delivered_orders
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
HAVING COUNT(DISTINCT o.order_id) > 100;

-- ===========================================================
-- Q8. Find the highest revenue-generating seller in each state.
-- Purpose: Identify the top-performing seller in every seller state.
-- ===========================================================

WITH seller_revenue AS (
    SELECT
        s.seller_state,
        s.seller_id,
        SUM(oi.price) AS total_revenue
    FROM sellers s
    JOIN order_items oi
        ON s.seller_id = oi.seller_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        s.seller_state,
        s.seller_id
),
ranked_sellers AS (
    SELECT
        seller_state,
        seller_id,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY seller_state
            ORDER BY total_revenue DESC
        ) AS seller_rank
    FROM seller_revenue
)

SELECT
    seller_state,
    seller_id,
    total_revenue
FROM ranked_sellers
WHERE seller_rank = 1
ORDER BY seller_state;
