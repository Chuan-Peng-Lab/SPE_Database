# ============================================================================
# Atzeni_2026_PsychRes — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1）
# ----------------------------------------------------------------------------
# 背景（2026-08-31 阶段 5 入库）：Atzeni et al. (2026), "A multi-faceted approach
# to the study of the relationship between self-esteem and the self-prioritization
# effect", Psychological Research, DOI 10.1007/s00426-026-02365-8（online first
# 2026-08-25）。SPE-自尊纵向研究（OSF tmk5b），3 会话各间隔约 1 周：
#   S1: SE-IAT + NLT + RSES（无匹配任务）；S2: IAT + RSES + 匹配任务；
#   S3: 仅匹配任务（沿用 S2 学习的形状-身份绑定）。全程在线（PsychoPy
#   2022.2.4 + Pavlovia）；帕多瓦大学（Italy）心理学本科生；伦理
#   Protocol 987-a（2025-01-24）。本库只收匹配任务（S2 + S3 两个时点）。
#
# 任务（shape-label matching，Sui et al. 2012 范式）：20 练习试次（数据不
# 含）→ 200 正式试次 = 4 条件各 50（match_self/match_other/nonmatch_self/
# nonmatch_other；形状 2 个 square/triangle × 标签 2 个 TU/SCONOSCIUTO）。
# 500 ms fixation → 100 ms 刺激（形状+标签同时）→ 1500 ms 空白响应窗 →
# 500 ms 反馈（"OK"）。形状-身份绑定逐被试 counterbalance（condizione 1:
# square=self / condizione 2: triangle=self）。
#
# 数据（输入区 tmk5b/data/analysis/T2|T3/matching_task_*.csv，作者聚合导出，
# 无逐被试原始文件）：
#   participant condizione type_trial(exp) label(TU/SCONOSCIUTO)
#   shape(images/square.png|triangle.png) matching_task.corr(1/0)
#   matching_task.rt(秒；无反应行 rt='NA' 而 corr=0——作者 miss 口径)
#   shape_type square/triangle who(self/other = 标签身份，冗余列)
#   trial_type(match_self/match_other/nonmatch_self/nonmatch_other = 实际
#   4 组合编码；match ⟺ (label==TU)==(shape==自形状(按 condizione)))
# 样本：T2 116 人（119 参加，3 人数据缺失）；T3 93 人（97 参加，4 缺失）；
# 重叠 69 人。T2 有 3 人（GSMA/JRHA/LFVI）400 行 = 两次 session 拼接（作者
# 分析剔除）；T3 有 4 人（CTNA/FPMA/ESAD/mtma）>200 行（作者剔除）、2 人
# 部分（LFFI 150 / RCJE 137）。库内全保留（最小预处理），Note/JSON 记录。
#
# 身份映射（用户确认 2026-08-31）：Label Origin=TU/SCONOSCIUTO（意大利语
# 原样）→ English You/Stranger → Std Self/Stranger；Shape 列=实际形状名
# （square/triangle），形状身份按 condizione（self/stranger）→ Std
# Self/Stranger。无反应（rt NA）→ ACC=NA、RT_ms=NA（项目约定；作者记 0）。
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
.study_dir <- file.path(.root, "1_Data", "Atzeni_2026_PsychRes")
.arch <- file.path(.study_dir, "Atzeni_2026_PsychRes_Raw", "tmk5b-osfstorage-archive")
stopifnot(dir.exists(.arch))

# ---- 读入 T2/T3 ----
.read_time <- function(t, lab) {
  d <- read.csv(file.path(.arch, "data", "analysis", t,
                          paste0("matching_task_", lab, ".csv")),
                stringsAsFactors = FALSE, na.strings = c("", "NA"))
  d$Session <- as.integer(lab)
  d
}
dat <- rbind(.read_time("T2", 2), .read_time("T3", 3))
dat$Subject <- trimws(dat$participant)   # 3 个 ID 含前导/尾随空白（' EMMA'/'ccim '/'GGMA '），归一
cat("rows:", nrow(dat), "| T2:", sum(dat$Session == 2), "| T3:", sum(dat$Session == 3), "\n")

# ---- 守卫 1：样本结构 ----
.sub2 <- unique(dat$Subject[dat$Session == 2]); .sub3 <- unique(dat$Subject[dat$Session == 3])
stopifnot(length(.sub2) == 116, length(.sub3) == 93,
          length(unique(dat$Subject)) == 140)
cat("guard 1 OK: T2", length(.sub2), "T3", length(.sub3),
    "unique", length(unique(dat$Subject)), "(overlap", length(intersect(.sub2, .sub3)), ")\n")

# ---- 守卫 2：trial_type 语义（match ⟺ (label==TU)==(shape==self-shape)） ----
.self_shape <- ifelse(dat$condizione == "condizione 1", "images/square.png",
                      "images/triangle.png")
stopifnot(all((dat$trial_type %in% c("match_self", "match_other")) ==
                ((dat$label == "TU") == (dat$shape == .self_shape))))
stopifnot(all((dat$who == "self") == (dat$label == "TU")))   # who = 标签身份
cat("guard 2 OK: trial_type mapping consistent for all", nrow(dat), "trials\n")

