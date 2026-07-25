/*
===========================================================
Project : Olist Brazilian E-commerce Analysis
Section : Review & Satisfaction Analysis
Database: PostgreSQL
===========================================================
*/

-- ===========================================================
-- Q1. What is the average customer review score?
-- Purpose: Measure overall customer satisfaction based on review scores.
-- ===========================================================

SELECT
    ROUND(AVG(r.review_score), 2) AS avg_customer_review_score
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- ===========================================================
-- Q2. How many reviews were received for each review score (1–5 stars)?
-- Purpose: Analyze the distribution of customer review ratings.
-- ===========================================================

SELECT
    r.review_score,
    COUNT(*) AS total_reviews
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY r.review_score
ORDER BY total_reviews ASC;

-- ===========================================================
-- Q3. What percentage of reviews are 5-star reviews?
-- Purpose: Measure the share of highly satisfied customer reviews.
-- ===========================================================

SELECT
    ROUND(
        (
            COUNT(CASE WHEN r.review_score = 5 THEN 1 END) * 100.0
        ) /
        COUNT(*),
        2
    ) AS percentage_5_stars
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered';

-- ===========================================================
-- Q4. What is the average review score for each product category?
-- Purpose: Compare customer satisfaction across product categories.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    ROUND(
        AVG(r.review_score)::numeric,
        2
    ) AS avg_review_score
FROM category_translation ct
JOIN products p
    ON ct.product_category_name = p.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY avg_review_score;

-- ===========================================================
-- Q5. Which sellers have the lowest average review score?
-- Purpose: Identify sellers with the lowest customer satisfaction.
-- ===========================================================

SELECT
    s.seller_id,
    COUNT(r.review_id) AS total_reviews,
    ROUND(
        AVG(r.review_score)::numeric,
        2
    ) AS lowest_avg_review_score
FROM sellers s
JOIN order_items oi
    ON oi.seller_id = s.seller_id
JOIN orders o
    ON oi.order_id = o.order_id
JOIN reviews r
    ON o.order_id = r.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
HAVING COUNT(r.review_id) >= 20
ORDER BY lowest_avg_review_score ASC;

-- ===========================================================
-- Q6. How many reviews were received each month?
-- Purpose: Analyze monthly review volume.
-- ===========================================================

SELECT
    DATE_TRUNC('month', review_creation_date::timestamp) AS month,
    COUNT(*) AS total_reviews
FROM reviews
GROUP BY DATE_TRUNC('month', review_creation_date::timestamp)
ORDER BY month;

-- ===========================================================
-- Q7. Which product categories receive the highest number of 1-star reviews?
-- Purpose: Identify categories generating the most dissatisfied customers.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    COUNT(*) AS one_star_reviews
FROM category_translation ct
JOIN products p
    ON ct.product_category_name = p.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON o.order_id = oi.order_id
JOIN reviews r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
  AND r.review_score = 1
GROUP BY ct.product_category_name_english
ORDER BY one_star_reviews DESC;

-- ===========================================================
-- Q8. Which product categories have the highest average review score?
-- Purpose: Identify the highest-rated product categories.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    COUNT(r.review_id) AS total_reviews,
    ROUND(
        AVG(r.review_score)::numeric,
        2
    ) AS avg_review_score
FROM category_translation ct
JOIN products p
    ON ct.product_category_name = p.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON o.order_id = oi.order_id
JOIN reviews r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
HAVING COUNT(r.review_id) >= 20
ORDER BY avg_review_score DESC;

-- ===========================================================
-- Q9. Which sellers have the highest average review score?
-- Purpose: Identify the highest-rated sellers.
-- ===========================================================

SELECT
    s.seller_id,
    COUNT(r.review_id) AS total_reviews,
    ROUND(
        AVG(r.review_score)::numeric,
        2
    ) AS avg_review_score
FROM sellers s
JOIN order_items oi
    ON s.seller_id = oi.seller_id
JOIN orders o
    ON o.order_id = oi.order_id
JOIN reviews r
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY s.seller_id
HAVING COUNT(r.review_id) >= 20
ORDER BY
    avg_review_score DESC,
    total_reviews DESC;

-- ===========================================================
-- Q10. Which months have the highest average customer review score?
-- Purpose: Analyze monthly customer satisfaction trends.
-- ===========================================================

SELECT
    DATE_TRUNC('month', review_creation_date::timestamp) AS month,
    COUNT(review_id) AS total_reviews,
    ROUND(
        AVG(review_score)::numeric,
        2
    ) AS avg_customer_review
FROM reviews
GROUP BY month
HAVING COUNT(review_id) >= 20
ORDER BY month;

-- ===========================================================
-- Q11. Do customers who wait longer for delivery tend to give lower review scores?
-- Purpose: Analyze the relationship between delivery time and customer satisfaction.
-- ===========================================================

SELECT
    r.review_score,
    ROUND(
        AVG(
            EXTRACT(
                DAY FROM (
                    o.order_delivered_customer_date::timestamp -
                    o.order_purchase_timestamp::timestamp
                )
            )
        )::numeric,
        2
    ) AS avg_delivery_days
FROM reviews r
JOIN orders o
    ON r.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY r.review_score
ORDER BY avg_delivery_days DESC;
