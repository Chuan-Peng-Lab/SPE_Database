# Wozniak_2018_PLOS 独立清洗脚本（2026-09-01）
#
# 来源：2_Code/Clean_Data.Rmd 原 Wozniak_2018_PLOS E1/E2 两段（原文已从 Rmd 删除，
#       此脚本为唯一入口；本文件为原代码复制，仅修改 Block/Trial 推导，其余逻辑不变）。
#
# 修改点（2026-09-01 用户指示）：
#   原：Block = TrialList.Cycle（1-4，同性/异性两段复用同一 Cycle 值）、
#       Trial = TrialList.Sample（全局 1-336）
#       → arrange(Subject, Block, Trial) 后把 raw 的"前 4 段 M + 后 4 段 F"
#         分段结构打散为 M/F 交叉（Block 内性别不再恒定）。
#   现：Block = 段编号 1-8（每被试按 raw 行序每 84 行一段；段内性别恒定，
#       前 4 段同一性别、后 4 段另一性别 —— 对应论文"两部分各 4 blocks × 84"），
#       Trial = 段内序号 1-84（等价 raw 的 Trial 列）。
#   不加 Part 列（用户指示）：同/异性别信息由 Block + Face_Gender(Shape_Subtype) 承载。
#
# 兼容中断被试：行数为 84 整数倍即分段（完整被试 672=8 段；E1 有 336/588 行的中断被试，
# E2 有 420 行的中断被试，按实际行数分段，Block 编号 1-N）。
#
# 数据：任务为形状-标签匹配（面孔=shape，芝加哥面孔库 3 女 3 男），实验分两部分：
#       同性别面孔部分 + 异性别面孔部分（每部分 4 blocks × 84 = 336，共 672 试次/被试；
#       部分被试中断，行数不足 672，按实际行数分段）。
#
# 输出：Wozniak_2018_PLOS_Exp<N>_Clean.csv（与 Rmd 原输出同路径）。

# ---- 工作目录自适应：脚本位于 1_Data/Wozniak_2018_PLOS/ ----
args <- commandArgs(trailingOnly = FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
if (length(file_arg) && nzchar(file_arg)) {
  setwd(dirname(normalizePath(file_arg)))
} else if (!file.exists("Exp1/Wozniak_2018_PLOS_Exp1_raw.csv")) {
  stop("cannot locate Wozniak_2018_PLOS data directory")
}

suppressPackageStartupMessages(library(dplyr))

# ============================================================
# Experiment 1 (Identity = 3)  原 Rmd 行 615-698
# ============================================================
df1 <- read.csv(
  "Exp1/Wozniak_2018_PLOS_Exp1_raw.csv"
  ) %>%
  dplyr::filter(
    PracticeMode == "No"
  ) %>%
  dplyr::group_by(Subject) %>%
  dplyr::mutate(
    # [修改点] Block = 段编号 1-8（每 84 行一段）；Trial = 段内序号 1-84
    Block = ceiling(dplyr::row_number() / 84),
    Trial = (dplyr::row_number() - 1) %% 84 + 1,
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    Subject,
    Label = Cue,
    Shape = Stimulus,
    Face_Gender = Face_Gender,
    RT_ms = Cue.RT,
    ACC = Cue.ACC,
    Response = Cue.RESP,
    Block,
    Trial,
  ) %>%
  dplyr::mutate(
    Shape_Origin_Identity = case_when(
      Shape == "shape1.jpg" ~ "Self",
      Shape == "shape2.jpg" ~ "Friend",
      Shape == "shape3.jpg" ~ "Stranger",
      is.na(Shape) ~ NA_character_,
      TRUE ~ Shape
    ),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger",
    ),
    Label_Origin_Identity = case_when(
      Label == "You" ~ "Self",
      Label == "Friend" ~ "Friend",
      Label == "Stranger" ~ "Stranger",
      is.na(Label) ~ NA_character_,
      TRUE ~ Label
    ),
    Label_English_Identity = Label_Origin_Identity,
    Label_Standardized_Identity = case_when(
      Label_English_Identity == "Self" ~ "Self",
      Label_English_Identity == "Friend" ~ "Close",
      Label_English_Identity == "Stranger" ~ "Stranger",
    ),
    Matching = case_when(
      Shape_Origin_Identity == Label_Origin_Identity ~ "Matching",
      Shape_Origin_Identity != Label_Origin_Identity ~ "Nonmatching"
    ),
    Face_Gender = Face_Gender,
    RT_ms = as.numeric(RT_ms),
    RT_sec = RT_ms / 1000
  ) %>%
  dplyr::mutate(
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    Shape_Origin_Identity = factor(
      Shape_Origin_Identity, levels = c("Self", "Friend", "Stranger")
    ),
    Face_Gender = as.factor(Face_Gender),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
  ) %>%
  dplyr::select(
    Subject, Block, Trial, Matching,
    Shape, Shape_Subtype = Face_Gender,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    Response, RT_ms, RT_sec, ACC,
  ) %>%
  dplyr::arrange(
    Subject, Block, Trial
  )

