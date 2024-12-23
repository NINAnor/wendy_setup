# UI.R
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

fluidPage(theme = shinytheme("flatly"),
  titlePanel(title =  div(img(src="wendy.PNG", width ='120'), 'Mapping nature values - Admin tool'), windowTitle = "PGIS-ADMIN"),
  tags$head(
    # Custom CSS to ensure dropdown shows fully
    tags$style(HTML("
        .box { overflow: visible; }
        .selectize-dropdown-content { overflow-y: auto; max-height: 200px; }
              body {
        padding-bottom: 100px; /* Adjust this value to match the footer height */
      }
      "))
  ),
  tabsetPanel(id = "inTabset",
              tabPanel(title = "Admin login", value = "p0",
                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h4("To calculate the impact of wind energy infrastructure on landscape values, this tool administers a landscape value (ecosystem services) mapping questionnaire for your target region."),
                         br(),
                         h4("To create, track or modify a mapping study you need an administrator account. If you need such a profile, fill out this form. The Nowegian Institute for Nature Research (NINA) will grant you access after a quick check."),
                         showcase = bs_icon("book"),
                         theme = value_box_theme(bg = blue, fg = "black")
                       ),
                       bslib::value_box(
                         title = "",
                         value = "",
                         textInput("user_name","Please provide your user name of your admin account."),
                         actionButton("check1","check access"),
                         uiOutput("cond0")),
                         showcase = bs_icon("exclamation-octagon-fill"),
                         theme = value_box_theme(bg = orange, fg = "black")
                       ),

              tabPanel(title = "Create a new study area", value = "p1",
                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h5("Here you can setup a new landscape value mapping study."),
                         br(),
                         h4(" After you have created a study following the steps here, you need to invite participants to map landscape values based on their local knowledge."),
                         showcase = bs_icon("book"),
                         theme = value_box_theme(bg = blue, fg = "black")
                       ),
                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h4("Create a unique, short site id, without blank spaces, that you easily remember. You will use the site id to manage the study and to find the results within the WENDY consite tool"),
                         br(),
                         textInput("siteID","site id (no blank spaces)"),
                         br(),
                           showcase = bs_icon("1-circle"),
                         theme = value_box_theme(bg = orange, fg = "black")
                       ),
                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h4("Next, define a natural name of your study which can be understood by the study participants. This may include blank spaces"),
                         br(),
                         textInput("site_nat_name",""),
                         showcase = bs_icon("2-circle"),
                         theme = value_box_theme(bg = "white", fg = "black")
                       ),

                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h4("Ecosystem service maps per participant"),
                         br(),
                         h5("The study consists of a total of ten different ecosystem services to map with participants. It might take approx. 10 min for a participant to map one ecosystem service, maybe much less."),
                         h5("However, to optimize your study, please indicate how many ecosystem services each participant should map as a maximum. In other words how much time do you want your participants to spend with the study?"),
                         h5("The less time per participant, the more participants you need."),
                         selectInput("n_es","",choices = c("1","2","3","4","5","6","7","8","9","10"), selected = "",selectize = FALSE),
                         showcase = bs_icon("3-circle"),
                         theme = value_box_theme(bg = green, fg = "black")
                       ),
                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h4("Choose the language of the study."),
                         h5("If the language is not listed, please contact the tool administrator."),
                         br(),
                         selectInput("language","",choices = list("Greek" = "gk",
                                                                  "Norwegian" = "no",
                                                                  "Italian" = "it",
                                                                  "Spanish"="es",
                                                                  "English" = "en",
                                                                  "Slovak" = "svk",
                                                                  "French" = "fr"),selected = "",selectize = FALSE),
                         showcase = bs_icon("4-circle"),
                         theme = value_box_theme(bg = "white", fg = "black")
                       ),
                       br(),
                       bslib::value_box(
                         title="",
                         value = "",
                         h4("Is your study onshore or offshore?"),
                         br(),
                         selectInput("sitetype","",choices = c("","onshore","offshore"), selected = "",selectize = FALSE),
                         showcase = bs_icon("5-circle"),
                         theme = value_box_theme(bg = blue, fg = "black")
                       ),
                       br(),
                       uiOutput("cond_b1")



              ),
              tabPanel(title = "Create a new study area", value = "p1A",
                       uiOutput("type_dep")),
              tabPanel(title = "Create a new study area", value = "p1B",
                       uiOutput("id_note")),
              tabPanel(title = "Manage mapping study", value = "p2",
                       mod_manage_study_ui("manage_projects")
                       )
                      ),
  tags$footer(
    style = "position:fixed; bottom:0; left:0; width:100%;
             background-color:#f8f9fa; color:#333; padding:10px; text-align:center;
             border-top:1px solid #ddd; z-index: 1000;",
    HTML("
      <p>Licensed under <a href='https://www.gnu.org/licenses/gpl-3.0.txt' target='_blank'>GNU General Public License v3.0</a>.</p>
    "),
    div(
      style = "display: flex; justify-content: center; align-items: center;",
      img(src = "NINA_logo.png", height = "45px", style = "margin-right:10px;"),
      span("NINA © 2024 setup Geoprospective")
    )
  )

)#/page
