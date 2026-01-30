-- Purpose: Calculate each customer's annualized revenue, compare it to their potential, 
-- and assign a performance flag (Below Target / On Track / Above Target)

-- Step 1: Calculate the observation window per customer
WITH customer_duration AS
(
	SELECT
		c.customer_id,
		c.customer_name,
		CASE
			WHEN DATEDIFF(DAY, MIN(l.load_date), MAX(l.load_date)) = 0
			THEN 1                               -- Avoid zero-day duration for customers with only 1 load
			ELSE DATEDIFF(DAY, MIN(l.load_date), MAX(l.load_date))
		END AS duration_in_days,
		MIN(l.load_date) AS earliest_load_date, -- First load date
		MAX(l.load_date) AS latest_load_date    -- Last load date
	FROM customers AS c
	LEFT JOIN loads AS l
		ON c.customer_id = l.customer_id        -- Join loads to customers
	GROUP BY
		c.customer_id,
		c.customer_name
),

-- Step 2: Annualize revenue for each customer
customer_annual_revenue AS
(
	SELECT
		cd.customer_id,
		cd.customer_name,
		(SUM(l.revenue) / NULLIF(cd.duration_in_days,0)) * 365 AS annual_revenue  -- Revenue scaled to 1 year
	FROM customer_duration AS cd
	LEFT JOIN loads AS l
		ON cd.customer_id = l.customer_id
	GROUP BY
		cd.customer_id,
		cd.customer_name,
		duration_in_days
),

-- Step 3: Compare annualized revenue to customer potential
potential_percentage AS
(
	SELECT
		car.customer_id,
		car.customer_name,
		car.annual_revenue,
		c.annual_revenue_potential,
		ROUND((car.annual_revenue / c.annual_revenue_potential) * 100,2) AS realization_percentage  -- % of potential realized
	FROM customer_annual_revenue AS car
	LEFT JOIN customers AS c
		ON car.customer_id = c.customer_id
)

-- Step 4: Assign a performance flag based on realization percentage
SELECT
	customer_id,
	customer_name,
	annual_revenue,
	annual_revenue_potential,
	realization_percentage,
	CASE
		WHEN realization_percentage < 70 THEN 'Below Target'   -- Significant underperformance
		WHEN realization_percentage > 100 THEN 'Above Target'  -- Exceeding expected revenue
		ELSE 'On Track'                                       -- Within acceptable range
	END AS realization_flag
FROM potential_percentage
ORDER BY
	realization_percentage DESC;                              -- Show top performers first