# ---- E1 守卫 ----
stopifnot(
  "每被试行数为 84 的整数倍" = all(as.integer(table(df1$Subject)) %% 84 == 0),
  "每段 84 行" = all(vapply(split(df1$Block, df1$Subject),
                            function(b) all(as.integer(table(b)) == 84), logical(1))),
  "段内性别恒定" = all(vapply(split(df1$Shape_Subtype, list(df1$Subject, df1$Block)),
                              function(x) length(unique(x)) == 1, logical(1))
                    [lengths(split(df1$Shape_Subtype, list(df1$Subject, df1$Block))) > 0]),
  "Matching 逻辑 0 失配" = all(
    (df1$Matching == "Matching") == (as.character(df1$Shape_Origin_Identity) ==
                                       as.character(df1$Label_Origin_Identity))),
  "Shape 身份值域" = all(as.character(df1$Shape_Origin_Identity) %in%
                           c("Self", "Friend", "Stranger")),
  "性别值域" = all(as.character(df1$Shape_Subtype) %in% c("F", "M"))
)
# 完整 8 段被试：前 4 段同一性别、后 4 段另一性别
seg1 <- lapply(split(df1$Shape_Subtype, list(df1$Subject, df1$Block)),
               function(x) as.character(x[1]))
for (s in unique(df1$Subject)) {
  g <- unlist(seg1[paste(s, sort(unique(df1$Block[df1$Subject == s])), sep = ".")])
  if (length(g) == 8) {
    stopifnot(length(unique(g[1:4])) == 1, length(unique(g[5:8])) == 1, g[1] != g[5])
  } else {
    cat(sprintf("  note: subject %s has %d segments (incomplete)\n", s, length(g)))
  }
}

write.csv(x = df1, file = "Exp1/Wozniak_2018_PLOS_Exp1_Clean.csv", row.names = FALSE)
cat(sprintf("Wrote Exp1 Clean: %d rows, %d subjects\n", nrow(df1),
            length(unique(df1$Subject))))

