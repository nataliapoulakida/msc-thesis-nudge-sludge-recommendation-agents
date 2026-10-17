# Methodology

A reference note for the thesis *When Relevance Meets Urgency in Recommendation Agents: How Choice Personalization and Delivery Framing Shape User Perceptions on the Nudge-Sludge Continuum*. Section numbers refer to the thesis.

## 1. Research question and hypotheses

**Question:** How do choice personalization and urgency-based delivery framing intensity interact to shape whether users see a recommendation as a nudge (helpful, easy to avoid, autonomy-supporting) or as sludge (manipulative, pressuring, autonomy-threatening)?

The framework follows Mills's (2022) split between *choice personalization* (what is recommended) and *delivery personalization* (how it is framed). Delivery was operationalized as one fixed "urgency package": temporal cues, visual salience and assertive language, applied to everyone rather than tailored per user.

| Hypothesis | Prediction | Result |
|---|---|---|
| H1 | Excessive urgency raises sludge perception (PNSP) vs. moderate urgency | Not supported (b = 0.186, p = .220) |
| H2 | Personalization moderates the urgency effect | Not supported (interaction p = .105; ΔR² = .014) |
| H3 | Privacy concerns moderate the urgency × personalization interaction | Not supported (three-way p = .301; ΔR² = .004) |

Because the personalization manipulation failed (section 4), H2 and H3 were not properly testable. The thesis treats everything after this point as exploratory.

## 2. Design

- **2 × 2 between-subjects online experiment:** urgency (moderate / excessive) × choice personalization (low / high). Participants were randomly assigned to one cell.
- **Measured moderator:** general privacy concerns.
- **Outcome:** Perceived Nudge-Sludge Position (PNSP), a 7-point bipolar scale where higher means more sludge-like.
- **Cell sizes:** 68 / 69 / 65 / 76 (N = 278).

## 3. Stimulus: a realistic prototype

I built a fictional streaming platform ("StreamVibe"), designed in Figma, with recommendation logic implemented in Lovable. The scenario asked participants to imagine a Friday-night movie search.

1. **Preference elicitation.** Participants picked up to three of nine genres. This created a believable reason for the platform to "know" them. There were 129 possible genre combinations.
2. **Recommendation.** Three films were shown, with one marked "Top Pick". Only the Top Pick was interactive, so all attention went to a single stimulus.
3. **Delivery framing.**
   - *Moderate urgency:* a plain note that the title leaves the library in 24 hours.
   - *Excessive urgency:* a red "ACT FAST" banner and a live countdown timer.

**Recommendation logic (deterministic, built on MovieLens 25M):**
- For every film in the nine target genres, an *archetype score* = 0.7 × normalized genre purity + 0.3 × normalized (log) popularity. Purity comes from MovieLens genome relevance scores. Popularity is the number of ratings. The 70/30 weighting favours films that are clearly typical of their genre while staying recognisable.
- **High personalization:** the three highest-scoring films across the participant's chosen genres, with the best one as Top Pick.
- **Low personalization:** the other two films stay well matched (so the platform still looks competent), but the Top Pick is swapped for a film from a thematically adjacent genre cluster. This was meant to be a plausible miss, not an absurd one.
- A few manual overrides were applied for recognisability. These are listed in thesis section 3.3.1.

## 4. Measures

All items are 7-point scales. "Adapted" means wording was changed to fit the recommendation-agent context.

| Construct | Role | Items | Source | Reliability / notes |
|---|---|---|---|---|
| Perceived nudge-sludge position (PNSP) | Outcome | 9 → 7 | Developed for this study | α = .87 (7 items), McDonald's ωt = .90; 3-factor structure; items PNSP6 and PNSP7 dropped |
| Perceived urgency | Manipulation check | 3 | Developed for this study | α = .68 (marginal; one item captures deadline rather than time pressure; retained) |
| Perceived personalization | Manipulation check | 3 | Adapted from Dijkstra (2005), via Aguirre et al. (2015) | α = .80 |
| Perceived system incompetence | Diagnostic / mediator | 3 | Developed for this study, grounded in Knijnenburg et al. (2012) | α = .78 |
| Perceived strategic intent | Diagnostic / mediator | 3 → 2 | Adapted from Campbell (1995) and Cotte et al. (2005), plus one new item | Original α = .73; SI2 dropped (it measured benevolence, not manipulation); final inter-item r = .735 |
| Privacy concerns | Moderator | 4 | Malhotra et al. (2004) | α = .74; single-factor RMSEA = .156 (modest strain) |
| Streaming frequency, age band, gender | Descriptives | 3 | n/a | Categorical |

