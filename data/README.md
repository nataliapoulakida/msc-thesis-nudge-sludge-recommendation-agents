# Data

The data is **not included** in this repository, to protect participant anonymity. `.gitignore` blocks CSV, RData and zip files so nothing gets committed by accident.

If you want to re-run the analysis on a similar study, save a Qualtrics export (with the question-text header row, as `read.csv(skip = 1)` expects) as `data/qualtrics_export.csv`. Column structure and scoring rules are in [`docs/codebook.md`](../docs/codebook.md).

Summary statistics (means, SDs, correlations of the composite variables) are reported in the thesis and summarised in [`docs/methodology.md`](../docs/methodology.md).
