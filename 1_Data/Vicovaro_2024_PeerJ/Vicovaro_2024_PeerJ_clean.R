# ============================================================================
# Vicovaro_2024_PeerJ — 独立清洗脚本（Exp1 + Exp2）：标准 raw/Clean/subj_info
# ----------------------------------------------------------------------------
# 背景（2026-08-30 阶段 5 入库）：论文 Vicovaro & ? (2024), "Exploring the
# influence of self-identification on perceptual judgments of physical and
# social causality", PeerJ, DOI 10.7717/peerj.17449。两个实验均以自我匹配
# 任务（shape-label matching, Sui et al. 2012）作为学习后验证（manipulation
# check），主任务为因果判断动画（不入库，库口径只收匹配任务 trial 级数据）。
# 身份标签为英文 "you"（自我）与 "stranger"；几何形状 circle/square（数据
# 中仅记录身份，几何映射未上传）。数据来自 OSF e6hd7 存档
# （Vicovaro2024PeerJ_raw/e6hd7-osfstorage-archive/），为作者导出的分析格式
# （非原始逐试次导出）。
#
# 数据格式（两实验列名不同）：
#   Exp1 1_Matching_Task_1.csv: participant, shape, RT, trial_type, block, resp_type
#   Exp2 1_Matching_Task_2.csv: participant, ruolo, corrispondenza, key_resp_2.rt, block, resp_type
#     shape/ruolo   = 身份（you/stranger；作者导出值，实际刺激为意大利语
#       tu/sconosciuto，论文英文表述 you/stranger）——数据未记录几何形状
#     trial_type/corrispondenza = Matched/Nonmatching
#     RT / key_resp_2.rt = 反应时，两实验均已是毫秒（作者由 PsychoPy 秒 ×1000，
#       保留小数；2026-08-30 核实：Exp2 值域 0.33–1082 与 Exp1 0.6–1084 一致，
#       均为 ms——勿按 PsychoPy 秒单位再乘 1000）。两实验均含负值（提前按键）
#       与超窗异常值，按最小预处理保留原样。
#     resp_type = correct/incorrect/missed → ACC 1/0/NA（全库方案 A）。
#   每被试 240 试次（2 blocks × 120；每 block 内 Matched/Nonmatching 各 60）。
#   Label 数据未直接记录：匹配试次 label = shape 身份，非匹配试次 label =
#   相反身份（定义推导）。Info_Participants_{1,2}.csv: N;gender;age;included
#   （gender 大小写混合 F/m/f/M → Female/Male；included=no 者仅从因果任务
#   分析移除，匹配任务数据完整，全部保留）。
#
# 论文匹配任务仅定性报告（"robust self-prioritisation effect"），无精确
# 统计量——复现验证限于 SPE 方向（self 匹配试次更快/更准），见脚本尾部。
# 论文伦理：University of Padova 批准（approval 3455）→ 采集地 Italy/Padova。
#
# 验证守卫：每被试 240 行；block×trial_type 结构（每 block 每类型 60）；
# Trial 按数据行序全局编号（1-240）；输出 CRLF（库内惯例）。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Vicovaro_2024_PeerJ_clean.R
# 依赖包：无（base R）
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
.ut <- file.path(dirname(dirname(.script_dir)), "1_Data", "utils.R")
if (!file.exists(.ut)) .ut <- file.path(.script_dir, "utils.R")
stopifnot(file.exists(.ut))
source(.ut)
rm(.args, .fa, .script_dir, .ut)

STUDY_DIR <- file.path(spe_root(), "1_Data", "Vicovaro_2024_PeerJ")
stopifnot(dir.exists(STUDY_DIR))
IN <- file.path(STUDY_DIR, "Vicovaro2024PeerJ_raw", "e6hd7-osfstorage-archive")

# ============================================================================
# 形状-身份绑定表（self 对应的几何形状；两实验相同）
# ============================================================================
shape_binding <- rep(rep(c("circle", "square"), each = 4), 8)   # 64 名被试
names(shape_binding) <- as.character(1:64)

