library(glue)
library(rvest)
library(tidyverse)

get_cfsr_data = function(url) {
  ## figuring out what data to extract is a largely manual process
  ## the "developer tools" in the browser can help a lot
  
  ## read the HTML
  page = read_html(url)
  page %>% 
    ## extract any tables
    html_nodes("table") %>% 
    ## we're interested in the 2nd table
    pluck(2) %>% 
    ## parse the table to an R data frame
    html_table() %>%
    ## pick our relevant columns
    select(Measure, value = ncol(.)) %>%
    ## get rid of punctuation in the numbers
    mutate(
      value = str_replace_all(value, pattern = ",|%", replacement = "")
    ) %>% 
    ## separate the cell values into meaningful parts
    separate(value, into = c("rate", "numerator", "denominator"), sep = " = | / ") %>%
    ## convert to numeric
    type.convert() %>%
    ## where applicable, not the "per" units
    mutate(
      per = case_when(
        Measure == "Maltreatment in foster care" ~ 100000,
        Measure == "[HB630 - CWS5] Placement stability" ~ 1000,
        TRUE ~ 1
      ),
      ## recalculate the rate so there won't be rounding errors
      rate = numerator / denominator * per
    )
}

## "safe" version of the data-fetching function 
## that will not halt completely if there is an error
get_cfsr_safe = safely(get_cfsr_data)