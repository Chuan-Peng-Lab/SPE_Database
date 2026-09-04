# ============================================================================
# Bukowski_2021_ActaPsych — 独立清洗脚本：标准 raw/Clean/subj_info（Exp2）
# ----------------------------------------------------------------------------
# 背景（2026-09 阶段 5 入库）：Bukowski, Todorova, Boch, Silani & Lamm (2021),
# "Socio-cognitive training impacts emotional and perceptual self-salience but
# not self-other distinction", Acta Psychologica 216:103297, DOI
# 10.1016/j.actpsy.2021.103297（Crossref 核对通过；OSF pcv3u；University of
# Vienna 实验室采集）。两实验均含 Sui et al. (2012) 式形状-标签匹配任务
# （库内只收匹配任务；affective touch / 手指运动训练任务不入库）：
#   学习阶段：triangle/square/circle 三个形状 ↔ 三个标签
#     （德语 Sie=您/self、Freund=friend、Fremder=stranger；论文英文描述
#       you/best friend/unfamiliar person，实际刺激为德语）任意绑定；
#   测试阶段：500 ms fixation → 100 ms 形状+标签（800-1200 ms 响应窗，
#     m/n 键判断匹配与否，键映射 counterbalanced）→ 500 ms 反馈。
#   练习 9 试次（论文文字 "12 trials practice block"，数据实际 9 ——
#     按数据口径 Practice_Trial=9，论文差异记 CSV Note/exp JSON detail）；
#   正式 6 blocks × 60 = 360 试次/被试（论文文字 "three blocks of 60
#     trials"，数据实际 6 段 × 60 —— 按数据口径 numBlocks=6/numTrials=360，
#     论文差异记 Note）。
#
# 数据格式（输入区 pcv3u-osfstorage-archive/Raw data xp1xp2/）：
#   exp1/shape matching/          87 个 .edat2（二进制，无 txt —— 用户用
#                                 E-DataAid 转换后入库，转换 txt 放同目录）
#   exp2/trained 2.0 shape matching/  107 对 .edat2 + .txt（txt 为 E-Prime
#                                 文本导出，UTF-16LE，可解析）
#   exp2/.../bukowski_exp2_fix_subjID.xlsx  —— 用户整理（2026-09）：从
#     Book1.xlsx Data_and_counterbalance 提取并重编号：file（txt 文件名）、
#     Subject_eprime（E-Prime 原始编号）、Recode_subjID（库内唯一编号
#     1-113）、Outliers（1 = 无效被试，剔除）、Priming（训练组
#     Imitation/Counter-Imitation/Inhibition-control）。
#
# txt 内 LogFrame 结构（每被试）：Header（Subject/Session/Group/SessionDate/
#   SessionStartDateTimeUtc/DataFile.Basename/RandomSeed）+ 9 PracTrialProc
#   （练习）+ 1 PracProc（练习结束帧）+ 6 BlockProc（BlockList.Sample 1-6，
#   休息帧）+ 360 TrialProc（正式）。正式帧字段：TrialList(=块内序号 1-60)
#   Target(=S.bmp/T.bmp/C.bmp 形状图片文件) Shape(=Self/Friend/Stranger
#   形状身份) YesNoResp(=Yes 匹配/No 非匹配语义) CorrectAnswer(=m/n 正确键)
#   Label(=Sie/Freund/Fremder 标签文字) Target.ACC(=0/1) Target.RT(=整数 ms，
#   0=无反应) Target.RESP(=m/n/空) Target.CRESP(=m/n)。
#
# 无反应：RESP 空 & RT=0 & ACC=0 → 库内 ACC=NA、RT_ms=NA（E-Prime 对无反应
#   记 ACC=0，按项目约定无反应一律 NA）；有反应 ACC=Target.ACC 保留。
#
# 被试编号（用户决策 2026-09）：Subject = bukowski_exp2_fix_subjID.xlsx 的
#   Recode_subjID（用户从 Book1 Data_and_counterbalance 重编号，唯一）；
#   Outliers==1 的被试剔除（有文件的 4 人：156-2/911-2/919-2/812-3 → 剔除；
#   无文件 5 行天然无数据）；E-Prime 原始编号保留于 raw 的 Subject_EPrime
#   列。有效被试 = 107 − 4 = 103。
#
# 身份映射（用户确认 2026-09）：
#   Label 侧：Sie→You→Self、Freund→Friend→Close、Fremder→Stranger→Stranger
#   Shape 侧：数据 Shape 变量为身份词 Self/Friend/Stranger（英文原样）→
#     Origin=Self/Friend/Stranger、English 相同、Std=Self/Close/Stranger
#   Shape 列 = Target 文件原样（S.bmp/T.bmp/C.bmp；图片文件未随附，S/T/C
#     疑为 Square/Triangle/Circle 首字母但无法验证，用户确认填文件名原样）
#   Label 列 = 德语标签文字原样（Sie/Freund/Fremder）
#   Stim_language = German（用户确认；实际刺激为德语）。
#
# 训练组（组间设计，用户确认拆行；Priming 列）：Imitation (1) /
#   Counter-Imitation (2) / Inhibition-control (3) → 论文用语
#   imitation / imitation-inhibition / control-inhibition。
#
# N 口径（用户确认：分 group 统计，数据口径优先）：
#   Exp2 有效数据 103 人（107 txt − 4 Outliers=1）；组内：
#   imitation 35 / imitation-inhibition 34 / control-inhibition 34（自
#   fix_subjID 表统计）；论文 111 招募 / 109 final（37/36/36）/ 97 分析
#   （35/30/32）记 Note。仅女性被试（论文 "Only female participants were
#   recruited"）→ Male=0、Female=组内 N。
#
# 清洗 = 最小预处理：不过滤（RT 极值/ACC 0 全保留，无反应 NA）；练习试次
# 保留并以 Phase 列标注（SKILL 惯例）。
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
.study_dir <- file.path(.root, "1_Data", "Bukowski_2021_ActaPsych")
.inp_dir <- file.path(.study_dir, "Bukowski_2021_ActaPsych_Raw",
                      "pcv3u-osfstorage-archive")
