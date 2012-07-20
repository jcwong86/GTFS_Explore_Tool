## Generate data as a basic plot for SEPTA route-stop headways (Tuesday)

i<-"septa"


serv_ids_lookup<-sqldf(paste("SELECT service_id FROM service_ids WHERE agency_filename='",i,"'",sep=""))
SEPTA_hdwys<-data.frame("stop_route_avg_hdwys"=sqldf(paste("SELECT avghdwy FROM ",i,"WHERE service_id IN 'serv_ids_lookup'")))
SEPTA_hdwys<-rbind(SEPTA_hdwys,hdwy)
print(paste("-------Just added",i))

SEPTA_hdwys<-SEPTA_hdwys[!is.na(SEPTA_hdwys)] #get rid of NaN values

#Basic histogram with 5-min bins
hist(SEPTA_hdwys,breaks=90,xlim=c(0,90))

write.csv(SEPTA_hdwys,"SEPTA Bus Stop-Route Headways.csv")