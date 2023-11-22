function(input, output, session) {

  output$cond_b1<-renderUI({
    validate(
      need(input$projtype != "", 'Provide a projtype'),
      need(input$proj_nat_name != '', 'Provide a project name'),
      need(input$proj_descr != '', 'Provide a proj description')
    )
    tagList(
      actionButton('sub1', 'confirm', class='btn-primary'),
      uiOutput("type_dep")
    )

  })

  observeEvent(input$sub1,{
    if(input$projtype == "onshore"){
      output$type_dep<-renderUI(
        tagList(
          textOutput("cntr_text"),
          mapedit::selectModUI("map_sel_cntry"),
          actionButton("save_countr","save country"),
          br(),
          conditionalPanel(condition = "cntry_sel != NULL",
            uiOutput("cntry_dep")

          )

        )
      )
    }else if(input$projtype == "offshore"){
      output$type_dep<-renderUI(
        tagList(
          mapedit::editModUI("sel_offshore"),
          htmlOutput("overlay_result2"),
          uiOutput("btn2"),
        )
      )
    }
    removeUI(selector = "div:has(>> #select)")
    removeUI(selector = "#proj_nat_name")
    removeUI(selector = "#proj_nat_name-label")
    removeUI(selector = "#proj_descr")
    removeUI(selector = "#proj_descr-label")
    removeUI(selector = "#sub1")
  })

  output$cntr_text<-renderText("Select your country of interest")
  #country map

      cntry_sel <- callModule(module=selectMod,
                        leafmap=map_cntr,
                        id="map_sel_cntry")

      # cntry_sel<-mapedit::selectMap(map_cntr)

      #reactive values to store mapping
      rv<-reactiveValues(
        onshore_sel = reactive({}),
        offshore_sel = reactive({})
      )

      rv$offshore_sel<-callModule(module = editMod,
                             leafmap=map_coast,
                             id="sel_offshore")

   # offshore_sel<-mapedit::editMap(map_coast)




  sel_country<-eventReactive(input$save_countr,{
    cntry_sel<-cntry_sel()
    sel_country<-st_sf(cntr%>%filter(CNTR_ID==cntry_sel[which(cntry_sel$selected==TRUE),"id"]))
  })

  observeEvent(input$save_countr,{
    sel_country<-sel_country()

    # display only the selected country
    map_onshore<- leaflet(sel_country) %>%
      addPolygons(color = "orange", weight = 3, smoothFactor = 0.5,
                  opacity = 1.0, fillOpacity = 0)%>%
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

    rv$onshore_sel<-callModule(module = editMod,
                               leafmap=map_onshore,
                               id="sel_onshore")

    # onshore_sel<-mapedit::editMap(map_onshore)

    output$cntry_dep<-renderUI(
      tagList(
        "Draw your region of interest within the country borders",
        mapedit::editModUI("sel_onshore"),
        htmlOutput("overlay_result"),
        uiOutput("btn1"),
      )
    )
    removeUI(
      selector = paste0("#map_sel_cntry","-map"))
    removeUI(
      selector = "#save_countr")
    removeUI(
      selector = "#cntr_text")



  })

  ## for onshore:: a helper function to check if poly is inside country and correct size
  observe({
    req(rv$onshore_sel)
    req(sel_country)
    sel_country<-sel_country()


    rectangles <- rv$onshore_sel()$finished

    n_poly<-nrow(as.data.frame(rectangles))

    if(n_poly==1){
      n_within<-nrow(as.data.frame(st_within(rectangles,sel_country)))

      if(n_within<n_poly){
        output$overlay_result <- renderText({
          paste("<font color=\"#FF0000\"><b>","You can`t save the polygons:","</b> <li>Place your polygon completely within your selected country<li/></font>")
        })
        removeUI(
          selector = paste0("#savepoly"))
      }else{
        area<-round(as.numeric(st_area(rectangles))/1000000,0)

        if(area>on_max){
          output$overlay_result <- renderText({
            paste0("<font color=\"#FF0000\"> <li>Your area is ",area ," km2, and thus too big, please draw a smaller area of max ",on_max," km2<li/></font>")
          })
          removeUI(
            selector = paste0("#savepoly"))

        }else if(area<on_min){
          output$overlay_result <- renderText({
            paste0("<font color=\"#FF0000\"> <li>Your area is ",area, " km2, and thus too small, please draw a bigger area of min ",on_min," km2<li/></font>")
          })
          removeUI(
            selector = paste0("#savepoly"))

        }else{
          output$btn1<-renderUI(
            actionButton("savepoly","save area")
          )
          output$overlay_result <- renderText({
            paste0("Your area is ",area, " km2, Save your area now")

          })
        }

      }

    }else if(n_poly>1){
      output$overlay_result <- renderText({
        paste("<font color=\"#FF0000\"> <li>Remove areas, just one area allowed<li/></font>")
      })
      removeUI(
        selector = paste0("#savepoly"))

    }else if(n_poly==0){
      output$overlay_result <- renderText({
        paste("<font color=\"#FF0000\"><li>Please draw one area<li/></font>")
      })
      removeUI(
        selector = paste0("#savepoly"))

    }

  })

  ## for offshore:: a helper function to check poly area is outside coast line and correct size
  observe({
    req(rv$offshore_sel)

    rectangles <- rv$offshore_sel()$finished

    n_poly<-nrow(as.data.frame(rectangles))

    if(n_poly==1){
      n_inter<-nrow(as.data.frame(st_intersects(rectangles,coast)))

      if(n_inter==n_poly){
        output$overlay_result2 <- renderText({
          paste("<font color=\"#FF0000\"><b>","You can`t save the polygons:","</b> <li>Place your polygon completely inside offshore areas<li/></font>")
        })
        removeUI(
          selector = paste0("#savepoly"))
      }else{
        area<-round(as.numeric(st_area(rectangles))/1000000,0)

        if(area>off_max){
          output$overlay_result2 <- renderText({
            paste0("<font color=\"#FF0000\"> <li>Your area is ",area ," km2, and thus too big, please draw a smaller area of max ", off_max ," km2<li/></font>")
          })
          removeUI(
            selector = paste0("#savepoly"))

        }else if(area<off_min){
          output$overlay_result2 <- renderText({
            paste0("<font color=\"#FF0000\"> <li>Your area is ",area, " km2, and thus too small, please draw a bigger area of min ",off_min ," km2<li/></font>")
          })
          removeUI(
            selector = paste0("#savepoly"))

        }else{
          output$btn2<-renderUI(
            actionButton("savepoly","save area")
          )
          output$overlay_result2 <- renderText({
            paste0("Your area is ",area, " km2, Save your area now")

          })
        }

      }

    }else if(n_poly>1){
      output$overlay_result2 <- renderText({
        paste("<font color=\"#FF0000\"> <li>Remove areas, just one area allowed<li/></font>")
      })
      removeUI(
        selector = paste0("#savepoly"))

    }else if(n_poly==0){
      output$overlay_result2 <- renderText({
        paste("<font color=\"#FF0000\"><li>Please draw one area<li/></font>")
      })
      removeUI(
        selector = paste0("#savepoly"))

    }

  })

  ## save poly in wendy gee asset

  siteID<-eventReactive(input$savepoly,{
    siteID<-stri_rand_strings(1, 10, pattern = "[A-Za-z0-9]")
  })

  study_area<-eventReactive(input$savepoly,{
    req(siteID)
    siteID<-siteID()

    if(input$projtype=="onshore"){
      study_area<-rv$onshore_sel()$finished
      sel_country<-sel_country()
      study_area<-study_area%>%select()
      study_area$cntrID<-sel_country$ISO3_CODE
    }else{
      study_area<-rv$offshore_sel()$finished
      study_area<-study_area%>%select()
      study_area$cntrID<-"off"
    }

    study_area$siteID<-siteID
    study_area$area_km2<-round(as.numeric(st_area(study_area))/1000000,0)

    study_area$siteTYPE <-input$projtype
    study_area$siteNAME <-input$name
    study_area$siteDESCR <-input$descr

    study_area$siteCREATOR <-Sys.getenv("USERNAME")

    study_area$siteCREATETIME<-Sys.time()
    study_area


  })

  observeEvent(input$savepoly,{
    req(study_area)
    study_area<-study_area()
    print("1")
    if(input$projtype=="onshore"){

      removeUI(selector = paste0("#sel_onshore","-map"))
      removeUI(
        selector = "#overlay_result")

    }else{
      removeUI(selector = paste0("#sel_offshore","-map"))
      removeUI(
        selector = "#overlay_result2")
    }

    ee_study<-study_area
    ee_study$siteCREATETIME<-as.character(ee_study$siteCREATETIME)
    ee_study<-sf_as_ee(ee_study)


    ## save geom on gee
    assetId<-paste0("projects/eu-wendy/assets/study_sites/",as.character(study_area$siteID))
    # ee_study <- ee_study$set('siteID', as.character(study_area$siteID),
    #                              'cntrID', as.character(study_area$cntrID))
    # start_time<-Sys.time()
    # task_tab <- ee_table_to_asset(
    #   collection = ee_study,
    #   description = "test upload study area",
    #   assetId = assetId
    # )
    #
    # task_tab$start()

    ## upload as bq spatial table to WENDY google cloud
    # geo <- sf_geojson(study_area, atomise = TRUE)
    # st_write(study_area,"test.geojson")
    # geo1 <- sf_geojson(study_area, atomise = FALSE)
    # geo_js_df <- as.data.frame(geojson_wkt(geo))
    # str(geo)
    #
    # players_table = bq_table(project = "rgee-381312", dataset = "data_base", table = "test_new")
    # bq_table_upload(players_table, geo_js_df)

    #

    insertUI(selector = "#savepoly", where = "afterEnd",
             ui=tagList(
               # textOutput("proj_id"),
               br(),
               h5("Select the ecosystem services that are relevant to map in your study area"),
               br(),
               DT::dataTableOutput('es_descr'),
               #
               uiOutput("cond_save_es")
             ))

    removeUI(
      selector = "#savepoly")


  })

  output$es_descr <- renderDT({
      datatable(es_descr, selection = 'multiple', options = list(pageLength = 15))


  })

  observe({
    req(input$es_descr_rows_selected)

    if(length(input$es_descr_rows_selected)!=0){
      n_es_vec<-c("",1:length(input$es_descr_rows_selected))
      output$cond_save_es<-renderUI(
        tagList(
          selectInput("n_es","how many es should each participant map", n_es_vec, selected = ""),
          uiOutput("cond_save_es2")
        )
      )
    }else{
      output$cond_save_es<-renderUI(
        h5("select at least one es")
      )
    }
  })

  observe({
    req(input$n_es)

    if(input$n_es!=""){
      output$cond_save_es2<-renderUI(
        actionButton("save_es", "save selection")
      )
    }else{
      output$cond_save_es2<-renderUI(
        h5("select a number of ES to be mapped")
      )
    }
  })

  observeEvent(input$save_es,{
    siteID<-siteID()
    study_area<-study_area()

    ### clean ui
    insertUI(selector = "#save_es", where = "afterEnd",
             ui=tagList(
               br(),
               textOutput("stud_id")
             )
    )

    output$stud_id<-renderText(paste0("Your study area has been saved please save the following study id: ",study_area$siteID," which is used for the mapping of ecosystem services and the study management"))

    removeUI(selector = "#es_descr")
    removeUI(selector = "#es_descr")
    removeUI(selector = "#cond_save_es")
    removeUI(selector = "#n_es")
    removeUI(selector = "#cond_save_es2")

    study_area$siteSTATUS<-"created_avtive"
    study_area$n_es_mapping<-input$n_es

    selected_es <- es_descr[input$es_descr_rows_selected,  ]
    selected_es$siteID<-rep(siteID,nrow(selected_es))
    #save selected es in tab
    file <-paste("C:/Users/reto.spielhofer/OneDrive - NINA/Documents/Projects/WENDY/PGIS_ES/data_base/setup_230710/", Sys.Date(), "_es.csv", sep = "")
    write.csv(selected_es, file, row.names = FALSE)

    ## save study area info
    study_area<-as.data.frame(study_area%>%st_drop_geometry())
    file2 <-paste("C:/Users/reto.spielhofer/OneDrive - NINA/Documents/Projects/WENDY/PGIS_ES/data_base/setup_230710/", Sys.Date(), "_siteDat.csv", sep = "")
    write.csv(study_area, file2, row.names = FALSE)

  })

  # Observe the selected rows
  # observeEvent(input$mytable_rows_selected, {
  #   selected_rows <- input$es_descr_rows_selected
  #   output$selectedRowsText <- renderText({
  #     paste("Selected Rows: ", paste(selected_rows, collapse = ", "))
  #   })
  # })

  # Function to save selected rows
  # output$save_es <- downloadHandler(
  #   # studyID<-studyID()
  #   filename = function() {
  #     paste("C:/Users/reto.spielhofer/OneDrive - NINA/Documents/Projects/WENDY/PGIS_ES/data_base/setup_230710/", Sys.Date(), ".csv", sep = "")
  #   },
  #   content = function(file) {
  #     selected_rows <- input$es_descr_rows_selected
  #     if (length(selected_rows) > 0) {
  #       selected_data <- data[selected_rows, ]
  #       # selected_data$siteID<-rep("ABC",nrow(selected_data))
  #       write.csv(selected_data, file, row.names = FALSE)
  #     }
  #   }
  # )





}