stopifnot(dir.exists(.inp_dir))
.exp1_txt_dir <- file.path(.inp_dir, "Raw data xp1xp2", "exp1", "shape matching")
.exp2_txt_dir <- file.path(.inp_dir, "Raw data xp1xp2", "exp2",
                           "trained 2.0 shape matching")
.fix_path <- file.path(.exp2_txt_dir, "bukowski_exp2_fix_subjID.xlsx")
stopifnot(file.exists(.fix_path))

# ---- 读用户整理的被试编号/剔除/训练组表 ----
suppressMessages(library(readxl))
.fix <- read_excel(.fix_path)
stopifnot(all(c("file", "Subject_eprime", "Recode_subjID", "Outliers",
                "Priming") %in% names(.fix)))
.fix <- .fix[!is.na(.fix$file), ]               # 去掉无 txt 文件的 5 行
cat("fix table: file rows:", nrow(.fix), "| Outliers=1:",
    sum(.fix$Outliers == 1), "| valid subjects:",
    sum(.fix$Outliers == 0), "\n")
stopifnot(sum(.fix$Outliers == 0) == 103)       # 107 − 4 = 103 有效被试

# ---- 身份映射表 ----
.std_map <- c(Self = "Self", You = "Self", Friend = "Close", Stranger = "Stranger",
              Sie = "Self", Freund = "Close", Fremder = "Stranger")

