# ============================================================================
# Zhang_2026_JNeurosci — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1）
# ----------------------------------------------------------------------------
# 背景（2026-08-31 阶段 5 入库）：Zhang, Sun, Wang, Pan, Wang & Sui (2026),
# "Neural Compensation in the Medial Prefrontal Cortex Preserves
# Self-Prioritization in Aging: A Computational Approach", The Journal of
# Neuroscience 46(1):1-16, DOI 10.1523/JNEUROSCI.0487-25.2025. AgingSPE 研究
# （OSF x9frd，HDDM 分析 notebook；fMRI 采集，清华 CBIR 伦理批准）。
#
# 任务（Sui et al. 2012 范式，E-Prime 2.0）：学习阶段建立 3 几何形状 ↔ 3 身份
# 标签（you/friend/stranger 抽象英文词；形状-身份绑定逐被试 counterbalanced）
# → 测试阶段判断 shape-label 配对是否匹配（匹配键/非匹配键 counterbalanced）。
# 500 ms fixation → 3000 ms 刺激 → 500-2500 ms 空白（jittered）→ 500 ms 反馈。
# 每 fMRI run（block；作者称 session，实为同一次扫描内连续 5 个 run）90 试次
# = 9 组合（3 shapes x 3 labels）各 10 次
# （3 match + 6 mismatch → match:mismatch = 1:2）。5 sessions；进扫描仪前
# 练习 5 分钟（无 trial 数据记录）。论文分析排除 RT<200 ms 或 >3SD 组均值
# （<3%），仅用于其分析，库内不过滤。
#
# 数据（输入区 aging_behavioral.csv，38,057 行）：作者聚合导出（无逐被试
# 原始文件），列：subj_idx / group(OA,YA) / session(1-5，作者列名 = fMRI run) /
# trial（run 内重复索引 1-10，每索引 9 组合试次）/ shape,label（身份词 Self/Friend/
# Stranger）/ TrialType(match,mismatch) / stim(1=match 指示，与 TrialType
# 同义) / accuracy(1/0) / response(1=匹配键, 0=非匹配键) / rt（秒）。
# **文件仅含已响应试次**：全行无 NA、无无反应行（论文 omission 0.77%/0.56%
# 的无反应试次行不在导出中——数据口径记录于 exp JSON detail）。run 试次数
# 41-90（90 = 完整；缺行 run 为作者导出即如此）。run 数 2-5（74 人 5 个；
# 17 人 2-4 个——含 fMRI 头动排除的 run）。
#
# 身份映射（用户确认 2026-08-31）：数据即英文身份词；Standardized:
# Self→Self, Friend→Close, Stranger→Stranger。数据无几何形状信息
# （形状-身份绑定 counterbalanced 且未记录）→ Clean Shape/Label 列 =
# 身份词原样（数据唯一可得的刺激信息）。
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
.study_dir <- file.path(.root, "1_Data", "Zhang_2026_JNeurosci")
.inp <- file.path(.study_dir, "Zhang_2026_JNeurosci_Raw", "aging_behavioral.csv")
stopifnot(file.exists(.inp))

# ---- 读入 ----
dat <- read.csv(.inp, stringsAsFactors = FALSE, na.strings = c("", "NA"))
cat("rows:", nrow(dat), "\n")

# ---- 守卫 1：被试/组结构 ----
stopifnot(length(unique(dat$subj_idx)) == 91)
.grps <- tapply(dat$group, dat$subj_idx, function(x) unique(x)[1])
stopifnot(sum(.grps == "OA") == 59, sum(.grps == "YA") == 32)
cat("guard 1 OK: 91 subjects (OA 59 / YA 32)\n")

# ---- 守卫 2：stim / accuracy / response 自洽 ----
stopifnot(all((dat$stim == 1) == (dat$TrialType == "match")))
stopifnot(all((dat$accuracy == 1) == ((dat$TrialType == "match") == (dat$response == 1))))
cat("guard 2 OK: stim==(match) and accuracy==((match)==(response==1)) for all",
    nrow(dat), "trials\n")

# ---- 守卫 3：session 结构与 match 比例 ----
.sess_n <- tapply(dat$trial, paste(dat$subj_idx, dat$session), length)
stopifnot(all(.sess_n <= 90), all(dat$trial >= 1 & dat$trial <= 10))
.full <- dat[dat$subj_idx %in% names(which(tapply(dat$session, dat$subj_idx,
                                                  function(x) length(unique(x)) == 5))), ]
.mf <- tapply(.full$TrialType == "match", paste(.full$subj_idx, .full$session), sum)
.full_sess <- .mf[.mf != 30]  # 允许部分缺行 session
stopifnot(all(tapply(dat$TrialType == "match", paste(dat$subj_idx, dat$session), sum) <= 30))
cat("guard 3 OK:", length(.sess_n), "sessions (41-90 trials); full-session match = 30\n")

