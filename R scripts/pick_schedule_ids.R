
####NOT REALLY WORKING WELL

setwd("/Users/openplans/Dropbox/OpenPlans/Research/GTFS Explore Paper/output/calendars")

#Edit for whether bus, rail, subway or light_rail
filelist<- list.files(pattern="*calendar.txt") 

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
    assign(substr(x,0,nchar(x)-4),read.csv(x,header=TRUE))
    print(paste("LOADED ",x)) 
  }
}
#Remove the skipped files from the filelist
filelist<-filelist[!filelist %in% rm]
remove(rm)
remove(x)

#Remove the .csv from the filelist titles
for(i in 1:length(filelist)) {
  filelist[i] <- substr(filelist[i],0,nchar(filelist[i])-4)
}
remove(i)


######
##BROKENNNNN
###

#Ask user to select the correct schedule to use
sched<-data.frame("a","a")
colnames(sched)<-c("filename","schedule_id")

Console.Read()
for (x in filelist) {
    get(x)
    y<-readline(prompt=paste("Choose the row number of the schedule you want to use from ",x,": "))
    if(y=="exit") break 
  }


