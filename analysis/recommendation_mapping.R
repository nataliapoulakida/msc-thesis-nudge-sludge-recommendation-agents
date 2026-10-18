# Run from the repository root.
# Input : the MovieLens 25M dataset (Harper & Konstan, 2015), downloaded from
#         https://grouplens.org/datasets/movielens/25m/ and unzipped to
#         data/ml-25m/ (the dataset is not redistributed in this repository).
# Output: mapping/high_personalization_mapping.csv and
#         mapping/low_personalization_mapping.csv (the 129-combination lookup
#         tables used by the prototype). Create the mapping/ folder first.
# Full description of the logic: docs/recommendation-logic.md
#
# ==============================================================================
# THESIS METHODOLOGY: MOVIELENS 25M RECOMMENDATION ENGINE PIPELINE
# Objectives:
# 1. Genre Popularity Ranking (target_9 selection)
# 2. Semantic Clustering via Cosine Similarity
# 3. Archetypal Movie Selection (70/30 Weighting)
# 4. Tier 1-4 Mapping Logic (Low Personalization)
# 5. All 129 Combination Lookup Tables (High & Low Personalization)
# ==============================================================================

# 1. LOAD LIBRARIES
if (!require("pacman")) install.packages("pacman")
pacman::p_load(dplyr, tidyr, readr, proxy, cluster)

# 2. CONFIGURATION & DATA LOADING
path <- "data/ml-25m/"

movies        <- read_csv(paste0(path, "movies.csv"))
ratings       <- read_csv(paste0(path, "ratings.csv"))
genome_tags   <- read_csv(paste0(path, "genome-tags.csv"))
genome_scores <- read_csv(paste0(path, "genome-scores.csv"))

# ==============================================================================
# PHASE 0: GENRE POPULARITY RANKING
# Selects the 9 most popular genres by total number of ratings
# Justifies the selection of the target_9 genre set
# ==============================================================================

all_genre_popularity <- movies %>%
  separate_rows(genres, sep = "\\|") %>%
  filter(genres != "(no genres listed)") %>%
  inner_join(
    ratings %>% group_by(movieId) %>%
      summarise(n_ratings = n(), .groups = "drop"),
    by = "movieId"
  ) %>%
  group_by(genres) %>%
  summarise(total_ratings = sum(n_ratings), .groups = "drop") %>%
  arrange(desc(total_ratings)) %>%
  mutate(popularity_rank = row_number())

cat("\n--- FULL GENRE POPULARITY RANKING ---\n")
print(all_genre_popularity)

# Extract top 9 genres in popularity order
target_9 <- all_genre_popularity %>%
  slice(1:9) %>%
  pull(genres)

cat("\n--- SELECTED TOP 9 GENRES ---\n")
print(target_9)

# ==============================================================================
# PHASE 1: SEMANTIC CLUSTERING
# ==============================================================================

genre_tag_profile <- movies %>%
  separate_rows(genres, sep = "\\|") %>%
  filter(genres %in% target_9) %>%
  inner_join(genome_scores, by = "movieId") %>%
  group_by(genres, tagId) %>%
  summarise(mean_relevance = mean(relevance), .groups = "drop") %>%
  pivot_wider(names_from = tagId, values_from = mean_relevance)

genre_matrix <- as.matrix(genre_tag_profile[,-1])
rownames(genre_matrix) <- genre_tag_profile$genres

cos_matrix <- as.matrix(proxy::simil(genre_matrix, method = "cosine"))
diag(cos_matrix) <- 1
rownames(cos_matrix) <- trimws(target_9)
colnames(cos_matrix) <- trimws(target_9)

# Cluster assignments derived from cosine similarity matrix
# Cluster 1: Speculative & Escapist (Adventure, Fantasy, Sci-Fi)
# Cluster 2: Grounded & Interpersonal (Comedy, Drama, Romance)
# Cluster 3: Conflict & Suspense (Action, Crime, Thriller)
genre_clusters <- data.frame(
  Genre   = c("Action", "Adventure", "Comedy", "Crime", "Drama",
              "Fantasy", "Romance", "Sci-Fi", "Thriller"),
  Cluster = c(3, 1, 2, 3, 2, 1, 2, 1, 3)
)