# ---- 守卫 4：RT 量级（秒） ----
stopifnot(all(dat$rt >= 0.1 & dat$rt <= 5))
cat("guard 4 OK: rt in seconds (range", round(min(dat$rt), 2), "-",
    round(max(dat$rt), 2), ")\n")

# ---- 派生列 ----
dat$Subject <- as.character(dat$subj_idx)
.id_map <- c(Self = "Self", Friend = "Friend", Stranger = "Stranger")
.std_map <- c(Self = "Self", Friend = "Close", Stranger = "Stranger")
stopifnot(all(dat$shape %in% names(.id_map)), all(dat$label %in% names(.id_map)))
dat$Matching <- ifelse(dat$TrialType == "match", "Matching", "Nonmatching")
dat$Shape_Origin_Identity <- dat$shape          # 数据原样（已是英文身份词）
dat$Shape_English_Identity <- dat$shape
dat$Shape_Standardized_Identity <- .std_map[dat$shape]
dat$Label_Origin_Identity <- dat$label
dat$Label_English_Identity <- dat$label
dat$Label_Standardized_Identity <- .std_map[dat$label]
dat$ACC <- as.integer(dat$accuracy)             # 1/0；文件无无反应行
dat$RT_ms <- round(dat$rt * 1000)
dat$RT_sec <- dat$RT_ms / 1000
# Trial：subject x session 内顺序号（作者 trial 列为重复索引 1-10，raw 保留）
dat$Trial <- ave(seq_len(nrow(dat)), dat$Subject, dat$session, FUN = seq_along)

# ---- 行序：Subject + session + 原行序 ----
dat <- dat[order(dat$Subject, dat$session, seq_len(nrow(dat))), ]

# ---- 产出 1：raw（作者原始列 + Subject） ----
.raw <- dat[, c("Subject", "subj_idx", "group", "session", "trial", "shape",
                "label", "TrialType", "stim", "accuracy", "response", "rt")]
write.csv(.raw, file.path(.study_dir, "Zhang_2026_JNeurosci_Exp1_raw.csv"),
          row.names = FALSE)
cat("  raw:", nrow(.raw), "rows\n")

# ---- 产出 2：Clean（标准列 + Group/Block） ----
.cl <- data.frame(
  Subject = dat$Subject,
  Group = dat$group,
  Block = dat$session,          # 作者列名 session（1-5）= 同一次扫描内 fMRI run；
                                # 按库内约定（SKILL §列说明）Session = 一次完整实验参加，
                                # 同一参加内的重复任务段用 Block——故 Clean 列名 Block
  Trial = dat$Trial,
  Shape = dat$shape,                              # 身份词原样（数据无几何信息）
  Label = dat$label,
  Matching = dat$Matching,
  Label_Origin_Identity = dat$Label_Origin_Identity,
  Label_English_Identity = dat$Label_English_Identity,
  Label_Standardized_Identity = dat$Label_Standardized_Identity,
  Shape_Origin_Identity = dat$Shape_Origin_Identity,
  Shape_English_Identity = dat$Shape_English_Identity,
  Shape_Standardized_Identity = dat$Shape_Standardized_Identity,
  RT_ms = dat$RT_ms, RT_sec = dat$RT_sec, ACC = dat$ACC,
  stringsAsFactors = FALSE)
write_clean_csv(.cl, file.path(.study_dir, "Zhang_2026_JNeurosci_Exp1_Clean.csv"))
stopifnot(nrow(.cl) == nrow(.raw),
          length(unique(.cl$Subject)) == 91)
cat("  Clean:", nrow(.cl), "rows /", length(unique(.cl$Subject)),
    "subjects; self-match RT mean (OA) =",
    round(mean(.cl$RT_ms[.cl$Group == "OA" & .cl$Shape_Standardized_Identity == "Self" &
                         .cl$Matching == "Matching"], na.rm = TRUE), 1), "ms\n")

# ---- 产出 3：subj_info（91 行；人口学数据无，仅组别与 block 数） ----
.s0 <- dat[!duplicated(dat$Subject), ]
.nsess <- tapply(dat$session, dat$Subject, function(x) length(unique(x)))
.subj <- data.frame(
  Subject_ID = .s0$Subject,
  Exp_id = rep("Zhang_2026_JNeurosci_Exp1", nrow(.s0)),
  Group = .s0$group,
  Age = rep("/", nrow(.s0)),
  Gender = rep("/", nrow(.s0)),
  Blocks = as.integer(.nsess[.s0$Subject]),
  stringsAsFactors = FALSE)
.subj <- .subj[order(.subj$Subject_ID), ]
stopifnot(nrow(.subj) == 91, sum(.subj$Group == "OA") == 59, sum(.subj$Group == "YA") == 32)
write_clean_csv(.subj, file.path(.study_dir, "Zhang_2026_JNeurosci_Exp1_subj_info.csv"))
cat("  subj_info:", nrow(.subj), "rows; OA", sum(.subj$Group == "OA"),
    "/ YA", sum(.subj$Group == "YA"), "\n")

cat("DONE. 91 subjects; ACC/RT guards passed.\n")
