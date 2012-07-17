-- NUMBER OF ROUTES SERVED
-- Uses trip table to find those with service_id=1 which means M-F for SEPTA. Also uses direction_id to ensure only one direction is counted so that if trip x serves stop y in two directions, it’s only counted once. 
CREATE TABLE stop_level_routes_served AS
SELECT stop_id, service_id, direction_id, count(distinct route_id) as numRoutes
FROM gtfs_stop_times a
JOIN (SELECT route_id, service_id, direction_id, trip_id
	FROM gtfs_trips) c
USING (trip_id)
GROUP BY stop_id, service_id, direction_id
ORDER BY service_id, stop_id, direction_id;


-- NUM TRIPS PER DAY
-- Counts number of trip_id’s associated with each stop_id. We could add route_id as a group-by function if needed. Slow to execute currently.
CREATE TABLE stop_level_trips_per_day AS
SELECT service_id, stop_id, direction_id, count(b.trip_id) AS "TripsServingStop" 
FROM gtfs_stop_times a
JOIN (SELECT trip_id, service_id, direction_id
	FROM gtfs_trips) b
USING (trip_id)
GROUP BY stop_id, b.service_id, b.direction_id
ORDER BY service_id, stop_id, direction_id;


-- AVG TIME BETWEEN ARRIVALS
-- Provides average and stdev headways for a particular direction of a route at a stop at different service plans (M-D/Sa/Su etc. Note that headways less than 3 min are ignored per guidance in TCQSM as not being the equivalent of two separate arrivals. Those >90min are ignored as well as likely service breaks (no lit support).

CREATE TABLE stop_level_avg_hdwy AS 
SELECT service_id, stop_id, route_id, direction_id, avgHdwy, stdev_hdwy 
FROM
	(SELECT service_id, stop_id, route_id, direction_id, trunc(avg(headway),1) AS avgHdwy, trunc(stddev(headway),1) as stdev_hdwy
	FROM( 
		SELECT service_id, stop_id, route_id, direction_id, 
		CASE WHEN (headwayTest>90 OR headwayTest<3) THEN NULL ELSE headwayTest END AS headway
		FROM(
			SELECT service_id, 
				stop_id, 
				route_id, 
				direction_id,
				(departure_time_seconds - lag(departure_time_seconds) OVER (PARTITION BY service_id, stop_id, route_id, direction_id ORDER BY departure_time_seconds))/60 AS headwayTest
			FROM gtfs_stop_times 
			JOIN gtfs_trips USING (trip_id)) d ) e
	GROUP BY service_id, stop_id, route_id, direction_id) c 
JOIN gtfs_stops USING (stop_id)
JOIN gtfs_routes USING (route_id)
ORDER BY service_id, stop_id, route_id, direction_id;

--CREATE STOP LEVEL AND STOP/ROUTE LEVEL REPORTS
--stop_level_report provides summary information for each stop at each service_id and direction_id. 
--
CREATE VIEW stop_level_Report AS
SELECT * 
FROM stop_level_routes_served 
NATURAL JOIN stop_level_trips_per_day 
JOIN (SELECT stop_name, stop_lat, stop_lon, stop_id FROM gtfs_stops) a USING (stop_id);


CREATE VIEW stop_route_level_Report AS
SELECT * 
FROM
stop_level_avg_hdwy
JOIN (SELECT stop_name, stop_lat, stop_lon, stop_id FROM gtfs_stops) a USING (stop_id)
JOIN (SELECT route_short_name, route_long_name, route_id FROM gtfs_routes) b USING (route_id);


--ROUTE LEVEL ANALYSES

-- NUM TRIPS PER DAY
-- Organized by service_id for day of week, route_id as primary and direction_id as secondary grouping/sorting, show the number of trips scheduled per day.
CREATE TABLE route_level_trips_per_day AS
SELECT service_id, route_id, count(trip_id) AS numTripsPerRoute_both_dir
FROM gtfs_trips JOIN gtfs_routes USING (route_id)
GROUP BY service_id, route_id
ORDER BY service_id, route_id;

-- HOURS OF SERVICE
-- This provides the hours of the day in which this route operates at ANY stop. A route length of 90 min whose last trip starts at 8pm would show up as having service at 8pm and 9pm. This includes both directions.
CREATE TABLE route_level_hrs_of_service AS
SELECT service_id, route_id, count(distinct departure_time_seconds/3600) AS hours_of_service
FROM (SELECT stop_id, departure_time_seconds, trip_id	FROM gtfs_stop_times) a
	LEFT JOIN (SELECT service_id, route_id, trip_id FROM gtfs_trips) b USING (trip_id)
	LEFT JOIN gtfs_routes USING (route_id) 
GROUP BY service_id, route_id
ORDER BY service_id, route_id ASC;


-- FIRST/LAST TRIPS OF THE DAY AND SPAN OF SERVICE
CREATE TABLE route_level_FLtrip_serv_span AS
SELECT service_id, route_id,
	min(starting_departure) AS first_departure_sec, 
	max(ending_arrival) AS last_departure_sec,
	ROUND((max(ending_arrival)-min(starting_departure))/3600.0) AS span_of_service_hrs
FROM (
	SELECT service_id, trip_id, route_id, 
		min(departure_time_seconds) AS starting_departure,
		max(arrival_time_seconds) AS ending_arrival
	FROM gtfs_stop_times
	JOIN (SELECT service_id, trip_id, route_id FROM gtfs_trips) a USING (trip_id)
	JOIN gtfs_routes USING (route_id)
	GROUP BY service_id, trip_id, route_id) b
GROUP BY service_id, route_id
ORDER BY service_id, route_id;

-- NUMBER OF STOPS PER ROUTE
-- Reports number of stops for each trip and then creates a weighted average for all the trips that belong to a route to account for a higher number of similar runs
CREATE TABLE route_level_num_stops_detail AS
SELECT service_id, route_id, direction_id, stops_per_trip, COUNT(*) AS num_similar_runs
FROM(
	SELECT service_id, route_id, direction_id, trip_id, count(stop_id) AS stops_per_trip 
	FROM gtfs_trips 
	JOIN (SELECT DISTINCT stop_id, trip_id FROM gtfs_stop_times) a USING (trip_id)
	JOIN gtfs_routes USING (route_id)
	GROUP BY service_id, route_id, direction_id,trip_id) b 
GROUP BY service_id, route_id, direction_id,stops_per_trip
ORDER BY service_id, route_id, direction_id;

CREATE TABLE route_level_w_avg_stops AS
SELECT service_id, route_id, direction_id, round(sum(heavyAvg)/sum(num_similar_runs) ,1) AS w_avg_num_stops
FROM (
	SELECT *, stops_per_trip*num_similar_runs AS heavyAvg 
	FROM route_level_num_stops_detail) a
GROUP BY service_id, route_id, direction_id
ORDER BY route_id, service_id;

-- AVERAGE HEADWAY ON ROUTE
-- This provides the average headway of a route based on the stop-route headway at the most popular stop of each route. It is arbitrarily chosen among multiple stops with the same number of arrivals per day.
CREATE TABLE route_level_headway AS
SELECT service_id, route_id, direction_id, avghdwy AS route_avg_hdwy, stdev_hdwy AS route_stdev_hdwy, trips_per_day
FROM stop_level_avg_hdwy a
RIGHT JOIN (
	SELECT DISTINCT
	first_value(service_id) OVER w AS service_id, 
	first_value(route_id) OVER w AS route_id, 
	first_value(direction_id) OVER w AS direction_id, 
	first_value(stop_id) OVER w AS stop_id,
	first_value(numTripsPerDay) OVER w AS trips_per_day
	FROM (
		SELECT service_id, route_id, direction_id, stop_id, count(trip_id) as numTripsPerDay
		FROM gtfs_stop_times JOIN gtfs_trips USING (trip_id)
		GROUP BY service_id, route_id, direction_id, stop_id) c
	WINDOW w AS (PARTITION BY service_id, route_id, direction_id ORDER BY numTripsPerDay DESC)) b
USING (service_id, route_id, direction_id, stop_id);


-- AVERAGE DISTANCE BETWEEN STOPS
-- Note that this uses the st_line_locate function which requires use 
-- of geometries which are using the google universal projection. Ideally it will use
-- state planes or geographies which should be updated for the future.

CREATE INDEX ON gtfs_stop_times(stop_id);
CREATE INDEX ON gtfs_trips(trip_id);
CREATE INDEX ON gtfs_trips(shape_id);

CREATE TABLE temp1 AS 
SELECT 	b.stop_id, 
	b.shape_id, 
	round((b.percent_along_route*b.route_length_meters)::NUMERIC,1) as dist_along_route_m
FROM (
	SELECT a.stop_id, 
		a.shape_id, 
		ST_line_locate_point(route.the_geom, stop.the_geom) as percent_along_route,
		ST_length(st_transform(route.the_geom,900913)) as route_length_meters
	FROM (
		SELECT DISTINCT stop_id, shape_id 
		FROM gtfs_stop_times  
		JOIN gtfs_trips 
		USING (trip_id)) a, 
		gtfs_shape_geoms route, 
		gtfs_stops stop
	WHERE stop.stop_id=a.stop_id AND route.shape_id=a.shape_id) b;

CREATE TABLE temp2 AS
SELECT 	service_id, stop_id, route_id, direction_id, stop_sequence, trip_id,
	shape_id, departure_time_seconds, arrival_time_seconds
FROM gtfs_stop_times 
JOIN gtfs_trips USING (trip_id)
ORDER by service_id, stop_id, route_id, direction_id, trip_id;

CREATE INDEX ON temp1(stop_id, shape_id); 
CREATE INDEX ON temp2(stop_id, shape_id);

CREATE TABLE temp3 AS 
SELECT *
FROM temp1 JOIN temp2 USING (stop_id, shape_id);

DROP TABLE temp1, temp2;
CREATE INDEX ON temp3(stop_id);

CREATE TABLE stop_times_w_dist_duration AS
SELECT 	service_id, route_id, direction_id, trip_id, stop_sequence, stop_id,
	departure_time_seconds - lag(arrival_time_seconds) OVER w AS sec_since_last_stop,
	dist_along_route_m - lag(dist_along_route_m) OVER w AS meters_since_last_stop
FROM temp3
WINDOW w as (PARTITION BY service_id, route_id, direction_id, trip_id 
	ORDER BY stop_sequence)
ORDER BY trip_id, service_id, stop_sequence, route_id, direction_id, stop_sequence;

CREATE TABLE route_level_dist_bw_stops AS
SELECT route_id, service_id, direction_id, avg(meters_since_last_stop)*3.281 AS avg_dist_bw_stops_ft
FROM stop_times_w_dist_duration
GROUP BY service_id, route_id, direction_id;
DROP TABLE temp3, stop_times_w_dist_duration;


-- TRIP SPEED
-- Provides the speed of every trip along with start/end time and duration. Includes support information like service id, route id and trip id. Can be aggregated to provide better time-of-day information

CREATE INDEX ON gtfs_stop_times(trip_id);
CREATE INDEX ON gtfs_trips(trip_id);
CREATE INDEX ON gtfs_trips(service_id, route_id, direction_id, trip_id);

CREATE TABLE temp1 AS
SELECT service_id,
	route_id,
	direction_id,
	TR.trip_id,
	(max(arrival_time_seconds)-min(departure_time_seconds)) AS trip_duration_sec,
	to_timestamp(max(arrival_time_seconds)-min(departure_time_seconds)) - 'epoch' AS trip_duration,
	to_timestamp(min(departure_time_seconds)) -'epoch' AS begin_time_hrs,
	to_timestamp(max(arrival_time_seconds)) - 'epoch' AS end_time_hrs
FROM	gtfs_stop_times ST, gtfs_trips TR
WHERE	ST.trip_id=TR.trip_id
GROUP BY service_id, route_id,	direction_id, TR.trip_id;

CREATE INDEX ON temp1(trip_id);

CREATE TABLE trip_geoms AS
SELECT a.trip_id, b.route_id, the_geom
FROM gtfs_trips a, gtfs_routes b, gtfs_shape_geoms c
WHERE a.route_id=b.route_id AND a.shape_id=c.shape_id;

CREATE TABLE temp2 AS
SELECT	b.*,
	round(ST_length(st_transform(a.the_geom,900913))) as trip_length_m
FROM 	trip_geoms a, 
	temp1 b
WHERE a.trip_id=b.trip_id;

CREATE TABLE trip_speeds AS
SELECT	route_id,
	service_id,
	direction_id,
	trip_id,
	trip_duration,
	begin_time_hrs,
	end_time_hrs,
	trip_length_m,
	round(CAST((trip_length_m/trip_duration_sec)*2.2370 AS NUMERIC),1) AS trip_speed_mph
FROM temp2;

DROP TABLE temp1, temp2;

-- ROUTE SPEED
-- Separate summary table using average of all trips per route for a speed (on a specific service_id)
CREATE TABLE route_level_speeds AS
SELECT 	service_id, 
	direction_id,
	route_id, 
	average_speed, 
	average_length_mi
FROM (
	SELECT 	service_id, 
		route_id, 
		direction_id,
		ROUND(avg(trip_speed_mph),1) AS average_speed, 
		ROUND(CAST(AVG(trip_length_m/1609.34) AS NUMERIC),1) AS average_length_mi
	FROM trip_speeds
	GROUP BY service_id, route_id, direction_id) a
	JOIN gtfs_routes USING (route_id)
ORDER BY service_id, route_id;


CREATE OR REPLACE VIEW route_level_report AS
SELECT *
FROM route_level_trips_per_day
NATURAL LEFT OUTER JOIN route_level_hrs_of_service
NATURAL LEFT OUTER JOIN route_level_FLtrip_serv_span
NATURAL LEFT OUTER JOIN route_level_headway
NATURAL LEFT OUTER JOIN route_level_speeds
NATURAL LEFT OUTER JOIN route_level_w_avg_stops
NATURAL LEFT OUTER JOIN route_level_dist_bw_stops
NATURAL JOIN (SELECT route_short_name, route_long_name, route_id FROM gtfs_routes) a;