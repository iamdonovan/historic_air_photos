
library(colormap)
library(ggpubr)
library(ggplot2)
library(RColorBrewer)
library(directlabels)
library(colorRamps)
library(scales)
library(tools)
library(patchwork)
library(ggrepel)
library(dplyr)
library(zoo)
library(grid)
library(stats)
library(data.table)
library(DescTools)
library(oce)
options(digits = 5, scipen = 50)
text_size = 9
line_thickness = 0.25
inch_converting =  2.54


# ------------------------------------------------------------
# initialisation and preparation of dataframe to be evaluable
# ------------------------------------------------------------

# set paths
wd_path <- "E:/PROJECTS/REVIEW_HIST_PHOTOS/historic_air_photos/"
reviewSheet <- paste(wd_path,"data/Review_Historic_Air_Photos.csv",sep = "")

# import datasheet, restore individual keys (one key per dataset)
myData = read.csv(file = reviewSheet, header = TRUE, sep = "," ,na.strings=c("","NA"))
myData$datnno <- with(myData, ave(seq_along(Key), Key, FUN=seq_along))
myData = myData %>% 
  unite(Key2, c("Key", "datnno"))
# clean up data
myData$Fiducial.Marks[is.na(myData$Fiducial.Marks)] <- "not specified"
myData$Fiducial.Marks <- factor(myData$Fiducial.Marks)

myData$Comparison.source.group <- as.character(myData$Comparison.source.group)
myData$Comparison.source.group[is.na(myData$Comparison.source.group)] <- "not specified"
myData$Comparison.source.group[myData$Comparison.source.group == 'diverse'] <- "not specified"

# make it simpler and create a sub data frame only containing pre-processing-related content
df_acc <- data.frame(
  'key' = myData$Key2, 
  'ImgType' = myData$Data.Type,
  'DEMRes' = myData$DEM.resolution..m., 
  'OrthoRes' = myData$Orthophoto.resolution..m., 
  'CompSrcGroup' = myData$Comparison.source.group,
  "ResComp" = myData$Residuals.to.comparison..m..avg, 
  "ResGCP" = myData$Residuals.to.GCPs..m..avg,
  "ResCP" = myData$Residuals.to.CPs..m..avg.1, # what happened to "Residuals.to.CPs..m..avg
  "AccComp" = myData$Accuracy.comparison..m..avg,
  "Fid" = myData$Fiducial.Marks)

df_acc <- df_acc[order(df_acc$ResComp),] #reorder
df_acc_satellite <- subset(df_acc, ImgType=='Satellite')
df_acc_aerial <- subset(df_acc, ImgType=='Aerial')



# SATELLITE #
# 1.Residuals to comparison, ordered ascending, colored by use of fiducials 
plt_sat_fid_resid <- ggplot(
  subset(df_acc, ImgType=='Satellite'), 
  aes(x=1:nrow(df_acc_satellite), 
      y=ResComp, 
      colour=Fid, 
      shape=CompSrcGroup), 
  na.rm = TRUE) +
  geom_hline(yintercept = 0, color = "gray80", size = 0.5) + # thick zero line
  geom_point(size=2) +
  xlim(0,51) + ylim(-15,30) + 
  geom_errorbar(aes(
    ymin=ResComp - AccComp, 
    ymax=ResComp + AccComp), 
    width=.3,
    position=position_dodge(.9)) + 
  labs(title="Hist. Satellite Images",x ="ID", y = "Residuals to comparison data [m]", shape = "Comparison Src", colour = "Fiducials?") + 
  theme_light() + # bw light theme
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 14), legend.position="bottom", legend.box="vertical", legend.margin=margin(),
        legend.text = element_text(size=14), title = element_text(size=14, face = 'bold')) + 

png(paste(wd_path, "Rplot_Sat_ResidComp_Fiducials.png"), units="in", width=10, height=5, res=300) #print
plot(plt_sat_fid_resid)
dev.off()

# AERIAL #
# 1.Residuals to comparison, ordered ascending, colored by use of fiducials 
plt_sat_fid_resid <- ggplot(
  subset(df_acc, ImgType=='Aerial'), 
  aes(x=1:nrow(df_acc_aerial), 
      y=ResComp, 
      colour=Fid, 
      shape=CompSrcGroup), 
  na.rm = TRUE) +
  geom_hline(yintercept = 0, color = "gray80", size = 0.5) + # thick zero line
  geom_point(size=2)  +  xlim(0,125) + ylim(-2.5,20) + 
  geom_errorbar(aes(
    ymin=ResComp - AccComp, 
    ymax=ResComp + AccComp), 
    width=.3,
    position=position_dodge(.9)) + 
  labs(title="Hist. Aerial Images",x ="ID", y = "Residuals to comparison data [m]", shape = "Comparison Src", colour = "Fiducials?") + 
  theme_light() + # bw light theme
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 14), legend.position="bottom", legend.box="vertical", legend.margin=margin(),
        legend.text = element_text(size=14), title = element_text(size=14, face = 'bold')) + 

png(paste(wd_path, "Rplot_Aerial_ResidComp_Fiducials.png"), units="in", width=10, height=5, res=300) #print
plot(plt_sat_fid_resid)
dev.off()




print(paste("Number of Vals used in 'Rplot_Satellite_ResidComp_Fiducials.png':" , sum(!is.na(df_acc_satellite$ResComp))))
print(paste("Number of Vals used in 'Rplot_Aerial_ResidComp_Fiducials.png':" , sum(!is.na(df_acc_aerial$ResComp))))





