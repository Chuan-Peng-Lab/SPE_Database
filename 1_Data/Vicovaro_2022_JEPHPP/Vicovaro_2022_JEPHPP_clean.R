
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
#      VICOVARO_OUT_DIR 指定（缺省 <脚本目录>）。
#   3. 输出带 stopifnot 一致性守卫（行数/被试数/列名集合）。
# 清洗逻辑要点（最小预处理、不过滤）：
#   - Exp1：无过滤；列映射 + 值映射；14400 行 / 30 被试（participant_id 1-30）。
#     列序：Subject, Response, Symmetry, Shape, Matching, 三级 Shape Identity,
#           RT_ms, RT_sec, ACC。
#   - Exp2（2026-08 阶段 3 重建，替代原 filter(block=="selfS") 只留 48 人
#     的旧逻辑）：raw 24960 行 = 104 人 × 240 试次（selfS 52 人 + selfA 52 人，
#     论文被试间设计）。participant_id 编码混乱——95 个唯一 ID 中含 8 个
#     480 行双人 ID（LS99/AC99/SD99/MS98 在 selfS，AG99/AS99/IG94/AP99 在
#     selfA，各为两人数据合并，前/后 240 试次几乎不重叠）与 AB99 跨
#     selfS+selfA 两区（各 240 行，两人量）。重建逻辑：按 (participant_id,
#     block) 分组、每 240 行切分为 1 个 Subject（480 行块拆为 2 人、AB99 拆
#     为 2 人、空 ID 块单独 1 人）→ 104 个 Subject；纳入 selfS+selfA 全部
#     数据（Asymmetry 块不再丢弃）；段内重复行保留（最小预处理，不去重）。
#     列序：Subject, Symmetry, Shape, Matching, 三级 Shape Identity,
#           Response, RT_ms, RT_sec, ACC。
#   - 公共映射：block selfS->Symmetry / selfA->Asymmetry；
#     shape self-related->Self / stranger-related->Stranger（三级一致）；
#     match yes->Matching / no->Nonmatching；respCorr 1->1 / 0->0 /
#     "missed"->NA；RT_ms = respRt*1000。
# ----------------------------------------------------------------------------
# 运行方式：Rscript 1_Data/Vicovaro_2022_JEPHPP/Vicovaro_2022_JEPHPP_clean.R
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
# Experiment 2 (Identity = 2)：纳入 selfS + selfA 全部数据，104 人（2026-08 重建）
# ----------------------------------------------------------------------------
# Subject 编号原则（保留原始 participant_id，重复时加段号后缀）：
#   1. 唯一 ID（仅 1 段，240 行）→ 直接用原始 ID（如 "CR99"）。
#   2. 重复 ID（多段，即多于一人的数据共用同一 participant_id 编码）：
#      按段在原始数据中的出现顺序加 "_1"/"_2"/... 后缀。
#      * 480 行块（LS99/AC99/SD99/MS98 在 selfS；AG99/AS99/IG94/AP99 在
#        selfA）前/后 240 试次几乎不重叠，判定为两人数据合并 →
#        "LS99_1" / "LS99_2"。
#      * 跨两个 block 的 ID（AB99：selfS 240 + selfA 240 = 两人量，
#        两段试次几乎不重叠）→ "AB99_1"（selfS）/ "AB99_2"（selfA）。
#      条件归属（Symmetry vs Asymmetry）由 Clean 的 Symmetry 列承载，不重复
#      编码进 Subject（AB99_1 的 Symmetry=Symmetry，AB99_2=Asymmetry）。
#   3. 空 participant_id（240 行，selfS）→ "Vicovaro2022Exp2_1"（无原始 ID）。
# 以上规则保证 104 个 Subject 全部唯一且可追溯回原始数据。
# 段序与条件映射明细：见下方 Subject_ID 生成逻辑（seg_no 按 (participant_id,
# block) 组内 240 行切分；跨区 ID 的段序 = block 出现顺序）。
# ============================================================================
temp <- read.csv(file.path(STUDY, "Exp2", "Vicovaro_2022_JEPHPP_Exp2_raw.csv"),
                 stringsAsFactors = FALSE) %>%
  dplyr::mutate(grp = paste(participant_id, block, sep = "|")) %>%
  dplyr::group_by(participant_id, block) %>%
  dplyr::mutate(seg_no = (row_number() - 1) %/% 240 + 1) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(Subject_raw = paste(participant_id, block, seg_no, sep = "|"))

