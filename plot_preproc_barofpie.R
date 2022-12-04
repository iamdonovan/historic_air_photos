library(ggplot2)
library(ggforce)
library(dplyr)
library(webr)


options(digits = 5)
text_size = 9
line_thickness = 0.25
inch_converting =  2.54



wd_path <- "E:/PROJECTS/REVIEW_HIST_PHOTOS/historic_air_photos/"
reviewSheet <- paste(wd_path,"data/Review_Historic_Air_Photos.csv",sep = "")


myData = read.csv(file = reviewSheet, header = TRUE, sep = "," ,na.strings=c("","NA"))
myData$Pre.processing[is.na(myData$Pre.processing)] <- "not specified" #if NA is in column, no information was given -> set to "not specified"

# count 
perc_no_preproc = sum(myData$Pre.processing == "no") 
perc_notspec_preproc = sum(myData$Pre.processing == "not specified") 
perc_preproc = sum(myData$Pre.processing == "yes") 

perc_geom_preproc = sum(!is.na(myData$simplified.geometric.preprocessing) & is.na(myData$simplified.radiometric.preprocessing)) 
perc_radiom_preproc = sum(!is.na(myData$simplified.radiometric.preprocessing) & is.na(myData$simplified.geometric.preprocessing))
perc_both_preproc = sum(!is.na(myData$simplified.radiometric.preprocessing) & !is.na(myData$simplified.geometric.preprocessing)) 

# create data frame from counts
Type <- c('NA', 'NA', 'Geom', 'Radio', 'Both')
Fiducials <- c('No', 'Not specified', 'yes', 'yes', 'yes')
Count <- c(perc_no_preproc, perc_notspec_preproc, perc_geom_preproc, perc_radiom_preproc, perc_both_preproc)
PD <- data.frame(Type, Fiducials, Count)
print (PD)

## Shape of dataframe:
## # Groups:   Class [4]
##   Type Done    Count
## 1 NA   No         113
## 2 NA   Not specified        334
## 3 Geom Yes         158
## 4 Radio   Yes        23
## 5 Both   Yes         26

plt_pie_donut <- PieDonut(PD, 
                          aes(Fiducials, Type, count=Count), 
                          ratioByGroup = TRUE, 
                          explode = 3,
                          pieLabelSize = 5,
                          donutLabelSize = 4)


png(paste(wd_path, "Rplot_pie_donut_fiducials.png"), units="in", width=5, height=5, res=300) #print
plot(plt_pie_donut)
dev.off()

# TODO: Automatic export does not work properly... need to export via "Export" option in R Studio. 
  
  
  

