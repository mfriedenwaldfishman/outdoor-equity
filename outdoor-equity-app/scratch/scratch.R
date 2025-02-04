library(tidyverse)
library(here)
library(collections)

ggplot(data = test_bab, aes(x = distance_traveled_m, y = aggregated_site_type)) +
  geom_point()

ggplot(data = data_joined_2018, aes(x = distance_traveled_m)) +
  geom_histogram()

map_data <- test_bab %>% 
  group_by(customer_zip) %>%
  summarize(number_reservations = n()) %>%
  mutate(customer_zip = as.character(customer_zip))

map_data_geometries <-
  data_ca_zip_code_geometries %>% # read in saved RDS file
  left_join(map_data,
            by = c("zip_code" = "customer_zip")) %>%
  mutate(number_reservations = ifelse(is.na(number_reservations), 0, number_reservations))

test_bab <- data_joined_2018 %>% filter(park == "Upper Pines")

test_dt <- data_joined_2018 %>% filter(park %in% "Wawona") %>% str_to_title()

race_group <- c("other", "pacific_islander", "multiracial", "asian",
                "black", "white", "native_american", "hispanic_latinx")

data_race_quants <-
  race_group %>%
  map_dbl(race_top_quartile, acs_df = data_ca_acs_2018) %>%
  cbind("race_group" = race_group,
        "weighted_quartile" = .) %>%
  as.data.frame()

test_race_stay <- data_joined_2018 %>% 
  filter(park %in% "Wawona") %>%
  # select to variables of interest
  select(park, customer_zip, 
         asian, black, hispanic_latinx, multiracial, 
         native_american, other, pacific_islander, white,
         length_of_stay) %>% 
  drop_na(length_of_stay) %>% 
  filter(length_of_stay >= 0) %>% 
  pivot_longer(cols = 3:10,
               names_to = "race",
               values_to = "race_percentage") %>% 
  # filter for specific racial category
  filter(race %in% race_group) %>% 
  drop_na(race_percentage) %>% 
  # filter rows that fall above 3rd quartile value
  filter(race_percentage >= data_race_quants$weighted_quartile) %>% 
  # summarize to inner quartile range, median, and total reservations
  # NOTE HD: Are you missing a group by here?
  summarize(median_length_of_stay = median(length_of_stay),
            quartile_lower = quantile(length_of_stay)[[2]],
            quartile_upper = quantile(length_of_stay)[[4]],
            count = n()) %>% 
  # updated racial category name strings for plotting
  mutate(race = paste0(race_group)) %>% 
  relocate(race, .before = 1) %>% 
  mutate(race = str_replace(string = race,
                            pattern = "_",
                            replacement = " "),
         race = str_to_title(race),
         race = str_replace(string = race,
                            pattern = "Other",
                            replacement = "Other Race(s)"))


data_joined_2018 %>% 
  filter(park == "Wawona")

ggplot(data_joined_2018, aes(x = median_income)) +
  geom_histogram()

tm_shape(data_zip_geometries_ca) +
  tm_fill(col = "number_reservations",
          title = "Number of Visits",
          palette = "PuRd",
          style = "jenks",
          n = 10, 
          popup.vars = c("Total Visits" = "number_reservations")) +
  tm_shape(data_yosemite_upper_pines_geom) +
  tm_dots(col = "#009900FF", size = 0.1, alpha = 0.9,
          id = "park") +
  tm_view(set.view = c(-119.559917, 37.061753, 6))

test <- data_joined_2018 %>%
  filter(park %in% "Wawona") %>%
  summarize(white = mean(white, na.rm = TRUE),
            black = mean(black, na.rm = TRUE),
            asian = mean(asian, na.rm = TRUE),
            multiracial = mean(multiracial, na.rm = TRUE),
            other = mean(other, na.rm = TRUE),
            native_american = mean(native_american, na.rm = TRUE),
            pacific_islander = mean(pacific_islander, na.rm = TRUE),
            hispanic_latinx = mean(hispanic_latinx, na.rm = TRUE)) %>%
  pivot_longer(cols = 1:8, names_to = "race", values_to = "race_percent_average") %>% 
  mutate(race = str_replace(string = race,
                            pattern = "_",
                            replacement = " "),
         race = str_to_title(race))


