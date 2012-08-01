#Combines service id lookup and parts of the load file to generate a dataframe
#with 5-min bin freq distributions for each set of stop_time avg hdwys

#set path to calendars folder
setwd("/Users/openplans/Dropbox/gtfs_explore/calendars")


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

#loop through filenames and get them loaded into the service_id lookup
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
remove(i,j,x,filename,temp,temp_df)




#percentiles<-data.frame("85th_Percentile_hdwy"=0)
bins<-c(seq(from=0,to=85,by=5))
freq<-data.frame("[0,5)"=0, "[5,10)"=0, "[10,15)"=0, "[15,20)"=0, "[20,25)"=0, "[25,30)"=0, "[30,35)"=0, "[35,40)"=0, "[40,45)"=0, "[45,50)"=0, "[50,55)"=0, "[55,60)"=0, "[60,65)"=0, "[65,70)"=0, "[70,75)"=0, "[75,80)"=0, "[80,85)"=0)
aname<-data.frame()
setwd("../output")

for(i in filelist){
  flag<-FALSE
  if(!file.exists(paste(i,"_bus_stop_route_level.csv",sep=""))){
    print(paste("SKIP",i,"for no file"))
    flag<-TRUE
  }
  
  if(!flag){temp<-read.csv(paste(i,"_bus_stop_route_level.csv",sep=""),header=TRUE)}
  if(nrow(temp)==0){
    print(paste("SKIPPED",i,"for no data"))
    flag<-TRUE
  }
  
  serv_ids_lookup<-sqldf(paste("SELECT service_id FROM service_ids WHERE agency_filename='",i,"'",sep=""))
 
  if(nrow(serv_ids_lookup)==0){
    print(paste("SKIPPED",i,"for no data"))
    flag<-TRUE
  }
  
  if(!flag){
    query<-"SELECT avghdwy FROM temp WHERE service_id IN 'serv_ids_lookup'"
    allhdwys<-sqldf(query)
    allhdwys<-allhdwys[!is.na(allhdwys)]
  }
  
  if(length(allhdwys)==0){
    print(paste("SKIPPED",i,"for empty allhdwys"))
    flag<-TRUE
  }
  
  if(!flag){
    row<-table(cut(allhdwys,bins,right=FALSE))
    freq<-rbind(freq,row)
    #aname<-rbind(aname,as.character(i))
    print(paste("-------Just added",i))
  }
  
}
#freq<-freq[2:nrow(freq),1] #get rid of starter row
#names(aname)<-"agency_name"
freq<-freq[2:nrow(freq),]
#freq<cbind(freq,aname)

write.csv(freq,"../AllAgencies-hist-avghdwys.csv")

