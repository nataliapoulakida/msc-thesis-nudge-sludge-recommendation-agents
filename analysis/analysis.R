#' ---
#' title: |
#'   Natalia Poulakida
#'
#'   When Relevance Meets Urgency in Recommendation Agents: How Choice
#'   Personalization and Delivery Framing Shape User Perceptions on the
#'   Nudge-Sludge Continuum
#'
#'   Data Analysis Output
#' author: ""
#' ---

# ------------------------------------------------------------------------------
# Analysis script for the MSc thesis "When Relevance Meets Urgency in
# Recommendation Agents" (Rotterdam School of Management, 2026).
#
# Run from the repository root. The raw Qualtrics export is NOT included in this
# repository (participant anonymity). To re-run, place your own export at
# data/qualtrics_export.csv with the same structure (see docs/codebook.md).
# Section numbers (4.1 - 4.5) match the thesis chapters.
# R 4.5.3. Bootstrap seeds are fixed (set.seed(123)).
# ------------------------------------------------------------------------------

options(warn = -1)
knitr::opts_chunk$set(warning = FALSE, message = FALSE)

# Load required packages
rm(list = ls())

packages <- c("tidyverse", "psych", "car", "effectsize", "performance", 
              "careless", "mediation", "ggplot2", "patchwork", "lavaan", "see", 
              "lmtest", "sandwich")

missing_pkgs <- setdiff(packages, rownames(installed.packages()))
if (length(missing_pkgs) > 0) {
  stop("Please install missing packages first: install.packages(c(",
       paste0('"', missing_pkgs, '"', collapse = ", "), "))")
}
suppressPackageStartupMessages({
  library(tidyverse)
  library(psych)
  library(car)
  library(effectsize)
  library(performance)
  library(careless)
  library(mediation)
  library(ggplot2)
  library(patchwork)
  library(lavaan)
  library(see)
  library(lmtest)
  library(sandwich)
})

# ==============================================================================
# 4.1 Data Preparation and Sample Characteristics
# ==============================================================================

# Load Data
df_raw <- read.csv("data/qualtrics_export.csv", skip = 1)
df_raw <- df_raw[-1, ] # Remove Qualtrics metadata row
df_raw <- df_raw %>% filter(Response.Type == "IP Address") # Remove previews
df_raw <- df_raw %>% filter(as.Date(Start.Date) >= as.Date("2026-05-13"))

# Rename Columns
df_raw <- df_raw %>% rename(
  response_id    = Response.ID,
  duration       = Duration..in.seconds.,
  
  PNSP1 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Autonomy.preserving.Pressuring,
  PNSP2 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Provides.options.Limits.my.choices,
  PNSP3 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Tries.to.control.me.Respects.my.freedom,
  PNSP4 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Acceptable.Manipulative,
  PNSP5 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Transparent.Deceptive,
  PNSP6 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Self.serving.Well.intentioned,
  PNSP7 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Hard.to.ignore.Easy.to.ignore,
  PNSP8 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Low.pressure.High.pressure,
  PNSP9 = Please.evaluate.the..Top.Pick..recommendation.you.received.based.on.the.following.pairs....Dismissible.Coercive,
  
  URG1 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.recommendation.created.a.sense.of.time.pressure.,
  URG2 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....I.did.not.feel.rushed.to.make.a.decision.,
  URG3 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....I.perceived.a.clear.and.strict.deadline.for.when.the.recommended.movie.would.no.longer.be.available.,
  
  PER1 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.recommendation.was.directed.to.me.personally.,
  PER2 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.recommendation.did.not.take.into.account.my.personal.preferences.,
  PER3 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....I.recognize.my.personal.preferences.in.the.recommendation.,
  
  ATTN = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....If.you.are.reading.this..select..Agree..,
  
  PSI1 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.platform.did.not.have.enough.information.about.my.preferences.to.make.an.accurate.recommendation.,
  PSI2 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.platform.understands.what.I.am.looking.for.,
  PSI3 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.platform.s.recommendation.system.does.not.work.very.well.,
  
  SI1 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.way.the.recommendation.was.presented.felt.like.it.was.trying.to.manipulate.me.,
  SI2 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....I.believe.the.platform.prioritized.providing.me.with.a.relevant.recommendation.over.its.own.interests.,
  SI3 = Please.indicate.your.level.of.agreement.with.the.following.statements..keeping.in.mind.your.experience.with.the..Top.Pick..recommendation.you.received....The.platform.seemed.to.be.trying.to.inappropriately.manage.or.control.my.decision.,
  
  PC1 = Please.indicate.your.level.of.agreement.with.the.following.statements.regarding.your.general.views.on.online.privacy.and.data.collection....It.usually.bothers.me.when.online.companies.ask.me.for.personal.information.,
  PC2 = Please.indicate.your.level.of.agreement.with.the.following.statements.regarding.your.general.views.on.online.privacy.and.data.collection....Compared.to.other.subjects.on.my.mind..personal.privacy.is.very.important.,
  PC3 = Please.indicate.your.level.of.agreement.with.the.following.statements.regarding.your.general.views.on.online.privacy.and.data.collection....I.m.concerned.that.online.companies.are.collecting.too.much.personal.information.about.me.,
  PC4 = Please.indicate.your.level.of.agreement.with.the.following.statements.regarding.your.general.views.on.online.privacy.and.data.collection....Companies.should.never.sell.the.personal.information.in.their.computer.databases.to.other.companies.,
  
  age = Age.,
  gender = Gender.,
  streaming_freq = How.often.do.you.use.movie.streaming.platforms..Netflix..Disney...etc...
)

