
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
library(tidyr) # for separate
library(stringr) # Load stringr
library(reshape)
library(stringr)
library(forcats)

options(digits = 5)
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
myData$Pre.processing[is.na(myData$Pre.processing)] <- "not specified" # clean up data base
myData$datnno <- with(myData, ave(seq_along(Key), Key, FUN=seq_along))
myData = myData %>% 
  unite(Key2, c("Key", "datnno"))

# make it simpler and create a sub data frame only containing pre-processing-related content
df_preproc <- data.frame(
  'key' = myData$Key2, 
  'PreProc' = myData$Pre.processing, 
  'Geom' = myData$simplified.geometric.preprocessing, 
  "Radio" = myData$simplified.radiometric.preprocessing, 
  "ImgType" = myData$Data.Type)

# remove rows where Pre.processing = "not specified" or "no"
df_preproc <- df_preproc[!(df_preproc$PreProc=="not specified" | df_preproc$PreProc=="no"),]
df_preproc$PreProc <- NULL #df contains only datasets that have been pre processed. no need to keep "pre processing" column 

# separate multiple vals in columns, separated by commata, into separate cols (e.g. 'mosaicing, cropping' -> Geom_1 (col): mosaicing, Geom_2 (col): cropping)
df_preproc <- separate(df_preproc, 'Geom', paste("Geom", 1:4, sep="_"), sep=",", extra="drop")
df_preproc <- separate(df_preproc, 'Radio', paste("Radio", 1:4, sep="_"), sep=",", extra="drop")

# convert data frame in evaluable structure
dm1 <- melt(df_preproc[,c("key","Geom_1","Geom_2","Geom_3","Geom_4")], id="key")
dm2 <- melt(df_preproc[,c("key","Radio_1","Radio_2","Radio_3","Radio_4")], id="key")
dm3 <- melt(df_preproc[,c("key","ImgType")], id="key")
colnames(dm1) <- c("key", "variable", "Geom") # rename cols
colnames(dm2) <- c("key", "variable", "Radio") # rename cols
colnames(dm3) <- c("key", "variable", "ImgType") # rename cols
dm1 <- dm1[ , ! names(dm1) %in% c("variable")] # drop unnecessary cols
dm2 <- dm2[ , ! names(dm2) %in% c("variable")] # drop unnecessary cols
dm3 <- dm3[ , ! names(dm3) %in% c("variable")] # drop unnecessary cols
dm1 <- dm1[!with(dm1,is.na(dm1$Geom)),] #remove NA lines
dm2 <- dm2[!with(dm2,is.na(dm2$Radio)),] #remove NA lines
dm3 <- dm3[!with(dm3,is.na(dm3$ImgType)),] #remove NA lines
temp <- merge(dm1, dm2, by="key", all=TRUE) # merge everything together by restored keys (one key per dataset)
df_preproc <- merge(temp, dm3, by="key", all=TRUE) # update dataframe

# -----------------------------------------------------------------------
# Unify terms in table - @all: Please feel free to make adjustments here!
# -----------------------------------------------------------------------
# I've tried as best i can here to find a generic term for what could be read in the table in the respective columns of the processing steps
# feel free to edit, rearrange or find better unique terms to plot

# fuse RADIOMETRIC pp steps to single terms that should be plotted
df_preproc$Radio <- factor (df_preproc$Radio)
df_preproc$Radio <- as.character (df_preproc$Radio )
df_preproc$Radio <- ifelse(grepl("contrast", df_preproc$Radio), "contrast enhancement", df_preproc$Radio)
df_preproc$Radio <- ifelse(grepl("denoise", df_preproc$Radio), "denoise", df_preproc$Radio)
df_preproc$Radio <- ifelse(grepl("sharpening", df_preproc$Radio), "sharpening", df_preproc$Radio)
df_preproc$Radio <- ifelse(grepl("intensity", df_preproc$Radio), "intensity enhancement", df_preproc$Radio)
df_preproc$Radio <- ifelse(grepl("radiometric", df_preproc$Radio), "radiometric alignment", df_preproc$Radio)
df_preproc$Radio <- ifelse(grepl("no details", df_preproc$Radio), "no details specified", df_preproc$Radio)
df_preproc$Radio <- ifelse(grepl("exposure", df_preproc$Radio), "exposure enhancement", df_preproc$Radio)