# ==============================================================================
# PHASE 2: ARCHETYPAL MOVIE SELECTION (70% PURITY / 30% POPULARITY)
# ==============================================================================

# A. Calculate Log-Normalized Popularity
movie_stats <- ratings %>%
  group_by(movieId) %>%
  summarise(n_ratings = n(), .groups = "drop") %>%
  mutate(norm_pop = (log(n_ratings) - min(log(n_ratings))) /
           (max(log(n_ratings)) - min(log(n_ratings))))

# B. Map Genres to lowercase Genome Tags
genre_to_tag_map <- data.frame(
  target_genre = target_9,
  tag_name     = tolower(target_9)
)

target_tag_ids <- genome_tags %>%
  filter(tag %in% genre_to_tag_map$tag_name) %>%
  inner_join(genre_to_tag_map, by = c("tag" = "tag_name"))

# C. Calculate Composite Archetype Score
purity_candidates <- genome_scores %>%
  inner_join(target_tag_ids, by = "tagId") %>%
  inner_join(movies, by = "movieId") %>%
  inner_join(movie_stats, by = "movieId") %>%
  rename(movie_genres = genres) %>%
  filter(mapply(function(t, m) grepl(t, m), target_genre, movie_genres)) %>%
  mutate(
    norm_purity     = (relevance - min(relevance)) / (max(relevance) - min(relevance)),
    archetype_score = (0.7 * norm_purity) + (0.3 * norm_pop)
  ) %>%
  arrange(desc(archetype_score))

# D. Pre-compute mean archetype score per genre
# Used to identify primary genre in multi-genre combinations
genre_mean_archetype <- purity_candidates %>%
  group_by(target_genre) %>%
  summarise(mean_archetype = mean(archetype_score), .groups = "drop")

# ==============================================================================
# PHASE 3: TIER MAPPING (LOW PERSONALIZATION LOGIC)
# Tier 2: most similar genre within cluster
# Tier 3: second most similar genre within cluster
# Tier 4: most similar genre outside cluster
# Special case: Drama/Comedy bridge via Romance
# ==============================================================================

final_table <- genre_clusters

final_table$Tier_2_Target   <- NA
final_table$Tier_3_Fallback <- NA
final_table$Tier_4_Bridge   <- NA

for (i in 1:nrow(final_table)) {
  curr  <- final_table$Genre[i]
  clust <- final_table$Cluster[i]
  
  mates   <- final_table$Genre[final_table$Cluster == clust & final_table$Genre != curr]
  sims_in <- cos_matrix[curr, mates]
  
  # MANUAL OVERRIDE 1: Grounded & Interpersonal cluster tier assignments
  # Romance is manually assigned as Tier 2 for both Comedy and Drama to reflect
  # its affective positioning as a tonal bridge between the two genres,
  # ensuring within-cluster mismatches remain tonally proximate rather than jarring.
  # Drama is assigned as Tier 2 for Romance for the same reason.
  if (curr == "Drama") {
    final_table$Tier_2_Target[i]   <- "Romance"
    final_table$Tier_3_Fallback[i] <- "Comedy"
  } else if (curr == "Comedy") {
    final_table$Tier_2_Target[i]   <- "Romance"
    final_table$Tier_3_Fallback[i] <- "Drama"
  } else if (curr == "Romance") {
    final_table$Tier_2_Target[i]   <- "Drama"
    final_table$Tier_3_Fallback[i] <- "Comedy"
  } else {
    final_table$Tier_2_Target[i]   <- names(sort(sims_in, decreasing = TRUE))[1]
    final_table$Tier_3_Fallback[i] <- names(sort(sims_in, decreasing = TRUE))[2]
  }
  
  strangers <- final_table$Genre[final_table$Cluster != clust]
  sims_out  <- cos_matrix[curr, strangers]
  final_table$Tier_4_Bridge[i] <- names(which.max(sims_out))
}

