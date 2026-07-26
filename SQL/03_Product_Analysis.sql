/*
===========================================================
Project : Olist Brazilian E-commerce Analysis
Section : Product Performance Analysis
Database: PostgreSQL
===========================================================
*/

-- ===========================================================
-- Q1. Which 10 products sold the highest number of items among delivered orders?
-- Purpose: Identify the products with the highest sales volume based on delivered items.
-- ===========================================================

SELECT
    oi.product_id,
    COUNT(oi.order_item_id) AS total_number_of_items
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY total_number_of_items DESC
LIMIT 10;

-- ===========================================================
-- Q2. Which 10 products appeared in the highest number of unique delivered orders?
-- Purpose: Identify products purchased across the highest number of unique delivered orders.
-- ===========================================================

SELECT
    oi.product_id,
    COUNT(DISTINCT oi.order_id) AS total_unique_orders
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY total_unique_orders DESC
LIMIT 10;

-- ===========================================================
-- Q3. Which 10 products generated the highest revenue from delivered orders?
-- Purpose: Identify the highest revenue-generating products.
-- ===========================================================

SELECT
    oi.product_id,
    SUM(oi.price) AS total_revenue
FROM order_items oi
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- ===========================================================
-- Q4. Which 10 products generated the highest revenue, and how many items did each product sell?
-- Purpose: Compare revenue and sales volume for the top-performing products.
-- ===========================================================

SELECT
    oi.product_id,
    SUM(oi.price) AS total_revenue,
    COUNT(oi.order_item_id) AS total_items
FROM order_items oi
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY total_revenue DESC
LIMIT 10;

-- ===========================================================
-- Q5. Which 10 products have the highest Average Selling Price (ASP) among delivered orders?
-- Purpose: Identify products with the highest average selling price.
-- ===========================================================

SELECT
    oi.product_id,
    SUM(oi.price) / COUNT(oi.order_item_id) AS average_selling_price
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
ORDER BY average_selling_price DESC
LIMIT 10;

-- ===========================================================
-- Q6. Which 10 products have the highest ASP among products that sold at least 10 items?
-- Purpose: Identify premium products with meaningful sales volume.
-- ===========================================================

SELECT
    oi.product_id,
    SUM(oi.price) / COUNT(oi.order_item_id) AS average_selling_price
FROM order_items oi
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY oi.product_id
HAVING COUNT(oi.order_item_id) >= 10
ORDER BY average_selling_price DESC
LIMIT 10;

-- ===========================================================
-- Q7. Which product categories have high sales volume but relatively low ASP?
-- Purpose: Identify categories that sell many items while maintaining a relatively low average selling price.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    COUNT(oi.order_id) AS sales_volume,
    SUM(oi.price) / COUNT(oi.order_item_id) AS average_selling_price
FROM products p
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY
    sales_volume DESC,
    average_selling_price ASC;

-- ===========================================================
-- Q8. What percentage of total delivered revenue does each product category contribute?
-- Purpose: Measure each product category's contribution to overall marketplace revenue.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    SUM(oi.price) AS category_revenue,
    ROUND(
        (
            SUM(oi.price) /
            SUM(SUM(oi.price)) OVER () * 100
        )::numeric,
        2
    ) AS revenue_percentage
FROM products p
JOIN category_translation ct
    ON p.product_category_name = ct.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY revenue_percentage DESC;

-- ===========================================================
-- Q9. How many unique products were sold in each product category?
-- Purpose: Measure product variety within each product category.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    COUNT(DISTINCT oi.product_id) AS unique_products
FROM category_translation ct
JOIN products p
    ON ct.product_category_name = p.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY unique_products DESC;

-- ===========================================================
-- Q10. Which product categories generate the highest revenue per unique product sold?
-- Purpose: Identify categories that generate the most revenue per unique product.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    SUM(oi.price) / COUNT(DISTINCT oi.product_id) AS revenue_per_unique_product
FROM category_translation ct
JOIN products p
    ON ct.product_category_name = p.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
ORDER BY revenue_per_unique_product DESC;

