## scraping CFSR data from UNC

## load packages
## if there are any errors here, you
## probably need to install the packages with 
## e.g., install.packages("tidyverse")
library(tidyverse)
library(tidycensus)
library(glue)
library(rvest)


## for reference, this is a county-year-specific URL
## http://sasweb.unc.edu/cgi-bin/broker?_service=default&_program=cwweb.cfsr3net.sas&county=North%20Carolina&label=&format=html&entry=6&meas=1a&meas=1b&meas=2a&meas=2b&meas=2c&meas=2d&meas=2e&year=20194&Type=L&DatShow=0
## Used that as an example for the `make_url` function

## load custom functions written for this script
source("R/make_url.r")
source("R/get_cfsr_data.r")

## grab NC counties and format them for URL insertion
data(fips_codes, package = "tidycensus")
nc_counties = filter(fips_codes, state == "NC") %>%
  mutate(
    county_name = str_replace(county, " County", ""),
    county_for_url = str_replace_all(county_name, " ", "%20")
  )

## url with placeholders for county and year
base_url = 
  "http://sasweb.unc.edu/cgi-bin/broker?_service=default&_program=cwweb.cfsr3net.sas&county={county}&label=County&format=html&entry=6&meas=1a&meas=1b&meas=2a&meas=2b&meas=2c&meas=2d&meas=2e&year={year}4&Type=L&DatShow=0"

## make complete list of URLs to get data from
## using the make_url function defined in a separate file
urls = make_url(year = 2016:2019, county = nc_counties$county_for_url, base_url = base_url)

## augment urls with data, call it results
results = urls
for (i in 1:nrow(results)) {
  message(paste("Iter", i, results$county[i], results$year[i]))
  results$data[[i]] = 
    get_cfsr_safe(url = results$url[i])
}

## save scraped results immediately
write_rds(results, "data/initial_data_dump.rds")

## clean up results and save
good_results = results %>% 
  mutate(cfsr = map(data, pluck, "result")) %>%
  unnest(cfsr) %>%
  select(year, county, measure = Measure, rate, numerator, denominator, per)

write_rds(good_results, "data/good_results.rds")
write_tsv(good_results, "data/cfsr_2016_2019.tsv")

## check for errors
issues = results %>%
  mutate(errors = map(data, pluck, "error")) %>%
  unnest(errors)

issues
