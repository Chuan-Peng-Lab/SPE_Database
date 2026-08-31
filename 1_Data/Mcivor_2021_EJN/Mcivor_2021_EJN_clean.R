# ============================================================================
# Mcivor_2021_EJN — 独立清洗脚本：标准 raw/Clean/subj_info（Exp1）
# ----------------------------------------------------------------------------
# 背景（阶段 5 入库，2026-09）：McIvor, Sui, Malhotra, Drury & Kumar (2021),
# "Self-referential processing and emotion context insensitivity in major
# depressive disorder", European Journal of Neuroscience 53(1):311-329,
# DOI 10.1111/ejn.14782（Oxford Brookes University 实验室采集，2018-05 ~
# 2019-04；伦理 1718/122）。数据：figshare "Participant E-Prime Data
# Combined.xlsx"（输入区；40 被试 x 972 行 = 12 训练 + 960 正式）+ "Participant
# data information.xlsx"（作者问卷/人口学：M.I.N.I. 诊断 + Age/Hand/BDI/RSES）。
#
# 任务（Sui et al. 2012 式匹配任务 + 情绪上下文）：每人从 6 种形状
# （circle/triangle/diamond/pentagon/hexagon/octagon）中 counterbalanced 分配
# 2 种，绑定 "self"/"other" 标签；形状内含 happy/sad/neutral 线条面孔
# （任务无关）。试次：fixation 800-1200 ms → 形状+标签 150 ms → 响应窗
# （刺激 onset 起 1150 ms；s/k 键判断匹配与否，键映射 counterbalanced）→
# 反馈 500 ms。6 块 x 150 + 末块 60 = 960 正式试次（12 条件 x 80/人）+ 12
# 训练试次（形状+标签、无面孔，SubTrial 1-12）。
#
# 数据要点（2026-09 勘察）：
#  - 合并导出无块结构（Block/Trial 恒 1，SubTrial 1-972 为原始试次序）；
#    Clean 的 Block 列按论文 6x150+60 从正式试次位置派生（末 60 试次在数据中
#    恰好每格 5 次/人平衡，与论文一致；1-6 块为全局随机化的程序性分段）。
#  - 响应记录于 ITI（训练）/ITI2（正式）slide：ITI2.RT 自刺激消失起算，
#    CorrrT = ITI2.RT + 150（自刺激 onset 起算，全量验证 0 失配）；无反应行
#    ITI2.RT=0、CorrrT=NA、作者 ACC=0。库内 RT_ms = CorrrT（onset 起算），
#    无反应 -> NA。
#  - 作者 ACC = (RESP == CRESP)；subject 7815 有 264 行 CRESP 未记录
#    （'{F4}'，全部落在按键错误/无反应行，作者 ACC=0 无误分类）。库内 ACC 按
#    RESP == Correctanswer 重算（Correctanswer 每被试每格恒定，0 失配验证），
#    与作者 ACC 全等。
#  - subject 9292 有 1 行 RESP='k' 但 RT=0/CorrrT=NA（按键在 slide 结束瞬间
#    登记，RT 未记录）：按 responded 处理（ACC 照算），RT_ms=NA。
#  - 临床分组（E-Prime Group 码与临床分组无关！控制组含码 0/1、抑郁组含
#    0/1/2）：来源 = 作者问卷文件 'Age, Hand, BDI, SE Trait' 表 CONTROL/
#    DEPRESSED 名单（各 20）。E-Prime subject 1 = 问卷 '0' 号（M.I.N.I. 表
#    抑郁名单记 '1'；E-Prime 导出有 1 无 0；论文 N=40（df 证据）与抑郁组 2M
#    均要求 subject 1 属抑郁组）。问卷年龄统计逐位复现论文（control
#    M=29.85/SD=11.69、depressed M=24.30/SD=6.99、control BDI M=5.50、
#    GAD 9/20、6M/2M）。年龄记录不一致（作者内部）：subject 1 E-Prime 24 vs
#    问卷 22；subject 10 E-Prime 22 vs 问卷 24（记 exp JSON detail）。
#  - 身份映射：label 'Self' -> Self、'Other'（陌生他人）-> Stranger；形状侧
#    按每人绑定（Selfshape -> Self、Othershape -> Stranger）。
#  - 清洗 = 最小预处理：不过滤（论文 RT<200 ms 正确试次剔除仅用于其 v 分析；
#    数据中 onset-RT<200 的正确试次仅 16 行（0.04%），与论文 "<0.0001%" 表述
#    不符，记 exp JSON detail 不建 Issue）；训练试次保留并以 Phase='training'
#    标注（Qi 先例）。
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
.study_dir <- file.path(.root, "1_Data", "Mcivor_2021_EJN")
.inp_dir <- file.path(.study_dir, "Mcivor_2021_EJN_Raw")
stopifnot(dir.exists(.inp_dir))
.e_file <- file.path(.inp_dir, "Participant E-Prime Data Combined.xlsx")
.q_file <- file.path(.inp_dir, "Participant data information.xlsx")
stopifnot(file.exists(.e_file), file.exists(.q_file))

