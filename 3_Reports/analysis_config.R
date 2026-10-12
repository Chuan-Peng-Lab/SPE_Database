# ============================================================================
# analysis_config.R — SPE Database 三段分析（例1/例2/例3）共用的数据装配层
#
# 目的：把「哪些文件构成一个逻辑数据集」「哪些行进入分析」从三段代码里
#       抽出来集中定义，避免三处各写一份、口径漂移。
#
# v4 相对 v3 的变化（2026-10-12，Hu_YQ_2026_ChinaSciData 结构重构之后）：
#   Hu_YQ 的两个实验文件已由数据层重排为：`..._Exp1_Clean`（北京 2015，36 人，
#   两个任务已合并为一个数据集）+ `..._Exp2_Clean`（开封 2023，26 人）。
#   因此 v3 的「Exp1 + Exp2 合并」规则必须删除（否则会把北京与开封合成一个
#   62 人数据集）；开封的基线阶段由 `Phase == "01_baseline"` 改为
#   `Session == "baseline"`（新 Clean 的阶段名在 Session 列，Phase 只有
#   practice/main）。本文件只改装配规则，分析模型不变。
#
# v3 相对 v2 的变化（均为数据侧规则变化，不是分析模型变化）：
#   (1) 大文件分片：v2 用 pattern="_Clean\\.csv$"，匹配不到 2026-09-27 起的
#       `_Clean_part<N>.csv`，会**静默丢掉整个数据集**（Sun_2026_DataExp_Exp1、
#       Hu_YQ_2026_ChinaSciData_Exp2 各丢一个）。v3 匹配两种命名并按逻辑数据集
#       rbind 还原（库规则：分片 = 一个数据集，不新增 Exp/不新增主索引行）。
#   (2) Hu_YQ_2026_ChinaSciData：见 v4 说明（v3 的合并规则已废止）。
#   (3) 保守法的「至少 3 个不同身份」判定：只数 6 类规范身份
#       （Self/NonPerson/Stranger/Celebrity/Acquaintance/Close），
#       奖赏（£1/£3/£9）、情绪（Happy/Neutral/...）、伪词（Filler）、
#       ingroup 等**非身份取值不计入**。
#   (4) practice 行策略可切换（见 PRACTICE_POLICY）。
#   (5) Sun_2026_DataExp（2026-10-01 数据重建后）：分析层剔除 Task1（shape-matching，
#       几何图形版、无身份维度），仅保留 Task2（self-matching）——Task1 的 Identity
#       列按 schema 记为 NonPerson 而非真实身份条件，两任务合并会生成跨任务伪 d。
# ============================================================================

suppressPackageStartupMessages(library(data.table))

# ---- 常量 -----------------------------------------------------------------
ALL_CANONICAL_IDENTITIES <- c("Self", "NonPerson", "Stranger",
                              "Celebrity", "Acquaintance", "Close")
BASELINE_IDENTITIES <- c("NonPerson", "Stranger", "Celebrity",
                         "Acquaintance", "Close")

# ---- 文件发现与逻辑数据集还原 ----------------------------------------------
# 匹配 `*_Clean.csv` 与 `*_Clean_part<N>.csv`；后者按逻辑数据集合并。
SPE_CLEAN_REGEX <- "_Clean(_part[0-9]+)?\\.csv$"

spe_clean_files <- function(root) {
  list.files(root, pattern = SPE_CLEAN_REGEX, recursive = TRUE, full.names = TRUE)
}

# `Aa_Bb_Exp1_Clean_part2.csv` -> `Aa_Bb_Exp1_Clean`（= 逻辑数据集 ID）
spe_logical_id <- function(path) {
  b <- basename(path)
  b <- sub("_Clean_part[0-9]+\\.csv$", "_Clean.csv", b)
  sub("\\.csv$", "", b)
}

# ---- Hu_YQ 结构性规则 ------------------------------------------------------
HU_YQ_EXP1 <- "Hu_YQ_2026_ChinaSciData_Exp1_Clean"      # 北京 2015，36 人（两任务已合并）
HU_YQ_EXP2 <- "Hu_YQ_2026_ChinaSciData_Exp2_Clean"      # 开封 2023 训练研究，26 人
HU_YQ_EXP2_BASELINE <- "baseline"                       # 仅训练前基线（Session 列取值）

# ---- Sun_2026_DataExp 结构性规则 -------------------------------------------
# 两任务 = 同批被试的两个 session：Task1（shape-matching，Session 2，2026-10-01 重建后）
# 无身份维度（Identity 按 schema 记 NonPerson，非身份条件）；Task2（self-matching，
# Session 3）才是自我参照任务。分析层剔除 Task1，防止生成跨任务伪 d。
SUN_EXP1 <- "Sun_2026_DataExp_Exp1_Clean"
SUN_TASK_DROP <- "shape-matching"

# ---- practice 行策略 -------------------------------------------------------
# "exclude"（默认）：Phase 值含 prac（practice/Practice/00_practice/prac_ALT2_*）的行剔除
# "keep"：与 v1/v2 行为一致（全部保留）
PRACTICE_POLICY <- Sys.getenv("SPE_PRACTICE_POLICY", unset = "exclude")
PRACTICE_REGEX  <- "prac"      # 大小写不敏感

