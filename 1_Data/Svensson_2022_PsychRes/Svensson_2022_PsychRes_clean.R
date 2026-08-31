# ============================================================================
# Svensson_2022_PsychRes — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1-3）
# ----------------------------------------------------------------------------
# 背景（2026-09 阶段 5 入库）：Svensson, Golubickis, Maclean, Falbén, Persson,
# Tsamadi, Caughey, Sahraie & Macrae (2022), "More or less of me and you:
# self-relevance augments the effects of item probability on stimulus
# prioritization", Psychological Research 86(4):1145-1164,
# DOI 10.1007/s00426-021-01562-x（online 2021-07-29；University of Aberdeen
# 实验室采集；REF/Svensson_2022_PsychRes.md 全文）。
#
# 任务（Sui et al. 2012 式形状-标签匹配）：学习阶段绑定两个几何形状
# （triangle/square，138x138 px，灰底白形）↔ 两个身份（自己/最好朋友），
# 绑定 counterbalanced 且未记录；试次：1000 ms fixation → 100 ms 形状(上)-
# 标签(下)配对 → 空白屏直至按键（N/M 键，映射 counterbalanced）；10 练习
# 试次（不在数据文件）。三实验：
#   Exp1 equal           ：1 block x 200 正式试次（4 条件 x 50）；预期 50/50。
#   Exp2 confirmatory    ：2 blocks x 200（self-frequent 75/25 + friend-
#                          frequent 75/25；block 序 counterbalanced）；预期
#                          与实际频率一致。
#   Exp3 dis-confirmatory：2 blocks x 200；预期与实际相反（self-expectancy
#                          block 实际 friend 形状 75%）。
#
# 数据格式（输入区 cj7fp-osfstorage-archive/Data/*.xlsx，OSF 共享文件）：
#   Exp1: Participant # | Trial Type(Matching/Nonmatching) | Target Label
#         (YOU/FRIEND) | Shape Association(Self/Friend) | Target Accuracy(1/0)
#         | Reponse Time(ms)        [列名 "Reponse" 为作者拼写，raw 保留]
#   Exp2: Participant # | Trial Type | Expectancy(Self/Friend = block 指示
#         条件) | Shape Association | Target Accuracy | Response Time(ms)
#   Exp3: Participant # | Trial Number(1-200, per block) | Trial Type |
#         Expectancy | Shape Association | Target Accuracy | Response Time(ms)
#   行序：Exp1 无 trial 序号（试次随机序）；Exp2 按 block（expectancy run
#   排序，每被试恰 2 run）；Exp3 按 (ACC desc, block, trial number) 排序
#   （正确试次在前；两 ACC 组内各 1 次 trial 重启、expectancy 顺序一致）。
#
# 数据特性（作者预清洗，2026-09 入库核对，用户确认原样入库）：
#   * 文件已排除 RT<200 ms 与未响应试次：RT min = 200（论文分析口径
#     "Responses faster than 200 ms were excluded"）；无 NA 行；RT 上限
#     ~1200 ms。每被试试次数少于设计（Exp1 118-199/200；Exp2 215-390/400；
#     Exp3 206-399/400）——缺失原因论文/OSF 未说明，库内原样保留全部行
#     （最小预处理），细节记 exp JSON detail / CSV Note。
#   * 练习试次（10）不在文件。
#   * 无几何形状信息（绑定 counterbalanced 未记录）→ Shape 列 = 身份词
#     （Zhang_2026 / Golubickis 先例）。
#   * Exp2/3 无 Target Label 列 → Label 由 Trial Type + Shape Association
#     推导（二身份下完全确定：Matching → label = 形状身份；Nonmatching →
#     label = 另一身份；Exp1 全量验证 Matching <=> (Label==SA) 0 失配），
#     Codebook/JSON 注明推导性质。
#
# 身份映射（用户确认 2026-09）：YOU/self → Self；FRIEND/friend → Close。
# 清洗 = 最小预处理：不过滤；raw 保留作者原列名。
# ============================================================================