cat("\n--- TIER MAPPING ---\n")
print(final_table, row.names = FALSE)

# ==============================================================================
# PHASE 4: GENERATE ALL 129 GENRE SELECTION COMBINATIONS
# ==============================================================================

combos <- list()

# Single genre (9)
for (g in target_9) {
  combos[[length(combos) + 1]] <- c(g)
}

# Two genres (36)
for (i in 1:(length(target_9) - 1)) {
  for (j in (i + 1):length(target_9)) {
    combos[[length(combos) + 1]] <- c(target_9[i], target_9[j])
  }
}

# Three genres (84)
for (i in 1:(length(target_9) - 2)) {
  for (j in (i + 1):(length(target_9) - 1)) {
    for (k in (j + 1):length(target_9)) {
      combos[[length(combos) + 1]] <- c(target_9[i], target_9[j], target_9[k])
    }
  }
}

cat(sprintf("\nTotal combinations generated: %d\n", length(combos)))

# ==============================================================================
# PHASE 5: HELPER FUNCTIONS
# ==============================================================================

# Get best N films for a set of genres using combination-based scoring
get_best_films <- function(genre_set, n = 3) {
  candidates <- purity_candidates %>%
    filter(target_genre %in% genre_set)
  
  if (length(genre_set) > 1) {
    candidates <- candidates %>%
      group_by(movieId, title) %>%
      summarise(archetype_score = mean(archetype_score), .groups = "drop") %>%
      arrange(desc(archetype_score))
  } else {
    candidates <- candidates %>%
      select(movieId, title, archetype_score) %>%
      distinct() %>%
      arrange(desc(archetype_score))
  }
  
  candidates %>% slice(1:n)
}

# Identify primary genre from combination
# Primary = genre with highest mean archetype score; tiebreak alphabetically
get_primary_genre <- function(combo) {
  genre_mean_archetype %>%
    filter(target_genre %in% combo) %>%
    arrange(desc(mean_archetype), target_genre) %>%
    slice(1) %>%
    pull(target_genre)
}

# Get low personalization top pick genre via tier logic
get_low_pers_genre <- function(primary, combo) {
  tiers <- final_table %>% filter(Genre == primary)
  tier2 <- tiers$Tier_2_Target
  tier3 <- tiers$Tier_3_Fallback
  tier4 <- tiers$Tier_4_Bridge
  
  if (!tier2 %in% combo) return(tier2)
  if (!tier3 %in% combo) return(tier3)
  return(tier4)
}

# Get top scoring film for a single genre
get_top_film_for_genre <- function(g) {
  purity_candidates %>%
    filter(target_genre == g) %>%
    select(movieId, title, archetype_score) %>%
    distinct() %>%
    arrange(desc(archetype_score)) %>%
    slice(1) %>%
    pull(title)
}

# ==============================================================================
# PHASE 6: BUILD HIGH PERSONALIZATION LOOKUP TABLE
# Top Pick: highest scoring film across selected genres
# Filler 1 & 2: next two highest scoring films across selected genres
# ==============================================================================

high_pers_table <- data.frame()

for (combo in combos) {
  combo_key <- paste(sort(combo), collapse = " + ")
  top3      <- get_best_films(combo, n = 3)
  
  # MANUAL OVERRIDE 4: High personalization Romance-only selection
  # The pipeline default for Romance was less recognizable to a contemporary audience.
  # The Notebook (2004) is substituted as a more recognizable and affectively
  # coherent stimulus for Romance-only participants.
  if (length(combo) == 1 && combo == "Romance") {
    top3$title[1] <- "Notebook, The (2004)"
  }
  
  row <- data.frame(
    combo      = combo_key,
    n_selected = length(combo),
    top_pick   = ifelse(nrow(top3) >= 1, top3$title[1], NA),
    filler_1   = ifelse(nrow(top3) >= 2, top3$title[2], NA),
    filler_2   = ifelse(nrow(top3) >= 3, top3$title[3], NA),
    stringsAsFactors = FALSE
  )
  
  high_pers_table <- bind_rows(high_pers_table, row)
}

