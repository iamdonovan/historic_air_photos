
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
library(tidyr)

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


# Aerial, Satellite, Mix, Terrestrial
# exlude aerial, mix, terrestrial 
myData_Satellite <-myData[myData$Data.Type=="Satellite",]
myData_Aerial <-myData[myData$Data.Type=="Aerial",]




# --------------
# SATELLITE ----
# --------------
# DEM Resolution / Orthophoto Resolution, Ordered Ascending
myData_Satellite <- myData_Satellite[order(myData_Satellite$DEM.resolution..m., myData_Satellite$Orthophoto.resolution..m.),] #reorder by DEM and Ortho res

# Scatter plot + Histogram on DEM/Ortho resolution
# create own df for this and melt variables to enable color separation
# 22.07.22: add application
sat_res_data_DEM <- myData_Satellite$DEM.resolution..m
sat_res_data_Ortho <- myData_Satellite$Orthophoto.resolution..m.
sat_res_data_key <- 1:nrow(myData_Satellite)
sat_res_data <- data.frame('id' = sat_res_data_key, "DEM" = sat_res_data_DEM,  "Orthophoto" = sat_res_data_Ortho)

sat_res_data_mm <- melt(as.data.table(sat_res_data), id = 'id')
sat_res_data_mm$value=as.numeric(sat_res_data_mm$value) #important that col contains unique vals

# Scatter plot
plt_sat_out_res <- ggplot(sat_res_data_mm, aes(x=id) , na.rm = TRUE) + 
  geom_point(aes(y=value, color=variable), na.rm = TRUE) + 
  xlim(0,80) + 
  ylim(0,60) + 
  labs(title="Hist. Satellite images: Output resolution [m]",x ="", y = "Output resolution [m]", color = "Output")  + 
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20))
png(paste(wd_path, "Rplot_Sat_Output_Resolution.png"), units="in", width=10, height=5, res=300) #print
plot(plt_sat_out_res)
dev.off()

# Histogram
plt_sat_out_res_hist <- ggplot(sat_res_data_mm, aes(x=value, fill=variable)) + 
  geom_histogram(position="dodge", binwidth=2, na.rm = TRUE, alpha = 0.75, boundary = 0, color="gray") + #bins=20 
  labs(title = "Histogram: Hist. Satellite Images: Output resolution [m]", x ="Resolution [m]", y="Count", fill = "Output", color = "Output") + 
  scale_x_continuous(limits=c(0,30), breaks = seq(0, 30, by = 2))+
  scale_y_continuous(limits=c(0,150), breaks = seq(0, 150, by = 25))+
  #xlim (-2,30) + 
  #ylim(0,110) +
  theme(plot.title = element_blank(), text = element_text(size = 20))
png(paste(wd_path, "Rplot_Satellite_Output_Resolution_Histo.png"), units="in", width=10, height=5, res=300) #print
plot(plt_sat_out_res_hist)
dev.off()





# DEM res_ category
sat_res_data_Cat <- myData_Satellite$Category
sat_res_data['Category'] = sat_res_data_Cat
sat_res_data_DEM<-subset(sat_res_data, !is.na(sat_res_data$DEM) & sat_res_data$DEM < 50.0) # drop NA, and filter outliers

plt_sat_out_res_hist_DEM <- ggplot(sat_res_data_DEM, aes(x=DEM, fill=Category))+#, color=Category)) + 
  geom_histogram(position="stack", breaks = c(0.0, 1.0,2.5, 5.0,10.0,20.0,30.0), na.rm = TRUE, alpha = 0.75, color="gray", boundary = 0) + #bins=20 
  scale_x_continuous(trans=scales::pseudo_log_trans(base = 10),breaks = c(0.0, 1.0, 2.5, 5.0,10.0,20.0,30.0))+
  scale_y_continuous(limits=c(0,50), breaks = seq(0, 50, by = 10)) +
  scale_fill_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  scale_color_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  labs (title = element_blank(), x ="Resolution [m]", y="Count", fill = "Category") +
  #labs(title = "Histogram: Hist. Aerial Images: Output resolution [m]", x ="Resolution [m]", y="Count", fill = "Category") + 
  theme_light()+
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20), legend.position = 'bottom',  legend.box="vertical", legend.margin=margin()) +
  guides(fill=guide_legend(nrow=2,byrow=TRUE))
  
