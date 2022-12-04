
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

# TODO: script needs to be cleaned up! 
# split into individual scripts (one per figure / group)



wd_path <- "D:/TUD/ReviewPaper/historic_air_photos/figures/acc/"
reviewSheet <- "D:/TUD/ReviewPaper/historic_air_photos/data/Review_Historic_Air_Photos.csv"

# more colors needed? do this: https://www.datanovia.com/en/blog/easy-way-to-expand-color-palettes-in-r/
# Define the number of colors you want
# nb.cols <- length(unique(comp_data$comp_source))
# mycolors <- colorRampPalette(brewer.pal(8, "Set1"))(nb.cols)
# Create a ggplot with 18 colors 
# Use scale_fill_manual: scale_fill_manual(values = mycolors) 



myData = read.csv(file = reviewSheet, header = TRUE, sep = "," ,na.strings=c("","NA"))
myData$Fiducial.Marks[is.na(myData$Fiducial.Marks)] <- "not specified"
myData$Fiducial.Marks <- factor(myData$Fiducial.Marks)


# Aerial, Satellite, Mix, Terrestrial
# exlude aerial, mix, terrestrial 
myData_Satellite <-myData[!(myData$Data.Type=="Aerial" | myData$Data.Type=="Terrestrial" | myData$Data.Type=="Mix" ),]
myData_Aerial <-myData[!(myData$Data.Type=="Satellite" | myData$Data.Type=="Terrestrial" | myData$Data.Type=="Mix" ),]



# 4. Groundcontrol data: type and when used? aerial / satellite
# prep data
gcp_source <- myData$Ground.control.source.group
gcp_source <- as.character(gcp_source)
gcp_source[gcp_source == "?"] <- NA # remove some creepy stuff like "?" -> to NA
gcp_source <- factor(gcp_source)

gcp_accuracy_avg <- myData$Ground.control.accuraxy..m..avg
data_type <- myData$Data.Type
gcp_data <- data.frame("GCP source" = gcp_source, "GCP accuracy (avg) [m]" = gcp_accuracy_avg, "Data Type" = data_type)
gcp_data<-subset(gcp_data, data_type!="Terrestrial" & data_type!="Mix") #drop Terrestrial & Mix

gcp_data<-subset(gcp_data, !is.na(gcp_data$GCP.accuracy..avg...m.) & !is.na(gcp_data$GCP.source)) # drop NA, makes no sense to print this information


gcp_data <- gcp_data[order(gcp_data$GCP.source),] # sort dataset by accuracy



print(paste("Number of area-based GCP sources in 'aerial':" , length(which(gcp_data$GCP.source=='area-based' & gcp_data$Data.Type=='Aerial'))))
print(paste("Number of point-based GCP sources in 'aerial':" , length(which(gcp_data$GCP.source=='point-based' & gcp_data$Data.Type=='Aerial'))))
print(paste("Number of area-based GCP sources in 'satellite':" , length(which(gcp_data$GCP.source=='area-based' & gcp_data$Data.Type=='Satellite'))))
print(paste("Number of point-based GCP sources in 'satellite':" , length(which(gcp_data$GCP.source=='point-based' & gcp_data$Data.Type=='Satellite'))))



# Histogram: Source Ground Control Information
plt_gcp_bar_src_dt <- ggplot(gcp_data, aes(x=GCP.source, fill=Data.Type), na.rm = TRUE) + 
  geom_bar (position="identity", alpha = 0.75) +
  labs(x ="GCP source", y="Count", fill = "Data Type:") + #title = "Source of Ground Control Information"
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20), legend.position="top", 
        legend.text = element_text(size=14), title = element_text(size=14, face = 'bold'))
print(paste("Number of Datasets used in 'Rplot_source_groundcontrol.png':" , nrow(gcp_data)))

