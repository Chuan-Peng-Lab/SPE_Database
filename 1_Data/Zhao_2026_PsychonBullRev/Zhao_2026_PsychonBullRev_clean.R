## Zhao_2026_PsychonBullRev_clean.R
## =====================================================================
## 独立清洗脚本：Zhao_2026_PsychonBullRev（Zhao & Wang, "Beyond the unitary
## self: Behavioral and drift-diffusion modeling evidence for a true
## self-prioritization effect and intra-self competition",
## Psychonomic Bulletin & Review, 2026, DOI 10.3758/s13423-026-03000-8）
##
## 2026-10-13 重写：数据源由 OSF 共享的「作者分析文件（已过滤）」改为
##   作者提供的**原始 PsychoPy 逐被试日志**（输入区，2026-10-13 入库），
##   据库内「最小预处理不删试次/被试」原则重建：
##     - 保留全部正式试次（含无反应与 RT < 200 ms 试次）与练习试次
##     - 保留全部有数据的被试（含作者因低于机遇水平排除的 Exp1 3 人、
##       Exp2 2 人）
##     - 补齐 Shape（形状文件名）、Label（中文标签词）、Block/Trial 编号
##     - 非匹配试次的 Label 身份不再需要 missing（原始日志逐试次记录）
##
## 数据源（输入区 <Folder_Name>_Raw/，只读、不参与校验）：
##   EXP1-true self spe/programming_files/data/*.csv            48 人
##   EXP2-general self spe/programming_files/data/*.csv         49 人
##   EXP3-true self vs general self spe/{true,general}/.../data  22+22 人
##       作者原始 PsychoPy 日志（psychopyVersion 2022.2.4）；文件名前缀 =
##       被试编号（= OSF 文件 subj_idx，已逐试次核验一致）
##   osf_data/behavior_questionnaire_data/exp{1,2,3}_behavior_questionnaire.xlsx
##       年龄/性别（Exp3 另含 exp_task 分组）；Exp2/Exp3 原始日志无人口学列，
##       此为唯一来源；Exp1 两类来源已逐人核验一致
##
## 已核事实（对照论文全文 + 作者程序 SPE.psyexp + 原始日志）：
##   - 任务：shape-label matching（Sui et al., 2012），中文标签呈现
##     Exp1: 3(true self 真实我, general self 一般我, stranger 陌生人) x 2
##     Exp2: 3(general self 一般我, friend 朋友, stranger 陌生人) x 2
##     Exp3: 2(task 组间: true self / general self) x 3(self, friend,
##           stranger) x 2；组内代码 1 = 该组自我标签
##   - 形状-身份绑定与反应键 12 种反平衡组合（作者 group 1-12 =
##     formal/practice_{1..6}{A,B}.xlsx）：1A = 圆-真实我/方-一般我/三角-
##     陌生人、匹配键 z；A/B 为匹配键 z/m 对调。原始日志 `condition` 列记录。
##   - 试次时序（程序内确认）：注视十字 0.5 s（RGB 127,127,127）→ 形状
##     (2.4°x2.4°，画面上方) 与标签（下方）同时呈现 0.1 s → 空屏反应窗 1.1 s
##     → 反馈 0.5 s（反应正确/反应错误/反应过慢）
##   - 分块：360 正式试次，每 60 试次休息屏（程序代码 formal_times in
##     (60,120,180,240,300)；原始日志 key_resp_4.keys == 'space' 出现在
##     formal.thisN = 59/119/179/239/299，双重印证）→ 6 块 x 60
##   - 练习：单段循环「连续正确 6 次」结束（程序 practice_times = 6）；
##     长度因人而异（Exp1 6-224、Exp2 6-335、Exp3 6-314 试次）。**Exp1 有
##     17/48 份日志的练习段结尾不满足「连续正确 6 次」**（均为 2025-03-31
##     之前的场次，疑当时程序版本不同）——练习试次作者分析时已排除，不影响
##     论文结果，已记入 exp JSON detail。
##   - 形状刺激：circle.png / rectangle.png / triangle.png（均 300x300 px；
##     rectangle.png 内白色形状实测 214x213 px 即正方形，与论文文字
##     "circle, square, triangle" 一致，仅文件名沿旧称）
##   - ACC 统一编码：按键正确 1、按键错误 0、无反应 NA（PsychoPy 对无反应
##     记 corr = 0，本脚本按库内规则重编码为 NA）；允许键仅 z/m，无范围外
##     按键记录，故不用 -2/-3/-4
##
## 输出（Exp1/Exp2/Exp3 三个文件夹，各含 raw/Clean/subj_info）：
##   列序对齐 SKILL 模板 v2：Subject → [Group] → Task → Phase → Block →
##   Trial → Matching → Shape → Shape-Identity×3 → Label → Label-Identity×3
##   → CorrResponse → Response → RT_ms → RT_sec → ACC → Counterbalance
##   练习行 Block = NA（先例 Bukowski_2021_ActaPsych）、Trial 为练习段内序号
## =====================================================================

