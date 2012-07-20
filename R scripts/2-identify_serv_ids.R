# This script should be used in order to create a dataframe service_ids that selects
# those data that from the other tables that are operating on Tuesdays on the current date
#
# James Wong jcwong86@gmail.com
#



#set path to calendars folder
setwd("/Users/openplans/Dropbox/OpenPlans/Research/GTFS Explore Paper/output/calendars/")


#Load a SQL like language into R
library(sqldf)


#Edit for whether bus, rail, subway or light_rail
filelist <- list.files(pattern="-calendar.txt") 
#remove hyphen so sql could read it
i=0
for(x in filelist){
  i=i+1
  filelist[i]<-sub(".zip-calendar.txt","",filelist[i])
}

#Set up the dataframe to hold service_ids
service_ids<-data.frame("agency_filename"="a","service_id"=as.factor("b"))

#loop through filenames and get them loaded into the 
for (x in filelist) {
  filename<-paste(x,".zip-calendar.txt",sep="")
  if(file.info(filename)$size==0){
    print(paste("SKIPPED FOR EMPTY FILE:",x))
  }
  else {
    print(paste("-------Starting",x))
    temp<-read.csv(paste(x,".zip-calendar.txt",sep=""),header=TRUE)
    colnames(temp)[1]<-"service_id"
    
    j=1
    if(sum(temp$tuesday)!=0){
      #Choose only those rows where the service_id is valid on a TUESDAY and on the date (Jul 17, 2012)
      if(nrow(sqldf("SELECT service_id FROM temp WHERE tuesday=1 AND start_date<20120717 AND end_date>20120717"))==0){
        temp$start_date<-20120101
        temp$end_date<-20130101        
      }
      temp_df<-sqldf("SELECT service_id FROM temp WHERE tuesday=1 AND start_date<20120717 AND end_date>20120717")
      if(nrow(temp_df)==0) print(paste("STOP - Look at",x))
      for(i in 1:nrow(temp_df)) {
        service_ids<-rbind(service_ids,data.frame("agency_filename"=x,"service_id"=as.character(temp_df[j,1])))
        j=j+1
      }
    }
  }
}
service_ids<-service_ids[2:nrow(service_ids),]
#remove(i,j,x,filename,temp,temp_df)

