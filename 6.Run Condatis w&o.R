################################################
#                                              #
#   Speed change Within and Outside B-lines    #
#                                              #
################################################

#This script runs the Condatis function to calculate the speed metric in the landscapes selected in step 5

#The script iterates the calculation of speed using different dispersal distances within the range estimated in step 1

#The result is a table with the speed corresponding to a particular dispersal distance

#The area under the curve (AUC) of dispersal distance vs speed is calculated for both landscapes, i.e. habitat within B-line and habitat outside B-line project intervention. Then, the percentage of change in speed between both landscape curves is calculated.

#INPUTS:
# Hab - raster of the habitat you wish to measure connectivity over (habitat.tif/ habitat_bl.tif obtained with the layer preparation script)
# st - raster of location of sources and targets (st.tif obtained with the layer preparation script)
# R - R value of the species moving (number of movers produced per km^2 of habitat), fixed to 1000
# disp - range of dispersal distance per group

library(raster)
library(sf)
library(tidyverse)
library(rgdal)
library(dplyr)
library(ggplot2)
library(maptools)
library(scales)
library(DescTools)

# Run Condatis with dispersal distance iteration --------------------------


#Rasters of AOI habitat and source and target within B-line 
hab<- raster("spatialdata/habitatW.tif") #3k grid @ 10m resolution
st<- raster("spatialdata/stW.tif")
R<-1000

#Dispersal distance for bees and hoverflies (0.015-10.4km)
disper <-c(10^seq(-1.8,0.5,0.1)) #maximum distance between 

#Dispersal distance for moths (0.00043-81.1km)
#disper <-10^seq(-3.367,1.91,0.2)

test_result<-data.frame()
for(i in disper) {
  test<-CondatisNR(hab=hab, st=st, R=R, disp=i)
  test_result<- rbind(test_result, test$conductance)
}

colnames(test_result)<-c("disp" , "conductance")

con<- data.frame(test_result %>%
                   group_by(disp)%>%
                   summarise(Conduct = mean(conductance)))

write.csv(con, "conductance/testW.csv")




#Raster of AOI outside B-line 
hab<-raster("spatialdata/habitatO.tif") #2k square @ 5m resolution
st<- raster("spatialdata/stO.tif")
R<-1000

#Dispersal distance for bees and hoverflies (0.015-10.4km)
disper <-c(10^seq(-1.8,0.5,0.1))

#Dispersal distance for moths (0.00043-81.1km)
#disper <-10^seq(-3.367,1.91,0.2)

test_result<-data.frame()
for(i in disper) {
  test<-CondatisNR(hab=hab, st=st, R=R, disp=i)
  test_result<- rbind(test_result, test$conductance)
}

colnames(test_result)<-c("disp" , "conductance")

con<- data.frame(test_result %>%
                   group_by(disp)%>%
                   summarise(Conduct = mean(conductance)))

write.csv(con, "conductance/testO.csv")

# Plot results ------------------------------------------------------------

#Joining results of the conductance of landscapes within('Within BL')) and outside ('Outside BL') B-lines
condW<- data.frame(read.csv("conductance/testW.csv"))
condO<- data.frame(read.csv("conductance/testO.csv"))
conductance<-data.frame(cond$disp, condW$Conduct, condO$Conduct)
colnames(conductance)<-c('disp_dist', 'Whithin','Outside')

#Rearranging the conductance data frame to plot both landscapes
conductance.long <- conductance %>% 
  select('disp_dist', 'Whithin','Outside') %>% 
  pivot_longer(-disp_dist, names_to = "Variable", values_to = "speed")


#plot absolute dispersal distance vs speed
ggplot(conductance.long, aes(disp_dist, speed, colour = Variable)) + 
  geom_point(size = 5)+
  labs(x = 'Dispersal distance [km]', y='Speed')+
  theme(text = element_text(size = 30), legend.position="right",
        legend.title=element_blank())

#plot absolute dispersal distance vs log speed
ggplot(conductance.long, aes(disp_dist, log10(speed), colour = Variable)) + 
  geom_point(size = 4)+
  labs(x = 'Dispersal distance [km]', y='log(Speed)')+
  theme(text = element_text(size = 20))


#plot log dispersal distance vs log speed
ggplot(conductance.long, aes(log10(disp_dist), log10(speed), colour = Variable))+ 
  geom_point(size = 5)+
  labs(x = 'log (Dispersal distance) [km]', y='log(Speed)' )+
  scale_x_continuous(breaks=c(-1.5,-1,-0.5,0,0.5))+
  theme(text = element_text(size = 30), legend.position="right",
        legend.title=element_blank())




# Estimate change of speed due to intervention ----------------------------

Wbl_area<-AUC(conductance$disp_dist, conductance$`Whithin BL`)
Wbl_area
Obl_area<-AUC(conductance$disp_dist, conductance$`Outside BL`)
Obl_area
change<-Wbl_area-Obl_area
perc_changeWO<-(change/Obl_area)*100
perc_changeWO