suppressMessages({
  library(data.table)
  library(readxl)
})

## ---- 路径（脚本所在目录自适应） ----------------------------------------------
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script_path)) script_path <- normalizePath(script_path) else script_path <- normalizePath(sys.frame(1)$ofile)
workdir <- dirname(script_path)
setwd(workdir)
STUDY  <- "Zhao_2026_PsychonBullRev"
RAWDIR <- file.path(workdir, paste0(STUDY, "_Raw"))
stopifnot(dir.exists(RAWDIR))

EXP_DIRS <- list(
  Exp1 = file.path(RAWDIR, "EXP1-true self spe", "programming_files", "data"),
  Exp2 = file.path(RAWDIR, "EXP2-general self spe", "programming_files", "data"),
  Exp3 = c(file.path(RAWDIR, "EXP3-true self vs general self spe", "true", "programming_files", "data"),
           file.path(RAWDIR, "EXP3-true self vs general self spe", "general", "programming_files", "data"))
)
EXP_GROUP <- list(Exp1 = NULL,
                  Exp2 = NULL,
                  Exp3 = c("true self task", "general self task"))
BEH_DIR <- file.path(RAWDIR, "osf_data", "behavior_questionnaire_data")
for (p in c(unlist(EXP_DIRS), BEH_DIR)) stopifnot(dir.exists(p))

## 中文标签词 → 英文 / Std 6 类词表
EN_MAP  <- c("真实我" = "true self", "一般我" = "general self",
             "朋友" = "friend", "陌生人" = "stranger")
STD_MAP <- c("真实我" = "Self", "一般我" = "Self",
             "朋友" = "Close", "陌生人" = "Stranger")

## ---- 读取单份原始日志 --------------------------------------------------------
read_log <- function(f) {
  d <- fread(f, encoding = "UTF-8", na.strings = c("", "NA"), showProgress = FALSE)
  d <- d[!is.na(phase)]                       # 去掉文件首尾的空行（无 phase）
  stopifnot(all(d$phase %in% c("practice", "formal")))
  ## 练习段在正式段之前
  stopifnot(!any(diff(as.integer(factor(d$phase, levels = c("practice", "formal")))) < 0))
  d[, Source_File := basename(f)]
  d[]
}