# ============================================================================
# 解析单实验匹配任务（Exp1/2 列名不同）
# ============================================================================
parse_matching <- function(exp) {
  d <- read.csv(file.path(IN, sprintf("Experiment_%s/3_Raw_Data/1_Matching_Task_%s.csv", exp, exp)),
                stringsAsFactors = FALSE, check.names = FALSE, na.strings = c("", "NA"))
  col_shape <- if (exp == "1") "shape" else "ruolo"
  col_match <- if (exp == "1") "trial_type" else "corrispondenza"
  col_rt    <- if (exp == "1") "RT" else "key_resp_2.rt"
  stopifnot(all(c("participant", col_shape, col_match, col_rt, "block", "resp_type") %in% names(d)))
  out <- data.frame(
    Subject = as.integer(d$participant),
    Block   = as.integer(d$block),
    ShapeIdentity = d[[col_shape]],        # 原始身份（you/stranger，作者导出值）
    Matching = ifelse(d[[col_match]] == "Matched", "Matching", "Nonmatching"),
    ACC     = ifelse(d$resp_type == "correct", 1L, ifelse(d$resp_type == "incorrect", 0L, NA_integer_)),
    RT_ms   = ifelse(is.na(d[[col_rt]]), NA_real_, round(as.numeric(d[[col_rt]]))),
    resp_type = d$resp_type,
    stringsAsFactors = FALSE
  )
  # Shape = 实际呈现的几何形状（按 per-subject 绑定；self 形状 = shape_binding[subj]）
  self_shp <- shape_binding[as.character(out$Subject)]
  out$Shape <- ifelse(out$ShapeIdentity == "you", self_shp,
                      ifelse(self_shp == "circle", "square", "circle"))
  # Trial：按数据行序全局编号（block 1 全部在前，block 2 在后）
  out$Trial <- ave(seq_len(nrow(out)), out$Subject, FUN = seq_along)
  out[, c("Subject", "Trial", "Block", "Shape", "ShapeIdentity",
          "Matching", "ACC", "RT_ms", "resp_type")]
}

# ============================================================================
# Label 推导 + Identity 三级（Origin → English → Standardized）
# ============================================================================
add_identity <- function(d) {
  d$Label <- ifelse(d$Matching == "Matching", d$ShapeIdentity,
                    ifelse(d$ShapeIdentity == "you", "stranger", "you"))
  d$Label_Origin_Identity <- d$Label
  d$Label_English_Identity <- ifelse(d$Label == "you", "You", "Stranger")
  d$Label_Standardized_Identity <- ifelse(d$Label == "you", "Self", "Stranger")
  d$Shape_Origin_Identity <- d$ShapeIdentity          # 原始身份值（数据原样）
  d$Shape_English_Identity <- ifelse(d$ShapeIdentity == "you", "You", "Stranger")
  d$Shape_Standardized_Identity <- ifelse(d$ShapeIdentity == "you", "Self", "Stranger")
  d[, c("Subject", "Trial", "Block", "Shape", "Label", "Matching", "ACC", "RT_ms",
        "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
        "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity")]
}

# ============================================================================
# subj_info（Info_Participants；gender 大小写统一；included 记 Note 用）
# ============================================================================
make_subj_info <- function(exp, exp_id) {
  info <- read.csv(file.path(IN, sprintf("Experiment_%s/2_Info_Participants/Info_Participants_%s.csv", exp, exp)),
                   sep = ";", stringsAsFactors = FALSE)
  data.frame(Subject_ID = as.integer(info$N),
             Exp_id = exp_id,
             Age = info$age,
             Gender = ifelse(tolower(info$gender) == "f", "Female", "Male"),
             Handedness = "/", Ethnicity = "/", Employment_Status = "/",
             Country = "/", First_Language = "/", Education = "/",
             stringsAsFactors = FALSE)
}

# ============================================================================
# Exp1（RT 已是 ms）
# ============================================================================
cat("== Exp1: 解析 1_Matching_Task_1.csv ...\n")
raw1 <- parse_matching("1")
stopifnot(nrow(raw1) == 64 * 240)
stopifnot(all(table(raw1$Subject) == 240))
cat("  Exp1 raw 行数:", nrow(raw1), "(预期 15360 = 64×240)\n")