# 4.1.1 Data Cleaning & Exclusions
df_raw$duration <- as.numeric(df_raw$duration)

attn_fail <- df_raw$ATTN != "Agree"
fast <- df_raw$duration < 120
exclude <- attn_fail | fast

cat("Attention check failures:", sum(attn_fail), "\n")
cat("Too fast (<120s):", sum(fast), "\n")
cat("Flagged for both:", sum(attn_fail & fast), "\n")
cat("Total excluded:", sum(exclude), "\n")
cat("Remaining N:", nrow(df_raw) - sum(exclude), "\n")

df <- df_raw %>% filter(!exclude)

# Recode Likert Scales
likert_map <- c("Strongly agree"=7, "Agree"=6, "Somewhat agree"=5, 
                "Neither agree nor disagree"=4, "Somewhat disagree"=3, 
                "Disagree"=2, "Strongly disagree"=1)
recode_likert <- function(x) as.numeric(likert_map[x])

pnsp_raw_cols <- c("PNSP1","PNSP2","PNSP3","PNSP4","PNSP5",
                   "PNSP6","PNSP7","PNSP8","PNSP9")
df[pnsp_raw_cols] <- lapply(df[pnsp_raw_cols], function(x) 
  as.numeric(as.character(x)))

other_cols <- c("URG1","URG2","URG3","PER1","PER2","PER3",
                "PSI1","PSI2","PSI3","SI1","SI2","SI3",
                "PC1","PC2","PC3","PC4")
df[other_cols] <- lapply(df[other_cols], recode_likert)

# Reverse Scoring
df$URG2r <- 8 - df$URG2
df$PER2r <- 8 - df$PER2
df$PSI2r <- 8 - df$PSI2
df$SI2r <- 8 - df$SI2
df$PNSP3r <- 8 - df$PNSP3
df$PNSP6r <- 8 - df$PNSP6
df$PNSP7r <- 8 - df$PNSP7


# Careless Response Screening
likert_items <- df[, c("URG1","URG2r","URG3", "PER1","PER2r","PER3",
                       "PSI1","PSI2r","PSI3", "SI1","SI2r","SI3",
                       "PC1","PC2","PC3","PC4")]
df$longstring <- longstring(likert_items)
df$irv <- irv(likert_items)
df$careless_flag <- df$longstring > 12 | df$irv < 0.5
df <- df %>% filter(careless_flag == FALSE)
cat("Final valid N after careless screening:", nrow(df), "\n")

# Common Method Bias (Harman's single factor)
all_items <- df[, c("PNSP1","PNSP2","PNSP3r","PNSP4","PNSP5","PNSP6r",
                    "PNSP7r","PNSP8","PNSP9",
                    "URG1","URG2r","URG3", "PER1","PER2r","PER3",
                    "PSI1","PSI2r","PSI3", "SI1","SI2r","SI3",
                    "PC1","PC2","PC3","PC4")]
harman <- fa(all_items, nfactors=1, rotate="none", fm="ml")
cat("Harman Single-Factor Variance:", round(harman$Vaccounted[2,1] * 100, 2), 
    "%\n")

