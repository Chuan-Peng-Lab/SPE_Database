# ============================================================================
# Navon_2021_psyarxiv — 独立清洗脚本（Exp1–Exp4）
# ----------------------------------------------------------------------------
# 来源：2_Code/Clean_Data.Rmd「Mayan Navon_2021」四段（原 L870-1155，
#      对应 Rmd 内 Paper n13 Experiment 1-4 四个代码块）。
# 相对原 Rmd 块的修改：
#   1. 修正失效路径（旧文件夹名 Navon_2021 已弃用，现为 Navon_2021_psyarxiv）：
#      - 读取：<repo>/1_Data/Navon_2021_psyarxiv/ExpN/Navon_2021_psyarxiv_ExpN_raw.csv
#        （原 Rmd 写为 ../1_Data/Navon_2021/ExpN/Navon_2021_ExpN_raw.csv）
#      - 写入：<研究文件夹>/ExpN/Navon_2021_psyarxiv_ExpN_Clean.csv
#        （输出目录默认研究文件夹，可用 NAVON_OUT_DIR 覆盖）
#   2. 删除原 Rmd 中的无效行 Subjcet = as.numeric(Subject)（拼写错误，生成的
#      Subjcet 列未被 select 选中，纯无操作，删除不影响输出）。
#   3. Exp3 的 Label_Standardized_Identity：原 Rmd case_when 写 Label == "Friend"
#      （Exp3 词表为 Self/Father/Stranger，无 Friend），导致 Father 行 3360 行
#      输出 NA——2026-08 已修复为 Label == "Father" ~ "Close"（证据见
#      PROJ_STATE.md 自动化试点新发现）。
#   4. 清洗逻辑本身（过滤 MMProc、列重命名、三级 Identity、Matching、
#      排序、类型）与原 Rmd 完全一致：仅最小预处理，不过滤任何 trial/值。
#      E-Prime 原始导出中刺激标签已是英文（Self/Friend/Stranger/Father），
#      无 Hebrew 原文，故 Label_Origin_Identity == Label_English_Identity。
# 运行方式：Rscript /tmp/navon_clean.R（工作目录自适应，可从任意 cwd 运行）
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

suppressMessages({ library(dplyr) })

repo_root <- spe_root()
study_dir <- file.path(repo_root, "1_Data", "Navon_2021_psyarxiv")
out_dir   <- Sys.getenv("NAVON_OUT_DIR", unset = study_dir)
stopifnot(dir.exists(study_dir))