# ---- E-Prime txt 解析：返回 data.frame（被试级字段 + trial 级） ----
.parse_txt <- function(path) {
  lines <- read_eprime_txt(path)               # utils.R: UTF-16LE 逐行
  hdr <- parse_header(lines)
  frames <- list()
  starts <- grep("\\*\\*\\* LogFrame Start", lines)
  ends <- grep("\\*\\*\\* LogFrame End", lines)
  stopifnot(length(ends) == length(starts))
  for (i in seq_along(starts)) {
    block <- lines[(starts[i] + 1):(ends[i] - 1)]
    kv <- list()
    for (ln in block) {
      m <- regexec("^\\s*([^:]+):\\s*(.*)$", ln)
      if (length(m[[1]]) == 3 && m[[1]][1] != -1) {
        parts <- regmatches(ln, m)[[1]]
        kv[[trimws(parts[2])]] <- trimws(parts[3])
      }
    }
    if (!is.null(kv[["Procedure"]])) frames[[length(frames) + 1]] <- kv
  }
  procs <- vapply(frames, function(x) x[["Procedure"]], "")
  tr <- frames[procs == "TrialProc"]
  stopifnot(length(tr) == 360)                 # 6 blocks x 60
  pr <- frames[procs == "PracTrialProc"]
  stopifnot(length(pr) == 9)                   # 9 practice trials (data)
  blk <- frames[procs == "BlockProc"]
  stopifnot(length(blk) == 6)
  block_of <- ((seq_along(tr) - 1) %/% 60) + 1
  out <- lapply(seq_along(tr), function(j) {
    d <- tr[[j]]
    data.frame(
      Subject_EPrime = hdr$Subject,             # E-Prime 原始编号
      Session = hdr$Session,
      Group = hdr$Group,
      SessionDate = hdr$SessionDate,
      Phase = "formal",
      Block = block_of[j],
      Trial = as.integer(d[["TrialList.Sample"]]),   # 块内序号 1-60（E-Prime TrialList.Sample）
      Target = d[["Target"]],
      Shape = d[["Shape"]],
      Label = d[["Label"]],
      YesNoResp = d[["YesNoResp"]],
      CorrectAnswer = d[["CorrectAnswer"]],
      Target_ACC = d[["Target.ACC"]],
      Target_RT = d[["Target.RT"]],
      Target_RESP = d[["Target.RESP"]],
      Target_CRESP = d[["Target.CRESP"]],
      stringsAsFactors = FALSE)
  })
  out_pr <- lapply(pr, function(d) {
    data.frame(
      Subject_EPrime = hdr$Subject,
      Session = hdr$Session,
      Group = hdr$Group,
      SessionDate = hdr$SessionDate,
      Phase = "practice",
      Block = NA_integer_,
      Trial = as.integer(d[["PracTrialList.Sample"]]),
      Target = d[["Target"]],
      Shape = d[["Shape"]],
      Label = d[["Label"]],
      YesNoResp = d[["YesNoResp"]],
      CorrectAnswer = d[["CorrectAnswer"]],
      Target_ACC = d[["Target.ACC"]],
      Target_RT = d[["Target.RT"]],
      Target_RESP = d[["Target.RESP"]],
      Target_CRESP = d[["Target.CRESP"]],
      stringsAsFactors = FALSE)
  })
  do.call(rbind, c(out, out_pr))
}

# ---- Exp2（txt 已就绪） ----
.exp2_files <- sort(list.files(.exp2_txt_dir, pattern = "\\.txt$"))
stopifnot(length(.exp2_files) == 107)          # 107 名被试
cat("Exp2: reading", length(.exp2_files), "txt files\n")
.exp2 <- lapply(.exp2_files, function(f) {
  d <- .parse_txt(file.path(.exp2_txt_dir, f))
  d$file <- f
  d
})
.exp2 <- do.call(rbind, .exp2)

# ---- 合并 fix 表：Subject = Recode_subjID、剔除 Outliers=1、训练组 ----
.fixm <- .fix[, c("file", "Recode_subjID", "Outliers", "Priming")]
.exp2 <- merge(.exp2, .fixm, by = "file", all.x = TRUE)
stopifnot(all(!is.na(.exp2$Recode_subjID)))    # 107 文件全部有编号
.exp2 <- .exp2[.exp2$Outliers == 0, ]          # 剔除 4 名无效被试
.exp2$Subject <- as.character(.exp2$Recode_subjID)
.exp2$Recode_subjID <- NULL
.exp2$Outliers <- NULL
.exp2$file <- NULL

# ---- 守卫 1（Exp2 结构） ----
stopifnot(length(unique(.exp2$Subject)) == 103)
.fcnt <- tapply(.exp2$Phase == "formal", .exp2$Subject, sum)
.pcnt <- tapply(.exp2$Phase == "practice", .exp2$Subject, sum)
stopifnot(all(.fcnt == 360), all(.pcnt == 9))
.fsub <- .exp2[.exp2$Phase == "formal", ]
stopifnot(all(.fsub$Block >= 1), all(.fsub$Block <= 6))
stopifnot(all(.fsub$Trial >= 1), all(.fsub$Trial <= 60))
# 每被试每 block 内 Trial 1-60 各出现一次
.tperb <- tapply(.fsub$Trial, list(.fsub$Subject, .fsub$Block),
                 function(x) identical(sort(x), 1:60))