plt_gcp_hist_acc_src <- ggplot(gcp_data, aes(x=GCP.accuracy..avg...m., fill = GCP.source), na.rm = TRUE) + 
  geom_histogram(position="dodge", binwidth = 2, alpha = 0.75, boundary = 0, color = "gray") +
  #xlim(0,100) + ylim(0,20) +
  scale_y_continuous(limits=c(0,60), breaks = seq(0, 60, by = 15))+
  scale_x_continuous(limits=c(0,20), breaks = seq(0, 20, by = 2))+
  labs( x ="Accuracy [m]", y="Count", fill = "GCP Source:") + #title="Accuracy of Ground Control Information",
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 20), legend.position="top", 
        legend.text = element_text(size=14), title = element_text(size=14, face = 'bold'))

# fuse both graphics
#https://rdrr.io/cran/ggpubr/man/rremove.html
plt_gcp_bar_hist_src_acc <- ggarrange(plt_gcp_bar_src_dt, plt_gcp_hist_acc_src + rremove("y.title"), labels = c("A", "B"), ncol = 2, nrow = 1)
plt_gcp_bar_hist_src_acc <- annotate_figure(plt_gcp_bar_hist_src_acc, top = text_grob("Source / Accuracy of Ground Control Data", color = "black", size = 20)) #face = "bold", 
plt_gcp_bar_hist_src_acc <- annotate_figure(plt_gcp_bar_hist_src_acc, bottom = text_grob(paste("Considered datasets:", nrow(gcp_data), "(no NA)" ), color = "black", size = 14))
plt_gcp_bar_hist_src_acc

png(paste(wd_path, "Rplot_src_acc_gc.png"), units="in", width=8, height=5, res=300) #print
plot(plt_gcp_hist_acc_src) # changed! print only left side
dev.off()





# 5. Comparison data: source (simplified) and when used? aerial / satellite
# prep data 
comp_source <- myData$Comparison.data.simplified
comp_source <- as.character(comp_source)
comp_source[comp_source == "?"] <- NA # remove some creepy stuff like "?" -> to NA
# make things a bit easier and simplify the tags a bit more #20.5.22
comp_source[comp_source == "GCP"] <- "GCPs" # remove some creepy stuff like "?" -> to NA
comp_source[comp_source == "GCPs"] <- "GCPs" # remove some creepy stuff like "?" -> to NA
comp_source[comp_source == "CPs"] <- "CPs" # remove some creepy stuff like "?" -> to NA

# more unique
comp_source[comp_source == "ALS-DEM, TLS"] <- "DEM"
comp_source[comp_source == "ALS-DEM"] <- "DEM"
comp_source[comp_source == "ICESat"] <- "Altimetry"
comp_source[comp_source == "ICESat, ALS-DEM"] <- "diverse"
comp_source[comp_source == "Imgs, ALS-DEM"] <- "DEM"
comp_source[comp_source == "Imgs, SRTM, ICESat"] <- "diverse"
comp_source[comp_source == "StereoDEM"] <- "DEM"
comp_source[comp_source == "TLS"] <- "DEM"

comp_source <- factor(comp_source)
comp_accuracy_avg <- myData$Accurcy.comparison..m..avg
data_type <- myData$Data.Type
comp_source_group <- myData$Comparison.source.group

comp_data <- data.frame(comp_source, comp_accuracy_avg, data_type, comp_source_group)
comp_data <- comp_data[order(comp_data$comp_accuracy_avg),] #reorder by acc
comp_data_noNA <- subset(comp_data,!is.na(comp_accuracy_avg)) # drop all rows that contain no accuracy information!
comp_data_noNA <- subset(comp_data_noNA, (comp_source_group == 'area-based' | comp_source_group == 'point-based' )) # drop all rows that contain no accuracy information!

plt_compData_src_acc <- ggplot(comp_data_noNA, aes(x = comp_accuracy_avg, y=reorder(comp_source_group,comp_accuracy_avg)), na.rm = TRUE) + 
  #geom_line(aes(colour = comp_source), na.rm = TRUE) + 
  #geom_point(size=2, aes(colour=comp_source), na.rm = TRUE) +
  geom_line(na.rm = TRUE) + #no color
  geom_point(size=2, na.rm = TRUE, aes(colour = comp_source)) + #no color
  scale_x_continuous(trans="log10",breaks = c(0, 0.25, 0.5,1,2,4,6,8,10,25), labels = c(0, "<0.25", 0.5, 1,2,4,6,8,10,25)) +
  labs(title="Accuracy/Source of Comparison Information", x ="Accuracy [m]", y="Source", colour = "Source") +
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 15))

