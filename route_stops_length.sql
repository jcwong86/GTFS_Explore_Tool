-- Creates an output with the length and number of stops for each route.
-- Check service_id for your gtfs file
-- Check route_type at the end of the file
-- Change projection as necessary


SELECT route_short_name, route_long_name, route_stops, route_length_mi
FROM gtfs_routes -- get supporting route info
JOIN(
	SELECT route_id, route_stops, route_length_mi
	FROM
		-- Get the number of stops for each route_id as the avg of each trip using that route_id
		(SELECT route_id, ROUND(avg(num_stops),1) as route_stops
		FROM (
			SELECT route_id, trip_id, count(DISTINCT stop_id) as num_stops
			FROM gtfs_stop_times
			RIGHT JOIN (
				SELECT trip_id, route_id
				FROM gtfs_trips
				WHERE service_id='1') a -- weekday service
			USING (trip_id)
			GROUP BY trip_id, route_id) b
		GROUP BY route_id) num_stop_table
	FULL OUTER JOIN
		-- Get the length of each route_id
		(SELECT route_id, ROUND(AVG(shape_length_mi)::NUMERIC,1) AS route_length_mi
		FROM( --Note projection. This SRID is for SE Pennsylvania
			SELECT shape_id, ST_LENGTH(TRANSFORM(the_geom,32129))/1609.34 AS shape_length_mi
			FROM gtfs_shape_geoms) X,
		gtfs_trips Y
		WHERE X.shape_id=Y.shape_id
		GROUP BY route_id) length_table
	USING (route_id)) N
USING (route_id)
WHERE route_type=3 --Only get buses