# ============================================================================
# Experiment 1（Identity = 3）
# "Self", "Friend", "Stranger" → "Self", "Close", "Stranger"（无 trial 混乱）
# 列映射：Shape=Stimulus, Label=Word, Response=Target.RESP, RT=Target.RT, ACC=Target.ACC
# ============================================================================
df_e1 <- read.csv(
  file.path(study_dir, "Exp1", "Navon_2021_psyarxiv_Exp1_raw.csv")
) %>%
  dplyr::filter(
    Procedure.SubTrial. == "MMProc"
  ) %>%
  dplyr::select(
    Subject,
    Shape = Stimulus,
    Response = Target.RESP,
    Label = Word,
    Label_Origin_Identity = Word,
    Label_English_Identity = Word,
    CloseShape,
    MediumShape,
    FarShape,
    RT = Target.RT,
    ACC = Target.ACC
  ) %>%
  dplyr::mutate(
    # 先生成 Identity(Shape)，再判断 Shape_Origin_Identity == Label
    Shape_Origin_Identity = case_when(
      Shape == CloseShape ~ "Self",
      Shape == MediumShape ~ "Friend",
      Shape == FarShape ~ "Stranger",
      TRUE ~ Shape # 兜底：MMProc 内实际全部命中，无 NA
    ),
    Matching = case_when(
      Shape_Origin_Identity == Label ~ "Matching",
      Shape_Origin_Identity != Label ~ "Nonmatching"
    ),
    RT_ms = as.numeric(RT),
    RT_sec = RT_ms / 1000,
    ACC = as.numeric(ACC)
  ) %>%
  dplyr::mutate(
    Matching = factor(Matching, levels = c("Matching", "Nonmatching")),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger"
    ),
    Label_Standardized_Identity = case_when(
      Label == "Self" ~ "Self",
      Label == "Friend" ~ "Close",
      Label == "Stranger" ~ "Stranger"
    )
  ) %>%
  dplyr::select(
    Subject, Shape, Label, Matching,
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

dir.create(file.path(out_dir, "Exp1"), recursive = TRUE, showWarnings = FALSE)
write_clean_csv(df_e1, file.path(out_dir, "Exp1", "Navon_2021_psyarxiv_Exp1_Clean.csv"))

# ============================================================================
# Experiment 2（Identity = 3；无 Label 列——设计为 Father/Close/Stranger 三词
# 仅作形状联想，刺激为形状，故 Matching 由 BlockType + Shape 与所属形状判定）
# "Father", "Close", "Stranger" → "Close", "Close", "Stranger"
# ============================================================================
df_e2 <- read.csv(
  file.path(study_dir, "Exp2", "Navon_2021_psyarxiv_Exp2_raw.csv")
) %>%
  dplyr::filter(
    Procedure.SubTrial. == "MMProc"
  ) %>%
  dplyr::select(
    Subject,
    Shape = Stimulus,
    Response = Target.RESP,
    CloseShape,
    MediumShape,
    FarShape,
    BlockType,
    RT = Target.RT,
    ACC = Target.ACC
  ) %>%
  dplyr::mutate(
    Shape_Origin_Identity = case_when(
      Shape == CloseShape ~ "Father",
      Shape == MediumShape ~ "Close",
      Shape == FarShape ~ "Stranger",
      TRUE ~ Shape
    ),
    Matching = case_when(
      BlockType == "CloseBlock" & Shape == CloseShape ~ "Matching",
      BlockType == "MediumBlock" & Shape == MediumShape ~ "Matching",
      BlockType == "FarBlock" & Shape == FarShape ~ "Matching",
      TRUE ~ "Nonmatching"
    ),
    RT_ms = as.numeric(RT),
    RT_sec = RT_ms / 1000,
    ACC = as.numeric(ACC)
  ) %>%
  dplyr::mutate(
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Father" ~ "Close",
      Shape_English_Identity == "Close" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger"
    )
  ) %>%
  dplyr::select(
    Subject, Shape, Matching,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

dir.create(file.path(out_dir, "Exp2"), recursive = TRUE, showWarnings = FALSE)
write_clean_csv(df_e2, file.path(out_dir, "Exp2", "Navon_2021_psyarxiv_Exp2_Clean.csv"))

# ============================================================================
# Experiment 3（Identity = 3）
# "Self", "Father", "Stranger" → "Self", "Close", "Stranger"
# 额外保留 Block = MMTrialList.Cycle, Trial = MMTrialList.Sample。
# 注意：Label_Standardized_Identity 的 case_when 2026-08 已由 "Friend" 修正为
# "Father"（原 Rmd 写 Friend，Exp3 词表为 Self/Father/Stranger，Father 行曾为 NA）。
# ============================================================================
df_e3 <- read.csv(
  file.path(study_dir, "Exp3", "Navon_2021_psyarxiv_Exp3_raw.csv")
) %>%
  dplyr::filter(
    Procedure.SubTrial. == "MMProc"
  ) %>%
  dplyr::select(
    Subject,
    Shape = Stimulus,
    Label = Word,
    Label_Origin_Identity = Word,
    Label_English_Identity = Word,
    Trial = MMTrialList.Sample,
    Block = MMTrialList.Cycle,
    CloseShape,
    MediumShape,
    FarShape,
    Response = Target.RESP,
    RT = Target.RT,
    ACC = Target.ACC
  ) %>%
  dplyr::mutate(
    Shape_Origin_Identity = case_when(
      Shape == CloseShape ~ "Self",
      Shape == MediumShape ~ "Father",
      Shape == FarShape ~ "Stranger",
      TRUE ~ Shape
    ),
    Matching = case_when(
      Shape_Origin_Identity == Label ~ "Matching",
      Shape_Origin_Identity != Label ~ "Nonmatching"
    ),
    RT_ms = as.numeric(RT),
    RT_sec = RT_ms / 1000,
    ACC = as.numeric(ACC)
  ) %>%
  dplyr::mutate(
    Matching = factor(Matching, levels = c("Matching", "Nonmatching")),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Father" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger"
    ),
    Label_Standardized_Identity = case_when(
      Label == "Self" ~ "Self",
      Label == "Father" ~ "Close",  # 2026-08 修复：原 Rmd 写 "Friend"（Exp3 词表无 Friend），Father 行曾输出 NA
      Label == "Stranger" ~ "Stranger"
    )
  ) %>%
  dplyr::select(
    Subject, Block, Trial, Shape, Label, Matching,
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

dir.create(file.path(out_dir, "Exp3"), recursive = TRUE, showWarnings = FALSE)
write_clean_csv(df_e3, file.path(out_dir, "Exp3", "Navon_2021_psyarxiv_Exp3_Clean.csv"))

# ============================================================================
# Experiment 4（Identity = 3）
# "Self", "Friend", "Stranger" → "Self", "Close", "Stranger"（无 trial 混乱）
# ============================================================================
df_e4 <- read.csv(
  file.path(study_dir, "Exp4", "Navon_2021_psyarxiv_Exp4_raw.csv")
) %>%
  dplyr::filter(
    Procedure.SubTrial. == "MMProc"
  ) %>%
  dplyr::select(
    Subject,
    Shape = Stimulus,
    Label = Word,
    Label_Origin_Identity = Word,
    Label_English_Identity = Word,
    CloseShape,
    MediumShape,
    FarShape,
    RT = Target.RT,
    ACC = Target.ACC,
    Response = Target.RESP
  ) %>%
  dplyr::mutate(
    Shape_Origin_Identity = case_when(
      Shape == CloseShape ~ "Self",
      Shape == MediumShape ~ "Friend",
      Shape == FarShape ~ "Stranger",
      TRUE ~ Shape
    ),
    Matching = case_when(
      Shape_Origin_Identity == Label ~ "Matching",
      Shape_Origin_Identity != Label ~ "Nonmatching"
    ),
    RT_ms = as.numeric(RT),
    RT_sec = RT_ms / 1000,
    ACC = as.numeric(ACC)
  ) %>%
  dplyr::mutate(
    Matching = factor(Matching, levels = c("Matching", "Nonmatching")),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger"
    ),
    Label_Standardized_Identity = case_when(
      Label == "Self" ~ "Self",
      Label == "Friend" ~ "Close",
      Label == "Stranger" ~ "Stranger"
    )
  ) %>%
  dplyr::select(
    Subject, Shape, Label, Matching,
    Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject)

