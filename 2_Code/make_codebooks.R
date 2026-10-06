# Codebook generator for SPE Database (stage-1 backfill / stage-5 ingestion).
# Creates one Codebook_<Study>_Exp<N>_Clean.xlsx (single Sheet1, 4 columns:
# Variable_name | Variable_description | Variable_value | Variable_category) per Clean.csv.
# USAGE: edit the `jobs` list (clean csv path -> output xlsx path), then: Rscript make_codebooks.R
# Column values are enumerated from the actual data (unique values, incl. special codes like NA/timeout/None).
# Follows SKILL.md (spe-database-curation) §Codebook authoring rules.
library(openxlsx)

jobs <- list(
  list(clean = "1_Data/Lee_2023_Cognition/Exp1/Lee_2023_Cognition_Exp1_Clean.csv",
       cb = "1_Data/Lee_2023_Cognition/Exp1/Codebook_Lee_2023_Cognition_Exp1_Clean.xlsx"),
  list(clean = "1_Data/Lee_2023_Cognition/Exp2/Lee_2023_Cognition_Exp2_Clean.csv",
       cb = "1_Data/Lee_2023_Cognition/Exp2/Codebook_Lee_2023_Cognition_Exp2_Clean.xlsx"),
  list(clean = "1_Data/Smith_2024_Cortex/Smith_2024_Cortex_Exp1_Clean.csv",
       cb = "1_Data/Smith_2024_Cortex/Codebook_Smith_2024_Cortex_Exp1_Clean.xlsx"),
  list(clean = "1_Data/Svensson_2023_QJEP/Svensson_2023_QJEP_Exp1_Clean.csv",
       cb = "1_Data/Svensson_2023_QJEP/Codebook_Svensson_2023_QJEP_Exp1_Clean.xlsx"),
  list(clean = "1_Data/Orellana-Corrales_2021_APP/Exp1/Orellana-Corrales_2021_APP_Exp1_Clean.csv",
       cb = "1_Data/Orellana-Corrales_2021_APP/Exp1/Codebook_Orellana-Corrales_2021_APP_Exp1_Clean.xlsx"),
  list(clean = "1_Data/Orellana-Corrales_2021_APP/Exp2/Orellana-Corrales_2021_APP_Exp2_Clean.csv",
       cb = "1_Data/Orellana-Corrales_2021_APP/Exp2/Codebook_Orellana-Corrales_2021_APP_Exp2_Clean.xlsx"),
  # Sun_2026_DataExp：Clean 已按被试边界分为 4 片，枚举用 /tmp 下的合并副本（分片共用 1 份 Codebook）
  list(clean = "/tmp/sun_cb/clean_combined.csv",
       cb = "1_Data/Sun_2026_DataExp/Codebook_Sun_2026_DataExp_Exp1_Clean.xlsx")
)

describe <- function(col) {
  if (col == "Subject") return("Participant number")
  if (col == "Block") return("Block number in the experiment; each block may contain practice or experimental trials")
  if (col == "Trial") return("Trial number within the block")
  if (col == "Shape") return("Visual shape stimulus presented in the trial")
  if (col == "Label") return("Text label presented for matching with the shape")
  if (col == "Matching") return("Type of matching task for the trial; indicates whether the shape and label match or not")
  if (col == "Label_Origin_Identity") return("Original identity associated with the label")
  if (col == "Label_English_Identity") return("English translation of the label's identity")
  if (col == "Label_Standardized_Identity") return("Standardized identity for the label used across experiments")
  if (col == "Shape_Origin_Identity") return("Original identity associated with the shape stimulus")
  if (col == "Shape_English_Identity") return("English translation of the shape's identity")
  if (col == "Shape_Standardized_Identity") return("Standardized identity for the shape used across experiments")
  if (col == "Response") return("Participant's response in the trial")
  if (col == "RT_ms") return("Reaction time for the response, measured in milliseconds")
  if (col == "RT_sec") return("Reaction time for the response, measured in seconds")
  if (col == "ACC") return("Accuracy of the participant's response")
  if (col == "Session") return("Test session in which the trial was completed (same task across sessions is not a new experiment)")
  if (col == "Task") return("Task type: whether the shape-label association includes a self-referential identity (self-matching) or not")
  if (col == "Phase") return("Phase of the task the trial belongs to (practice vs formal, and task/sub-task variant)")
  if (col == "extraIV1") return("Study-specific additional independent variable 1 (semantics documented in the experiment JSON detail)")
  if (col == "extraIV2") return("Study-specific additional independent variable 2 (semantics documented in the experiment JSON detail)")
  if (col == "CorrResponse") return("Correct response key for the trial as designed (missing if the source file does not provide it)")
  if (col == "Run") return("Administration run of the same task for participants who completed it more than once (1 = first run)")
  return("NA")
}

