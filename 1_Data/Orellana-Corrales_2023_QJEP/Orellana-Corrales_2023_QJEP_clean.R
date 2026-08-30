# ============================================================================
# Orellana-Corrales_2023_QJEP — 独立清洗脚本（入库，SKILL 场景 B）
# ----------------------------------------------------------------------------
# 背景（2026-08 阶段 5 入库）：QJEP 2023（"Does an experimentally induced
# self-association elicit affective self-prioritisation?", QJEP 83: 1084–1094,
# DOI 10.1177/17470218221124928）原为 pending 条目，OSF 官方仓库
# （osf.io/v8r2p, "Affective prioritization of self"）完整存档已下载至输入区
# （Orellana-Corrales_2023_QJEP_raw/v8r2p-osfstorage-data-archive/）。本脚本
# 从 PsychoPy 每被试原始导出（data_raw/v1-v8/*.csv，v1-v8 = exp_v 版本 1-8）
# 解析匹配任务（Sui 2012 范式：shape-label 配对判断）trial 级数据，重建
# 标准 raw.csv / Clean.csv / subj_info.csv。
#
# 数据要点：
#   1. 被试编号与作者 data_merged.tsv 完全一致：按作者合并顺序
#      （v1→v8、每目录文件字母序）rbind 后取 unique(date) 依次编号 1..136
#      （作者 1-mergeAndSubset.R：subject = as.integer(factor(date,
#      levels=unique(date)))）；脚本内置逐值对比守卫保证编号对齐。
#   2. 匹配任务：每被试 4 练习试次（MT_p.*，剔除）+ 140 实验试次
#      （MT.corr 非空；bed 四条件 i_m/i_n/f_m/f_n 各 35，论文 L95
#      "4 practice + 140 experimental trials"）。
#      无反应试次（MT.keys 空、MT.corr=0、MT.rt 空）：raw 保留原值
#      （ACC=0、RT_ms=NA）；Clean 按项目 ACC 统一编码（P21 方案 A）
#      无反应 -> NA（有明确证据：PsychoPy 无按键记录）。
#   3. 刺激字段：label = "Ich"/"Möbel"（德语，论文 L72/L95）、
#      bild = Kreis1-5.png/Dreieck1-5.png（circle/triangle × 5 种填充
#      pattern，论文 L72）——data_merged.tsv 已丢弃这两列，故从原始 csv 重建。
#   4. 身份映射（bed 编码 shape 关联身份，作者 2-dataprep_mt.py 同口径）：
#      bed i_* = shape 关联 self、f_* = 关联 furniture；m/n = 匹配/非匹配。
#      Shape 侧身份 = bed 首字母，Label 侧 = label 列实际词。
#      Origin: Ich/Möbel（原文）-> English: self/furniture ->
#      Standardized: Self/NonPerson（furniture 为非人对象类）。
#   5. 论文分析样本（SPSS 3-Syntax.sps 硬编码排除名单，raw/Clean 不过滤，
#      供 Note 引用）：29 名 Tukey 离群（1.5×IQR 口径）排除 -> N=107；
#      words 组排除 16 名（71->55）、shapes 组排除 13 名（65->52），
#      与论文 t(54)/t(51)、F(1,106) 吻合。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Orellana-Corrales_2023_QJEP_clean.R
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

STUDY_DIR <- file.path(spe_root(), "1_Data", "Orellana-Corrales_2023_QJEP")
stopifnot(dir.exists(STUDY_DIR))

RAW_DIR <- file.path(STUDY_DIR, "Orellana-Corrales_2023_QJEP_raw",
                     "v8r2p-osfstorage-data-archive", "data_raw")
stopifnot(dir.exists(RAW_DIR))

# ============================================================================
# 1. 读取全部 PsychoPy csv（作者合并顺序：v1→v8、每目录文件字母序）
# ============================================================================
cat("== 读取 data_raw/v1-v8 全部 csv ...\n")
csv_files <- unlist(lapply(sprintf("v%d", 1:8), function(v) {
  p <- file.path(RAW_DIR, v)
  sort(list.files(p, pattern = "\\.csv$", full.names = TRUE))
}))
cat("   csv 文件数:", length(csv_files), "(预期 136)\n")
stopifnot(length(csv_files) == 136)

read_psycopy <- function(p) {
  d <- read.csv(p, stringsAsFactors = FALSE, check.names = FALSE,
                fileEncoding = "UTF-8-BOM")
  # 每被试人口学/组信息（各行重复出现，取首个非空）
  get1 <- function(col) {
    v <- d[[col]]
    v <- v[!is.na(v) & nzchar(trimws(v))]
    if (length(v)) v[1] else NA_character_
  }
  list(
    date = get1("date"),
    sex = get1("Geschlecht"),
    hand = get1("Händigkeit"),
    yob = get1("Geburtsjahr (JJJJ)"),
    type = get1("type"),
    rows = d
  )
}