# 4.1.2 Sample Characteristics
# Create Composites
df$urgency_mc <- rowMeans(df[,c("URG1","URG2r","URG3")], na.rm=TRUE)
df$person_mc <- rowMeans(df[,c("PER1","PER2r","PER3")], na.rm=TRUE)
df$PSI_score <- rowMeans(df[,c("PSI1","PSI2r","PSI3")], na.rm=TRUE)
df$privacy_concerns <- rowMeans(df[,c("PC1","PC2","PC3","PC4")], na.rm=TRUE)
# SI: SI2r removed following item-level validation 
# (see section 4.2.1 for item-level validation justification)
df$SI_score <- rowMeans(df[, c("SI1","SI3")], na.rm=TRUE)

# PNSP: Final 7-item composite and subscales 
# PNSP6 and PNSP7 removed following item-level validation 
# (see section 4.2.2 for item-level validation justification)
df$PNSP <- rowMeans(df[,c("PNSP1","PNSP2","PNSP3r","PNSP4","PNSP5",
                          "PNSP8","PNSP9")], na.rm=TRUE)
df$PNSP_legitimacy <- rowMeans(df[,c("PNSP2","PNSP3r","PNSP4","PNSP5")], 
                               na.rm=TRUE)
df$PNSP_avoidability <- rowMeans(df[,c("PNSP1","PNSP8","PNSP9")], na.rm=TRUE)

# Categorical Conditions
df$Condition <- as.factor(df$Condition)
df$urgency <- factor(ifelse(df$Condition %in% c(3,4), "High", "Low"), 
                     levels=c("Low","High"))
df$person <- factor(ifelse(df$Condition %in% c(2,4), "High", "Low"), 
                    levels=c("Low","High"))

# Demographics
cat("\n=== DEMOGRAPHICS PER CONDITION ===\n")
table(df$Condition)
print(table(df$gender, df$Condition))
round(prop.table(table(df$gender, df$Condition), margin = 2)* 100, 1)
print(table(df$age, df$Condition))
round(prop.table(table(df$age, df$Condition), margin = 2)* 100, 1)
print(table(df$streaming_freq, df$Condition))
round(prop.table(table(df$streaming_freq, df$Condition), margin = 2)* 100, 1)

round(tapply(df$privacy_concerns, df$Condition, mean, na.rm = TRUE), 2)
round(tapply(df$privacy_concerns, df$Condition, sd, na.rm = TRUE), 2)

cat("\n=== DEMOGRAPHICS (TOTAL) ===\n")
print(table(df$gender))
round(prop.table(table(df$gender)) * 100, 1)
print(table(df$age))
round(prop.table(table(df$age)) * 100, 1)
print(table(df$streaming_freq))
round(prop.table(table(df$streaming_freq)) * 100, 1)

cat("Mean Baseline Privacy Concerns:", mean(df$privacy_concerns, na.rm=TRUE), 
    "(SD:", sd(df$privacy_concerns, na.rm=TRUE), ")\n")

# Appendix E: Descriptive Statistics and Bivariate Correlations
cat("\n=== Appendix E: Descriptive Statistics and Bivariate Correlations ===\n")
desc_vars <- df[, c("PNSP", "urgency_mc", "person_mc", 
                    "PSI_score", "SI_score", "privacy_concerns")]

desc_stats <- data.frame(
  Variable = c("PNSP", "Perceived Urgency", "Perceived Personalization",
               "System Incompetence", "Strategic Intent", "Privacy Concerns"),
  M  = round(colMeans(desc_vars, na.rm=TRUE), 2),
  SD = round(apply(desc_vars, 2, sd, na.rm=TRUE), 2)
)
print(desc_stats)

cat("\nCorrelation Matrix:\n")
cor_matrix <- round(cor(desc_vars, use="complete.obs"), 3)
print(cor_matrix)
cor_test_matrix <- psych::corr.test(desc_vars, use="complete")
print(cor_test_matrix$p, digits=3)

# ==============================================================================
# 4.2 Scale Validation
# ==============================================================================

# 4.2.1 Reliability of Scales
# CHOICE PERSONALIZATION
cat("\n=== CHOICE PERSONALIZATION ===\n")
cat("Alpha:", alpha(df[,c("PER1","PER2r","PER3")])$total$raw_alpha, "\n")
cat("Item-total correlations:\n")
print(alpha(df[,c("PER1","PER2r","PER3")])$item.stats[, c("r.cor","r.drop")])
efa_per <- fa(df[,c("PER1","PER2r","PER3")], nfactors=1, rotate="oblimin", 
              fm="ml")
print(efa_per$loadings)

