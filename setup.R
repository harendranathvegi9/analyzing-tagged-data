# Code to set up necessary packages and platform for 'Analyzing tagged data'

# function to get/load necessary packages
chkinspkgs <- function(packagevector)
{ 
  existingpackages <- installed.packages()[,1]
  for(package in packagevector)
  {
    if (package %in% existingpackages==F)
    {
      install.packages(package,quiet=T)
      existingpackages <- installed.packages()[,1]
      # check again
      if (package %in% existingpackages==F)
      {
        stop("* There is a problem with installing the following package. Restart R (command: ctrl+shift+F10 in RStudio) and run the SETUP again. If the problem persists, check your internet connection. Still, if problem persists,  refer 'Troubleshooting SETUP' in README")
        print(as.character(package))
        break
      }
      # check is over
    }
  } # end of for loop
  message("* Packages required for 'Analyzing tagged data' were checked/installed successfully.")
}

#----

repeat{
message("-------------SETUP----------------\nPackages, code and data for 'Analyzing tagged data' to be run for first time.\n* Might require internet connection\n* If there is a problem with installing packages, restart R (ctrl+shift+F10 on RStudio) and run SETUP again\n* The script should end with **DONE**\n----------------------------------")
userinput <- readline("Run (press y/n and then hit ENTER)?\n")


if(userinput!="y")
 {
  message("SETUP was not run.")
  break}

message("----\n* Checking/Installing packages ... it might take a while...") 

# set a working mirror, IIT Chennai
r <- getOption("repos")
rold <- r["CRAN"]
r["CRAN"] <- "http://ftp.iitm.ac.in/cran/"
options(repos = r)

chkinspkgs(c("dplyr","ggplot2","reshape2","knitr","rmarkdown","mime", "stringi", "magrittr", "evaluate", "digest", "formatR", "highr", "markdown", "stringr", "yaml"))

loaddata <- lapply(c("dplyr","ggplot2","reshape2","knitr","rmarkdown","mime", "stringi", "magrittr", "evaluate", "digest", "formatR", "highr", "markdown", "stringr", "yaml","rmarkdown","knitr"),suppressPackageStartupMessages(require),character.only=T)

message("* Setting 'analyzing-tagged-data-master' as the working directory\n* Loading functions\n ** oorecommend\n ** otrecommend\n ** torecommend\n ** ttrecommend")

setwd("analyzing-tagged-data-master/")
source("vistagdata.R")
rm(userinput,chkinspkgs,loaddata)

# set the mirror back
r["CRAN"] <- rold
options(repos = r)
rm(r,rold)
message("**DONE**")
message("----")
break}# end of repeat loop