stopifnot(all(.tperb))
stopifnot(all(.exp2$Shape %in% c("Self", "Friend", "Stranger")))
stopifnot(all(.exp2$Label %in% c("Sie", "Freund", "Fremder")))
stopifnot(all(.exp2$Target %in% c("S.bmp", "T.bmp", "C.bmp")))
stopifnot(all(.exp2$YesNoResp %in% c("Yes", "No")))
stopifnot(all(.exp2$CorrectAnswer %in% c("m", "n")))
stopifnot(all(.exp2$Target_ACC %in% c("0", "1")))
stopifnot(all(.exp2$Target_CRESP %in% c("m", "n")))
stopifnot(all(.exp2$Target_RESP %in% c("", "m", "n")))
# 匹配语义：YesNoResp == Yes ⟺ Shape 身份 == Label 身份
.match_ok <- (.exp2$Shape == "Self" & .exp2$Label == "Sie") |
             (.exp2$Shape == "Friend" & .exp2$Label == "Freund") |
             (.exp2$Shape == "Stranger" & .exp2$Label == "Fremder")
stopifnot(all((.exp2$YesNoResp == "Yes") == .match_ok))
# 键映射 counterbalanced（一半被试 Yes→n，一半 Yes→m）
.keymap <- tapply(.exp2$CorrectAnswer[.exp2$YesNoResp == "Yes"],
                  .exp2$Subject[.exp2$YesNoResp == "Yes"],
                  function(x) unique(x))
stopifnot(all(vapply(.keymap, length, 0L) == 1),
          all(vapply(.keymap, function(x) x %in% c("m", "n"), logical(1))))
cat("guard 1 (Exp2 structure) OK: 103 subjects x 360 trials; match logic, key mapping, value domains all pass\n")

# ---- 守卫 2（Exp2 无反应语义） ----
.noresp <- .exp2$Target_RESP == ""
stopifnot(all(.exp2$Target_ACC[.noresp] == "0"),
          all(.exp2$Target_RT[.noresp] == "0"))
.rts <- as.integer(.exp2$Target_RT[!.noresp])
stopifnot(all(.rts > 0), all(.rts < 10000))
cat("guard 2 (no-response semantics) OK:", sum(.noresp),
    "no-response trials -> ACC/RT NA\n")

# ---- 标准化（Exp2） ----
.acc <- as.integer(.exp2$Target_ACC)
.acc[.noresp] <- NA_integer_
.rt <- as.integer(.exp2$Target_RT)
.rt[.noresp] <- NA_integer_
clean2 <- data.frame(
  Subject = .exp2$Subject,
  Task = "self-matching",                       # 全库模板 v2（2026-09-01 定案）
  Phase = .exp2$Phase,
  Block = .exp2$Block,
  Trial = .exp2$Trial,
  Matching = ifelse(.exp2$YesNoResp == "Yes", "Matching", "Nonmatching"),
  Shape = .exp2$Target,                        # 实际刺激文件原样（用户确认）
  Shape_Origin_Identity = .exp2$Shape,         # 数据原样（身份词英文）
  Shape_English_Identity = .exp2$Shape,
  Shape_Standardized_Identity = .std_map[.exp2$Shape],
  Label = .exp2$Label,                         # 德语标签原样
  Label_Origin_Identity = .exp2$Label,         # 德语原样
  Label_English_Identity = ifelse(.exp2$Label == "Sie", "You",
                           ifelse(.exp2$Label == "Freund", "Friend", "Stranger")),
  Label_Standardized_Identity = .std_map[.exp2$Label],
  RT_ms = .rt,
  ACC = .acc,
  stringsAsFactors = FALSE)
stopifnot(all(clean2$Shape_Standardized_Identity %in%
                c("Self", "Close", "Stranger")))
stopifnot(all(clean2$Label_Standardized_Identity %in%
                c("Self", "Close", "Stranger")))