# SYSTEM INCOMPETENCE
cat("\n=== SYSTEM INCOMPETENCE ===\n")
cat("Alpha:", alpha(df[,c("PSI1","PSI2r","PSI3")])$total$raw_alpha, "\n")
cat("Item-total correlations:\n")
print(alpha(df[,c("PSI1","PSI2r","PSI3")])$item.stats[, c("r.cor","r.drop")])
efa_psi <- fa(df[,c("PSI1","PSI2r","PSI3")], nfactors=1, rotate="oblimin", 
              fm="ml")
print(efa_psi$loadings)

# STRATEGIC INTENT
cat("\n=== STRATEGIC INTENT ===\n")
cat("Alpha (3-item):", 
    alpha(df[,c("SI1","SI2r","SI3")])$total$raw_alpha, "\n")
cat("Item-total correlations:\n")
print(alpha(df[,c("SI1","SI2r","SI3")])$item.stats[, c("r.cor","r.drop")])
efa_si <- fa(df[,c("SI1","SI2r","SI3")], nfactors=1, rotate="oblimin", fm="ml")
print(efa_si$loadings)
cat("Final SI scale (SI1 + SI3)\n")
cat("Inter-item correlation:", 
    round(cor(df$SI1, df$SI3, use="complete.obs"), 3), "\n")

# URGENCY
cat("\n=== URGENCY ===\n")
cat("Alpha:", alpha(df[,c("URG1","URG2r","URG3")])$total$raw_alpha, "\n")
cat("Item-total correlations:\n")
print(alpha(df[,c("URG1","URG2r","URG3")])$item.stats[, c("r.cor","r.drop")])
efa_urg <- fa(df[,c("URG1","URG2r","URG3")], nfactors=1, rotate="oblimin", 
              fm="ml")
print(efa_urg$loadings)

# PRIVACY CONCERNS
cat("\n=== PRIVACY CONCERNS ===\n")
cat("Alpha:", alpha(df[,c("PC1","PC2","PC3","PC4")])$total$raw_alpha, "\n")
cat("Item-total correlations:\n")
print(alpha(df[,c("PC1","PC2","PC3","PC4")])$item.stats[, c("r.cor","r.drop")])
efa_pc <- fa(df[,c("PC1","PC2","PC3","PC4")], nfactors=1, rotate="oblimin", 
             fm="ml")
print(efa_pc$loadings)
cat("RMSEA:", efa_pc$RMSEA[1], "\n")


# 4.2.2 PNSP Scale Validation
cat("\n=== 4.2.2 PNSP SCALE VALIDATION ===\n")
# Step 1: Nine-item
pnsp_items_9 <- df[, c("PNSP1","PNSP2","PNSP3r","PNSP4","PNSP5",
                       "PNSP6r","PNSP7r","PNSP8","PNSP9")]
cat("PNSP (9 items) Cronbach's alpha:", 
    alpha(pnsp_items_9)$total$raw_alpha, "\n")
cat("Item-total correlations (9 items):\n")
print(alpha(pnsp_items_9)$item.stats[, c("r.cor","r.drop")])
efa_pnsp9 <- fa(pnsp_items_9, nfactors=3, rotate="oblimin", fm="ml")
cat("EFA loadings (9 items):\n")
print(efa_pnsp9$loadings)

# Step 2: Eight-item scale after removing PNSP7
pnsp_items_8 <- df[, c("PNSP1","PNSP2","PNSP3r","PNSP4","PNSP5",
                       "PNSP6r","PNSP8","PNSP9")]
cat("PNSP (8 items) Cronbach's alpha:", 
    alpha(pnsp_items_8)$total$raw_alpha, "\n")
efa_pnsp8 <- fa(pnsp_items_8, nfactors=3, rotate="oblimin", fm="ml")
cat("EFA loadings (8 items):\n")
print(efa_pnsp8$loadings)

# Step 3: Final seven-item scale after removing PNSP6
pnsp_items_final <- df[, c("PNSP1","PNSP2","PNSP3r","PNSP4","PNSP5",
                           "PNSP8","PNSP9")]
cat("PNSP (7 items) Cronbach's alpha:", 
    alpha(pnsp_items_final)$total$raw_alpha, "\n")
fa.parallel(pnsp_items_final, fm="ml", fa="fa")
efa_pnsp7 <- fa(pnsp_items_final, nfactors=3, rotate="oblimin", fm="ml")
cat("EFA RMSEA:", efa_pnsp7$RMSEA[1], " | TLI:", efa_pnsp7$TLI, "\n")
print(efa_pnsp7$loadings)
print(efa_pnsp7$Vaccounted)
print(efa_pnsp7$Phi)
omega(pnsp_items_final, nfactors=3, plot=FALSE)

