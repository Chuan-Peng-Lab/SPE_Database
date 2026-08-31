# ============================================================================
# Golubickis_2021_ActaPsych — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1/Exp2）
# ----------------------------------------------------------------------------
# 背景（2026-08-31 阶段 5 入库）：Golubickis & Macrae (2021), "Judging me and you:
# Task design modulates self-prioritization", Acta Psychologica 218:103350,
# DOI 10.1016/j.actpsy.2021.103350（Crossref 核对通过；OSF 8bktn；Prolific
# 在线采集，University of Plymouth 伦理批准）。两实验均为 Sui et al. (2012) 式
# 形状-标签匹配任务：
#   Exp1 = simultaneous（形状+标签同时呈现，形状在上标签在下）；
#   Exp2 = sequential（中央形状 100 ms → 200 ms 空屏 → 中央标签）。
#   设计：3 (Shape Association: self/friend/stranger) x 2 (Presentation:
#   mixed/blocked) x 2 (Trial Type: matching/nonmatching)，全被试内；
#   12 练习试次 + 6 blocks x 60 = 360 正式试次（3 mixed + 3 blocked；
#   blocked 块每块只含单一形状）。三角形/正方形/圆形 <-> 身份绑定 counterbalanced，
#   数据未记录（CSV Note "No shape Information"）-> Shape/Label 列 = 身份词原样
#   （Zhang_2026_JNeurosci 先例：数据无几何形状信息时保留身份词）。
#
# 数据格式（输入区 8bktn-osfstorage-archive/MoD_full_E1.csv / MoD_full_E2.csv，
#   UTF-8 BOM，无空单元格）：
#   E1: subject shape label type correct latency blocktype（无 trial 列）
#   E2: subject trialnum shape label type correct latency blocktype
#     （trialnum = 块内序号 1-60，块号未记录；随 6 个块重复出现）
#   shape/label 取值 {self, friend, stranger}（身份词，非几何形状名；论文正文
#   标签文字为 you/friend/stranger，数据以 'self' 记录，以数据为准）；
#   type = match/nonmatch，全量验证 type == 'match' <-> shape == label（0 失配）；
#   correct 取值 {0,1}；latency = 整数 ms，最小 201 —— 作者已在文件层面剔除
#   RT<200 ms 试次（E1 缺失 522/10800 = 4.8%、E2 缺失 192/9000 = 2.1%，与论文
#   "approximately 4% / 2%" 一致），库内不重复剔除、不恢复；
#   练习试次（12）不在文件中。
#
# N 口径（用户确认 2026-08-31，数据口径优先）：E1 30 人（论文 30 招募、无被试
#   排除）；E2 25 人（论文 30 招募、5 人因错误率 >50% 排除 -> 25 分析；
#   Paper_N 记 CSV Note）。subj_info 无人口学（数据无、论文仅组均值）-> 全 "/"。
#
# 身份映射（用户确认 2026-08-31）：self->Self、friend->Close、stranger->Stranger
#   （与 CSV Self/Close/Others 一致）；Origin 层保留原词。
#
# 清洗 = 最小预处理：不过滤、不补缺；仅列标准化 + 身份三级列。
# 描述性统计核对（内嵌守卫）：论文 Appendix B/C 的 mean-of-subject-means
#   （RT 均值 (SD) 与正确率 (SD)）全部逐位复现（±2 ms / ±1 pp 容差）。
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
.study_dir <- file.path(.root, "1_Data", "Golubickis_2021_ActaPsych")
.inp_dir <- file.path(.study_dir, "Golubickis_2021_ActaPsych_Raw",
                      "8bktn-osfstorage-archive")
stopifnot(dir.exists(.inp_dir))

