setwd("./James_Docs/gtfs_explore")
stop_data <- read.csv("stop_level_report.csv",header=TRUE)
stop_route_data <- read.csv("stop_route_level_report.csv",header=TRUE)
route_data <- read.csv("route_level_report.csv",header=TRUE)

library("pastecs")
library("xtable")
options(scipen=1)
options(digits=2)
stat.desc(stop_data$numroutes)

library("sqldf")
library(lattice)

hdwy.reduced <- sqldf("select route_short_name, avghdwy from stop_route_data where direction_id=1 and service_id='1'")
hdwy.wkdy <- sqldf("select route_short_name, avghdwy from stop_route_data where direction_id=1 and service_id='1'")
hdwy.sat <- sqldf("select route_short_name, avghdwy from stop_route_data where direction_id=1 and service_id='2'")
hdwy.sun <- sqldf("select route_short_name, avghdwy from stop_route_data where direction_id=1 and service_id='3'")

histogram(~ avghdwy | route_short_name, data=hdwy.reduced, breaks=seq(0,500,5), xlim=c(0,90), as.table=TRUE)
histogram(~ avghdwy | route_short_name, data=hdwy.wkdy, breaks=seq(0,500,5), xlim=c(0,90), as.table=TRUE)


hist(hdwy.wkdy$avghdwy, 
     xlim=c(0,90),
     breaks=45,
     ylim=c(0,800),
     main="Distribution of Bus Headways in Philadelphia, PA",
     xlab="Average Headway for Route-Stop Pairs (min)",
     ylab="Distribution of Avg Headways",
     col=rgb(224,170,15,255,maxColorValue=255),
     border=FALSE,
     yaxt="n",
     xaxt="n")
axis(2,at=100*(0:8),las=2)
axis(2,at=100*(0:8),tck=1,col="white",lwd=2,labels=FALSE)
axis(1,at=5*(0:18))