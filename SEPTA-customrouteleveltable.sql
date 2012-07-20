
-- Quick and dirty script to grab the route length and number of stops on the route
-- averaged over all trips sharing that route_id

SELECT route_short_name, route_long_name, AvgRouteLength_mi, num_stops_per_route FROM

(SELECT route_id, route_short_name, route_long_name, round(AvgRouteLength::numeric,1) as AvgRouteLength_mi FROM 
gtfs_routes 
RIGHT JOIN
(SELECT route_id, avg(route_length_miles) as AvgRouteLength FROM
(SELECT DISTINCT route_id,shape_id FROM gtfs_trips) a
LEFT JOIN (SELECT shape_id, ST_length(st_transform(the_geom,32129))/1609.34 as route_length_miles 
	FROM gtfs_shape_geoms) c USING (shape_id)
GROUP BY route_id) d
USING (route_id)) e

JOIN


(SELECT route_id, round(num_stops_on_route/numtrips::numeric,1) AS num_stops_per_route
FROM 
(SELECT route_id, count(trip_id) AS numtrips
FROM gtfs_trips
GROUP BY route_id) x
JOIN
(SELECT route_id, count(*) AS num_stops_on_route
FROM gtfs_stop_times p, gtfs_trips q
WHERE p.trip_id=q.trip_id AND service_id='1'
GROUP BY route_id) y
USING (route_id) ) z

USING (route_id)

ORDER BY avgroutelength_mi