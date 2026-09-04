## Lee_2026_BritJPsy_clean.R
## =====================================================================
## 独立清洗脚本：Lee_2026_BritJPsy（Naomi A. Lee, Douglas Martin, Jie Sui,
## "Happy me: Asymmetric bidirectional links between the self and positivity
##  underpin biased processing", British Journal of Psychology, 2026, DOI 10.1111/bjop.70100）
##
## 数据源：OSF https://osf.io/enfma/ 下载归档 enfma-osfstorage-archive/Data_files/
##   - E1a_HN_P_data  = 论文 Experiment 1a（happy/neutral 情绪 prime → 个人 shape-label 匹配）
##   - E1b_SN_P_data  = 论文 Experiment 1b（sad/neutral 情绪 prime → 个人 shape-label 匹配）
##   - E2_SSt_E_data  = 论文 Experiment 2（self/stranger 人名 prime → 形状↔情绪面孔 匹配）
##     （作者内部编号 e3a；由 Inquisit 脚本 E3a.iqx 运行；Read me 中 masked/direct
##       描述属 OSF 项目旧模板残留，与内容不符，不作依据）
##
## 已核事实（2026-09-04 复现作者 OSF_analysis.Rmd 清洗）：
##   - 每文件 tasktype=="SAT" 即正式试次（360/人 = 5 block x 72 trial，12 条件 x 30）
##   - 每个完整被试恰 360 SAT 行；各文件夹并集内无跨文件重复被试
##   - 完整数据被试数：E1a=50、E1b=53、E2=50（与论文招募数一致）
##   - 作者 chance 剔除（acc<=55% 和/或 RT<200ms）：E1a 7 人、E1b 11 人、E2 8 人
##     → 论文分析 N = 43/42/42；本库最小预处理不清除被试，故 Clean 收录全部完整被试
##   - 未完整被试（E1a: '1' 216 行 [作者注 "not data set"/测试]、727358861 324 行、
##     498626665 37 行；E1b: 349253591 197 行、18542 350 行；E2: 463627897 54 行）
##     = 中断/测试，不构成数据集 → 不入库（作者 Rmd 同判），在 subj_info 不出现
##   - 反应键：b/v 二键（per-trial 正确键 cres='b'/'v'）；response 47/48 = 二键键码，
##     '0' = 超时无反应（latency 1500），作者将超时计为 incorrect（论文口径；库内 ACC 编码
##     无反应=NA，由使用方自行按分析目标处理）
##   - 被试侧人口学：SubGender (Male/Female/A different gender/Do not want to answer)、
##     SubAge、SubHand (Left/Right/Ambidextrous)、SubEthnicity 码 1-7（E1a.iqx 选项：
##     1 Asian or Pacific Islander; 2 Black or African American; 3 Hispanic or Latino;
##     4 Mixed race; 5 Native American or American Indian; 6 White; 7 Other）
##   - 采集方式：Inquisit 6 (millisecond.com) 在线（SONA + Prolific）
##
## 输出（3 个实验文件夹，每个含 raw/Clean/subj_info 三 CSV；列序对齐 SKILL 模板 v2）：
##   Exp1a/Exp1b：标准 self-matching（形状↔自我/朋友/陌生人联结）+
##     extraIV1 = 情绪 prime（happy/neutral；sad/neutral）
##   Exp2：facialExpression-matching（形状↔情绪面孔联结，Task 受控值）
##     + extraIV1 = 人名 prime（self/stranger）
## =====================================================================

suppressMessages({
  library(data.table)
})

## ---- 路径（脚本所在目录自适应） ------------------------------------------------
args <- commandArgs(trailingOnly = FALSE)
script_path <- sub("^--file=", "", args[grepl("^--file=", args)])
if (length(script_path)) script_path <- normalizePath(script_path) else script_path <- normalizePath(sys.frame(1)$ofile)
workdir <- dirname(script_path)
setwd(workdir)
raw_root <- file.path(workdir, "Lee_2026_BritJPsy_raw", "enfma-osfstorage-archive", "Data_files")
stopifnot(dir.exists(raw_root))

## ---- 通用：读取某实验文件夹全部 csv，SAT 行，列名对齐 -----------------------------
keep_cols <- c("prolific", "build", "computer.platform", "date", "time", "subject",
               "group", "SubGender", "SubAge", "SubEthnicity", "SubHand",
               "FriendYear", "FriendFamiliar", "FriendMeetfreq", "FriendMeetTime",
               "Con_match", "Cue", "Con_shape", "Con_label", "Con_emotion",
               "Stim_Content", "tasktype", "nblock", "TrialID",
               "response", "latency", "correct", "cres")

read_exp <- function(expfolder) {
  files <- list.files(file.path(raw_root, expfolder), pattern = "[.]csv$", full.names = TRUE)
  stopifnot(length(files) > 0)
  out <- lapply(files, function(f) {
    d <- fread(f, header = TRUE, fill = TRUE, encoding = "UTF-8")
    for (cn in setdiff(keep_cols, names(d))) d[[cn]] <- NA_character_
    d <- d[, .SD, .SDcols = intersect(keep_cols, names(d))]
    d
  })
  d <- rbindlist(out, use.names = TRUE, fill = TRUE)
  d[tasktype == "SAT"]
}

