library(shiny)
library(leaflet)
library(mapedit)
library(sf)
library(dplyr)
library(rgee)
library(DT)
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
bq_auth(path = "C:/Users/reto.spielhofer/OneDrive - NINA/Documents/Projects/WENDY/eu-wendy_service_account.json")
con <- dbConnect(
  bigrquery::bigquery(),
  project = "eu-wendy",
  dataset = "testWendy",
  billing = "eu-wendy"
)



## define on - offshore min-max area km2
on_min<-500
on_max<-3000
off_min<-500
off_max<-10000

# con <- dbConnect(
#   bigrquery::bigquery(),
#   project = "publicdata",
#   dataset = "samples",
#   billing = ""
# )

# con <- dbConnect(
#   bigrquery::bigquery(),
#   project = "rgee-381312",
#   dataset = "data_base",
#   billing = "rgee-381312"
# )
# es_all<-tbl(con, "test")


## country map
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


# coast<-st_read("R:/GeoSpatialData/SeaRegions/World_oceans/Original/ne_10m_ocean/ne_10m_ocean.shp")
# bbcoast<-st_as_sfc(st_bbox(c(-20.742171, 28.025439, 43.066422, 72.61762)),crs = st_crs(coast))
# sea<-st_crop(bbcoast,coast)

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

ee_Initialize()

es_descr<-read.csv("C:/Users/reto.spielhofer/OneDrive - NINA/Documents/Projects/WENDY/PGIS_ES/data_base/setup_230710/es_descr.csv")