# ---- 输出（Exp2 raw/Clean/subj_info） ----
.exp2_dir <- file.path(.study_dir, "Exp2")
dir.create(.exp2_dir, showWarnings = FALSE, recursive = TRUE)
raw2 <- data.frame(
  Subject = .exp2$Subject, Subject_EPrime = .exp2$Subject_EPrime,
  Session = .exp2$Session, Group = .exp2$Group,
  SessionDate = .exp2$SessionDate, Phase = .exp2$Phase,
  Block = .exp2$Block,
  TrialList.Sample = .exp2$Trial, Target = .exp2$Target, Shape = .exp2$Shape,
  Label = .exp2$Label, YesNoResp = .exp2$YesNoResp,
  CorrectAnswer = .exp2$CorrectAnswer, Target.ACC = .exp2$Target_ACC,
  Target.RT = .exp2$Target_RT, Target.RESP = .exp2$Target_RESP,
  Target.CRESP = .exp2$Target_CRESP, Priming = .exp2$Priming,
  stringsAsFactors = FALSE)
stopifnot(nrow(raw2) == 103 * 369, nrow(clean2) == 103 * 369)
write.csv(raw2, file.path(.exp2_dir,
          "Bukowski_2021_ActaPsych_Exp2_raw.csv"), row.names = FALSE)
write_clean_csv(clean2, file.path(.exp2_dir,
                "Bukowski_2021_ActaPsych_Exp2_Clean.csv"))
cat("Exp2 products: raw", nrow(raw2), "rows / Clean", nrow(clean2),
    "rows /", length(unique(clean2$Subject)), "subjects\n")

# ---- subj_info（Exp2：Subject=Recode_subjID；论文仅女性/右利手） ----
.s2 <- .exp2[!duplicated(.exp2$Subject),
             c("Subject", "SessionDate", "Priming")]
.s2 <- .s2[order(.s2$Subject), ]
subj2 <- data.frame(
  Subject_ID = .s2$Subject,
  Exp_id = "Bukowski_2021_ActaPsych_Exp2",
  Age = "/",                                    # 无人口学数据来源（sav 不采用）
  Gender = "Female",                            # 论文仅招募女性
  Handedness = "Right",                         # 右利手为纳入标准
  Group = .s2$Priming,
  Date = .s2$SessionDate,
  stringsAsFactors = FALSE)
write.csv(subj2, file.path(.exp2_dir,
          "Bukowski_2021_ActaPsych_Exp2_subj_info.csv"),
          row.names = FALSE, na = "")
stopifnot(nrow(subj2) == 103)
cat("Exp2 subj_info:", nrow(subj2), "rows\n")

# ---- 训练组分布（供 CSV 行收口） ----
.grp_tab <- table(.s2$Priming)
cat("Exp2 group counts (data caliber):\n")
print(.grp_tab)
stopifnot(identical(as.integer(.grp_tab), c(33L, 35L, 35L)))  # counter 33 / imitation 35 / inhibition 35

# ---- 描述性统计方向核对（论文：self 最快最准、stranger 最慢；仅正式试次） ----
.direction <- function(d, exp_label) {
  d <- d[d$Phase == "formal", ]
  .s <- d$Shape_Standardized_Identity[d$Matching == "Matching"]
  .rt <- d$RT_ms[d$Matching == "Matching"]
  .acc <- d$ACC[d$Matching == "Matching"]
  .m <- tapply(.rt, .s, function(x) mean(x, na.rm = TRUE))
  .a <- tapply(.acc, .s, function(x) mean(x, na.rm = TRUE))
  cat(sprintf("  %s matching RT (ms): self %.1f / close %.1f / stranger %.1f | ACC: self %.3f / close %.3f / stranger %.3f\n",
      exp_label, .m["Self"], .m["Close"], .m["Stranger"],
      .a["Self"], .a["Close"], .a["Stranger"]))
  stopifnot(.m["Self"] < .m["Close"], .m["Close"] < .m["Stranger"],
            .a["Self"] > .a["Close"], .a["Close"] > .a["Stranger"])
}
.direction(clean2, "Exp2")