Subject_ID <- temp %>%
  dplyr::select(Subject_raw, participant_id, block, seg_no) %>%
  dplyr::distinct() %>%
  # 同一 participant_id 的多个段按原始出现顺序编全局段号
  dplyr::group_by(participant_id) %>%
  dplyr::arrange(block, seg_no, .by_group = TRUE) %>%
  dplyr::mutate(
    global_seg = dplyr::row_number(),
    n_segs     = dplyr::n()
  ) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    Subject = dplyr::case_when(
      participant_id == "" ~ "Vicovaro2022Exp2_1",                       # 空 ID
      n_segs   > 1         ~ paste0(participant_id, "_", global_seg),     # 重复 ID 各段加段号
      TRUE                 ~ participant_id                               # 唯一 ID
    )
  ) %>%
  dplyr::select(Subject_raw, Subject, participant_id, block, seg_no, global_seg)

# ---- 供 subj_info 对齐的段映射（脚本内存对象，不落盘为独立文件） ----
subject_map <- Subject_ID

df_e2 <- temp %>%
  dplyr::left_join(Subject_ID %>% dplyr::select(-participant_id, -block, -seg_no),
                   by = "Subject_raw") %>%
  dplyr::mutate(
    Symmetry = dplyr::case_when(
      block == "selfS" ~ "Symmetry",
      block == "selfA" ~ "Asymmetry"
    ),
    Shape_English_Identity = case_when(
      shape == "self-related" ~ "Self",
      shape == "stranger-related" ~ "Stranger"
    ),
    Shape_Standardized_Identity = Shape_English_Identity,
    Matching = case_when(
      match == "yes" ~ "Matching",
      match == "no" ~ "Nonmatching",
    ),
    ACC = case_when(
      respCorr == 1 ~ 1,
      respCorr == 0 ~ 0,
      respCorr == "missed" ~ NA
    ),
    RT_sec = as.numeric(respRt),
    RT_ms = RT_sec * 1000,
  ) %>%
  dplyr::rename(
    Shape_Origin_Identity = shape,
    Response = responseKey
  ) %>%
  dplyr::mutate(
    Subject = as.character(Subject),   # 保留原始 ID（字符串，如 "CR99"、"LS99_1"）
    Shape = Shape_Origin_Identity,
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
  ) %>%
  dplyr::select(
    Subject_raw, Subject, Symmetry, Shape, Matching,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(Subject) %>%
  # 写出前删除临时列 Subject_raw（仅用于构建期对齐 subj_info，非最终列）
  dplyr::select(-Subject_raw)

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
cat("Exp2 Symmetry dist:\n")
print(table(df_e2$Symmetry))

stopifnot(
  nrow(df_e1) == 14400,
  length(unique(df_e1$Subject)) == 30,
  identical(
    names(df_e1),
    c("Subject", "Response", "Symmetry", "Shape", "Matching",
      "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
      "RT_ms", "RT_sec", "ACC")
  ),
  nrow(df_e2) == 24960,
  length(unique(df_e2$Subject)) == 104,
  identical(
    names(df_e2),
    c("Subject", "Symmetry", "Shape", "Matching",
      "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
      "Response", "RT_ms", "RT_sec", "ACC")
  ),
  all(df_e2$Symmetry %in% c("Symmetry", "Asymmetry")),
  sum(df_e2$Symmetry == "Symmetry") == 12480,
  sum(df_e2$Symmetry == "Asymmetry") == 12480
)
cat("\n校验通过：Exp1 14400 行/30 被试；Exp2 24960 行/104 被试（selfS 12480 + selfA 12480）。\n")
