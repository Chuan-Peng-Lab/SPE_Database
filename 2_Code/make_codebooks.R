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
               Variable_description = describe(col),
               Variable_value = v,
               Variable_category = catg,
               stringsAsFactors = FALSE)
  }))
  write.xlsx(rows, j$cb, sheetName = "Sheet1")
  cat("WROTE", j$cb, "| rows:", nrow(rows), "\n")
}