# ---- 引导块：定位脚本目录与项目根，加载 utils.R ----
.args <- commandArgs(trailingOnly = FALSE)
.script_dir <- sub("--file=", "", .args[grep("^--file=", .args)])
if (length(.script_dir) == 0) .script_dir <- getwd()
.script_dir <- normalizePath(dirname(.script_dir))
.ut <- file.path(.script_dir, "..", "utils.R")
if (!file.exists(.ut)) stop("utils.R not found next to clean script")
source(.ut)
.root <- spe_root(.script_dir)
.study_dir <- file.path(.root, "1_Data", "Svensson_2022_PsychRes")
.inp_dir <- file.path(.study_dir, "Svensson_2022_PsychRes_Raw",
                      "cj7fp-osfstorage-archive", "Data")
stopifnot(dir.exists(.inp_dir))
.f1 <- file.path(.inp_dir, "Experiment 1, equal.xlsx")
.f2 <- file.path(.inp_dir, "Experiment 2, confirmatory.xlsx")
.f3 <- file.path(.inp_dir, "Experiment 3, dis-confirmatory.xlsx")
stopifnot(all(file.exists(c(.f1, .f2, .f3))))

# ---- 公共映射与辅助 ----
.id_english <- c("YOU" = "Self", "FRIEND" = "Friend",
                 "Self" = "Self", "Friend" = "Friend")
.id_std     <- c("YOU" = "Self", "FRIEND" = "Close",
                 "Self" = "Self", "Friend" = "Close")
.nanmean <- function(x) mean(x[is.finite(x)])          # 空/NaN 安全均值

# ---- 通用：按被试试次均值的方向核对（mean-of-subject-means） ----
.direction_check <- function(d, sa_col, acc_col, rt_col, subj_col,
                             label) {
  # 返回 list：matching 与 nonmatching 下 self/friend 的 RT(正确试次)/ACC 均值
  .cells <- list()
  for (m in c("Matching", "Nonmatching")) {
    for (s in c("Self", "Friend")) {
      .sub <- tapply(seq_len(nrow(d)), d[[subj_col]], function(i) {
        .dd <- d[i, ]
        .cc <- .dd[[sa_col]] == s & .dd$Matching == m
        .rt <- mean(.dd[[rt_col]][.cc & .dd[[acc_col]] == 1], na.rm = TRUE)
        .ac <- mean(.dd[[acc_col]][.cc], na.rm = TRUE)
        c(rt = .rt, acc = .ac)
      })
      .cells[[paste(m, s)]] <- c(
        rt = .nanmean(vapply(.sub, function(x) x["rt"], numeric(1))),
        acc = .nanmean(vapply(.sub, function(x) x["acc"], numeric(1))))
    }
  }
  cat("  --", label, "--\n")
  for (m in c("Matching", "Nonmatching")) {
    for (s in c("Self", "Friend")) {
      v <- .cells[[paste(m, s)]]
      cat(sprintf("    %-11s %-6s: RT %6.1f ms  ACC %5.1f%%\n",
                  m, s, v["rt"], v["acc"] * 100))
    }
  }
  .cells
}

# ============================================================================
# Exp1 — equal context（1 block x 200）
# ============================================================================
cat("== Exp1 ==\n")
.e1 <- as.data.frame(readxl::read_excel(.f1))
stopifnot(ncol(.e1) == 6, nrow(.e1) == 3370)          # 20 被试，作者文件行数
names(.e1) <- c("Participant #", "Trial Type", "Target Label",
                "Shape Association", "Target Accuracy", "Reponse Time")
.e1$Subject <- .e1$`Participant #`
.e1$Matching <- .e1$`Trial Type`
.e1$ACC <- as.integer(.e1$`Target Accuracy`)
.e1$RT_ms <- as.integer(.e1$`Reponse Time`)

# 守卫 1：结构（20 被试、每被试 <= 200 试次、值域）
stopifnot(length(unique(.e1$Subject)) == 20)
stopifnot(all(table(.e1$Subject) <= 200))             # 设计 200/人（预清洗后更少）
stopifnot(all(.e1$Matching %in% c("Matching", "Nonmatching")),
          all(.e1$`Target Label` %in% c("YOU", "FRIEND")),
          all(.e1$`Shape Association` %in% c("Self", "Friend")),
          all(.e1$ACC %in% c(0, 1)))
stopifnot(all(.e1$RT_ms >= 200))                      # 作者已排除 RT<200
# 守卫 2：Matching <=> (Label 身份 == Shape 身份)，全量 0 失配
stopifnot(all((.e1$Matching == "Matching") ==
              ((.e1$`Target Label` == "YOU") ==
               (.e1$`Shape Association` == "Self"))))