# Subscales alpha
cat("Manipulative influence subscale alpha:", 
    alpha(df[,c("PNSP2","PNSP3r","PNSP4","PNSP5")])$total$raw_alpha, "\n")
cat("Ease of avoidance subscale alpha:", 
    alpha(df[,c("PNSP1","PNSP8","PNSP9")])$total$raw_alpha, "\n")


# ==============================================================================
# 4.3 Manipulation Checks
# ==============================================================================

# 4.3.1 Urgency Manipulation Check
cat("\n=== 4.3.1 URGENCY MANIPULATION CHECK ===\n")
print(t.test(urgency_mc ~ urgency, data=df, var.equal=TRUE))
tapply(df$urgency_mc, df$urgency, sd, na.rm=TRUE)
cat("Cohen's d:", cohens_d(urgency_mc ~ urgency, data=df)$Cohens_d, "\n")

# 4.3.2 Personalization Manipulation Check
cat("\n=== 4.3.2 PERSONALIZATION MANIPULATION CHECK ===\n")
print(t.test(person_mc ~ person, data=df, var.equal=TRUE))
tapply(df$person_mc, df$person, sd, na.rm=TRUE)
cat("Cohen's d:", cohens_d(person_mc ~ person, data=df)$Cohens_d, "\n")

#Manipulation Check t-tests

cat("\n=== LEVENE'S TEST: MANIPULATION CHECK T-TESTS ===\n")
cat("Urgency manipulation check:\n")
print(leveneTest(urgency_mc ~ urgency, data=df))
cat("Personalization manipulation check:\n")
print(leveneTest(person_mc ~ person, data=df))

# Personalization: Levene's significant -> switch to Welch's
cat("\n=== PERSONALIZATION MANIPULATION CHECK (Welch's t-test) ===\n")
print(t.test(person_mc ~ person, data=df))
tapply(df$person_mc, df$person, sd, na.rm=TRUE)
cat("Cohen's d:", cohens_d(person_mc ~ person, data=df)$Cohens_d, "\n")


# ==============================================================================
# 4.4 Confirmatory Hypotheses Check
# ==============================================================================

# Dummy Coding & Mean Centering
df$urgency_d <- ifelse(df$urgency == "High", 1, 0)
df$person_d <- ifelse(df$person  == "High", 1, 0)
df$privacy_c <- as.numeric(scale(df$privacy_concerns, center=TRUE, scale=FALSE))

# Interaction Terms
df$urgency_x_person <- df$urgency_d * df$person_d
df$urgency_x_privacy_c <- df$urgency_d * df$privacy_c
df$person_x_privacy_c <- df$person_d  * df$privacy_c
df$three_way_c <- df$urgency_d * df$person_d * df$privacy_c

model_r1 <- lm(PNSP ~ urgency_d + person_d + privacy_c, data=df) # step 1
model_r2 <- lm(PNSP ~ urgency_d + person_d + privacy_c + 
                 urgency_x_person + urgency_x_privacy_c + person_x_privacy_c, 
               data=df) # step 2
model_r3 <- lm(PNSP ~ urgency_d + person_d + privacy_c + 
                 urgency_x_person + urgency_x_privacy_c + person_x_privacy_c + 
                 three_way_c, data=df) # step 3

print(summary(model_r1))
print(summary(model_r2))
print(anova(model_r1, model_r2))
print(summary(model_r3))
print(anova(model_r2, model_r3))


# Confirmatory Analysis - Assumption Checks
sw <- shapiro.test(residuals(model_r3))
bp <- ncvTest(model_r3)
check_model(model_r3)
cat("Assumption Check - Shapiro-Wilk W =", round(sw$statistic,4), 
    ", p =", round(sw$p.value,4), "\n")
cat("Assumption Check - Breusch-Pagan Chisq =", round(bp$ChiSquare,4), 
    ", p =", round(bp$p,4), "\n")
cat("VIF - Confirmatory Model:\n")
print(vif(model_r3))


# ==============================================================================
# 4.5 Exploratory Analysis
# ==============================================================================

# 4.5.1 Cell Variations & Subscale Analysis
model_leg <- lm(PNSP_legitimacy ~ urgency_d + person_d + privacy_c +
                  urgency_x_person + urgency_x_privacy_c +
                  person_x_privacy_c + three_way_c, data=df)
model_avo <- lm(PNSP_avoidability ~ urgency_d + person_d + privacy_c +
                  urgency_x_person + urgency_x_privacy_c +
                  person_x_privacy_c + three_way_c, data=df)
