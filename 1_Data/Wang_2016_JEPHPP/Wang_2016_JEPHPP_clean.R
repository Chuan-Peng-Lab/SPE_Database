# ============================================================================
# Wang_2016_JEPHPP_clean.R — Wang, Humphreys & Sui (2016, JEPHPP) Exp1/Exp2 重建
# ----------------------------------------------------------------------------
# 背景（2026-08 阶段 4 发现）：库内原 Wang Exp1 五件套（raw/Clean/subj_info）
# 数据源错误——实为 AssoMatc_Self 任务数据（31 人，带 person+reward 参数，
# 2013 年收集，非 Wang 2016 任何实验；错误自 Clean_Data.Rmd 初期清洗延续）。
# 旧文件已归档至 1_Data/Wang_2016_JEPHPP_Raw/AssoMatc_Self_archive/。
#
# 本脚本从输入区（Wang_2016_JEPHPP_Raw/）作者 E-Merge 聚合 CSV 重建：
#   Exp1 = 21 人（编号 3-24 缺 23；论文 21 人一致）
#   Exp2 = 25 人（编号 1-25；论文报告 N=20，未公开排除名单，按数据口径 25）
#
# 阶段结构（两阶段均入 Clean；用户 2026-08 决策）：
#   Association（Part 1 学习，行数因人而异，学习到标准）：
#     作者聚合导出无 Label 列（仅 Identity=形状身份 + Shape + ACC/RT），
#     显示标签不可恢复 → Clean 的 Label / Matching 留空（NA）
#   Breaking（Part 2 切换匹配）：
#     Exp1 每被试 657 行 = 前 9 行 practice（9 组合各 1 试次，论文 nine practice trials）
#       + 648 正式（8 blocks x 81 = 9 条件 x 72）
#     Exp2 每被试 648 行（数据无 practice 行）
#
# Matching 规则（新指令映射；方向经论文统计验证一致，2026-08）：
#   Identity 列 = 形状的 Part 1 身份（与 association 数据一致，逐被试固定）
#   Exp1: self-shape->stranger, friend->self, stranger->friend
#   Exp2: self->friend, friend->stranger, stranger->self
#   Match = (Label == f(Identity))
#
# ACC/RT：无反应（Target.RESP=="" 且 Target.RT==0）→ NA；其余原样
# （ACC 1=correct / 0=wrong；RT ms）。Label 列按数据原文（Exp1 大写 / Exp2 小写）。
# ============================================================================

# ---- 引导块：定位脚本目录与 utils.R ----
.args <- commandArgs(trailingOnly = FALSE)
.script_dir <- sub("^--file=", "", .args[grep("^--file=", .args)])
if (length(.script_dir) == 0 || !nzchar(.script_dir)) .script_dir <- getwd()
.script_dir <- normalizePath(dirname(.script_dir))
source(file.path(.script_dir, "..", "utils.R"))
.root <- spe_root(.script_dir)
.study <- "Wang_2016_JEPHPP"
.sdir <- file.path(.root, "1_Data", .study)
.raw_dir <- file.path(.sdir, paste0(.study, "_Raw"))

# ---- 读取作者聚合 CSV ----
read_agg <- function(f) {
  read.csv(file.path(.raw_dir, f), check.names = FALSE, stringsAsFactors = FALSE,
           na.strings = c("", "NA", "NULL"))
}
exp1_assoc <- read_agg("Wang_2016_JEPHPP_Exp1_Association.csv")
exp1_sw    <- read_agg("Wang_2016_JEPHPP_Exp1_Switch.csv")
exp2_assoc <- read_agg("Wang_2016_JEPHPP_Exp2_Association.csv")
exp2_sw    <- read_agg("Wang_2016_JEPHPP_Exp2_Switch.csv")

cat("Exp1 assoc rows:", nrow(exp1_assoc), "| Exp1 switch rows:", nrow(exp1_sw), "\n")
cat("Exp2 assoc rows:", nrow(exp2_assoc), "| Exp2 switch rows:", nrow(exp2_sw), "\n")