cat("guard OK: Exp1 3370 rows / 20 subjects; matching logic 0 mismatch; RT>=200\n")

# 身份三级列 + 标准列
.e1$Label_Origin_Identity <- .e1$`Target Label`
.e1$Label_English_Identity <- .id_english[.e1$`Target Label`]
.e1$Label_Standardized_Identity <- .id_std[.e1$`Target Label`]
.e1$Shape_Origin_Identity <- .e1$`Shape Association`
.e1$Shape_English_Identity <- .id_english[.e1$`Shape Association`]
.e1$Shape_Standardized_Identity <- .id_std[.e1$`Shape Association`]
.e1$Shape <- .e1$`Shape Association`                  # 无几何形状信息 → 身份词
.e1$Label <- .e1$`Target Label`
.e1$RT_sec <- .e1$RT_ms / 1000

# 方向核对（论文 Fig.1/2：matching self 最快最准；nonmatching friend 更快）
.c1 <- .direction_check(.e1, "Shape_English_Identity", "ACC", "RT_ms",
                        "Subject", "Exp1")
stopifnot(.c1[["Matching Self"]] ["rt"] < .c1[["Matching Friend"]] ["rt"],
          .c1[["Matching Self"]] ["acc"] > .c1[["Matching Friend"]] ["acc"],
          .c1[["Nonmatching Friend"]] ["rt"] < .c1[["Nonmatching Self"]] ["rt"])

# 产出 Exp1
.exp1_dir <- file.path(.study_dir, "Exp1")
dir.create(.exp1_dir, showWarnings = FALSE)
.raw1 <- .e1[, c("Participant #", "Trial Type", "Target Label",
                 "Shape Association", "Target Accuracy", "Reponse Time")]
write.csv(.raw1, file.path(.exp1_dir, "Svensson_2022_PsychRes_Exp1_raw.csv"),
          row.names = FALSE)
.cl1 <- .e1[, c("Subject", "Shape", "Label", "Matching",
                "Label_Origin_Identity", "Label_English_Identity",
                "Label_Standardized_Identity", "Shape_Origin_Identity",
                "Shape_English_Identity", "Shape_Standardized_Identity",
                "RT_ms", "RT_sec", "ACC")]
write_clean_csv(.cl1, file.path(.exp1_dir,
                                "Svensson_2022_PsychRes_Exp1_Clean.csv"))
.sj1 <- data.frame(Subject_ID = sort(unique(.e1$Subject)),
                   Exp_id = rep("Svensson_2022_PsychRes_Exp1", 20),
                   Age = rep("/", 20), Gender = rep("/", 20))
write_clean_csv(.sj1, file.path(.exp1_dir,
                                "Svensson_2022_PsychRes_Exp1_subj_info.csv"))
stopifnot(nrow(.cl1) == nrow(.raw1), nrow(.sj1) == 20)

# ============================================================================
# Exp2 — confirmatory context（2 blocks x 200；expectancy = 实际频率）
# ============================================================================
cat("== Exp2 ==\n")
.e2 <- as.data.frame(readxl::read_excel(.f2))
stopifnot(ncol(.e2) == 6, nrow(.e2) == 8335)
names(.e2) <- c("Participant #", "Trial Type", "Expectancy",
                "Shape Association", "Target Accuracy", "Response Time")
.e2$Subject <- .e2$`Participant #`
.e2$Matching <- .e2$`Trial Type`
.e2$ACC <- as.integer(.e2$`Target Accuracy`)
.e2$RT_ms <- as.integer(.e2$`Response Time`)

# 守卫 1：结构（24 被试、每被试 <= 400 试次、值域）
stopifnot(length(unique(.e2$Subject)) == 24)
stopifnot(all(table(.e2$Subject) <= 400))
stopifnot(all(.e2$Matching %in% c("Matching", "Nonmatching")),
          all(.e2$Expectancy %in% c("Self", "Friend")),
          all(.e2$`Shape Association` %in% c("Self", "Friend")),
          all(.e2$ACC %in% c(0, 1)),
          all(.e2$RT_ms >= 200))

