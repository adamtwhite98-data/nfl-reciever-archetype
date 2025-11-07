# nfl-reciever-archetype
Performing clustering on NFL wide receivers. Utilizing dimensionality reduction techinques such as PCA and UMAP and combining with unsupervised machine mearning techniques such as K-means clustering to allocate receivers to a certain "Archetype".

## GOAL:  Cluster NFL wide receivers by **per-play-level** usage
- Variables used:
- - Average depth of target (ADOT)
  - target share
  - YAC
  - catch rate
  - explosive play percentage (catches >= 20 yards)
  - deep target rate (air yards >= 20)
  - first down rate
- Specifically did not want to include stats like targets, catches or touchdowns, to see if someone is playing at an All pro level (similar to Julio Jones 2016) but is not getting enough touches to be noticed by the NFL community
- Minimum 70 targets for season to be included

## Data Used:
- nflfastR play by play data

## Tools Used
- R (tidyverse, umap, ggplot2 (gganimate, ggrepel), uwot, factoextra, cluster)
- Euclidean distance for player similarity
- Principle component analysis for dimensionality reduction
- Data wrangling to get season level data from play by play data
- Data visualization to view clusters, and scree plot (PCA)

## Machine Learning Angle
- K-means nearest neighbor classification

## Key Insights
An optimal 4 distinct clusters, or "Receiver Archetypes" were found. I reference them as:
- **"Do it All WR1":**
- - These guys were efficient (Top 2!) in all the metrics listed earlier, while also holding the highest average target share and first down rate relative to the other clusters. The best players and their best seasons fall into this category. 
- - Examples: Davante Adams in (2018-2022), Deandre Hopkins (2018-2020) and Justin Jefferson (2020-2024)
- **"Speedy Deep Threat"**
- - These are you guys that had the highest ADOT, highest deep target percentage, and highest explosive play percentage. They also had the highest drop percentage due to the ball always being thrown deep.
- - Examples: George Pickens (2022-2024), 2019 Will Fuller V., 2018 Tyreek Hill, 2019 Kenny Golladay, and Gabe Davis (2020-2023)
- **"Short Route YAC":**
- - These are your players that had a significantly lower ADOT, but made it for it by racking up YAC. They had the highest catch rate, likely from the short route depth, and almost never went deep.
- - Examples: Deebo Samuel (2019 & 2021-2024), Cole Beasley (2018-2021), and Michael Thomas (2018-2019)
- **"Good but Nowhere Near the Best"**
- - These are your WR2s, your great WRs that are at the beginning or tail end of their career, and your guys that fall just short of the top 10-15 in the league that year. These guys are nessecary to a teams success, but these stats don't show how great they really are. They are 3rd (or last) in every variable used in this analysis.
- - Examples: Chase Claypool (2021-2022), Raiders Davante Adams (2023), Robert Woods (2022-2023), and 2024 Xavier Legette.

## Player Similarities (Code Output)
Below are some intersting player comparisons. This was done by utilizing Euclidian distance for player similarity (dimensions reduced to 2 ~70% of variance captured):
|                     | Target Player | Closest Player | 
|:--------------------|:-------------:|:--------------:|
|Player ID            |  00-0033908   |   00-0031381   |
|Player Name Short    |    C.Kupp     |    D.Adams     |
|Player Name          |  Cooper Kupp  | Davante Adams  |
|Catches              |      178      |      133       |
|Targets              |      233      |      174       |
|Yards                |     2425      |      1507      |
|TDs                  |      22       |       20       |
|Season               |     2021      |      2020      |
|Variables Used Below |       -       |       -        |
|Catch Rate           |     76.39     |     76.44      |
|ADOT                 |     8.66      |      8.3       |
|Explosive Play %     |     7.73      |      6.32      |
|Avg. YAC             |     4.52      |      3.84      |
|Deep Target Rate     |     13.3      |     12.07      |
|First Down Rate      |     46.35     |     47.13      |
|Target Share         |     31.57     |     29.95      |

This one in particular is my favorite.
|                     | Target Player | Closest Player |
|:--------------------|:-------------:|:--------------:|
|Player ID            |  00-0036900   |   00-0023921   |
|Player Name Short    |    J.Chase    |    M.Austin    |
|Player Name          | Ja'Marr Chase |  Miles Austin  |
|Catches              |      127      |       92       |
|Targets              |      175      |      142       |
|Yards                |     1708      |      1436      |
|TDs                  |      17       |       12       |
|Season               |     2024      |      2009      |
|Variables Used Below |       -       |       -        |
|Catch Rate           |     72.57     |     64.79      |
|ADOT                 |     8.72      |      9.65      |
|Explosive Play %     |     4.57      |      5.63      |
|Avg. YAC             |      4.5      |      5.01      |
|Deep Target Rate     |     11.43     |     13.38      |
|First Down Rate      |     42.86     |     44.37      |
|Target Share         |     27.87     |     23.16      |

As if these guys didn't get compared to each other enough. 
|                     | Target Player | Closest Player |
|:--------------------|:-------------:|:--------------:|
|Player ID            |  00-0027944   |   00-0027793   |
|Player Name Short    |    J.Jones    |    A.Brown     |
|Player Name          |  Julio Jones  | Antonio Brown  |
|Catches              |      136      |      138       |
|Targets              |      203      |      195       |
|Yards                |     1871      |      1815      |
|TDs                  |       8       |       13       |
|Season               |     2015      |      2014      |
|Variables Used Below |       -       |       -        |
|Catch Rate           |      67       |     70.77      |
|ADOT                 |     10.15     |     10.32      |
|Explosive Play %     |      6.9      |      7.18      |
|Avg. YAC             |     3.16      |      3.24      |
|Deep Target Rate     |     12.81     |     13.85      |
|First Down Rate      |     45.81     |     46.15      |
|Target Share         |     32.9      |     30.05      |

## Next Steps
- View NFL receiver archetypes by season, see if the output changes.
- Combine into dashboard that goes over week by week WR, RB, QB, and Team visualizations.