test <- data_joined_2018 %>%
  filter(park %in% "Wawona") %>%
  select(park, median_income) %>% 
  rename(location_indicator = park) %>% 
  mutate(mean_zip_code_population = 1,
         data_source = "Visitors to California Sites")

median_income_ca_test <- data_ca_acs_2018 %>%
  select(zip_code, median_income, mean_zip_code_population) %>% 
  rename(location_indicator = zip_code) %>% 
  mutate(data_source = "California Residents")

median_income_plot_df_test <- rbind(test, median_income_ca_test)

color_ridb_ca <- c("Visitors to California Sites" = "#009900FF", 
                   "California Residents" = "#666666")
fill_ridb_ca <- c("Visitors to California Sites" = "#00c000", 
                  "California Residents" = "#848484")

median_income_plotly_test <- ggplot() +
  geom_histogram(data = median_income_plot_df_test,
                 aes(x = median_income,
                     color = data_source,
                     fill = data_source,
                     #weight = mean_zip_code_population,
                     text = data_source),
                 alpha = 0.5) +
  scale_fill_manual(values = fill_ridb_ca) +
  scale_color_manual(values = color_ridb_ca) +
  scale_x_continuous(labels = dollar) +
  labs(x = "Household Median Income (US $)",
       y = "Density") +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank())

ggplotly(median_income_plotly_test, 
         tooltip = list("text")) %>% 
  layout(showlegend = FALSE) %>%
  config(modeBarButtonsToRemove = list("pan", "select", "lasso2d", "autoScale2d", 
                                       "hoverClosestCartesian", "hoverCompareCartesian"))


test <- data_joined_2018 %>%
  filter(park %in% "Wawona") %>%
  select(park, aggregated_site_type) %>% 
  mutate(aggregated_site_type = str_to_title(string = aggregated_site_type),
         aggregated_site_type = str_replace(string = aggregated_site_type,
                                            pattern = "Rv",
                                            replacement = "RV")) %>% 
  count(aggregated_site_type) %>% 
  mutate(percent = n/sum(n))

hist_colors <- c("#009900FF")

# plot for shiny app
site_type_plotly <- ggplot(data = test) +
  geom_col(aes(x = percent, 
               y = reorder(aggregated_site_type, percent), 
               text = paste0(percent(n/sum(n), accuracy = 1), " of reservations were made to ", 
                             aggregated_site_type, " sites", "<br>(All reservations to site: ",
                             comma(sum(n), accuracy = 1), ")")),
           fill = hist_colors) +
  scale_x_continuous(labels = percent) +
  labs(x = paste0("Percentage of Reservations to "),
       y = "",
       title = paste0("Number of Visits by Site Type for<br>")) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank(),
        plot.title = element_text(size = 11))

ggplotly(site_type_plotly,
         tooltip = list("text"))


race_group <- c("other", "pacific_islander", "multiracial", "asian",
                "black", "white", "native_american", "hispanic_latinx")

test_df <- data_joined_2018 %>%
  filter(park %in% "Middle Meadows") %>%
  select(park, customer_zip, asian, black, hispanic_latinx, 
         multiracial, native_american, other, pacific_islander, white,
         distance_traveled_m) %>% 
  mutate(distance_traveled_mi = distance_traveled_m * 0.000621371) %>% 
  select(-distance_traveled_m) %>% 
  drop_na(distance_traveled_mi) %>% 
  pivot_longer(cols = 4:10,
               names_to = "race",
               values_to = "race_percentage") %>% 
  filter(race %in% paste0(race_group)) %>% 
  drop_na(race_percentage)


site_type_test <- data_joined_2018 %>%
  filter(park %in% "Wawona") %>%
  select(park, aggregated_site_type) %>% 
  mutate(aggregated_site_type = str_to_title(string = aggregated_site_type),
         aggregated_site_type = str_replace(string = aggregated_site_type,
                                            pattern = "Rv",
                                            replacement = "RV")) %>% 
  count(aggregated_site_type)

hist_colors <- c("#009900FF")