# 守卫 2：Block = expectancy run（每被试恰 2 run）；block 内 SA 频率 75/25
.e2$Block <- ave(seq_len(nrow(.e2)), .e2$Subject, FUN = function(i) {
  .ex <- .e2$Expectancy[i]
  .run <- cumsum(c(TRUE, .ex[-1] != .ex[-length(.ex)]))
  stopifnot(max(.run) == 2)                            # 每被试恰 2 blocks
  .run
})
stopifnot(all(tapply(.e2$Block, .e2$Subject, function(x) length(unique(x)) == 2)))
# confirmatory：self-expectancy block 内 SA Self 应 ~75%，friend-expectancy 反之
.frq <- do.call(rbind, lapply(split(seq_len(nrow(.e2)), .e2$Subject), function(i) {
  .d <- .e2[i, ]
  do.call(rbind, lapply(unique(.d$Block), function(b) {
    .dd <- .d[.d$Block == b, ]
    data.frame(expect = unique(.dd$Expectancy),
               fracSelf = mean(.dd$`Shape Association` == "Self"))
  }))
}))
stopifnot(all(abs(.frq$fracSelf[.frq$expect == "Self"] - 0.75) < 0.15),
          all(abs(.frq$fracSelf[.frq$expect == "Friend"] - 0.25) < 0.15))
cat("guard OK: Exp2 8335 rows / 24 subjects; 2 blocks each; 75/25 balance\n")

# 身份三级列 + 标准列（Label 由 Trial Type + SA 推导）
.e2$Shape_Origin_Identity <- .e2$`Shape Association`
.e2$Shape_English_Identity <- .id_english[.e2$`Shape Association`]
.e2$Shape_Standardized_Identity <- .id_std[.e2$`Shape Association`]
.e2$Shape <- .e2$`Shape Association`
.e2$Label_derived <- ifelse(.e2$Matching == "Matching",
                            .e2$`Shape Association`,
                            ifelse(.e2$`Shape Association` == "Self",
                                   "Friend", "Self"))
.e2$Label_Origin_Identity <- .e2$Label_derived
.e2$Label_English_Identity <- .id_english[.e2$Label_derived]
.e2$Label_Standardized_Identity <- .id_std[.e2$Label_derived]
.e2$Label <- .e2$Label_derived
.e2$RT_sec <- .e2$RT_ms / 1000

# 方向核对（论文 Fig.3/4：实际高频身份更快更准，self 效应更大）
.c2 <- .direction_check(.e2, "Shape_English_Identity", "ACC", "RT_ms",
                        "Subject", "Exp2 (collapsed)")
# 分 expectancy 方向（confirmatory：expectancy = 实际频率）：
# self-expectancy block 内 self 更快；friend-expectancy 内 friend 更快
.byexp <- function(d, expval) {
  .d <- d[d$Expectancy == expval, ]
  .cells <- list()
  for (s in c("Self", "Friend")) {
    .sub <- tapply(seq_len(nrow(.d)), .d$Subject, function(i) {
      .dd <- .d[i, ]
      .cc <- .dd$Shape_English_Identity == s
      c(rt = mean(.dd$RT_ms[.cc & .dd$ACC == 1], na.rm = TRUE),
        acc = mean(.dd$ACC[.cc], na.rm = TRUE))
    })
    .cells[[s]] <- c(rt = .nanmean(vapply(.sub, function(x) x["rt"], numeric(1))),
                     acc = .nanmean(vapply(.sub, function(x) x["acc"], numeric(1))))
  }
  .cells
}
.bS <- .byexp(.e2, "Self")
.bF <- .byexp(.e2, "Friend")
cat(sprintf("  -- Exp2 self-expectancy blocks: self RT %.1f/ACC %.1f%% vs friend RT %.1f/ACC %.1f%%\n",
            .bS$Self["rt"], .bS$Self["acc"] * 100,
            .bS$Friend["rt"], .bS$Friend["acc"] * 100))
cat(sprintf("  -- Exp2 friend-expectancy blocks: friend RT %.1f/ACC %.1f%% vs self RT %.1f/ACC %.1f%%\n",
            .bF$Friend["rt"], .bF$Friend["acc"] * 100,
            .bF$Self["rt"], .bF$Self["acc"] * 100))
stopifnot(.bS$Self["rt"] < .bS$Friend["rt"],
          .bF$Friend["rt"] < .bF$Self["rt"])

# 产出 Exp2
.exp2_dir <- file.path(.study_dir, "Exp2")
dir.create(.exp2_dir, showWarnings = FALSE)
.raw2 <- .e2[, c("Participant #", "Trial Type", "Expectancy",
                 "Shape Association", "Target Accuracy", "Response Time")]
