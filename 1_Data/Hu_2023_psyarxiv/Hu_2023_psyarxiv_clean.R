# Hu_2023_psyarxiv 独立清洗脚本（2026-09-02）
#
# 来源：SalientGoodSelf-master 仓库（输入区 Hu_2023_psyarxiv_raw/）原始导出。
#   作者预处理权威参考：Load_save_data.r（列解码、Subject 重编码、无效被试判定）。
#
# 纳入范围（2026-09-02 用户决策）：仅纳入"self 作为自变量"的实验，依据
#   general_method.rmd 的 Table_1_exp_info chunk（Exp_info_all.csv 的 Self-ref 列）：
#     Exp_3a（explicit）、Exp_3b（explicit）、Exp_4a_1/4a_2（implicit）、
#     Exp_6b（explicit；d1+d2 均纳入，Session 1/2/3 区分——2026-09-02 用户指示）。
#   排除：Exp_1a/1b/1c/2/5/6a（Self-ref=NA）；Exp_4b_1/4b_2（用户指示不入库——
#     4b 形状↔道德人物联结、self/other 仅为形状内干扰词）；exp7（Hu_2020 另一论文）。
#
# 列语义（依据 Load_save_data.r + 原始数据核对）：
#   - Matching = YesNoResp（Yes→Matching；经 CRESP 与形状-标签身份对照确认其为真实
#     匹配状态而非被试反应；k/m 按键映射被试间 counterbalance）。
#   - extraIV1 = 形状侧道德效价（Good/Neutral/Bad），统一从 Shape 文本推导
#     （3a/3b/6b 从 Shape 文本；4a 从 morality 列=形状内词）。作者 3b/6b 的 Valence
#     取 Morality 列=标签侧、3a 取 Shape 文本=形状侧——两侧 match 试次相同、mismatch
#     不同；DB 统一形状侧并文档化。
#   - Identity 三级：Shape 侧 Origin=Shape 文本（3a/3b/6b）或 Shape 列（4a），
#     Label 侧 Origin=标签文本（3a/3b/4a）或 identity 列（6b=标签侧身份）。
#     Std：self→Self，other/他/她/他人→Stranger（循 Hu_2020 Other→Stranger）。
#   - 无反应试次（RESP 空且 RT=0、ACC=0）→ ACC=NA、RT_ms=NA（E-Prime 标准；
#     3a 全部 1154 个无反应行 RT 恰为 0 已核实）。
#   - 练习试次保留，Phase=Practice、Block=NA；6b 练习用 Targetprac.*（循作者），
#     其余实验 Target.*。
#   - Subject 重编码（循作者，跨实验唯一）：3a +3000、4a_1 +4100、其余原样。
#   - Block/Trial：formal 用 raw block 号（3b 因 self/other block 各自编号 1-3，
#     按文件内连续段重编号 1-6）；Trial = 每 (Subject, [Session], Block) 内顺序位置，
#     练习为每 (Subject, [Session]) 内顺序位置（raw SubTrial 不齐，统一位置编码）。

# ---- 工作目录自适应 ----
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(file_arg) && nzchar(file_arg)) {
  setwd(dirname(normalizePath(file_arg)))
} else if (!dir.exists("Hu_2023_psyarxiv_raw")) {
  stop("cannot locate Hu_2023_psyarxiv data directory")
}

suppressPackageStartupMessages(library(dplyr))

raw_root <- file.path("Hu_2023_psyarxiv_raw", "SalientGoodSelf-master")

# ---- 通用函数 ----------------------------------------------------------------
read_exp <- function(f) {
  read.csv(file.path(raw_root, f), header = TRUE, sep = ",", stringsAsFactors = FALSE,
           na.strings = c("", "NA"), fileEncoding = "UTF-8-BOM", check.names = FALSE)
}