# ============================================================================
# Exp1（merge txt 已由用户转换，2026-08-31）
# ----------------------------------------------------------------------------
# 数据：shapematching_merge_all_20260831.txt = E-Merge 聚合导出（UTF-16LE，
#   扁平表格而非 LogFrame 块）：前 4 行为类型/列名表头（第 4 行 = 89 列名），
#   第 5 行起为数据行。87 个唯一 Subject（E-Prime 原始编号 101-416，与
#   DataFile.Basename 一一对应，无跨批次重复 → 无需重编号，用户决策 2026-09-02
#   用现有材料，不另建 fix 表）。每被试 369 行 = 9 PracTrialProc（练习，
#   PracTrialList.Sample 1-9）+ 360 TrialProc（正式 6 blocks × 60，
#   BlockList.Sample 1-6、TrialList.Sample 块内 1-60）。列语义与 Exp2 相同
#   （Target=S/T/C.bmp、Shape=Self/Friend/Stranger、Label=Sie/Freund/Fremder、
#   YesNoResp=Yes/No 匹配语义、CorrectAnswer=m/n 键、Target.ACC/RT/RESP/CRESP）。
# 剔除：outlier shape.txt 的 9 个编号（204/221/406/207/322/120/206/217/210）
#   = 无效被试（用户决策 2026-09-02）→ 有效 78 人。
# 训练组：res1.xlsx Sheet1 的 Subject + TrainCond（Imitation/Counter-Imitation/
#   Inhibition-control/Be-imitated）→ 论文口径 imitation / imitation-inhibition
#   / control-inhibition / be-imitated（用户决策 2026-09-02，拆 4 行）。
# N 口径：数据 78（87 − 9）；论文 132 招募 / 90 final（24/26/18/22）/
#   64 分析（16/17/14/17，ACC chance 剔除 22 人）记 CSV Note。
# ============================================================================

# ---- merge txt 扁平表解析（E-Merge 导出格式，非 LogFrame） ----
.parse_merge_txt <- function(path) {
  lines <- read_eprime_txt(path)             # UTF-16LE 逐行
  stopifnot(length(lines) > 4)
  cols <- strsplit(lines[4], "\t", fixed = TRUE)[[1]]
  stopifnot(length(cols) == 89)
  data_lines <- lines[5:length(lines)]
  data_lines <- data_lines[nzchar(trimws(data_lines))]
  out <- lapply(data_lines, function(ln) {
    v <- strsplit(ln, "\t", fixed = TRUE)[[1]]
    if (length(v) < length(cols)) v <- c(v, rep("", length(cols) - length(v)))
    names(v) <- cols
    v
  })
  do.call(rbind, lapply(out, function(v) as.data.frame(t(v), stringsAsFactors = FALSE)))
}

.exp1_merge <- file.path(.exp1_txt_dir, "shapematching_merge_all_20260831.txt")
stopifnot(file.exists(.exp1_merge))
cat("Exp1: parsing E-Merge export\n")
.exp1 <- .parse_merge_txt(.exp1_merge)
stopifnot(nrow(.exp1) == 87 * 369)           # 87 人 × (9 练习 + 360 正式)
stopifnot(length(unique(.exp1$Subject)) == 87)

# ---- 训练组：res1.xlsx Sheet1（Subject + TrainCond） ----
.res1 <- read_excel(file.path(.exp1_txt_dir, "res1.xlsx"), sheet = "Sheet1")
.res1 <- .res1[!is.na(.res1[[1]]) & grepl("^\\d+$", as.character(.res1[[1]])), ]
.tc_map <- setNames(as.character(.res1[[11]]), as.character(.res1[[1]]))
.tc_map <- .tc_map[!is.na(.tc_map) & .tc_map != "NA"]
.group_rename <- c(Imitation = "imitation", "Counter-Imitation" = "imitation-inhibition",
                   "Inhibition-control" = "control-inhibition", "Be-imitated" = "be-imitated")
.exp1$Priming <- unname(.group_rename[.tc_map[.exp1$Subject]])
stopifnot(all(!is.na(.exp1$Priming)))        # 87 人全部有训练组
cat("Exp1 group counts (87 files):\n"); print(table(.exp1$Priming[!duplicated(.exp1$Subject)]))

# ---- 剔除 outlier shape.txt 的 9 人 ----
.outl <- readLines(file.path(.exp1_txt_dir, "outlier shape.txt"), warn = FALSE)
.outl <- unique(trimws(.outl[nzchar(trimws(.outl))]))
stopifnot(length(.outl) == 9)
.exp1 <- .exp1[!(.exp1$Subject %in% .outl), ]
stopifnot(length(unique(.exp1$Subject)) == 78)
cat("Exp1: excluded", length(.outl), "outliers ->", length(unique(.exp1$Subject)), "valid subjects\n")

