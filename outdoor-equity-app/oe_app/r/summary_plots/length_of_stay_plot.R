
#' Length of Stay Data Summary Plotly
#'
#' @param admin_unitInput User pick for admin unit
#' @param siteInput User pick for site
#' @param ridb_df RIDB dataframe object name
#'
#' @return Plotly of length of stay
#'
#' @examples

length_of_stay_plot <- function(admin_unitInput, siteInput, ridb_df){
  
  # reactive data frame 
  length_of_stay_rdf <- reactive ({
    
    validate(
      need(siteInput != "",
           "Please select a reservable site to visualize.")
    ) # EO validate
    
    ridb_df %>%
      filter(park %in% siteInput) %>%
      select(park, length_of_stay)
    
  })
  
  # wrangling
  x_max <- (round(max(length_of_stay_rdf()$length_of_stay) / 5) * 5) + 5 # max value x rounded up to nearest 5
  
  quant_80 <- quantile(x = length_of_stay_rdf()$length_of_stay,
                       probs = seq(0, 1, 0.1))[[9]] %>% round(0)
  
  # parameters
  hist_colors <- c("#64863C", "#466C04")
  quant_80_color <- c("#FACE00")
  caption_color <- c("#ac8d00")
  
  # plot for shiny app
  length_of_stay_plotly <- ggplot(data = length_of_stay_rdf()) +
    geom_histogram(aes(x = length_of_stay,
                       text = paste0(scales::percent(..count.. / nrow(length_of_stay_rdf()), accuracy = 0.1), 
                                     " of all reservations stay between ", 
                                     scales::comma(xmin, accuracy = 1), " and ", 
                                     scales::comma(xmax, accuracy = 1), " days",  
                                     "<br>",
                                     "(Total reservations to site: ",
                                     scales::comma(nrow(length_of_stay_rdf()), accuracy = 1),
                                     ")")),
                   binwidth = 1,
                   center = 0.5,
                   fill = hist_colors[[1]], 
                   col = hist_colors[[2]], size = 0.05) +
    scale_x_continuous(limits = c(0, x_max)) +
    scale_y_continuous(labels = comma_format()) +
    geom_vline(xintercept = quant_80,
               linetype = "dashed", alpha = 0.5, color = quant_80_color) +
    labs(x = "Length of visit (days)",
         y = "") +
    theme_minimal() +
    theme(plot.background = element_rect("white"),
          panel.grid.major.y = element_blank())
  
  ggplotly(length_of_stay_plotly,
           tooltip = list("text"),
           dynamicTicks = TRUE) %>% 
    layout(title = list(text = paste0('<b>', siteInput, '<br>', admin_unitInput, '</b>',
                                      '<br>',
                                      'Length of Visit of Reservations'),
                        font = list(size = 15)),
           xaxis = list(separatethousands = TRUE),
           yaxis = list(separatethousands = TRUE),
           margin = list(b = 130, t = 100), 
           annotations =  list(x = x_max/2, y = -0.6, 
                               text = paste0("80% of reservations stay less than ", '<b>', quant_80, '</b>', " days", 
                                             "<br>", 
                                             "(shown on plot with yellow dotted line)."), 
                               showarrow = F, 
                               xre = 'paper', yref = 'paper', 
                               xanchor = 'middle', yanchor = 'auto', 
                               xshift = 0, yshift = 0,
                               font = list(size = 12, color = caption_color))) %>%
    config(modeBarButtonsToRemove = list("pan", "select", "lasso2d", "autoScale2d", 
                                         "hoverClosestCartesian", "hoverCompareCartesian"))
} # EO function