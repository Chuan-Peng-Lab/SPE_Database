# ============================================================================
# Sui_2015_unpub — 独立清洗脚本（Exp1 + Exp2）【已废弃 2026-09-02，勿再运行】
# ----------------------------------------------------------------------------
# 本脚本为历史双 Exp 版本：其输出（Exp1/、Exp2/ 子文件夹五件套）已随合并治理
# 删除。当前权威清洗脚本为同目录 `Sui_2015_unpub_merge.R`（同批 20 被试完成
# 无奖励 + reward 两条件 → 合并单实验单文件）。本文件仅作历史归档保留。
# 来源：2_Code/Clean_Data.Rmd「Sui_2015 (Unpublish)」一节（原 L3498-3659）。
# 相对原 Rmd 块的修改：
#   1. 修正失效路径：
#      - 读取：Sui_2015_unpub_Raw/Source/（原 Rmd 误写为 Sui_2015_Raw/Source/）
#      - 写入：Exp1/Sui_2015_unpub_Exp1_Clean.csv、
#              Exp2/Sui_2015_unpub_Exp2_Clean.csv
#        （原 Rmd 写为 ../1_Data/Sui_2015/...，该旧文件夹名已弃用）
#   2. Exp2 排除测试被试 subject 0（PROJ_STATE.md 已知问题）：
#      PractExperiment_2_Subject_3_Ses_1_.mat 内部编号 num=0（初始 XX、性别 fm、
#      年龄 0、按键映射反转 subRespkeys=[2,1]），均为实验开始对话框默认值，属
#      测试运行；其 240 行此前以 Subject=0 混入 Exp2_Clean.csv。排除后 Exp2
#      有效 N=20（subject 1-20，subject 3 仅剩 session 2），与稿件 Table 1
#      的 Exp2=20 一致。
#   3. ACC 编码说明（PROJ_STATE.md 已知问题）：
#      1=正确, 0=错误, 3=超时反应（probeDur=1 s，RT>=1000 ms），
#      4=无反应（RT=0）。按项目「最小预处理」约定保留原值、不重编码、不过滤
#      （含义已写入 codebook 与下方注释）。
#   4. 新增标准 trial 级 *_ExpN_raw.csv 输出（2026-08-31 阶段 4 判定：
#      .mat raw 可生成，见 PROJ_STATE.md 阶段 4）：
#      从同一批 Source/*.mat 提取原始数值码（Shape/Label=1/2/3，
#      ACC=1/0/3/4，RT_ms 即 TestRt 原值）+ 还原 Block(1-4)/Trial(1-60)
#      序列 + 会话人口学（Age/Sex/Hand，自 .mat 的 age/sex/han）+ 按键
#      Response（TestResp，1/2）。练习试次（ptrialMat，12/会话）不导出，
#      与既有 Clean 口径一致（Clean 亦只含 240 测试试次/会话）。
#      raw 行数与 Clean 完全一致（Exp1=9600 / Exp2=9360），并做
#      raw↔Clean 逐值核对守卫（Orellana-2021 先例）。输入区顶层同名 CSV
#      仅含人口学一行，非 trial 数据，raw 一律取自 Source/*.mat。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Sui_2015_unpub_clean.R（或在 RStudio 中打开后 Run/Source）
# 依赖包：R.matlab, dplyr, tidyr
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

suppressMessages({
  library(R.matlab)
  library(dplyr)
  library(tidyr)
})

STUDY_DIR <- file.path(spe_root(), "1_Data", "Sui_2015_unpub")
stopifnot(dir.exists(STUDY_DIR))



