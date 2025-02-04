# SEL site ----
# used in (1) data summary; (2) data relationships; (3) visitorsheds; (4) data download
select_site <- function(locationId, isMultiple = FALSE, isSize = NULL, defaultValue = "Upper Pines"){
  
  selectizeInput(inputId = paste("site", locationId, sep = "_"),
                 label = "Select a reservable site",
                 choices = sites,
                 multiple = isMultiple,
                 size = isSize,
                 options = list(
                   placeholder = "Type to search for a reservable site",
                   # Note(HD) when created set a value for the input to an empty string
                   onInitialize = I(paste0('function() { this.setValue("', defaultValue, '"); }'))
                 ))
} # EO SEL site