# ---- 守卫 3：每被试每时点试次数（200 或作者重复/部分 session） ----
.n <- tapply(dat$trial, paste(dat$Subject, dat$Session), length)
cat("guard 3: trials per subject x time:", paste(names(table(.n)), table(.n),
                                                 collapse = "; "), "\n")

# ---- 守卫 4：condizione 平衡 ----
stopifnot(all(dat$condizione %in% c("condizione 1", "condizione 2")))

# ---- 派生列 ----
dat$Matching <- ifelse(dat$trial_type %in% c("match_self", "match_other"),
                       "Matching", "Nonmatching")
dat$Label_Origin_Identity <- dat$label            # TU/SCONOSCIUTO 原样
dat$Label_English_Identity <- ifelse(dat$label == "TU", "You", "Stranger")
dat$Label_Standardized_Identity <- ifelse(dat$label == "TU", "Self", "Stranger")
.shape_id <- ifelse(dat$shape == .self_shape, "self", "stranger")
dat$Shape_Origin_Identity <- .shape_id            # 形状身份（按 condizione 推导）
dat$Shape_English_Identity <- .shape_id
dat$Shape_Standardized_Identity <- ifelse(.shape_id == "self", "Self", "Stranger")
.no_resp <- is.na(dat$matching_task.rt)
dat$ACC <- ifelse(.no_resp, NA_integer_, as.integer(dat$matching_task.corr))
dat$RT_ms <- ifelse(.no_resp, NA_integer_, round(dat$matching_task.rt * 1000))
dat$RT_sec <- dat$RT_ms / 1000
dat$Trial <- ave(seq_len(nrow(dat)), dat$Subject, dat$Session, FUN = seq_along)
# rt 全量 0.03-1.58 s（响应窗 1500 ms 内）；唯一 1 行 rt=0 保留原值（最小预处理）
stopifnot(all(dat$RT_ms[!is.na(dat$RT_ms)] >= 0 &
              dat$RT_ms[!is.na(dat$RT_ms)] < 5000))

# ---- 行序 ----
dat <- dat[order(dat$Subject, dat$Session, seq_len(nrow(dat))), ]

# ---- 产出 1：raw（作者原始列 + Subject + Session） ----
.raw <- dat[, c("Subject", "Session", "participant", "condizione", "type_trial",
                "label", "shape", "matching_task.corr", "matching_task.rt",
                "shape_type", "who", "trial_type")]
write.csv(.raw, file.path(.study_dir, "Atzeni_2026_PsychRes_Exp1_raw.csv"),
          row.names = FALSE)
cat("  raw:", nrow(.raw), "rows\n")

# ---- 产出 2：Clean（标准列 + Session/Condition） ----
.cl <- data.frame(
  Subject = dat$Subject,
  Session = dat$Session,
  Condition = dat$condizione,
  Trial = dat$Trial,
  Shape = sub("images/", "", dat$shape),           # square/triangle
  Label = dat$label,                               # TU/SCONOSCIUTO
  Matching = dat$Matching,
  Label_Origin_Identity = dat$Label_Origin_Identity,
  Label_English_Identity = dat$Label_English_Identity,
  Label_Standardized_Identity = dat$Label_Standardized_Identity,
  Shape_Origin_Identity = dat$Shape_Origin_Identity,
  Shape_English_Identity = dat$Shape_English_Identity,
  Shape_Standardized_Identity = dat$Shape_Standardized_Identity,
  RT_ms = dat$RT_ms, RT_sec = dat$RT_sec, ACC = dat$ACC,
  stringsAsFactors = FALSE)
write_clean_csv(.cl, file.path(.study_dir, "Atzeni_2026_PsychRes_Exp1_Clean.csv"))
stopifnot(nrow(.cl) == nrow(.raw), length(unique(.cl$Subject)) == 140)
cat("  Clean:", nrow(.cl), "rows /", length(unique(.cl$Subject)),
    "subjects; self-match RT mean (T2) =",
    round(mean(.cl$RT_ms[.cl$Session == 2 &
                         .cl$Label_Standardized_Identity == "Self" &
                         .cl$Matching == "Matching"], na.rm = TRUE), 1), "ms\n")

# ---- 产出 3：subj_info（140 行；无人口学数据，T2/T3 完成标记） ----
.s0 <- dat[!duplicated(dat$Subject), ]
.subj <- data.frame(
  Subject_ID = .s0$Subject,
  Exp_id = rep("Atzeni_2026_PsychRes_Exp1", nrow(.s0)),
  T2 = as.integer(.s0$Subject %in% .sub2),
  T3 = as.integer(.s0$Subject %in% .sub3),
  Age = rep("/", nrow(.s0)),
  Gender = rep("/", nrow(.s0)),
  stringsAsFactors = FALSE)
.subj <- .subj[order(.subj$Subject_ID), ]
stopifnot(nrow(.subj) == 140, sum(.subj$T2) == 116, sum(.subj$T3) == 93)
write_clean_csv(.subj, file.path(.study_dir, "Atzeni_2026_PsychRes_Exp1_subj_info.csv"))
cat("  subj_info:", nrow(.subj), "rows; T2", sum(.subj$T2), "/ T3", sum(.subj$T3), "\n")

cat("DONE. 140 unique subjects (T2 116 / T3 93); ACC/RT guards passed.\n")
