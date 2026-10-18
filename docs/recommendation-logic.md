# Recommendation logic

How the prototype ("StreamVibe") decided which three films to show each participant, and which one to mark as "Top Pick". The logic was deterministic: the same genre selection and the same experimental condition always produced the same recommendation. Section references are to the thesis (section 3.3.1 and Appendix A).

## Why this logic had to be designed

The experiment needed one clearly defined stimulus, the Top Pick, in two versions: a **well-matched** recommendation (high choice personalization) and a **poorly matched** one (low choice personalization). Three requirements shaped the design:

1. **Recognisable films.** Participants had to know what they were judging, so the films needed to be well known.
2. **A believable platform.** In the low personalization condition the rest of the interface still had to look competent. Only the Top Pick was mismatched.
3. **Full control.** Every participant in the same condition and genre selection had to see the same stimulus, so that differences in responses could be attributed to the manipulation.

## Step 1: choose the genres on offer

The nine most-rated genres in the MovieLens 25M dataset (Harper & Konstan, 2015) were identified in R, ranked by total number of ratings: Drama, Comedy, Action, Thriller, Adventure, Romance, Sci-Fi, Crime, Fantasy. Participants chose up to three, which gives **129 possible combinations** (9 single, 36 pairs and 84 triples).

Nine is the upper limit of what people can process at once (Miller, 1956), so participants had enough choice without being overloaded. Other onboarding questions (streaming frequency, preferred viewing time and device) were included as filler. They did not affect the recommendation, and made the flow look realistic and hid the study's purpose.

## Step 2: score every film

Every film in the nine genres received an **archetype score**:

```
Archetype score = 0.7 × normalized purity + 0.3 × normalized popularity
```

| Component | Definition |
|---|---|
| Normalized purity | How strongly a film is associated with a genre tag, from MovieLens genome relevance scores, min-max normalized across all candidate films and genres |
| Normalized popularity | Number of user ratings, log-transformed to compress the wide range, then min-max normalized |

The 70/30 weighting favours films that are clearly typical of their genre over films that are merely famous, while still keeping them recognisable.

## Step 3: high choice personalization (cells 2 and 4)

For each genre combination, take the **three films with the highest archetype scores across the selected genres**. A film's score for a combination is its mean archetype score over the selected genres it belongs to. The highest-scoring one is the Top Pick, and the other two are the fillers.

## Step 4: low choice personalization (cells 1 and 3)

The goal was a **plausible miss**: a platform that seems to have understood the user's general taste but not their specific interest. This was built in four parts.

**4a. Genre clusters.** Genre similarity was computed as a cosine similarity matrix from the average MovieLens genome tag profile of each genre. The nine genres fall into three clusters of thematically and tonally close genres. Cluster membership is fixed in the script, based on that similarity matrix.

| Cluster | Genres | Character |
|---|---|---|
| 1. Speculative & Escapist | Adventure, Fantasy, Sci-Fi | World-building, special effects, heroism, imaginary worlds |
| 2. Grounded & Interpersonal | Comedy, Drama, Romance | Relationships, dialogue, emotion, everyday life |
| 3. Conflict & Suspense | Action, Crime, Thriller | Tension, physical stakes, urban settings, investigation |

**4b. Primary genre.** For each of the 129 combinations, the *primary* genre is the selected genre whose films have the highest average archetype score, meaning the most reliable representative of the participant's taste. Ties are broken alphabetically.

**4c. Adjacent genre.** Each genre has a ranked list of adjacent genres to take the Top Pick from:
- *Adjacent 1:* the most similar genre in the same cluster.
- *Adjacent 2:* the second most similar in the same cluster, used if Adjacent 1 was also selected.
- *Adjacent 3:* the most similar genre outside the cluster, a last resort when the participant selected the whole cluster.

| Primary genre | Adjacent 1 | Adjacent 2 | Adjacent 3 |
|---|---|---|---|
| Adventure | Sci-Fi | Fantasy | Thriller |
| Fantasy | Adventure | Sci-Fi | Thriller |
| Sci-Fi | Adventure | Fantasy | Action |
| Comedy | Romance | Drama | Crime |
| Drama | Romance | Comedy | Fantasy |
| Romance | Drama | Comedy | Action |
| Action | Thriller | Crime | Sci-Fi |
| Crime | Action | Thriller | Comedy |
| Thriller | Action | Crime | Fantasy |

**4d. Top Pick and fillers.** The Top Pick is the highest-scoring film in the chosen adjacent genre. The two fillers are the same as in the high personalization condition, so the interface as a whole still looks competent.

## Manual overrides

Three adjustments were made by hand, each documented in the thesis:

1. **Cluster 2 adjacency.** Romance was set as the first adjacent genre for both Comedy and Drama, and Drama for Romance, where the automatic pipeline had suggested otherwise. Romance acts as a tonal bridge between the two, so the mismatches stay tonally close.
2. **Romance-only Top Pick.** *The Notebook* replaced *Romancing the Stone* as the Top Pick for a participant who selected only Romance (high condition) and for the low condition when the adjacent genre was Romance, because it is more recognisable to a contemporary audience.
3. **Comedy as adjacent genre.** The Top Pick was set to *Forrest Gump* for the low condition, because its tone sits between Drama and Romance and is less jarring than a pure comedy.

## Files in this repository

| File | Content |
|---|---|
| [`analysis/recommendation_mapping.R`](../analysis/recommendation_mapping.R) | The full pipeline: genre ranking, clustering, scoring, tier mapping and both lookup tables. It needs the MovieLens 25M dataset, which is not included |
| [`mapping/high_personalization_mapping.csv`](../mapping/high_personalization_mapping.csv) | All 129 combinations: Top Pick and two fillers (high personalization) |
| [`mapping/low_personalization_mapping.csv`](../mapping/low_personalization_mapping.csv) | All 129 combinations: primary genre, adjacent genre, Top Pick and the same two fillers (low personalization) |

Film titles follow MovieLens naming (for example "Notebook, The (2004)").

## Worked examples

| Selected genres | High: Top Pick | Low: primary → adjacent genre | Low: Top Pick |
|---|---|---|---|
| Romance | The Notebook | Romance → Drama | Good Will Hunting |
| Action | Terminator 2: Judgment Day | Action → Thriller | The Silence of the Lambs |
| Sci-Fi | The Matrix | Sci-Fi → Adventure | Raiders of the Lost Ark |
| Drama + Romance | Romancing the Stone | Romance → Comedy (Drama already selected) | Forrest Gump |
| Action + Thriller | Terminator 2: Judgment Day | Action → Crime (Thriller already selected) | The Usual Suspects |

## Reflection

- The urgency manipulation worked, but the personalization manipulation did not separate the groups (perceived alignment M = 4.71 vs 4.48, p = .173). One possible explanation, which the thesis did not test, is that a mismatch *within* a genre cluster was too subtle for participants to notice. The thesis recommends that future work use fully mismatched recommendations, or treat personalization as a continuous perceived variable from the start.
- For this reason, the exploratory analyses used participants' **perceived** personalization instead of the assigned condition (see the README).

The dataset itself is not included in this repository. It is available from [GroupLens](https://grouplens.org/datasets/movielens/25m/) under its own licence.