## ---- 通用：每个实验的组装与导出 --------------------------------------------------
## ACC: 1/0 = 作者 correct 码（范围内对/错键）；无反应(response=='0')=NA（超时）
## 说明：留存样本中 response 仅 47/48/'0'（Ctrl+* 行仅出现在不完整被试，已被剔除）
build_clean_exp <- function(subj_sat, exp_code, task) {
  d <- copy(subj_sat)
  d[, `:=`(
    latency_n = as.numeric(latency),
    resp_is_none = is.na(response) | response == "0"
  )]
  ## 断言：超时无反应 <-> latency==1500（若 latency 缺失/0 也归 NA 但需核对）
  ## Inquisit 无反应 latency 记 1500；此处仅作 soft check
  cat(sprintf("[%s] response=='0' rows: %d ; latency==1500 rows: %d\n",
              exp_code, sum(d$resp_is_none), sum(d$latency_n == 1500, na.rm = TRUE)))
  d[, ACC := ifelse(resp_is_none, NA_integer_, as.integer(correct))]
  d[, RT_ms := latency_n]
  ## (Subject, Block, Trial) 唯一性
  stopifnot(!anyDuplicated(d[, .(subject, nblock, TrialID)]))
  d[, `:=`(Block = as.integer(nblock), Trial = as.integer(TrialID))]
  ## Matching 列取值全库规范：Matching（联结一致）/ Nonmatching（联结不一致）
  ## （2026-09-04 全库统一；raw 保留作者原始词 match/unmatch）
  d[, Matching := ifelse(Con_match == "match", "Matching", "Nonmatching")]
  d[, Subject := subject]
  ## 键检查：留存样本 response 必须在 47/48/'0'
  bad <- d[!response %in% c("47", "48", "0") & !is.na(response), ]
  if (nrow(bad)) stop(sprintf("[%s] 留存样本含非常规 response: %s", exp_code,
                              paste(unique(bad$response), collapse = ",")))
  return(d)
}

## 身份标准化映射（person 概念 → 6 类词表）
person_std <- function(x) {
  out <- rep(NA_character_, length(x))
  out[x == "self"]     <- "Self"
  out[x == "friend"]   <- "Close"
  out[x == "stranger"] <- "Stranger"
  out
}

## 形状图片 → 几何名称映射（视觉确认 + 作者提供：1.tif=triangle, 2.tif=diamond, 3.tif=pentagon）
shape_map <- function(x) {
  f <- sub("[.]tif$", "", x)
  out <- c("1" = "triangle", "2" = "diamond", "3" = "pentagon")[f]
  unname(ifelse(is.na(out), x, out))
}

## ---------------- Experiment 1a / 1b：self-matching + 情绪 prime -----------------
make_exp1 <- function(expfolder, exp_code, prime_levels) {
  sat <- read_exp(expfolder)
  ## 只留完整被试（恰 360 SAT 行）
  n_sat <- sat[, .N, by = subject]
  compl <- n_sat[N == 360, subject]
  cat(sprintf("[%s] raw 被试总数=%d, 完整(360行)=%d\n", exp_code, nrow(n_sat), length(compl)))
  stopifnot(length(compl) %in% c(50, 53))
  d <- sat[subject %in% compl]
  stopifnot(nrow(d) == length(compl) * 360)
  ## Cue 水平核对
  stopifnot(sort(unique(d$Cue)) == sort(prime_levels))
  ## 基础派生（Subject/ACC/RT_ms/Block/Trial/Matching）
  d <- build_clean_exp(d, exp_code)

  d[, `:=`(
    Shape  = shape_map(Stim_Content),           # 形状侧刺激 = 几何形状（triangle/diamond/pentagon）
    Label  = Con_label,                         # 标签文字（self/friend/stranger 概念词）
    ## 身份三层：形状侧 = 该形状被联结的人（Con_shape）；标签侧 = 标签词所属的人
    Shape_Origin_Identity       = Con_shape,
    Shape_English_Identity      = Con_shape,
    Shape_Standardized_Identity = person_std(Con_shape),
    Label_Origin_Identity       = Con_label,
    Label_English_Identity      = Con_label,
    Label_Standardized_Identity = person_std(Con_label),
    extraIV1 = Cue                              # 情绪 prime（E1a: happy/neutral; E1b: sad/neutral）
  )]
  cols <- c("Subject", "Task", "Block", "Trial", "Matching",
            "Shape", "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
            "Label", "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
            "extraIV1", "RT_ms", "ACC")
  d[, Task := "self-matching"]
  clean <- d[, .SD, .SDcols = cols]
  setorderv(clean, c("Subject", "Block", "Trial"))
  clean
}

