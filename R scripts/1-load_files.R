setwd("/Users/openplans/Dropbox/OpenPlans/Research/GTFS Explore Paper/output/")

#Edit for whether bus, rail, subway or light_rail
filelist <- list.files(pattern="bus_stop_route_level") 

#Walks through the file list and checks if its an empty table, if so it skips it.
#If its valid, it pulls it into a dataframe based on the name of the file less ".csv"

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
    assign(substr(x,0,nchar(x)-25),read.csv(x,header=TRUE))
    print(paste("LOADED ",x)) 
  }
}
#Remove the skipped files from the filelist
filelist<-filelist[!filelist %in% rm]
remove(rm, x)

#Remove the .csv from the filelist titles
for(i in 1:length(filelist)) {
  filelist[i] <- substr(filelist[i],0,nchar(filelist[i])-4)
}
remove(i)


#Load the SEPTA Specific route file.