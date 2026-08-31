# ============================================================================
# Qi_2025_SciData — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1）
# ----------------------------------------------------------------------------
# 背景（2026-08-31 阶段 5 入库）：Qi, Zou, Chau, Zhou, Wang & Sui (2025), "A
# Comprehensive Dataset for Investigating the Structure of Self-Bias",
# Scientific Data 12(1), DOI 10.1038/s41597-025-06035-z（数据论文；134 名被试
# 10 范式，库内只收 SLM = shape-label matching 任务）。
#
# 任务（SLM，PsychoPy 2022.2.4，25 英寸 1920x1080 @60Hz 显示器）：
#   学习阶段：三个几何形状 ↔ 三个全名身份（自己/好友/鲁迅 = familiar other）；
#   测试阶段：500 ms fixation → 100 ms 形状-名字配对（形状在上、名字在下）→
#   1100 ms 空白响应窗（z/m 键判断匹配与否；键映射 counterbalanced）→
#   500 ms 反馈。练习块直到连续 6 次正确 → 正式 360 试次（6 条件 × 60，
#   每 60 试次休息）。形状-身份绑定（circle/square/triangle 论文文字；
#   数据文件名实际为 circle.png/triangle.png/rectangle.png——以数据为准，
#   差异记 exp JSON detail）+ 键映射 = 12 组 counterbalance
#   （condition 1A..6B ↔ group 1..12，作者 SLM_rawdata_code.txt）。
#
# 数据格式（输入区 Data_of_each_participant/<ID>_SLM_*.csv，134 个逐被试
#   PsychoPy 导出，UTF-8 BOM）：
#   phase(practice/formal) condition(1A..6B) label(self/friend/other)
#   shape(circle.png/triangle.png/rectangle.png) correct(应按键 m/z)
#   match(1/0) label_identity(1/2/3) shape_identity(1/2/3) group(1-12)
#   key_resp.keys/corr/rt（练习）key_resp_formal.keys/corr/rt（正式）
#   ID age sex(1=男,2=女；1 个文件为中文"男") date expName psychopyVersion frameRate
#   每个文件前 2 行为 PsychoPy 元数据/空行（phase 为空，第 1 行含 ID/age/sex）。
#   无反应：keys 为空串 → 库内 ACC=NA、RT_ms=NA（PsychoPy 对错过试次
#   corr 默认记 0，非真实按键，按项目约定无反应一律 NA）。
#
# 身份映射（用户确认 2026-08-31）：label_identity/shape_identity
#   1=self→Self、2=friend→Close、3=familiar other（鲁迅）→Celebrity
#   （Qian_2020_QJEP "Familiar"→"Celebrity" 先例；鲁迅为著名公众人物）。
#
# 清洗 = 最小预处理：不过滤（论文分析口径 RT<100 ms 或 >3SD 排除、2 名
#   被试 ACC<均值-3SD 排除仅用于其 Technical Validation，库内全部保留）；
#   练习试次保留并以 Phase 列标注（SKILL 惯例）；正式试次数 = 360/被试。
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
.study_dir <- file.path(.root, "1_Data", "Qi_2025_SciData")
.inp_dir <- file.path(.study_dir, "Qi_2025_SciData_Raw", "Data_of_each_participant")
stopifnot(dir.exists(.inp_dir))

# ---- 读入全部 134 个逐被试导出 ----
.files <- sort(list.files(.inp_dir, pattern = "^[0-9]+_SLM_.*\\.csv$"))
stopifnot(length(.files) == 134)                     # 134 名被试
cat("reading", length(.files), "participant csv files\n")

.dl <- lapply(.files, function(f) {
  d <- read.csv(file.path(.inp_dir, f), fileEncoding = "UTF-8-BOM",
                stringsAsFactors = FALSE, na.strings = c("", "NA"))
  stopifnot(nrow(d) >= 362)                          # 2 元数据行 + ≥6 练习 + 360 正式
  d <- d[!is.na(d$phase) & d$phase != "", ]          # 去掉元数据/空行
  d$Subject <- sub("_SLM_.*$", "", f)                # 文件名前缀 = 被试 ID
  d
})
dat <- do.call(rbind, .dl)
dat$Subject <- as.character(dat$Subject)
rm(.dl); gc()

cat("rows:", nrow(dat), "| practice:", sum(dat$phase == "practice"),
    "| formal:", sum(dat$phase == "formal"), "\n")

# ---- 守卫 1：结构（134 被试、正式 360/人、练习 ≥6/人、练习先于正式） ----
stopifnot(length(unique(dat$Subject)) == 134)
.fcnt <- tapply(dat$phase == "formal", dat$Subject, sum)
.pcnt <- tapply(dat$phase == "practice", dat$Subject, sum)
stopifnot(all(.fcnt == 360), all(.pcnt >= 6))
.ord_ok <- all(tapply(dat$phase == "formal", dat$Subject, function(x)
  all(x == cummax(x))))                              # 练习行全部先于正式行
stopifnot(.ord_ok)
cat("guard 1 OK: 134 subjects x 360 formal (+", sum(.pcnt),
    "practice) trials\n")

# ---- 守卫 2：match == (shape_identity == label_identity) ----
stopifnot(all((dat$match == 1) == (dat$shape_identity == dat$label_identity)))
cat("guard 2 OK: match == (shape_identity == label_identity) for all",
    nrow(dat), "trials\n")

