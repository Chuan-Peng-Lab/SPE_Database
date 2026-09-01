# Hu_2020_CollabraPsy 独立清洗脚本（2026-09-01）
#
# 来源：2_Code/Clean_Data.Rmd 原 Hu_2020_CP 段（原样复制，仅修改 Trial 重编码）
#
# 修改点（2026-09-01 用户指示；2026-09-02 用户改判 600 行被试有效并指示 Block 重编码）：
#   ① Trial 重编码 = (Bin-1)*24 + Trial（bin=1 → 1-24, bin=2 → 25-48, ... 每 block 内唯一）。
#   ② Block 重编码（2026-09-02 用户指示）：600 行被试的后 240 行 = 5 个真实穿插匹配块
#      （论文 "five short interleaved perceptual-matching blocks of 48 trials"），
#      但原程序在 3 个正式 block 之后把 Block 编号错误地全部记为 1、Bin 只在 1/2 间循环。
#      现按时间顺序每 48 行 = 一个 block，重编码为 Block 4-8（bin 合入 trial 后每 block 内 1-48 唯一）。
#      依据：Date 时间戳单调（42/42 被试）、段间 ~4 分钟大间隔 = 真实 block 边界（7304 实测 235-279 s）。
#   前 360 行（3 正式 block × 5 bins × 24）Block 1-3 保持不变。
#   结论：全部 44 名被试 (Subject, Block, Trial) 0 重复（2026-09-02 模拟验证）。
#   600 行被试判定历史：2026-09-01 曾记录"用户确认无效、后续剔除"——2026-09-02 用户依据完成时间
#   改判为有效（后 240 行是真实试次，非导出重复），42 名 600 行被试全部保留。
#
# 输出：Hu_2020_CollabraPsy_Exp1_Clean.csv（与 Rmd 原输出同路径）

# ---- 工作目录自适应：脚本位于 1_Data/Hu_2020_CollabraPsy/ ----
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(file_arg) && nzchar(file_arg)) {
  setwd(dirname(normalizePath(file_arg)))
} else if (!file.exists("Hu_2020_CollabraPsy_Exp1_raw.csv")) {
  stop("cannot locate Hu_2020_CollabraPsy data directory")
}

suppressPackageStartupMessages(library(dplyr))

df <- read.csv(
  "Hu_2020_CollabraPsy_Exp1_raw.csv"
  ) %>%
  dplyr::select(
    Subject = Subject,
    Block = Block,
    Bin = Bin,
    Trial = Trial,
    Shape_Origin_Identity = Identity,
    extraIV1 = Morality,
    Shape = Shape,
    Label = Label,
    Response = Resp,
    Matching = Match,
    RT_sec = RT,
    ACC = ACC,
    ) %>%
  dplyr::mutate(
    Matching = case_when(
      Matching == "match" ~ "Matching",
      Matching == "mismatch" ~ "Nonmatching"),
    RT_sec = as.numeric(RT_sec),
    RT_ms = RT_sec * 1000,
    # [修改点 ③] ACC 统一编码（2026-09-02 修复回归）：raw 原码 -1（无反应）/2（范围外按键）
    #    → 统一编码 NA / -2。来源：e588bcc 提取 clean.R 时漏掉该步骤，曾致 681 行
    #    （658 无反应 + 23 范围外）与 Codebook/旧版 Clean 不一致（PROJ_STATE 遗留项）。
    ACC = case_when(
      ACC == -1 ~ NA_real_,
      ACC == 2 ~ -2,
      TRUE ~ as.numeric(ACC)
    ),
    ) %>%
  dplyr::mutate(
    # [修改点 ①] Trial 重编码：bin 合入 trial，使每 block 内 Trial 唯一
    Trial = (as.numeric(Bin) - 1) * 24 + as.numeric(Trial),
    Task = "self-matching",
    Subjcet = as.numeric(Subject),
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
      ),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Other" ~ "Stranger",
      Shape_English_Identity == "Self" ~ "Self",
    ),
    Label_Origin_Identity = case_when(
      Label == "immoralOther" ~ "Stranger",
      Label == "moralOther" ~ "Stranger",
      Label == "immoralSelf" ~ "Self",
      Label == "moralSelf" ~ "Self",
    ),
    Label_English_Identity = Label_Origin_Identity,
    Label_Standardized_Identity = Label_English_Identity,
    ) %>%
  dplyr::group_by(Subject) %>%
  dplyr::mutate(
    # [修改点 ②] Block 重编码：600 行被试后 240 行（5 个穿插匹配块）按 48 行/块赋 Block 4-8
    #   （组内行号 = raw 行序；n() == 600 识别 600 行被试，7302/7303 为 360 行不受影响）
    Block = ifelse(
      dplyr::n() == 600 & dplyr::row_number() > 360,
      as.character(4 + (dplyr::row_number() - 361) %/% 48),
      as.character(Block)
    )
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    Subject, Block, Trial, Matching,
    Shape, Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Task, extraIV1, Response, RT_ms, RT_sec, ACC
    ) %>%
  dplyr::arrange(
    Subject, Block, Trial
    )

# ---- 守卫：全库一致性 (Subject, Block, Trial) 唯一（2026-09-02 用户改判后要求）----
stopifnot(nrow(df) == 25920)
stopifnot(length(unique(df$Subject)) == 44)
stopifnot(!anyDuplicated(df[, c("Subject", "Block", "Trial")]))
stopifnot(all(table(df$Subject) %in% c(360, 600)))
cat("Guards passed: 25920 rows, 44 subjects, (Subject, Block, Trial) unique\n")

write.csv(x = df, file = "Hu_2020_CollabraPsy_Exp1_Clean.csv", row.names = FALSE)
cat(sprintf("Wrote Hu_2020_CollabraPsy_Exp1_Clean.csv: %d rows, %d subjects\n",
            nrow(df), length(unique(df$Subject))))
cat("Hu_2020_CollabraPsy_clean.R done\n")