dir.create(file.path(out_dir, "Exp4"), recursive = TRUE, showWarnings = FALSE)
write_clean_csv(df_e4, file.path(out_dir, "Exp4", "Navon_2021_psyarxiv_Exp4_Clean.csv"))

# ============================================================================
# 输出校验与一致性守卫
# ============================================================================
cat("Exp1: rows =", nrow(df_e1), "| subjects =", length(unique(df_e1$Subject)), "\n")
cat("Exp2: rows =", nrow(df_e2), "| subjects =", length(unique(df_e2$Subject)), "\n")
cat("Exp3: rows =", nrow(df_e3), "| subjects =", length(unique(df_e3$Subject)), "\n")
cat("Exp4: rows =", nrow(df_e4), "| subjects =", length(unique(df_e4$Subject)), "\n")
cat("Exp3 Label_Standardized_Identity 计数（含 NA，既有问题）：\n")
print(table(df_e3$Label_Standardized_Identity, useNA = "ifany"))

stopifnot(
  nrow(df_e1) == 4680, length(unique(df_e1$Subject)) == 13,
  nrow(df_e2) == 9720, length(unique(df_e2$Subject)) == 27,
  nrow(df_e3) == 10080, length(unique(df_e3$Subject)) == 28,
  nrow(df_e4) == 9720, length(unique(df_e4$Subject)) == 27
)
cat("校验通过：Exp1 4680 行/13 被试，Exp2 9720 行/27 被试，",
    "Exp3 10080 行/28 被试，Exp4 9720 行/27 被试。\n")
