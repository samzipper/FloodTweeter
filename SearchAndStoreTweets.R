## SearchAndStoreTweets.R
#' This script is intended to:
#'  (1) search Twitter for a keyword or set of keywords
#'  (2) download all matching Tweets
#'  (3) save the output to a SQLite database

# path to git directory - change this to wherever you have your git repository
git.dir <- "C:/Users/Sam/WorkGits/FloodTweeter/"

# load packages
library(rtweet)
library(lubridate)
library(DBI)

## search string: what will you search twitter for?
# test search strings with the file TestSearchStrings.R to decide
search.text <- "(high water) OR (heavy rain) OR (flash flooding) OR (hail flooding) OR (street flooding) OR (road flooding)"

# search within the previous day only
date_today <- as.Date(Sys.time())
date_yesterday <- date_today-days(1)

# combine text and dates into a string for rtweet
search.str <- paste0(search.text, " since:", as.character(date_yesterday), " until:", as.character(date_today))

# output directory: save to Dropbox, not git repository, so it's automatically backed up
# this is also where authentication info is stored
out.dir <- "C:/Users/Sam/OneDrive - The University of Kansas/Research/Twitter/FloodTweeter/"

# path to save output data
path.out <- paste0(out.dir, "FloodTweeter.sqlite")
db <- DBI::dbConnect(RSQLite::SQLite(), path.out)  # will be created if doesn't exist

# path to save the screen output
path.sink <- paste0(out.dir, "FloodTweeterOut_Screen_", format(Sys.time(), "%Y%m%d-%H%M"), ".txt")

# read in token which was created with script rtweet_SetUpToken.R
r.token <- readRDS(file.path(out.dir, "twitter_token.Rds"))

## launch sink file, which will store screen output 
# this is useful when automating, so it can be double-checked later
# to make sure nothing weird happened
s <- file(path.sink, open="wt")
sink(s, type="message")

# status update
print(paste0("starting, from ", date_yesterday, " to ", date_today))

# USA bounding box for search, determined using `lookup_coords("usa")`
usa_coords <- structure(list(place = "usa", box = c(sw.lng = -124.848974, sw.lat = 24.396308, 
                                                    ne.lng = -66.885444, ne.lat = 49.384358), 
                             point = c(lat = 36.89, 
                                       lng = -95.867)), 
                        class = c("coords", "list"))

# search twitter!
tweets <- rtweet::search_tweets(search.str,
                                n=10000, 
                                geocode=usa_coords,
                                type="recent",
                                include_rts=F,
                                retryOnRateLimit=T, 
                                token=r.token)

# subset to yesterday only, just in case...
tweets <- subset(tweets, created_at >= date_yesterday & created_at < date_today)

# get rid of duplicates just in case
tweets <- unique(tweets)

# put in order
tweets <- tweets[order(tweets$status_id), ]

# convert dates to character string for database
tweets$created_at <- as.character(tweets$created_at)

## convert columns that are lists to text strings separated by _<>_
# find list columns
cols.list <- which(lapply(tweets, class) == "list")
for (col in cols.list){
  tweets[,col] <- apply(tweets[,col], 1, function(x) as.character(paste(x, collapse="_<>_")))
}

## put into database
# add data frame to database (if it doesn't exist, it will be created)
dbWriteTable(db, "tweets", tweets, append=T)

# when you're done, disconnect from database (this is when the data will be written)
dbDisconnect(db)

# print status update
print(paste0(dim(tweets)[1], " tweets added to database"))

# close sink
close(s)
sink()
sink(type="message")
close(s)