## ---- 单份日志 → Clean 行 -----------------------------------------------------
prep_one <- function(d, exp_id, group = NA_character_) {
  ## 身份码 ↔ 标签词 双射（逐被试核验，防止跨实验假设码义一致）
  m <- unique(d[!is.na(label_identity), .(code = as.character(label_identity), word = label)])
  stopifnot(nrow(m) == 3L, uniqueN(m$code) == 3L, uniqueN(m$word) == 3L)
  stopifnot(all(unique(as.character(d$shape_identity)) %in% m$code))
  stopifnot(all(unique(m$word) %in% names(EN_MAP)))

  is_formal <- d$phase == "formal"
  stopifnot(sum(is_formal) == 360L, identical(sort(d$formal.thisN[is_formal]), 0:359))
  ## 匹配试次 shape 身份 == label 身份；非匹配 !=
  stopifnot(all((as.character(d$shape_identity) == as.character(d$label_identity)) == (d$match == 1L)))

  ## 实际按键 / RT / ACC（练习用 key_resp.*，正式用 key_resp_formal.*）
  keys <- rep(NA_character_, nrow(d))
  rt   <- rep(NA_real_,    nrow(d))
  keys[is_formal] <- d$key_resp_formal.keys[is_formal]
  rt[is_formal]   <- d$key_resp_formal.rt[is_formal]
  keys[!is_formal] <- d$key_resp.keys[!is_formal]
  rt[!is_formal]   <- d$key_resp.rt[!is_formal]
  keys[!is.na(keys) & keys %in% c("None", "")] <- NA_character_
  stopifnot(all(na.omit(keys) %in% c("z", "m")))          # 允许键仅 z/m
  stopifnot(all(is.na(rt) | (rt > 0 & rt < 1100/1000 + 0.2)))
  resp <- keys
  acc  <- ifelse(is.na(resp), NA_integer_, as.integer(resp == d$correct))

  ## 分块：正式 = 每 60 试次一块；练习 = 单段（Block 记 NA）
  blk <- rep(NA_integer_, nrow(d))
  blk[is_formal] <- d$formal.thisN[is_formal] %/% 60L + 1L
  trl <- integer(nrow(d))
  trl[is_formal]  <- d$formal.thisN[is_formal] %% 60L + 1L
  trl[!is_formal] <- seq_len(sum(!is_formal))

  ## 休息屏位置核验：formal.thisN 59/119/179/239/299 上有空格键
  rest <- d$formal.thisN[is_formal][!is.na(d$key_resp_4.keys[is_formal]) &
                                      d$key_resp_4.keys[is_formal] == "space"]
  stopifnot(identical(sort(as.integer(rest)), c(59L, 119L, 179L, 239L, 299L)))

  shp_word <- m$word[match(as.character(d$shape_identity), m$code)]
  lab_word <- m$word[match(as.character(d$label_identity), m$code)]
  out <- data.table(
    Subject = as.integer(d$ID),
    Task    = "self-matching",
    Phase   = d$phase,
    Block   = blk,
    Trial   = trl,
    Matching = ifelse(d$match == 1L, "Matching", "Nonmatching"),
    Shape    = d$shape,
    Shape_Origin_Identity       = as.character(d$shape_identity),
    Shape_English_Identity      = unname(EN_MAP[shp_word]),
    Shape_Standardized_Identity = unname(STD_MAP[shp_word]),
    Label                       = d$label,
    Label_Origin_Identity       = d$label,
    Label_English_Identity      = unname(EN_MAP[lab_word]),
    Label_Standardized_Identity = unname(STD_MAP[lab_word]),
    CorrResponse = d$correct,
    Response     = resp,
    RT_ms        = rt * 1000,
    RT_sec       = rt,
    ACC          = acc,
    Counterbalance = d$condition
  )
  if (!is.na(group)) {                       # 模板 v2：[Group] 紧随 Subject
    out[, Group := group]
    setcolorder(out, c("Subject", "Group", setdiff(names(out), c("Subject", "Group"))))
  }
  out[]
}

## ---- 读一个实验的全部日志 ----------------------------------------------------
build_exp <- function(exp_id) {
  dirs <- EXP_DIRS[[exp_id]]
  groups <- EXP_GROUP[[exp_id]]
  if (is.null(groups)) groups <- rep(NA_character_, length(dirs))
  parts <- list()
  for (i in seq_along(dirs)) {
    fs <- list.files(dirs[i], pattern = "\\.csv$", full.names = TRUE)
    fs <- fs[order(as.integer(sub("_.*$", "", basename(fs))))]     # 按被试编号排序
    for (f in fs) parts[[length(parts) + 1L]] <- prep_one(read_log(f), exp_id, groups[i])
  }
  dt <- rbindlist(parts, fill = TRUE, use.names = TRUE)
  if (!is.null(EXP_GROUP[[exp_id]])) dt[, Group := factor(Group, levels = EXP_GROUP[[exp_id]])]
  dt[, .ord := seq_len(.N)]
  setorderv(dt, c("Subject", ".ord"))
  dt[, .ord := NULL]
  dt[]
}

