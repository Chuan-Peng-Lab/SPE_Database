# ============================================================================
# Zhang_2024_PsychJ — 独立清洗脚本（Exp1 + Exp2）：标准 raw/Clean/subj_info
# ----------------------------------------------------------------------------
# 背景（2026-08-30 阶段 5 入库）：论文 Zhang, Zhou, Tang & Xi (2024), "Can
# irrelevant self-related information in working memory be actively suppressed?",
# PsyCh Journal 13(6), DOI 10.1002/pchj.790。两实验均为两阶段：训练阶段 =
# 形状-标签联想学习任务（associative-learning task，即本库收录的匹配任务，
# 2 键判断）+ 测试阶段 = 无关干扰工作记忆任务（颜色记忆、忽略形状，不入库）。
# 输入区：Zhang2024_PsychJ_Raw/data and procedure.zip（exp1/exp2 各含
# association data 与 distracting data 的每被试 .mat；exp2 另有 error_data
# 为测试/错误文件，不入库）。
#
# 数据格式（每被试一个 .mat，结构 rec (n,6) uint16 + 头部 p）：
#   rec 列（p.recLabel）：trialNo, shape, label, RespKey, RT, CorrectResp
#     shape/label = 身份编号（exp1: 1=you, 2=friend, 3=stranger——程序
#       Associate_shape.m 的 you_EN/friend_EN/stranger_EN.bmp 定义；
#       exp2: 1=you, 2=stranger，另有两个中性形状 3/4——论文 "two neutral
#       shapes, not associated with any labels"）。几何形状（用户 2026-08-30
#       解压 stimuli.zip 确认，两实验为两套不同图）：exp1 Associate1=三角形
#       （=you）、2=正方形（=friend）、3=圆形（=stranger）；exp2 Associate1=
#       正方形（=you）、2=三角形（=stranger）、3=圆形（=中性）、4=五边形
#       （=中性）。exp2 中性形状出现在匹配任务属设计使然：论文明示 "two
#       neutral shapes... were introduced"（Figure 3 + Appendix A），程序
#       factors 写死包含 (3,1)(3,2)(4,1)(4,2) 四组合（各 10 试次），数据
#       40 试次/被试与程序完全吻合——非数据错误。
#     RespKey = 实际按键（1 = 'm' 不匹配键 / 2 = 'n' 匹配键，keyMode 决定
#       匹配键；0 = 无反应）。
#     RT = 反应时 ms（0 = 无反应）。
#     CorrectResp = 程序判定正确性（1/0）。
#   exp1: 216 试次 = 2 blocks × 108（程序 trialsPerBlock=108, blockNum=2，
#     trials=[conditions;conditions]；匹配组合 (1,1)(2,2)(3,3) 各 36 +
#     不匹配 6 组合各 18）。exp2: 120 试次 = 2 blocks × 60（trialsPerBlock=
#     60；匹配 (1,1)(2,2) 各 30 + 不匹配 6 组合各 10）。
#   练习：论文 "Before the formal experiment, participants completed 20
#   practice trials. Only those with an accuracy rate of 80% or higher
#   proceeded"——练习 20 试次（数据无练习行）。
#
# 论文 N 口径（Note 用，raw 不过滤）：
#   exp1: 46 参加、4 因 catch 表现差排除 → 42 分析；数据 43 个 .mat（
#     46-3 缺文件或含被排除者，以数据为准 Sample_Size=43）。
#   exp2: 38 参加、2 排除 → 36 分析；数据 36 个 .mat（含 error_data 5 个
#     测试/错误文件不入库）。exp2 匹配任务论文报告 "Accuracy: self-stranger
#     p < .001; RTs: self-stranger p < .001"（方向验证，见脚本尾部）。
# 论文伦理：Anhui Medical University（中国合肥）批准 → Country=China。
# 被试人口学：.mat 无 Age/Gender 字段 → subj_info 填 /（论文仅报告组均值）。
#
# ACC 编码（全库方案 A）：CorrectResp 1=正确 / 0=错误；RespKey==0（无反应）
# → NA。RT==0 → NA。RT 过滤（论文 "less than 200 ms and more than three
# SDs from the condition mean"）属分析口径，raw/Clean 不过滤（最小预处理）。
#
# 验证守卫：每被试行数（216/120）；Matching 结构（匹配:不匹配 = 108:108 /
# 60:60）；SPE 方向（self 匹配 RT 更快、ACC 更高）。
# ----------------------------------------------------------------------------
# 运行方式：Rscript Zhang_2024_PsychJ_clean.R
# 依赖包：R.matlab
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

library(R.matlab)

STUDY_DIR <- file.path(spe_root(), "1_Data", "Zhang_2024_PsychJ")
stopifnot(dir.exists(STUDY_DIR))
ZIP <- file.path(STUDY_DIR, "Zhang2024_PsychJ_Raw", "data and procedure.zip")
stopifnot(file.exists(ZIP))

