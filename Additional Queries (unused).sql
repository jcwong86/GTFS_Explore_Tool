--OPTIONAL ADDITIONAL ANALYSES
--incomplete


-- SPAN OF SERVICE
-- Returns the time in seconds of the first/last departure; note that the last departure may actually be an arrival if its a terminal stop. Hours of service is different. Some post-processing should be done on rows with early_departures=true because that means there’s a departure before 4:30 AM which is a rough indicator of some kind of late-night service.
CREATE TABLE stop_level_span_of_service AS
SELECT stop_id, 
	service_id, 
	direction_id, 
	route_id, 
	min(departure_time_seconds) AS first_departure,
	max(arrival_time_seconds) AS last_departure, 
	(max(arrival_time_seconds)-min(departure_time_seconds))/3600+1 AS span_of_service_hrs, 
	CASE WHEN min(departure_time_seconds) < 16200 THEN TRUE END AS early_departures 
FROM gtfs_stop_times a
JOIN (SELECT route_id, service_id, direction_id, trip_id FROM gtfs_trips) c
USING (trip_id)
GROUP BY stop_id, service_id, route_id, direction_id
ORDER BY service_id, stop_id, route_id, direction_id;

-- HOURS OF SERVICE
-- Counts the number of hours in which at least one bus arrival occurs. Provided at service, stop, route and direction breakdown level. 
CREATE TABLE stop_level_hours_of_service AS
SELECT 
	stop_id, 
	service_id, 
	route_id, 
	direction_id, 
	count(distinct departure_time_seconds/3600) AS hours_of_service
FROM (
	SELECT stop_id, departure_time_seconds, trip_id
	FROM gtfs_stop_times) a
LEFT JOIN (
	SELECT service_id, 
		route_id, 
		direction_id, 
		trip_id 
	FROM gtfs_trips) b 
USING (trip_id)
GROUP BY service_id, stop_id, route_id, direction_id
ORDER BY service_id, stop_id, route_id ASC;
-- ROUTES SERVED BY SERVICE PLAN 
-- NOTE: Not found in summaries.
SELECT service_id, count(distinct route_id)
FROM gtfs_trips JOIN gtfs_routes USING (route_id)
GROUP BY service_id
ORDER BY service_id;