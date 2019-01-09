library(knitr)
knitr::read_chunk("scripts/theme_addendum.R")
source("./scripts/theme_addendum.R")
source("./scripts/verwaltungsausgaben.R")
needs(markdown)
needs(rmarkdown)
needs(datasets)
needs(kableExtra)
needs(sf)
needs(tidyverse)
library(tidyverse) # ggplot2, dplyr, tidyr, readr, purrr, tibble
library(magrittr) # pipes
library(stringr) # string manipulation
library(readxl) # excel
#library(scales) # scales for ggplot2
library(jsonlite) # json
library(forcats) # easier factor handling,
library(lintr) # code linting
library(xlsx) #Excel
library(googlesheets) 
library(directlabels) # googlesheets (replace with googlesheets4 asap)

library(knitr)

out <- NULL
print(getwd())
for(ausgewaehlte_regionalausgabe in unique(posten_data$regionalausgabe)) {
  if(ausgewaehlte_regionalausgabe!="-") {
    
    print(ausgewaehlte_regionalausgabe)
    #data <- alldata %>% filter(blkz==landfilterdings)
    #ausgewaehlte_regionalausgabe <- paste("Land", data[1,]$bl)
    
    env=new.env() #create a new empty environment, it inherits objects from the current environment.
    rmarkdown::render('scripts/report.Rmd', output_file=paste0(ausgewaehlte_regionalausgabe,'.html'), envir = env, output_dir="output/generated")
  }
}