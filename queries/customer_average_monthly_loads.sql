-- Purpose: Calculate the average number of loads per month for each customer
-- Ensures that months with no loads are counted as 0 so the average is accurate

-- Step 1: Get a list of all months present in the dataset
WITH month_list AS
(
	SELECT DISTINCT
		YEAR(load_date) AS year,       -- Year of the load
		MONTH(load_date) AS month      -- Month number of the load
	FROM loads
),

-- Step 2: Generate a "skeleton table" of every customer × month combination
skeleton_table AS
(
	SELECT
		c.customer_id,
		c.customer_name,
		ml.year,
		ml.month
	FROM month_list AS ml
	CROSS JOIN customers AS c           -- Cross join to ensure all months exist for all customers
),

-- Step 3: Attach actual loads to the skeleton table
customer_load AS
(
	SELECT
		l.load_id,
		st.customer_id,
		st.customer_name,
		st.year,
		st.month
	FROM skeleton_table AS st
	LEFT JOIN loads AS l
		ON st.customer_id = l.customer_id
		AND st.year = YEAR(l.load_date)
		AND st.month = MONTH(l.load_date)		   -- Keeps months without loads as NULL
),

-- Step 4: Count loads per customer per month
customer_monthly_load AS
(
	SELECT
		customer_id,
		customer_name,
		year,
		month,
		COALESCE(COUNT(load_id),0) AS load_count   -- Replace NULLs with 0
	FROM customer_load
	GROUP BY
		customer_id,
		customer_name,
		year,
		month
)

-- Step 5: Calculate average monthly load per customer
SELECT
	customer_id,
	customer_name,
	AVG(load_count) AS average_monthly_load       -- Average over all months, including months with 0 loads
FROM customer_monthly_load
GROUP BY
	customer_id,
	customer_name
