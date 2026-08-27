
# ============================================================================
# Vicovaro_2022_JEPHPP — 独立清洗脚本（Exp1 + Exp2）
# ----------------------------------------------------------------------------
# 来源：2_Code/Clean_Data.Rmd「Vicovaro_2022_EPHPP」两节（原 L1750-1894，
#       chunk: "Paper t6 Experiment 1" / "Paper t6 Experiment 2"）。
# 相对原 Rmd 块的修改：
#   1. 修正失效路径：Rmd 中旧文件夹名 Vicovaro_2022_EPHPP → 当前
#      Vicovaro_2022_JEPHPP（项目已改名）。
#   2. 路径自适应：脚本不依赖 Rmd 上下文。项目根目录由环境变量
#      VICOVARO_PROJ_ROOT 指定（缺省为硬编码本机路径）；输出目录由
#      VICOVARO_OUT_DIR 指定（缺省 <脚本目录>/vicovaro_test）。本测试版脚本
#      放 /tmp，输出全部写 /tmp/vicovaro_test/，不触碰 1_Data/。
#   3. 输出带 stopifnot 一致性守卫（行数/被试数/列名集合）。
# 清洗逻辑要点（与 Rmd 完全一致，最小预处理、不过滤）：
#   - Exp1：无过滤；列映射 + 值映射；14400 行 / 30 被试（participant_id 1-30）。
#     列序：Subject, Response, Symmetry, Shape, Matching, 三级 Shape Identity,
#           RT_ms, RT_sec, ACC。
#   - Exp2：先 filter(block == "selfS")（只保留对称块；raw 24960 → 12480 行）；
#     participant_id 为字符串（46 个命名 ID + 1 个空 ID 块 240 行），
#     group_by(Subject) 后按 dplyr 排序重编号 Subject_ID=1..48
#     （空 ID 排序最前 → Subject 1）。保留全部行不剔除（含 4 个 480 行的
#     参与者块 AC99/LS99/MS98/SD99，其内部有少量重复行——原 Rmd 不去重，
#     此处也不去重）。列序：Subject, Symmetry, Shape, Matching, 三级 Shape
#     Identity, Response, RT_ms, RT_sec, ACC。
#   - 公共映射：block selfS->Symmetry / selfA->Asymmetry；
#     shape self-related->Self / stranger-related->Stranger（三级一致）；
#     match yes->Matching / no->Nonmatching；respCorr 1->1 / 0->0 /
#     "missed"->NA；RT_ms = respRt*1000。
# ----------------------------------------------------------------------------
# 运行方式：Rscript /tmp/vicovaro_clean.R
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

PROJ_ROOT <- spe_root()
STUDY <- file.path(PROJ_ROOT, "1_Data", "Vicovaro_2022_JEPHPP")
OUT_DIR <- Sys.getenv("VICOVARO_OUT_DIR", unset = STUDY)
stopifnot(dir.exists(STUDY))

