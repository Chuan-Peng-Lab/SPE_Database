# ============================================================================
# Pan_2025_unpub — 独立清洗脚本（Exp1，jsPsych 7.3.1 / naodao.com 在线实验）
# ----------------------------------------------------------------------------
# 来源：2_Code/Clean_Data.Rmd「Pan_2025」一节（原 L4840-4957）。
# 本脚本自该 Rmd 块原样复制，仅改以下 4 处（2026-09 治理任务）：
#   1. 补 gender：Rmd 已从逐被试文件 response[6] 提取 gender，但 select() 漏带，
#      致 subj_info 的 Gender 全 "/"。此处把 gender 带回 select 并写入 subj_info。
#   2. 保留无反应试次：Rmd 原 `filter(rt != "null")` 把无反应试次（全库 40 人共
#      763 条）直接丢弃。此处不再过滤，改为 rt → NA、ACC → NA（项目「最小预处理
#      不过滤」约定：无反应应保留并编码 NA）。
#   3. 列序对齐模板 v2：Subject → Task → Phase → Matching → Shape →
#      Shape-Identity×3 → Label → Label-Identity×3 → extraIV1 → Response →
#      RT_ms → RT_sec → ACC（原 Rmd 为 legacy：Task 排在 Shape/Label 后、
#      Label-Identity 在 Shape-Identity 前）。
#   4. Stim_Type 列更名为 extraIV1（语义 = stim_order：word-first / shape-first，
#      即先文字/先图形的呈现顺序，由 target 映射、不用 Word/Image 原文）；
#      新增 Task 列（默认 self-matching）——与 2026-09 治理一致。
# ----------------------------------------------------------------------------
# 实验程序（输入区 20231208SPE-EXP1/ 的 exp1.js）揭示的正式实验结构：
#   6 block × 120 trial = 720 trial/被试；trial 内：注视点 500-1000 ms →
#   刺激1 50 ms（1000-1050）→ 刺激2 50 ms（1150-1200，SOA 150 ms）→
#   反应窗 1550 ms（response_start 1150、trial_duration 2700）。
#   练习：每轮 24 trial，循环至正确率 ≥85%。按键 f/j（match/mismatch，被试间
#   counterbalance）。3 形状 C/S/T_ambi40.png（Circle/Square/Triangle）↔
#   3 标签 自我/朋友/他人（Self/Friend/Stranger）。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Pan_2025_unpub_clean.R
# 依赖包：tidyverse (readr/dplyr/tidyr/purrr), jsonlite
# ============================================================================

# ---- 定位脚本目录 + 加载 utils.R ----
.args <- commandArgs(trailingOnly = FALSE)
.fa <- .args[grepl("^--file=", .args)]
.script_dir <- if (length(.fa)) {
  dirname(normalizePath(sub("^--file=", "", .fa[1])))
} else if (!is.null(sys.frame(1)$ofile)) {
  dirname(normalizePath(sys.frame(1)$ofile))
} else {
  getwd()
}
.ut <- file.path(dirname(dirname(.script_dir)), "1_Data", "utils.R")
if (!file.exists(.ut)) .ut <- file.path(.script_dir, "utils.R")
stopifnot(file.exists(.ut))
source(.ut)
rm(.args, .fa, .script_dir, .ut)

suppressMessages({
  library(tidyverse)
  library(jsonlite)
})

# 关闭 readr/vroom 进度条：opencode 以 PTY 捕获输出时，进度条的 ANSI 转义码会卡住
# 终端界面（表现为运行完脚本后界面无响应，需 ctrl+c）。数据读取不受影响。
options(vroom.show_progress = FALSE)
options(readr.show_progress = FALSE)

STUDY_DIR <- file.path(spe_root(), "1_Data", "Pan_2025_unpub")
stopifnot(dir.exists(STUDY_DIR))
RAW_DIR <- file.path(STUDY_DIR, "Pan_2025_unpub_Exp1_Raw")
stopifnot(dir.exists(RAW_DIR))

