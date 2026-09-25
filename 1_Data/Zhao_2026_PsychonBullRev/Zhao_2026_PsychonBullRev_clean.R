## Zhao_2026_PsychonBullRev_clean.R
## =====================================================================
## 独立清洗脚本：Zhao_2026_PsychonBullRev（Yue Zhao & Fei Wang,
## "Beyond the unitary self: Behavioral and drift–diffusion modeling
##  evidence for a true self-prioritization effect and intra-self
##  competition", Psychonomic Bulletin & Review, 2026,
##  DOI 10.3758/s13423-026-03000-8）
##
## 数据源：OSF https://osf.io/j2pxc/ （论文 Data availability 的匿名
##   view-only 链接，2026-09-09 下载，归档保存于本文件夹 *_Raw/ 输入区）
##   - data/hddm_trial_data/exp{1,2,3}_hddm_trial_data.xlsx
##       作者共享的试次级分析文件（HDDM 建模输入；含列 match /
##       shape_identity / corr / rt / subj_idx / response，Exp3 另有 task）
##   - data/behavior_questionnaire_data/exp{1,2,3}_behavior_questionnaire.xlsx
##       逐被试条件汇总（rt/acc/re）+ 人口学（gender/age）+ 问卷（BTS/SEB/SCS）
##
## 已核事实（2026-09-09，对照论文全文 + Crossref + 作者行为汇总文件）：
##   - 三实验均为 shape-label matching（Sui et al., 2012）：
##     Exp1: 3(true self, general self, stranger) x 2(matching, nonmatching)
##           within-subject；正式 360 试次/人（6 blocks x 60；60/条件）
##     Exp2: 3(general self, friend, stranger) x 2 同上
##     Exp3: 2(task: true self vs general self, between) x
##           3(self, friend, stranger) x 2 同上
##   - 身份编码（作者数据字典）：Exp1: 1=true self, 2=general self, 3=stranger；
##     Exp2: 1=general self, 2=friend, 3=stranger；
##     Exp3: task=1 true self task / task=2 general self task，组内
##     1=self(真我或一般我), 2=friend, 3=stranger
##   - corr == (match == response) 在三个文件中 100% 成立 → response 即
##     语义反应键（1 = 按"匹配"键；0 = 按"不匹配"键），corr = 正确性
##   - 人口学与论文一致：Exp1 N=45（33 F），Exp2 N=47（29 F），
##     Exp3 N=44（19 F，两任务组各 22）；行为汇总文件逐值与论文一致
##   - 注意（同 Golubickis_2021 先例）：OSF 试次文件为作者分析用文件，
##     只保留有反应且 RT >= 200 ms 的试次（无反应/过早反应试次作者已剔除，
##     故每被试 < 360 行，缺行均为错误/无反应试次）；无 block/trial 编号；
##     无逐试次形状几何与标签文字（形状-身份绑定 counterbalanced、未记录）
##   - 屏幕呈现语言/具体标签文字、实验软件待作者确认（2026-09-09 已去信）
##
## 输出（3 个实验文件夹，每个含 raw/Clean/subj_info 三 CSV；列序对齐
##   SKILL 模板 v2；shape/label 原刺激不可得 → missing，身份信息由
##   Identity 三层承载）：
##   Exp1/Exp2: self-matching（Task=self-matching；身份见上）
##   Exp3:      self-matching，组间任务用 Group 列
## =====================================================================

suppressMessages(library(data.table))
suppressMessages(library(readxl))

## ---- 路径（脚本所在目录自适应，与 Lee_2026 同款引导） ------------------------
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script_path)) script_path <- normalizePath(script_path) else script_path <- normalizePath(sys.frame(1)$ofile)
workdir <- dirname(script_path)
setwd(workdir)
stopifnot(dir.exists(file.path(workdir, "Zhao_2026_PsychonBullRev_Raw", "data")))
raw_trial <- file.path(workdir, "Zhao_2026_PsychonBullRev_Raw", "data", "hddm_trial_data")
raw_beh   <- file.path(workdir, "Zhao_2026_PsychonBullRev_Raw", "data", "behavior_questionnaire_data")
STUDY <- "Zhao_2026_PsychonBullRev"

## ---- 通用：身份词与 Std 映射 --------------------------------------------------
std_map <- c("true self" = "Self", "general self" = "Self", "self" = "Self",
             "friend" = "Close", "stranger" = "Stranger")

