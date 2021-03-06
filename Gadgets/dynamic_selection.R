library(dplyr)
library(shiny)
library(miniUI)
library(ggplot2)

dynamic_select <- function() {
    
    # get what is in the data directory
    city_list <- dir(path = "Data/") %>% gsub(pattern = "*\\.csv$", replacement = "")
    
    # make path list of respective city RDS, and then read data
    cities <- sapply(X = city_list, FUN = sprintf, fmt = "Data/%s.csv") %>% 
        lapply(FUN = readr::read_csv) 
    
    # assign names to be aligned with input selector
    names(cities) <- toupper(city_list)
    
    ui <- miniPage(
        gadgetTitleBar("Excr: Dynamic Selection"),
        miniContentPanel(
            selectInput("city", label = "Select A City : ", choices = toupper(c("", city_list))),
            selectInput("subcity", label = "Filter by District : ", character(0)),
            tableOutput("head")
        )
    )
    
    server <- function(input, output, session) {
        
        # select from a list of data frames
        selectCity <- reactive({ 
            # prevent eror from initial empty value 
            req(input$city)
            cities[[input$city]] 
        })
        
        # sublevel of city selection,
        # some cities have a larger subcity cluster (neightbourhood_group).
        nb <- reactive({ 
            if(sum(is.na(selectCity()[["neighbourhood_group"]] > 100))){
                unique(selectCity()[["neighbourhood"]])
            }else{
                unique(selectCity()[["neighbourhood_group"]])
            }
        })
        
        # generate neighbourhood selection based on selected city (dynamic UI)
        observe({
            updateSelectInput(session, "subcity", choices = c("", nb()))
        })
        
        # produce head of selected area
        output$head <- renderTable({
            (selectCity() %>% filter(neighbourhood == input$subcity | neighbourhood_group == input$subcity) %>% head())[1:3]
        })
    
    }
    
    runGadget(ui, server)
}