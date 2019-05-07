## LoadTweets.R
#' This script is intended to load a data frame of tweets from an
#' SQLite database generated with the script SearchAndStoreTweets.R

# load packages
library(rtweet)
library(lubridate)
library(DBI)
library(dplyr)
library(ggplot2)

# output directory: this is where the SQLite database is
out.dir <- "C:/Users/Sam/OneDrive - The University of Kansas/Research/Twitter/FloodTweeter/"

# path to database
path.out <- paste0(out.dir, "FloodTweeter.sqlite")

# connect to database
db <- DBI::dbConnect(RSQLite::SQLite(), path.out)

# read in table
df <- dbReadTable(db, "tweets")

# trim to unique and rewrite
df <- unique(df)
dbWriteTable(db, "tweets", df, overwrite=T)

# when you're done, disconnect from database (this is when the data will be written)
dbDisconnect(db)

# plot of tweets by day
df$created_at <- ymd_hms(df$created_at)
df$DOY <- yday(df$created_at)
df$Date <- as.Date(df$created_at)
df.d <- dplyr::summarize(dplyr::group_by(df, Date),
                         tweets = sum(is.finite(created_at)))

# list of missing days - this will only work if there is more than 1 day in database
missing <- seq(df.d$Date[1], Sys.Date()-1, by="day")[!(seq(df.d$Date[1], Sys.Date()-1, by="day") %in% df.d$Date)]
print(missing)

# print most recent tweet
print(paste0("Last tweet: ", df$created_at[which.max(df$status_id)]))

ggplot(df.d, aes(x=Date, y=tweets)) +
  geom_bar(stat="identity") +
  labs(title=paste0(sum(df.d$tweets), " tweets")) +
  theme_bw() +
  theme(panel.grid=element_blank())