# ==============================================================================
# PHASE 7: BUILD LOW PERSONALIZATION LOOKUP TABLE
# Top Pick: tier-based mismatch derived from primary genre
# Filler 1 & 2: from high personalization table for same combination
# ==============================================================================

low_pers_table <- data.frame()

for (combo in combos) {
  combo_key <- paste(sort(combo), collapse = " + ")
  
  primary_genre     <- get_primary_genre(combo)
  low_pers_genre    <- get_low_pers_genre(primary_genre, combo)
  # MANUAL OVERRIDE 2: When adjacent genre is Romance, Top Pick = The Notebook (2004)
  # The pipeline default for Romance was less recognizable to a contemporary audience.
  # MANUAL OVERRIDE 3: When adjacent genre is Comedy, Top Pick = Forrest Gump (1994)
  # Forrest Gump's tonal proximity to the Drama and Romance genres reduces the risk
  # of an overly jarring mismatch for participants in the low personalization condition.
  low_pers_top_pick <- if (low_pers_genre == "Romance") {
    "Notebook, The (2004)"
  } else if (low_pers_genre == "Comedy") {
    "Forrest Gump (1994)"
  } else {
    get_top_film_for_genre(low_pers_genre)
  }
  
  high_row <- high_pers_table %>% filter(combo == combo_key)
  
  row <- data.frame(
    combo          = combo_key,
    n_selected     = length(combo),
    primary_genre  = primary_genre,
    top_pick_genre = low_pers_genre,
    top_pick       = low_pers_top_pick,
    filler_1       = ifelse(nrow(high_row) > 0, high_row$filler_1, NA),
    filler_2       = ifelse(nrow(high_row) > 0, high_row$filler_2, NA),
    stringsAsFactors = FALSE
  )
  
  low_pers_table <- bind_rows(low_pers_table, row)
}

# ==============================================================================
# PHASE 8: OUTPUT
# ==============================================================================

cat("\n=== HIGH PERSONALIZATION LOOKUP TABLE ===\n")
for (i in 1:nrow(high_pers_table)) {
  cat("─────────────────────────────────────────────\n")
  cat(sprintf("Selected : %s\n", high_pers_table$combo[i]))
  cat(sprintf("Top Pick : %s\n", high_pers_table$top_pick[i]))
  cat(sprintf("Filler 1 : %s\n", high_pers_table$filler_1[i]))
  cat(sprintf("Filler 2 : %s\n", high_pers_table$filler_2[i]))
}
cat("─────────────────────────────────────────────\n")

cat("\n=== LOW PERSONALIZATION LOOKUP TABLE ===\n")
for (i in 1:nrow(low_pers_table)) {
  cat("─────────────────────────────────────────────\n")
  cat(sprintf("Selected       : %s\n", low_pers_table$combo[i]))
  cat(sprintf("Primary Genre  : %s\n", low_pers_table$primary_genre[i]))
  cat(sprintf("Top Pick Genre : %s\n", low_pers_table$top_pick_genre[i]))
  cat(sprintf("Top Pick       : %s\n", low_pers_table$top_pick[i]))
  cat(sprintf("Filler 1       : %s\n", low_pers_table$filler_1[i]))
  cat(sprintf("Filler 2       : %s\n", low_pers_table$filler_2[i]))
}
cat("─────────────────────────────────────────────\n")

# Save CSVs for Lovable
write.csv(high_pers_table, "mapping/high_personalization_mapping.csv", row.names = FALSE)
write.csv(low_pers_table,  "mapping/low_personalization_mapping.csv",  row.names = FALSE)

cat("\nCSV files saved in mapping/: high_personalization_mapping.csv and low_personalization_mapping.csv\n")