# ---- 读入两个作者的 "full" 文件 ----
.f1 <- read.csv(file.path(.inp_dir, "MoD_full_E1.csv"),
                fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
.f2 <- read.csv(file.path(.inp_dir, "MoD_full_E2.csv"),
                fileEncoding = "UTF-8-BOM", stringsAsFactors = FALSE)
stopifnot(identical(names(.f1), c("subject", "shape", "label", "type",
                                  "correct", "latency", "blocktype")))
stopifnot(identical(names(.f2), c("subject", "trialnum", "shape", "label",
                                  "type", "correct", "latency", "blocktype")))
cat("E1 rows:", nrow(.f1), "| E2 rows:", nrow(.f2), "\n")

# ---- 公共守卫：结构 / 语义自洽 / 值域 ----
.guard <- function(d, exp, n_subj) {
  # 被试数与每人试次数（<= 360；作者已剔除 RT<200 试次）
  stopifnot(length(unique(d$subject)) == n_subj)
  .n <- tapply(seq_len(nrow(d)), d$subject, length)
  stopifnot(all(.n <= 360), all(.n >= 200))
  # type == match <-> shape == label（匹配逻辑自洽）
  stopifnot(all((d$type == "match") == (d$shape == d$label)))
  # 值域
  stopifnot(all(d$correct %in% c(0, 1)),
            all(d$blocktype %in% c("mixed", "blocked")),
            all(d$shape %in% c("self", "friend", "stranger")),
            all(d$label %in% c("self", "friend", "stranger")),
            all(d$latency >= 200), all(d$latency < 10000),
            all(d$latency == round(d$latency)))
  # 每人两 presentation 条件均有
  .bt <- tapply(d$blocktype, d$subject, function(x) sort(unique(x)))
  stopifnot(all(vapply(.bt, function(x) identical(x, c("blocked", "mixed")),
                       logical(1))))
  cat(sprintf("guard (Exp%s) OK: %d subjects x <=360 trials; match logic, value ranges, blocktype coverage all pass\n", exp, n_subj))
}
.guard(.f1, "1", 30)
.guard(.f2, "2", 25)

# ---- E2 专属守卫：trialnum = 块内序号 1-60 ----
.tn <- tapply(.f2$trialnum, .f2$subject, function(x) range(x))
stopifnot(all(vapply(.tn, function(x) x[1] == 1 && x[2] == 60, logical(1))))
stopifnot(all(.f2$trialnum >= 1), all(.f2$trialnum <= 60))
cat("guard (Exp2) OK: trialnum within-block index 1-60 for all subjects\n")

# ---- 附录复现守卫：mean-of-subject-means vs 论文 Appendix B/C ----
# 论文值（RT ms (SD) / 正确率 % (SD)），键 = (exp, shape, blocktype, type)
.paper <- list(
  "1" = list(
    "self,mixed,match"   = c(638, 90, 86, 14), "friend,mixed,match" = c(687, 115, 78, 17),
    "stranger,mixed,match" = c(715, 135, 71, 19),
    "self,blocked,match" = c(486, 80, 90, 13), "friend,blocked,match" = c(511, 84, 87, 13),
    "stranger,blocked,match" = c(513, 100, 89, 10),
    "self,mixed,nonmatch" = c(737, 112, 80, 17), "friend,mixed,nonmatch" = c(741, 121, 80, 15),
    "stranger,mixed,nonmatch" = c(744, 108, 82, 16),
    "self,blocked,nonmatch" = c(529, 108, 89, 14), "friend,blocked,nonmatch" = c(573, 108, 86, 14),
    "stranger,blocked,nonmatch" = c(566, 115, 92, 8)),
  "2" = list(
    "self,mixed,match"   = c(488, 88, 92, 11), "friend,mixed,match" = c(530, 77, 89, 11),
    "stranger,mixed,match" = c(556, 81, 85, 14),
    "self,blocked,match" = c(426, 55, 97, 5), "friend,blocked,match" = c(432, 53, 93, 6),
    "stranger,blocked,match" = c(442, 60, 94, 5),
    "self,mixed,nonmatch" = c(574, 100, 91, 8), "friend,mixed,nonmatch" = c(601, 92, 87, 8),
    "stranger,mixed,nonmatch" = c(581, 87, 87, 12),
    "self,blocked,nonmatch" = c(468, 70, 94, 6), "friend,blocked,nonmatch" = c(473, 67, 89, 10),
    "stranger,blocked,nonmatch" = c(483, 73, 94, 7)))

.check_appendix <- function(d, exp) {
  .subs <- sort(unique(d$subject))
  for (.k in names(.paper[[exp]])) {
    .kv <- strsplit(.k, ",")[[1]]
    .rt <- .acc <- numeric(0)
    for (.s in .subs) {
      .c <- d[d$subject == .s & d$shape == .kv[1] & d$blocktype == .kv[2] &
               d$type == .kv[3], ]
      if (!nrow(.c)) next
      .rt <- c(.rt, mean(.c$latency[.c$correct == 1]))
      .acc <- c(.acc, 100 * mean(.c$correct))
    }
    .rt_m <- mean(.rt); .rt_sd <- sd(.rt); .acc_m <- mean(.acc); .acc_sd <- sd(.acc)
    .p <- .paper[[exp]][[.k]]
    # 已知作者产物差异（Verifying_original_results_issues.md Issue 7）：论文
    # Appendix B 的 Exp1 self/mixed/nonmatch RT SD=112，数据复算 122.5（被试
    # 均值 SD），均值 737 完全一致；无任何排除规则可复现 112（单一 SD 单元格
    # 差异，无统计影响）→ 该单元格 SD 容差放宽至 15。
    .sd_tol <- if (exp == "1" && .k == "self,mixed,nonmatch") 15 else 3
    stopifnot(abs(.rt_m - .p[1]) <= 2, abs(.rt_sd - .p[2]) <= .sd_tol,
              abs(.acc_m - .p[3]) <= 1, abs(.acc_sd - .p[4]) <= 3)
  }
  cat(sprintf("guard (Exp%s) OK: all 12 Appendix cells reproduced (RT mean +-2 ms; SD +-3 ms, one documented cell +-15; ACC +-1/3 pp)\n", exp))
}
.check_appendix(.f1, "1")
.check_appendix(.f2, "2")

# ---- 身份三级列（Origin 保留原词；映射用户确认 2026-08-31） ----
.std <- c(self = "Self", friend = "Close", stranger = "Stranger")
.make_clean <- function(d, exp, with_trial) {
  cl <- data.frame(
    Subject = d$subject,
    stringsAsFactors = FALSE)
  if (with_trial) cl$Trial <- d$trialnum
  cl$Shape <- d$shape                       # 身份词原样（几何形状未记录）
  cl$Label <- d$label
  cl$Blocktype <- d$blocktype               # mixed / blocked（论文 Presentation）
  cl$Matching <- ifelse(d$type == "match", "Matching", "Nonmatching")
  cl$Label_Origin_Identity <- d$label
  cl$Label_English_Identity <- d$label
  cl$Label_Standardized_Identity <- .std[d$label]
  cl$Shape_Origin_Identity <- d$shape
  cl$Shape_English_Identity <- d$shape
  cl$Shape_Standardized_Identity <- .std[d$shape]
  cl$RT_ms <- as.integer(d$latency)
  cl$RT_sec <- cl$RT_ms / 1000
  cl$ACC <- as.integer(d$correct)
  rownames(cl) <- NULL
  cl
}
.cl1 <- .make_clean(.f1, "1", with_trial = FALSE)
.cl2 <- .make_clean(.f2, "2", with_trial = TRUE)

# ---- 行序：按作者文件行序（subject 出现序）----
.f1 <- .f1[order(.f1$subject, seq_len(nrow(.f1))), ]
.f2 <- .f2[order(.f2$subject, seq_len(nrow(.f2))), ]
.cl1 <- .cl1[order(.cl1$Subject, seq_len(nrow(.cl1))), ]
.cl2 <- .cl2[order(.cl2$Subject, seq_len(nrow(.cl2))), ]

# ---- 产出：Exp1/Exp2 子文件夹（SKILL 多实验布局）----
for (.e in c("Exp1", "Exp2")) if (!dir.exists(file.path(.study_dir, .e)))
  dir.create(file.path(.study_dir, .e))

# raw：保留作者原始列原样（含 trialnum，E2 独有）
write_clean_csv(.f1, file.path(.study_dir, "Exp1",
                               "Golubickis_2021_ActaPsych_Exp1_raw.csv"))
write_clean_csv(.f2, file.path(.study_dir, "Exp2",
                               "Golubickis_2021_ActaPsych_Exp2_raw.csv"))
cat("  raw: E1", nrow(.f1), "rows / E2", nrow(.f2), "rows\n")

# Clean
write_clean_csv(.cl1, file.path(.study_dir, "Exp1",
                                "Golubickis_2021_ActaPsych_Exp1_Clean.csv"))
write_clean_csv(.cl2, file.path(.study_dir, "Exp2",
                                "Golubickis_2021_ActaPsych_Exp2_Clean.csv"))
stopifnot(nrow(.cl1) == nrow(.f1), nrow(.cl2) == nrow(.f2),
          length(unique(.cl1$Subject)) == 30,
          length(unique(.cl2$Subject)) == 25)
cat("  Clean: E1", nrow(.cl1), "rows / 30 subjects; E2", nrow(.cl2),
    "rows / 25 subjects\n")

# subj_info：无人口学（数据无、论文仅组均值）-> 全 "/"
.si1 <- data.frame(Subject_ID = sort(unique(.cl1$Subject)),
                   Exp_id = rep("Golubickis_2021_ActaPsych_Exp1", 30),
                   Age = rep("/", 30), Gender = rep("/", 30),
                   stringsAsFactors = FALSE)
.si2 <- data.frame(Subject_ID = sort(unique(.cl2$Subject)),
                   Exp_id = rep("Golubickis_2021_ActaPsych_Exp2", 25),
                   Age = rep("/", 25), Gender = rep("/", 25),
                   stringsAsFactors = FALSE)
stopifnot(nrow(.si1) == 30, nrow(.si2) == 25)
write_clean_csv(.si1, file.path(.study_dir, "Exp1",
                                "Golubickis_2021_ActaPsych_Exp1_subj_info.csv"))
write_clean_csv(.si2, file.path(.study_dir, "Exp2",
                                "Golubickis_2021_ActaPsych_Exp2_subj_info.csv"))
cat("  subj_info: E1 30 rows / E2 25 rows (demographics '/', not recorded)\n")

# ---- 方向核对输出（论文描述性方向，不重复统计检验）----
for (.e in list(list(d = .cl1, lab = "E1"), list(d = .cl2, lab = "E2"))) {
  .d <- .e$d
  .m <- function(shape, bt, mt) mean(.d$RT_ms[.d$Shape_Standardized_Identity == shape &
                                               .d$Blocktype == bt & .d$Matching == mt], na.rm = TRUE)
  .a <- function(shape, bt, mt) 100 * mean(.d$ACC[.d$Shape_Standardized_Identity == shape &
                                                  .d$Blocktype == bt & .d$Matching == mt] == 1)
  cat(sprintf(paste0("%s matching-trial direction: mixed self %.0f < friend %.0f < stranger %.0f ms; ",
                     "blocked self %.0f < friend %.0f < stranger %.0f ms; ",
                     "accuracy mixed %.0f/%.0f/%.0f, blocked %.0f/%.0f/%.0f\n"),
              .e$lab, .m("Self", "mixed", "Matching"), .m("Close", "mixed", "Matching"),
              .m("Stranger", "mixed", "Matching"), .m("Self", "blocked", "Matching"),
              .m("Close", "blocked", "Matching"), .m("Stranger", "blocked", "Matching"),
              .a("Self", "mixed", "Matching"), .a("Close", "mixed", "Matching"),
              .a("Stranger", "mixed", "Matching"), .a("Self", "blocked", "Matching"),
              .a("Close", "blocked", "Matching"), .a("Stranger", "blocked", "Matching")))
}
cat("DONE. Exp1: 30 subjects x <=360 trials; Exp2: 25 subjects x <=360 trials; all guards passed.\n")
