/*
    Purpose: Evaluate driver performance based on trip speed and load type.
    - Calculate each trip's average speed excluding idle time.
    - Flag trips as 'Dependable', 'Unreliable', or 'Discrepant' based on realistic speed thresholds per load type.
    - Aggregate trips by driver to determine the proportion of trips in each flag category.
    - This provides a snapshot of driver reliability and highlights unusual or suspicious trips.
*/

WITH driver_speed AS
(
	SELECT
		d.driver_id,
		t.trip_id,
		l.load_id,
		l.load_type,
		t.actual_distance_miles,
		t.actual_duration_hours,
		t.idle_time_hours,
		t.actual_distance_miles / 
			CASE 
				WHEN (t.actual_duration_hours - t.idle_time_hours) = 0 THEN 1
				ELSE (t.actual_duration_hours - t.idle_time_hours)
			END AS average_trip_speed
	FROM drivers AS d
	LEFT JOIN trips AS t
		ON d.driver_id = t.driver_id
	LEFT JOIN loads AS l
		ON t.load_id = l.load_id
),

trip_flags AS
(
	SELECT
		driver_id,
		trip_id,
		load_id,
		load_type,
		actual_distance_miles,
		actual_duration_hours,
		idle_time_hours,
		average_trip_speed,
		CASE
			-- Flag extreme or impossible speeds first
			WHEN (average_trip_speed < 0 OR average_trip_speed > 70) THEN 'Discrepant'

			-- Dry Van thresholds
			WHEN load_type = 'Dry Van' AND average_trip_speed BETWEEN 0 AND 30 THEN 'Unreliable'
			WHEN load_type = 'Dry Van' AND average_trip_speed > 30 THEN 'Dependable'

			-- Refrigerated thresholds
			WHEN load_type = 'Refrigerated' AND average_trip_speed BETWEEN 0 AND 40 THEN 'Unreliable'
			WHEN load_type = 'Refrigerated' AND average_trip_speed > 40 THEN 'Dependable'

			-- Catch-all
			ELSE 'Discrepant'
		END AS flag
	FROM driver_speed
),

driver_flag_summary AS
(
	SELECT
		driver_id,
		flag,
		COUNT(*) AS trips_per_flag,
		COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY driver_id) AS trips_percentage
	FROM trip_flags
	GROUP BY
		driver_id,
		flag
)

SELECT *
FROM driver_flag_summary
ORDER BY driver_id, flag;