# ---- 读取 ----------------------------------------------------------------
# 返回 data.table：每个逻辑数据集一个 Source；分片已合并。
# cols = 需要保留的列（各研究列集不同，缺失列自动 NA）。
spe_read_datasets <- function(root, cols, verbose = TRUE) {
  files <- spe_clean_files(root)
  ids   <- spe_logical_id(files)
  if (verbose) cat(sprintf("匹配到 %d 个 Clean 文件（含分片）-> %d 个逻辑数据集\n",
                           length(files), length(unique(ids))))
  multi <- names(which(table(ids) > 1))
  if (length(multi) && verbose) {
    cat("含分片的数据集：\n")
    for (m in multi) cat(sprintf("   %s (%d 片)\n", m, sum(ids == m)))
  }

  read_one <- function(f) {
    h <- names(data.table::fread(f, nrows = 0, showProgress = FALSE))
    keep <- intersect(cols, h)
    d <- data.table::fread(f, select = keep, showProgress = FALSE)
    for (cc in setdiff(keep, names(d))) d[, (cc) := NA_character_]
    d
  }

  out <- vector("list", length(unique(ids)))
  for (i in seq_along(unique(ids))) {
    id <- unique(ids)[i]
    parts <- sort(files[ids == id])          # part1, part2, ... 顺序拼接
    d <- data.table::rbindlist(lapply(parts, read_one), fill = TRUE)
    d[, Source := id]
    out[[i]] <- d
  }
  data.table::rbindlist(out, fill = TRUE)
}

# ---- 结构性规则的应用 ------------------------------------------------------
# 输入：spe_read_datasets() 的产物（至少含 Source / Subject 列）
spe_apply_structure <- function(dt, practice_policy = PRACTICE_POLICY, verbose = TRUE) {
  dt <- data.table::copy(dt)

  # (2a) Hu_YQ 结构性规则（v4，2026-10-12）
  # 数据层已把北京两个任务合并为 `..._Exp1_Clean`（36 人）、开封训练研究编为
  # `..._Exp2_Clean`（26 人）——两个数据集各自独立，此处不再做任何合并。
  # 开封训练研究只保留训练前基线阶段（Session 列；Phase 仅 practice/main）。
  if ("Session" %in% names(dt)) {
    drop <- dt$Source == HU_YQ_EXP2 &
      (is.na(dt$Session) | dt$Session != HU_YQ_EXP2_BASELINE)
    if (verbose) {
      cat(sprintf("Hu_YQ Exp2（开封）：仅保留 Session == '%s'（剔除 %d 行 / %.0f%%）\n",
                  HU_YQ_EXP2_BASELINE, sum(drop),
                  100 * mean(drop[dt$Source == HU_YQ_EXP2])))
    }
    dt <- dt[!drop]
  } else if (HU_YQ_EXP2 %in% unique(dt$Source)) {
    warning("Hu_YQ 开封数据集需要 Session 列以取训练前基线；请在调用脚本的 NEEDED 中加入 Session")
  }

  # (3) Sun_2026_DataExp：剔除 Task1（shape-matching，无身份维度），保留 Task2（self-matching）
  if ("Task" %in% names(dt)) {
    drop_sun <- dt$Source == SUN_EXP1 & !is.na(dt$Task) & dt$Task == SUN_TASK_DROP
    if (verbose && any(drop_sun)) {
      cat(sprintf("Sun_2026_DataExp：剔除 Task1（%s，无身份维度）%d 行，保留 Task2（self-matching）\n",
                  SUN_TASK_DROP, sum(drop_sun)))
    }
    dt <- dt[!drop_sun]
  } else if (SUN_EXP1 %in% unique(dt$Source)) {
    warning("Sun_2026_DataExp 需要 Task 列以剔除无身份的 Task1；请在调用脚本的 NEEDED 中加入 Task")
  }

  # (4) practice 行
  if (practice_policy == "exclude" && "Phase" %in% names(dt)) {
    is_prac <- !is.na(dt$Phase) & grepl(PRACTICE_REGEX, dt$Phase, ignore.case = TRUE)
    if (verbose) {
      cat(sprintf("practice 策略 = exclude：剔除 %d 行（%.2f%%），涉及 %d 个数据集\n",
                  sum(is_prac), 100 * mean(is_prac), uniqueN(dt$Source[is_prac])))
    }
    dt <- dt[!is_prac]
  } else if (verbose) {
    cat("practice 策略 = keep（不剔除练习试次）\n")
  }

  dt[]
}

# ---- 保守法身份判定（只数规范身份） ----------------------------------------
# 返回 TRUE/FALSE：该被试的 primary 列是否含 Self、Stranger，且规范身份 >= 3 类。
spe_has_three_identities <- function(ids) {
  ids <- ids[!is.na(ids)]
  canon <- intersect(unique(ids), ALL_CANONICAL_IDENTITIES)
  ("Self" %in% canon) && ("Stranger" %in% canon) && length(canon) >= 3
}

# ---- 被试唯一键 ------------------------------------------------------------
spe_add_subject_key <- function(dt) {
  dt[, Subject := as.character(Subject)]
  dt[, SubjKey := paste(Source, Subject, sep = "_")]
  dt[]
}
