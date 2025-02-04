# library(ridbAPI) cannot use because not robust enough and it's a third party package so not sure how reliable that is
# https://ridb.recreation.gov/api/v1/activities?limit=50&offset=0&apikey=

## SETUP ##
library(httr)
library(jsonlite)
library(tidyverse)
source("private/ridb-api.R")

# activities from RIDB api
response <- httr::GET("https://ridb.recreation.gov/api/v1/activities",
                      query = list(limit = 5, 
                                   offset = 0, 
                                   apikey = ridb_api_key))

# check content of the response
# confirmed it's in json string
# save body of the json string in a variable
activity_body <- content(response, "text")

# convert json to a list and then a data frame
activity_parsed_data <- fromJSON(activity_body, flatten=TRUE, simplifyDataFrame=TRUE)
activity_df <- data.frame(activity_parsed_data)

# convert df to a csv
# activity_csv <- write_csv()