# 解压到临时目录（输入区 zip 保持原样）
TD <- tempfile("zhang24_")
dir.create(TD)
unzip(ZIP, exdir = TD)
ASSO1 <- file.path(TD, "data and procedure", "exp1", "association data")
ASSO2 <- file.path(TD, "data and procedure", "exp2", "association data")

# ============================================================================
# 解析单个 .mat（exp1/exp2 共用；身份映射与中性形状处理按实验参数）
# ============================================================================
parse_mat <- function(path, subject_id, label_names, neutral_shapes = integer(0),
                       shape_map = NULL) {
  m <- R.matlab::readMat(path)
  rec <- m$rec
  p <- m$p
  stopifnot(is.matrix(rec), ncol(rec) == 6)
  shape_code <- as.integer(rec[, 2])
  label_code <- as.integer(rec[, 3])
  out <- data.frame(
    Subject = subject_id,
    Trial = as.integer(rec[, 1]),
    Shape = if (!is.null(shape_map)) unname(shape_map[as.character(shape_code)]) else shape_code,
    ShapeCode = shape_code,               # 原始编号（Matching/Identity 计算与追溯用）
    Label = if (!is.null(label_names)) unname(label_names[as.character(label_code)]) else label_code,
    LabelCode = label_code,               # 原始编号（Matching/Identity 计算与追溯用）
    RespKey = as.integer(rec[, 4]),
    RT = as.integer(rec[, 5]),
    CorrectResp = as.integer(rec[, 6]),
    stringsAsFactors = FALSE
  )
  out$SubjectName <- if (is.list(p[1, 1, 1])) as.character(p[1, 1, 1][[1]]) else NA_character_
  out
}

# ============================================================================
# 标准列生成（Block 按程序块切分；Matching/ACC/RT/Identity 三级）
# ============================================================================
finalize <- function(d, block_size, label_map, neutral_shapes = integer(0)) {
  code <- d$ShapeCode                   # 原始编号（Shape 列已映射为形状名）
  lcode <- d$LabelCode                  # 原始编号（Label 列已映射为标签文字）
  d$Block <- ceiling(d$Trial / block_size)
  d$Matching <- ifelse(code == lcode, "Matching", "Nonmatching")
  d$ACC <- d$CorrectResp
  d$ACC[d$RespKey == 0] <- NA_integer_          # 无反应 → NA（方案 A）
  d$RT_ms <- d$RT
  d$RT_ms[d$RT == 0] <- NA_integer_             # 无反应 RT=0 → NA
  d$Response <- d$RespKey
  # Identity 三级（编号 → 身份名 → Std；Shape_Origin_Identity 保留原始编号）
  lab_eng <- label_map[as.character(lcode)]
  shp_eng <- label_map[as.character(code)]
  shp_eng[code %in% neutral_shapes] <- "Neutral shape"      # 中性形状（exp2 的 3/4）
  d$Label_Origin_Identity <- as.character(lcode)
  d$Label_English_Identity <- lab_eng
  d$Label_Standardized_Identity <- ifelse(lab_eng == "You", "Self",
                                    ifelse(lab_eng == "Friend", "Close",
                                    ifelse(lab_eng == "Stranger", "Stranger", "NonPerson")))
  d$Shape_Origin_Identity <- as.character(code)
  d$Shape_English_Identity <- shp_eng
  d$Shape_Standardized_Identity <- ifelse(shp_eng == "You", "Self",
                                    ifelse(shp_eng == "Friend", "Close",
                                    ifelse(shp_eng == "Stranger", "Stranger", "NonPerson")))
  d[, c("Subject", "Trial", "Block", "Shape", "Label", "Matching", "ACC", "RT_ms",
        "Response", "Label_Origin_Identity", "Label_English_Identity",
        "Label_Standardized_Identity", "Shape_Origin_Identity",
        "Shape_English_Identity", "Shape_Standardized_Identity")]
}

# ============================================================================
# Exp1（43 名 × 216 试次；身份 you/friend/stranger；2 blocks × 108）
# ============================================================================
cat("== Exp1: 解析 association data .mat ...\n")
mat1 <- list.files(ASSO1, pattern = "\\.mat$", recursive = TRUE, full.names = TRUE)
mat1 <- mat1[!grepl("error_data", mat1)]
stopifnot(length(mat1) == 43)
map_shapes1 <- c(`1` = "triangle", `2` = "square", `3` = "circle")
map_labels1 <- c(`1` = "you", `2` = "friend", `3` = "stranger")
raw1 <- do.call(rbind, lapply(seq_along(mat1), function(i)
  parse_mat(mat1[i], i, label_names = map_labels1, shape_map = map_shapes1)))
rownames(raw1) <- NULL
stopifnot(nrow(raw1) == 43 * 216)
stopifnot(all(table(raw1$Subject) == 216))
cat("  Exp1 raw 行数:", nrow(raw1), "(预期 9288 = 43×216)\n")

