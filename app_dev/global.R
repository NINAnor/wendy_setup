library(shiny)
library(leaflet)
library(mapedit)
library(sf)
library(dplyr)
library(rgee)
library(DT)
library(shinyjs)
library(shinycssloaders)
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

## change this to wendy
bq_auth(path = "C:/Users/reto.spielhofer/OneDrive - NINA/Documents/Projects/WENDY/eu-wendy-92974cdf189d.json")
con <- dbConnect(
  bigrquery::bigquery(),
  project = "eu-wendy",
  dataset = "integrated_wendy",
  billing = "eu-wendy"
)



## define on - offshore min-max area km2
on_min<-50
on_max<-1000
off_min<-500
off_max<-2000

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

coast<-gisco_get_coastallines()


map_cntr<- leaflet() %>%
  addProviderTiles(provider= "CartoDB.Positron")%>%
  addFeatures(st_sf(cntr), layerId = ~cntr$CNTR_ID)

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

ee_Initialize("reto.spielhofer@nina.no")

es_descr<-tbl(con, "es_descr")
es_descr<-es_descr%>%collect()
