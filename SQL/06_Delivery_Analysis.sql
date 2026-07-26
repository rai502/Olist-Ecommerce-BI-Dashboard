/*
===========================================================
Project : Olist Brazilian E-commerce Analysis
Section : Delivery Analysis
Database: PostgreSQL
===========================================================
*/

-- ===========================================================
-- Q1. What is the average number of days taken to deliver a delivered order?
-- Purpose: Measure the average end-to-end delivery time.
-- ===========================================================

SELECT
    ROUND(
        AVG(
            DATE_PART(
                'day',
                order_delivered_customer_date - order_purchase_timestamp
            )
        )::numeric,
        2
    ) AS avg_delivery_days
FROM orders
WHERE order_status = 'delivered';

-- ===========================================================
-- Q2. What is the average shipping time (in days)?
-- Purpose: Measure the average time taken for sellers to ship orders.
-- ===========================================================

SELECT
    ROUND(
        AVG(
            DATE_PART(
                'day',
                order_delivered_carrier_date - order_purchase_timestamp
            )
        )::numeric,
        2
    ) AS avg_shipping_days
FROM orders
WHERE order_status = 'delivered';

-- ===========================================================
-- Q3. What is the average transit time (in days)?
-- Purpose: Measure the average time between carrier pickup and customer delivery.
-- ===========================================================

SELECT
    ROUND(
        AVG(
            DATE_PART(
                'day',
                order_delivered_customer_date - order_delivered_carrier_date
            )
        )::numeric,
        2
    ) AS avg_transit_time
FROM orders
WHERE order_status = 'delivered';

-- ===========================================================
-- Q4. How many delivered orders were delivered late?
-- Purpose: Compare late deliveries with on-time deliveries.
-- ===========================================================

SELECT
    COUNT(*) AS total_orders,
    COUNT(
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
            THEN 1
        END
    ) AS late_orders,
    COUNT(
        CASE
            WHEN order_delivered_customer_date <= order_estimated_delivery_date
            THEN 1
        END
    ) AS on_time_orders
FROM orders
WHERE order_status = 'delivered';

-- ===========================================================
-- Q5. What is the Late Delivery Rate (%)?
-- Purpose: Measure the percentage of delivered orders that arrived late.
-- ===========================================================

WITH delivery AS (
    SELECT
        COUNT(*) AS late_deliveries_count
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date > order_estimated_delivery_date
),
delivery_orders AS (
    SELECT
        COUNT(*) AS total_delivered_orders
    FROM orders
    WHERE order_status = 'delivered'
)
SELECT
    d.late_deliveries_count,
    t.total_delivered_orders,
    ROUND(
        (
            late_deliveries_count * 100.0 /
            total_delivered_orders
        )::numeric,
        2
    ) AS late_delivery_rate
FROM delivery d
CROSS JOIN delivery_orders t;

-- ===========================================================
-- Q6. What is the On-Time Delivery Rate (%)?
-- Purpose: Measure the percentage of orders delivered on or before the estimated delivery date.
-- ===========================================================

WITH delivery AS (
    SELECT
        COUNT(*) AS on_time_delivery
    FROM orders
    WHERE order_status = 'delivered'
      AND order_delivered_customer_date <= order_estimated_delivery_date
),
delivery_orders AS (
    SELECT
        COUNT(*) AS total_delivered_orders
    FROM orders
    WHERE order_status = 'delivered'
)
SELECT
    d.on_time_delivery,
    t.total_delivered_orders,
    ROUND(
        (
            on_time_delivery * 100.0 /
            total_delivered_orders
        )::numeric,
        2
    ) AS on_time_delivery_rate
FROM delivery d
CROSS JOIN delivery_orders t;

-- ===========================================================
-- Q7. Which states have the highest average delivery time?
-- Purpose: Identify states with the slowest delivery performance.
-- ===========================================================

SELECT
    c.customer_state,
    ROUND(
        AVG(
            DATE_PART(
                'day',
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )
        )::numeric,
        2
    ) AS avg_delivery_time
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY avg_delivery_time DESC;

-- ===========================================================
-- Q8. Do late-delivered orders receive lower review scores?
-- Purpose: Compare review scores for late and on-time deliveries.
-- ===========================================================

WITH delivery_status AS (
    SELECT
        order_id,
        CASE
            WHEN order_delivered_customer_date > order_estimated_delivery_date
                THEN 'Late'
            ELSE 'On Time/Early'
        END AS delivery_status
    FROM orders
    WHERE order_status = 'delivered'
)
SELECT
    ds.delivery_status,
    ROUND(AVG(r.review_score), 2) AS avg_review_score
FROM delivery_status ds
JOIN reviews r
    ON ds.order_id = r.order_id
GROUP BY ds.delivery_status;

-- ===========================================================
-- Q9. Top 10 Slowest Cities by Average Delivery Time
-- Purpose: Identify cities with the longest average delivery time.
-- ===========================================================

SELECT
    c.customer_city,
    COUNT(*) AS delivered_orders,
    ROUND(
        AVG(
            DATE_PART(
                'day',
                o.order_delivered_customer_date - o.order_purchase_timestamp
            )
        )::numeric,
        2
    ) AS avg_delivery_time
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_city
HAVING COUNT(*) >= 50
ORDER BY avg_delivery_time DESC
LIMIT 10;

-- ===========================================================
-- Q10. How has the average delivery time changed month by month?
-- Purpose: Analyze monthly delivery performance trends.
-- ===========================================================

SELECT
    DATE_TRUNC('month', order_purchase_timestamp) AS month,
    ROUND(
        AVG(
            DATE_PART(
                'day',
                order_delivered_customer_date - order_purchase_timestamp
            )
        )::numeric,
        2
    ) AS avg_delivery_time
FROM orders
WHERE order_status = 'delivered'
GROUP BY DATE_TRUNC('month', order_purchase_timestamp)
ORDER BY month;
