#!/usr/bin/env Rscript
# =============================================================================
# Hu_YQ_2026_ChinaSciData_clean.R
# -----------------------------------------------------------------------------
# Merge the de-identified per-participant Clean CSVs under clean/ into the
# standard SPE-Database single-CSV-per-experiment layout (v2 column template),
# and emit the subj_info CSVs, codebooks, and paper/experiment JSONs
# (the five-piece set, except *_raw.csv which is exempted — no standard raw
# trial-level export is available).
#
# Source (read-only):
#   clean/Hu_2015_unpub/Exp1/Hu_2015_unpub_Exp1_<ID>_Clean.csv          (36)
#   clean/Hu_2015_unpub/Exp2/Hu_2015_unpub_Exp2_<ID>_Clean.csv          (36)
#   clean/Zhou_2023_unpub_Exp1/cleaned/Zhou_2023_unpub_Exp1_<ID>_Clean.csv (26)
# Target: this study folder (Exp1/Exp2/Exp3).
#
# Experiment numbering:  Exp1 = Hu 2015 Task1 (classic association),
#   Exp2 = Hu 2015 Task2 (emotion association), Exp3 = Zhou 2023 Exp1.
# subj_Group split:      Hu -> control (BDI<10) / depression (BDI>=21);
#                        Zhou -> matching-first (Group=1) / nonmatching-first (Group=2).
# Converted from the earlier Python implementation on 2026-09-25.
# =============================================================================
suppressMessages({
  library(data.table)
  library(openxlsx)
  library(jsonlite)
})

# --- resolve paths (self-contained; do not rely on cwd) --------------------
args <- commandArgs(FALSE)
fl   <- sub("^--file=", "", args[grep("^--file=", args)])
if (!length(fl)) fl <- "Hu_YQ_2026_ChinaSciData_clean.R"
study_dir <- normalizePath(dirname(fl))
repo      <- normalizePath(file.path(study_dir, "..", ".."))
src       <- file.path(repo, "clean")
study     <- "Hu_YQ_2026_ChinaSciData"

# --- helpers ----------------------------------------------------------------
read_merged <- function(pattern) {
  files <- sort(Sys.glob(pattern))
  stopifnot(length(files) > 0)
  rbindlist(lapply(files, fread, encoding = "UTF-8", na.strings = c("", "NA")),
            fill = TRUE)
}
write_csv <- function(dt, path) fwrite(dt, path, na = "NA", quote = "auto", sep = ",")

# --- between-subjects group maps -------------------------------------------
hu_subj <- fread(file.path(src, "Hu_2015_unpub", "Hu_2015_unpub_subj_info.csv"),
                 encoding = "UTF-8")
hu_group <- ifelse(as.integer(hu_subj$BDI_Score) >= 21, "depression", "control")
names(hu_group) <- as.character(hu_subj$Subject_ID)

zhou_subj <- fread(file.path(src, "Zhou_2023_unpub_Exp1",
                             "Zhou_2023_unpub_Exp1_subj_info.csv"),
                   encoding = "UTF-8")
zhou_group <- ifelse(zhou_subj$Group == 1, "matching-first", "nonmatching-first")
names(zhou_group) <- as.character(zhou_subj$Subject_ID)

# =============================================================================
# Experiment 1 — Hu 2015 Task1 (self-matching / reward / emotion associations)
# =============================================================================
e1 <- read_merged(file.path(src, "Hu_2015_unpub", "Exp1",
                            "Hu_2015_unpub_Exp1_*_Clean.csv"))
match1 <- c(Matched = "Matching", Mismatched = "Nonmatching")
e1[, `:=`(
  Group      = hu_group[as.character(Subject)],
  Phase      = fifelse(SubTrial == 1, "practice", "main"),
  Block      = BlockList.Sample,
  Matching   = match1[Matching],
  CorrResponse = CorrectAnswer
)]
e1_cols <- c("Subject", "Group", "Session", "Task", "Phase", "Block", "Matching",
             "Shape", "Shape_Origin_Identity", "Shape_English_Identity",
             "Shape_Standardized_Identity", "Label", "Label_Origin_Identity",
             "Label_English_Identity", "Label_Standardized_Identity",
             "CorrResponse", "Response", "RT_ms", "ACC", "Clock.StartTimeOfDay")