# ---- read.mat：从 Rmd 同名辅助函数原样提取（把 .mat 的
#      TestRt/Correct/Tshape/Tlabel 四列块纵向展开为长表） ----
read.mat <- function(list) {

  res <- list()

  for (i in 1:length(list)) {

    list_mat <- list[[i]]

    # 提取人口统计学变量
    Age <- list_mat$age
    han <- list_mat$han
    sex <- list_mat$sex

    # 提取反应时间（RT）数据
    df_rt <- data.frame(
      RT_1 = list_mat$TestRt[, 1],
      RT_2 = list_mat$TestRt[, 2],
      RT_3 = list_mat$TestRt[, 3],
      RT_4 = list_mat$TestRt[, 4]
    ) %>%
      tidyr::pivot_longer(
        cols = starts_with("RT_"),
        names_to = "Block",
        names_prefix = "RT_",
        values_to = "RT"
      )

    # 提取准确率（ACC）数据
    df_acc <- data.frame(
      ACC_1 = list_mat$Correct[, 1],
      ACC_2 = list_mat$Correct[, 2],
      ACC_3 = list_mat$Correct[, 3],
      ACC_4 = list_mat$Correct[, 4]
    ) %>%
      tidyr::pivot_longer(
        cols = starts_with("ACC_"),
        names_to = "Block",
        names_prefix = "ACC_",
        values_to = "ACC"
      ) %>%
      dplyr::select(-Block)

    # 提取形状（Shape）数据
    df_sha <- data.frame(
      Shape_1 = list_mat$Tshape[, 1],
      Shape_2 = list_mat$Tshape[, 2],
      Shape_3 = list_mat$Tshape[, 3],
      Shape_4 = list_mat$Tshape[, 4]
    ) %>%
      tidyr::pivot_longer(
        cols = starts_with("Shape_"),
        names_to = "Block",
        names_prefix = "Shape_",
        values_to = "Shape"
      ) %>%
      dplyr::select(-Block)

    # 提取标签（Label）数据
    df_lab <- data.frame(
      Label_1 = list_mat$Tlabel[, 1],
      Label_2 = list_mat$Tlabel[, 2],
      Label_3 = list_mat$Tlabel[, 3],
      Label_4 = list_mat$Tlabel[, 4]
    ) %>%
      tidyr::pivot_longer(
        cols = starts_with("Label_"),
        names_to = "Block",
        names_prefix = "Label_",
        values_to = "Label"
      ) %>%
      dplyr::select(-Block)

    # 创建主数据框，包括人口统计学变量
    df_mat <- data.frame(
      Subject = list_mat$num,
      Session = list_mat$ses,
      Hand = han,  # 添加汉字变量
      sex = sex,
      df_sha, df_lab,
      df_rt, df_acc
    )

    res[[i]] <- df_mat
  }

  # 合并所有数据框
  df <- do.call(rbind, res)

  return(df)
}

# ---- write_raw_csv：从 .mat 会话导出标准 trial 级 raw（原始数值码；
#      还原 Block(1-4)/Trial(1-60) 序列 + 会话人口学 + 按键；练习试次
#      （ptrialMat）不导出，与 Clean 口径一致） ----
write_raw_csv <- function(list, out_path, exclude_zero = FALSE) {
  res <- list()
  for (nm in names(list)) {
    m <- list[[nm]]
    n_tr <- nrow(m$TestRt)
    n_blk <- ncol(m$TestRt)
    res[[nm]] <- data.frame(
      Subject  = as.numeric(m$num),
      Session  = as.numeric(m$ses),
      Block    = rep(seq_len(n_blk), each = n_tr),
      Trial    = rep(seq_len(n_tr), n_blk),
      Shape    = as.vector(m$Tshape),
      Label    = as.vector(m$Tlabel),
      Matching = ifelse(
        as.vector(m$Tshape) == as.vector(m$Tlabel),
        "Matching", "Nonmatching"
      ),
      ACC      = as.vector(m$Correct),
      RT_ms    = as.vector(m$TestRt),
      Response = as.vector(m$TestResp),
      Age      = as.numeric(m$age),
      Sex      = as.character(m$sex),
      Hand     = as.character(m$han)
    )
  }
  df <- do.call(rbind, res)
  if (exclude_zero) df <- df[df$Subject != 0, ] # 排除测试被试 subject 0（同 Clean 口径）
  df <- df[order(df$Subject, df$Session, df$Block, df$Trial), ]
  row.names(df) <- NULL
  write_clean_csv(df, out_path)
  df
}