# ---- 合并 raw（union 列 + Phase） ----
merge_raw <- function(assoc, sw) {
  # 统一列（assoc 无 Label 列 → 补 NA）
  all_cols <- unique(c(names(assoc), names(sw)))
  for (nm in setdiff(all_cols, names(assoc))) assoc[[nm]] <- NA
  for (nm in setdiff(all_cols, names(sw))) sw[[nm]] <- NA
  assoc$Phase <- "Association"
  sw$Phase    <- "Breaking"
  rbind(assoc[, c(all_cols, "Phase")], sw[, c(all_cols, "Phase")])
}
exp1_raw <- merge_raw(exp1_assoc, exp1_sw)
exp2_raw <- merge_raw(exp2_assoc, exp2_sw)

# ---- 转换 Clean ----
clean_exp <- function(raw, fmap, exp_label) {
  d <- raw
  d$Subject <- as.numeric(d$Subject)
  # Label 原文（association 阶段为空）
  d$Label[is.na(d$Label)] <- ""
  # Matching：breaking 阶段按新指令映射（Exp1/Exp2 的 Label 大小写不同 → 归一比较）
  is_match <- !is.na(d$Identity) & tolower(d$Label) == tolower(fmap[d$Identity])
  is_match[is.na(is_match)] <- FALSE
  d$Matching <- ifelse(d$Phase == "Breaking", ifelse(is_match, "Matching", "Nonmatching"), NA)
  # Practice 标记：Exp1 breaking 每被试前 9 行（9 组合各 1 试次）；Exp2 无
  d$Practice <- 0L
  if (exp_label == "Exp1") {
    keep <- d$Phase == "Breaking"
    d$Practice[keep] <- as.integer(ave(seq_len(sum(keep)), d$Subject[keep], FUN = seq_along) <= 9)
  }
  # 无反应 → ACC/RT/Response NA
  noresp <- !is.na(d$Target.RESP) & d$Target.RESP == ""
  d$ACC <- as.numeric(d$Target.ACC); d$ACC[noresp] <- NA
  d$RT_ms <- as.numeric(d$Target.RT); d$RT_ms[noresp] <- NA
  d$Response <- d$Target.RESP; d$Response[noresp] <- NA
  # Identity 三级（Shape 侧：Identity 列 = 形状 Part 1 身份；Label 侧仅 breaking）
  std_map <- c(Self = "Self", Friend = "Close", Stranger = "Stranger")
  eng_map <- c(Self = "Self", Friend = "Friend", Stranger = "Stranger")
  lab_origin <- d$Label
  lab_origin[lab_origin == ""] <- NA
  lab_eng <- eng_map[tolower(lab_origin)]
  d$Label_Origin_Identity <- lab_origin
  d$Label_English_Identity <- unname(lab_eng)
  d$Label_Standardized_Identity <- unname(std_map[tolower(lab_origin)])
  shp_eng <- eng_map[d$Identity]
  d$Shape_Origin_Identity <- d$Identity
  d$Shape_English_Identity <- unname(shp_eng)
  d$Shape_Standardized_Identity <- unname(std_map[d$Identity])
  # 输出标准列
  out <- data.frame(
    Subject = d$Subject,
    Phase = d$Phase,
    Practice = d$Practice,
    Shape = d$Shape,
    Label = d$Label,
    Matching = d$Matching,
    Label_Origin_Identity = d$Label_Origin_Identity,
    Label_English_Identity = d$Label_English_Identity,
    Label_Standardized_Identity = d$Label_Standardized_Identity,
    Shape_Origin_Identity = d$Shape_Origin_Identity,
    Shape_English_Identity = d$Shape_English_Identity,
    Shape_Standardized_Identity = d$Shape_Standardized_Identity,
    Response = d$Response,
    RT_ms = d$RT_ms,
    RT_sec = d$RT_ms / 1000,
    ACC = d$ACC,
    stringsAsFactors = FALSE
  )
  out
}
exp1_clean <- clean_exp(exp1_raw, c(Self = "Stranger", Friend = "Self", Stranger = "Friend"), "Exp1")
exp2_clean <- clean_exp(exp2_raw, c(Self = "Friend", Friend = "Stranger", Stranger = "Self"), "Exp2")

