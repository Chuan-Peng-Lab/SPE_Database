# ============================================================================
# Sui_2015_unpub — 独立清洗脚本（合并版 2026-09-02）
# ----------------------------------------------------------------------------
# 背景（2026-09-02 治理定案）：该 unpublished 数据原拆为 Exp1/Exp2 两个文件夹，
# 经原始 .mat 调查确认两"实验"实为**同一批 20 名被试、同一次到访内连续完成
# 的两个任务条件**：经典 self-matching（无奖励）+ reward 变体（rewardValues
# 1/4/16 关联 Self/Friend/Stranger）。Session(ses 1/2) 两 run 间隔 ~46 分钟
# （全被试一致，无 wall-clock 日期）→ 同一天两轮，故命名 Phase。按 SKILL
# 「同批被试完成多个实验 → 合并单 Clean」规则合并为单实验单文件，五件套平铺
# study 根目录（删 Exp1/Exp2 子文件夹）。原双 Exp 脚本
# `Sui_2015_unpub_clean.R`（439 行）降级为历史参考（备份于 2026-09-02 会话临时目录）。
# 列语义：Phase=run 1/2；extraIV1 = 每 trial 奖励面值（0 = 无奖励条件，
# 1/4/16 = 奖励条件中 Self/Friend/Stranger 关联面值，由 Reward×500 还原）；
# Reward（仅 raw）= 逐 trial TpercentReward 原值（Exp1 全 0；Exp2 ∈
# {0.002, 0.008, 0.032} 对应 rewardValues 1/4/16）；StartTime/EndTime（仅 raw）
# = 会话级 startInst/endfeedB 原值（秒）。ACC 保留作者码 1/0/3/4（3=超时
# RT>=1000ms、4=无反应 RT=0，Codebook 已注明）。
# 来源逻辑：基于原 `Sui_2015_unpub_clean.R`（其 read.mat/write_raw_csv 辅助
# 函数思路）+ 2026-09-02 合并调查结论重写。行序 Block-major。
# 运行方式：Rscript Sui_2015_unpub_merge.R；依赖 R.matlab（无 dplyr/tidyr 依赖）。
# ============================================================================
suppressMessages(library(R.matlab))

.args <- commandArgs(trailingOnly = FALSE)
.fa <- .args[grepl("^--file=", .args)]
.script_dir <- if (length(.fa)) {
  dirname(normalizePath(sub("^--file=", "", .fa[1])))
} else {
  getwd()
}
STUDY_DIR <- .script_dir
SRC <- file.path(STUDY_DIR, "Sui_2015_unpub_Raw", "Source")
stopifnot(dir.exists(SRC))

mats <- list.files(SRC, pattern = "^PractExperiment_[12].*[.]mat$", full.names = TRUE)
stopifnot(length(mats) == 80)  # 40 (Exp1/2 x 20 subj) x 2 phase

rows_all <- list()
for (f in mats) {
  m <- readMat(f)
  if (isTRUE(as.numeric(m$num) == 0)) next   # 排除测试运行 (PractExperiment_2_Subject_3_Ses_1)
  n_tr <- nrow(m$TestRt)
  n_blk <- ncol(m$TestRt)
  exp_order <- if (grepl("^PractExperiment_1_", basename(f))) 1L else 2L
  rows_all[[basename(f)]] <- data.frame(
    Subject   = as.numeric(m$num),
    Phase     = as.numeric(m$ses),
    Task      = "self-matching",
    exp_order = exp_order,
    Block     = rep(seq_len(n_blk), each = n_tr),
    Trial     = rep(seq_len(n_tr), n_blk),
    Shape     = as.vector(m$Tshape),
    Label     = as.vector(m$Tlabel),
    Matching  = ifelse(as.vector(m$Tshape) == as.vector(m$Tlabel),
                       "Matching", "Nonmatching"),
    Reward    = as.vector(m$TpercentReward),   # 原始值 (TpercentReward)
    ACC       = as.vector(m$Correct),
    RT_ms     = as.vector(m$TestRt),
    Response  = as.vector(m$TestResp),
    Age       = as.numeric(m$age),
    Sex       = as.character(m$sex),
    Hand      = as.character(m$han),
    StartTime = as.numeric(m$startInst),
    EndTime   = as.numeric(m$endfeedB),
    stringsAsFactors = FALSE
  )
}
raw <- do.call(rbind, rows_all)
# extraIV1 = 每 trial 奖励面值：Reward 原始比例值 ×500 → {1,4,16}；无奖励条件 Reward=0 → extraIV1=0
# （已验证全部 reward run 的 TpercentReward×500 严格落在 {1,4,16}）
raw$extraIV1 <- round(raw$Reward * 500)
stopifnot(all(raw$extraIV1 %in% c(0, 1, 4, 16)))
# 行序 = 原始运行序（Subject, Phase, 任务条件块 exp_order, Block, Trial）。
# 无奖励条件（PractExperiment_1=1）先运行、reward 条件（PractExperiment_2=2）后运行；
# 不按 extraIV1 值排序——reward 条件内 trial 面值 1/4/16 是逐 trial 的，不得打乱真实顺序。
raw <- raw[order(raw$Subject, raw$Phase, raw$exp_order, raw$Block, raw$Trial), ]
rownames(raw) <- NULL
# 列序：Subject, Phase, Task, extraIV1, Block, Trial, Shape, Label, Matching, Reward, ACC, RT_ms, Response, Age, Sex, Hand, StartTime, EndTime
raw <- raw[, c("Subject", "Phase", "Task", "extraIV1", "Block", "Trial", "Shape", "Label",
               "Matching", "Reward", "ACC", "RT_ms", "Response", "Age", "Sex", "Hand",
               "StartTime", "EndTime")]

