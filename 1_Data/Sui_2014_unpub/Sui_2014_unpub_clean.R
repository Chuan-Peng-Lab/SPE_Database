# ============================================================================
# Sui_2014_unpub — 独立清洗脚本（未发表数据，单实验）
# ----------------------------------------------------------------------------
# 来源：2_Code/Clean_Data.Rmd「Sui_2014 (Unpublish)」一节（原 L3436-3497）。
# 配方注释原文：「Matching 分布不对，没明白Session和Group的区别」——
# 本脚本照 Rmd 逻辑原样提取（不修正语义），该不确定点已在脚本末尾校验输出
# 中复现（Matching=5760/17280，Session 各被试 240/360 不等，Group 为形状-标签
# 配对分组），是否影响输出见验证报告。
#
# 相对原 Rmd 块的修改：
#   1. 修正失效路径：
#      - 读取：1_Data/Sui_2014_unpub/Sui_2014_unpub_Exp1_raw.csv
#        （原 Rmd 误写为 ../1_Data/Sui_2014/Sui_2014_Exp1_raw.csv，
#        旧文件夹名 Sui_2014 已弃用，现为 Sui_2014_unpub）
#      - 写入：默认 1_Data/Sui_2014_unpub/Sui_2014_unpub_Exp1_Clean.csv
#        （可用环境变量 SUI2014_OUT_DIR 覆盖）
#   2. 列映射说明（E-Prime 导出 → 标准列）：
#      Subject→Subject, Session→Session, Block(第1个,值 Group1/2/3)→Group,
#      SelfRelated→Shape/Shape_Origin_Identity, Question→Label/Label_Origin_Identity,
#      RT→RT_ms, ACC→ACC；RT_sec = RT_ms/1000。
#      注意：raw 中第 4 列和第 7 列都叫 Block，read.csv 自动改名第 2 个为
#      Block.1；配方取第 1 个（Group1/2/3，形状-标签配对反平衡组）。
#   3. 中文 Identity 三级映射：本实验原始标签即英文（Shape 为 Self/Friend/
#      Stranger，Label 为 You/Friend/Stranger），Origin=English；
#      Standardized：You→Self，Friend→Close，Stranger→Stranger。
#   4. Matching = (Shape == Label_Origin_Identity)，即形状身份与提问身份是否一致。
#   5. 输出用 CRLF 行尾 + quote=TRUE（write.csv 默认），与库内 *_Clean.csv 一致。
# ----------------------------------------------------------------------------
# 运行方式：Rscript /tmp/sui2014_clean.R（可在任意目录运行：
#   项目根自动解析顺序：环境变量 SPE_DATABASE_ROOT > 当前工作目录 > 脚本所在目录）
# 依赖包：dplyr
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

suppressMessages(library(dplyr))

PROJECT_ROOT <- spe_root()


RAW_PATH <- file.path(
  PROJECT_ROOT, "1_Data/Sui_2014_unpub", "Sui_2014_unpub_Exp1_raw.csv"
)
OUT_DIR <- Sys.getenv("SUI2014_OUT_DIR",
                unset = file.path(PROJECT_ROOT, "1_Data", "Sui_2014_unpub"))
dir.create(OUT_DIR, showWarnings = FALSE, recursive = TRUE)
OUT_PATH <- file.path(OUT_DIR, "Sui_2014_unpub_Exp1_Clean.csv")

cat("项目根:", PROJECT_ROOT, "\n")
cat("读取:", RAW_PATH, "\n")
cat("输出:", OUT_PATH, "\n")

suppressMessages(library(dplyr))

# ---- write_clean_csv：写 CSV 使用 CRLF 行尾（与库内 *_Clean.csv 惯例一致） ----
write_clean_csv <- function(df, path) {
  tmp <- tempfile(fileext = ".csv")
  write.csv(df, tmp, row.names = FALSE)
  txt <- readLines(tmp, warn = FALSE)
  con <- file(path, open = "wb")
  writeLines(txt, con, sep = "\r\n", useBytes = TRUE)
  close(con)
  unlink(tmp)
}

# ============================================================================
# Experiment 1（Identity = 3）
# "Self"/"Friend"/"Stranger"（Shape 原始英文）与 "You"/"Friend"/"Stranger"
# （Label 原始英文）→ Standardized: You/Self→Self, Friend→Close, Stranger→Stranger
# ============================================================================
df <- read.csv(RAW_PATH) %>%
  dplyr::select(
    Subject = Subject,
    Session = Session,
    Group = Block,            # 取第 1 个 Block 列（值 Group1/2/3）
    Shape = SelfRelated,
    Shape_Origin_Identity = SelfRelated,
    Label = Question,
    Label_Origin_Identity = Question,
    RT_ms = RT,
    ACC = ACC,
  ) %>%
  dplyr::mutate(
    RT_sec = RT_ms / 1000,
    Label_English_Identity = Label_Origin_Identity,
    Label_Standardized_Identity = case_when(
      Label_Origin_Identity == "You" ~ "Self",
      Label_Origin_Identity == "Friend" ~ "Close",
      Label_Origin_Identity == "Stranger" ~ "Stranger",
    ),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger",
    ),
    Matching = case_when(
      Shape == Label_Origin_Identity ~ "Matching",
      Shape != Label_Origin_Identity ~ "Nonmatching"),
  ) %>%
  dplyr::mutate(
    Subject = as.numeric(Subject),
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    Session = as.factor(Session),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
  ) %>%
  dplyr::select(
    Subject, Group, Session, Matching, Shape, Label,
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

write_clean_csv(df, OUT_PATH)

# ============================================================================
# 输出校验（一致性守卫）
# ============================================================================
cat("\nrows =", nrow(df), "| subjects =", length(unique(df$Subject)), "\n")
cat("Matching 分布（配方不确定性复现）:\n")
print(table(df$Matching))
cat("Session 分布:", paste(names(table(df$Session)), table(df$Session), sep = "=", collapse = " "), "\n")
cat("Group 分布:", paste(names(table(df$Group)), table(df$Group), sep = "=", collapse = " "), "\n")
cat("ACC 分布:\n")
print(table(df$ACC))

required_cols <- c(
  "Subject", "Group", "Session", "Matching", "Shape", "Label",
  "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
  "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
  "RT_ms", "RT_sec", "ACC"
)
stopifnot(
  nrow(df) == 17280,
  length(unique(df$Subject)) == 24,
  identical(names(df), required_cols),
  as.numeric(table(df$Matching)["Matching"]) == 5760,
  as.numeric(table(df$Matching)["Nonmatching"]) == 11520
)
cat("\n校验通过：17280 行 / 24 被试 / 15 列 / Matching 5760+11520。\n")