# ---- 守卫 ----
stopifnot(length(unique(exp1_clean$Subject)) == 21)
stopifnot(length(unique(exp2_clean$Subject)) == 25)
stopifnot(nrow(exp1_clean) == 2050 + 13797)
stopifnot(nrow(exp2_clean) == 1435 + 16200)
# breaking 阶段 Matching 比例 1/3；practice 9 行/被试（Exp1）
br1 <- exp1_clean[exp1_clean$Phase == "Breaking", ]
stopifnot(abs(sum(br1$Matching == "Matching") / nrow(br1) - 1 / 3) < 0.01)
stopifnot(all(tapply(br1$Practice, br1$Subject, sum) == 9))
stopifnot(all(exp2_clean$Practice == 0))

# ---- subj_info ----
make_subj_info <- function(assoc, sw, exp_id) {
  both <- rbind(assoc[, intersect(c("Subject", "Age", "Handedness", "Sex"), names(assoc))],
                sw[, intersect(c("Subject", "Age", "Handedness", "Sex"), names(sw))])
  both$Subject <- as.numeric(both$Subject)
  pick <- function(col) {
    v <- tapply(both[[col]], both$Subject, function(x) {
      x <- x[!is.na(x) & x != ""]
      if (length(x) == 0) "/" else as.character(x[1])
    })
    v[order(as.numeric(names(v)))]
  }
  data.frame(
    Subject_ID = names(pick("Age")),
    Exp_id = exp_id,
    Age = unname(pick("Age")),
    Gender = tolower(unname(pick("Sex"))),
    Handedness = tolower(unname(pick("Handedness"))),
    Ethnicity = "/", Employment_Status = "/", Country = "/",
    First_Language = "/", Education = "/",
    stringsAsFactors = FALSE, row.names = NULL
  )
}
exp1_si <- make_subj_info(exp1_assoc, exp1_sw, "Wang_2016_JEPHPP_Exp1")
exp2_si <- make_subj_info(exp2_assoc, exp2_sw, "Wang_2016_JEPHPP_Exp2")
stopifnot(nrow(exp1_si) == 21, nrow(exp2_si) == 25)

# ---- 写出（多实验布局：每实验一个 ExpN/ 子文件夹，SKILL.md 规范） ----
dir.create(file.path(.sdir, "Exp1"), showWarnings = FALSE)
dir.create(file.path(.sdir, "Exp2"), showWarnings = FALSE)
write_clean_csv(exp1_raw, file.path(.sdir, "Exp1", "Wang_2016_JEPHPP_Exp1_raw.csv"))
write_clean_csv(exp2_raw, file.path(.sdir, "Exp2", "Wang_2016_JEPHPP_Exp2_raw.csv"))
write_clean_csv(exp1_clean, file.path(.sdir, "Exp1", "Wang_2016_JEPHPP_Exp1_Clean.csv"))
write_clean_csv(exp2_clean, file.path(.sdir, "Exp2", "Wang_2016_JEPHPP_Exp2_Clean.csv"))
write_clean_csv(exp1_si, file.path(.sdir, "Exp1", "Wang_2016_JEPHPP_Exp1_subj_info.csv"))
write_clean_csv(exp2_si, file.path(.sdir, "Exp2", "Wang_2016_JEPHPP_Exp2_subj_info.csv"))

cat("DONE. Exp1 rows:", nrow(exp1_clean), "| Exp2 rows:", nrow(exp2_clean), "\n")
cat("Exp1 M/F:", table(exp1_si$Gender), "\n")
cat("Exp2 M/F:", table(exp2_si$Gender), "\n")