# ---- jspsycsv2df：自 Rmd 同名函数复制（gender 加入 select） ----
jspsycsv2df <- function(path) {
  df <- read_csv(path, show_col_types = FALSE)
  # 逐被试文件前几行固定：response[5]=编号 / [6]=性别 / [7]=出生年 / [8]=学历，
  # view_dist_mm[9]=虚拟下巴托测的视距。行号硬编码，与该程序导出结构一致。
  df$subj_idx  <- jsonlite::fromJSON(df$response[5])$Q0 %>% as.numeric()
  df$gender    <- jsonlite::fromJSON(df$response[6])
  df$year      <- jsonlite::fromJSON(df$response[7])$Q0
  df$education <- jsonlite::fromJSON(df$response[8])$Q0
  df$dist      <- df$view_dist_mm[9]

  df2 <- df %>%
    dplyr::select(
      subj_idx, gender, year, education, dist, trial_type, image, word, target,
      valence, matchness, exp_condition, response, key_press, correct_response,
      correct, rt
    )

  df3 <- df2 %>%
    dplyr::filter(trial_type == "psychophysics")

  return(df3)
}

# ---- data_preprocessing：自 Rmd 复制，改「保留无反应」+「gender 保留」 ----
data_preprocessing <- function() {
  files <- list.files(RAW_DIR, pattern = "^exp1_[0-9]+\\.csv$", full.names = TRUE)
  all <- purrr::map_dfr(.x = files, .f = ~jspsycsv2df(.x))

  data <- all %>%
    dplyr::filter(exp_condition == "Formal")

  # 原 Rmd：`filter(rt != "null")` 丢弃无反应试次。
  # 现：保留无反应试次，rt "null" → NA，ACC → NA。
  data2 <- data %>%
    dplyr::mutate(
      rt = if_else(rt == "null", NA_real_, as.numeric(rt) / 1000)
    ) %>%
    dplyr::mutate(
      ACC = if_else(is.na(rt), NA_real_, as.numeric(correct))
    )

  # 身份文字因子重标号（原 Rmd 原样保留；经核实 Match 行 valence==word、
  # Mismatch 行 valence!=word，映射正确）
  data2$valence <- factor(data2$valence, labels = c("他人", "朋友", "自我"))
  data2$valence <- factor(data2$valence, levels = c("自我", "朋友", "他人"))
  data2$word <- factor(data2$word, labels = c("他人", "朋友", "自我"))
  data2$word <- factor(data2$word, levels = c("自我", "朋友", "他人"))

  data2 <- data2 %>%
    dplyr::mutate(
      target_identity = if_else(target == "Word", word, valence),
      test_identity  = if_else(target == "Word", valence, word)
    )

  return(data2)
}

pan_data <- data_preprocessing()

# ---- 标准 trial 级 raw（原始码 + 派生列；含无反应行，rt/ACC 为 NA） ----
write_clean_csv(pan_data, file.path(STUDY_DIR, "Pan_2025_unpub_Exp1_raw.csv"))