# 无反应判定与 ACC/RT 统一编码（RESP 空 → 无反应：ACC=NA、RT=NA）
code_acc_rt <- function(acc, resp, rt) {
  acc_o <- rep(NA_real_, length(acc))
  rt_o  <- rep(NA_real_, length(acc))
  for (i in seq_along(acc)) {
    noresp <- is.na(resp[i]) || resp[i] == ""
    acc_o[i] <- if (is.na(acc[i])) NA_real_
                else if (acc[i] == 1) 1
                else if (noresp) NA_real_
                else 0
    rt_o[i]  <- if (noresp) NA_real_ else as.numeric(rt[i])
  }
  list(ACC = acc_o, RT_ms = rt_o)
}

std_identity <- function(x) {
  ifelse(is.na(x), NA_character_,
         ifelse(tolower(x) == "self", "Self", "Stranger"))
}

finalize <- function(d, acc_raw, resp, rt_raw, session = FALSE) {
  ca <- code_acc_rt(acc_raw, resp, rt_raw)
  d <- d %>%
    dplyr::mutate(ACC = ca$ACC, RT_ms = ca$RT_ms, RT_sec = RT_ms / 1000,
                  Task = "self-matching")
  keep <- c("Subject", if (session) "Session", "Task", "Phase", "Block", "Trial",
            "Matching", "Shape",
            "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
            "Label", "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
            "extraIV1", "CorrResponse", "Response", "RT_ms", "RT_sec", "ACC")
  d <- d[, keep]
  if (session) {
    d <- d[order(d$Subject, d$Session, d$Phase, d$Block, d$Trial), ]
  } else {
    d <- d[order(d$Subject, d$Phase, d$Block, d$Trial), ]
  }
  row.names(d) <- NULL
  d
}

# ---- 1) Exp3a（2014-04 THU） -------------------------------------------------
cat("== Exp3a ==\n")
d3a <- read_exp(file.path("exp3a", "rawdata_behav_exp3a_2014_export_2019.csv"))
stopifnot(nrow(d3a) == 37800, length(unique(d3a$Subject)) == 38)
df3a <- d3a %>%
  dplyr::mutate(
    Subject = Subject + 3000,
    Phase = ifelse(is.na(BlockList.Sample), "Practice", "Formal"),
    Matching = ifelse(YesNoResp == "Yes", "Matching", "Nonmatching"),
    Shape_col = Shape,                       # 原始 Shape 文本 = 形状概念（身份×效价）
    Shape = Target,                          # 几何文件
    extraIV1 = case_when(
      grepl("^Good", Shape_col) ~ "Good",
      grepl("^Normal", Shape_col) ~ "Neutral",
      grepl("^Bad", Shape_col) ~ "Bad", .default = NA_character_),
    Shape_Origin_Identity = Shape_col,
    Shape_English_Identity = case_when(
      Shape_col == "Goodself" ~ "Good self", Shape_col == "Goodother" ~ "Good other",
      Shape_col == "Normalself" ~ "Neutral self", Shape_col == "Normalother" ~ "Neutral other",
      Shape_col == "Badself" ~ "Bad self", Shape_col == "Badother" ~ "Bad other",
      .default = NA_character_),
    Shape_Standardized_Identity = ifelse(grepl("self$", Shape_col), "Self", "Stranger"),
    Label_Origin_Identity = Label,
    Label_English_Identity = case_when(
      Label == "好我" ~ "good me", Label == "好人" ~ "good person",
      Label == "凡我" ~ "neutral me", Label == "凡人" ~ "neutral person",
      Label == "坏我" ~ "bad me", Label == "坏人" ~ "bad person", .default = NA_character_),
    Label_Standardized_Identity = ifelse(grepl("我$", Label), "Self", "Stranger"),
    CorrResponse = Target.CRESP,
    Response = Target.RESP,
    RT_ms_raw = Target.RT,
    ACC_raw = Target.ACC,
    Block = ifelse(Phase == "Formal", as.character(BlockList.Sample), NA_character_)
  ) %>%
  dplyr::group_by(Subject, Block) %>%
  dplyr::mutate(Trial = as.character(row_number())) %>%
  dplyr::ungroup()