site_type_plotly <- ggplot(data = site_type_test) +
  geom_col(aes(x = n/sum(n), 
               y = reorder(aggregated_site_type, n), 
               text = paste0(percent(n/sum(n), accuracy = 1), " of reservations were made to ", 
                             aggregated_site_type, " sites", "<br>(All reservations to site: ",
                             comma(sum(n), accuracy = 1), ")")),
           fill = hist_colors) +
  scale_x_continuous(labels = percent) +
  labs(x = "Percentage of Reservations to Selected Site",
       y = "",
       title = paste0("Number of Visits by Site Type for in 2018")) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank(),
        plot.title = element_text(size = 11))

ggplotly(site_type_plotly,
         tooltip = list("text"))

booking_window_rdf <- data_joined_2018 %>%
  filter(park %in% "Anacapa Island") %>%
  filter(booking_window > 0) %>%
  select(park, booking_window)

x_max <- (round(max(booking_window_rdf$booking_window) / 5) * 5) + 5


daily_cost_visitor <- data_joined_2018 %>%
  filter(park %in% "Anacapa Island") %>%
  filter(daily_cost_per_visitor != "Inf") %>%
  select(park, daily_cost_per_visitor)

x_max_test <- (round(max(daily_cost_visitor$daily_cost_per_visitor) / 5) * 5) + 5

quant_80 <- quantile(x = daily_cost_visitor$daily_cost_per_visitor,
                     probs = seq(0, 1, 0.1))[[9]] %>% round(0)

hist_colors <- c("#009900FF", "#00c000")

# plot for shiny app
daily_cost_plotly <- ggplot(data = daily_cost_visitor) +
  geom_histogram(aes(x = daily_cost_per_visitor, 
                     text = paste(percent(..count.. / nrow(daily_cost_visitor), accuracy = 0.1), 
                                  "of all reservations paid between", dollar(xmin), "and", dollar(xmax),
                                  "<br>(All reservations to site: ",
                                  comma(nrow(daily_cost_visitor), accuracy = 1), ")")),
                 binwidth = 1,
                 center = 0.5,
                 fill = hist_colors[[1]], 
                 col = hist_colors[[2]], size = 0.05) +
  labs(x = "Daily cost per visitor ($)",
       y = "",
       title = paste0("Daily Cost per Visitor for Visits to")) +
  scale_x_continuous(limits = c(0, x_max), labels = dollar) +
  scale_y_continuous(labels = comma) +
  geom_vline(xintercept = quant_80,
             linetype = "dashed", alpha = 0.5, color = "#000099") +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank(),
        plot.title = element_text(size = 11))

ggplotly(daily_cost_plotly,
         tooltip = list("text"),
         dynamicTicks = TRUE) %>% 
  layout(margin = list(b = 130, t = 100), 
         annotations =  list(x = 1, 
                             y = -0.6, 
                             text = paste0("80% of reservations paid less than ", dollar(quant_80), 
                                           " per visitor per day <br>(shown on plot with dotted line)."), 
                             showarrow = F, 
                             xre = 'paper', yref = 'paper', 
                             xanchor = 'left', 
                             yanchor = 'auto', 
                             xshift = 0, yshift = 0,
                             font = list(size = 12, color = "#000099")))


dist_travel_df <- data_joined_2018 %>%
  filter(agency %in% "USFS",
         admin_unit %in% "Eldorado National Forest",
         park %in% "Middle Meadows") %>%
  mutate(distance_traveled_mi = distance_traveled_m * 0.000621371) %>%
  select(agency, admin_unit, park, distance_traveled_mi)
  filter(!is.na(distance_traveled_mi))

x_max <- (round(max(dist_travel_df$distance_traveled_mi) / 5) * 5) + 5 # max x rounded to nearest 5
center_bin <-
  if (max(dist_travel_df$distance_traveled_mi) > 100) {
    round((max(dist_travel_df$distance_traveled_mi) / 100) / 5) * 5
  } else if (max(dist_travel_df$distance_traveled_mi) > 10) {
    round((max(dist_travel_df$distance_traveled_mi) / 10) / 5) * 5
  } else {
    0.5
  }

quant_80 <- quantile(x = dist_travel_df$distance_traveled_mi,
                     probs = seq(0, 1, 0.1))[[9]] %>% round(0)