# ---- check_raw_vs_clean：raw 与 Clean 逐值核对（行数 + 共有列全等）。
#      Clean 由 pivot_longer 生成，被试-会话组内为 trial-major（行序 = 试次
#      优先，每试次 4 个 block 相邻：Trial=rep(1:60,each=4), Block=rep(1:4,60)）；
#      raw 为 block-major（.mat 矩阵列主序，Block=rep(1:4,each=60),
#      Trial=rep(1:60,4)，贴近真实运行顺序）。核对前统一按 (Trial, Block)
#      排序对齐，不依赖两文件自身行序。
#      ACC 编码差异（既有、与 raw 生成无关）：.mat 的 Correct 含特殊码
#      3=超时（RT>=1000 ms）/ 4=无反应（RT=0），已提交的 *_Clean.csv 将其
#      全部重编码为 NA（Exp1 143 行 / Exp2 76 行，与 raw 中 3+4 行数逐一
#      吻合）；本脚本按项目「最小预处理」约定保留 3/4。核对时对两侧同时做
#      {3,4}→NA 归一后比较：特殊码行集合必须完全一致，非特殊码 ACC 值全等。
#      （注：.mat 与已提交 Clean 的编码分歧先于本次 raw 生成即存在，见
#      PROJ_STATE.md 阶段 4 记录；raw 一律保留 .mat 原始码。） ----
check_raw_vs_clean <- function(raw_df, cln_df) {
  stopifnot(nrow(raw_df) == nrow(cln_df), nrow(cln_df) %% 4 == 0)
  n_grp <- nrow(cln_df) / 4 # 每 4 行 = 同一试次的 4 个 block（trial-major）
  c <- cln_df[order(
    cln_df$Subject, cln_df$Session,
    rep(seq_len(n_grp), each = 4),      # Trial 键
    rep(seq_len(4), n_grp)              # Block 键
  ), ]
  r <- raw_df[order(raw_df$Subject, raw_df$Session, raw_df$Trial, raw_df$Block), ]
  norm_acc <- function(x) ifelse(x %in% c(3, 4), NA_real_, x)
  acc_r <- norm_acc(r$ACC)
  acc_c <- norm_acc(c$ACC)
  stopifnot(
    all(r$Subject == c$Subject),
    all(r$Session == c$Session),
    all(r$Shape == c$Shape),
    all(r$Label == c$Label),
    all(as.character(r$Matching) == as.character(c$Matching)),
    sum(is.na(acc_r)) == sum(r$ACC %in% c(3, 4)),
    all(is.na(acc_r) == is.na(acc_c)),                # 特殊码行集合完全一致
    all(ifelse(is.na(acc_r), TRUE, acc_r == acc_c)),  # 非特殊码 ACC 全等
    all(abs(r$RT_ms - c$RT_ms) < 1e-9)
  )
  cat("raw ↔ Clean 逐值全等（", nrow(raw_df), " 行；ACC 按 {3,4}↔NA 归一后核对，特殊码 ",
      sum(is.na(acc_r)), " 行）\n", sep = "")
}

# ============================================================================
# Experiment 1（Identity = 3）
# "Self", "Friend", "Stranger" -> "Self", "Close", "Stranger"（无 trial 混乱）
# ============================================================================
file_list <- list.files(
  path = file.path(STUDY_DIR, "Sui_2015_unpub_Raw", "Source"),
  pattern = "^PractExperiment_1.*\\.mat$",
  full.names = TRUE
)

# 创建一个空的列表来存储读取的.mat文件
list_mat_e1 <- list()

# 循环读取文件并存储到列表中
for (file in file_list) {
  mat_data <- R.matlab::readMat(file)
  list_mat_e1[[basename(file)]] <- mat_data
}

rm(file, file_list)

