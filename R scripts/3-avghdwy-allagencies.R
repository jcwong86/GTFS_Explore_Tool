#This queries the average headway of each of the top agencies. Has error checking/logging
#This should point to the calendars files in the directory, but it relies on loading all the
#data from part 2.


filelist <- list.files(pattern="-calendar.txt") 
#remove hyphen so sql could read it
i=0
for(x in filelist){
  i=i+1
  filelist[i]<-sub(".zip-calendar.txt","",filelist[i])
}



headways<-data.frame("agency_avg_hdwy"=0)

for(i in filelist){
  if(exists(i)) {
    serv_ids_lookup<-sqldf(paste("SELECT service_id FROM service_ids WHERE agency_filename='",i,"'",sep=""))
    if(nrow(serv_ids_lookup)>0){
      hdwy<-colMeans(sqldf(paste("SELECT avghdwy FROM ",i,"WHERE service_id IN 'serv_ids_lookup'")),na.rm=TRUE)
      if(!is.na(hdwy)){
        headways<-rbind(headways,hdwy)
        print(paste("-------Just added",i))
        if(hdwy<5) {print("HUH? Very short headway.")}
      }
      else{
        print(paste("SKIPPED",i,"for NA"))
      }
    }
    else {
      print(paste("SKIPPED",i,"for no service_ids"))
    }
  }
  else {
    print(paste("SKIPPED",i,"for no table"))
  }
}
headways<-headways[2:nrow(headways),1] #get rid of starter row
headways<-headways[!is.na(headways)] #get rid of NaN values
remove(i,j,x,hdwy,filename,filelist)

write.csv(headways,"AllAgencies-Bus-avghdwys.csv")