e1 <- e1[, ..e1_cols]
write_csv(e1, file.path(study_dir, "Exp1", paste0(study, "_Exp1_Clean.csv")))

# =============================================================================
# Experiment 2 — Hu 2015 Task2 (self/friend/stranger identity x emotion)
# =============================================================================
e2 <- read_merged(file.path(src, "Hu_2015_unpub", "Exp2",
                            "Hu_2015_unpub_Exp2_*_Clean.csv"))
shape_eng    <- c(self = "Self",     friend = "Friend",   stranger = "Stranger")
shape_std    <- c(self = "Self",     friend = "Close",    stranger = "Stranger")
label_origin <- c(self = "自己",      friend = "朋友",     stranger = "生人")
label_eng    <- c(self = "Self",     friend = "Friend",   stranger = "Stranger")
label_std    <- c(self = "Self",     friend = "Close",    stranger = "Stranger")
e2[, `:=`(
  Group      = hu_group[as.character(Subject)],
  Phase      = fifelse(is.na(BlockList.Sample), "practice", "main"),
  Block      = BlockList.Sample,
  Trial      = TrialList,
  Shape_Origin_Identity       = Shape_Origin_Identity,
  Shape_English_Identity      = shape_eng[Shape_Origin_Identity],
  Shape_Standardized_Identity = shape_std[Shape_Origin_Identity],
  Label_Origin_Identity       = label_origin[Label_Origin_Identity],
  Label_English_Identity      = label_eng[Label_Origin_Identity],
  Label_Standardized_Identity = label_std[Label_Origin_Identity],
  Emotion    = fifelse(Emotion == "neutal", "neutral", Emotion),
  CorrResponse = CorrectAnswer
)]
e2_cols <- c("Subject", "Group", "Session", "Task", "Phase", "Block", "Trial",
             "Matching", "Shape", "Shape_Origin_Identity", "Shape_English_Identity",
             "Shape_Standardized_Identity", "Label", "Label_Origin_Identity",
             "Label_English_Identity", "Label_Standardized_Identity",
             "CorrResponse", "Response", "RT_ms", "ACC",
             "Selfpic", "Friendpic", "Strangerpic", "Emotion",
             "TrialList.Cycle", "Clock.StartTimeOfDay")
e2 <- e2[, ..e2_cols]
write_csv(e2, file.path(study_dir, "Exp2", paste0(study, "_Exp2_Clean.csv")))

# =============================================================================
# Experiment 3 — Zhou 2023 Exp1 (matching-verification training task)
# =============================================================================
e3 <- read_merged(file.path(src, "Zhou_2023_unpub_Exp1", "cleaned",
                            "Zhou_2023_unpub_Exp1_*_Clean.csv"))
match3 <- c(match = "Matching", mismatch = "Nonmatching", fill = "Nonmatching")
e3[, `:=`(
  Group      = zhou_group[as.character(Subject)],
  Task       = "self-matching",
  Phase      = Session,          # 9 training stages -> Phase
  Practice   = phase,            # practice/main -> Practice
  Matching   = match3[TrialType],
  CorrResponse = CorrectAnswer,
  RT_ms      = round(as.numeric(RT_ms))
)]
e3_cols <- c("Subject", "Group", "Task", "Phase", "Practice", "Matching",
             "Shape", "Shape_Origin_Identity", "Shape_English_Identity",
             "Shape_Standardized_Identity", "Label", "Label_Origin_Identity",
             "Label_English_Identity", "Label_Standardized_Identity",
             "CorrResponse", "Response", "RT_ms", "ACC")
e3 <- e3[, ..e3_cols]
write_csv(e3, file.path(study_dir, "Exp3", paste0(study, "_Exp3_Clean.csv")))

