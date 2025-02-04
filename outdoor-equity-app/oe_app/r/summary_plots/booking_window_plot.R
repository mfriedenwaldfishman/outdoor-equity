
#' Booking Window Data Summary Plotly
#'
#' @param admin_unitInput User pick for admin unit
#' @param siteInput User pick for site
#' @param ridb_df RIDB dataframe object name
#'
#' @return Plotly of booking window
#'
#' @examples
booking_window_plot <- function(admin_unitInput, siteInput, ridb_df){
  
  # reactive data frame
  booking_window_rdf <- reactive({
    
    validate(
      need(siteInput != "",
           "Please select a reservable site to visualize.")
    ) # EO validate
    
    ridb_df %>%
      filter(park %in% siteInput,
             booking_window > 0,
             booking_window != "Inf") %>% 
      select(park, booking_window) %>% 
      filter(!is.na(booking_window))
  })
  
  # wrangling
  x_max <- numeric(0)
  if(dim(booking_window_rdf()) != 0) {
    
    x_max <- (round(max(booking_window_rdf()$booking_window) / 5) * 5) + 5 # max x rounded to nearest 5
  }
  
  quant_80 <- numeric()
  if(dim(booking_window_rdf()) != 0) {
    
    quant_80 <- quantile(x = booking_window_rdf()$booking_window,
                         probs = seq(0, 1, 0.1))[[9]] %>% round(0)
  }
  
  # parameters
  hist_colors <- c("#64863C", "#466C04")
  quant_80_color <- c("#FACE00")
  caption_color <- c("#ac8d00")
  
  # plot for shiny app
  plotly <- ggplot(
    data = booking_window_rdf()) +
    geom_histogram(aes(x = booking_window,
                       text = paste0(scales::percent(..count.. / nrow(booking_window_rdf()), accuracy = 0.1), 
                                     " of all visits are reserved between ", 
                                     scales::comma(xmin, accuracy = 1), 
                                     " and ", 
                                     scales::comma(xmax, accuracy = 1), 
                                     " days before the start of the visit", 
                                     "<br>",
                                     "(Total reservations to site: ",
                                     scales::comma(nrow(booking_window_rdf()), accuracy = 1), 
                                     ")")),
                   binwidth = 7,
                   center = 7 / 2,
                   fill = hist_colors[[1]], 
                   col = hist_colors[[2]], size = 0.05) +
    labs(x = "Days in advance before visit (each bar = 1 week)",
         y = "") +
    scale_x_continuous(limits = c(0, x_max)) +
    geom_vline(xintercept = quant_80,
               linetype = "dashed", alpha = 0.5, color = quant_80_color) +
    theme_minimal() +
    theme(plot.background = element_rect("white"),
          panel.grid.major.y = element_blank())
  
  # add 6 month / 1 year annotation if data allows
  if (x_max <= 180) {
    # don't include 6 month or 1 year annotation
    plotly
    
  } else if (x_max > 180 & x_max <= 360){
    # include 6 month annotation
    plotly <- plotly +
      geom_vline(xintercept = 180, 
                 linetype = "dashed", size = .3, alpha = .5) +
      annotate("text", label = "6 months",  size = 3,
               x = 180, y = 5)
    
  } else if (x_max >= 360) {
    
    # include 6 month and 1 year annotation
    plotly <- plotly +
      geom_vline(xintercept = 180, 
                 linetype = "dashed", size = .3, alpha = .5) +
      annotate("text", label = "6 months", size = 3,
               x = 180, y = 5) +
      geom_vline(xintercept = 360,
                 linetype = "dashed", size = .3, alpha = .5) +
      annotate("text", label = "1 year", size = 3,
               x = 360, y = 5)
  } # EO else if for plotly
  
  ggplotly(plotly,
           tooltip = list("text"),
           dynamicTicks = TRUE) %>% 
    layout(title = list(text = paste0('<b>', siteInput, '<br>', admin_unitInput, '</b>',
                                      '<br>',
                                      'Number of days from reservation to start of visit'),
                        font = list(size = 15)),
           xaxis = list(separatethousands = TRUE),
           yaxis = list(separatethousands = TRUE),
           margin = list(b = 130, t = 100), 
           annotations =  list(x = x_max/2, y = -0.6, 
                               text = paste0("80% of reservations reserve their visit less than ", '<b>', quant_80, '</b>', 
                                             " days before the start date", 
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