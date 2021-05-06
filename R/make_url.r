library(glue)
library(dplyr)

make_url = function(year, county, base_url) {
  combos = expand.grid(year = year, county = county) %>%
    mutate(
      url = glue(base_url)
    )
}