print(summary(model_leg))
print(summary(model_avo))

anova_model <- aov(PNSP ~ Condition, data=df)
print(summary(anova_model))
eta_squared(anova_model)
print(TukeyHSD(anova_model))
tapply(df$PNSP, df$Condition, mean, na.rm=TRUE)
tapply(df$PNSP, df$Condition, sd, na.rm=TRUE)

# (4.5.1) Subscale Regressions - Assumption Checks | One-Way Anova

print(leveneTest(PNSP ~ Condition, data=df))

#Manipulative Influence subscale
sw_leg <- shapiro.test(residuals(model_leg))
bp_leg <- ncvTest(model_leg)
cat("Shapiro-Wilk W =", round(sw_leg$statistic,4), ", p =", 
    round(sw_leg$p.value,4), "\n")
cat("Breusch-Pagan Chisq =", round(bp_leg$ChiSquare,4), ", p =", 
    round(bp_leg$p,4), "\n")
cat("VIF:\n"); print(vif(model_leg))
qqnorm(residuals(model_leg), main="Q-Q Plot: Manipulative Influence Subscale")
qqline(residuals(model_leg), col="red")

# Ease of Avoidance subscale
sw_avo <- shapiro.test(residuals(model_avo))
bp_avo <- ncvTest(model_avo)
cat("Shapiro-Wilk W =", round(sw_avo$statistic,4), ", p =", 
    round(sw_avo$p.value,4), "\n")
cat("Breusch-Pagan Chisq =", round(bp_avo$ChiSquare,4), ", p =", 
    round(bp_avo$p,4), "\n")
cat("VIF:\n"); print(vif(model_avo))


# 4.5.2 Continuous Perceptual Model
df$person_mc_c  <- as.numeric(scale(df$person_mc,  center=TRUE, scale=FALSE))
df$urgency_mc_c <- as.numeric(scale(df$urgency_mc, center=TRUE, scale=FALSE))

df$urg_mc_x_per_mc <- df$urgency_mc_c * df$person_mc_c
df$urg_mc_x_privacy <- df$urgency_mc_c * df$privacy_c
df$per_mc_x_privacy <- df$person_mc_c  * df$privacy_c
df$three_way_continuous <- df$urgency_mc_c * df$person_mc_c * df$privacy_c

model_c1 <- lm(PNSP ~ urgency_mc_c + person_mc_c + privacy_c, data=df)
model_c2 <- lm(PNSP ~ urgency_mc_c + person_mc_c + privacy_c + 
                 urg_mc_x_per_mc + urg_mc_x_privacy + per_mc_x_privacy, data=df)
model_c3 <- lm(PNSP ~ urgency_mc_c + person_mc_c + privacy_c + 
                 urg_mc_x_per_mc + urg_mc_x_privacy + per_mc_x_privacy + 
                 three_way_continuous, data=df)

print(summary(model_c1))
print(summary(model_c2))
print(anova(model_c1, model_c2))
print(summary(model_c3))
print(anova(model_c2, model_c3))


# Continuous Model - Assumptions check
check_model(model_c3)
cat("VIF - Continuous Model:\n")
print(vif(model_c3))
sw_c3 <- shapiro.test(residuals(model_c3))
bp_c3 <- ncvTest(model_c3)
cat("Assumption Check (Continuous) - Shapiro-Wilk W =", 
    round(sw_c3$statistic,4), 
    ", p =", round(sw_c3$p.value,4), "\n")
cat("Assumption Check (Continuous) - Breusch-Pagan Chisq =", 
    round(bp_c3$ChiSquare,4), 
    ", p =", round(bp_c3$p,4), "\n")


# Figure 10: Continuous Model Plots
apa_theme <- theme_classic() +
  theme(
    plot.margin = margin(t=15, r=25, b=40, l=55),
    text = element_text(family="serif", size=12),
    axis.title.x = element_text(margin=margin(t=12), size=12, family="serif"),
    axis.title.y = element_text(margin=margin(r=12), size=12, family="serif"),
    axis.text = element_text(color="black", size=11, family="serif"),
    axis.line = element_line(color="black", linewidth=0.5),
    axis.ticks = element_line(color="black"),
    panel.grid = element_blank(),
    plot.subtitle = element_text(size=12, hjust=0.5, family="serif", 
                                 face="bold")
  )