write.csv(.raw2, file.path(.exp2_dir, "Svensson_2022_PsychRes_Exp2_raw.csv"),
          row.names = FALSE)
.cl2 <- .e2[, c("Subject", "Block", "Expectancy", "Shape", "Label", "Matching",
                "Label_Origin_Identity", "Label_English_Identity",
                "Label_Standardized_Identity", "Shape_Origin_Identity",
                "Shape_English_Identity", "Shape_Standardized_Identity",
                "RT_ms", "RT_sec", "ACC")]
write_clean_csv(.cl2, file.path(.exp2_dir,
                                "Svensson_2022_PsychRes_Exp2_Clean.csv"))
.sj2 <- data.frame(Subject_ID = sort(unique(.e2$Subject)),
                   Exp_id = rep("Svensson_2022_PsychRes_Exp2", 24),
                   Age = rep("/", 24), Gender = rep("/", 24))
write_clean_csv(.sj2, file.path(.exp2_dir,
                                "Svensson_2022_PsychRes_Exp2_subj_info.csv"))
stopifnot(nrow(.cl2) == nrow(.raw2), nrow(.sj2) == 24)

# ============================================================================
# Exp3 — dis-confirmatory context（2 blocks x 200；expectancy ≠ 实际频率）
# ============================================================================
cat("== Exp3 ==\n")
.e3 <- as.data.frame(readxl::read_excel(.f3))
stopifnot(ncol(.e3) == 7, nrow(.e3) == 8786)
names(.e3) <- c("Participant #", "Trial Number", "Trial Type", "Expectancy",
                "Shape Association", "Target Accuracy", "Response Time")
.e3$Subject <- .e3$`Participant #`
.e3$Trial <- as.integer(.e3$`Trial Number`)
.e3$Matching <- .e3$`Trial Type`
.e3$ACC <- as.integer(.e3$`Target Accuracy`)
.e3$RT_ms <- as.integer(.e3$`Response Time`)

# 守卫 1：结构（25 被试、每被试 <= 400 试次、值域、trial 1-200/block）
stopifnot(length(unique(.e3$Subject)) == 25)
stopifnot(all(table(.e3$Subject) <= 400))
stopifnot(all(.e3$Matching %in% c("Matching", "Nonmatching")),
          all(.e3$Expectancy %in% c("Self", "Friend")),
          all(.e3$`Shape Association` %in% c("Self", "Friend")),
          all(.e3$ACC %in% c(0, 1)),
          all(.e3$RT_ms >= 200),
          all(.e3$Trial >= 1 & .e3$Trial <= 200))

# 守卫 2：行序 = (ACC desc, block, trial) → 两 ACC 组内 trial 重启各 1 次、
#   expectancy run 各 2 次且顺序一致 → Block 可确定派生
.e3$Block <- ave(seq_len(nrow(.e3)), .e3$Subject, FUN = function(i) {
  .d <- .e3[i, ]
  .blk <- integer(length(i))
  for (g in c(1, 0)) {                               # ACC 组
    .gi <- which(.d$ACC == g)
    .tn <- .d$Trial[.gi]
    .restart <- cumsum(c(TRUE, .tn[-1] < .tn[-length(.tn)]))
    stopifnot(max(.restart) == 2)                    # 每 ACC 组恰 2 blocks
    .blk[.gi] <- .restart
  }
  # 两 ACC 组的 expectancy 顺序必须一致（同 block 序）
  .seq1 <- unique(.d$Expectancy[.d$ACC == 1][order(.blk[.d$ACC == 1])])
  .seq0 <- unique(.d$Expectancy[.d$ACC == 0][order(.blk[.d$ACC == 0])])
  stopifnot(length(.seq1) == 2, length(.seq0) == 2,
            identical(as.character(.seq1), as.character(.seq0)))
  .blk
})
# dis-confirmatory：self-expectancy block 内 SA Self 应 ~25%（friend 实际 75%），
# friend-expectancy 反之
.frq3 <- do.call(rbind, lapply(split(seq_len(nrow(.e3)), .e3$Subject), function(i) {
  .d <- .e3[i, ]
  do.call(rbind, lapply(unique(.d$Block), function(b) {
    .dd <- .d[.d$Block == b, ]
    data.frame(expect = unique(.dd$Expectancy),
               fracSelf = mean(.dd$`Shape Association` == "Self"))
  }))
}))
stopifnot(all(abs(.frq3$fracSelf[.frq3$expect == "Self"] - 0.25) < 0.15),
          all(abs(.frq3$fracSelf[.frq3$expect == "Friend"] - 0.75) < 0.15))
