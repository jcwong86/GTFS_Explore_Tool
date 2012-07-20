
#Load a SQL like language into R
library(sqldf)

#Use this chunk to isolate a specific service_id from the table
for(i in 1:5){
  assign(filelist[i],sqldf(paste("SELECT * FROM ",filelist[i]," WHERE service_id= '",as.character(service_ids[i,2]),"'",sep="")))
}

#Need to find a way to choose the correct direction_id, can do some count functions using sql


#Go to calendars file and pull all the service ids for a specific Wednesday and all the ones that are active; keep those, make averages based on that.