# ---- 读 E-Prime 合并导出（105 列，列名保留原样） ----
dat <- as.data.frame(readxl::read_excel(.e_file, sheet = 1,
                                        .name_repair = "minimal"),
                     stringsAsFactors = FALSE)
stopifnot(nrow(dat) == 38880, ncol(dat) == 105)
dat$Subject <- as.character(dat$Subject)
cat("read E-Prime export:", nrow(dat), "rows x", ncol(dat), "cols\n")

# ---- 读问卷文件：Age/BDI 表（sheet 2）+ M.I.N.I. 表（sheet 1） ----
q0 <- as.data.frame(readxl::read_excel(.q_file, sheet = 2, col_names = FALSE),
                    stringsAsFactors = FALSE)
stopifnot(nrow(q0) == 43, ncol(q0) == 5)
qctrl <- q0[3:22, ]                       # 行 3-22 = CONTROL 名单（20）
qdepr <- q0[24:43, ]                      # 行 24-43 = DEPRESSED 名单（20）
.qb <- rbind(
  data.frame(id = as.character(qctrl[[1]]), q_age = as.numeric(qctrl[[2]]),
             q_hand = qctrl[[3]], bdi = as.numeric(qctrl[[4]]),
             se_trait = as.numeric(qctrl[[5]]), stringsAsFactors = FALSE),
  data.frame(id = as.character(qdepr[[1]]), q_age = as.numeric(qdepr[[2]]),
             q_hand = qdepr[[3]], bdi = as.numeric(qdepr[[4]]),
             se_trait = as.numeric(qdepr[[5]]), stringsAsFactors = FALSE))
.qb$id[.qb$id == "0"] <- "1"              # E-Prime subject 1 = 问卷 '0' 号
ctrl_ids <- as.character(qctrl[[1]])
depr_ids <- setdiff(.qb$id, ctrl_ids)
stopifnot(length(ctrl_ids) == 20, length(depr_ids) == 20,
          length(unique(c(ctrl_ids, depr_ids))) == 40)

m0 <- as.data.frame(readxl::read_excel(.q_file, sheet = 1, col_names = FALSE),
                    stringsAsFactors = FALSE)
stopifnot(nrow(m0) == 44, ncol(m0) == 23)   # 23 列 = 被试号 + 22 诊断列
.mini_names <- c("MINI_MDD_Current", "MINI_MDD_Recurrent",
                 "MINI_MDD_Melancholic", "MINI_Dysthymia", "MINI_Suicidality",
                 "MINI_Manic", "MINI_Hypomanic", "MINI_Panic",
                 "MINI_Agoraphobia", "MINI_Social_Phobia", "MINI_OCD",
                 "MINI_PTSD", "MINI_Alcohol_Dependence", "MINI_Alcohol_Abuse",
                 "MINI_Substance_Dependence", "MINI_Substance_Abuse",
                 "MINI_Psychotic", "MINI_Anorexia", "MINI_Bulimia",
                 "MINI_Anorexia_Bulimia", "MINI_GAD", "MINI_Antisocial_PD")
.mini_ctrl <- m0[4:23, c(1, 2:23)]        # 行 4-23 = 控制（M.I.N.I. 表有两行表头，
                                          # 数据行比 Age 表晚 1 行；列 1 = 被试号）
