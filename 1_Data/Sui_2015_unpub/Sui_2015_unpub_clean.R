# ============================================================================
# Sui_2015_unpub — 独立清洗脚本（Exp1 + Exp2）
# ----------------------------------------------------------------------------
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
# ----------------------------------------------------------------------------
# 运行方式：Rscript Sui_2015_unpub_clean.R（或在 RStudio 中打开后 Run/Source）
# 依赖包：R.matlab, dplyr, tidyr
# ============================================================================

# ---- 设置工作目录为脚本所在目录（兼容 Rscript 与 RStudio Source） ----
args <- commandArgs(trailingOnly = FALSE)
file_arg <- args[grepl("^--file=", args)]
if (length(file_arg) > 0) {
  setwd(dirname(normalizePath(sub("^--file=", "", file_arg[1]))))
} else if (!is.null(sys.frame(1)$ofile)) {
  setwd(dirname(normalizePath(sys.frame(1)$ofile)))
}

suppressMessages({
  library(R.matlab)
  library(dplyr)
  library(tidyr)
})

# ---- read.mat：从 Rmd 同名辅助函数原样提取（把 .mat 的
#      TestRt/Correct/Tshape/Tlabel 四列块纵向展开为长表） ----
# ---- write_clean_csv：写 CSV 时使用 CRLF 行尾（与库内 *_Clean.csv 惯例一致） ----
write_clean_csv <- function(df, path) {
  tmp <- tempfile(fileext = ".csv")
  write.csv(df, tmp, row.names = FALSE)
  txt <- readLines(tmp, warn = FALSE)
  con <- file(path, open = "wb")
  writeLines(txt, con, sep = "\r\n", useBytes = TRUE)
  close(con)
  unlink(tmp)
}

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

# ============================================================================
# Experiment 1（Identity = 3）
# "Self", "Friend", "Stranger" -> "Self", "Close", "Stranger"（无 trial 混乱）
# ============================================================================
file_list <- list.files(
  path = "Sui_2015_unpub_Raw/Source/",
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

rm(list_mat_e1, mat_data)

write_clean_csv(df_e1, "Exp1/Sui_2015_unpub_Exp1_Clean.csv")

# ============================================================================
# Experiment 2（Identity = 3）
# "Self", "Friend", "Stranger" -> "Self", "Close", "Stranger"（无 trial 混乱）
# 注意：排除测试被试 subject 0——PractExperiment_2_Subject_3_Ses_1_.mat 为测试
# 运行（内部 num=0，初始/性别/年龄均为对话框默认值，按键映射反转），其数据
# 不进入 Clean 文件；对应 subject 3 仅保留 session 2。
# ============================================================================
file_list <- list.files(
  path = "Sui_2015_unpub_Raw/Source/",
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

rm(list_mat_e2, mat_data)

write_clean_csv(df_e2, "Exp2/Sui_2015_unpub_Exp2_Clean.csv")

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

# 一致性守卫：Exp1=9600 行 / 20 被试；Exp2=9360 行 / 20 被试 / 无 subject 0
stopifnot(
  nrow(df_e1) == 9600, length(unique(df_e1$Subject)) == 20,
  nrow(df_e2) == 9360, length(unique(df_e2$Subject)) == 20,
  !any(df_e2$Subject == 0)
)
cat("
校验通过：Exp1 9600 行（subject 1-20），Exp2 9360 行（subject 1-20，无 subject 0）。
")