# fuse GEOMETRIC pp steps to single terms that should be plotted
df_preproc$Geom <- ifelse(grepl("cropping", df_preproc$Geom), "cropping", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("down", df_preproc$Geom), "downsampling", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("masking", df_preproc$Geom), "masking", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("mosaic", df_preproc$Geom), "mosaicing", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("manual IOP", df_preproc$Geom), "pre-calibration", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("pp to center", df_preproc$Geom), "pre-calibration", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("pre-calib", df_preproc$Geom), "pre-calibration", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("affine transformation", df_preproc$Geom), "image transformation", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("resamp", df_preproc$Geom), "image transformation", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("resize", df_preproc$Geom), "image transformation", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("rotat", df_preproc$Geom), "image transformation", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("scaling", df_preproc$Geom), "image transformation", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("warp", df_preproc$Geom), "image transformation", df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("undistortion", df_preproc$Geom), "undistortion", df_preproc$Geom)

# preproc steps that are related to geometry but not directly applied to the image
df_preproc$Geom <- ifelse(grepl("detection", df_preproc$Geom), NA, df_preproc$Geom) #???
df_preproc$Geom <- ifelse(grepl("meta", df_preproc$Geom), NA, df_preproc$Geom) # meta information derived

# word fragments in geometric pre-proc table. delete.
df_preproc$Geom <- ifelse(grepl("imgs same", df_preproc$Geom), NA, df_preproc$Geom) 
df_preproc$Geom <- ifelse(grepl("high dist", df_preproc$Geom), NA, df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("keep fiducials", df_preproc$Geom), NA, df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("pseudo", df_preproc$Geom), NA, df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("sky", df_preproc$Geom), NA, df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("moving", df_preproc$Geom), NA, df_preproc$Geom)
df_preproc$Geom <- ifelse(grepl("other", df_preproc$Geom), NA, df_preproc$Geom)




# ---------
# plotting
# ---------

# separate dataframe by geometric and radiometric preprocessing (might not be necessary but makes things easier)
df_preproc_geom <- data.frame('key' = df_preproc$key, 'Geom' = df_preproc$Geom, "ImgType" = df_preproc$ImgType)
df_preproc_radio <- data.frame('key' = df_preproc$key, 'Radio' = df_preproc$Radio, "ImgType" = df_preproc$ImgType)

# remove rows containing NA in Geom/Radio col
df_preproc_geom <- df_preproc_geom[!with(df_preproc_geom,is.na(df_preproc_geom$Geom)),] #remove NA lines
df_preproc_radio <- df_preproc_radio[!with(df_preproc_radio,is.na(df_preproc_radio$Radio)),] #remove NA lines

# Geometric Preprocessing
# exclude Mix and Terrestrial from plotting
fig_preproc_geom <- ggplot(data=subset(df_preproc_geom, !is.na(Geom) & !ImgType=="Terrestrial" & !ImgType=="Mix" ), aes(x=forcats::fct_infreq(Geom),  fill=ImgType, color = ImgType)) + 
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) + 
  geom_bar(alpha = 0.5) + 
  #ylim(c(0,100)) +
  labs( x ="", y="Count") + #title="Accuracy of Ground Control Information",
  theme_light() + # bw light 
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 14), legend.position="top", 
        legend.text = element_text(size=14), title = element_text(size=14, face = 'bold'))
png(paste(wd_path, "fig_preproc_geom.png"), units="in", width=8, height=4, res=300) #print
# insert ggplot code
plot(fig_preproc_geom)
dev.off()

# Radiometric Preprocessing
# exclude Max and Terrestrial from plotting
fig_preproc_radio <- ggplot(data=subset(df_preproc_radio, !is.na(Radio) & !ImgType=="Terrestrial" & !ImgType=="Mix" ), aes(x=forcats::fct_infreq(Radio), fill=ImgType, color = ImgType)) + 
  scale_x_discrete(labels = function(x) str_wrap(x, width = 10)) + 
  geom_bar(alpha = 0.5) + 
  #ylim(c(0,80)) +
  labs( x ="", y="Count") + #title="Accuracy of Ground Control Information",
  theme_light() + # bw light 
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 14), legend.position="top", 
        legend.text = element_text(size=14), title = element_text(size=14, face = 'bold'))
png(paste(wd_path, "fig_preproc_radio.png"), units="in", width=8, height=4, res=300) #print
# insert ggplot code
plot(fig_preproc_radio)
dev.off()