acc_v <- df3a$ACC_raw; resp_v <- df3a$Response; rt_v <- df3a$RT_ms_raw
df3a <- df3a %>% dplyr::select(-Shape_col, -RT_ms_raw, -ACC_raw)
df3a <- finalize(df3a, acc_v, resp_v, rt_v)
stopifnot(!anyDuplicated(df3a[df3a$Phase == "Formal", c("Subject", "Block", "Trial")]))
stopifnot(nrow(df3a) == 37800, length(unique(df3a$Subject)) == 38)
dir.create("Exp3a", showWarnings = FALSE)
write.csv(df3a, "Exp3a/Hu_2023_psyarxiv_Exp3a_Clean.csv", row.names = FALSE)
cat(sprintf("  Clean %d rows, %d subjects, formal %d rows\n",
            nrow(df3a), length(unique(df3a$Subject)), sum(df3a$Phase == "Formal")))

# ---- 2) Exp3b（2017-04 WZU；self/other 分 block） -----------------------------
cat("== Exp3b ==\n")
d3b <- read_exp(file.path("exp3b", "rawdata_behav_exp3b_201704_export_2019.csv"))
stopifnot(nrow(d3b) == 55440, length(unique(d3b$Subject)) == 61)
df3b <- d3b %>%
  dplyr::mutate(
    Phase = ifelse(is.na(otherBlocklList.Sample) & is.na(selfBlockList.Sample),
                   "Practice", "Formal"),
    Matching = ifelse(YesNoResp == "Yes", "Matching", "Nonmatching"),
    Shape_col = Shape,
    Shape = Target,
    extraIV1 = case_when(
      grepl("^Good", Shape_col) ~ "Good",
      grepl("^Neutral", Shape_col) ~ "Neutral",
      grepl("^Bad", Shape_col) ~ "Bad", .default = NA_character_),
    Shape_Origin_Identity = Shape_col,
    Shape_English_Identity = case_when(
      Shape_col == "Goodself" ~ "Good self", Shape_col == "Neutralself" ~ "Neutral self",
      Shape_col == "Badself" ~ "Bad self", Shape_col == "GoodOther" ~ "Good other",
      Shape_col == "NeutralOther" ~ "Neutral other", Shape_col == "BadOther" ~ "Bad other",
      .default = NA_character_),
    Shape_Standardized_Identity = ifelse(grepl("self$", Shape_col), "Self", "Stranger"),
    Label_Origin_Identity = Label,
    Label_English_Identity = case_when(
      Label == "好我" ~ "good me", Label == "好他" ~ "good him", Label == "好她" ~ "good her",
      Label == "常我" ~ "neutral me", Label == "常他" ~ "neutral him", Label == "常她" ~ "neutral her",
      Label == "坏我" ~ "bad me", Label == "坏他" ~ "bad him", Label == "坏她" ~ "bad her",
      .default = NA_character_),
    Label_Standardized_Identity = ifelse(grepl("我$", Label), "Self", "Stranger"),
    CorrResponse = Target.CRESP,
    Response = Target.RESP,
    RT_ms_raw = Target.RT,
    ACC_raw = Target.ACC
  ) %>%
  dplyr::group_by(Subject) %>%
  dplyr::mutate(
    .blk_key = ifelse(Phase == "Formal",
                      paste0(ifelse(!is.na(selfBlockList.Sample), "S", "O"),
                             ifelse(!is.na(selfBlockList.Sample),
                                    selfBlockList.Sample, otherBlocklList.Sample)),
                      NA_character_),
    .blk_chg = Phase == "Formal" & (.blk_key != dplyr::lag(.blk_key) |
                                      is.na(dplyr::lag(.blk_key))),
    Block = ifelse(Phase == "Formal", as.character(cumsum(.blk_chg)), NA_character_)
  ) %>%
  dplyr::ungroup() %>%
  dplyr::group_by(Subject, Block) %>%
  dplyr::mutate(Trial = as.character(row_number())) %>%
  dplyr::ungroup() %>%
  dplyr::select(-.blk_key, -.blk_chg, -Shape_col)