## ---- 人口学 ----------------------------------------------------------------
read_beh <- function(exp_id) {
  f <- file.path(BEH_DIR, sprintf("exp%d_behavior_questionnaire.xlsx",
                                  as.integer(sub("^Exp", "", exp_id))))
  d <- as.data.table(read_excel(f, sheet = 1))
  junk <- grepl("^Unnamed|^\\.\\.\\.", names(d)); if (any(junk)) d <- d[, !junk, with = FALSE]
  d
}
make_subj_info <- function(clean, exp_id, raw_logs = NULL) {
  ids <- sort(unique(clean$Subject))
  si  <- data.table(Subject_ID = ids)
  beh <- read_beh(exp_id)
  has_task <- "exp_task" %in% names(beh)          # 仅 Exp3 的汇总文件含任务分组
  si  <- merge(si, beh[, .(Subject_ID = as.integer(id), Age = as.numeric(age),
                           Gender = fifelse(gender == 1, "Male", fifelse(gender == 2, "Female", "/")),
                           beh_group = if (has_task) exp_task else NA_integer_)],
               by = "Subject_ID", all.x = TRUE)
  if (!is.null(raw_logs)) {                       # Exp1：原始日志有年龄/性别/利手
    si <- merge(si, raw_logs, by = "Subject_ID", all.x = TRUE)
    si[!is.na(Age_raw), Age := Age_raw]
    si[!is.na(Gender_raw), Gender := Gender_raw]
    si[, c("Age_raw", "Gender_raw") := NULL]
  }
  si[is.na(Age), Age := NA_real_]
  si[is.na(Gender), Gender := "/"]
  ## subj_info 的人口学缺失统一写 "/"（SKILL §数据标准化）
  si[, Age := fifelse(is.na(Age), "/", as.character(Age))]
  si[, `:=`(Exp_id = exp_id,
            Handedness = if ("Handedness_raw" %in% names(si)) Handedness_raw else "/",
            Ethnicity = "/", Country = "/", First_Language = "/")]
  if ("Handedness_raw" %in% names(si)) si[is.na(Handedness_raw), Handedness := "/"]
  if (has_task) {
    stopifnot(all(!is.na(si$beh_group)))          # Exp3：behavior 文件含分组
    si[, Group := fifelse(beh_group == 1, "true self task", "general self task")]
  }
  cols <- c("Subject_ID", "Exp_id")
  if ("Group" %in% names(si)) cols <- c(cols, "Group")
  cols <- c(cols, "Age", "Gender", "Handedness", "Ethnicity", "Country", "First_Language")
  setorderv(si, "Subject_ID")
  si[, ..cols]
}

## ---- Exp1 人口学（来自原始日志；Exp2/Exp3 日志无人口学列，返回 NULL） --------
raw_demo <- function(exp_id) {
  dirs <- EXP_DIRS[[exp_id]]
  fs <- unlist(lapply(dirs, list.files, pattern = "\\.csv$", full.names = TRUE))
  res <- rbindlist(lapply(fs, function(f) {
    d <- fread(f, encoding = "UTF-8", na.strings = c("", "NA"), showProgress = FALSE)
    if (!"年龄" %in% names(d)) return(NULL)
    d <- d[!is.na(年龄)]
    if (!nrow(d)) return(NULL)
    data.table(Subject_ID = as.integer(d$ID[1]),
               Age_raw = as.numeric(d$`年龄`[1]),
               Gender_raw = fifelse(d$`性别（男1，女2）`[1] == 1, "Male",
                                    fifelse(d$`性别（男1，女2）`[1] == 2, "Female", "/")),
               Handedness_raw = fifelse(d$`利手（右1，左2）`[1] == 1, "Right",
                                        fifelse(d$`利手（右1，左2）`[1] == 2, "Left", "/")))
  }))
  if (is.null(res) || !nrow(res)) return(NULL)
  res
}

