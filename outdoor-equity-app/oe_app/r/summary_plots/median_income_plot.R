
#' Median-income Data Summary Plotly
#'
#' @param admin_unitInput User pick for admin unit
#' @param siteInput User pick for site
#' @param ridb_df RIDB dataframe object name
#'
#' @return Plotly of median-income
#'
#' @examples

median_income_plot <- function(admin_unitInput, siteInput, ridb_df){
  
  # reactive data frame 
  median_income_rdf <- reactive ({
    
    validate(
      need(siteInput != "",
           "Please select a reservable site to visualize.")
    ) # EO validate
    
    # reservations in CA
    ridb_df %>%
      filter(park %in% siteInput) %>%
      select(park, median_income) %>% 
      rename(location_indicator = park) %>% 
      mutate(mean_zip_code_population = 1,
             data_source = "Visitors to California Sites",
             tooltip_text = 
               paste("The green curve represents all visitors to this site.",
                     "<br>",
                     "If it is above the grey curve at a specific median-income", 
                     "<br>",
                     "that median household income is over-represented",
                     "<br>",
                     "at this site compared to the California census."))
    
  }) # EO RDF
  
  # non RDF
  # CA population
  median_income_ca <- data_ca_acs_2018 %>%
    select(zip_code, median_income, mean_zip_code_population) %>% 
    rename(location_indicator = zip_code) %>% 
    mutate(data_source = "California Residents",
           tooltip_text = 
             paste("The grey curve represents all California residents.",
                   "<br>",
                   "If it is above the green curve at a specific median-income", 
                   "<br>",
                   "that median household income is under-represented",
                   "<br>",
                   "at this site compared to the California census."))
  
  median_income_data_plot <- rbind(median_income_rdf(), median_income_ca)
  
  # parameters
  color_ridb_ca <- c("Visitors to California Sites" = "#466C04", 
                     "California Residents" = "#848484")
  fill_ridb_ca <- c("Visitors to California Sites" = "#64863C", 
                    "California Residents" = "#a3a3a3")
  
  # plot for shiny app
  median_income_plotly <- ggplot() +
    geom_density(data = median_income_data_plot,
                 aes(x = median_income,
                     color = data_source,
                     fill = data_source,
                     weight = mean_zip_code_population,
                     text = tooltip_text),
                 alpha = 0.5) +
    scale_fill_manual(values = fill_ridb_ca) +
    scale_color_manual(values = color_ridb_ca) +
    scale_x_continuous(labels = dollar) +
    scale_y_continuous(labels = NULL, expand = c(0.3, 0)) +
    labs(x = "Household Median Income (US $)",
         y = NULL) +
    theme_minimal() +
    theme(plot.background = element_rect("white"))
          #panel.grid.major.y = element_blank())
  
  ggplotly(median_income_plotly, 
           tooltip = list("text")) %>% 
    layout(title = list(text = paste0('<b>', siteInput, '<br>', admin_unitInput, '</b>',
                                      '<br>',
                                      'Median-incomes for California Residents vs. Visitors'),
                        font = list(size = 15)),
           showlegend = FALSE,
           xaxis = list(tickformat = "$.2f")) %>%
    config(modeBarButtonsToRemove = list("pan", "select", "lasso2d", "autoScale2d", 
                                         "hoverClosestCartesian", "hoverCompareCartesian"))
  
} # EO function