raw_list <- lapply(csv_files, read_psycopy)

# ---- 被试编号（作者口径：按合并行序 unique(date)） ----
dates <- vapply(raw_list, function(x) x$date, character(1))
stopifnot(!anyNA(dates), length(unique(dates)) == 136)
subj_of <- setNames(seq_along(unique(dates)), unique(dates))

# ============================================================================
# 2. 提取匹配实验试次（MT.corr 非空；剔除 MT_p 练习行）
# ============================================================================
MT_BEDS <- c("i_m", "i_n", "f_m", "f_n")
extract_mt <- function(x, subj) {
  d <- x$rows
  mt <- d[!is.na(d$MT.corr) & nzchar(trimws(d$MT.corr)), , drop = FALSE]
  stopifnot(nrow(mt) == 140)                       # 140 实验试次/被试
  stopifnot(all(mt$bed %in% MT_BEDS))
  stopifnot(all(table(mt$bed) == 35))              # 每条件 35
  m <- match(mt$bed, c("i_m", "f_m", "i_n", "f_n"))  # 顺序：match 先于 nonmatch
  matching <- ifelse(mt$bed %in% c("i_m", "f_m"), "Matching", "Nonmatching")
  rt_ms <- suppressWarnings(round(as.numeric(mt$MT.rt) * 1000))
  rt_ms[is.na(mt$MT.rt) | !nzchar(trimws(mt$MT.rt))] <- NA_integer_
  data.frame(
    Subject = subj,
    Trial = seq_len(nrow(mt)),
    Shape = mt$bild,
    Label = mt$label,
    Matching = matching,
    ACC = as.integer(mt$MT.corr),
    RT_ms = rt_ms,
    bed = mt$bed,
    Ass = mt$Ass,
    Group = x$type,
    stringsAsFactors = FALSE
  )
}

raw_all <- do.call(rbind, lapply(seq_along(raw_list), function(i) {
  extract_mt(raw_list[[i]], subj_of[[raw_list[[i]]$date]])
}))
rownames(raw_all) <- NULL
cat("   raw 行数:", nrow(raw_all), "(预期 19040 = 136×140)\n")
stopifnot(nrow(raw_all) == 136 * 140)

# ============================================================================
# 3. 强验证：与作者 data_merged.tsv 逐值对比（subject 编号 + bed + corr + rt）
# ============================================================================
cat("== 与 data_merged.tsv 逐值对比 ...\n")
merged_path <- file.path(STUDY_DIR, "Orellana-Corrales_2023_QJEP_raw",
                         "v8r2p-osfstorage-data-archive", "data_merged.tsv")
stopifnot(file.exists(merged_path))
mg <- read.delim(merged_path, stringsAsFactors = FALSE, check.names = FALSE,
                 fileEncoding = "UTF-8-BOM", na.strings = "")
mg <- mg[mg$bed %in% MT_BEDS & !is.na(mg$MT.corr) & nzchar(mg$MT.corr), ]
stopifnot(nrow(mg) == 19040)
o <- order(mg$subject, mg$bed, seq_len(nrow(mg)))
mg <- mg[order(mg$subject), ]
# data_merged.tsv 的 MT.rt 已是毫秒整数（作者 1-mergeAndSubset.R 已 ×1000 取整）
mg$mt_rt_ms <- suppressWarnings(as.integer(mg$MT.rt))

stopifnot(all(mg$subject == raw_all$Subject))         # 编号一致（同被试同号）
stopifnot(all(mg$bed == raw_all$bed))
stopifnot(all(as.integer(mg$MT.corr) == raw_all$ACC))
stopifnot(all(is.na(mg$mt_rt_ms) == is.na(raw_all$RT_ms)))
eq <- which(!is.na(mg$mt_rt_ms))
stopifnot(all(mg$mt_rt_ms[eq] == raw_all$RT_ms[eq]))
cat("   ✓ 与 data_merged.tsv 逐值全等（subject/bed/MT.corr/MT.rt×1000）\n")

# ============================================================================
# 4. 生成 Clean（+ Identity 三级；ACC 按 P21 无反应 -> NA）
# ============================================================================
cat("== 生成 Clean ...\n")
# 无反应：PsychoPy 中 MT.keys 空（corr=0 且 rt 空）——需从原始行取 MT.keys
mt_keys <- lapply(seq_along(raw_list), function(i) {
  d <- raw_list[[i]]$rows
  mt <- d[!is.na(d$MT.corr) & nzchar(trimws(d$MT.corr)), , drop = FALSE]
  !is.na(mt$MT.keys) & nzchar(trimws(mt$MT.keys))
})
keys_all <- unlist(mt_keys)
stopifnot(length(keys_all) == nrow(raw_all))