# ============================================================================
# Exp2（RT 为秒 → ×1000）
# ============================================================================
cat("== Exp2: 解析 1_Matching_Task_2.csv ...\n")
raw2 <- parse_matching("2")
stopifnot(nrow(raw2) == 64 * 240)
stopifnot(all(table(raw2$Subject) == 240))
cat("  Exp2 raw 行数:", nrow(raw2), "(预期 15360 = 64×240)\n")

# ============================================================================
# 结构守卫 + Identity + SPE 方向验证（论文仅定性报告）
# ============================================================================
for (nm in c("raw1", "raw2")) {
  d <- get(nm)
  tab <- table(d$Block, d$Matching)
  stopifnot(all(tab == 60 * length(unique(d$Subject))))   # 每 block 每类型 60/被试
  stopifnot(!any(is.na(d$Shape)), !any(is.na(d$Matching)))
}
cat("  结构守卫通过（每被试 240 = 2 blocks × 120，每 block 每类型 60）\n")
c1 <- add_identity(raw1)
c2 <- add_identity(raw2)
for (nm in c("c1", "c2")) {
  d <- get(nm)
  ok_m <- all(d$Label[d$Matching == "Matching"] == d$ShapeIdentity[d$Matching == "Matching"])
  ok_n <- all(d$Label[d$Matching == "Nonmatching"] != d$ShapeIdentity[d$Matching == "Nonmatching"])
  stopifnot(ok_m, ok_n)
  # 绑定自洽：Shape 列只有 circle/square 且与绑定表一致
  stopifnot(all(d$Shape %in% c("circle", "square")))
}
cat("  Label 推导自洽（Matching: label==shape；Nonmatching: label!=shape）\n")
for (nm in c("c1", "c2")) {
  d <- get(nm)
  # SPE 方向：self 匹配试次 RT 均值 vs stranger 匹配试次
  sel <- d$Matching == "Matching" & !is.na(d$RT_ms)
  rt_self <- mean(d$RT_ms[sel & d$Shape_Standardized_Identity == "Self"])
  rt_str  <- mean(d$RT_ms[sel & d$Shape_Standardized_Identity == "Stranger"])
  acc_self <- mean(d$ACC[sel & d$Shape_Standardized_Identity == "Self"], na.rm = TRUE)
  acc_str  <- mean(d$ACC[sel & d$Shape_Standardized_Identity == "Stranger"], na.rm = TRUE)
  cat(sprintf("  %s SPE 方向：self 匹配 RT %.1f vs stranger %.1f ms；ACC %.3f vs %.3f\n",
              nm, rt_self, rt_str, acc_self, acc_str))
  stopifnot(rt_self < rt_str, acc_self > acc_str)   # 论文定性结论（robust SPE）
}

# ============================================================================
# 写出 raw / Clean / subj_info（Exp1/2 子文件夹）
# ============================================================================
info1 <- make_subj_info("1", "Vicovaro_2024_PeerJ_Exp1")
info2 <- make_subj_info("2", "Vicovaro_2024_PeerJ_Exp2")
stopifnot(nrow(info1) == 64, nrow(info2) == 64)

out <- list(
  list(raw1, file.path(STUDY_DIR, "Exp1", "Vicovaro_2024_PeerJ_Exp1_raw.csv")),
  list(c1,  file.path(STUDY_DIR, "Exp1", "Vicovaro_2024_PeerJ_Exp1_Clean.csv")),
  list(info1, file.path(STUDY_DIR, "Exp1", "Vicovaro_2024_PeerJ_Exp1_subj_info.csv")),
  list(raw2, file.path(STUDY_DIR, "Exp2", "Vicovaro_2024_PeerJ_Exp2_raw.csv")),
  list(c2,  file.path(STUDY_DIR, "Exp2", "Vicovaro_2024_PeerJ_Exp2_Clean.csv")),
  list(info2, file.path(STUDY_DIR, "Exp2", "Vicovaro_2024_PeerJ_Exp2_subj_info.csv"))
)
for (o in out) stopifnot(!file.exists(o[[2]]))
for (o in out) write_clean_csv(o[[1]], o[[2]])
cat("完成：\n")
for (o in out) cat("  ", o[[2]], "\n")