# =============================================================================
# subj_info CSVs
# =============================================================================
hu_si <- data.table(
  Subject_ID = as.character(hu_subj$Subject_ID),
  Age        = hu_subj$Age,
  Gender     = hu_subj$Gender,
  Handedness = hu_subj$Handedness,
  BDI_Score  = hu_subj$BDI_Score,
  BAI_Score  = hu_subj$BAI_Score,
  Group      = hu_group[as.character(hu_subj$Subject_ID)]
)[order(Subject_ID)]
for (exp in c("Exp1", "Exp2")) {
  write_csv(hu_si, file.path(study_dir, exp, paste0(study, "_", exp, "_subj_info.csv")))
}

zhou_si <- data.table(
  Subject_ID = as.character(zhou_subj$Subject_ID),
  Gender     = zhou_subj$Gender,
  Group      = zhou_group[as.character(zhou_subj$Subject_ID)]
)[order(Subject_ID)]
write_csv(zhou_si, file.path(study_dir, "Exp3", paste0(study, "_Exp3_subj_info.csv")))

# =============================================================================
# Codebooks (openxlsx)
# =============================================================================
DESC <- c(
  Subject = "Participant ID",
  Group = "Between-subjects group",
  Session = "Session number (one complete experimental participation)",
  Task = "Association/task type (whether the association involves a self-referential identity)",
  Phase = "Trial phase",
  Practice = "Practice vs main trial",
  Block = "Block number (NA for practice trials)",
  Trial = "Trial number within block / list cycle",
  Matching = "Whether the presented shape-label pair matches the learned association",
  Shape = "Presented shape stimulus",
  Shape_Origin_Identity = "Identity of the shape in its original form",
  Shape_English_Identity = "English translation of the shape identity",
  Shape_Standardized_Identity = "Canonical standardized identity of the shape (6-category vocabulary)",
  Label = "Presented label stimulus",
  Label_Origin_Identity = "Identity of the label in its original form",
  Label_English_Identity = "English translation of the label identity",
  Label_Standardized_Identity = "Canonical standardized identity of the label (6-category vocabulary)",
  CorrResponse = "Correct response key",
  Response = "Participant's response key (NA = no response)",
  RT_ms = "Reaction time in milliseconds (NA = no response)",
  ACC = "Accuracy: 1 = correct, 0 = incorrect (wrong key), NA = no response",
  Clock.StartTimeOfDay = "Trial start time of day (MM/DD/YY HH:MM)",
  Selfpic = "Circle image assigned to the self identity (counterbalanced)",
  Friendpic = "Circle image assigned to the friend identity (counterbalanced)",
  Strangerpic = "Circle image assigned to the stranger identity (counterbalanced)",
  Emotion = "Emotional expression of the shape stimulus",
  TrialList.Cycle = "E-Prime list cycle number"
)
VAL <- list(ACC = "1 (correct); 0 (incorrect); NA (no response)",
            RT_ms = "milliseconds (NA = no response)",
            Matching = "Matching; Nonmatching")
NUM_COLS <- c("Subject", "Session", "Block", "Trial", "RT_ms", "TrialList.Cycle")

