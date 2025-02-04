# SEL agency ----
# used in (1) data summary; (2) data relationships; (3) visitorsheds; (4) data download
select_agency <- function(locationId, isMultiple = FALSE, isSize = NULL, defaultValue = "National Park Service"){
  
  selectizeInput(inputId = paste("agency", locationId, sep = "_"),
                 label = "Select an agency",
                 choices = sort(ca_agency),
                 multiple = isMultiple,
                 size = isSize,
                 options = list(
                   placeholder = "Type to search for an agency",
                   # Note(HD) when created set a value for the input to an empty string
                   onInitialize = I(paste0('function() { this.setValue("', defaultValue, '"); }'))
                 )) 
} # EO SEL agency