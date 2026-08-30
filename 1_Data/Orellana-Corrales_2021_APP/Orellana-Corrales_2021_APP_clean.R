# ============================================================================
# Orellana-Corrales_2021_APP — 独立清洗脚本（Exp1 + Exp2）：重建标准 *_raw.csv
# ----------------------------------------------------------------------------
# 背景（2026-08 阶段 4 raw 追补）：本研究此前仅有 Clean/subj_info/Codebook/JSON，
# 无标准 trial 级 *_raw.csv。OSF 官方仓库（g7wrc = Exp1/Study 1 shapes，
# 4cwrv = Exp2/Study 2 nonwords）的 storage archive 已下载至输入区
# （Orellana-Corrales_2021_APP/Exp1_g7wrc-osfstorage-archive/、
#  Orellana-Corrales_2021_APP/EXP2_4cwrv-osfstorage-archive/），本脚本从
# E-Prime 文本导出（UTF-16LE 的 *_txt）解析匹配任务（matching task）trial 级
# 数据，重建标准 raw.csv。
#
# 相对原始导出的处理：
#   1. 仅提取匹配任务：每个 LogFrame 块中 Procedure == Matching 的块
#      （练习块 Procedure == Prac 不提取；论文：4 练习 + 128 实验试次）。
#   2. 字段映射（E-Prime 原始名 → raw 列）：
#        label  -> Label（Ich/Fremder，德语原文）
#        shape  -> Shape（Exp1；Kreis.png/Dreieck.png）
#        nonword-> Nonword（Exp2；非词字符串）
#        match  -> Matching（"match"/"nonmatch" -> "Matching"/"Nonmatching"，
#                          与库内 Clean 值域一致）
#        MT.ACC -> ACC（1 正确 / 0 错误，E-Prime 原始编码，最小预处理保留）
#        MT.RT  -> RT_ms（无反应时 E-Prime 留空 -> NA）
#        MT.RESP/MT.CRESP -> Resp/Cresp（实际按键/应按键）
#        bed/manipCheck/Condition（counterbalance 版本/试次内检查点）原样保留
#   3. 每被试 Trial 按 txt 中匹配块出现顺序 1..n 编号。
#   4. Exp2 nonwords-01 数据不完整（源数据问题，2026-08 核实）：匹配任务仅
#      68 试次（其余 33 名均为 128），txt 日志自然终止（无损坏）；OSF 仓库中
#      该被试亦仅有 txt（无 edat2/XML）。raw.csv 保留其 68 行（真实数据），
#      库内 Clean/subj_info 维持既有口径（33 名，不含 01）。
#   5. 论文分析样本（SPSS 脚本硬编码排除名单，供 Note 引用，raw 不过滤）：
#      Exp1 排除 {5, 6, 20, 23, 24, 27}（Tukey，N=28）；
#      Exp2 排除 {4, 33}（Tukey，N=31；nonwords-01 亦不在分析中）。
#
# 验证守卫：Exp1 raw 与现有 Clean 逐值（Subject/Trial/Shape/Label/Matching/
# RT_ms/ACC，按 Subject+Trial 对齐）全等；Exp2 raw 中 subject 2-34 与现有
# Clean 逐值全等。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Orellana-Corrales_2021_APP_clean.R
# 依赖包：无（base R）
# ============================================================================

# ---- 定位脚本目录（引导块，utils.R 依赖） ----
.args <- commandArgs(trailingOnly = FALSE)
.fa <- .args[grepl("^--file=", .args)]
.script_dir <- if (length(.fa)) {
  dirname(normalizePath(sub("^--file=", "", .fa[1])))
} else if (!is.null(sys.frame(1)$ofile)) {
  dirname(normalizePath(sys.frame(1)$ofile))
} else {
  getwd()
}
# ---- 加载通用函数（1_Data/utils.R，与脚本同库） ----
.ut <- file.path(dirname(dirname(.script_dir)), "1_Data", "utils.R")
if (!file.exists(.ut)) .ut <- file.path(.script_dir, "utils.R")
stopifnot(file.exists(.ut))
source(.ut)
rm(.args, .fa, .script_dir, .ut)