## ---- 写出 -------------------------------------------------------------------
write_exp <- function(exp_id, clean, raw_dt, si) {
  dir.create(exp_id, showWarnings = FALSE)
  fwrite(clean,  file.path(exp_id, sprintf("%s_%s_Clean.csv", STUDY, exp_id)), na = "NA")
  fwrite(si,     file.path(exp_id, sprintf("%s_%s_subj_info.csv", STUDY, exp_id)), na = "NA")
  fwrite(raw_dt, file.path(exp_id, sprintf("%s_%s_raw.csv", STUDY, exp_id)), na = "NA")
  cat(sprintf(">>> %s: Clean %d rows / %d subj (%d practice) ; raw %d rows ; subj_info %d\n",
              exp_id, nrow(clean), uniqueN(clean$Subject),
              sum(clean$Phase == "practice"), nrow(raw_dt), nrow(si)))
}

## ---- 作者原始日志的合并（标准 raw：作者列名原样 + Source_File） --------------
RAW_COLS <- c("ID", "phase", "condition", "group", "label", "shape", "correct", "match",
              "label_identity", "shape_identity",
              "practice.thisRepN", "practice.thisTrialN", "practice.thisN", "practice.thisIndex",
              "formal.thisRepN", "formal.thisTrialN", "formal.thisN", "formal.thisIndex",
              "key_resp.keys", "key_resp.corr", "key_resp.rt",
              "key_resp_formal.keys", "key_resp_formal.corr", "key_resp_formal.rt",
              "年龄", "性别（男1，女2）", "利手（右1，左2）",
              "date", "expName", "psychopyVersion", "frameRate", "Source_File")
merge_raw <- function(exp_id) {
  dirs <- EXP_DIRS[[exp_id]]
  fs <- unlist(lapply(dirs, list.files, pattern = "\\.csv$", full.names = TRUE))
  fs <- fs[order(as.integer(sub("_.*$", "", basename(fs))))]
  dt <- rbindlist(lapply(fs, read_log), fill = TRUE, use.names = TRUE)
  keep <- intersect(RAW_COLS, names(dt))
  dt <- dt[, ..keep]
  setorderv(dt, "ID")
  dt[]
}

## ============================ 主流程 =========================================
EXPECT_SUBJ <- c(Exp1 = 48, Exp2 = 49, Exp3 = 44)
EXPECT_OSF  <- c(Exp1 = 15659L, Exp2 = 16528L, Exp3 = 15376L)   # 作者 OSF 分析文件行数
OSF_EXCLUDED <- list(Exp1 = c(7L, 46L, 48L), Exp2 = c(14L, 49L), Exp3 = integer(0))

for (exp_id in c("Exp1", "Exp2", "Exp3")) {
  clean <- build_exp(exp_id)
  stopifnot(uniqueN(clean$Subject) == EXPECT_SUBJ[[exp_id]])
  stopifnot(!anyNA(clean$Subject), !anyNA(clean$Matching), !anyNA(clean$Shape),
            !anyNA(clean$Label), !anyNA(clean$ACC[clean$Phase == "formal" &
                                                   !is.na(clean$Response)]))
  ## 一致性检查：ACC == (Response == CorrResponse)（有反应处）
  stopifnot(all(clean[!is.na(Response), ACC == as.integer(Response == CorrResponse)]))
  ## 键唯一性 (Subject, Phase, Block, Trial)
  stopifnot(!anyDuplicated(clean[, .(Subject, Phase, Block, Trial)]))
  ## 与作者 OSF 分析文件逐行对应（同一来源、同一过滤口径）
  kept <- clean[Phase == "formal" & !is.na(Response) & RT_sec >= 0.2 &
                  !(Subject %in% OSF_EXCLUDED[[exp_id]])]
  stopifnot(nrow(kept) == EXPECT_OSF[[exp_id]])
  cat(sprintf("[%s] Clean %d 行 / %d 人；其中正式 %d、练习 %d；作者分析口径 %d 行\n",
              exp_id, nrow(clean), uniqueN(clean$Subject),
              sum(clean$Phase == "formal"), sum(clean$Phase == "practice"), nrow(kept)))

  si <- make_subj_info(clean, exp_id, raw_logs = raw_demo(exp_id))
  stopifnot(nrow(si) == uniqueN(clean$Subject), !anyNA(si$Subject_ID))
  write_exp(exp_id, clean, merge_raw(exp_id), si)
}

cat("\n==== Zhao_2026_PsychonBullRev cleaning complete ====\n")