# ============================================================
# Experiment 2 (Identity = 3)  原 Rmd 行 700-778
# ============================================================
df2 <- read.csv(
  "Exp2/Wozniak_2018_PLOS_Exp2_raw.csv"
  ) %>%
  dplyr::filter(
    PracticeMode == "No"
  ) %>%
  dplyr::group_by(Subject) %>%
  dplyr::mutate(
    # [修改点] Block = 段编号 1-8（每 84 行一段）；Trial = 段内序号 1-84
    Block = ceiling(dplyr::row_number() / 84),
    Trial = (dplyr::row_number() - 1) %% 84 + 1,
  ) %>%
  dplyr::ungroup() %>%
  dplyr::select(
    Subject,
    Label = Cue,
    Shape = Stimulus,
    Face_Gender = Face_Gender,
    RT_ms = Stimulus.RT,
    ACC = Stimulus.ACC,
    Block,
    Trial,
  ) %>%
  dplyr::mutate(
    Shape_Origin_Identity = case_when(
      Shape == "shape1.jpg" ~ "Self",
      Shape == "shape2.jpg" ~ "Friend",
      Shape == "shape3.jpg" ~ "Stranger",
      is.na(Shape) ~ NA_character_,
      TRUE ~ Shape
    ),
    Shape_English_Identity = Shape_Origin_Identity,
    Shape_Standardized_Identity = case_when(
      Shape_English_Identity == "Self" ~ "Self",
      Shape_English_Identity == "Friend" ~ "Close",
      Shape_English_Identity == "Stranger" ~ "Stranger",
    ),
    Label_Origin_Identity = case_when(
      Label == "You" ~ "Self",
      Label == "Friend" ~ "Friend",
      Label == "Stranger" ~ "Stranger",
      is.na(Label) ~ NA_character_,
      TRUE ~ Label
    ),
    Label_English_Identity = Label_Origin_Identity,
    Label_Standardized_Identity = case_when(
      Label_English_Identity == "Self" ~ "Self",
      Label_English_Identity == "Friend" ~ "Close",
      Label_English_Identity == "Stranger" ~ "Stranger",
    ),
    Matching = case_when(
      Shape_Origin_Identity == Label_Origin_Identity ~ "Matching",
      Shape_Origin_Identity != Label_Origin_Identity ~ "Nonmatching"
    ),
    Face_Gender = Face_Gender,
    RT_ms = as.numeric(RT_ms),
    RT_sec = RT_ms / 1000
  ) %>%
  dplyr::mutate(
    Matching = factor(
      Matching, levels = c("Matching", "Nonmatching")
    ),
    Face_Gender = as.factor(Face_Gender),
    RT_ms = as.numeric(RT_ms),
    RT_sec = as.numeric(RT_sec),
    ACC = as.numeric(ACC),
  ) %>%
  dplyr::select(
    Subject, Block, Trial, Matching,
    Shape, Shape_Subtype = Face_Gender,
    Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity,
    Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity,
    RT_ms, RT_sec, ACC
  ) %>%
  dplyr::arrange(
    Subject, Block, Trial,
  )

# ---- E2 守卫 ----
stopifnot(
  "每被试行数为 84 的整数倍" = all(as.integer(table(df2$Subject)) %% 84 == 0),
  "每段 84 行" = all(vapply(split(df2$Block, df2$Subject),
                            function(b) all(as.integer(table(b)) == 84), logical(1))),
  "段内性别恒定" = all(vapply(split(df2$Shape_Subtype, list(df2$Subject, df2$Block)),
                              function(x) length(unique(x)) == 1, logical(1))
                    [lengths(split(df2$Shape_Subtype, list(df2$Subject, df2$Block))) > 0]),
  "Matching 逻辑 0 失配" = all(
    (df2$Matching == "Matching") == (as.character(df2$Shape_Origin_Identity) ==
                                       as.character(df2$Label_Origin_Identity))),
  "Shape 身份值域" = all(as.character(df2$Shape_Origin_Identity) %in%
                           c("Self", "Friend", "Stranger")),
  "性别值域" = all(as.character(df2$Shape_Subtype) %in% c("F", "M"))
)
seg2 <- lapply(split(df2$Shape_Subtype, list(df2$Subject, df2$Block)),
               function(x) as.character(x[1]))
for (s in unique(df2$Subject)) {
  g <- unlist(seg2[paste(s, sort(unique(df2$Block[df2$Subject == s])), sep = ".")])
  if (length(g) == 8) {
    stopifnot(length(unique(g[1:4])) == 1, length(unique(g[5:8])) == 1, g[1] != g[5])
  } else {
    cat(sprintf("  note: subject %s has %d segments (incomplete)\n", s, length(g)))
  }
}

write.csv(x = df2, file = "Exp2/Wozniak_2018_PLOS_Exp2_Clean.csv", row.names = FALSE)
cat(sprintf("Wrote Exp2 Clean: %d rows, %d subjects\n", nrow(df2),
            length(unique(df2$Subject))))

cat("Wozniak_2018_PLOS_clean.R done\n")