acc_v <- df3b$ACC_raw; resp_v <- df3b$Response; rt_v <- df3b$RT_ms_raw
df3b <- df3b %>% dplyr::select(-RT_ms_raw, -ACC_raw)
df3b <- finalize(df3b, acc_v, resp_v, rt_v)
stopifnot(!anyDuplicated(df3b[df3b$Phase == "Formal", c("Subject", "Block", "Trial")]))
stopifnot(all(table(df3b$Subject[df3b$Phase == "Formal"]) == 720))
stopifnot(nrow(df3b) == 55440, length(unique(df3b$Subject)) == 61)
dir.create("Exp3b", showWarnings = FALSE)
write.csv(df3b, "Exp3b/Hu_2023_psyarxiv_Exp3b_Clean.csv", row.names = FALSE)
cat(sprintf("  Clean %d rows, %d subjects, formal 720/subj\n",
            nrow(df3b), length(unique(df3b$Subject))))

# ---- 3) Exp4a_1（2015 THU）与 Exp4a_2（2017 WZU） -----------------------------
cat("== Exp4a_1 / Exp4a_2 ==\n")
clean_4a <- function(f, subj_offset, exp_dir, exp_id) {
  d <- read_exp(f)
  if (!"morality" %in% names(d)) d$morality <- d$Morality   # 2017 版大写
  if (!"self" %in% names(d))     d$self <- d$Identity
  d <- d %>%
    dplyr::mutate(
      Subject = Subject + subj_offset,
      Phase = ifelse(is.na(BlockList.Sample), "Practice", "Formal"),
      Matching = ifelse(YesNoResp == "Yes", "Matching", "Nonmatching"),
      Shape_col = Shape,                     # 形状的学习身份 Self/Other
      Shape = Target,
      Shape_Origin_Identity = Shape_col,
      Shape_English_Identity = Shape_col,
      Shape_Standardized_Identity = std_identity(Shape_col),
      extraIV1 = case_when(
        morality == "Good" ~ "Good", morality == "Normal" ~ "Neutral",
        morality == "Bad" ~ "Bad", .default = NA_character_),
      Label_Origin_Identity = Label,
      Label_English_Identity = ifelse(Label == "自己", "Self", "Other"),
      Label_Standardized_Identity = ifelse(Label == "自己", "Self", "Stranger"),
      CorrResponse = Target.CRESP,
      Response = Target.RESP,
      RT_ms_raw = Target.RT,
      ACC_raw = Target.ACC,
      Block = ifelse(Phase == "Formal", as.character(BlockList.Sample), NA_character_)
    ) %>%
    dplyr::group_by(Subject, Block) %>%
    dplyr::mutate(Trial = as.character(row_number())) %>%
    dplyr::ungroup() %>%
    dplyr::select(-morality, -self, -Shape_col)
  acc_v <- d$ACC_raw; resp_v <- d$Response; rt_v <- d$RT_ms_raw
  d <- d %>% dplyr::select(-RT_ms_raw, -ACC_raw)
  out <- finalize(d, acc_v, resp_v, rt_v)
  stopifnot(!anyDuplicated(out[out$Phase == "Formal", c("Subject", "Block", "Trial")]))
  dir.create(exp_dir, showWarnings = FALSE)
  write.csv(out, file.path(exp_dir, paste0("Hu_2023_psyarxiv_", exp_id, "_Clean.csv")),
            row.names = FALSE)
  cat(sprintf("  %s: %d rows, %d subjects\n", exp_id, nrow(out), length(unique(out$Subject))))
  out
}
df4a1 <- clean_4a(file.path("exp4a", "rawdata_behav_exp4a_2015_export_2019.csv"),
                  4100, "Exp4a_1", "Exp4a_1")
df4a2 <- clean_4a(file.path("exp4a", "rawdata_behav_exp4a_2017_export_2019.csv"),
                  0, "Exp4a_2", "Exp4a_2")
stopifnot(nrow(df4a1) == 15333, length(unique(df4a1$Subject)) == 32)
stopifnot(nrow(df4a2) == 30240, length(unique(df4a2$Subject)) == 32)

