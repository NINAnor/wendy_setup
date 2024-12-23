# global.R
# Copyright (C) 2024 Reto Spielhofer; Norwegian Institute for Nature Research (NINA)
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <https://www.gnu.org/licenses/>.

library(shiny)
library(leaflet)
library(mapedit)
library(sf)
library(shinythemes)
library(dplyr)
library(DT)
library(shinyjs)
library(leafem)
library(tibble)
library(leafpop)
library(mapview)
library(shinyRadioMatrix)
library(shinylogs)
library(leaflet.extras)
library(leaflet.extras2)
library(stringi)
library(shinyWidgets)
library(tidyverse)
library(bigrquery)
library(DBI)
library(shinyjs)
library(shinyBS)
library(giscoR)
library(googleCloudStorageR)
library(shinybusy)
library(terra)
library(bsicons)
library(bslib)
library(irr)


## change this to wendy
### BQ connection to store rectangles
env<-"dev"
project<-"eu-wendy"
var_lang<-"en"
bqprojID<-"wendy"
bq_auth(
  path = "bq_wendy.json"
)


#bucket for pdf trigger
#bucket_name<-paste0(bqprojID,"_geopros_",env)
bucket_name<-"es_pdf"
gcs_auth("bq_wendy.json")
gcs_global_bucket(bucket_name)

source("mod_manage_study.R")
source("functions.R")


dataset <- paste0("wendy_",env)
# dataset <- "admin_data"

con_admin<-data.frame(
  project = project,
  dataset = dataset,
  billing = project
)


con_admin <- dbConnect(
  bigrquery::bigquery(),
  project = con_admin$project,
  dataset = con_admin$dataset,
  billing = con_admin$billing
)

orange = "#ffa626"
blue = "#53adc9"
green = "#50b330"


## define on - offshore min-max area km2
on_min<-50
on_max<-5000
off_min<-500
off_max<-15000

cntr<-gisco_get_countries(year = "2020",
                          epsg = "4326",
                          cache = TRUE,
                          update_cache = FALSE,
                          cache_dir = NULL,
                          verbose = FALSE,
                          resolution = "60",
                          spatialtype = "RG",
                          country = NULL,
                          region = "Europe")
cntr<-cntr%>%filter(CNTR_ID != "RU")

coast<-gisco_get_coastallines()
# coast<-st_read("data/eez_v12_sel.gpkg")


map_cntr<- leaflet(cntr) %>%
  addProviderTiles(provider= "CartoDB.Positron")%>%
  #addFeatures(st_sf(cntr), layerId = ~cntr$CNTR_ID)
  addPolygons(
    layerId = ~CNTR_ID, # Use CNTR_ID as layer ID
    fillColor = "blue",
    color = "black",
    weight = 1,
    highlightOptions = highlightOptions(color = "yellow", weight = 2, bringToFront = TRUE)
  )

map_coast<- leaflet(st_sf(coast)) %>%
  addPolygons(color = "blue", weight = 3, smoothFactor = 0.5,
              opacity = 1.0, fillOpacity = 0.3)%>%
  addProviderTiles(provider= "CartoDB.Positron")%>%
  addDrawToolbar(targetGroup='drawPoly',
                 polylineOptions = F,
                 polygonOptions = F,
                 circleOptions = F,
                 markerOptions = F,
                 circleMarkerOptions = F,
                 rectangleOptions = T,
                 singleFeature = FALSE,
                 editOptions = editToolbarOptions(selectedPathOptions = selectedPathOptions()))



# es_descr<-tbl(con_admin, "es_descr")
# es_descr<-es_descr%>%collect()



