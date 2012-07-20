setwd("/Users/openplans/Dropbox/OpenPlans/Research/GTFS Explore Paper/output")

#Edit for whether bus, rail, subway or light_rail
filelist <- list.files(pattern="*bus_route_l") 
for(x in 1:length(filelist)) filelist[x] <- substr(filelist[x],0,nchar(filelist[x])-4)
#Walks through the file list and checks if its an empty table, if so it skips it.
#If its valid, it pulls it into a dataframe based on the name of the file less ".csv"
i<-0
for (x in filelist) {
  i++
  if (file.info(paste(x,".csv",sep="")$size==0)) {
    #file.remove(x) #this can be used to delete those empty files
    print(paste("SKIPPED ",x))
    filelist[i]<-NULL
    i<-i-1
    }
  else {
    assign(substr(x,0,nchar(x)-4),read.csv(filelist[x],header=TRUE))
    print(paste("assigned ",x))  
  }
  
}
x<-NULL



#Ask user to select the correct schedule to use
if (interactive()){
  for (x in filelist) {
    View(unique(get(x)[,2]))
    y<-readline(prompt=paste("Choose the row number of the schedule you want to use from ",x,": "))
    if(y=="exit"){break}
    }
   }
else {print("Non-interactive session, skip block")}