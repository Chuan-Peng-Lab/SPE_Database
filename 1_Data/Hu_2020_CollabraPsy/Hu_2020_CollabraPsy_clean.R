# Hu_2020_CollabraPsy 独立清洗脚本（2026-09-01）
#
# 来源：2_Code/Clean_Data.Rmd 原 Hu_2020_CP 段（原样复制，仅修改 Trial 重编码）
#
# 修改点（2026-09-01 用户指示）：
#   原：Block = Block, Bin = Bin, Trial = Trial（Trial 1-24 每 bin 内循环）
#       → 2026-09-01 治理删除 Bin 列后，(Subject, Block, Trial) 不再唯一。
#   现：Trial 重编码 = (Bin-1)*24 + Trial（bin=1 → 1-24, bin=2 → 25-48, ... 每 block 内 1-120 唯一），
#       Bin 列保留原名（治理删除前为 Bin，删除后由本脚本重建输出 Bin；如需与治理后模板一致可后续再删）。
#   600 行被试为无效被试（用户确认），本脚本按同一逻辑处理全部被试。
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
    ) %>%
  dplyr::mutate(
    # [修改点] Trial 重编码：bin 合入 trial，使 (Subject, Block, Trial) 唯一
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
  dplyr::select(
    Subject, Block, Trial, Matching,
    Shape, Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Task, extraIV1, Response, RT_ms, RT_sec, ACC
    ) %>%
  dplyr::arrange(
    Subject, Block, Trial
    )

write.csv(x = df, file = "Hu_2020_CollabraPsy_Exp1_Clean.csv", row.names = FALSE)
cat(sprintf("Wrote Hu_2020_CollabraPsy_Exp1_Clean.csv: %d rows, %d subjects\n",
            nrow(df), length(unique(df$Subject))))
cat("Hu_2020_CollabraPsy_clean.R done\n")