cat("guard OK: Exp3 8786 rows / 25 subjects; 2 blocks each; dis-confirmatory 25/75 balance\n")

# 身份三级列 + 标准列（Label 推导同上）
.e3$Shape_Origin_Identity <- .e3$`Shape Association`
.e3$Shape_English_Identity <- .id_english[.e3$`Shape Association`]
.e3$Shape_Standardized_Identity <- .id_std[.e3$`Shape Association`]
.e3$Shape <- .e3$`Shape Association`
.e3$Label_derived <- ifelse(.e3$Matching == "Matching",
                            .e3$`Shape Association`,
                            ifelse(.e3$`Shape Association` == "Self",
                                   "Friend", "Self"))
.e3$Label_Origin_Identity <- .e3$Label_derived
.e3$Label_English_Identity <- .id_english[.e3$Label_derived]
.e3$Label_Standardized_Identity <- .id_std[.e3$Label_derived]
.e3$Label <- .e3$Label_derived
.e3$RT_sec <- .e3$RT_ms / 1000

# 方向核对（论文 Fig.5/6：实际高频身份更快，self 效应更大）
.c3 <- .direction_check(.e3, "Shape_English_Identity", "ACC", "RT_ms",
                        "Subject", "Exp3 (collapsed)")
# 分 expectancy 方向（dis-confirmatory：expectancy ≠ 实际频率）：
# self-expectancy block 实际 friend 形状 75% → friend 更快；
# friend-expectancy block 实际 self 形状 75% → self 更快
.bS3 <- .byexp(.e3, "Self")
.bF3 <- .byexp(.e3, "Friend")
cat(sprintf("  -- Exp3 self-expectancy blocks (friend actually frequent): friend RT %.1f/ACC %.1f%% vs self RT %.1f/ACC %.1f%%\n",
            .bS3$Friend["rt"], .bS3$Friend["acc"] * 100,
            .bS3$Self["rt"], .bS3$Self["acc"] * 100))
cat(sprintf("  -- Exp3 friend-expectancy blocks (self actually frequent): self RT %.1f/ACC %.1f%% vs friend RT %.1f/ACC %.1f%%\n",
            .bF3$Self["rt"], .bF3$Self["acc"] * 100,
            .bF3$Friend["rt"], .bF3$Friend["acc"] * 100))
stopifnot(.bS3$Friend["rt"] < .bS3$Self["rt"],
          .bF3$Self["rt"] < .bF3$Friend["rt"])

# 产出 Exp3
.exp3_dir <- file.path(.study_dir, "Exp3")
dir.create(.exp3_dir, showWarnings = FALSE)
.raw3 <- .e3[, c("Participant #", "Trial Number", "Trial Type", "Expectancy",
                 "Shape Association", "Target Accuracy", "Response Time")]
write.csv(.raw3, file.path(.exp3_dir, "Svensson_2022_PsychRes_Exp3_raw.csv"),
          row.names = FALSE)
.cl3 <- .e3[, c("Subject", "Block", "Trial", "Expectancy", "Shape", "Label",
                "Matching", "Label_Origin_Identity", "Label_English_Identity",
                "Label_Standardized_Identity", "Shape_Origin_Identity",
                "Shape_English_Identity", "Shape_Standardized_Identity",
                "RT_ms", "RT_sec", "ACC")]
write_clean_csv(.cl3, file.path(.exp3_dir,
                                "Svensson_2022_PsychRes_Exp3_Clean.csv"))
.sj3 <- data.frame(Subject_ID = sort(unique(.e3$Subject)),
                   Exp_id = rep("Svensson_2022_PsychRes_Exp3", 25),
                   Age = rep("/", 25), Gender = rep("/", 25))
write_clean_csv(.sj3, file.path(.exp3_dir,
                                "Svensson_2022_PsychRes_Exp3_subj_info.csv"))
stopifnot(nrow(.cl3) == nrow(.raw3), nrow(.sj3) == 25)

cat("DONE. Exp1 20 / Exp2 24 / Exp3 25 subjects; all guards passed.\n")
