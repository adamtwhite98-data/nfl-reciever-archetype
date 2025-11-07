

#Goal: Cluster wide receivers by play-level usage: route depth, target share, YAC

#ML angle: K-means 

#Twist: Build a 2D interactive “Receiver Map” visualization — 
#               find modern comps for legends like Randy Moss or Wes Welker.

#utilizes PCA which is a dimensionality reduction technique that increases
# interpretability, while at the same time minimizes potential information loss

library(nflfastR)
library(dplyr)
library(tidyr)
library(scales)
library(uwot)
library(factoextra)
library(gganimate)
library(uwot)
library(ggplot2)
library(cluster)
library(ggrepel)

setwd("/Users/Adam/Sports Analytics Hobby/NFL Analytics/Receiver Archtype Data/")

#lets look at receivers from 2010-2024 but filter to a certain target threshold
load("wr_season_stats.RData")
load("targets.RData")

wr_s_feats <- season_stats %>%
  select(player_id, player_name, season, target_share)


#selecting important features for analysis (season level data, min. 50 targets)
wr_features <- targets %>%
  group_by(receiver_player_id, target_player_name, season) %>%
  summarize(targets = n(),
            catch_rate = mean(complete_pass),
            ADOT = mean(air_yards),
            explosive_p = mean(ifelse(complete_pass == 1 & air_yards >= 20, 1, 0)),
            avg_yac = mean(yards_after_catch),
            deep_target_rate = mean(ifelse(air_yards >= 20, 1, 0)),
            first_down_rate = mean(first_down_pass)
            ) %>%
  filter(targets >= 70)

## joining other season level data to get stats like target share, etc.

wr_features <- wr_features %>%
  inner_join(wr_s_feats, by = c("receiver_player_id" = 'player_id', 
                                "target_player_name" = 'player_name',
                                'season' = 'season'))

dbl_cols <- c("catch_rate", "ADOT", "explosive_p", "avg_yac", 
              "deep_target_rate", "first_down_rate", "target_share")

#removing the wr name and seasons then scaling the data
labels <- wr_features[1:4]
wr_feats_scaled <- wr_features[-1:-3] %>%
  mutate(across(all_of(dbl_cols), ~ ifelse(is.na(.), 0, .))) %>%
  mutate(across(all_of(dbl_cols), ~ scale(.)))

#principle component analysis to inspect variance and how comp. explain the most vars
pca <- prcomp(select(wr_feats_scaled, all_of(dbl_cols)), center=FALSE, scale.=FALSE)
vars_explained <- round(pca$sdev^2/sum((pca$sdev)^2)*100, 4)

summary(pca)

#visualize scree plot 
fviz <- fviz_eig(pca)

animated <- fviz + 
  geom_text(aes(label = vars_explained), vjust = -1) + 
  transition_reveal(seq_along(vars_explained), keep_last = TRUE)
animate(animated, renderer = gifski_renderer(), height = 400, res = 100)
# 4 PCs explain enough ~90%, 5 rises to 96%
# likely will go with 4


set.seed(42)
umap_2d <- umap(select(wr_feats_scaled, all_of(dbl_cols)), n_neighbors=150, min_dist=0.1, n_components=2)
umap_df <- as.data.frame(umap_2d)
colnames(umap_df) <- c("UMAP1","UMAP2")
umap_df <- cbind(wr_features %>% 
                   select(receiver_player_id, 
                          target_player_name,
                          season), umap_df)



k <- 4
km <- kmeans(select(wr_feats_scaled, all_of(dbl_cols)), centers=k, nstart=150)
umap_df$cluster <- factor(km$cluster)

# quick silhouette
sil <- silhouette(km$cluster, dist(select(wr_feats_scaled, all_of(dbl_cols))))
mean(sil[,3])


top_labels <- umap_df %>% group_by(cluster)
ggplot(umap_df, aes(x=UMAP1, y=UMAP2, color=cluster)) +
  geom_point(alpha=0.7) +
  geom_text_repel(data=top_labels, aes(label=paste0(target_player_name, " ", season)), 
                  vjust=1.5, size=3)


