#!/usr/bin/env Rscript
# ============================================================
# validate_clean_csv.R — Clean.csv 内容级校验器（2026-08 新增）
# ------------------------------------------------------------
# 用途：在 validate_json_metadata.R（结构级）之外，对每个
#   *_Clean.csv 做内容级检查：
#   E1 缺 Subject 列
#   E2 Identity 三级不完整（有 X_Origin_Identity 却缺
#      X_English_Identity / X_Standardized_Identity）
#   E3 Subject 唯一数 != 对应 *_subj_info.csv 数据行数
#   W1 缺推荐标准列（Shape/Label/Matching/ACC/RT_ms，含替代列提示）
#   W2 Subject 数 vs Dataset_inf.csv Valid_Subj/Sample_Size（口径差异，已知）
#   W3 ACC 值域异常（不在 {-1,0,1,2,3,4} 内）
#   W4 非标准命名 *_Clean.csv（不匹配 <Study>_Exp<N>_Clean.csv）
#   W5 Matching 值域异常（严格：仅允许 Matching/Nonmatching；空白/NA 亦报错；
#      不列出错值；2026-09-04 全库统一规范，Zhang_2023_NeuroImage_Exp1 占位 NA 行 → WARN 待核查）
# 排除：输入区目录（*_Raw/、*Raw/、Source/ 等，见 SKILL.md 输入区规范）。
# 用法：Rscript 2_Code/validate_clean_csv.R
# 退出码：存在 ERROR（非已知例外）→ 1，否则 0。
# 历史遗留问题列于下方 known 清单（KNOWN 豁免，修复后移除，
# 与 validate_json_metadata.R 的 known_pending 模式一致）。
# ============================================================
suppressMessages(library(data.table))
options(warn = -1)

args <- commandArgs(TRUE)
data_dir <- if (length(args)) args[1] else "1_Data"
if (!dir.exists(data_dir)) data_dir <- file.path("..", "1_Data")
stopifnot(dir.exists(data_dir))

# 产物区 Clean 文件（排除输入区 *_Raw/ 与 Source/ 等）
clean_files <- sort(list.files(data_dir, pattern = "_Clean[.]csv$",
                                recursive = TRUE, full.names = TRUE))
clean_files <- clean_files[!grepl("/[.]_", clean_files)]
clean_files <- clean_files[!grepl("(_Raw/|_raw/|/Raw/|/Source/)", clean_files)]

# ---------- 已知例外（历史遗留，修复后移出） ----------
known <- c(
  "Constable_2020_ActaPsych_Exp1"    = "缺 Label/Shape 的 English/Standardized 四个 Identity 三级列（历史文件，待补）",
  "Sun_2026_DataExp_Exp1"            = "nSubj 506 vs subj_info 334 行（全样本 vs 有效样本口径，已知）",
  "Zhang_2023_NeuroImage_Exp1"       = "nSubj 346 vs subj_info 347 行（差 1，待核）",
  "Perrykkad_2022_BMCPsych_Exp1"       = "nSubj 334 vs subj_info 288 行（Pt7E1 N 口径，待核）"
)
is_known <- function(base, rule) {
  if (!base %in% names(known)) return(FALSE)
  grepl(rule, known[[base]], fixed = TRUE)
}

# ---------- Dataset_inf.csv 引用 ----------
inf <- tryCatch(as.data.frame(fread(file.path(data_dir, "Dataset_inf.csv"),
                                    encoding = "UTF-8")),
                error = function(e) read.csv(file.path(data_dir, "Dataset_inf.csv"),
                                             fileEncoding = "UTF-8-BOM",
                                             check.names = FALSE, stringsAsFactors = FALSE))
if (!"Folder_Name" %in% names(inf))
  inf <- read.csv(file.path(data_dir, "Dataset_inf.csv"), fileEncoding = "UTF-8-BOM",
                  check.names = FALSE, stringsAsFactors = FALSE)