.mini_depr <- m0[25:44, c(1, 2:23)]       # 行 25-44 = 抑郁
.mini_all <- rbind(.mini_ctrl, .mini_depr)
names(.mini_all) <- c("id", .mini_names)
stopifnot(all(sort(.mini_all$id) == sort(c(ctrl_ids, depr_ids))))  # 40 人 M.I.N.I. 行全覆盖
stopifnot(any(.mini_all$id == "1"))       # M.I.N.I. 抑郁名单含 '1'（=E-Prime 1）
cat("read questionnaire: control", length(ctrl_ids), "/ depressed",
    length(depr_ids), "participants\n")

# ---- 临床分组 + 问卷量表合并到被试表 ----
# 注意：E-Prime 导出自带 'Group' 列（0/1/2 码，与临床分组无关）——临床分组
# 列显式命名 clinical_group，避免 merge 后缀冲突。
.grpdf <- data.frame(Subject = c(ctrl_ids, depr_ids),
                     Group = c(rep("control", 20), rep("depressed", 20)),
                     stringsAsFactors = FALSE)
.grpdf <- merge(.grpdf, .qb, by.x = "Subject", by.y = "id", all.x = TRUE)
.grpdf <- merge(.grpdf, .mini_all, by.x = "Subject", by.y = "id", all.x = TRUE)
stopifnot(nrow(.grpdf) == 40, all(!is.na(.grpdf$bdi)),
          all(!is.na(.grpdf$Group)))
.grcols <- .grpdf[, c("Subject", "Group", "bdi", "se_trait", "q_hand",
                      setdiff(names(.mini_all), "id"))]
names(.grcols)[names(.grcols) == "Group"] <- "clinical_group"
dat <- merge(dat, .grcols, by = "Subject", all.x = TRUE)
stopifnot(nrow(dat) == 38880, all(!is.na(dat$clinical_group)))

# ---- 阶段/条件/情绪/匹配 ----
dat$Phase <- ifelse(dat[["Procedure[SubTrial]"]] == "Proclearningphase1",
                    "training", "test")
stopifnot(all(dat$Phase %in% c("training", "test")))
.test <- dat$Phase == "test"              # 正式试次索引（后续全脚本共用）
dat$Emotion <- tolower(sub("^(Happy|Sad|Neutral).*$", "\\1", dat$CellLabel))
stopifnot(all(dat$Emotion %in% c("happy", "sad", "neutral")))
dat$Matching <- ifelse(grepl("nonmatch$", dat$CellLabel),
                       "Nonmatching", "Matching")
stopifnot(all(dat$Matching %in% c("Matching", "Nonmatching")))
# 正式试次的 Label 列未记录（全空）；Label2 列覆盖全部正式行且与格型一致
# （self 格 -> 'Self'、other 格 -> 'Other'，逐格全量验证）；训练行 Label 列有值。
# 注意：CellLabel 内嵌身份为小写（'Happyselfmatch'），Label/Label2 为大写。
dat$Label[.test] <- dat$Label2[.test]
stopifnot(all((dat$Label == "Self") == grepl("self", dat$CellLabel)),
          all((dat$Label == "Other") == grepl("other", dat$CellLabel)))

# ---- 形状（实际呈现）与身份三级 ----
dat$Shape <- NA_character_
dat$Shape[.test] <- sub("(happy|sad|neutral)[.]jpg$", "",
                        dat$Emotiveshape[.test])
.expected_shape <- ifelse(dat$Matching == "Matching",
                          ifelse(dat$Label == "Self", dat$Selfshape,
                                 dat$Othershape),
                          ifelse(dat$Label == "Self", dat$Othershape,
                                 dat$Selfshape))
stopifnot(all(dat$Shape[.test] == .expected_shape[.test]))
dat$Shape[!.test] <- .expected_shape[!.test]  # 训练行：按条件格推导（无面孔记录）
stopifnot(all(dat$Shape %in% c("Circle", "Triangle", "Diamond", "Pentagon",
                               "Hexagon", "Octagon")))
dat$Label_Origin_Identity <- dat$Label
dat$Label_English_Identity <- dat$Label
dat$Label_Standardized_Identity <- ifelse(dat$Label == "Self", "Self",
                                          "Stranger")