split_all <- data.frame(table(cut(x = dist_travel_df$distance_traveled_mi,
                                  breaks = seq(0,
                                               x_max,
                                               center_bin * 2))))


# parameters
hist_colors <- c("#009900FF", "#00c000")

# plot for shiny app
dist_travel_plot <- ggplot(data = dist_travel_df) +
  geom_histogram(aes(x = distance_traveled_mi,
                     text = paste0(scales::percent(..count.. / nrow(dist_travel_df), accuracy = 0.1), 
                                                   " of all reservations traveled between ", " MIN ", " and ", " MAX ", " miles",
                                                   "<br>(", scales::comma(..count.., accuracy = 1), " reservations)")),
                     binwidth = center_bin * 2,
                     center = center_bin,
                     fill = hist_colors[[1]], 
                     col = hist_colors[[2]], size = 0.05) +
  scale_x_continuous(limits = c(0, x_max)) +
  scale_y_continuous(labels = comma) +
  geom_vline(xintercept = quant_80,
             linetype = "dashed", alpha = 0.5, color = "darkred") +
  labs(x = "Distance traveled (miles)",
       y = "",
       title = paste0("Distance Traveled to Reservations for <br>", "Middle Meadows", ", ", "Eldorado National Forest", " in 2018")) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank()
  )

ggplotly(dist_travel_plot,
         tooltip = list("text")) %>% 
  layout(margin = list(b = 130, t = 100), 
         annotations =  list(x = 1, 
                             y = -0.35, 
                             text = paste0("80% of reservations to California overnight sites in 2018 traveled less than ", 
                                           " quant_80 ", " miles."), 
                             showarrow = F, 
                             xre = 'paper', yref = 'paper', 
                             xanchor = 'left', 
                             yancho = 'auto', 
                             xshift = 0, yshift = 0,
                             font = list(size = 12, color = "darkred")))



dist_travel_df <- data_joined_2018 %>%
  filter(agency %in% "USFS",
         admin_unit %in% "Eldorado National Forest",
         park %in% "Middle Meadows") %>%
  mutate(distance_traveled_mi = distance_traveled_m * 0.000621371) %>% 
  select(agency, admin_unit, park, distance_traveled_mi)

hist_colors <- c("#009900FF")

ggplot(data = dist_travel_df) +
  geom_histogram(aes(x = distance_traveled_mi),
                 fill = hist_colors) +
  scale_y_continuous(labels = comma) +
  labs(x = "Distance traveled (miles)",
       y = "",
       title = "Distribution of Distance Traveled to ",
       subtitle = "Overnight Reservations in California in 2018") +
  scale_x_continuous(limits = c(0, 3000), breaks = seq(0, 3000, 500), minor_breaks = seq(0, 3000, 250)) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank()
  )


choices <- vector()

for (i in seq_along(admin_units)){
  
  choices <- append(choices,
                    admin_units_to_site_dict$get(input$admin_units[[i]]))
  
}

updateSelectizeInput(session, "site_visitorsheds",
                     choices = sort(choices))




for (i in colnames(data_joined_2018)) {
  
  return(class(data_joined_2018$i))
  return(length(unique(data_joined_2018$i)))
  
}

# creating booking window plot + reactive df
booking_window_df <- `2018_data_plot_boooking_window` %>% 
    filter(agency %in% "USFS")

# parameters
hist_colors <- c("#009900FF")

# plot for shiny app
ggplot(data = booking_window_df) + # reactive df
  geom_histogram(aes(x = booking_window),
                 binwidth = 7,
                 fill = hist_colors) +
  labs(x = "Days elapsed from order to visit (each bar = 1 week)",
       y = "",
       title = "Distribution of Booking Windows for",
       subtitle = "Overnight Reservations in California in 2018") +
  scale_x_continuous(limits = c(0, 510), 
                     breaks = seq(0, 510, by = 30)) +
  scale_y_continuous(labels = comma) +
  geom_vline(xintercept = 180, 
             linetype = "dashed", size = .3, alpha = .5) +
  annotate("text", label = "6 months", 
           x = 210, y = 65000) +
  geom_vline(xintercept = 360, 
             linetype = "dashed", size = .3, alpha = .5) +
  annotate("text", label = "1 year", 
           x = 380, y = 65000) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank())