orig_map <- c(i_m = "Ich", f_m = "Möbel", i_n = "Ich", f_n = "Möbel")
eng_map  <- c(Ich = "self", Möbel = "furniture")
std_map  <- c(self = "Self", furniture = "NonPerson")

clean <- data.frame(
  Subject = raw_all$Subject,
  Trial = raw_all$Trial,
  Shape = raw_all$Shape,
  Label = raw_all$Label,
  Matching = raw_all$Matching,
  Shape_Origin_Identity = unname(orig_map[raw_all$bed]),
  Shape_English_Identity = unname(eng_map[orig_map[raw_all$bed]]),
  Shape_Standardized_Identity = unname(std_map[eng_map[orig_map[raw_all$bed]]]),
  Label_Origin_Identity = raw_all$Label,
  Label_English_Identity = unname(eng_map[raw_all$Label]),
  Label_Standardized_Identity = unname(std_map[eng_map[raw_all$Label]]),
  RT_ms = raw_all$RT_ms,
  RT_sec = raw_all$RT_ms / 1000,
  ACC = ifelse(keys_all, raw_all$ACC, NA_integer_),   # 无反应 -> NA（P21）
  stringsAsFactors = FALSE
)
stopifnot(all(clean$Shape_Standardized_Identity %in% c("Self", "NonPerson")))
stopifnot(all(clean$Label_Standardized_Identity %in% c("Self", "NonPerson")))
cat("   Clean 行数:", nrow(clean), "| 无反应(ACC=NA)行:", sum(is.na(clean$ACC)), "\n")

# ============================================================================
# 5. subj_info（136 名；年龄 = 2020−出生年，作者 3-Syntax.sps 同口径）
# ============================================================================
cat("== 生成 subj_info ...\n")
sex_map  <- c(Weiblich = "female", Männlich = "male")
hand_map <- c(links = "left", rechts = "right", beides = "both")
grp_map  <- c(words = "familiar (words)", shapes = "new (shapes)")
# 出生年解析：被试自由输入，含德语日期格式（dd.mm.yyyy）；5 位手误（如
# "19998"）无法确定 -> NA（2026-08 入库核实时发现，Codebook/Note 注明）
parse_yob <- function(v) {
  v <- trimws(v)
  if (is.na(v) || !nzchar(v)) return(NA_integer_)
  m <- regmatches(v, regexec("^(\\d{1,2})\\.(\\d{1,2})\\.(\\d{4})$", v))[[1]]
  if (length(m) == 4) return(as.integer(m[4]))
  if (grepl("^\\d{4}$", v)) return(as.integer(v))
  NA_integer_
}
subj_info <- data.frame(
  Subject_ID = seq_along(raw_list),
  Exp_id = "Orellana-Corrales_2023_QJEP_Exp1",
  Age = vapply(raw_list, function(x) 2020 - parse_yob(x$yob), numeric(1)),
  Gender = vapply(raw_list, function(x) unname(sex_map[x$sex]), character(1)),
  Handedness = vapply(raw_list, function(x) unname(hand_map[x$hand]), character(1)),
  Ethnicity = "/", Employment_Status = "/",
  Country = "Germany", First_Language = "German", Education = "/",
  Group = vapply(raw_list, function(x) unname(grp_map[x$type]), character(1)),
  stringsAsFactors = FALSE
)
stopifnot(nrow(subj_info) == 136)
cat("   subj_info 行数:", nrow(subj_info),
    "| 组分布:", paste(names(table(subj_info$Group)), table(subj_info$Group),
                       sep = "=", collapse = ", "), "\n")
stopifnot(table(subj_info$Group)[["familiar (words)"]] == 71)
stopifnot(table(subj_info$Group)[["new (shapes)"]] == 65)

# ============================================================================
# 6. 写出（防覆盖 + CRLF 惯例）
# ============================================================================
out_raw <- file.path(STUDY_DIR, "Orellana-Corrales_2023_QJEP_Exp1_raw.csv")
out_clean <- file.path(STUDY_DIR, "Orellana-Corrales_2023_QJEP_Exp1_Clean.csv")
out_subj <- file.path(STUDY_DIR, "Orellana-Corrales_2023_QJEP_Exp1_subj_info.csv")
stopifnot(!file.exists(out_raw), !file.exists(out_clean), !file.exists(out_subj))
write_clean_csv(raw_all, out_raw)
write_clean_csv(clean, out_clean)
write_clean_csv(subj_info, out_subj)
cat("完成：\n  ", out_raw, "\n  ", out_clean, "\n  ", out_subj, "\n")