## ---------------- Experiment 2：facialExpression-matching + 人名 prime -------------
make_exp2 <- function() {
  sat <- read_exp("E2_SSt_E_data")
  n_sat <- sat[, .N, by = subject]
  compl <- n_sat[N == 360, subject]
  cat(sprintf("[Exp2] raw 被试总数=%d, 完整(360行)=%d\n", nrow(n_sat), length(compl)))
  stopifnot(length(compl) == 50)
  d <- sat[subject %in% compl]
  stopifnot(nrow(d) == 50 * 360)
  stopifnot(sort(unique(d$Cue)) == c("self", "stranger"))
  stopifnot(sort(unique(d$Con_shape)) == c("happy", "neutral", "sad"))
  d <- build_clean_exp(d, "2")

  d[, `:=`(
    Shape  = shape_map(Stim_Content),           # 形状侧刺激 = 几何形状（triangle/diamond/pentagon）
    Label  = Con_emotion,      # 标签侧刺激 = 情绪面孔图片文件（happy/neutral/sad.tif）
    extraIV1 = Cue             # 人名 prime（self/stranger）
  )]
  cols <- c("Subject", "Task", "Block", "Trial", "Matching",
            "Shape", "Label", "extraIV1", "RT_ms", "ACC")
  d[, Task := "facialExpression-matching"]
  clean <- d[, .SD, .SDcols = cols]
  setorderv(clean, c("Subject", "Block", "Trial"))
  clean
}

## ---------------- subj_info（人口学） --------------------------------------------
ethnic_map <- c("1" = "Asian or Pacific Islander", "2" = "Black or African American",
                "3" = "Hispanic or Latino", "4" = "Mixed race",
                "5" = "Native American or American Indian", "6" = "White", "7" = "Other")
make_subj_info <- function(subj_sat, exp_code) {
  si <- subj_sat[, .(Subject = subject[1],
                     Date   = date[1],
                     Age    = SubAge[1],
                     Gender = SubGender[1],
                     Handedness = SubHand[1],
                     Ethnicity_code = SubEthnicity[1],
                     Platform = ifelse(is.na(prolific[1]) | prolific[1] == "", "Other", "Prolific")),
                 by = subject]
  si[, Ethnicity := unname(ethnic_map[Ethnicity_code])]
  si[is.na(Ethnicity), Ethnicity := "NA"]
  si[, Exp_id := exp_code]
  si[, .(Subject_ID = Subject, Exp_id, Date, Age, Gender, Handedness, Ethnicity, Platform)]
}

## ---------------- 主流程 + 落盘 ---------------------------------------------------
exp_specs <- list(
  list(folder = "E1a_HN_P_data", code = "1a", primes = c("happy", "neutral")),
  list(folder = "E1b_SN_P_data", code = "1b", primes = c("sad", "neutral"))
)

for (sp in exp_specs) {
  sat <- read_exp(sp$folder)
  clean <- make_exp1(sp$folder, sp$code, sp$primes)
  subj_sat <- sat[subject %in% unique(clean$Subject)]
  si <- make_subj_info(subj_sat, sp$code)
  ## 断言：Clean 被试数 == subj_info 行数
  stopifnot(length(unique(clean$Subject)) == nrow(si))

  out_dir <- file.path(workdir, paste0("Exp", sp$code))
  dir.create(out_dir, showWarnings = FALSE)
  fwrite(clean, file.path(out_dir, sprintf("Lee_2026_BritJPsy_Exp%s_Clean.csv", sp$code)))
  fwrite(si,    file.path(out_dir, sprintf("Lee_2026_BritJPsy_Exp%s_subj_info.csv", sp$code)))
  ## raw：标准 trial 级（留存被试的原始 SAT 行，原始列名保留）
  raw <- copy(subj_sat)
  setorderv(raw, c("subject", "nblock", "TrialID"))
  fwrite(raw, file.path(out_dir, sprintf("Lee_2026_BritJPsy_Exp%s_raw.csv", sp$code)))
  cat(sprintf(">>> Exp%s written: Clean %d rows / %d subj ; subj_info %d rows\n",
              sp$code, nrow(clean), length(unique(clean$Subject)), nrow(si)))
}

## Experiment 2
sat2 <- read_exp("E2_SSt_E_data")
clean2 <- make_exp2()
subj_sat2 <- sat2[subject %in% unique(clean2$Subject)]
si2 <- make_subj_info(subj_sat2, "2")
stopifnot(length(unique(clean2$Subject)) == nrow(si2))
out_dir2 <- file.path(workdir, "Exp2")
dir.create(out_dir2, showWarnings = FALSE)
fwrite(clean2, file.path(out_dir2, "Lee_2026_BritJPsy_Exp2_Clean.csv"))
fwrite(si2,    file.path(out_dir2, "Lee_2026_BritJPsy_Exp2_subj_info.csv"))
raw2 <- copy(subj_sat2)
setorderv(raw2, c("subject", "nblock", "TrialID"))
fwrite(raw2, file.path(out_dir2, "Lee_2026_BritJPsy_Exp2_raw.csv"))
cat(sprintf(">>> Exp2 written: Clean %d rows / %d subj ; subj_info %d rows\n",
            nrow(clean2), length(unique(clean2$Subject)), nrow(si2)))

cat("\n==== 完成 ====\n")