# ---- 4) Exp6b（2016-01 THU；d1+d2，Session 1/2/3） -----------------------------
cat("== Exp6b ==\n")
d6b1 <- read_exp(file.path("exp6b_erp2", "rawdata_erp_exp6b_d1_2016_export_2019.csv"))
d6b2 <- read_exp(file.path("exp6b_erp2", "rawdata_erp_exp6b_d2_2016_export_2019.csv"))
all_cols <- union(names(d6b1), names(d6b2))     # d2 多 CodePrime/CodeTarget
for (c in setdiff(all_cols, names(d6b1))) d6b1[[c]] <- NA
for (c in setdiff(all_cols, names(d6b2))) d6b2[[c]] <- NA
d6b <- rbind(d6b1[, all_cols], d6b2[, all_cols])
stopifnot(nrow(d6b) == 67411, length(unique(d6b$Subject)) == 23)
# 剔除 6205/S2 的 1 行全空伪记录（导出残留空行，无刺激/反应/时间数据；raw 保留 verbatim）
.drop_art <- !is.na(d6b$Subject) & d6b$Subject == 6205 & d6b$Session == "2" &
             is.na(d6b$Label) & is.na(d6b$Target) & is.na(d6b$BlockList.Sample)
stopifnot(sum(.drop_art) == 1)
d6b <- d6b[!.drop_art, ]
stopifnot(nrow(d6b) == 67410)

df6b <- d6b %>%
  dplyr::mutate(
    Phase = ifelse(is.na(BlockList.Sample), "Practice", "Formal"),
    Matching = ifelse(YesNoResp == "Yes", "Matching", "Nonmatching"),
    Shape_col = Shape,
    Shape = Target,
    extraIV1 = case_when(
      grepl("^Good", Shape_col) ~ "Good",
      grepl("^Normal", Shape_col) ~ "Neutral",
      grepl("^Bad", Shape_col) ~ "Bad", .default = NA_character_),
    Shape_Origin_Identity = Shape_col,
    Shape_English_Identity = case_when(
      Shape_col == "Goodself" ~ "Good self", Shape_col == "Goodother" ~ "Good other",
      Shape_col == "Normalself" ~ "Neutral self", Shape_col == "Normalother" ~ "Neutral other",
      Shape_col == "Badself" ~ "Bad self", Shape_col == "Badother" ~ "Bad other",
      .default = NA_character_),
    Shape_Standardized_Identity = ifelse(grepl("self$", Shape_col), "Self", "Stranger"),
    Label_Origin_Identity = identity,          # = 标签侧身份（与 Label 文件名 1:1 已核实）
    Label_English_Identity = ifelse(tolower(identity) == "self", "Self", "Other"),
    Label_Standardized_Identity = ifelse(tolower(identity) == "self", "Self", "Stranger"),
    CorrResponse = ifelse(Phase == "Formal", CorrectAnswer, NA_character_),
    Response = ifelse(Phase == "Formal", Target.RESP, Targetprac.RESP),
    RT_ms_raw = ifelse(Phase == "Formal", Target.RT, Targetprac.RT),
    ACC_raw = ifelse(Phase == "Formal", Target.ACC, Targetprac.ACC),
    Block = ifelse(Phase == "Formal", as.character(BlockList.Sample), NA_character_),
    Session = as.numeric(Session)
  ) %>%
  dplyr::group_by(Subject, Session, Block) %>%
  dplyr::mutate(Trial = as.character(row_number())) %>%
  dplyr::ungroup() %>%
  dplyr::select(-Shape_col, -CodePrime, -CodeTarget)
acc_v <- df6b$ACC_raw; resp_v <- df6b$Response; rt_v <- df6b$RT_ms_raw
df6b <- df6b %>% dplyr::select(-RT_ms_raw, -ACC_raw)
df6b <- finalize(df6b, acc_v, resp_v, rt_v, session = TRUE)
stopifnot(!anyDuplicated(df6b[df6b$Phase == "Formal", c("Subject", "Session", "Block", "Trial")]))
stopifnot(nrow(df6b) == 67410, length(unique(df6b$Subject)) == 23)
dir.create("Exp6b", showWarnings = FALSE)
write.csv(df6b, "Exp6b/Hu_2023_psyarxiv_Exp6b_Clean.csv", row.names = FALSE)
cat(sprintf("  Clean %d rows, %d subjects, formal %d rows\n",
            nrow(df6b), length(unique(df6b$Subject)), sum(df6b$Phase == "Formal")))