# ---- 研究特有描述覆盖（per-job `desc`；未覆盖的列仍用 describe()）--------------
# Wu_2026_Chinaxiv：Shape = 承载身份的 RDK 感觉特征（非几何图形）、Task 含新受控值 choice-task、
# extraIV1 = difficulty、extraIV2 = task relevance（详见 3_Reports/Wu_2026_Chinaxiv_Ingestion_Plan.md §5/§5.1）
desc_wu_exp1 <- c(
  Subject = "Participant number as used by the authors in the shared repository (raw file names exp1_subj_<N>.csv). 1-70 = motion group, 71-141 = colour group",
  Group = "Between-subjects factor: perceptual dimension of the random-dot kinematogram (RDK) task. motion = participants judged the overall motion direction; colour = participants judged the dominant colour",
  Task = "Task type. self-matching = identity-matching task (a learned feature-identity association is probed: the identity-bearing RDK feature is paired with an image label 我/他/她). choice-task = two-alternative feature discrimination of the RDK (judge motion direction or dominant colour); no matching judgement",
  Phase = "Session phase. staircase = adaptive threshold estimation (8 groups of 12 trials) run before the association instructions; practice = association practice blocks (criterion >=65% correct, repeated until reached); main = formal blocks",
  Block = "Block number, numbered sequentially within a participant across tasks and phases (rest-delimited blocks; staircase in groups of 12 trials)",
  Trial = "Trial number within the block",
  Matching = "Whether the presented feature-label pair agrees with the association learned before the task. NA = not applicable (choice-task and staircase trials have no matching dimension)",
  Shape = "Identity-bearing stimulus layer: the RDK feature associated with an identity - motion direction (left/right) for the motion group, dominant colour (blue/red) for the colour group. The feature-identity binding was counterbalanced across participants (self = left or right; self = blue or red; see subj_info Self_Feature). Not a geometric shape",
  Shape_Origin_Identity = "Identity of the shape-side stimulus as recorded in the raw data (raw column association). NA = no identity established (staircase trials)",
  Shape_English_Identity = "English form of the raw identity label",
  Shape_Standardized_Identity = "Standardized identity category (database-wide vocabulary): Self = self-associated feature, Stranger = other-associated feature. NA = no identity established (staircase trials)",
  Label = "Identity label presented as an image in the matching task (我 = self; 他/她 = other, matching the participant's gender per the raw label column). Not presented in the choice task, where the value is the identity the feature is associated with",
  Label_Origin_Identity = "Identity label as recorded in the raw data (raw column label; choice-task rows carry the associated identity label, see Label)",
  Label_English_Identity = "English form of the label identity (我 = Self; 他/她 = Other)",
  Label_Standardized_Identity = "Standardized identity category of the label (Self / Stranger)",
  extraIV1 = "Difficulty level of the trial (manipulated within-subject variable 3): very_easy / easy / difficult / very_difficult, mapped from the raw difficulty codes 1-4 (staircase targets ~90/80/70/60% correct). Implemented by the RDK coherence (motion group) or target-colour proportion (colour group), titrated per participant by the preceding staircase; those physical values are kept in the raw file (columns coherence / target_color_proportion). NA = not applicable (staircase trials)",
  Response = "Key pressed by the participant: f / j (matching task; response-to-key mapping counterbalanced across participants), arrowleft / arrowright (motion discrimination), d / k (colour discrimination). NA = no response within the 3000 ms response window",
  RT_ms = "Reaction time in milliseconds from stimulus onset (raw column rt). The raw value -1 (no response) is written as NA",
  ACC = "Response accuracy: 1 = correct, 0 = incorrect (a key within the response set), NA = no response (raw rt = -1). The raw correct flag is false for no-response trials and is not treated as an error"
)
desc_wu_exp2 <- desc_wu_exp1
desc_wu_exp2[["Subject"]] <- "Participant number as used by the authors in the shared repository (raw file names exp2_subj_<N>.csv). 1-30 = motion-associated, 36-65 = colour-associated (31-35 not shared after failing practice)"
desc_wu_exp2[["Group"]] <- "Between-subjects counterbalancing variable: the dimension associated with the identity (motion = direction-associated participants; colour = colour-associated participants). Determines which dimension is the identity-associated feature and hence which choice-task block is task-relevant"
desc_wu_exp2[["Task"]] <- "Task type. self-matching = identity-matching task (learned feature-identity association probed with an image label 我/他/她). choice-task = two-alternative feature discrimination of the RDK (judge motion direction or dominant colour); no matching judgement"
desc_wu_exp2[["Phase"]] <- "Session phase. staircase = adaptive threshold estimation for both dimensions (2 x 4 groups of 12 trials) before the association instructions; practice = association practice blocks (criterion >=65% correct); main = formal blocks"
desc_wu_exp2[["extraIV1"]] <- "Difficulty level of the trial (manipulated within-subject variable 3): easy / hard (targets ~85% / ~70% correct), as exported by the program. Implemented by the RDK coherence (motion dimension) or target-colour proportion (colour dimension), titrated per participant by the staircase; those physical values are kept in the raw file. NA = not applicable (staircase trials)"
desc_wu_exp2[["extraIV2"]] <- "Task relevance of the association (manipulated within-subject variable 4). relevant = the judged feature is the identity-associated feature; irrelevant = the judged feature is the other feature. NA = not applicable (matching task and staircase trials). For the 7 participants whose raw export lacks the task_type column (25-28, 58-60) the value was reconstructed as 'block dimension == associated dimension ? relevant : irrelevant' (see experiment JSON detail)"
desc_wu_exp2[["Response"]] <- "Key pressed by the participant: f / j (matching task; response-to-key mapping counterbalanced across participants), arrowleft / arrowright (motion discrimination), d / k (colour discrimination). NA = no response within the 3000 ms response window"

