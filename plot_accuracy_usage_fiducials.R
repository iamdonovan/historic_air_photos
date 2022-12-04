
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

df_acc_satellite <- subset(df_acc, ImgType=='Satellite')
df_acc_aerial <- subset(df_acc, ImgType=='Aerial')


# Usage of fiducials in percentage -> yes / no / not specified
perc_sat_fiduc_no = round(100 * sum(df_acc_satellite$Fid == "no") / length(df_acc_satellite$Fid), 2)
perc_sat_fiduc_yes = round(100 * sum(df_acc_satellite$Fid == "yes") / length(df_acc_satellite$Fid), 2)
perc_sat_fiduc_not_spec = round(100 * sum(df_acc_satellite$Fid == "not specified") / length(df_acc_satellite$Fid), 2)

perc_aerial_fiduc_no = round(100 * sum(df_acc_aerial$Fid == "no") / length(df_acc_aerial$Fid), 2)
perc_aerial_fiduc_yes = round(100 * sum(df_acc_aerial$Fid == "yes") / length(df_acc_aerial$Fid), 2)
perc_aerial_fiduc_not_spec = round(100 * sum(df_acc_aerial$Fid == "not specified") / length(df_acc_aerial$Fid), 2)



# Create donut charts 
# https://r-graph-gallery.com/128-ring-or-donut-plot.html
data_sat <- data.frame(
  category=c("yes", "no", "not specified"),
  count=c(perc_sat_fiduc_yes, perc_sat_fiduc_no, perc_sat_fiduc_not_spec)
)

# Compute percentages
data_sat$fraction <- data_sat$count / sum(data_sat$count)

# Compute the cumulative percentages (top of each rectangle)
data_sat$ymax <- cumsum(data_sat$fraction)

# Compute the bottom of each rectangle
data_sat$ymin <- c(0, head(data_sat$ymax, n=-1))

# Compute label position
data_sat$labelPosition <- (data_sat$ymax + data_sat$ymin) / 2

# Compute a good label
data_sat$label <- paste0(data_sat$category, "\n value: ", data_sat$count)

# Make the plot
plt_sat_fid <-ggplot(data_sat, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=category)) +
  geom_rect() +
  geom_label( x=3.5, aes(y=labelPosition, label=label), size=6) +
  scale_fill_brewer(palette=1) +
  coord_polar(theta="y") +
  xlim(c(2, 4)) +
  theme_void() +
  theme(legend.position = "none")

png(paste(wd_path, "Rplot_Sat_Fiducials.png"), units="in", width=5, height=5, res=300) #print
plot(plt_sat_fid)
dev.off()





# Create donut charts 
# https://r-graph-gallery.com/128-ring-or-donut-plot.html
data_aerial <- data.frame(
  category=c("yes", "no", "not specified"),
  count=c(perc_aerial_fiduc_yes, perc_aerial_fiduc_no, perc_aerial_fiduc_not_spec)
)

data_aerial$fraction <- data_aerial$count / sum(data_aerial$count)
data_aerial$ymax <- cumsum(data_aerial$fraction)
data_aerial$ymin <- c(0, head(data_aerial$ymax, n=-1))
data_aerial$labelPosition <- (data_aerial$ymax + data_aerial$ymin) / 2
data_aerial$label <- paste0(data_aerial$category, "\n value: ", data_aerial$count)

# Make the plot
plt_aerial_fid <- ggplot(data_aerial, aes(ymax=ymax, ymin=ymin, xmax=4, xmin=3, fill=category)) +
  geom_rect() +
  geom_label( x=3.5, aes(y=labelPosition, label=label), size=6) +
  scale_fill_brewer(palette=1) +
  coord_polar(theta="y") +
  xlim(c(2, 4)) +
  theme_void() +
  theme(legend.position = "none")


png(paste(wd_path, "Rplot_Aerial_Fiducials.png"), units="in", width=5, height=5, res=300) #print
plot(plt_aerial_fid)
dev.off()