# ---- 列语义换算（与 Exp2 相同的字段名） ----
.proc <- .exp1[["Procedure[SubTrial]"]]
.stop_ok <- .proc %in% c("TrialProc", "PracTrialProc")
stopifnot(all(.stop_ok))
.exp1$Phase <- ifelse(.proc == "PracTrialProc", "practice", "formal")
.exp1$Block <- as.integer(ifelse(.exp1$Phase == "formal", .exp1$BlockList.Sample, NA))
.exp1$Trial <- as.integer(ifelse(.exp1$Phase == "formal", .exp1$TrialList.Sample,
                      .exp1$PracTrialList.Sample))
# 关键列值域
stopifnot(all(.exp1$Target %in% c("S.bmp", "T.bmp", "C.bmp")))
stopifnot(all(.exp1$Shape %in% c("Self", "Friend", "Stranger")))
stopifnot(all(.exp1$Label %in% c("Sie", "Freund", "Fremder")))
stopifnot(all(.exp1$YesNoResp %in% c("Yes", "No")))
stopifnot(all(.exp1$CorrectAnswer %in% c("m", "n")))
stopifnot(all(.exp1$Target.ACC %in% c("0", "1")))
stopifnot(all(.exp1$Target.CRESP %in% c("m", "n")))
stopifnot(all(.exp1$Target.RESP %in% c("", "m", "n")))

# ---- 守卫 1（Exp1 结构：78 人 × 369） ----
.fcnt <- tapply(.exp1$Phase == "formal", .exp1$Subject, sum)
.pcnt <- tapply(.exp1$Phase == "practice", .exp1$Subject, sum)
stopifnot(all(.fcnt == 360), all(.pcnt == 9))
.fsub <- .exp1[.exp1$Phase == "formal", ]
stopifnot(all(.fsub$Block >= 1), all(.fsub$Block <= 6))
stopifnot(all(.fsub$Trial >= 1), all(.fsub$Trial <= 60))
.tperb <- tapply(.fsub$Trial, list(.fsub$Subject, .fsub$Block),
                 function(x) identical(sort(as.integer(x)), 1:60))
stopifnot(all(.tperb))
# 匹配语义：YesNoResp == Yes ⟺ Shape 身份 == Label 身份
.match_ok1 <- (.exp1$Shape == "Self" & .exp1$Label == "Sie") |
              (.exp1$Shape == "Friend" & .exp1$Label == "Freund") |
              (.exp1$Shape == "Stranger" & .exp1$Label == "Fremder")
stopifnot(all((.exp1$YesNoResp == "Yes") == .match_ok1))
# 键映射 counterbalanced
.keymap1 <- tapply(.exp1$CorrectAnswer[.exp1$YesNoResp == "Yes"],
                   .exp1$Subject[.exp1$YesNoResp == "Yes"],
                   function(x) unique(x))
stopifnot(all(vapply(.keymap1, length, 0L) == 1),
          all(vapply(.keymap1, function(x) x %in% c("m", "n"), logical(1))))
cat("guard 1 (Exp1 structure) OK: 78 subjects x 360 trials; match logic, key mapping, value domains all pass\n")

# ---- 守卫 2（Exp1 无反应语义） ----
.noresp1 <- .exp1$Target.RESP == ""
stopifnot(all(.exp1$Target.ACC[.noresp1] == "0"),
          all(.exp1$Target.RT[.noresp1] == "0"))
.rts1 <- as.integer(.exp1$Target.RT[!.noresp1])
stopifnot(all(.rts1 > 0), all(.rts1 < 10000))
cat("guard 2 (Exp1 no-response semantics) OK:", sum(.noresp1),
    "no-response trials -> ACC/RT NA\n")

