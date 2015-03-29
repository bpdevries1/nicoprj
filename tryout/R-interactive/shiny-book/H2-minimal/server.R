######################################
##### minimal example - server.R #####
######################################
library(shiny) # load shiny at beginning at both scripts

shinyServer(function(input, output) { # server is defined within
                                      # these parentheses
  output$plotDisplay <- renderPlot({hist(rnorm(input$nobs), main = input$comment)})
})
