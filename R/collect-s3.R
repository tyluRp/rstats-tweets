suppressPackageStartupMessages({
  library(dplyr)
  library(aws.s3)
  library(glue)
  library(rtweet)
})

df_old_tweets <- s3readRDS(
  object = "rstats_tweets.rds",
  bucket = "tylerlittlefield"
)

df_old_tweets_refreshed <- lookup_statuses(
  statuses = unique(df_old_tweets$status_id),
  token = readRDS(".rtweet_token2.rds")
)

df_old_tweets <- df_old_tweets %>% 
  # filter out matching status id's to pull refreshed ones, any remaining are
  # likely deleted tweets
  filter(!status_id %in% df_old_tweets_refreshed$status_id) %>% 
  bind_rows(df_old_tweets_refreshed) 

df_new_tweets <- search_tweets(
  q = "rstats",
  n = 18000, 
  include_rts = FALSE, 
  retryonratelimit = TRUE, 
  verbose = FALSE, 
  token = readRDS(".rtweet_token2.rds")
)

df_new_tweets %>% 
  filter(!status_id %in% df_old_tweets$status_id) %>% 
  { cat(glue("[{Sys.Date()}] Collecting {nrow(.)} new tweets...\n\n")); . } %>%
  bind_rows(df_old_tweets) %>% 
  s3saveRDS(
    object = "rstats_tweets.rds",
    bucket = "tylerlittlefield"
  )

# cronR::cron_add(
#   command = "cd /home/tyler/dev/rstats-tweets && /usr/bin/Rscript 'R/collect.R' >> 'R/collect.log' 2>&1",
#   frequency = "daily",
#   at = "11PM",
#   id = "rstats tweets",
#   tags = "#rstats, #twitter, #data",
#   description = "Collects twitter data with 'rstats' in text, everyday at 11PM."
# )