STUDY_DIR <- file.path(spe_root(), "1_Data", "Orellana-Corrales_2021_APP")
stopifnot(dir.exists(STUDY_DIR))

EXP1_IN  <- file.path(STUDY_DIR, "Orellana-Corrales_2021_APP",
                      "Exp1_g7wrc-osfstorage-archive", "raw_data")
EXP2_IN  <- file.path(STUDY_DIR, "Orellana-Corrales_2021_APP",
                      "EXP2_4cwrv-osfstorage-archive", "Exp2_rawData")
stopifnot(dir.exists(EXP1_IN), dir.exists(EXP2_IN))

# ============================================================================
# E-Prime 文本导出解析（UTF-16LE）：read_eprime_txt / parse_header /
# parse_matching_blocks 已提取至 1_Data/utils.R（2026-08 沉淀，跨研究复用），
# 由上方引导块 source 的 utils.R 提供，此处不再重复定义。
# ============================================================================

# 单个被试 txt -> trial 行列表
subject_rows <- function(path, has_shape) {
  lines <- read_eprime_txt(path)
  hdr <- parse_header(lines)
  blocks <- parse_matching_blocks(lines)
  subj <- suppressWarnings(as.integer(hdr[["Subject"]]))
  cond <- if (is.null(hdr[["Condition"]])) NA_character_ else hdr[["Condition"]]
  stopifnot(!is.na(subj))
  rows <- lapply(seq_along(blocks), function(i) {
    b <- blocks[[i]]
    acc <- if (!is.null(b[["MT.ACC"]]) && nzchar(b[["MT.ACC"]])) {
      suppressWarnings(as.integer(b[["MT.ACC"]]))
    } else NA_integer_
    rt <- if (!is.null(b[["MT.RT"]]) && nzchar(b[["MT.RT"]])) {
      suppressWarnings(as.integer(b[["MT.RT"]]))
    } else NA_integer_
    matchv <- if (!is.null(b[["match"]])) {
      if (b[["match"]] == "match") "Matching" else if (b[["match"]] == "nonmatch") "Nonmatching" else b[["match"]]
    } else NA_character_
    mc <- if (!is.null(b[["manipCheck"]]) && nzchar(b[["manipCheck"]])) {
      suppressWarnings(as.integer(b[["manipCheck"]]))
    } else NA_integer_
    base <- data.frame(
      Subject = subj, Trial = i,
      Matching = matchv,
      ACC = acc, RT_ms = rt,
      bed = if (is.null(b[["bed"]])) NA_character_ else b[["bed"]],
      manipCheck = mc,
      Resp = if (is.null(b[["MT.RESP"]])) NA_character_ else b[["MT.RESP"]],
      Cresp = if (is.null(b[["MT.CRESP"]])) NA_character_ else b[["MT.CRESP"]],
      Condition = cond,
      stringsAsFactors = FALSE
    )
    base$Label <- if (is.null(b[["label"]])) NA_character_ else b[["label"]]
    if (has_shape) {
      base$Shape <- if (is.null(b[["shape"]])) NA_character_ else b[["shape"]]
      base[, c("Subject", "Trial", "Shape", "Label", "Matching", "ACC", "RT_ms",
               "bed", "manipCheck", "Resp", "Cresp", "Condition")]
    } else {
      base$Nonword <- if (is.null(b[["nonword"]])) NA_character_ else b[["nonword"]]
      base[, c("Subject", "Trial", "Label", "Nonword", "Matching", "ACC", "RT_ms",
               "bed", "manipCheck", "Resp", "Cresp", "Condition")]
    }
  })
  do.call(rbind, rows)
}

# ============================================================================
# 生成 Exp1 raw（34 名 × 128 试次）
# ============================================================================
cat("== Exp1: 解析 targetTasks txt ...\n")
exp1_files <- sort(list.files(EXP1_IN, pattern = "^targetTasks.*\\.txt$", full.names = TRUE))
stopifnot(length(exp1_files) == 34)
raw1 <- do.call(rbind, lapply(exp1_files, subject_rows, has_shape = TRUE))
rownames(raw1) <- NULL
cat("  Exp1 raw 行数:", nrow(raw1), "(预期 4352 = 34×128)\n")
stopifnot(nrow(raw1) == 34 * 128)
stopifnot(all(table(raw1$Subject) == 128))