png(paste(wd_path, "Rplot_acc_src_comp_A.png"), units="in", width=10, height=3, res=300) #print
# insert ggplot code
plot(plt_compData_src_acc)
dev.off()


plt_compData_src_acc <- ggplot(comp_data_noNA, aes(x = comp_accuracy_avg, y=reorder(comp_source,comp_accuracy_avg)), na.rm = TRUE) + 
  #geom_line(aes(colour = comp_source), na.rm = TRUE) + 
  #geom_point(size=2, aes(colour=comp_source), na.rm = TRUE) +
  geom_line(na.rm = TRUE) + #no color
  geom_point(size=2, na.rm = TRUE) + #no color
  scale_x_continuous(trans="log10",breaks = c(0, 0.25, 0.5,1,2,4,6,8,10,25), labels = c(0, "<0.25", 0.5, 1,2,4,6,8,10,25)) +
  labs(title="Accuracy/Source of Comparison Information", x ="Accuracy [m]", y="Source", colour = "Source") +
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 15))

png(paste(wd_path, "Rplot_acc_src_comp_B.png"), units="in", width=10, height=3, res=300) #print
# insert ggplot code
plot(plt_compData_src_acc)
dev.off()



#6. GSD Input / Output
myData_dropped_DT <- subset(myData, Data.Type!="Terrestrial" & Data.Type!="Mix") # drop terrestrial and mixed
myData_dropped_DT <- subset(myData_dropped_DT,!is.na(GSD..m.)) # drop all rows that contain no accuracy information!
myData_dropped_DT <- subset(myData_dropped_DT,!is.na(Residuals.to.comparison..m..avg)) # drop all rows that contain no accuracy information!
myData_dropped_DT <- subset(myData_dropped_DT,(GSD..m. <= 10)) # drop all rows that contain no accuracy information!
myData_dropped_DT <- myData_dropped_DT[order(myData_dropped_DT$Residuals.to.comparison..m..avg, myData_dropped_DT$GSD..m.),] #reorder by DEM and Ortho res

iso_0.5 <- data.frame("x" = seq(0, 10, by = 0.1), "y" = seq(0, 50, by = 0.5))
iso_0.25 <- data.frame("x" = seq(0, 10, by = 0.1), "y" = seq(0, 25, by = 0.25))
iso_0.1 <- data.frame("x" = seq(0, 10, by = 0.1), "y" = seq(0, 10, by = 0.1))


plt_residuals_gsd <- ggplot() +
  geom_point(aes(x = myData_dropped_DT$GSD..m., y=myData_dropped_DT$Residuals.to.comparison..m..avg, colour=myData_dropped_DT$Data.Type)) + 
  geom_line(aes(x=iso_0.5$x, y=iso_0.5$y)) +
  geom_line(aes(x=iso_0.25$x, y=iso_0.25$y)) +
  geom_line(aes(x=iso_0.1$x, y=iso_0.1$y)) +
  ylim(0,20) +
  #scale_x_continuous(trans='log', limits = c(0, 10)) +
  scale_x_continuous(trans="log", breaks = c(0, 0.10, 0.25, 0.5,1,2,4,6,8,10), labels = c(0, 0.10, 0.25, 0.5, 1,2,4,6,8,10)) +
  #labs(title="Residuals to GSD", x ="GSD [m]", y="Residuals [m]", fill = "Data Type") +
  labs(x ="GSD [m]", y="Residuals [m]", colour = "Data Type") + #no title
  theme(plot.title = element_text(color="black", hjust=0.5), text = element_text(size = 15))

png(paste(wd_path, "Rplot_gsd_residuals_without_tl.png"), units="in", width=8, height=3, res=300) #print
# insert ggplot code
plot(plt_residuals_gsd)
dev.off()

#cor.test(myData$GSD..m., myData$Residuals.to.comparison..m..avg, method = c("kendall"))