# testing creating a dictionary with collections ----

au_test_values <- c("Yosemite National Park", "Eldorado National Forest")

au_test_df <- data_joined_2018 %>% 
  filter(admin_unit %in% au_test_values)

# start here for dictionary
au_vector <- as.vector(unique(au_test_df$admin_unit))

au_dict <- dict()

for (i in seq_along(au_vector)){
  # pull out each admin unit
  au_df <- au_test_df %>% filter(admin_unit == au_vector[[i]]) 
  # pull out each park
  value_vector <- unique(au_df$park)
  
  au_dict$set(au_vector[[i]], value_vector)
} # end here for dictionary

# use keys() to view all the keys in the dict
# use get() to get specific values from a specific key













test_adminUnit_choices <- dict(items = NULL,
                               keys = au_choices("USFS"))


au_choices <- function(selAgency){
  
  au_df <- data_joined_2018 %>% 
    filter(agency == selAgency)
  
  au_value <- as.vector(unique(au_df$regional_area))
  
  au_value
}






# plot test
ggplot(data = data_test, aes(x = length_of_stay)) + 
  geom_histogram()

test <- data_joined_2018 %>% 
  filter(agency == "USFS")

admin_test <- as.vector(unique(test$regional_area))

# admin unit choices
admin_unit_choices <- {
  "USFS": admin_test
}

admin_unit_choices[input.agency]



DT::datatable(data_joined_2018)

select_analysis <- function(){
  
  selectizeInput(inputId = "analysis",
               label = "2. What kind of analysis do you want to see?",
               # conditional panel options / "id's" ---- 
               choices = c(Comparison = "compare", Distribution = "hist"),
               multiple = FALSE,
               options = list(
                 placeholder = "Select an analysis type",
                 onInitialize = I('function() { this.setValue(""); }')
               ))
}



# OLD INPUTS ----
selectizeInput(inputId = "compare_first",
               label = "3. Select the first variable",
               choices = c("Distance traveled" = "distance_traveled_mi",
                           "Race" = "race"),
               multiple = FALSE,
               options = list(
                 placeholder = "Type to search for a variable",
                 onInitialize = I('function() { this.setValue(""); }')
               )) # end of step 3 compare first var

# comparison second var 
selectizeInput(inputId = "compare_second",
               label = "4. Select a second variable to compare",
               choices = c("Distance traveled" = "distance_traveled_mi",
                           "Race" = "race"),
               multiple = FALSE,
               options = list(
                 placeholder = "Type to search for a variable",
                 onInitialize = I('function() { this.setValue(""); }')
               )) # end of step 4 compare second var 

# parameters
racial_group_colors <- c("Other" = "#999999", "Pacific Islander" = "#E69F00", "Multiracial" = "#56B4E9",
                         "Asian" = "#009E73", "Black" = "#F0E442", "White" = "#0072B2", 
                         "Native American" = "#D55E00", "Hispanic Latinx" = "#CC79A7")

# plot for shiny
ggplot(data = data_comp_dist_travel_race) +
  geom_col(aes(x = distance_traveled_bins,
               y = race_percentage,
               fill = race),
           stat = "identity",
           position = "dodge")  +
  scale_fill_manual(values = racial_group_colors) +
  labs(y = "Distance Traveled (miles)",
       x = "Percentage (%)",
       caption = "Distance Travel Quintiles: 1 = less than 60.2 (with the lowest being 0.5), 2 = 60.2 - 116.9, 3 = 116.7 - 180.9, 4 = 180.9 - 229.3, 5 = above 229.3 (with the highest being 3613.7") +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank())



data_reg_comb <- data_joined_2018 %>% 
  group_by(regional_area, agency) %>% 
  summarize(count = n())


tmap_mode("plot")
tm_shape(data_ca_geom) +
  tm_polygons(col = "white") +
tm_shape(data_reg_comb) +
  tm_symbols(shape = "agency",
             title.shape = "Agency")

## RACE COL PLOT ----
## -- data wrangle -- ##

## -- create plot -- ##

# parameters
race_colors_ridb_ca <- c("RIDB" = "#009900FF", "CA" = "#666666")

