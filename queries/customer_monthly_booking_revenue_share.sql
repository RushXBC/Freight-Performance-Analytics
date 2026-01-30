/*
    Purpose: Calculate and analyze each customer's contribution to monthly revenue by booking type.
    - Aggregate revenue per customer per month, segmented by customer type and booking type.
    - Compute the total revenue per booking type for each month to determine proportional contribution.
    - Calculate the percentage share of revenue for each customer within their booking type per month.
    - This analysis helps identify which customers drive revenue in each booking category and month.
*/

-- Step 1: Collect all relevant customer and load revenue data
WITH customer_revenue AS
(
    SELECT
        c.customer_id,
        l.load_id,
        c.customer_name,
        c.customer_type,
        l.booking_type,
        YEAR(l.load_date) AS year,
        MONTH(l.load_date) AS month,
        l.revenue
    FROM customers AS c
    LEFT JOIN loads AS l
        ON c.customer_id = l.customer_id
),

-- Step 2: Calculate total revenue per booking type per month for comparison
load_share AS
(
    SELECT
        customer_id,
        load_id,
        customer_name,
        customer_type,
        booking_type,
        year,
        month,
        revenue AS revenue_per_load,
        -- Total revenue per booking type for that month
        SUM(revenue) OVER (PARTITION BY customer_type, booking_type, year, month) AS monthly_booking_type_revenue
    FROM customer_revenue
),

-- Step 3: Aggregate revenue per customer per month by booking type
customer_booking_monthly_revenue AS
(
    SELECT
        customer_id,
        customer_name,
        customer_type,
        booking_type,
        year,
        month,
        SUM(revenue_per_load) AS customer_monthly_total_revenue
    FROM load_share
    GROUP BY
        customer_id,
        customer_name,
        customer_type,
        booking_type,
        year,
        month
)

-- Step 4: Final output including each customer's percentage share of booking type revenue per month
SELECT
    customer_id,
    customer_name,
    year,
    month,
    customer_type,
    booking_type,
    customer_monthly_total_revenue,
    -- Total revenue per booking type in that month
    SUM(customer_monthly_total_revenue) OVER (PARTITION BY customer_type, booking_type, year, month) AS booking_total_revenue,
    -- Customer's share of the booking type revenue
    ROUND(customer_monthly_total_revenue
        / SUM(customer_monthly_total_revenue) OVER (PARTITION BY customer_type, booking_type, year, month)
        * 100, 2) AS booking_type_percentage_share
FROM customer_booking_monthly_revenue
ORDER BY
    year,
    month,
    customer_type,
    booking_type,
    customer_id;