png(paste(wd_path, "Rplot_Satellite_Output_Resolution_Histo_DEM_Cat.png"), units="in", width=7.5, height=5, res=300) #print
plot(plt_sat_out_res_hist_DEM)
dev.off()

#<0.5m, 0.5-1, 1-2, 2-5, 5-10 ?


#Ortho category
sat_res_data_ortho<-subset(sat_res_data, !is.na(sat_res_data$Orthophoto) & sat_res_data$Orthophoto < 50.0) # drop NA, and filter outliers

plt_sat_out_res_hist_ortho <- ggplot(sat_res_data_ortho, aes(x=Orthophoto, fill=Category))+#, color=Category)) + 
  geom_histogram(position="stack", breaks = c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 4.5, 5.0, 5.5, 6.0), na.rm = TRUE, alpha = 0.75, color="gray", boundary = 0) + #bins=20 
  scale_x_continuous(trans=scales::pseudo_log_trans(base = 10),breaks = c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 4.0, 4.5, 5.0, 5.5, 6.0))+
  scale_y_continuous(limits=c(0,50), breaks = seq(0, 150, by = 25))+
  scale_fill_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  scale_color_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  labs (title = element_blank(), x ="Resolution [m]", y="Count", fill = "Category") +
  #labs(title = "Histogram: Hist. Aerial Images: Output resolution [m]", x ="Resolution [m]", y="Count", fill = "Category") + 
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20), legend.position = 'bottom',  legend.box="vertical", legend.margin=margin()) + 
  guides(fill=guide_legend(nrow=2,byrow=TRUE))

png(paste(wd_path, "Rplot_Satellite_Output_Resolution_Histo_Ortho_Cat.png"), units="in", width=9, height=5, res=300) #print
plot(plt_sat_out_res_hist_ortho)
dev.off()



# -----------
# AERIAL ----
# -----------
# DEM Resolution / Orthophoto Resolution, Ordered Ascending
myData_Aerial <- myData_Aerial[order(myData_Aerial$DEM.resolution..m., myData_Aerial$Orthophoto.resolution..m.),] #reorder by DEM and Ortho res

# Scatterplot + Histogram on DEM/Ortho resolution
# create own df for this and melt variables to enable color seperation
aerial_res_data_DEM <- myData_Aerial$DEM.resolution..m
aerial_res_data_Ortho <- myData_Aerial$Orthophoto.resolution..m.
aerial_res_data_key <- 1:nrow(myData_Aerial)
aerial_res_data <- data.frame('id' = aerial_res_data_key, 'DEM' = aerial_res_data_DEM, 'Orthophoto' = aerial_res_data_Ortho)
aerial_res_data_mm <- melt(as.data.table(aerial_res_data), id = 'id')

aerial_res_data_mm$value=as.numeric(aerial_res_data_mm$value) #important that col contains unique vals

#outlier removal
aerial_res_data_mm<-subset(aerial_res_data_mm, aerial_res_data_mm$value < 50.0) # drop NA, and filter outliers

# Scatter plot
plt_aerial_out_res <- ggplot(aerial_res_data_mm, aes(x=id)) + 
  geom_point(aes(y=value, color=variable), na.rm = TRUE) + 
  #xlim(0,250) + ylim(0,60) + 
  labs(title="Hist. Aerial images: Output resolution [m]",x ="", y = "Output resolution [m]", color = "Output")  + 
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20))

png(paste(wd_path, "Rplot_Aerial_Output_Resolution.png"), units="in", width=10, height=5, res=300) #print
plot(plt_aerial_out_res)
dev.off()

# Histogram
# position = dodge - graphs side-by-side
# position = identity - graphy overlap each other
# stack - stacked