plot_2a <- ggplot(df, aes(x=person_mc, y=PNSP)) +
  geom_jitter(alpha=0.5, color="black", shape=16, size=1, 
              width=0.15, height=0.15) +
  geom_smooth(method="lm", color="black", fill="grey70", 
              alpha=0.25, linewidth=1.2) +
  scale_x_continuous(limits=c(1,7), breaks=1:7) +
  scale_y_continuous(limits=c(1,7), breaks=1:7) +
  labs(subtitle="(a) Perceived Personalization",
       x="Perceived Personalization (1 = Low, 7 = High)",
       y="Perceived Nudge-Sludge Position\n(1 = Nudge, 7 = Sludge)") +
  annotate("text", x=1.2, y=6.8, 
           label="b = -0.367", hjust=0, size=4, 
           color="black", family="serif") +
  annotate("text", x=1.2, y=6.3, 
           label="p < .001", hjust=0, size=4, 
           color="black", family="serif") +
  apa_theme

plot_2b <- ggplot(df, aes(x=urgency_mc, y=PNSP)) +
  geom_jitter(alpha=0.5, color="black", shape=16, size=1, 
              width=0.15, height=0.15) +
  geom_smooth(method="lm", color="black", fill="grey70", 
              alpha=0.25, linewidth=1.2) +
  scale_x_continuous(limits=c(1,7), breaks=1:7) +
  scale_y_continuous(limits=c(1,7), breaks=1:7) +
  labs(subtitle="(b) Perceived Urgency",
       x="Perceived Urgency (1 = Low, 7 = High)",
       y="") +
  annotate("text", x=1.2, y=6.8, 
           label="b = 0.315", hjust=0, size=4, 
           color="black", family="serif") +
  annotate("text", x=1.2, y=6.3, 
           label="p < .001", hjust=0, size=4, 
           color="black", family="serif") +
  apa_theme

combined_plot <- plot_2a + plot_2b + 
  plot_layout(widths=c(1,1)) & 
  theme(plot.margin=margin(t=15, r=25, b=40, l=55))

ggsave("figures/figure10_perceptual_effects.png", combined_plot, 
       width=10, height=5, dpi=300, bg="white")


# 4.5.3 Perceptual Independence Check
# Model 1: Urgency -> Personalization -> PNSP
independence_model_1 <- '
  person_mc_c ~ a * urgency_mc_c
  PNSP ~ b * person_mc_c + c * urgency_mc_c
  indirect := a * b
  total := c + (a * b)
'
set.seed(123)
fit_ind_1 <- sem(independence_model_1, data=df, se="bootstrap", bootstrap=1000)
cat("Model 1: Urgency -> Personalization -> PNSP\n")
params_ind_1 <- parameterEstimates(fit_ind_1,
                                   boot.ci.type="bca.simple",
                                   level=0.95,
                                   ci=TRUE)
print(params_ind_1)

# Model 2: Personalization -> Urgency -> PNSP
independence_model_2 <- '
  urgency_mc_c ~ a * person_mc_c
  PNSP ~ b * urgency_mc_c + c * person_mc_c
  indirect := a * b
  total := c + (a * b)
'
set.seed(123)
fit_ind_2 <- sem(independence_model_2, data=df, se="bootstrap", bootstrap=1000)
cat("Model 2: Personalization -> Urgency -> PNSP\n")
params_ind_2 <- parameterEstimates(fit_ind_2,
                                   boot.ci.type="bca.simple",
                                   level=0.95,
                                   ci=TRUE)
print(params_ind_2)


# 4.5.4 Attribution Analysis: Incompetence vs Intent
model_attr <- lm(PNSP ~ PSI_score + SI_score, data=df)
print(summary(model_attr))

# Attribution regression - Assumption Checks
sw_attr <- shapiro.test(residuals(model_attr))
bp_attr <- ncvTest(model_attr)
cat("Shapiro-Wilk W =", round(sw_attr$statistic,4), ", p =", 
    round(sw_attr$p.value,4), "\n")
cat("Breusch-Pagan Chisq =", round(bp_attr$ChiSquare,4), ", p =", 
    round(bp_attr$p,4), "\n")
cat("VIF:\n"); print(vif(model_attr))
cat("\nRobust SE (HC3):\n")
print(coeftest(model_attr, vcov=vcovHC(model_attr, type="HC3")))


# 4.5.5 Attributional Pathways
cat("Correlation: Perceived Personalization ~ Perceived System Incompetence:", 
    round(cor(df$PSI_score, df$person_mc_c), 3), "\n")
cat("Correlation: Perceived Personalization ~ Perceived Strategic Intent:", 
    round(cor(df$person_mc_c, df$SI_score), 3), "\n")