# plot for shiny app
ggplot(data = data_hist_race) +
  geom_col(aes(x = race_percent_average,
               y = race,
               fill = data_source),
           stat = "identity",
           position = "dodge") +
  scale_fill_manual(values = groups_colors_ridb_ca) +  
  geom_text(aes(x = race_percent_average,
                y = race,
                label = paste0(round(race_percent_average, 1), "%"),
                col = data_source), 
            position = position_dodge(width = 1), 
            hjust = -0.1, size = 4) +
  scale_color_manual(values = groups_colors_ridb_ca) +
  labs(x = "Percentage (%)",
       y = "") +
  scale_x_continuous(limits = c(0, 60), breaks = seq(0, 60, 10), 
                     minor_breaks = seq(0, 60, 5)) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank()) 
# END RACE PLOT



hist_colors <- c("#009900FF")

# plot for shiny app
ggplot(data = data_hist_distance_traveled) +
  geom_histogram(aes(x = distance_traveled_mi),
                 fill = hist_colors) +
  scale_x_continuous(limits = c(0, 3000), breaks = seq(0, 3000, 500), minor_breaks = seq(0, 3000, 250)) +
  labs(x = "Distance traveled (miles)",
       y = "") +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank())


# distance traveled ----
# parameters
hist_colors <- c("#009900FF")

# plot for shiny app
ggplot(data = data_hist_distance_traveled) +
  geom_histogram(aes(x = distance_traveled_mi),
                 fill = hist_colors) +
  labs(x = "Distance traveled (miles)",
       y = "",
       title = "Distribution of Distance Traveled to ",
       subtitle = "Overnight Reservations in California in 2018") +
  scale_x_continuous(limits = c(0, 3000), breaks = seq(0, 3000, 500), minor_breaks = seq(0, 3000, 250)) +
  theme_minimal() +
  theme(plot.background = element_rect("white"),
        panel.grid.major.y = element_blank()) 






combined_summary_2018 <- readRDS(here::here("../../data_clean/2018_joined_data_site_summary.rds"))
combined_2018 <- readRDS(here::here("../../data_clean/2018_joined_data.csv"))

ggplot(data = combined_2018, aes(x = mean_booking_window)) +
  geom_histogram()

## TO DO ## ----

# need to figure out why these variables won't show up on app. how do I give one condition id to multiple options?
choices = c(booking_scat_var = "book_scat",
            agency_comp_acs_col_vars = "acs_scat")

# when 2. What kind of analysis do you want to see? is empty how to remove step 4?  Pick second variable to compare 




## OLD ## ----

#### TABS TO THINK ABOUT READDING LATER #### ----  


# selectizeInput(inputId = "distribution",
#                label = "3. Pick a variable to see its distribution",
#                choices = c()),


# tabPanel(title = "Spatial Analysis",
#   "spatial analysis maps and inputs here",
#   # subset agency picker input ----
#   shinyWidgets::pickerInput(inputId = "agency",
#                             label = "Select an agency:",
#                             choices = c("USFS", "NPS", "USACE", "BOR"),
#                             # selected = c("USFS", "NPS", "USACE", "BOR"), 
#                             # use this to automatically to set default choices
#                             multiple = TRUE,
#                             options = pickerOptions(actionsBox = TRUE)),
#   shinyWidgets::pickerInput(inputId = "state",
#                             label = "Select a state:",
#                             choices = c("California", "Alaska", "Utah", "Maine"),
#                             selected = "California",
#                             multiple = TRUE,
#                             options = pickerOptions(actionsBox = TRUE)),
#   shinyWidgets::pickerInput(inputId = "year",
#                             label = "Select a year:",
#                             choices = 2018,
#                             multiple = TRUE,
#                             options = pickerOptions(actionsBox = TRUE)),
#   shinyWidgets::pickerInput(inputId = "variable",
#               label = "Select a variable",
#               choices = c("Median income", "Race", "Transportation"),
#               selected = " ", # need to figure out why there is a default select
#               multiple = FALSE,
#               options = pickerOptions(actionsBox = TRUE))
# ),
# tabPanel(title = "Temporal Analysis",
#   "graphs that show interesting temporal trends"
# ))