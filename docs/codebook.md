# Codebook

Variables and scoring rules used in `analysis/analysis.R`. The data itself is not published (see `data/README.md`).

## Experimental conditions

`Condition` is recorded by the survey flow (randomly assigned).

| Condition | Urgency | Personalization | Derived `urgency` / `person` |
|---|---|---|---|
| 1 | Moderate | Low | Low / Low |
| 2 | Moderate | High | Low / High |
| 3 | Excessive | Low | High / Low |
| 4 | Excessive | High | High / High |

Dummy codes: `urgency_d` (1 = excessive), `person_d` (1 = high).

## Raw items

All items are on a 7-point scale. Agreement items run from "Strongly disagree" (1) to "Strongly agree" (7). The script recodes the text labels to numbers.

| Variable | Construct | Wording or anchors | Reverse-scored? |
|---|---|---|---|
| `PNSP1` | Nudge-sludge position | Autonomy preserving ↔ Pressuring | No |
| `PNSP2` | | Provides options ↔ Limits my choices | No |
| `PNSP3` | | Tries to control me ↔ Respects my freedom | Yes |
| `PNSP4` | | Acceptable ↔ Manipulative | No |
| `PNSP5` | | Transparent ↔ Deceptive | No |
| `PNSP6` | | Self-serving ↔ Well-intentioned | Yes (dropped in validation) |
| `PNSP7` | | Hard to ignore ↔ Easy to ignore | Yes (dropped in validation) |
| `PNSP8` | | Low pressure ↔ High pressure | No |
| `PNSP9` | | Dismissible ↔ Coercive | No |
| `URG1–3` | Perceived urgency (manipulation check) | Time pressure; "did not feel rushed" (`URG2`); clear, strict deadline | `URG2` |
| `PER1–3` | Perceived personalization (manipulation check) | Directed to me personally; "did not take into account my preferences" (`PER2`); recognise my preferences | `PER2` |
| `PSI1–3` | Perceived system incompetence | Platform lacked information; platform understands what I want (`PSI2`); recommender does not work well | `PSI2` |
| `SI1–3` | Perceived strategic intent | Felt like manipulation; platform prioritised my interests over its own (`SI2`); tried to control my decision | `SI2` (dropped in validation) |
| `PC1–4` | Privacy concerns (Malhotra et al., 2004) | General online privacy concern items | No |
| `ATTN` | Attention check | "If you are reading this, select 'Agree'" | n/a |
| `streaming_freq`, `age`, `gender` | Descriptives | Categorical (age in bands, 18–24 to 65+) | n/a |

Reverse scoring: `8 − x`.

## Exclusion rules (applied in this order)

1. Failed attention check (`ATTN` ≠ "Agree").
2. Completion time under 120 seconds.
3. Careless-response screen: `longstring` > 12 or intra-individual response variability (`irv`) < 0.5. This removed nobody.

Result: 284 → 278 participants.

## Composite scores

| Variable | Items averaged | Notes |
|---|---|---|
| `PNSP` | PNSP1, 2, 3r, 4, 5, 8, 9 | Outcome; higher = more sludge-like |
| `PNSP_legitimacy` | PNSP2, 3r, 4, 5 | Subscale (α = .86) |
| `PNSP_avoidability` | PNSP1, 8, 9 | Subscale (α = .72) |
| `urgency_mc` | URG1, URG2r, URG3 | Perceived urgency |
| `person_mc` | PER1, PER2r, PER3 | Perceived personalization |
| `PSI_score` | PSI1, PSI2r, PSI3 | System incompetence |
| `SI_score` | SI1, SI3 | Strategic intent (two items) |
| `privacy_concerns` | PC1–PC4 | Moderator; mean-centred as `privacy_c` |

Continuous-model predictors are mean-centred (`urgency_mc_c`, `person_mc_c`), and interaction terms are products of the centred variables.