make_codebook <- function(exp) {
  cf <- file.path(study_dir, exp, paste0(study, "_", exp, "_Clean.csv"))
  dt <- fread(cf, encoding = "UTF-8", na.strings = c("", "NA"))
  cols <- names(dt)
  out <- rbindlist(lapply(cols, function(col) {
    x <- dt[[col]]
    if (!is.null(VAL[[col]])) {
      vstr <- VAL[[col]]
    } else if (col %in% NUM_COLS) {
      x <- x[!is.na(x)]
      vstr <- if (length(x) && is.numeric(x)) {
        sprintf("%g - %g", min(x), max(x))
      } else "Number"
    } else {
      u <- unique(x[!is.na(x)])
      u <- as.character(u)
      u <- c(sort(setdiff(u, "NA")), if (any(is.na(x))) "NA" else NULL)
      vstr <- paste(head(u, 40), collapse = "; ")
    }
    data.table(Variable_name = col,
               Variable_description = ifelse(col %in% names(DESC), DESC[[col]], "NA"),
               Variable_value = vstr,
               Variable_category = ifelse(col %in% NUM_COLS, "Numerical", "Categorical"))
  }))
  wb <- createWorkbook(); addWorksheet(wb, "Sheet1")
  writeDataTable(wb, "Sheet1", out)
  saveWorkbook(wb, file.path(study_dir, exp,
                             paste0("Codebook_", study, "_", exp, "_Clean.xlsx")),
               overwrite = TRUE)
  message("codebook -> ", exp, " (", nrow(out), " vars)")
}
for (exp in c("Exp1", "Exp2", "Exp3")) make_codebook(exp)

# =============================================================================
# Experiment JSONs (re-key the source v2 JSONs; append a standardization note)
# =============================================================================
NOTE <- paste0(
  "Standardized to SPE Database schema v2 on 2026-09-25: per-participant ",
  "files merged into a single trial-level CSV; column order aligned to the v2 ",
  "template; Matching canonicalized to Matching/Nonmatching; identity columns ",
  "canonicalized (Self/Close/Stranger); a between-subjects Group column added; ",
  "study-specific columns moved to the tail. Source: clean/ (read-only).")

exp_json_src <- list(
  Exp1 = file.path(src, "Hu_2015_unpub", "Exp1", "Hu_2015_unpub_Exp1.json"),
  Exp2 = file.path(src, "Hu_2015_unpub", "Exp2", "Hu_2015_unpub_Exp2.json"),
  Exp3 = file.path(src, "Zhou_2023_unpub_Exp1", "Zhou_2023_unpub_Exp1.json"))
new_key <- c(Exp1 = "exp1", Exp2 = "exp2", Exp3 = "exp3")
for (exp in c("Exp1", "Exp2", "Exp3")) {
  s <- fromJSON(exp_json_src[[exp]], simplifyVector = FALSE)
  inner <- s[[1]]
  inner$detail <- trimws(paste(inner$detail, NOTE))
  obj <- setNames(list(inner), new_key[[exp]])
  writeLines(toJSON(obj, auto_unbox = TRUE, pretty = TRUE),
             file.path(study_dir, exp, paste0(study, "_", exp, ".json")))
}

# =============================================================================
# Paper JSON
# =============================================================================
paper <- list(
  Paper_name = "Data for Training Effect of Self Prioritization",
  Summary = paste0(
    "Cleaned, de-identified, minimally preprocessed trial-level behavioral ",
    "data of two self-prioritization training-effect experiments: Experiment 1 ",
    "and Experiment 2 of Hu et al. (2015, unpublished; Tsinghua University, ",
    "Beijing) and Experiment 1 of Zhou et al. (2023, unpublished; Henan ",
    "University, Kaifeng). Participants learned shape-label associations and ",
    "judged whether each presented shape-label pair matched the learned ",
    "association. Data follow the SPE Database schema (v2)."),
  Year = "2026",
  Author = "Chuanpeng Hu; Kaiping Peng; Jie Sui",
  Journal = "/",
  Country = "China",
  City = "Beijing",
  Extra_Var = "/",
  Email = "/",
  DOI = "10.57760/sciencedb.08117",
  Conclusion = paste0(
    "The dataset bundles three experiments: Hu 2015 Exp1 (self-matching / ",
    "reward / emotion associations), Hu 2015 Exp2 (self/friend/stranger ",
    "identities x emotion), and Zhou 2023 Exp1 (matching-verification ",
    "training, matching-first vs nonmatching-first groups). See the ",
    "experiment JSONs for full design details."))
writeLines(toJSON(paper, auto_unbox = TRUE, pretty = TRUE),
           file.path(study_dir, paste0(study, ".json")))

message("DONE: five-piece set regenerated under ", study_dir)