dat$Shape_Origin_Identity <- dat$Shape
dat$Shape_English_Identity <- dat$Shape
dat$Shape_Standardized_Identity <- ifelse(dat$Shape == dat$Selfshape, "Self",
                                          "Stranger")

# ---- 响应/ACC/RT（ITI=训练、ITI2=正式；CorrrT = onset 起算 RT） ----
.resp <- ifelse(.test, dat[["ITI2.RESP"]], dat[["ITI.RESP"]])
.rt_off <- ifelse(.test, dat[["ITI2.RT"]], dat[["ITI.RT"]])
.acc_auth <- ifelse(.test, dat[["ITI2.ACC"]], dat[["ITI.ACC"]])
.responded <- !is.na(.resp) & .resp %in% c("s", "k")
.late_key <- .responded & .rt_off == 0    # subject 9292 已知 1 行（RT 未记录）
stopifnot(sum(.late_key) == 1)
stopifnot(sum(!.responded & .rt_off != 0) == 0)
stopifnot(all(is.na(dat$CorrrT) == (!.responded | .late_key)))
.acc_ours <- ifelse(!.responded, NA_integer_,
                    as.integer(.resp == dat$Correctanswer))
stopifnot(all(.acc_ours[.responded & !.late_key] ==
                .acc_auth[.responded & !.late_key]))
stopifnot(all(.acc_auth[!.responded] == 0))
stopifnot(all(dat$CorrrT[.responded & !.late_key] ==
                .rt_off[.responded & !.late_key] + 150))
dat$ACC <- .acc_ours
dat$RT_ms <- ifelse(.responded & !.late_key, dat$CorrrT, NA_integer_)
dat$RT_sec <- dat$RT_ms / 1000
dat$Response <- ifelse(.responded, .resp, NA_character_)
stopifnot(all(dat$RT_ms[!is.na(dat$RT_ms)] < 5000))   # 量级 sanity

# ---- 守卫 1：结构（40 被试 x 972；训练 12/正式 960；每格 80 正式 + 1 训练） ----
stopifnot(length(unique(dat$Subject)) == 40)
.tbl <- table(dat$Subject, dat$Phase)
stopifnot(all(.tbl[, "training"] == 12), all(.tbl[, "test"] == 960))
.cnt <- table(dat$Subject[.test], dat$CellLabel[.test])
stopifnot(all(.cnt == 80))
.cnt2 <- table(dat$Subject[!.test], dat$CellLabel[!.test])
stopifnot(all(.cnt2 == 1))
cat("guard 1 OK: 40 subjects x (12 training + 960 test); 80 trials per cell",
    "(test)\n")

# ---- 守卫 2：Correctanswer 每被试每格恒定 + 匹配逻辑 0 失配 ----
.ca_tbl <- table(dat$Subject, dat$CellLabel, dat$Correctanswer)
stopifnot(sum(.ca_tbl > 0) == 40 * 12)    # 40 x 12 格各 1 个按键值
stopifnot(all((dat$Matching == "Matching") ==
                (dat$Shape_Standardized_Identity ==
                   dat$Label_Standardized_Identity)))
cat("guard 2 OK: Correctanswer constant per subject x cell; Matching == ",
    "(shape identity == label identity) for all", nrow(dat), "trials\n")

# ---- 守卫 3：作者 ACC 全等 + CorrrT 线性（已在上方内联验证） ----
cat("guard 3 OK: ACC recomputed == author ACC (", sum(.responded),
    "responded;", sum(!.responded), "no-response -> NA); CorrrT = RT + 150\n")

# ---- 守卫 4：临床分组（问卷名单 20/20；性别 6M/2M；问卷年龄/BDI 复现论文） ----
.su <- !duplicated(dat$Subject)            # 按被试（非试次行）计数
.sex <- tapply(dat$Sex[.su] == "male", dat$clinical_group[.su], sum)
stopifnot(unname(.sex["control"]) == 6, unname(.sex["depressed"]) == 2)
.qage_c <- .qb$q_age[.qb$id %in% ctrl_ids]
.qage_d <- .qb$q_age[.qb$id %in% depr_ids]
stopifnot(abs(mean(.qage_c) - 29.85) < 0.01, abs(sd(.qage_c) - 11.69) < 0.01,
          abs(mean(.qage_d) - 24.30) < 0.01, abs(sd(.qage_d) - 6.99) < 0.01)
