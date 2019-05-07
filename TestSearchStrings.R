## TestSearchStrings.R
#' This script is intended to be a simple way to test different search strings to help
#' determine the best search string to collect tweets of interest to the project.

## load packages
library(rtweet)
library(lubridate)

## number of results to print to screen
n.print <- 20

## search string: what will you search twitter for?
search.text <- "(high water) OR (heavy rain) OR (flash flooding) OR (hail flooding) OR (street flooding) OR (road flooding)"

# search within the previous day only
date_today <- as.Date(Sys.time())
date_yesterday <- date_today-days(1)

# combine text and dates into a string for rtweet
search.str <- paste0(search.text, " since:", as.character(date_yesterday), " until:", as.character(date_today))

# USA bounding box for search, determined using `lookup_coords("usa")`
usa_coords <- structure(list(place = "usa", box = c(sw.lng = -124.848974, sw.lat = 24.396308, 
                                                    ne.lng = -66.885444, ne.lat = 49.384358), 
                             point = c(lat = 36.89, 
                                       lng = -95.867)), 
                        class = c("coords", "list"))

## search for tweets!
tweets <- rtweet::search_tweets(search.str,
                                n=10000, 
                                geocode=usa_coords,
                                type="recent",
                                include_rts=F,
                                retryOnRateLimit=T)

## print a random selection of tweets to screen
print(base::sample(tweets$text, n.print))
print(paste0(dim(tweets)[1], " tweets found"))
