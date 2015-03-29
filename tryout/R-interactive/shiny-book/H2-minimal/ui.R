###################################
##### minimal example – ui.R #####
###################################
library(shiny) # load shiny at beginning at both scripts

shinyUI(pageWithSidebar( # standard shiny layout, controls on the
                         # left, output on the right
  headerPanel("Minimal example"), # give the interface a title
  sidebarPanel( # all the UI controls go in here
    textInput(inputId = "comment",              # this is the name of the
                                                # variable- this will be
                                                # passed to server.R
              label = "Title of graph", # display label for the
                                        # variable
              value = "Normal distribution" # initial value
              ),
    # sliderInput(inputId = "nobs", label = "#Observations", value = 50, min = 10, max = 100)
    numericInput(inputId = "nobs", label = "#Observations", value = 50, min = 10, max = 1000)
  ),
  
  mainPanel( # all of the output  elements go in here
    plotOutput("plotDisplay")
  )
))