# ---- 守卫 3：ACC 复现（实际按键 == 应按键 corr 列） ----
.keys <- ifelse(dat$phase == "formal", dat$key_resp_formal.keys, dat$key_resp.keys)
.corr <- ifelse(dat$phase == "formal", dat$key_resp_formal.corr, dat$key_resp.corr)
.rt   <- ifelse(dat$phase == "formal", dat$key_resp_formal.rt, dat$key_resp.rt)
stopifnot(all(dat$correct %in% c("m", "z")))
stopifnot(all(is.na(.keys) | .keys %in% c("m", "z")))
.resp <- !is.na(.keys)
stopifnot(all(.corr[.resp] == as.integer(.keys[.resp] == dat$correct[.resp])))
cat("guard 3 OK: ACC reproduces (keys == correct) rule for all",
    sum(.resp), "responded trials\n")

# ---- 身份三级列 ----
.id_map <- c("1" = "self", "2" = "friend", "3" = "other")
.std_map <- c("1" = "Self", "2" = "Close", "3" = "Celebrity")
dat$Shape_Origin_Identity <- dat$shape_identity      # 原始数字码（原样）
dat$Shape_English_Identity <- .id_map[dat$shape_identity]
dat$Shape_Standardized_Identity <- .std_map[dat$shape_identity]
dat$Label_Origin_Identity <- dat$label               # 原文字 self/friend/other
dat$Label_English_Identity <- .id_map[dat$label_identity]
dat$Label_Standardized_Identity <- .std_map[dat$label_identity]

# ---- 派生列 ----
dat$Matching <- ifelse(dat$match == 1, "Matching", "Nonmatching")
dat$ACC <- ifelse(is.na(.keys), NA_integer_, as.integer(.corr))  # 无反应 → NA
dat$RT_ms <- ifelse(is.na(.keys), NA_integer_, round(as.numeric(.rt) * 1000))
dat$RT_sec <- dat$RT_ms / 1000
dat$Trial <- as.integer(ave(seq_len(nrow(dat)), dat$Subject, dat$phase,
                            FUN = seq_along))        # 阶段内试次序号
.rt_ok <- !is.na(dat$RT_ms) & dat$RT_ms > 0
stopifnot(all(dat$RT_ms[.rt_ok] < 5000))             # 量级 sanity（无过滤）

# ---- 守卫 4：条件平衡（正式试次：每被试 匹配/非匹配 180 各半、三身份各 120） ----
.fdat <- dat[dat$phase == "formal", ]
.bal <- tapply(.fdat$match == 1, .fdat$Subject, sum)
stopifnot(all(.bal == 180))
.bal2 <- tapply(.fdat$label_identity, .fdat$Subject, function(x) table(x))
stopifnot(all(sapply(.bal2, function(x) all(x == 120))))
cat("guard 4 OK: per-subject 180 matching / 120 per identity (formal)\n")

# ---- 行序：按 Subject + 原始行序（文件内练习→正式） ----
dat <- dat[order(dat$Subject, seq_len(nrow(dat))), ]

# ---- 产出 1：raw（保留作者原始列 + Subject + 身份三级） ----
.raw <- dat[, c("Subject", "phase", "condition", "label", "shape", "correct",
                "match", "label_identity", "shape_identity", "group",
                "key_resp.keys", "key_resp.corr", "key_resp.rt",
                "key_resp_formal.keys", "key_resp_formal.corr",
                "key_resp_formal.rt", "ID", "age", "sex", "date", "expName",
                "psychopyVersion", "frameRate")]
write.csv(.raw, file.path(.study_dir, "Qi_2025_SciData_Exp1_raw.csv"),
          row.names = FALSE)
cat("  raw:", nrow(.raw), "rows\n")

# ---- 产出 2：Clean（标准列 + Phase 标注练习） ----
.cl <- data.frame(
  Subject = dat$Subject,
  Phase = dat$phase,
  Trial = dat$Trial,
  Shape = sub("[.]png$", "", dat$shape),             # 实际形状名
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
write_clean_csv(.cl, file.path(.study_dir,
                               "Qi_2025_SciData_Exp1_Clean.csv"))
stopifnot(nrow(.cl) == nrow(.raw),
          length(unique(.cl$Subject)) == 134)
cat("  Clean:", nrow(.cl), "rows /", length(unique(.cl$Subject)),
    "subjects;",
    "self-match RT mean =",
    round(mean(.cl$RT_ms[.cl$Label_Standardized_Identity == "Self" &
                         .cl$Matching == "Matching" & .cl$Phase == "formal"],
               na.rm = TRUE), 1), "ms\n")

# ---- 产出 3：subj_info（134 行；sex '男' 归一 Male） ----
.s0 <- dat[!duplicated(dat$Subject), ]
.subj <- data.frame(
  Subject_ID = .s0$Subject,
  Exp_id = rep("Qi_2025_SciData_Exp1", nrow(.s0)),
  Age = .s0$age,
  Gender = ifelse(.s0$sex %in% c("1", "男"), "Male", "Female"),
  Group = sub("[.]0$", "", .s0$group),               # counterbalance 组 1-12
  Date = .s0$date,
  stringsAsFactors = FALSE)
.subj <- .subj[order(.subj$Subject_ID), ]
stopifnot(nrow(.subj) == 134,
          sum(.subj$Gender == "Male") == 57, sum(.subj$Gender == "Female") == 77)
write_clean_csv(.subj, file.path(.study_dir,
                                 "Qi_2025_SciData_Exp1_subj_info.csv"))
cat("  subj_info:", nrow(.subj), "rows; M/F =",
    sum(.subj$Gender == "Male"), "/", sum(.subj$Gender == "Female"),
    "; Age mean =", round(mean(as.numeric(.subj$Age)), 2), "\n")

cat("DONE. 134 subjects x 360 formal trials; ACC/RT guards passed.\n")