## 读取某实验试次文件（丢弃作者多余的空白/Unnamed 列）
read_trial <- function(exp) {
  f <- file.path(raw_trial, sprintf("exp%d_hddm_trial_data.xlsx", exp))
  d <- as.data.table(read_excel(f, sheet = 1))
  junk <- grepl("^Unnamed|^\\.\\.\\.", names(d))
  if (any(junk)) d <- d[, !junk, with = FALSE]
  d
}

## 读取某实验行为汇总（含人口学）
read_beh <- function(exp) {
  f <- file.path(raw_beh, sprintf("exp%d_behavior_questionnaire.xlsx", exp))
  d <- as.data.table(read_excel(f, sheet = 1))
  junk <- grepl("^Unnamed|^\\.\\.\\.", names(d))
  if (any(junk)) d <- d[, !junk, with = FALSE]
  d
}

## 基础派生：Subject/Matching/ACC/RT/Response + 断言
build_base <- function(d, exp_code, identity_map, response_ok = c(0, 1)) {
  ## 身份码合法性
  stopifnot(all(d$shape_identity %in% as.integer(names(identity_map))))
  stopifnot(all(d$match %in% c(0, 1)))
  stopifnot(all(d$response %in% response_ok))
  stopifnot(all(d$corr == as.integer(d$match == d$response)))   # corr 口径核验
  stopifnot(all(d$rt >= 0.2, na.rm = TRUE))                     # 作者已剔 RT<200ms
  stopifnot(!anyNA(d[, .(match, shape_identity, corr, rt, subj_idx, response)]))
  d[, `:=`(
    Subject = subj_idx,
    Matching = ifelse(match == 1L, "Matching", "Nonmatching"),
    RT_ms = rt * 1000,
    RT_sec = rt,
    ACC = as.integer(corr),
    ## 身份三层：形状侧 = shape 的联结身份（作者码）；Origin 词 = 作者
    ## 数据字典英文词（屏幕呈现语言/文字待作者确认，2026-09-09 已去信）
    Shape_Origin_Identity       = unname(identity_map[as.character(shape_identity)]),
    Shape_English_Identity      = unname(identity_map[as.character(shape_identity)]),
    Shape_Standardized_Identity = unname(std_map[identity_map[as.character(shape_identity)]])
  )]
  ## Label 侧身份：Matching 试次 = 形状自身身份词（联结一致的定义使然）；
  ## Nonmatching 试次共享文件未记录所配标签身份 → missing
  d[, `:=`(
    Label_Origin_Identity       = ifelse(match == 1L, Shape_Origin_Identity, "missing"),
    Label_English_Identity      = ifelse(match == 1L, Shape_English_Identity, "missing"),
    Label_Standardized_Identity = ifelse(match == 1L, Shape_Standardized_Identity, "missing")
  )]
  cat(sprintf("[Exp%s] rows=%d subjects=%d\n", exp_code, nrow(d),
              length(unique(d$Subject))))
  d
}

## ---- Exp1 / Exp2（被试内 3x2） -----------------------------------------------
make_within <- function(exp, identity_map) {
  d <- read_trial(exp)
  d <- build_base(d, as.character(exp), identity_map)
  beh <- read_beh(exp)
  stopifnot(sort(unique(d$Subject)) == sort(unique(beh$id)))
  d[, Task := "self-matching"]
  clean <- d[, .(
    Subject, Task, Matching,
    Shape = "missing",
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label = "missing",
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Response = as.integer(response),
    RT_ms, RT_sec, ACC
  )]
  setorderv(clean, "Subject")
  stopifnot(nrow(clean) == nrow(d))
  list(clean = clean, beh = beh)
}