An attention-check item ("If you are reading this, select Agree") was included in the survey.

## 5. Sample and procedure

- **Recruitment:** Prolific. Requirements were being over 18 and able to read English. The survey ran in Qualtrics.
- **Power analysis:** for multiple linear regression (f² = .03, power .80, α = .05), 264 valid responses were needed. I recruited above that to absorb exclusions.
- **Exclusions:** 284 recruited. Four failed the attention check and three finished in under 120 seconds (one overlapped), so six were removed, leaving **N = 278**. Longstring and intra-individual response variability screens flagged no one further.
- **Common method bias:** Harman's single-factor test explained 30.6% of variance, below the 50% threshold.
- **Sample:** 60.1% male, 38.8% female; 71.6% under 35; 84.2% stream several times a week. Privacy concerns were high (M = 5.55, SD = 1.01) and balanced across cells.
- **Flow:** introduction and scenario → prototype interaction (random cell) → evaluation questionnaire → demographics.

## 6. Analysis plan (R 4.5.3)

| Step | Method |
|---|---|
| Scale validation | Cronbach's α, corrected item-total correlations, EFA (ML, oblimin), parallel analysis, McDonald's ω |
| Manipulation checks | Independent-samples t-tests (Welch where Levene's was significant), Cohen's d |
| Confirmatory tests | Three-step hierarchical OLS regression (main effects → two-way → three-way), mean-centred privacy concerns |
| Assumptions | Shapiro-Wilk, Breusch-Pagan, VIF, Q-Q plots |
| Exploratory models | Same regression on *perceived* urgency and personalization; attribution regression; path models in `lavaan` |
| Indirect effects | 1,000 bootstrap samples, bias-corrected and accelerated CIs (Preacher & Hayes, 2008); fixed seed |
| Robustness | HC3 robust standard errors where assumptions were violated |
| Fit reporting | CFI and SRMR for the small-df mediation model (pre-specified). RMSEA and TLI were not interpreted, as they behave poorly with few degrees of freedom |

## 7. What failed, and how it was handled

- **The personalization manipulation did not separate the groups.** Perceived personalization: high M = 4.71 vs low M = 4.48, Welch t(261.4) = −1.37, p = .173, d = −0.17. The urgency manipulation worked: M = 4.62 vs 3.76, t(276) = −5.28, d = −0.63.
- **Response:** I kept the confirmatory results as reported and ran clearly labelled exploratory analyses on participants' continuous perceptions. The exploratory model explains far more variance (R² = .371) than the categorical one (R² = .025). That gap is itself a finding: what users perceive matters more than what the system objectively did.
- **Scale trimming:** items were removed only on pre-set statistical thresholds (corrected item-total r ≥ .30, EFA loading ≥ .40) plus a check that the removal made conceptual sense. Each removal is reported.

## 8. Limitations

1. Exploratory results cannot support causal claims, and all measures came from a single session.
2. The "urgency package" was uniform, not truly personalized delivery.
3. One domain (movies), where urgency is easy to justify. Findings may not carry over to e-commerce or finance.
4. The sample skews male, young, digitally literate and privacy-conscious, and the high privacy concern may inflate strategic-intent attributions.
5. The strategic-intent scale has only two items, and the privacy scale shows some single-factor strain.

## References (selection)

Aguirre et al. (2015); Campbell (1995); Cotte et al. (2005); Dijkstra (2005); Harper & Konstan (2015), *The MovieLens datasets*; Knijnenburg et al. (2012); Malhotra et al. (2004); Mills (2022); Preacher & Hayes (2008); Thaler (2018), "Nudge, not sludge"; Thaler, Sunstein & Balz (2013). The full list is in the thesis.