# ---- 原始数据落盘（verbatim 复制/拼接至各 Exp 文件夹 *_raw.csv） --------------
file.copy(file.path(raw_root, "exp3a", "rawdata_behav_exp3a_2014_export_2019.csv"),
          "Exp3a/Hu_2023_psyarxiv_Exp3a_raw.csv", overwrite = TRUE)
file.copy(file.path(raw_root, "exp3b", "rawdata_behav_exp3b_201704_export_2019.csv"),
          "Exp3b/Hu_2023_psyarxiv_Exp3b_raw.csv", overwrite = TRUE)
file.copy(file.path(raw_root, "exp4a", "rawdata_behav_exp4a_2015_export_2019.csv"),
          "Exp4a_1/Hu_2023_psyarxiv_Exp4a_1_raw.csv", overwrite = TRUE)
file.copy(file.path(raw_root, "exp4a", "rawdata_behav_exp4a_2017_export_2019.csv"),
          "Exp4a_2/Hu_2023_psyarxiv_Exp4a_2_raw.csv", overwrite = TRUE)
write.csv(d6b, "Exp6b/Hu_2023_psyarxiv_Exp6b_raw.csv", row.names = FALSE, na = "")
cat("  raw files written (6b = d1+d2 concatenated, CodePrime/CodeTarget kept in raw)\n")

# ---- subj_info（人口学取每被试首行；Age=0 → NA 循作者） ------------------------
write_subj_info <- function(raw_df, subj_offset, exp_id, path) {
  si <- raw_df %>%
    dplyr::mutate(Subject = Subject + subj_offset) %>%
    dplyr::distinct(Subject, .keep_all = TRUE) %>%
    dplyr::mutate(
      Age = ifelse(Age == 0, NA, Age),
      Gender = ifelse(Sex == "male", "Male", "Female"),
      Handedness = ifelse(Handedness == "right", "R", "L"),
      Ethnicity = "/", Employment_Status = "/", Country = "/",
      First_Language = "/", Education = "/"
    ) %>%
    dplyr::select(Subject_ID = Subject, Age, Gender, Handedness,
                  Ethnicity, Employment_Status, Country, First_Language, Education)
  si$Exp_id <- exp_id
  si <- si[, c("Subject_ID", "Exp_id", "Age", "Gender", "Handedness",
               "Ethnicity", "Employment_Status", "Country", "First_Language", "Education")]
  write.csv(si, path, row.names = FALSE)
}
write_subj_info(d3a, 3000, "Hu_2023_psyarxiv_Exp3a",
                "Exp3a/Hu_2023_psyarxiv_Exp3a_subj_info.csv")
write_subj_info(d3b, 0, "Hu_2023_psyarxiv_Exp3b",
                "Exp3b/Hu_2023_psyarxiv_Exp3b_subj_info.csv")
write_subj_info(read_exp(file.path("exp4a", "rawdata_behav_exp4a_2015_export_2019.csv")),
                4100, "Hu_2023_psyarxiv_Exp4a_1",
                "Exp4a_1/Hu_2023_psyarxiv_Exp4a_1_subj_info.csv")
write_subj_info(read_exp(file.path("exp4a", "rawdata_behav_exp4a_2017_export_2019.csv")),
                0, "Hu_2023_psyarxiv_Exp4a_2",
                "Exp4a_2/Hu_2023_psyarxiv_Exp4a_2_subj_info.csv")
write_subj_info(d6b, 0, "Hu_2023_psyarxiv_Exp6b",
                "Exp6b/Hu_2023_psyarxiv_Exp6b_subj_info.csv")
cat("  subj_info files written\n")

cat("Hu_2023_psyarxiv_clean.R done\n")