cat("Correlation: Perceived Urgency ~ Perceived System Incompetence:", 
    round(cor(df$urgency_mc_c, df$PSI_score), 3), "\n")
cat("Correlation: Perceived Urgency ~ Perceived Strategic Intent:", 
    round(cor(df$urgency_mc_c, df$SI_score), 3), "\n")

model_psi_per <- lm(PSI_score ~ person_mc_c, data=df)
model_si_per <- lm(SI_score  ~ person_mc_c, data=df)
model_psi_urg <- lm(PSI_score ~ urgency_mc_c, data=df)
model_si_urg <- lm(SI_score  ~ urgency_mc_c, data=df)

print(summary(model_psi_per))
print(summary(model_si_per))
print(summary(model_psi_urg))
print(summary(model_si_urg))


#Simple Regressions - Assumption Checks
for (model_name in c("model_psi_per", "model_si_per", "model_psi_urg", 
                     "model_si_urg")) {
  model <- get(model_name)
  sw <- shapiro.test(residuals(model))
  bp <- ncvTest(model)
  cat(model_name, "— Shapiro-Wilk W =", round(sw$statistic,4),
      ", p =", round(sw$p.value,4),
      "| Breusch-Pagan Chisq =", round(bp$ChiSquare,4),
      ", p =", round(bp$p,4), "\n")
}

# Robust SE for violated models
cat("\nRobust SE (HC3) — PSI ~ Personalization:\n")
print(coeftest(model_psi_per, vcov=vcovHC(model_psi_per, type="HC3")))
qqnorm(residuals(model_psi_per), main="Q-Q Plot: PSI ~ Personalization")
qqline(residuals(model_psi_per), col="red")

cat("\nRobust SE (HC3) — SI ~ Urgency:\n")
print(coeftest(model_si_urg, vcov=vcovHC(model_si_urg, type="HC3")))
qqnorm(residuals(model_si_urg), main="Q-Q Plot: SI ~ Urgency")
qqline(residuals(model_si_urg), col="red")



# 4.5.6 Parallel Mediation Analysis
df$PSI_c <- as.numeric(scale(df$PSI_score, center=TRUE, scale=FALSE))
df$SI_c <- as.numeric(scale(df$SI_score,  center=TRUE, scale=FALSE))

parallel_model <- '
  # Mediator equations
  PSI_c ~ a1 * person_mc_c + a3 * urgency_mc_c
  SI_c  ~ a2 * person_mc_c + a4 * urgency_mc_c

  # Outcome equation
  PNSP ~ b1 * PSI_c + b2 * SI_c + c1 * person_mc_c + c2 * urgency_mc_c

  # Indirect effects
  indirect_per_PSI := a1 * b1
  indirect_per_SI  := a2 * b2
  indirect_urg_PSI := a3 * b1
  indirect_urg_SI  := a4 * b2

  # Total indirect effects
  total_indirect_per := (a1 * b1) + (a2 * b2)
  total_indirect_urg := (a3 * b1) + (a4 * b2)

  # Total effects
  total_per := c1 + (a1 * b1) + (a2 * b2)
  total_urg := c2 + (a3 * b1) + (a4 * b2)
'

set.seed(123)
fit <- sem(parallel_model, data=df, se="bootstrap", bootstrap=1000)
summary(fit, fit.measures=TRUE, ci=TRUE)
parameterEstimates(fit, boot.ci.type="bca.simple", level=0.95)

# 4.5.7 Privacy Concerns Group Comparisons
df$privacy_group <- ifelse(df$privacy_concerns >= median
                           (df$privacy_concerns, na.rm=TRUE), "High", "Low")
cat("Median privacy concerns:", median(df$privacy_concerns, na.rm=TRUE), "\n")
print(t.test(PNSP ~ privacy_group, data=df, var.equal=TRUE))
print(t.test(SI_score ~ privacy_group, data=df, var.equal=TRUE))
tapply(df$PNSP, df$privacy_group, sd, na.rm=TRUE)
tapply(df$SI_score, df$privacy_group, sd, na.rm=TRUE)
cohens_d(PNSP ~ privacy_group, data=df)
cohens_d(SI_score ~ privacy_group, data=df)

# Privacy Group t-tests
cat("\n=== LEVENE'S TEST: PRIVACY GROUP T-TESTS ===\n")
cat("PNSP by privacy group:\n")
print(leveneTest(PNSP ~ as.factor(privacy_group), data=df))
cat("SI by privacy group:\n")
print(leveneTest(SI_score ~ as.factor(privacy_group), data=df))