# ============================================================================
# 生成 Exp2 raw（34 名；nonwords-01 仅 68 试次）
# ============================================================================
cat("== Exp2: 解析 nonwords txt ...\n")
exp2_files <- sort(list.files(EXP2_IN, pattern = "^nonwords-.*\\.txt$", full.names = TRUE))
stopifnot(length(exp2_files) == 34)
raw2 <- do.call(rbind, lapply(exp2_files, subject_rows, has_shape = FALSE))
rownames(raw2) <- NULL
cat("  Exp2 raw 行数:", nrow(raw2), "(预期 4292 = 33×128 + 68)\n")
stopifnot(nrow(raw2) == 33 * 128 + 68)
stopifnot(all(table(raw2$Subject)[as.character(2:34)] == 128))
stopifnot(table(raw2$Subject)[["1"]] == 68)

# ============================================================================
# 与现有 Clean 交叉验证（逐值，按 Subject+Trial 对齐）
# ============================================================================
read_clean <- function(p) {
  read.csv(p, stringsAsFactors = FALSE, check.names = FALSE, fileEncoding = "UTF-8-BOM")
}
cat("== 交叉验证 ...\n")

# --- Exp1 ---
clean1 <- read_clean(file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2021_APP_Exp1_Clean.csv"))
stopifnot(nrow(clean1) == nrow(raw1))
o1 <- order(raw1$Subject, raw1$Trial)
oc <- order(clean1$Subject, clean1$Trial)
for (col in c("Subject", "Trial", "Shape", "Label", "Matching", "RT_ms", "ACC")) {
  a <- raw1[[col]][o1]; b <- clean1[[col]][oc]
  eq <- ifelse(is.na(a) & is.na(b), TRUE, !is.na(a) & !is.na(b) & a == b)
  stopifnot(all(eq))
}
cat("  Exp1: raw 与 Clean 逐值全等 ✓（Subject/Trial/Shape/Label/Matching/RT_ms/ACC）\n")
cat("  Exp1 ACC 分布:", paste(names(table(raw1$ACC)), table(raw1$ACC), sep = "=", collapse = ", "), "\n")

# --- Exp2（subject 2-34 与 Clean 全等；01 仅在 raw） ---
clean2 <- read_clean(file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2021_APP_Exp2_Clean.csv"))
stopifnot(nrow(clean2) == 33 * 128)
r2k <- raw2[raw2$Subject != 1, ]
o2 <- order(r2k$Subject, r2k$Trial)
oc2 <- order(clean2$Subject, clean2$Trial)
for (col in c("Subject", "Trial", "Label", "Matching", "RT_ms", "ACC")) {
  a <- r2k[[col]][o2]; b <- clean2[[col]][oc2]
  eq <- ifelse(is.na(a) & is.na(b), TRUE, !is.na(a) & !is.na(b) & a == b)
  stopifnot(all(eq))
}
cat("  Exp2: raw（subject 2-34）与 Clean 逐值全等 ✓\n")
cat("  Exp2 nonwords-01 保留:", table(raw2$Subject)[["1"]], "行（源数据不完整，见头部注释）\n")

# ============================================================================
# 写出 raw.csv（库内 CRLF 惯例）
# ============================================================================
out1 <- file.path(STUDY_DIR, "Exp1", "Orellana-Corrales_2021_APP_Exp1_raw.csv")
out2 <- file.path(STUDY_DIR, "Exp2", "Orellana-Corrales_2021_APP_Exp2_raw.csv")
stopifnot(!file.exists(out1), !file.exists(out2))   # 目标不存在（防覆盖）
write_clean_csv(raw1, out1)
write_clean_csv(raw2, out2)
cat("完成：\n  ", out1, "\n  ", out2, "\n")
