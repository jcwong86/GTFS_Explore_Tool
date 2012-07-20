#Set the path to the output files
setwd("./James_Docs/gtfs_explore_local/feedstats")

#Create a vertical vector that will eventually be transposed
names<-c(
  'PseudoAgencyName',
  'agency_agency_id',
  'agency_agency_name',
  'agency_agency_url',
  'agency_agency_timezone',
  'agency_agency_lang',
  'agency_agency_phone',
  'agency_agency_fare_url',
  'stops_stop_id',
  'stops_stop_code',
  'stops_stop_name',
  'stops_stop_desc',
  'stops_stop_lat',
  'stops_stop_lon',
  'stops_zone_id',
  'stops_stop_url',
  'stops_location_type',
  'stops_parent_station',
  'stops_stop_timezone',
  'stops_wheelchair_boarding',
  'routes_route_id',
  'routes_agency_id',
  'routes_route_short_name',
  'routes_route_long_name',
  'routes_route_desc',
  'routes_route_type',
  'routes_route_url',
  'routes_route_color',
  'routes_route_text_color',
  'trips_route_id',
  'trips_service_id',
  'trips_trip_id',
  'trips_trip_headsign',
  'trips_trip_short_name',
  'trips_direction_id',
  'trips_block_id',
  'trips_shape_id',
  'stop_times_trip_id',
  'stop_times_arrival_time',
  'stop_times_departure_time',
  'stop_times_stop_id',
  'stop_times_stop_sequence',
  'stop_times_stop_headsign',
  'stop_times_pickup_type',
  'stop_times_drop_off_type',
  'stop_times_shape_dist_traveled',
  'calendar_service_id',
  'calendar_monday',
  'calendar_tuesday',
  'calendar_wednesday',
  'calendar_thursday',
  'calendar_friday',
  'calendar_saturday',
  'calendar_sunday',
  'calendar_start_date',
  'calendar_end_date',
  'calendar_dates_service_id',
  'calendar_dates_date',
  'calendar_dates_exception_type',
  'fare_attributes_fare_id',
  'fare_attributes_price',
  'fare_attributes_currency_type',
  'fare_attributes_payment_method',
  'fare_attributes_transfers',
  'fare_attributes_transfer_duration',
  'fare_rules_fare_id',
  'fare_rules_route_id',
  'fare_rules_origin_id',
  'fare_rules_destination_id',
  'fare_rules_contains_id',
  'shapes_shape_id',
  'shapes_shape_pt_lat',
  'shapes_shape_pt_lon',
  'shapes_shape_pt_sequence',
  'shapes_shape_dist_traveled',
  'frequencies_trip_id',
  'frequencies_start_time',
  'frequencies_end_time',
  'frequencies_headway_secs',
  'frequencies_exact_times',
  'transfers_from_stop_id',
  'transfers_to_stop_id',
  'transfers_transfer_type',
  'transfers_min_transfer_time',
  'feed_info_feed_publisher_name',
  'feed_info_feed_publisher_url',
  'feed_info_feed_lang',
  'feed_info_feed_start_date',
  'feed_info_feed_end_date',
  'feed_info_feed_version')

feedstats=data.frame(colnames=names)

filelist <- list.files(pattern="stats.csv") 

#Walks through the file list and checks if its an empty table, if so it skips it.
#If its valid, it loads the data, reads a column, then drops the data
#It also replaces the first line of each column with the agency's pseudo_id

rm <- c()

for (x in filelist) {
  if(file.info(x)$size==0){
    print(paste("SKIPPED FOR EMPTY FILE:",x))
    rm<-append(rm,x)
  }
  else if(length(t(read.csv(x,header=TRUE)))==0){
    print(paste("SKIPPED FOR NO ROWS:",x))
    rm<-append(rm,x)
  }
  else {
    temp_df<-read.csv(x,header=TRUE)
    feedstats<-cbind(feedstats,temp_df[,3])
    names(feedstats)[length(feedstats)]<-temp_df[2,1]
    feedstats[1,length(feedstats)]<-temp_df[1,2]
    print(paste("LOADED ",x)) 
  }
}
feedstats<-feedstats[2:90,]
write.table(feedstats,file="_aggregated_feed_stats.csv",sep=",",col.names=TRUE, row.names=FALSE)