std_cols <- c("Subject", "Shape", "Label", "Matching", "ACC", "RT_ms")
alt_cols <- list(
  Shape    = c("Face", "Stimulus", "Voice", "soundfile", "file_stim", "Speaker"),
  Label    = c("Label1", "Label2", "Label3", "etichetta"),
  Matching = c("Condition", "Match", "match", "condizione", "TrialType"),
  ACC      = c("corr", "Correct", "respCorr", "risposta.corr", "fl.ACC", "MT4.ACC"),
  RT_ms    = c("RT", "rt", "respRt", "risposta.rt", "RT_sec", "fl.RT", "MT4.RT")
)
# ACC 合法值域：含 ACC 统一编码（方案 A，2026-08）的负码 -2/-3/-4 及历史旧码（-1 无反应、2/3/4 旧特殊码）
# 2026-09-02 同步：方案 A 执行时未更新本词表，Hu_2020 正确编码 -2（范围外按键）曾被误报 W3
ACC_OK <- c(-4, -3, -2, -1, 0, 1, 2, 3, 4)

find_subj_info <- function(cf, base) {
  dirs <- unique(c(dirname(cf), dirname(dirname(cf))))
  cands <- unlist(lapply(dirs, function(d)
    list.files(d, pattern = "_subj_info[.]csv$", full.names = TRUE)))
  cands <- cands[!grepl("/[.]_", cands)]
  if (!length(cands)) return(NA_character_)
  ok <- vapply(cands, function(s) {
    sb <- sub("_subj_info[.]csv$", "", basename(s))
    identical(sb, base) || startsWith(base, sb) || startsWith(sb, base)
  }, logical(1))
  if (!any(ok)) return(NA_character_)
  cands[ok][1]
}