# ============================================================================
# Experiment 1 (Identity = 2)：无过滤，14400 行 / 30 被试
# ============================================================================
df_e1 <- read.csv(file.path(STUDY, "Exp1", "Vicovaro_2022_JEPHPP_Exp1_raw.csv")) %>%
  dplyr::select(
    Subject = participant_id,
    Response = responseKey,
    Symmetry = block,
    Matching = match,
    Shape = shape,
    Shape_Origin_Identity = shape,
    RT_sec = respRt,
    ACC = respCorr,
  ) %>%
  dplyr::mutate(
    Symmetry = case_when(
      Symmetry == "selfS" ~ "Symmetry",
      Symmetry == "selfA" ~ "Asymmetry"
    ),
    Shape_English_Identity = case_when(
      Shape_Origin_Identity == "self-related" ~ "Self",
      Shape_Origin_Identity == "stranger-related" ~ "Stranger"
    ),
    Shape_Standardized_Identity = Shape_English_Identity,
    Matching = case_when(
      Matching == "yes" ~ "Matching",
      Matching == "no" ~ "Nonmatching",
    ),
    ACC = case_when(
      ACC == 1 ~ 1,
      ACC == 0 ~ 0,
      ACC == "missed" ~ NA
    ),
    RT_sec = as.numeric(RT_sec),
    RT_ms = RT_sec * 1000
  ) %>%
  dplyr::mutate(
    Subject = as.numeric(Subject),
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
  ) %>%
  dplyr::select(
    Subject, Response, Symmetry, Shape, Matching,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

write_clean_csv(df_e1, file.path(OUT_DIR, "Exp1", "Vicovaro_2022_JEPHPP_Exp1_Clean.csv"))

# ============================================================================
# Experiment 2 (Identity = 2)：filter(block=="selfS") + Subject 重编号
# ============================================================================
temp <- read.csv(file.path(STUDY, "Exp2", "Vicovaro_2022_JEPHPP_Exp2_raw.csv")) %>%
  dplyr::filter(block == "selfS") %>%
  dplyr::select(
    Subject = participant_id,
    Response = responseKey,
    Symmetry = block,
    Matching = match,
    Shape = shape,
    Shape_Origin_Identity = shape,
    RT_sec = respRt,
    ACC = respCorr,
  ) %>%
  dplyr::mutate(
    Symmetry = dplyr::case_when(
      Symmetry == "selfS" ~ "Symmetry",
      Symmetry == "selfA" ~ "Asymmetry"
    ),
    Shape_English_Identity = case_when(
      Shape_Origin_Identity == "self-related" ~ "Self",
      Shape_Origin_Identity == "stranger-related" ~ "Stranger"
    ),
    Shape_Standardized_Identity = Shape_English_Identity,
    Matching = case_when(
      Matching == "yes" ~ "Matching",
      Matching == "no" ~ "Nonmatching",
    ),
    ACC = case_when(
      ACC == 1 ~ 1,
      ACC == 0 ~ 0,
      ACC == "missed" ~ NA
    ),
    RT_sec = as.numeric(RT_sec),
    RT_ms = RT_sec * 1000,
  )

Subject_ID <- temp %>%
  dplyr::group_by(Subject) %>%
  dplyr::summarise(count = n()) %>%
  dplyr::mutate(Subject_ID = row_number()) %>%
  dplyr::select(Subject, Subject_ID)

df_e2 <- temp %>%
  dplyr::left_join(Subject_ID, by = "Subject") %>%
  dplyr::mutate(
    Subject = as.numeric(Subject_ID),
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
  ) %>%
  dplyr::select(
    Subject, Symmetry, Shape, Matching,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

rm(Subject_ID, temp)

write_clean_csv(df_e2, file.path(OUT_DIR, "Exp2", "Vicovaro_2022_JEPHPP_Exp2_Clean.csv"))

# ============================================================================
# 输出校验（一致性守卫）
# ============================================================================
cat("Exp1: rows =", nrow(df_e1), "| subjects =", length(unique(df_e1$Subject)), "\n")
cat("Exp1 ACC counts:\n")
print(table(df_e1$ACC, useNA = "ifany"))
cat("Exp2: rows =", nrow(df_e2), "| subjects =", length(unique(df_e2$Subject)), "\n")
cat("Exp2 rows per subject dist:\n")
print(table(table(df_e2$Subject)))

stopifnot(
  nrow(df_e1) == 14400,
  length(unique(df_e1$Subject)) == 30,
  identical(
    names(df_e1),
    c("Subject", "Response", "Symmetry", "Shape", "Matching",
      "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
      "RT_ms", "RT_sec", "ACC")
  ),
  nrow(df_e2) == 12480,
  length(unique(df_e2$Subject)) == 48,
  identical(
    names(df_e2),
    c("Subject", "Symmetry", "Shape", "Matching",
      "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
      "Response", "RT_ms", "RT_sec", "ACC")
  ),
  all(df_e2$Symmetry == "Symmetry")
)
cat("\n校验通过：Exp1 14400 行/30 被试；Exp2 12480 行/48 被试（filter selfS）。\n")