desc_lee2023_exp1 <- NULL  # 保留占位：其他研究仍用 describe() 的通用描述

jobs <- c(jobs, list(
  list(clean = "1_Data/Wu_2026_Chinaxiv/Exp1/Wu_2026_Chinaxiv_Exp1_Clean.csv",
       cb    = "1_Data/Wu_2026_Chinaxiv/Exp1/Codebook_Wu_2026_Chinaxiv_Exp1_Clean.xlsx",
       desc  = desc_wu_exp1),
  list(clean = "1_Data/Wu_2026_Chinaxiv/Exp2/Wu_2026_Chinaxiv_Exp2_Clean.csv",
       cb    = "1_Data/Wu_2026_Chinaxiv/Exp2/Codebook_Wu_2026_Chinaxiv_Exp2_Clean.xlsx",
       desc  = desc_wu_exp2)
))

# 可选：命令行给出子串时只处理匹配的 job（默认处理全部，行为不变）
argv <- commandArgs(trailingOnly = TRUE)
if (length(argv)) {
  jobs <- Filter(function(j) any(vapply(argv, function(a) grepl(a, j$clean, fixed = TRUE), logical(1))), jobs)
  cat("selected jobs:", length(jobs), "\n")
}

for (j in jobs) {
  d <- read.csv(j$clean, stringsAsFactors = FALSE, check.names = FALSE, na.strings = "")
  hdr <- names(d)
  rows <- do.call(rbind, lapply(hdr, function(col) {
    vals <- unique(d[[col]])
    vals <- vals[!is.na(vals) & vals != ""]
    if (col %in% c("Subject", "Block", "Trial", "RT_ms", "RT_sec")) {
      v <- "Number"
      catg <- "Numerical"
    } else {
      v <- paste(vals, collapse = ";")
      catg <- "Categorical"
    }
    data.frame(Variable_name = col,
               Variable_description = if (!is.null(j$desc) && col %in% names(j$desc)) unname(j$desc[[col]]) else describe(col),
               Variable_value = v,
               Variable_category = catg,
               stringsAsFactors = FALSE)
  }))
  write.xlsx(rows, j$cb, sheetName = "Sheet1")
  cat("WROTE", j$cb, "| rows:", nrow(rows), "\n")
}