cluster_summary <- umap_df %>%
  left_join(wr_features, by=c("receiver_player_id","season")) %>%
  group_by(cluster) %>%
  summarise(n_players = n(),
            ADOT= round(mean(ADOT, na.rm=TRUE),2),
            avg_yac = round(mean(avg_yac, na.rm=TRUE),2),
            avg_catch_rate = round(mean(catch_rate, na.rm=TRUE) * 100,2),
            deep_rate = round(mean(deep_target_rate, na.rm=TRUE) * 100,2),
            avg_tgt_share = round(mean(target_share, na.rm=TRUE) * 100,2),
            explosive_play_perc = round(mean(explosive_p, na.rm=TRUE) * 100,2),
            first_down_rate = round(mean(first_down_rate, na.rm = TRUE) * 100,2)
            )

setwd("/Users/Adam/Sports Analytics Hobby/NFL Analytics/Receiver Archtype Data/")

save(umap_df, file = "umap_df.RData")
save(wr_features, file = "wr_features.RData")
save(season_stats, file = "wr_season_stats.RData")

knitr::kable(cluster_summary)
names(wr_features)

#extracting the player id I care about
return_player_id_stats <- function(player_name, year){
  target_indices <- which(
    season_stats$player_name == player_name &
    season_stats$season == year
  )
  return(cbind(season_stats[target_indices,1:3], season_stats[target_indices,35:38]))
}



### Create a function to find the closest player
find_closest_player <- function(df, wr_features, player_id, player_name, season) {
  target_index <- which(
    df$receiver_player_id == player_id &
      df$target_player_name == player_name &
      df$season == season
  )
  
  if (length(target_index) == 0) {
    return("Target player id, name, or season not found.")
  }

  distances <- sqrt(
    (df$UMAP1 - df$UMAP1[target_index])^2 +
      (df$UMAP2 - df$UMAP2[target_index])^2
  )
  
  distances[target_index] <- Inf

  closest_index <- which.min(distances)
  
  stats_closest <- t(return_player_id_stats(
    wr_features[closest_index, ]$target_player_name,
    wr_features[closest_index, ]$season))

  stats_target <- (return_player_id_stats(player_name, season))
  
  stats_target <- t(stats_target[stats_target$player_id == player_id,])
  
  stats_both <- cbind(stats_target, stats_closest)
  
  season <- cbind(wr_features[target_index,3],
                   wr_features[closest_index,3])
  colnames(stats_both) <- c("Target Player", "Closest Player")
  colnames(season) <- c("Target Player", "Closest Player")
  
  stats_both <- rbind(stats_both, season, c("-", "-"))
  
  wr_feats <- t(cbind(
    rbind(round(wr_features[target_index,5]*100,2),
          round(wr_features[closest_index,5]*100,2)),
    rbind(round(wr_features[target_index,6],2),
          round(wr_features[closest_index,6],2)),
    rbind(round(wr_features[target_index,7]*100,2),
          round(wr_features[closest_index,7]*100,2)),
    rbind(round(wr_features[target_index,8],2),
          round(wr_features[closest_index,8],2)),
    rbind(round(wr_features[target_index,9]*100,2),
          round(wr_features[closest_index,9]*100,2)),
    rbind(round(wr_features[target_index,10]*100,2),
          round(wr_features[closest_index,10]*100,2)),
    rbind(round(wr_features[target_index,11]*100,2),
          round(wr_features[closest_index,11]*100,2))))
  print(wr_feats)
  
  colnames(wr_feats) <- c("Target Player", "Closest Player")
  stats_both <- rbind(stats_both, wr_feats)
  
  
  rownames(stats_both) <- c("Player ID", "Player Name Short",
                            "Player Name", "Catches", "Targets",
                            "Yards", "TDs", "Season", "Variables Used Below", 
                            "Catch Rate", "ADOT", "Explosive Play %",
                            "Avg. YAC", "Deep Target Rate", "First Down Rate",
                            "Target Share")
  
  
  
  colnames(stats_both) <- c("Target Player", "Closest Player")
  
  return(knitr::kable(stats_both, align = 'c'))
}


#returns the players ID to use in the next function 

return_player_id_stats("J.Jones", 2015)

find_closest_player(
  df = umap_df,
  wr_features = wr_features,
  player_id = "00-0027944",
  player_name = "J.Jones",
  season = 2015
)


knitr::kable(cluster_summary)

umap_df %>%
  filter(cluster == 1 & season >= 2010) %>%
  arrange(target_player_name) %>%
  print(n = 2)