id_map <- function(x) ifelse(x == 1, "Self", ifelse(x == 2, "Friend", "Stranger"))
std_map <- function(x) ifelse(x == 1, "Self", ifelse(x == 2, "Close", "Stranger"))

cln <- data.frame(
  Subject = raw$Subject,
  Task    = raw$Task,
  Phase   = raw$Phase,
  Block   = raw$Block,
  Trial   = raw$Trial,
  Matching = raw$Matching,
  Shape   = raw$Shape,
  Shape_Origin_Identity = id_map(raw$Shape),
  Shape_English_Identity = id_map(raw$Shape),
  Shape_Standardized_Identity = std_map(raw$Shape),
  Label   = raw$Label,
  Label_Origin_Identity = id_map(raw$Label),
  Label_English_Identity = id_map(raw$Label),
  Label_Standardized_Identity = std_map(raw$Label),
  extraIV1 = raw$extraIV1,
  Response = raw$Response,
  RT_ms   = raw$RT_ms,
  RT_sec  = round(raw$RT_ms / 1000, 3),
  ACC     = raw$ACC,
  stringsAsFactors = FALSE
)
# 列序按 SKILL 模板 v2：Subject → [Group] → [Session] → Task → [Phase] → Block → Trial
#   → Matching → Shape → Shape-Identity×3 → Label → Label-Identity×3 → extraIV1
#   → [CorrResponse] → Response → RT_ms → RT_sec → ACC
cln <- cln[, c("Subject", "Task", "Phase", "Block", "Trial", "Matching",
               "Shape", "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
               "Label", "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
               "extraIV1", "Response", "RT_ms", "RT_sec", "ACC")]

# 守卫
stopifnot(nrow(raw) == 18960, nrow(cln) == 18960)                 # 9600 + 9360
stopifnot(length(unique(raw$Subject)) == 20)
stopifnot(sum(raw$Subject == 3) == 720)                           # subject3 缺 reward-phase1
key_ok <- nrow(cln) == length(unique(paste(cln$Subject, cln$Phase,
                                           cln$extraIV1, cln$Block, cln$Trial)))
stopifnot(key_ok)
stopifnot(all(cln$extraIV1 %in% c(0, 1, 4, 16)))
stopifnot(all(cln$ACC %in% c(0, 1, 3, 4)))
stopifnot(all(cln$Block %in% 1:4), all(cln$Trial %in% 1:60))

write.table(raw, file.path(STUDY_DIR, "Sui_2015_unpub_Exp1_raw.csv"),
            sep = ",", row.names = FALSE, quote = TRUE, na = "", qmethod = "double")
write.table(cln, file.path(STUDY_DIR, "Sui_2015_unpub_Exp1_Clean.csv"),
            sep = ",", row.names = FALSE, quote = TRUE, na = "", qmethod = "double")

# subj_info：20 人人口学；Exp_id 统一。Gender/Age/Handedness 与原入库
# subj_info 口径一致（Gender 含 fm=subject17 原样保留；Handedness 用 /
# 占位——原入库未提取 han，保持一致不引入新改动）
si_rows <- list()
for (s in 1:20) {
  f <- file.path(SRC, sprintf("PractExperiment_1_Subject_%d_Ses_1_.mat", s))
  m <- readMat(f)
  si_rows[[s]] <- data.frame(
    Subject_ID = as.numeric(m$num),
    Exp_id     = "Sui_2015_unpub_Exp1",
    Age        = as.numeric(m$age),
    Gender     = as.character(m$sex),
    Handedness = "/",
    Ethnicity = "/", Employment_Status = "/", Country = "/",
    First_Language = "/", Education = "/",
    stringsAsFactors = FALSE
  )
}
si <- do.call(rbind, si_rows)
si <- si[order(as.numeric(si$Subject_ID)), ]
rownames(si) <- NULL
stopifnot(nrow(si) == 20)
# 全列转字符 + write.table 全引号（与库内 subj_info QUOTE_ALL 风格一致）
si[] <- lapply(si, as.character)
write.table(si, file.path(STUDY_DIR, "Sui_2015_unpub_Exp1_subj_info.csv"),
            sep = ",", row.names = FALSE, quote = TRUE, na = "", qmethod = "double")

cat("MERGED OK | raw rows:", nrow(raw), " clean rows:", nrow(cln),
    " subj_info:", nrow(si), "\n")