plt_aerial_out_res_hist <- ggplot(aerial_res_data_mm, aes(x=value, fill=variable)) + 
  geom_histogram(position="dodge", binwidth=2, na.rm = TRUE, alpha = 0.75, boundary = 0, color="gray") + #bins=20 
  labs(title = "Histogram: Hist. Aerial Images: Output resolution [m]", x ="Resolution [m]", y="Count", fill = "Output") + 
  scale_x_continuous(limits=c(0,30), breaks = seq(0, 30, by = 2))+
  scale_y_continuous(limits=c(0,150), breaks = seq(0, 150, by = 25))+
  #xlim (-2,30) + 
  #ylim(0,110) +
  theme(plot.title = element_blank(), text = element_text(size = 20))

png(paste(wd_path, "Rplot_Aerial_Output_Resolution_Histo.png"), units="in", width=10, height=5, res=300) #print
plot(plt_aerial_out_res_hist)
dev.off()


# DEM res_ category
aerial_res_data_Cat <- myData_Aerial$Category
aerial_res_data['Category'] = aerial_res_data_Cat
aerial_res_data_DEM<-subset(aerial_res_data, !is.na(aerial_res_data$DEM) & aerial_res_data$DEM < 50.0) # drop NA, and filter outliers

plt_aerial_out_res_hist_DEM <- ggplot(aerial_res_data_DEM, aes(x=DEM, fill=Category))+#, color=Category)) + 
  geom_histogram(position="stack", breaks = c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 5.0,10.0,20.0,30.0), na.rm = TRUE, alpha = 0.75, color="gray", boundary = 0) + #bins=20 
  scale_x_continuous(trans=scales::pseudo_log_trans(base = 10),breaks = c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 5.0,10.0,20.0,30.0))+
  scale_y_continuous(limits=c(0,75), breaks = seq(0, 75, by = 25)) +
  scale_fill_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  scale_color_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  labs (title = element_blank(), x ="Resolution [m]", y="Count", fill = "Category") +
  #labs(title = "Histogram: Hist. Aerial Images: Output resolution [m]", x ="Resolution [m]", y="Count", fill = "Category") + 
  theme_light()+
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20), legend.position = 'bottom',  legend.box="vertical", legend.margin=margin()) + 
  guides(fill=guide_legend(nrow=2,byrow=TRUE))
png(paste(wd_path, "Rplot_Aerial_Output_Resolution_Histo_DEM_Cat.png"), units="in", width=10, height=5, res=300) #print
plot(plt_aerial_out_res_hist_DEM)
dev.off()

# Ortho res_ category
aerial_res_data_Ortho<-subset(aerial_res_data, !is.na(aerial_res_data$Orthophoto) & aerial_res_data$Orthophoto < 50.0) # drop NA, and filter outliers

plt_aerial_out_res_hist_Ortho <- ggplot(aerial_res_data_Ortho, aes(x=Orthophoto, fill=Category))+#, color=Category)) + 
  geom_histogram(position="stack", breaks = c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,7.5), na.rm = TRUE, alpha = 0.75, color="gray", boundary = 0) + #bins=20 
  scale_x_continuous(trans=scales::pseudo_log_trans(base = 10),breaks = c(0.0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0,7.5))+
  scale_y_continuous(limits=c(0,80), breaks = seq(0, 150, by = 25))+
  scale_fill_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  scale_color_manual(values = c("Archeology" = "orange3", "Forestry" = "forestgreen", "Geomorphology" = "orange4", "Glaciology" = "steelblue1", "Landuse/Landcover" = "mediumpurple1", "Methodology" = "azure4", "Urban Change" = "lightblue4", "Volcanology" = "brown2")) +
  labs (title = element_blank(), x ="Resolution [m]", y="Count", fill = "Category") +
  #labs(title = "Histogram: Hist. Aerial Images: Output resolution [m]", x ="Resolution [m]", y="Count", fill = "Category") + 
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20), legend.position = 'bottom',  legend.box="vertical", legend.margin=margin()) + 
  guides(fill=guide_legend(nrow=2,byrow=TRUE))
png(paste(wd_path, "Rplot_Aerial_Output_Resolution_Histo_Ortho_Cat.png"), units="in", width=10, height=5, res=300) #print
plot(plt_aerial_out_res_hist_Ortho)
dev.off()