# ============================================================================
# Exp2（36 名 × 120 试次；身份 you/stranger + 中性形状 3/4；2 blocks × 60）
# ============================================================================
cat("== Exp2: 解析 association data .mat ...\n")
mat2 <- list.files(ASSO2, pattern = "\\.mat$", recursive = TRUE, full.names = TRUE)
mat2 <- mat2[!grepl("error_data", mat2)]
stopifnot(length(mat2) == 36)
map_shapes2 <- c(`1` = "square", `2` = "triangle", `3` = "circle", `4` = "pentagon")
map_labels2 <- c(`1` = "you", `2` = "stranger")
raw2 <- do.call(rbind, lapply(seq_along(mat2), function(i)
  parse_mat(mat2[i], i, label_names = map_labels2, shape_map = map_shapes2)))
rownames(raw2) <- NULL
stopifnot(nrow(raw2) == 36 * 120)
stopifnot(all(table(raw2$Subject) == 120))
cat("  Exp2 raw 行数:", nrow(raw2), "(预期 4320 = 36×120)\n")

# ============================================================================
# 标准列 + 结构守卫 + SPE 方向（论文：exp1 自我优势复现；exp2 p<.001 方向）
# ============================================================================
map1 <- c(`1` = "You", `2` = "Friend", `3` = "Stranger")
map2 <- c(`1` = "You", `2` = "Stranger")
c1 <- finalize(raw1, block_size = 108, label_map = map1)
c2 <- finalize(raw2, block_size = 60, label_map = map2, neutral_shapes = c(3, 4))
cat("  结构守卫：")
stopifnot(all(table(c1$Block, c1$Matching) == c(43 * 54, 43 * 54)))
stopifnot(all(table(c2$Block, c2$Matching) == c(36 * 30, 36 * 30)))
cat("exp1 匹配:不匹配 = 108:108/被试、exp2 = 60:60/被试 ✓\n")
cat("  exp1 Identity 分布:", paste(names(table(c1$Label_Standardized_Identity)),
    table(c1$Label_Standardized_Identity), collapse = " "), "\n")
cat("  exp2 Identity 分布:", paste(names(table(c2$Shape_Standardized_Identity)),
    table(c2$Shape_Standardized_Identity), collapse = " "), "\n")
stopifnot(!any(is.na(c1$Label_English_Identity)), !any(is.na(c2$Label_English_Identity)))
# 中性形状只出现在非匹配试次（用 ShapeCode 判断）
stopifnot(all(c2$Matching[c2$ShapeCode %in% c(3, 4)] == "Nonmatching"))
cat("  中性形状（3/4）仅出现在非匹配试次 ✓\n")
for (nm in c("c1", "c2")) {
  d <- get(nm)
  sel <- d$Matching == "Matching" & !is.na(d$RT_ms)
  rt_self <- mean(d$RT_ms[sel & d$Shape_Standardized_Identity == "Self"])
  rt_oth  <- mean(d$RT_ms[sel & d$Shape_Standardized_Identity != "Self"])
  acc_self <- mean(d$ACC[sel & d$Shape_Standardized_Identity == "Self"], na.rm = TRUE)
  acc_oth  <- mean(d$ACC[sel & d$Shape_Standardized_Identity != "Self"], na.rm = TRUE)
  cat(sprintf("  %s SPE 方向：self 匹配 RT %.1f vs 其他 %.1f ms；ACC %.3f vs %.3f\n",
              nm, rt_self, rt_oth, acc_self, acc_oth))
  stopifnot(rt_self < rt_oth, acc_self > acc_oth)
}

# ============================================================================
# subj_info（.mat 无人口学 → 全 /；Subject_ID 按文件名序 1..n）
# ============================================================================
mk_info <- function(n, exp_id) {
  data.frame(Subject_ID = seq_len(n), Exp_id = exp_id,
             Age = "/", Gender = "/", Handedness = "/", Ethnicity = "/",
             Employment_Status = "/", Country = "/", First_Language = "/",
             Education = "/", stringsAsFactors = FALSE)
}
info1 <- mk_info(43, "Zhang_2024_PsychJ_Exp1")
info2 <- mk_info(36, "Zhang_2024_PsychJ_Exp2")

# ============================================================================
# 写出（Exp1/Exp2 子文件夹）
# ============================================================================
out <- list(
  list(raw1, file.path(STUDY_DIR, "Exp1", "Zhang_2024_PsychJ_Exp1_raw.csv")),
  list(c1,  file.path(STUDY_DIR, "Exp1", "Zhang_2024_PsychJ_Exp1_Clean.csv")),
  list(info1, file.path(STUDY_DIR, "Exp1", "Zhang_2024_PsychJ_Exp1_subj_info.csv")),
  list(raw2, file.path(STUDY_DIR, "Exp2", "Zhang_2024_PsychJ_Exp2_raw.csv")),
  list(c2,  file.path(STUDY_DIR, "Exp2", "Zhang_2024_PsychJ_Exp2_Clean.csv")),
  list(info2, file.path(STUDY_DIR, "Exp2", "Zhang_2024_PsychJ_Exp2_subj_info.csv"))
)
for (o in out) stopifnot(!file.exists(o[[2]]))
for (o in out) write_clean_csv(o[[1]], o[[2]])
cat("完成：\n")
for (o in out) cat("  ", o[[2]], "\n")
