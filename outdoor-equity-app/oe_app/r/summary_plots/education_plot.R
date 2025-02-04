
#' Education Data Summary Plotly
#'
#' @param admin_unitInput User pick for admin unit
#' @param siteInput User pick for site
#' @param ridb_df RIDB dataframe object name
#'
#' @return Plotly of education
#'
#' @examples
education_plot <- function(admin_unitInput, siteInput, ridb_df){
  
  # reactive data frame 
  education_rdf <- reactive ({
    
    validate(
      need(siteInput != "",
           "Please select a reservable site to visualize.")
    ) # EO validate
    
    data_plot_education_ridb <- ridb_df %>%
      filter(park %in% siteInput) %>%
      summarize(hs_GED_or_below = mean(hs_GED_or_below, na.rm = TRUE),
                some_college = mean(some_college, na.rm = TRUE),
                college = mean(college, na.rm = TRUE),
                master_or_above = mean(master_or_above, na.rm = TRUE))  %>%
      pivot_longer(cols = 1:4, names_to = "education", values_to = "education_percent_average")
    
    # CA population
    data_plot_education_ca <- data_ca_acs_2018 %>%
      summarize(
        hs_GED_or_below = weighted.mean(hs_GED_or_below, mean_zip_code_population,
                                        na.rm = TRUE),
        some_college = weighted.mean(some_college, mean_zip_code_population,
                                     na.rm = TRUE),
        college = weighted.mean(college, mean_zip_code_population,
                                na.rm = TRUE),
        master_or_above = weighted.mean(master_or_above, mean_zip_code_population,
                                        na.rm = TRUE)
      )  %>%
      pivot_longer(cols = 1:4,
                   names_to = "education",
                   values_to = "education_percent_average")
    
    # join data for plotting
    # data_plot_education <-
    data_plot_education_ridb %>% 
      left_join(y = data_plot_education_ca,
                by = c("education"),
                suffix = c("_ridb", "_ca")) %>% 
      rename(RIDB = education_percent_average_ridb,
             CA = education_percent_average_ca) %>% 
      pivot_longer(cols = 2:3,
                   names_to = "data_source",
                   values_to = "education_percent_average") %>% 
      mutate(education = str_replace_all(string = education,
                                         pattern = "_", 
                                         replacement = " "),
             education = str_to_title(education),
             education = str_replace(string = education,
                                     pattern = "Hs Ged Or", 
                                     replacement = "HS, GED, or"),
             education = str_replace(string = education,
                                     pattern = "Some College",
                                     replacement = "Some College or Trade School"),
             education = str_replace(string = education,
                                     pattern = "^College$",
                                     replacement = "Associates or Bachelors Degree"),
             education = str_replace(string = education,
                                     pattern = "Master Or Above",
                                     replacement = "Masters Degree or Above"),
             education = factor(education, levels = c("HS, GED, or Below", "Some College or Trade School", 
                                                      "Associates or Bachelors Degree", "Masters Degree or Above")),
             data_source = factor(data_source, levels = c("RIDB", "CA")),
             tooltip_start = case_when(data_source == "RIDB" ~ "Visitors to this site live in communities where an estimated ",
                                       data_source == "CA" ~ ""),
             tooltip_middle = case_when(data_source == "RIDB" ~ " of the population <br>have ",
                                        data_source == "CA" ~ " of Californians have<br>"),
             tooltip_end = case_when(data_source == "RIDB" ~ " as their highest level of education.",
                                     data_source == "CA" ~ " as their highest level of education."))
    
  }) # EO RDF
  
  print(head(education_rdf(), 5))
  
  x_max <- max(education_rdf()$education_percent_average) + 0.1 # max x rounded to nearest 5
  
  # parameters
  groups_colors_ridb_ca <- c("RIDB" = "#64863C", "CA" = "#a3a3a3")
  text_colors_ridb_ca <- c("RIDB" = "#466C04", "CA" = "#848484")
  
  # plot for shiny app
  education_plot <- ggplot(data = education_rdf()) +
    geom_col(aes(x = education_percent_average,
                 y = education,
                 fill = data_source,
                 text = paste0(tooltip_start, scales::percent(education_percent_average, accuracy = 0.1), 
                               tooltip_middle, education, tooltip_end)),
             position = "dodge") +
    scale_x_continuous(limits = c(0, x_max), labels = percent_format(accuracy = 1)) + 
    scale_y_discrete(expand = c(0.4, 0)) +
    scale_fill_manual(values = groups_colors_ridb_ca) + 
    geom_text(aes(x = education_percent_average,
                  y = education,
                  label = scales::percent(education_percent_average, accuracy = 0.1),
                  col = data_source),
              position = position_dodge(width = 1),
              size = 4) +
    scale_color_manual(values = text_colors_ridb_ca) +
    labs(x = "Percentage (%)",
         y = "") +
    theme_minimal() +
    theme(plot.background = element_rect("white"),
          panel.grid.major.y = element_blank(),
          axis.text.y = element_text(size = 9))
  
  education_plotly <- ggplotly(education_plot,
           tooltip = list("text")) %>%
    # style( hoverinfo = "none",
    #        traces = c(3, 4),
    #        textposition = "right"
    #   ) %>%
    layout(title = list(text = paste('<b>', siteInput, '<br>', admin_unitInput, '</b>',
                                      '<br>',
                                      'Estimated Highest Level of Education of California Residents vs. Visitors'),
                        font = list(size = 15)),
    showlegend = FALSE) %>%
    config(modeBarButtonsToRemove = list("pan", "select", "lasso2d", "autoScale2d",
                                         "hoverClosestCartesian", "hoverCompareCartesian"))

  return(education_plotly)
} # EO function