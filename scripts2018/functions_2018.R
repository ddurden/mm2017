ranker <- function(data){
    #browser()
    # assign week of the year based on Daynum -- add year from 'Season'
    ## for the given day, assign the numeric week
    week_idx <- data.frame(day=seq(0, 161, 7), week=seq(1,24, 1))
    assign_week <- function(d, idx){
        for (i in 1:length(idx$day)){
            if (d >= idx[i,1] & d <= idx[i+1,1]){
                return(idx[i,2])
            }
        }
    }
    
    # assign 1 for win, 0 for loss, 0.5 for draw to team in left-most column
    data$outcome <- ifelse(data$lscore - data$lscore>0, 1, 0)
    data$week <- sapply(data$daynum, assign_week, week_idx)
    data$weekkey_winner <- paste0(data$wteam,"_",data$week)
    data$weekkey_loser <- paste0(data$lteam,"_",data$week)
    
    # this uses the Daynum converted to week
    ranks <- steph(select(data, week, wteam, lteam, outcome), history=TRUE)
    
    # matrix comes in wide format
    wide_ranks <- as.data.frame(ranks$history)
    wide_ranks$player <- rownames(wide_ranks)
    
    # convert to long format
    long_ranks <- tidyr::gather(wide_ranks, value = player)
    names(long_ranks) <- c("player", "type", "value")
    ## this is screwing up the week -- split is a regex field
    long_ranks$week <- ldply(stringr::str_split(long_ranks$type,"[.]"))[,1]
    
    # only grab ratings
    weekly_ranks <- filter(long_ranks, str_detect(type, "Rating"))
    weekly_ranks$weekkey <- paste0(weekly_ranks$player,"_",weekly_ranks$week)
    
    # 
    reg_weekly_ranks <- merge(data, weekly_ranks, by.x=c("weekkey_winner"), by.y=c("weekkey"))
    reg_weekly_ranks <- rename(reg_weekly_ranks, wteam_rank=value) %>% select(-player, -type, -week.x, -week.y)
    reg_weekly_ranks <- merge(reg_weekly_ranks, weekly_ranks, by.x=c("weekkey_loser"), by.y=c("weekkey"))
    reg_weekly_ranks <- rename(reg_weekly_ranks, wteam_rank=value)
    return(reg_weekly_ranks)
}