df_e1 <- read.mat(
  list = list_mat_e1
) %>%
  dplyr::mutate(
    Matching = case_when(
      Shape == Label ~ "Matching",
      Shape != Label ~ "Nonmatching"
    ),
    Label_Origin_Identity = case_when(
      Label == 1 ~ "Self",
      Label == 2 ~ "Friend", # Origin Label = Friend
      Label == 3 ~ "Stranger"
    ),
    Label_English_Identity = Label_Origin_Identity,
    Label_Standardized_Identity = case_when(
      Label == 1 ~ "Self",
      Label == 2 ~ "Close", # Origin Label = Friend
      Label == 3 ~ "Stranger"
    ),
    Shape_Origin_Identity = case_when(
      Shape == 1 ~ "Self",
      Shape == 2 ~ "Friend",
      Shape == 3 ~ "Stranger"
    ),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger"
    ),
    RT_ms = RT,
    RT_sec = RT / 1000
  ) %>%
  dplyr::mutate(
    Subject = as.numeric(Subject),
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    Session = as.factor(Session),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    # ACC 编码：1=正确, 0=错误, 3=超时反应（RT>=1000 ms）, 4=无反应（RT=0）
    ACC = as.numeric(ACC)
  ) %>%
  dplyr::select(
    Subject, Session, Shape, Label, Matching,
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(
    Subject
  )

# 标准 trial 级 raw：同一批 .mat，原始数值码 + Block/Trial 序列 + 人口学
df_e1_raw <- write_raw_csv(
  list = list_mat_e1,
  out_path = file.path(STUDY_DIR, "Exp1", "Sui_2015_unpub_Exp1_raw.csv"),
  exclude_zero = FALSE
)

rm(list_mat_e1, mat_data)

write_clean_csv(df_e1, file.path(STUDY_DIR, "Exp1", "Sui_2015_unpub_Exp1_Clean.csv"))

check_raw_vs_clean(df_e1_raw, df_e1)

# ============================================================================
# Experiment 2（Identity = 3）
# "Self", "Friend", "Stranger" -> "Self", "Close", "Stranger"（无 trial 混乱）
# 注意：排除测试被试 subject 0——PractExperiment_2_Subject_3_Ses_1_.mat 为测试
# 运行（内部 num=0，初始/性别/年龄均为对话框默认值，按键映射反转），其数据
# 不进入 Clean 文件；对应 subject 3 仅保留 session 2。
# ============================================================================
file_list <- list.files(
  path = file.path(STUDY_DIR, "Sui_2015_unpub_Raw", "Source"),
  pattern = "^PractExperiment_2.*\\.mat$",
  full.names = TRUE
)

# 创建一个空的列表来存储读取的.mat文件
list_mat_e2 <- list()

# 循环读取文件并存储到列表中
for (file in file_list) {
  mat_data <- R.matlab::readMat(file)
  list_mat_e2[[basename(file)]] <- mat_data
}

rm(file, file_list)

df_e2 <- read.mat(list = list_mat_e2) %>%
  dplyr::mutate(
    Matching = case_when(
      Shape == Label ~ "Matching",
      Shape != Label ~ "Nonmatching"
    ),
    Label_Origin_Identity = case_when(
      Label == 1 ~ "Self",
      Label == 2 ~ "Friend", # Origin Label = Friend
      Label == 3 ~ "Stranger"
    ),
    Label_English_Identity = Label_Origin_Identity,
    Label_Standardized_Identity = case_when(
      Label == 1 ~ "Self",
      Label == 2 ~ "Close", # Origin Label = Friend
      Label == 3 ~ "Stranger"
    ),
    Shape_Origin_Identity = case_when(
      Shape == 1 ~ "Self",
      Shape == 2 ~ "Friend",
      Shape == 3 ~ "Stranger"
    ),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger"
    ),
    RT_ms = RT,
    RT_sec = RT / 1000
  ) %>%
  dplyr::mutate(
    Subject = as.numeric(Subject),
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    Session = as.factor(Session),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    # ACC 编码：1=正确, 0=错误, 3=超时反应（RT>=1000 ms）, 4=无反应（RT=0）
    ACC = as.numeric(ACC)
  ) %>%
  dplyr::select(
    Subject, Session, Shape, Label, Matching,
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(
    Subject
  ) %>%
  dplyr::filter(Subject != 0) # 排除测试被试 subject 0（见文件头说明）

# 标准 trial 级 raw：同一批 .mat，排除测试被试 subject 0（同 Clean 口径）
df_e2_raw <- write_raw_csv(
  list = list_mat_e2,
  out_path = file.path(STUDY_DIR, "Exp2", "Sui_2015_unpub_Exp2_raw.csv"),
  exclude_zero = TRUE
)

rm(list_mat_e2, mat_data)

write_clean_csv(df_e2, file.path(STUDY_DIR, "Exp2", "Sui_2015_unpub_Exp2_Clean.csv"))

check_raw_vs_clean(df_e2_raw, df_e2)

# ============================================================================
# 输出校验
# ============================================================================
cat("Exp1: rows =", nrow(df_e1), "| subjects =", paste(unique(df_e1$Subject), collapse = ","), "
")
cat("Exp1 ACC counts:
")
print(table(df_e1$ACC))
cat("Exp2: rows =", nrow(df_e2), "| subjects =", paste(unique(df_e2$Subject), collapse = ","), "
")
cat("Exp2 ACC counts:
")
print(table(df_e2$ACC))
cat("Exp2 subject x session:
")
print(table(df_e2$Subject, df_e2$Session))

# 一致性守卫：Exp1=9600 行 / 20 被试；Exp2=9360 行 / 20 被试 / 无 subject 0；
# raw 与 Clean 同构（行数/被试数/无 subject 0），逐值核对见上方 check_raw_vs_clean
stopifnot(
  nrow(df_e1) == 9600, length(unique(df_e1$Subject)) == 20,
  nrow(df_e2) == 9360, length(unique(df_e2$Subject)) == 20,
  !any(df_e2$Subject == 0),
  nrow(df_e1_raw) == 9600, length(unique(df_e1_raw$Subject)) == 20,
  nrow(df_e2_raw) == 9360, length(unique(df_e2_raw$Subject)) == 20,
  !any(df_e2_raw$Subject == 0)
)
cat("
校验通过：Exp1 9600 行（subject 1-20），Exp2 9360 行（subject 1-20，无 subject 0）。
")