# ---- Clean：自 Rmd 复制，改列序 v2 + Task + extraIV1 + Response 空→NA ----
pan_clean <- pan_data %>%
  dplyr::mutate(
    Subject  = as.numeric(subj_idx),
    Task     = "self-matching",
    Phase    = exp_condition,
    Matching = case_when(
      matchness == "Match" ~ "Matching",
      matchness == "Mismatch" ~ "Nonmatching"
    ),
    Shape    = image,
    Shape_Origin_Identity = valence,
    Shape_English_Identity = case_when(
      as.character(valence) == "自我" ~ "Self",
      as.character(valence) == "朋友" ~ "Friend",
      as.character(valence) == "他人" ~ "Other"
    ),
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Other" ~ "Stranger"
    ),
    Label    = word,
    Label_Origin_Identity = word,
    Label_English_Identity = case_when(
      Label == "自我" ~ "Self",
      Label == "朋友" ~ "Friend",
      Label == "他人" ~ "Other"
    ),
    Label_Standardized_Identity = case_when(
      Label_English_Identity == "Self" ~ "Self",
      Label_English_Identity == "Friend" ~ "Close",
      Label_English_Identity == "Other" ~ "Stranger"
    ),
    extraIV1 = case_when(                 # stim_order：target 原文(Word/Image) → 语义层
      target == "Word"  ~ "word-first",   # 先文字后图形
      target == "Image" ~ "shape-first"   # 先图形后文字
    ),
    Response = if_else(response == "null", NA_character_, response),
    RT_sec   = rt,
    RT_ms    = rt * 1000,
    ACC      = ACC
  ) %>%
  dplyr::select(
    Subject, Task, Phase, Matching, Shape,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    extraIV1, Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

# 列序守卫：与模板 v2 逐列对齐
stopifnot(identical(
  names(pan_clean),
  c("Subject", "Task", "Phase", "Matching", "Shape",
    "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
    "Label", "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
    "extraIV1", "Response", "RT_ms", "RT_sec", "ACC")
))

write_clean_csv(pan_clean, file.path(STUDY_DIR, "Pan_2025_unpub_Exp1_Clean.csv"))

# ---- subj_info：自逐被试人口学生成（gender 0/1/2 → Male/Female/Other） ----
pan_subj <- pan_data %>%
  dplyr::select(subj_idx, gender, year, education) %>%
  dplyr::distinct() %>%
  dplyr::mutate(
    Subject_ID = as.numeric(subj_idx),
    Exp_id     = "Pan_2025_unpub_Exp1",
    Age        = 2025L - as.integer(year),   # 出生年 → 年龄（文件夹 Year=2025）
    Gender = case_when(
      gender == 0 ~ "Male",
      gender == 1 ~ "Female",
      gender == 2 ~ "Other",
      TRUE ~ "/"
    ),
    Handedness       = "/",
    Ethnicity        = "/",
    Employment_Status = "/",
    Country          = "/",
    First_Language   = "/",
    Education        = "college"   # education=5（大学）
  ) %>%
  dplyr::select(
    Subject_ID, Exp_id, Age, Gender, Handedness, Ethnicity,
    Employment_Status, Country, First_Language, Education
  ) %>%
  dplyr::arrange(Subject_ID)

write.csv(pan_subj, file.path(STUDY_DIR, "Pan_2025_unpub_Exp1_subj_info.csv"),
          row.names = FALSE)

# ---- 守卫 ----
stopifnot(
  # 40 被试 × 720 正式试次 = 28800（含 763 无反应行，rt/ACC=NA）
  nrow(pan_clean) == 28800,
  length(unique(pan_clean$Subject)) == 40,
  nrow(pan_clean) == nrow(pan_data),
  sum(is.na(pan_clean$ACC)) == 763,
  sum(is.na(pan_clean$RT_ms)) == 763,
  # 无反应行 = rt 为 NA 的行 = ACC 为 NA 的行（三者一致）
  sum(is.na(pan_clean$RT_ms)) == sum(is.na(pan_clean$ACC)),
  # subj_info 40 人，性别 10 男 / 30 女
  nrow(pan_subj) == 40,
  sum(pan_subj$Gender == "Male") == 10,
  sum(pan_subj$Gender == "Female") == 30
)

cat("Clean: rows =", nrow(pan_clean), "| subjects =", length(unique(pan_clean$Subject)), "\n")
cat("ACC counts (1/0/NA):\n")
print(table(pan_clean$ACC, useNA = "ifany"))
cat("subj_info: rows =", nrow(pan_subj), "| Male =", sum(pan_subj$Gender == "Male"),
    "| Female =", sum(pan_subj$Gender == "Female"), "\n")
cat("Gender table:\n")
print(table(pan_subj$Gender))
cat("校验通过：Clean 28800 行（40 被试 × 720），含 763 无反应（ACC/RT=NA），",
    "性别 10 男 / 30 女。\n")
