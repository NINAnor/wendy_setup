#' manage_study UI Function
#'
#' @description A shiny Module.
#'
#' @param id,input,output,session Internal parameters for {shiny}.
#'
#' @noRd
#'
#' @importFrom shiny NS tagList
mod_manage_study_ui <- function(id){
  ns <- NS(id)
  tagList(
    bslib::value_box(
      title="",
      value = "",
      h5("Here you can check the status of an ongoing study or modify the status of a study"),
      br(),
      h4("To change the status of a study, each landscape value (total of 10) must be mapped at least by two individual participants."),
      br(),
      h5("Enter your study id that you want to check or modify"),
      br(),
      textInput(ns("site_id"),""),
      actionButton(ns("check_study"),"check status"),
      showcase = bs_icon("book"),
      theme = value_box_theme(bg = blue, fg = "black")
    ),

    uiOutput(ns("cond_b1")),
    uiOutput(ns("process_fin"))

  )
}

#' manage_study Server Functions
#'
#' @noRd
mod_manage_study_server <- function(id){
  moduleServer( id, function(input, output, session){
    ns <- session$ns

    sites<-eventReactive(input$check_study,{
      shinybusy::show_modal_spinner(text = "fetch site status", color = "green")
      sites<-tbl(con_admin, "study_site")
      sites<-sites%>%collect()
      shinybusy::remove_modal_spinner()
      sites<-sites
    })

    sitestatus<-eventReactive(input$check_study,{
      req(sites)
      sites<-sites()


      if(input$site_id %in% sites$siteID){
        sitestatus<-as.integer(sites%>%filter(siteID==input$site_id)%>%
                                 arrange(desc(as.POSIXct(siteCREATETIME)))%>%first()%>%
                                 select(siteSTATUS))
      }else{
        sitestatus = 0
      }
      print(sitestatus)
      sitestatus<-sitestatus
    })

    ## for site status 1 and 3 we need to know how many maps per es are in the DB
    map_stats<-eventReactive(input$check_study,{
      sitestatus<-sitestatus()
      a<-as.character(input$site_id)
      if(sitestatus == 1){

        shinybusy::show_modal_spinner(text = "calculate round I statistics", color = "green")
        map_stats<-tbl(con_admin, "es_mappingR1")
        map_stats<-map_stats%>%filter(siteID == a & poss_mapping == TRUE)%>%
          group_by(esID)%>%summarise(n_maps = n_distinct(userID))%>%collect()
        shinybusy::remove_modal_spinner()

      }else if(sitestatus == 3){
        shinybusy::show_modal_spinner(text = "calculate round II statistics", color = "green")
        map_stats<-tbl(con_admin, "es_mappingR2")
        map_stats<-map_stats%>%filter(siteID == a & poss_mapping == TRUE)%>%
          group_by(esID)%>%summarise(n_maps = n_distinct(userID))%>%collect()
        shinybusy::remove_modal_spinner()
      }else{
        map_stats<-NULL
      }
      #print(map_stats)
      map_stats<-as.data.frame(map_stats)
    })

    ## based on the amount of maps render other UI

    observeEvent(input$check_study,{
      req(map_stats)
      sitestatus<-sitestatus()
      map_stats<-map_stats()
      if(sitestatus == 1){
        output$status_r1 <- renderDT({
          map_stats$Status <- ifelse(map_stats$n_maps < 2,
                              "<span style='color:red;'>&#10060;</span>",  # Red cross
                              "<span style='color:green;'>&#9989;</span>") # Green checkmark

          datatable(map_stats, escape = FALSE, rownames = FALSE, options = list(pageLength = 10))
          })

          if(min(map_stats$n_maps)<2){
            if(nrow(map_stats != 10)){
              output$cond_b1<-renderUI({
                ui=tagList(
                  br(),
                  bslib::value_box(
                    title="",
                    value = "",
                    h4("The selected study is open in the first mapping round"),
                    showcase = bs_icon("1-circle"),
                    theme = value_box_theme(bg = "white", fg = "black")
                  ),
                  DTOutput(ns('status_r1')),
                  br(),
                  bslib::value_box(
                    title="",
                    value = "",
                    h4("To close round I, each landscape value must have at least two maps. In addition some landscape values are missing."),
                    h4("Either you remind participants to map or you should invite more participants."),
                    showcase = bs_icon("exclamation-octagon-fill"),
                    theme = value_box_theme(bg = orange, fg = "black")
                  ),
                )
              })

            }else{
              output$cond_b1<-renderUI({
                ui=tagList(
                  br(),
                  bslib::value_box(
                    title="",
                    value = "",
                    h4("The selected study is open in the first mapping round"),
                    showcase = bs_icon("1-circle"),
                    theme = value_box_theme(bg = "white", fg = "black")
                  ),
                  DTOutput(ns('status_r1')),
                  br(),
                  bslib::value_box(
                    title="",
                    value = "",
                    h4("To close round I, each landscape value must have at least two maps."),
                    h4("Either you remind participants to map or you should invite more participants."),
                    showcase = bs_icon("exclamation-octagon-fill"),
                    theme = value_box_theme(bg = orange, fg = "black")
                  ),
                )
              })
            }
          ## only valid condition if status == 1
          }else if(min(map_stats$n_maps)>2 & nrow(map_stats == 10)){
            output$cond_b1<-renderUI({
              ui=tagList(
                br(),
                bslib::value_box(
                  title="",
                  value = "",
                  h4("The selected study is open in the first mapping round"),
                  showcase = bs_icon("1-circle"),
                  theme = value_box_theme(bg = "white", fg = "black")
                ),
                br(),
                bslib::value_box(
                  title="",
                  value = "",
                  h4("If you want, you can close mapping round I"),
                  actionButton(ns("close1"),"close session I"),
                  #uiOutput(ns("fin_process1")),
                  showcase = bs_icon("exclamation-octagon-fill"),
                  theme = value_box_theme(bg = green, fg = "black")
                ),
              )
            })

          }else if(min(map_stats$n_maps)>2 & nrow(map_stats != 10)){
            output$cond_b1<-renderUI({
              ui=tagList(
                br(),
                bslib::value_box(
                  title="",
                  value = "",
                  h4("The selected study is open in the first mapping round"),
                  showcase = bs_icon("1-circle"),
                  theme = value_box_theme(bg = "white", fg = "black")
                ),
                DTOutput(ns('status_r1')),
                br(),
                bslib::value_box(
                  title="",
                  value = "",
                  h4("Some landscape values are missing."),
                  h4("Either you remind participants to map or you should invite more participants."),
                  showcase = bs_icon("exclamation-octagon-fill"),
                  theme = value_box_theme(bg = orange, fg = "black")
                ),
              )
            })
          }

      ## status 3 running R2
      }else if(sitestatus == 3){
          output$status_r2 <- renderDT({
          map_stats$Status <- ifelse(map_stats$n_maps < 2,
                                     "<span style='color:red;'>&#10060;</span>",  # Red cross
                                     "<span style='color:green;'>&#9989;</span>") # Green checkmark

          datatable(map_stats, escape = FALSE, rownames = FALSE, options = list(pageLength = 10))
        })


        if(min(map_stats$n_maps)<2 | nrow(map_stats != 10)){
          output$cond_b1<-renderUI({
            ui=tagList(
              br(),
              bslib::value_box(
                title="",
                value = "",
                h4("The selected study is open in the second mapping round"),
                showcase = bs_icon("2-circle"),
                theme = value_box_theme(bg = "white", fg = "black")
              ),
              DTOutput(ns('status_r2')),
              br(),
              bslib::value_box(
                title="",
                value = "",
                h4("To close round II, each landscape value must have at least two maps. In addition some landscape values are missing."),
                h4("Either you remind participants to map or you should invite more participants."),
                showcase = bs_icon("exclamation-octagon-fill"),
                theme = value_box_theme(bg = orange, fg = "black")
              ),
            )
          })
        }else{
          output$cond_b1<-renderUI({
            ui=tagList(
              br(),
              bslib::value_box(
                title="",
                value = "",
                h4("The selected study is open in the second mapping round"),
                showcase = bs_icon("2-circle"),
                theme = value_box_theme(bg = "white", fg = "black")
              ),
              br(),
              bslib::value_box(
                title="",
                value = "",
                h4("If you want, you can close mapping round II"),
                actionButton(ns("close2"),"close session I"),
                #uiOutput(ns("fin_process1")),
                showcase = bs_icon("exclamation-octagon-fill"),
                theme = value_box_theme(bg = green, fg = "black")
              ),
            )
          })
        }
      }else if(sitestatus == 4){
        output$cond_b1<-renderUI({
          ui=tagList(
            bslib::value_box(
              title="",
              value = "",
              h4("Mapping round II is closed and you can use the maps in WENDY consite"),
              showcase = bs_icon("exclamation-octagon-fill"),
              theme = value_box_theme(bg = green, fg = "black")
            )
          )
        })
      }else{
        output$cond_b1<-renderUI({
          ui=tagList(
            h5("Invalid study ID", style = "color: red;")
          )
        })

      }

    })

    ### server logic for "closeR1"
    ## AHP calc individual and global order of importance in the study area.
    ## store values of impact for disturbance pdf
    ## status of projects should be set directly to 3
    observeEvent(input$close1,{
      req(map_stats)
      req(sites)

      map_stats<-map_stats()
      sites<-sites()

      shinybusy::show_modal_spinner(text = "Close mapping round I & update data base", color = "green")

      new_site<-sites%>%filter(siteID==input$site_id & siteSTATUS == 1)%>%
        mutate(siteSTATUS=replace(siteSTATUS, siteSTATUS==1, 3)) %>%
        mutate(siteCREATETIME=Sys.time()) %>%
        as.data.frame()

      ### AHP calculation
      es_pair <- tbl(con_admin, "es_pair")
      es_pair <- es_pair%>%select(es_pair, ES_left,ES_right,selection_text,selection_val,userID,siteID,ahp_section) %>%filter(siteID == input$site_id)%>% collect()
      perform_ahp_update_db(es_pair = es_pair, con_admin = con_admin, studyID = input$site_id)

      ### rated impacts for dist (not needed in pdf function included)
      # es_dist <-tbl(con_admin, "es_impact")
      # es_dist<-es_dist%>%filter(siteID == input$site_id)%>% collect()
      # influence_rating_summary(es_dist = es_dist, con_admin = con_admin, studyID = input$site_id)


      site_updated = bq_table(project = "eu-wendy", dataset = dataset, table = 'study_site')
      bq_table_upload(x = site_updated, values = new_site, create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND')

      shinybusy::remove_modal_spinner()

      removeUI(selector = "#cond_b1")
      output$process_fin<-renderUI({
        tagList(
          bslib::value_box(
            title="",
            value = "",
            h4("Mapping round I closed"),
            br(),
            h4(paste0("You can send the following link to your participants: https://view.nina.no/",input$site_id,"/ to access mapping round II")),
            showcase = bs_icon("exclamation-octagon-fill"),
            theme = value_box_theme(bg = green, fg = "black")
          )
        )
      })

    })

    ### server logic for "open2"
    ## just update the DB
    observeEvent(input$close2,{
      sites<-sites()

      shinybusy::show_modal_spinner(text = "update data base - postprocess session II", color = "green")
      new_site<-sites%>%filter(siteID==input$site_id & siteSTATUS == 3)%>%
        mutate(siteSTATUS=replace(siteSTATUS, siteSTATUS==2, 4)) %>%
        mutate(siteCREATETIME=Sys.time()) %>%
        as.data.frame()

      site_updated = bq_table(project = "eu-wendy", dataset = dataset, table = 'studSITE')
      bq_table_upload(x = site_updated, values = new_site, create_disposition='CREATE_IF_NEEDED', write_disposition='WRITE_APPEND')

      ## insert a helper raster on gcs bucket to trigger IAR, z, pdf calc fkts

      r <- rast(ncol=10, nrow=10)

      # Set random integer values between a specified range (e.g., 1 to 100)
      values(r) <- sample(1:100, ncell(r), replace=TRUE)
      tmp_name<-paste0(input$site_id,".tif")
      writeRaster(r, filename = tmp_name)

      file_name <-paste0(env,"/99_help_rast/",input$site_id)
      gcs_upload(tmp_name, bucket_name, name = file_name, predefinedAcl = "bucketLevel")
      file.remove(tmp_name)
      unlink(tmp_loc,recursive = T)


      shinybusy::remove_modal_spinner()

    })
  })
}

## To be copied in the UI
# mod_manage_study_ui("manage_study_1")

## To be copied in the server
# mod_manage_study_server("manage_study_1")