stopifnot(abs(mean(.qb$bdi[.qb$id %in% ctrl_ids]) - 5.50) < 0.01)
.gad_n <- sum(.mini_all$MINI_GAD[.mini_all$id %in% depr_ids] == "Y")
stopifnot(.gad_n == 9)
.hand_mis <- sum((dat$Handedness[.su] == "right") !=
                   (ifelse(is.na(dat$q_hand[.su]), "?",
                           dat$q_hand[.su]) == "R"))
.hmis_subj <- unique(dat$Subject[.su][
  (dat$Handedness[.su] == "right") !=
    (ifelse(is.na(dat$q_hand[.su]), "?", dat$q_hand[.su]) == "R")])
stopifnot(.hand_mis == 1, .hmis_subj == "3")   # subject 3: E-Prime 'right' vs 问卷 'L'
cat("guard 4 OK: control 20 (6M/14F), depressed 20 (2M/18F); questionnaire",
    "age M 29.85 / 24.30; control BDI M 5.50; GAD", .gad_n, "/20;",
    "handedness mismatch = 1 (subject 3, author-file inconsistency)\n")

# ---- 派生：Trial（=原始 SubTrial 1-972）、Block（正式位置 6x150+60 派生） ----
dat$Trial <- dat$SubTrial
dat$Block <- NA_integer_
dat$Block[.test] <- ceiling((dat$SubTrial[.test] - 12) / 150)
stopifnot(all(dat$Block[.test] %in% 1:7))
.bal7 <- table(dat$CellLabel[.test & dat$Block == 7])
stopifnot(all(.bal7 == 200))              # 末块 60 试次 = 每格 5 次/人
cat("  derived Block 1-7 (6x150+60); final block balanced: 200 x 12 cells\n")

# ---- 行序：Subject（数值序）+ SubTrial ----
dat <- dat[order(as.numeric(dat$Subject), dat$SubTrial), ]
rownames(dat) <- NULL

# ---- 产出 1：raw（作者原列子集 + Subject；完整 105 列见输入区 xlsx） ----
.rawcols <- c("ExperimentName", "Subject", "Session", "Group", "Age", "Sex",
              "Handedness", "SessionDate", "SessionTime", "Block", "BlockList",
              "Trial", "SubTrial", "Procedure[Block]", "Procedure[Trial]",
              "Procedure[SubTrial]", "Counterbalance1", "CellLabel",
              "CellNumber", "Label", "Label2", "Correctanswer",
              "Correctanswerreal", "Incorrectanswerreal", "Emotiveshape",
              "Selfshape", "Selfshapeimage", "Selfshapeimagereal",
              "Othershape", "Othershapeimage", "Happyshapeself",
              "Happyshapeother", "Neutralshapeself", "Neutralshapeother",
              "Sadshapeself", "Sadshapeother", "Fixation", "Fixation2",
              "CorrrT", "ITI.ACC", "ITI.CRESP", "ITI.RESP", "ITI.RT",
              "ITI2.ACC", "ITI2.CRESP", "ITI2.RESP", "ITI2.RT",
              "Learningphase1", "Learningphaseslide1.ACC",
              "Learningphaseslide1.CRESP", "Learningphaseslide1.RESP",
              "Learningphaseslide1.RT", "RespCorrTrigger",
              "RespInCorrTrigger", "Testphase", "Testphaseslide1.Duration")
stopifnot(all(.rawcols %in% names(dat)))
.raw <- dat[, .rawcols]
write.csv(.raw, file.path(.study_dir, "Mcivor_2021_EJN_Exp1_raw.csv"),
          row.names = FALSE)
cat("  raw:", nrow(.raw), "rows x", ncol(.raw), "cols\n")

