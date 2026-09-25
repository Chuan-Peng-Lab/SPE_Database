# ============================================================================
# Generate_Table1_v2.R  —  从 Dataset_inf.csv 重新生成稿件 Table 1（v2）
#
# 相对 Generate_Table1.qmd 的修正：
#   (1) 移除 `stopifnot("Paper_ID" %in% names(inf))`：Paper_ID 列已从
#       Dataset_inf.csv 移除，旧 qmd 因此无法渲染（EXIT != 0）。
#   (2) 输出改为 CSV（不依赖 quarto / pandoc），便于写入 Word 稿件。
#   (3) 统计口径：全部在 1_Data/ 下真实存在文件夹的行（2026-09-24 实测 107 行；
#       Hu_YQ_2026_ChinaSciData 为 deferred、无文件夹，故不入表）。
#
# 用法：Rscript Generate_Table1_v2.R   （工作目录 = 仓库根，脚本自行定位）
# ============================================================================

suppressPackageStartupMessages({
  library(jsonlite)
  library(dplyr)
})

# ---- 定位仓库根（脚本自身位置 → 上一级）--------------------------------
.this <- NULL
args <- commandArgs(trailingOnly = FALSE)
fa <- grep("^--file=", args, value = TRUE)
if (length(fa)) .this <- sub("^--file=", "", fa[1])
repo_root <- if (!is.null(.this)) {
  normalizePath(file.path(dirname(normalizePath(.this)), ".."), mustWork = FALSE)
} else {
  normalizePath(".", mustWork = FALSE)
}
setwd(repo_root)
cat("repo root:", getwd(), "\n")

data_dir <- file.path("1_Data")
inf_csv  <- file.path(data_dir, "Dataset_inf.csv")
out_dir  <- file.path("3_Reports", "Output")

inf <- read.csv(inf_csv, stringsAsFactors = FALSE, check.names = FALSE,
                na.strings = c("", "NA"), fileEncoding = "UTF-8-BOM")
stopifnot("Folder_Name" %in% names(inf))

folders <- list.dirs(data_dir, recursive = FALSE, full.names = FALSE)
folders <- sort(folders[!grepl("^\\._", folders)])

keep <- inf$Folder_Name %in% folders
cat("1_Data/ 文件夹数:", length(folders), "\n")
cat("Dataset_inf.csv 行数:", nrow(inf), "\n")
cat("保留（有文件夹）行数:", sum(keep), " 剔除行数:", sum(!keep), "\n")
cat("剔除的 Folder_Name:", paste(unique(inf$Folder_Name[!keep]), collapse = ", "), "\n")
d <- inf[keep, ]

# ---- Exp_Implement：从实验 JSON 的 Physical_Environment.Setting 推断 ----
exp_impl <- function(folder) {
  jsons <- list.files(file.path(data_dir, folder), pattern = "_Exp[0-9]+[.]json$",
                      recursive = TRUE, full.names = TRUE)
  jsons <- jsons[!grepl("[/\\\\][.]_", jsons)]
  if (!length(jsons)) return(NA_character_)
  settings <- character(0)
  for (j in jsons) {
    p <- tryCatch(fromJSON(j, simplifyVector = FALSE), error = function(e) NULL)
    if (is.null(p)) next
    key <- names(p)[1]
    pe  <- p[[key]]$Physical_Environment
    s   <- if (!is.null(pe) && !is.null(pe$Setting)) as.character(pe$Setting) else ""
    s   <- trimws(s)
    if (!is.na(s) && nzchar(s) && s != "/") settings <- c(settings, tolower(s))
  }
  txt <- paste(settings, collapse = " ")
  has_online <- grepl("online", txt)
  has_lab    <- grepl("laborat|lab ", txt) || grepl("quiet room|chamber|in-person|testing room", txt)
  if (has_online && has_lab) return("Mixed (Lab + Online)")
  if (has_online) return("Online Experiment")
  if (has_lab)    return("Lab Experiment")
  NA_character_
}
d$Exp_Implement <- vapply(d$Folder_Name, exp_impl, character(1))

# ---- Study 标签 ----------------------------------------------------------
d$Study <- ifelse(
  !is.na(d$FirstAuthor) & nzchar(d$FirstAuthor) & !is.na(d$Year) & nzchar(d$Year),
  paste0(d$FirstAuthor, " (", d$Year, ")"),
  d$Folder_Name
)

# ---- N (M/F) -------------------------------------------------------------
is_miss <- function(x) is.na(x) | !nzchar(trimws(x)) | tolower(trimws(x)) == "missing"
has_mf  <- !is_miss(d$Male) & !is_miss(d$Female)
d$`N (M/F)` <- ifelse(
  !is_miss(d$Sample_Size),
  ifelse(has_mf, paste0(d$Sample_Size, " (", d$Male, "/", d$Female, ")"),
         as.character(d$Sample_Size)),
  "\u2014"
)

# ---- 组装 Table 1 --------------------------------------------------------
tbl1 <- data.frame(
  Num           = seq_len(nrow(d)),
  ID            = d$Folder_Name,
  Study         = d$Study,
  Exp           = ifelse(is.na(d$Exp) | !nzchar(d$Exp), "", paste0("Exp", d$Exp)),
  Country       = d$Country,
  Language      = d$Stim_language,
  `N (M/F)`     = d$`N (M/F)`,
  Stimulus      = d$Stim_Type,
  Trials        = d$numTrials,
  License       = d$License,
  Exp_Implement = d$Exp_Implement,
  check.names = FALSE, stringsAsFactors = FALSE
)

dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
write.csv(tbl1, file.path(out_dir, "Table1_v2.csv"), row.names = FALSE, fileEncoding = "UTF-8")

cat("\n=== Table 1 (v2) 前 10 行 ===\n")
print(head(tbl1, 10), row.names = FALSE)
cat(sprintf("\n写出 %d 行 -> %s\n", nrow(tbl1), file.path(out_dir, "Table1_v2.csv")))

# ---- 规模数字重算 --------------------------------------------------------
num_ok <- suppressWarnings(as.numeric(d$Sample_Size))
trials_num <- suppressWarnings(as.numeric(sub("^([0-9]+).*$", "\\1", d$numTrials)))

summary_stats <- data.frame(
  metric = c("studies_with_data_folder", "csv_rows", "unique_folder_names",
             "unique_study_exp", "participants_sum", "trials_planned_sum"),
  value = c(length(unique(d$Folder_Name)), nrow(d),
            length(unique(d$Folder_Name)),
            nrow(unique(d[, c("Folder_Name", "Exp")])),
            sum(num_ok, na.rm = TRUE),
            sum(trials_num * num_ok, na.rm = TRUE))
)
print(summary_stats, row.names = FALSE)
write.csv(summary_stats, file.path(out_dir, "Table1_v2_summary_stats.csv"),
          row.names = FALSE)
cat("done\n")