n_err <- n_warn <- n_info <- 0
for (cf in clean_files) {
  base <- sub("_Clean[.]csv$", "", basename(cf))
  hdr  <- names(fread(cf, nrows = 0))
  sel  <- intersect(c("Subject", "ACC", "Matching"), hdr)
  dt   <- if (length(sel)) fread(cf, select = sel) else fread(cf, select = 1L)
  n_rows <- nrow(dt)
  n_subj <- if ("Subject" %in% hdr) length(unique(dt[["Subject"]])) else NA_integer_

  # ---- E1 缺 Subject ----
  if (!"Subject" %in% hdr) {
    cat(sprintf("[ERROR] %s: 缺标准列 Subject（列头: %s）\n", base,
                paste(head(hdr, 12), collapse = ",")))
    n_err <- n_err + 1
  }
  # ---- E2 Identity 三级完整性 ----
  org <- hdr[grepl("_Origin_Identity$", hdr)]
  for (o in org) {
    stem <- sub("_Origin_Identity$", "", o)
    for (suf in c("_English_Identity", "_Standardized_Identity")) {
      if (!paste0(stem, suf) %in% hdr) {
        if (is_known(base, "Identity 三级列")) {
          cat(sprintf("[KNOWN] %s: E2 缺 %s（历史遗留）\n", base, paste0(stem, suf)))
        } else {
          cat(sprintf("[ERROR] %s: 有 %s 但缺 %s\n", base, o, paste0(stem, suf)))
          n_err <- n_err + 1
        }
      }
    }
  }
  # ---- E3 Subject 数 vs subj_info ----
  si <- find_subj_info(cf, base)
  si_n <- if (!is.na(si)) nrow(fread(si, select = 1L)) else NA_integer_
  if (!is.na(n_subj) && !is.na(si_n) && n_subj != si_n) {
    if (is_known(base, "subj_info")) {
      cat(sprintf("[KNOWN] %s: E3 nSubj %d vs subj_info %d（历史遗留）\n", base, n_subj, si_n))
    } else {
      cat(sprintf("[ERROR] %s: nSubj %d != subj_info 行数 %d\n", base, n_subj, si_n))
      n_err <- n_err + 1
    }
  }
  # ---- W1 缺标准列（替代列提示） ----
  for (sc in std_cols[-1]) {
    if (!sc %in% hdr) {
      hit <- intersect(alt_cols[[sc]], hdr)
      hint <- if (length(hit)) sprintf("（有替代列: %s）", paste(hit, collapse = ",")) else ""
      cat(sprintf("[WARN] %s: 缺标准列 %s %s\n", base, sc, hint))
      n_warn <- n_warn + 1
    }
  }
  # ---- W2 CSV 引用（Folder_Name + Exp 精确匹配） ----
  exp_s <- sub(".*_Exp([0-9A-Za-z_]+)$", "\\1", base)
  folder <- NULL
  for (fn in unique(inf[["Folder_Name"]])) {
    if (!is.na(fn) && startsWith(base, paste0(fn, "_Exp"))) { folder <- fn; break }
  }
  if (!is.null(folder) && grepl("^[0-9A-Za-z_]+$", exp_s)) {
    ir <- inf[inf[["Folder_Name"]] == folder & as.character(inf[["Exp"]]) == exp_s, ]
    if (nrow(ir)) {
      vv <- as.character(ir[["Valid_Subj"]][1]); ss <- as.character(ir[["Sample_Size"]][1])
      if (!is.na(vv) && nzchar(vv) && as.numeric(vv) != n_subj)
        cat(sprintf("[WARN] %s: nSubj %d vs CSV Valid_Subj %s（口径差异，已知类）\n", base, n_subj, vv))
      if (!is.na(ss) && nzchar(ss) && as.numeric(ss) != n_subj)
        cat(sprintf("[WARN] %s: nSubj %d vs CSV Sample_Size %s（口径差异，已知类）\n", base, n_subj, ss))
    }
  }
  # ---- W3 ACC 值域 ----
  if ("ACC" %in% hdr) {
    vals <- unique(dt[["ACC"]])
    vals <- vals[!is.na(vals) & !grepl("^\\s*$", as.character(vals))]
    numv <- suppressWarnings(as.numeric(as.character(vals)))
    odd <- vals[is.na(numv) | !numv %in% ACC_OK]
    if (length(odd))
      cat(sprintf("[WARN] %s: ACC 值域外值: %s\n", base, paste(head(as.character(odd), 8), collapse = ",")))
  }
  # ---- W5 Matching 值域（2026-09-04 严格规范：仅允许 Matching/Nonmatching；
  #      空白/NA 亦视为非规范值 → 报错，不列出错值） ----
  if ("Matching" %in% hdr) {
    vals <- unique(dt[["Matching"]])
    bad  <- vals[is.na(vals) | !vals %in% c("Matching", "Nonmatching")]
    if (length(bad)) {
      cat(sprintf("[WARN] %s: Matching 列含非规范取值（仅允许 Matching/Nonmatching）\n", base))
      n_warn <- n_warn + 1
    }
  }
  # ---- W4 非标准命名 ----
  if (!grepl("_Exp[0-9]+([A-Za-z]+(_[0-9]+)?|\\.[0-9]+)?$", base)) {
    if (base %in% names(known))
      cat(sprintf("[KNOWN] %s: W4 非标准命名（历史变体）\n", base))
    else {
      cat(sprintf("[WARN] %s: 非标准命名（不匹配 <Study>_Exp<N>_Clean.csv）\n", base))
      n_warn <- n_warn + 1
    }
  }
  # ---- INFO ----
  cat(sprintf("[INFO] %s: rows=%d nSubj=%s subj_info=%s\n", base, n_rows,
              ifelse(is.na(n_subj), "-", n_subj),
              ifelse(is.na(si_n), "-", si_n)))
  n_info <- n_info + 1
}

cat(sprintf("\n==== SUMMARY: files=%d errors=%d warns=%d infos=%d ====\n",
            length(clean_files), n_err, n_warn, n_info))
if (n_err > 0) quit(status = 1)
cat("All Clean.csv files conform to the content conventions.\n")