## ---- Exp3（任务组间） ---------------------------------------------------------
make_exp3 <- function() {
  d <- read_trial(3)
  beh <- read_beh(3)
  stopifnot(all(d$task %in% c(1, 2)))
  stopifnot(sort(unique(d$subj_idx)) == sort(unique(beh$id)))
  map_by_task <- list(
    `1` = c("1" = "true self",    "2" = "friend", "3" = "stranger"),
    `2` = c("1" = "general self", "2" = "friend", "3" = "stranger")
  )
  ## 按任务组分别走 build_base（断言/派生一致），再合并 + Group 列
  parts <- lapply(sort(unique(d$task)), function(t) {
    sub <- d[task == t]
    b <- build_base(sub, "3", map_by_task[[as.character(t)]])
    b[, Group := if (t == 1) "true self task" else "general self task"]
    b
  })
  dd <- rbindlist(parts)
  stopifnot(nrow(dd) == nrow(d))
  dd[, Task := "self-matching"]
  clean <- dd[, .(
    Subject, Group, Task, Matching,
    Shape = "missing",
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label = "missing",
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Response = as.integer(response),
    RT_ms, RT_sec, ACC
  )]
  setorderv(clean, c("Group", "Subject"))
  list(clean = clean, beh = beh, task = d$task)
}

## ---- subj_info ----------------------------------------------------------------
make_subj_info <- function(clean, beh, exp_code, group_col = FALSE) {
  ## gender 码 1=male, 2=female（作者 Sheet2 说明）
  si <- beh[, .(id = as.numeric(id), Age = as.numeric(age),
                Gender = ifelse(gender == 1, "Male", ifelse(gender == 2, "Female", "/")))]
  si[is.na(Gender), Gender := "/"]
  if (group_col) {
    gtab <- unique(clean[, .(id = as.numeric(Subject), Group)])
    si <- merge(si, gtab, by = "id", all.x = TRUE)
  }
  si[, `:=`(Subject_ID = id, Exp_id = exp_code, Handedness = "/", Ethnicity = "/",
            Country = "/", First_Language = "/")]
  cols <- c("Subject_ID", "Exp_id")
  if (group_col) cols <- c(cols, "Group")
  cols <- c(cols, "Age", "Gender", "Handedness", "Ethnicity", "Country", "First_Language")
  si[, ..cols]
}

## ---- 落盘 ---------------------------------------------------------------------
write_exp <- function(exp_folder, clean, raw_dt, si, prefix) {
  dir.create(exp_folder, showWarnings = FALSE)
  fwrite(clean, file.path(exp_folder, paste0(prefix, "_Clean.csv")))
  fwrite(si,    file.path(exp_folder, paste0(prefix, "_subj_info.csv")))
  ## raw：标准 trial 级（作者列名原样保留）
  raw_out <- copy(raw_dt)
  setorderv(raw_out, "subj_idx")
  fwrite(raw_out, file.path(exp_folder, paste0(prefix, "_raw.csv")))
  cat(sprintf(">>> %s written: Clean %d rows / %d subj ; subj_info %d\n",
              prefix, nrow(clean), length(unique(clean$Subject)), nrow(si)))
}

## ---- Exp1 ---------------------------------------------------------------------
r1 <- make_within(1, c("1" = "true self", "2" = "general self", "3" = "stranger"))
stopifnot(length(unique(r1$clean$Subject)) == 45, nrow(r1$clean) == 15659)
si1 <- make_subj_info(r1$clean, r1$beh, "Exp1")
stopifnot(length(unique(r1$clean$Subject)) == nrow(si1))
write_exp(file.path(workdir, "Exp1"), r1$clean, read_trial(1), si1,
          paste0(STUDY, "_Exp1"))

## ---- Exp2 ---------------------------------------------------------------------
r2 <- make_within(2, c("1" = "general self", "2" = "friend", "3" = "stranger"))
stopifnot(length(unique(r2$clean$Subject)) == 47, nrow(r2$clean) == 16528)
si2 <- make_subj_info(r2$clean, r2$beh, "Exp2")
stopifnot(length(unique(r2$clean$Subject)) == nrow(si2))
write_exp(file.path(workdir, "Exp2"), r2$clean, read_trial(2), si2,
          paste0(STUDY, "_Exp2"))

## ---- Exp3 ---------------------------------------------------------------------
r3 <- make_exp3()
stopifnot(length(unique(r3$clean$Subject)) == 44, nrow(r3$clean) == 15376)
stopifnot(all(c("true self task", "general self task") %in% unique(r3$clean$Group)))
si3 <- make_subj_info(r3$clean, r3$beh, "Exp3", group_col = TRUE)
stopifnot(length(unique(r3$clean$Subject)) == nrow(si3))
write_exp(file.path(workdir, "Exp3"), r3$clean, read_trial(3), si3,
          paste0(STUDY, "_Exp3"))

cat("\n==== Zhao_2026_PsychonBullRev cleaning complete ====\n")