# ---- 标准化（Exp1） ----
.acc1 <- as.integer(.exp1$Target.ACC)
.acc1[.noresp1] <- NA_integer_
.rt1 <- as.integer(.exp1$Target.RT)
.rt1[.noresp1] <- NA_integer_
clean1 <- data.frame(
  Subject = .exp1$Subject,
  Task = "self-matching",                       # 全库模板 v2（2026-09-01 定案）
  Phase = .exp1$Phase,
  Block = .exp1$Block,
  Trial = as.integer(.exp1$Trial),
  Matching = ifelse(.exp1$YesNoResp == "Yes", "Matching", "Nonmatching"),
  Shape = .exp1$Target,                        # 实际刺激文件原样（同 Exp2）
  Shape_Origin_Identity = .exp1$Shape,         # 数据原样（身份词英文）
  Shape_English_Identity = .exp1$Shape,
  Shape_Standardized_Identity = .std_map[.exp1$Shape],
  Label = .exp1$Label,                         # 德语标签原样
  Label_Origin_Identity = .exp1$Label,         # 德语原样
  Label_English_Identity = ifelse(.exp1$Label == "Sie", "You",
                           ifelse(.exp1$Label == "Freund", "Friend", "Stranger")),
  Label_Standardized_Identity = .std_map[.exp1$Label],
  RT_ms = .rt1,
  ACC = .acc1,
  stringsAsFactors = FALSE)
stopifnot(all(clean1$Shape_Standardized_Identity %in% c("Self", "Close", "Stranger")))
stopifnot(all(clean1$Label_Standardized_Identity %in% c("Self", "Close", "Stranger")))

# ---- 输出（Exp1 raw/Clean/subj_info） ----
.exp1_dir <- file.path(.study_dir, "Exp1")
dir.create(.exp1_dir, showWarnings = FALSE, recursive = TRUE)
raw1 <- data.frame(
  Subject = .exp1$Subject, Session = .exp1$Session,
  SessionDate = .exp1$SessionDate, Phase = .exp1$Phase,
  Block = .exp1$Block,
  TrialList.Sample = .exp1$Trial, Target = .exp1$Target, Shape = .exp1$Shape,
  Label = .exp1$Label, YesNoResp = .exp1$YesNoResp,
  CorrectAnswer = .exp1$CorrectAnswer, Target.ACC = .exp1$Target.ACC,
  Target.RT = .exp1$Target.RT, Target.RESP = .exp1$Target.RESP,
  Target.CRESP = .exp1$Target.CRESP, Priming = .exp1$Priming,
  stringsAsFactors = FALSE)
stopifnot(nrow(raw1) == 78 * 369, nrow(clean1) == 78 * 369)
write.csv(raw1, file.path(.exp1_dir,
          "Bukowski_2021_ActaPsych_Exp1_raw.csv"), row.names = FALSE)
write_clean_csv(clean1, file.path(.exp1_dir,
                "Bukowski_2021_ActaPsych_Exp1_Clean.csv"))
cat("Exp1 products: raw", nrow(raw1), "rows / Clean", nrow(clean1),
    "rows /", length(unique(clean1$Subject)), "subjects\n")

# ---- subj_info（Exp1：Subject=E-Prime 编号原样；论文仅女性/右利手） ----
.s1 <- .exp1[!duplicated(.exp1$Subject),
             c("Subject", "SessionDate", "Priming")]
.s1 <- .s1[order(as.integer(.s1$Subject)), ]
subj1 <- data.frame(
  Subject_ID = .s1$Subject,
  Exp_id = "Bukowski_2021_ActaPsych_Exp1",
  Age = "/",                                    # 无人口学数据来源（同 Exp2）
  Gender = "Female",                            # 论文仅招募女性
  Handedness = "Right",                         # 右利手为纳入标准
  Group = .s1$Priming,
  Date = .s1$SessionDate,
  stringsAsFactors = FALSE)
write.csv(subj1, file.path(.exp1_dir,
          "Bukowski_2021_ActaPsych_Exp1_subj_info.csv"),
          row.names = FALSE, na = "")
stopifnot(nrow(subj1) == 78)
cat("Exp1 subj_info:", nrow(subj1), "rows\n")

# ---- Exp1 训练组分布（供 CSV 行收口） ----
.grp_tab1 <- table(subj1$Group)
cat("Exp1 group counts (data caliber, 78):\n"); print(.grp_tab1)

# ---- 描述性统计方向核对（Exp1，仅正式试次） ----
.direction(clean1, "Exp1")

cat("=== Bukowski clean.R finished ===\n")

cat("=== Bukowski clean.R finished ===\n")
