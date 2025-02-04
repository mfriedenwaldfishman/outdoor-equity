
#' Race x Daily Cost per Visitor Plotly
#'
#' @param admin_unitInput User pick for admin unit
#' @param siteInput User pick for site
#' @param race_top_quartile_df Object name for dataframe of all reservations above "high" threshold for race
#'
#' @return Plotly of racial categories compared to daily cost per visitor
#'
#' @examples

race_daily_cost_per_visitor_plot <- function(admin_unitInput, 
                                             siteInput,
                                             race_top_quartile_df){
  
  # create reactive dataframe and further subset
  rdf <- reactive ({
    
    validate(
      need(siteInput != "",
           "Please select a reservable site to visualize.")
    ) # EO validate
    
    race_top_quartile_df %>%
      # filter to user site of choice
      filter(park == siteInput) %>%
      # select to variables of interest
      select(park, customer_zip, 
             race, race_percentage,
             daily_cost_per_visitor) %>% 
      drop_na(daily_cost_per_visitor, race_percentage) %>% 
      # summarize to inner quartile range, median, and total reservations
      group_by(race) %>% 
      summarize(median_daily_cost_per_visitor = median(daily_cost_per_visitor),
                quartile_lower = quantile(daily_cost_per_visitor)[[2]],
                quartile_upper = quantile(daily_cost_per_visitor)[[4]],
                count = n())
  }) # EO rdf
  
  validate(need(
    nrow(rdf()) > 0,
    paste0("There are no reservations to ", siteInput, ", ", admin_unitInput, 
           " that come from communities in the high range for any racial categories.")
  )) # EO validate
  
  # parameters
  race_group_colors <- c("Other Race(s)" = "#999999", "Pacific Islander" = "#E69F00", "Multiracial" = "#56B4E9",
                         "Asian" = "#009E73", "Black" = "#F0E442", "White" = "#0072B2", 
                         "Native American" = "#D55E00", "Hispanic Latinx" = "#CC79A7")
  
  # create plot
  plotly <- ggplot(data = rdf(), 
                   aes(x = median_daily_cost_per_visitor,
                       y = reorder(race, median_daily_cost_per_visitor))) +
    geom_segment(aes(xend = 0, yend = race)) +
    geom_point(aes(color = race, fill = race,
                   text = paste0(scales::comma(count, accuracy = 1), 
                                 " unique visits were made by people who live in ZIP codes<br>with high ",
                                 race, " populations. Typically these visitors paid between<br>",
                                 scales::dollar(quartile_lower), 
                                 " and ", scales::dollar(quartile_upper), 
                                 " per day per person, with a median of ", 
                                 scales::dollar(median_daily_cost_per_visitor), 
                                 ".")),
               size = 3.5, 
               shape = 21, stroke = 2) +
    scale_x_continuous(labels = dollar) +
    scale_y_discrete(expand = c(0.45, 0)) +
    scale_fill_manual(values = race_group_colors) +
    scale_color_manual(values = race_group_colors) +
    labs(x = paste("Estimated Daily Cost per Reservation (US $)"),
         y = "") + 
    theme_minimal() +
    theme(plot.background = element_rect("white"),
          panel.grid.major.y = element_blank(),
          legend.position = "none")
  
  # create plotly
  ggplotly(plotly,
           tooltip = list("text")) %>%
    config(modeBarButtonsToRemove = list("zoom", "pan", "select", "lasso2d", "autoScale2d", 
                                         "hoverClosestCartesian", "hoverCompareCartesian")) %>% 
    layout(title = list(text = paste0('<b>', siteInput, '<br>', admin_unitInput, '</b>',
                                      '<br>',
                                      'Daily Costs per Visitor Paid by Different Racial Groups'),
                        font = list(size = 15))) %>% 
    add_annotations(text = "Reservations from ZIP codes<br>with high proportions of:", 
                    x = -0.15, y = 0.9, 
                    font = list(size = 11),
                    xref = 'paper', yref = 'paper', 
                    showarrow = FALSE)
  
} # EO function