-- ===========================================================
-- Q11. Show only categories where revenue per unique product sold is greater than R$5,000.
-- Purpose: Identify premium product categories with exceptionally high revenue per unique product.
-- ===========================================================

SELECT
    ct.product_category_name_english,
    SUM(oi.price) / COUNT(DISTINCT oi.product_id) AS revenue_per_unique_product
FROM category_translation ct
JOIN products p
    ON ct.product_category_name = p.product_category_name
JOIN order_items oi
    ON oi.product_id = p.product_id
JOIN orders o
    ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY ct.product_category_name_english
HAVING SUM(oi.price) / COUNT(DISTINCT oi.product_id) > 5000
ORDER BY revenue_per_unique_product DESC;

-- ===========================================================
-- Q12. Which product categories depend heavily on their top-selling product for revenue?
-- Purpose: Identify categories whose revenue relies heavily on a single top-performing product.
-- ===========================================================

WITH product_revenue AS (
    SELECT
        ct.product_category_name_english AS category,
        oi.product_id,
        SUM(oi.price) AS product_revenue
    FROM products p
    JOIN category_translation ct
        ON p.product_category_name = ct.product_category_name
    JOIN order_items oi
        ON oi.product_id = p.product_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        ct.product_category_name_english,
        oi.product_id
),
ranked_products AS (
    SELECT
        category,
        product_id,
        product_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY category
            ORDER BY product_revenue DESC
        ) AS product_rank
    FROM product_revenue
)

SELECT
    category,
    SUM(product_revenue) AS category_revenue,
    MAX(
        CASE
            WHEN product_rank = 1 THEN product_revenue
        END
    ) AS top_product_revenue,
    ROUND(
        (
            MAX(
                CASE
                    WHEN product_rank = 1 THEN product_revenue
                END
            ) /
            SUM(product_revenue) * 100
        )::numeric,
        2
    ) AS top_product_revenue_percentage
FROM ranked_products
GROUP BY category
ORDER BY top_product_revenue_percentage DESC;

-- ===========================================================
-- Q13. Find the highest revenue-generating product in each product category.
-- Purpose: Identify the best-performing product within every product category.
-- ===========================================================

WITH products_revenue AS (
    SELECT
        ct.product_category_name_english,
        oi.product_id,
        SUM(oi.price) AS product_revenue
    FROM category_translation ct
    JOIN products p
        ON ct.product_category_name = p.product_category_name
    JOIN order_items oi
        ON oi.product_id = p.product_id
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        ct.product_category_name_english,
        oi.product_id
),
ranked_products AS (
    SELECT
        product_category_name_english,
        product_id,
        product_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY product_category_name_english
            ORDER BY product_revenue DESC
        ) AS product_rank
    FROM products_revenue
)

SELECT
    product_category_name_english,
    product_id,
    product_revenue
FROM ranked_products
WHERE product_rank = 1;

-- ===========================================================
-- Q14. Which products generated above-average product revenue?
-- Purpose: Identify products that outperform the marketplace average in revenue generation.
-- ===========================================================

WITH revenue AS (
    SELECT
        oi.product_id,
        SUM(oi.price) AS product_revenue
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id
)

SELECT
    product_id,
    product_revenue
FROM revenue
WHERE product_revenue > (
    SELECT AVG(product_revenue)
    FROM revenue
);

-- ===========================================================
-- Q15. Which products have high sales volume but generate below-average product revenue?
-- Purpose: Identify frequently sold products that underperform in revenue generation.
-- ===========================================================

WITH revenue AS (
    SELECT
        oi.product_id,
        COUNT(oi.order_item_id) AS total_sales_volume,
        SUM(oi.price) AS total_revenue
    FROM order_items oi
    JOIN orders o
        ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY oi.product_id
)

SELECT
    product_id,
    total_sales_volume,
    total_revenue
FROM revenue
WHERE total_sales_volume > (
    SELECT AVG(total_sales_volume)
    FROM revenue
)
AND total_revenue < (
    SELECT AVG(total_revenue)
    FROM revenue
);