# ---- 产出 2：Clean（标准列 + Group/Phase/Block/Emotion/Response） ----
.cl <- data.frame(
  Subject = dat$Subject,
  Group = dat$clinical_group,
  Phase = dat$Phase,
  Block = dat$Block,
  Trial = dat$Trial,
  Emotion = dat$Emotion,
  Shape = dat$Shape,
  Label = dat$Label,
  Matching = dat$Matching,
  ACC = dat$ACC,
  RT_ms = dat$RT_ms,
  RT_sec = dat$RT_sec,
  Response = dat$Response,
  Label_Origin_Identity = dat$Label_Origin_Identity,
  Label_English_Identity = dat$Label_English_Identity,
  Label_Standardized_Identity = dat$Label_Standardized_Identity,
  Shape_Origin_Identity = dat$Shape_Origin_Identity,
  Shape_English_Identity = dat$Shape_English_Identity,
  Shape_Standardized_Identity = dat$Shape_Standardized_Identity,
  stringsAsFactors = FALSE)
write_clean_csv(.cl, file.path(.study_dir,
                               "Mcivor_2021_EJN_Exp1_Clean.csv"))
stopifnot(nrow(.cl) == nrow(.raw), length(unique(.cl$Subject)) == 40)
cat("  Clean:", nrow(.cl), "rows /", length(unique(.cl$Subject)),
    "subjects\n")

# ---- 产出 3：subj_info（40 行；E-Prime 人口学 + 问卷 BDI/SE + M.I.N.I. 诊断） ----
.s0 <- dat[!duplicated(dat$Subject), ]
.sd <- sub(" .*$", "", as.character(.s0$SessionDate))  # POSIXct/文本 → 日期部分
.is_serial <- grepl("^[0-9]{5}$", .sd)   # Excel 日期序列（如 43562 = 2019-04-07）
.sd[.is_serial] <- format(as.Date(as.numeric(.sd[.is_serial]),
                                  origin = "1899-12-30"))
.sd <- ifelse(grepl("^[0-9]{2}-[0-9]{2}-[0-9]{4}$", .sd),
              paste0(substr(.sd, 7, 10), "-", substr(.sd, 1, 2), "-",
                     substr(.sd, 4, 5)),
              .sd)
stopifnot(all(grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", .sd)))
.subj <- data.frame(
  Subject_ID = .s0$Subject,
  Exp_id = rep("Mcivor_2021_EJN_Exp1", nrow(.s0)),
  Group = .s0$clinical_group,
  Age = .s0$Age,
  Gender = ifelse(.s0$Sex == "male", "Male", "Female"),
  Handedness = .s0$Handedness,
  BDI = .s0$bdi,
  SE_Trait = .s0$se_trait,
  SessionDate = .sd,
  Counterbalance1 = .s0$Counterbalance1,
  Selfshape = .s0$Selfshape,
  Othershape = .s0$Othershape,
  stringsAsFactors = FALSE)
.subj <- cbind(.subj, .s0[, .mini_names, drop = FALSE])
.subj <- .subj[order(as.numeric(.subj$Subject_ID)), ]
stopifnot(nrow(.subj) == 40,
          sum(.subj$Gender == "Male") == 8,
          all(!is.na(.subj$BDI)))
write_clean_csv(.subj, file.path(.study_dir,
                                 "Mcivor_2021_EJN_Exp1_subj_info.csv"))
cat("  subj_info:", nrow(.subj), "rows; M/F =", sum(.subj$Gender == "Male"),
    "/", sum(.subj$Gender == "Female"), "\n")

# ---- 方向输出（正式试次，供描述性核对） ----
.f <- .cl[.cl$Phase == "test" & !is.na(.cl$ACC), ]
.rtf <- .f[!is.na(.f$RT_ms), ]
for (g in c("control", "depressed")) {
  .g <- .rtf[.rtf$Group == g, ]
  .self <- .g$Label_Standardized_Identity == "Self"
  cat(sprintf("%s: self-match RT %.0f vs other-match RT %.0f ms; ACC self %.3f vs other %.3f\n",
              g,
              mean(.g$RT_ms[.self & .g$Matching == "Matching"]),
              mean(.g$RT_ms[!.self & .g$Matching == "Matching"]),
              mean(.g$ACC[.self & .g$Matching == "Matching"]),
              mean(.g$ACC[!.self & .g$Matching == "Matching"])))
}
cat("DONE. Mcivor_2021_EJN: 40 subjects (20 control / 20 depressed);",
    "38880 rows; ACC/RT/分组守卫全过。\n")
