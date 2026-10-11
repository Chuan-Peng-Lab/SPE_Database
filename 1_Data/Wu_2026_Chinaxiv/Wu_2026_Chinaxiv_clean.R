#!/usr/bin/env Rscript
# =============================================================================
# Wu_2026_Chinaxiv_clean.R — Wu_2026_Chinaxiv（Exp1 / Exp2）独立清洗脚本
# -----------------------------------------------------------------------------
# 依据：.agents/skills/spe-database-curation/SKILL.md（列序模板 v2 / ACC 统一编码 /
#       Identity 三级标准化 / 最小预处理=不过滤）
#       + 3_Reports/Wu_2026_Chinaxiv_Ingestion_Plan.md（§5 列序与自变量映射、§5.1 Codebook 缺口处置）
#
# 输入（只读，输入区）：
#   Wu_2026_Chinaxiv_Raw/SPE_Rand_Dots-master/SPE_analysis/3_Data/exp1/RawData/motion/exp1_subj_<N>.csv   (N = 1–70)
#   Wu_2026_Chinaxiv_Raw/SPE_Rand_Dots-master/SPE_analysis/3_Data/exp1/RawData/color/exp1_subj_<N>.csv    (N = 71–141)
#   Wu_2026_Chinaxiv_Raw/SPE_Rand_Dots-master/SPE_analysis/3_Data/exp2/RawData/exp2_subj_<N>.csv           (N = 1–30, 36–65)
#
# 输出：Exp1/ 与 Exp2/ 下各 3 个标准文件（*_raw.csv / *_Clean.csv / *_subj_info.csv）
#
# 关键处理（与计划 §5 / §5.1 一致）
#  1) 只保留试次行（trial_type == "rdk"）。问卷题（part=survey 人口学；part=color_test 的
#     trial_type=survey-text 色盲图片筛查；part=survey_isMatch 绑定操纵检查）与 fullScreen /
#     instruction / fixation 行一律不入 Clean；问卷答案转 subj_info（2026-10-06 用户确认）。
#  2) Phase：staircase（motion_test / color_test 的试次）/ practice / main；以 instruction 标记定位正式段起点
#     （Exp2 两个辨别相关块各有起点：首块为 instruction_RDK_practice_end 之后紧邻的 instruction 行，
#      次块为 instruction_RDk_formal_beginning）。
#  3) Block：被试内跨 Task/Phase 连续编号（phase/task/part 变化、instruction_rest、练习轮起点、
#     阶梯每 12 试次一组）；Trial：块内序号（从 1 起）→ (Subject, Block, Trial) 唯一。
#  4) Task：匹配任务 = self-matching；辨别任务与阶梯段 = choice-task。
#  5) 自变量（全部落标准列，不设研究特有尾部列）：
#       第 1 自变量 association → Shape/Label 的 Identity 三级；
#       第 2 自变量 matchness   → Matching；
#       第 3 自变量 difficulty  → extraIV1（Exp1: very_easy/easy/difficult/very_difficult；Exp2: easy/hard）；
#       第 4 自变量 task relevance（仅 Exp2 辨别）→ extraIV2；
#       组间（Exp1 知觉维度 / Exp2 关联维度）→ Group。
#  6) 身份绑定逐被试恢复（正式匹配段 association × 特征值）：运动侧 coherent_direction 0=right / 180=left；
#     颜色侧 dot_color_final 首元素为目标色（hsl(225)=blue / hsl(0)=red）。两者均由辨别任务正确率核实
#     （运动组 0→arrowright 正确、180→arrowleft；颜色组 hsl(0) 目标→d 正确、hsl(225) 目标→k 正确）。
#     Shape = 承载身份的特征值（运动侧 left/right；颜色侧 blue/red），辨别任务中标签未呈现 →
#     Label 取关联身份标签（我 / 他·她），Codebook 已注明。
#  7) Exp2 早期版本文件（被试 25、26、27、28、58、59、60）无 task_type 列，且非关联维度块的
#     association 为空 → task relevance 由「块维度 == 被试关联维度 ? relevant : irrelevant」推出，
#     association 由绑定值重建（计划 §5.1 缺口 2 / Issue 5；Codebook 与 exp JSON detail 双处标注）。
#  8) 无反应（response 为空 / rt = -1）→ Response = NA、RT_ms = NA、ACC = NA。
#     raw 的 correct = "false" 是无反应试次的插件伪影，不得当作错误 0（计划 §5.1 缺口 5）。
#  9) 最小预处理：不删试次、不删被试、不改数值、不做 RT 过滤（作者分析的 [100,3000] / [100,4000] ms
#     窗口只写入 Codebook/JSON detail 说明）。
# =============================================================================

suppressMessages(library(data.table))

# ---- 工作目录自适应（Rscript --file=）---------------------------------------
args <- commandArgs(FALSE)
file_arg <- sub("^--file=", "", args[grep("^--file=", args)])
script_dir <- if (length(file_arg)) dirname(normalizePath(file_arg)) else getwd()
setwd(script_dir)                                   # -> 1_Data/Wu_2026_Chinaxiv
raw_root <- file.path("Wu_2026_Chinaxiv_Raw", "SPE_Rand_Dots-master", "SPE_analysis", "3_Data")
stopifnot(dir.exists(raw_root))

# ---- 常量 -------------------------------------------------------------------
DIR2LR   <- c("0" = "right", "180" = "left")        # 由辨别任务正确率核实
COL2NAME <- c("225" = "blue", "0" = "red")          # dot_color_final 首元素 = 目标（多数）色
DIFF1    <- c("1" = "very_easy", "2" = "easy", "3" = "difficult", "4" = "very_difficult")
ACC_CODES <- c(0, 1)

CLEAN_COLS_COMMON <- c(
  "Subject", "Group", "Task", "Phase", "Block", "Trial", "Matching", "Shape",
  "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
  "Label", "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
  "extraIV1"
)
CLEAN_COLS_TAIL <- c("Response", "RT_ms", "ACC")

# raw 保留的原始 jsPsych 列（作者原值，不改写；顺序按原表）
RAW_KEEP <- c(
  "part", "trial_type", "trial_index", "rt", "response", "correct", "choices",
  "correct_choice", "correct_response", "trial_duration", "response_ends_trial",
  "number_of_dots", "coherent_direction", "coherence", "opposite_coherence", "dot_radius",
  "dot_life", "move_distance", "aperture_width", "aperture_height", "dot_color",
  "dot_color_final", "color_change_delay", "target_color_proportion", "motion_change_delay",
  "dot_shape", "background_color", "RDK_type", "frame_rate", "number_of_frames",
  "canvas_width", "canvas_height", "data_label", "task", "difficulty", "isMatch",
  "association", "label", "task_type"
)

# ---- 小工具 -----------------------------------------------------------------
json_get <- function(s, key) {                       # 极简 JSON 取值（问卷 response 为简单平坦对象）
  if (is.na(s) || !nzchar(s)) return(NA_character_)
  pat <- sprintf('"%s"\\s*:\\s*"?([^",}]*)"?', key)
  m <- regmatches(s, regexpr(pat, s))
  if (!length(m)) return(NA_character_)
  trimws(sub(pat, "\\1", m))
}
feat_dir <- function(x) unname(DIR2LR[as.character(x)])                       # 方向 → left/right
feat_col <- function(x) {                                                     # 目标色 → blue/red
  h <- sub('^\\["hsl\\(([0-9]+),.*$', "\\1", x)
  out <- unname(COL2NAME[h])
  out[is.na(out)] <- NA_character_
  out
}
chr <- function(x) { x <- as.character(x); x[is.na(x)] <- ""; x }

# ---- 单被试处理 -------------------------------------------------------------
process_subject <- function(path, exp, sid, group_hint) {
  d <- read.csv(path, stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
  d[] <- lapply(d, chr)
  part <- d$part
  n <- nrow(d)

  # ---- 问卷题（非试次）→ subj_info ----
  info_json <- d$response[d$trial_type == "survey" & part == "survey"][1]
  screen_json <- d$response[d$trial_type == "survey-text"][1]
  manip_json <- d$response[part == "survey_isMatch"][1]
  sex_raw <- json_get(info_json, "sex")
  gender <- if (identical(sex_raw, "女")) "Female" else if (identical(sex_raw, "男")) "Male" else NA_character_
  hands <- json_get(info_json, "hands")
  handedness <- if (identical(hands, "右")) "Right" else if (identical(hands, "左")) "Left" else NA_character_
  colblind <- json_get(info_json, "color_blindness")
  coltest <- toupper(trimws(gsub("\\\\n|\\\\r", "", json_get(screen_json, "Q0"))))

  # ---- 试次行（trial_type == "rdk"）----
  is_trial <- d$trial_type == "rdk"

  # ---- Phase 状态机（含 Exp2 两块辨别各自的正式起点）----
  phase <- rep(NA_character_, n)
  idx_mf <- which(part == "instruction_match_formal"); i_mf <- if (length(idx_mf)) max(idx_mf) else Inf
  formal_seen <- FALSE; awaiting <- FALSE; cur_rdk <- ""
  for (i in seq_len(n)) {
    p <- part[i]
    if (!is_trial[i]) {
      if (p == "instruction_RDk_formal_beginning") { formal_seen <- TRUE; awaiting <- FALSE }
      else if (p == "instruction_RDK_practice_end") { awaiting <- TRUE }
      else if (p == "instruction" && awaiting) { formal_seen <- TRUE; awaiting <- FALSE }
      else if (p %in% c("instruction_RDK_practice", "instruction")) { awaiting <- FALSE }
      next
    }
    if (p %in% c("motion_test", "color_test")) { phase[i] <- "staircase" }
    else if (p == "match_RDK") { phase[i] <- if (i > i_mf) "main" else "practice" }
    else if (p %in% c("RDK", "RDK_motion", "RDK_color")) {
      if (!identical(p, cur_rdk)) { cur_rdk <- p; formal_seen <- FALSE }     # 换块 → 重置正式标记
      phase[i] <- if (formal_seen) "main" else "practice"
    }
    next
  }
  phase[is.na(phase) & is_trial] <- NA_character_      # 其它 rdk 行（不应出现）

  # ---- Block / Trial（被试内跨 Task/Phase 连续编号；阶梯每 12 试次一组）----
  boundary_parts <- c("instruction_rest", "instruction_continuePractice", "instruction_match_practice",
                      "instruction_RDK_practice", "instruction", "instruction_match_formal",
                      "instruction_RDk_formal_beginning", "instruction_RDK_beginning",
                      "instruction_practiceEnd", "instruction_RDK_practice_end")
  is_bnd <- part %in% boundary_parts
  tp <- which(!is.na(phase))
  blk <- integer(length(tp)); trl <- integer(length(tp))
  b <- 0L; t_in <- 0L; stair_in <- 0L; prev <- 0L
  prev_phase <- NA_character_; prev_task <- NA_character_; prev_part <- NA_character_
  for (k in seq_along(tp)) {
    i <- tp[k]
    gap <- if (i - prev > 1L) any(is_bnd[(prev + 1L):(i - 1L)]) else FALSE
    task_k <- if (part[i] == "match_RDK") "self-matching" else "choice-task"
    new_blk <- (k == 1L) || gap ||
      !identical(phase[i], prev_phase) || !identical(task_k, prev_task) || !identical(part[i], prev_part)
    if (identical(phase[i], "staircase")) new_blk <- new_blk || (stair_in >= 12L)
    if (new_blk) { b <- b + 1L; t_in <- 1L; stair_in <- 1L } else { t_in <- t_in + 1L; stair_in <- stair_in + 1L }
    blk[k] <- b; trl[k] <- t_in
    prev <- i; prev_phase <- phase[i]; prev_task <- task_k; prev_part <- part[i]
  }

  # ---- 特征、绑定与关联维度（用正式匹配段恢复）----
  fdir_all <- feat_dir(d$coherent_direction); fcol_all <- feat_col(d$dot_color_final)
  assoc_all <- chr(d$association)
  mm <- which(!is.na(phase) & phase == "main" & part == "match_RDK")
  bij <- function(a, f) {
    ok <- a %in% c("self", "other") & !is.na(f)
    if (!any(ok)) return(FALSE)
    s <- unique(f[ok & a == "self"]); o <- unique(f[ok & a == "other"])
    length(s) == 1L && length(o) == 1L && !identical(s, o)
  }
  assoc_dim <- if (bij(assoc_all[mm], fdir_all[mm])) "motion" else
               if (bij(assoc_all[mm], fcol_all[mm])) "colour" else NA_character_
  self_feat <- if (identical(assoc_dim, "motion")) unique(fdir_all[mm][assoc_all[mm] == "self"]) else
               if (identical(assoc_dim, "colour")) unique(fcol_all[mm][assoc_all[mm] == "self"]) else NA_character_
  other_feat <- if (identical(assoc_dim, "motion")) unique(fdir_all[mm][assoc_all[mm] == "other"]) else
                if (identical(assoc_dim, "colour")) unique(fcol_all[mm][assoc_all[mm] == "other"]) else NA_character_
  stopifnot(length(self_feat) == 1L, length(other_feat) == 1L, !identical(self_feat, other_feat))

  # 操纵检查（survey_isMatch）：被试自报的自我/他人特征
  if (identical(assoc_dim, "motion")) {
    ml <- json_get(manip_json, "move_left"); mr <- json_get(manip_json, "move_right")
    manip_self <- if (identical(ml, "我")) "left" else if (identical(mr, "我")) "right" else NA_character_
    manip_other <- if (identical(ml, "TA")) "left" else if (identical(mr, "TA")) "right" else NA_character_
  } else {
    cr <- json_get(manip_json, "color_red"); cb <- json_get(manip_json, "color_blue")
    manip_self <- if (identical(cr, "我")) "red" else if (identical(cb, "我")) "blue" else NA_character_
    manip_other <- if (identical(cr, "TA")) "red" else if (identical(cb, "TA")) "blue" else NA_character_
  }

  # Exp2 两相关块的呈现顺序
  rdk_parts_order <- unique(part[!is.na(phase) & phase != "staircase" & part %in% c("RDK_motion", "RDK_color")])
  rel_order <- if (length(rdk_parts_order) == 2L) {
    first_dim <- if (identical(rdk_parts_order[1], "RDK_motion")) "motion" else "colour"
    if (identical(first_dim, assoc_dim)) "relevant_first" else "irrelevant_first"
  } else NA_character_

  # ---- Clean 列 -------------------------------------------------------------
  keep <- tp
  task_clean <- ifelse(part[keep] == "match_RDK", "self-matching", "choice-task")
  assoc_rec <- assoc_all[keep]
  assoc_rec[!nzchar(assoc_rec)] <- NA_character_      # "" → NA（作者未导出/无联结）
  # 非阶梯辨别试次若 association 未导出（各早期版本文件）→ 由绑定值重建
  need <- which(is.na(assoc_rec) & !is.na(phase[keep]) & phase[keep] != "staircase" & task_clean == "choice-task")
  if (length(need)) {
    f <- if (identical(assoc_dim, "motion")) fdir_all[keep][need] else fcol_all[keep][need]
    assoc_rec[need] <- ifelse(f == self_feat, "self", ifelse(!is.na(f), "other", NA_character_))
  }
  shape_val <- if (identical(assoc_dim, "motion")) fdir_all[keep] else fcol_all[keep]
  lab_other <- if (identical(gender, "Female")) "她" else "他"
  label_val <- chr(d$label[keep])
  label_val[!nzchar(label_val)] <- NA_character_
  need2 <- which(is.na(label_val) & !is.na(phase[keep]) & task_clean == "choice-task")
  label_val[need2] <- ifelse(assoc_rec[need2] == "self", "我",
                      ifelse(assoc_rec[need2] == "other", lab_other, NA_character_))
  # difficulty → extraIV1
  diff_raw <- chr(d$difficulty[keep])
  extra1 <- if (exp == 1) unname(DIFF1[diff_raw]) else ifelse(diff_raw %in% c("easy", "hard"), diff_raw, NA_character_)
  # task relevance → extraIV2（仅 Exp2 辨别试次；阶梯段 = NA）
  extra2 <- rep(NA_character_, length(keep))
  if (exp == 2) {
    # 早期版本文件无 task_type 列 → 该列为空向量，须显式判空（nzchar(NA) 为 TRUE，不可直接用作条件）
    tt <- if ("task_type" %in% names(d)) chr(d$task_type[keep]) else rep("", length(keep))
    ph <- phase[keep]
    is_choice <- task_clean == "choice-task" & ph != "staircase"
    blk_dim <- ifelse(part[keep] == "RDK_motion", "motion",
               ifelse(part[keep] == "RDK_color", "colour", NA_character_))
    derived <- ifelse(blk_dim == assoc_dim, "relevant", "irrelevant")
    use_tt <- !is.na(tt) & nzchar(tt)
    extra2[is_choice] <- ifelse(use_tt[is_choice], tt[is_choice], derived[is_choice])
  }
  # Response / RT_ms / ACC（无反应：response 空 或 rt = -1 → NA）
  resp_raw <- chr(d$response[keep]); rt_raw <- chr(d$rt[keep]); corr_raw <- chr(d$correct[keep])
  noresp <- !nzchar(resp_raw) | rt_raw == "-1"
  resp_out <- ifelse(noresp | !nzchar(resp_raw), NA_character_, resp_raw)
  rt_out <- suppressWarnings(as.numeric(ifelse(!nzchar(rt_raw) | rt_raw == "-1", NA, rt_raw)))
  acc_out <- ifelse(noresp, NA_integer_,
                    ifelse(corr_raw == "true", 1L, ifelse(corr_raw == "false", 0L, NA_integer_)))

  clean <- data.frame(
    Subject = sid,
    Group = group_hint,
    Task = task_clean,
    Phase = phase[keep],
    Block = blk,
    Trial = trl,
    Matching = ifelse(chr(d$isMatch[keep]) == "match", "Matching",
               ifelse(chr(d$isMatch[keep]) == "mismatch", "Nonmatching", NA_character_)),
    Shape = shape_val,
    Shape_Origin_Identity = assoc_rec,
    Shape_English_Identity = ifelse(assoc_rec == "self", "Self", ifelse(assoc_rec == "other", "Other", NA_character_)),
    Shape_Standardized_Identity = ifelse(assoc_rec == "self", "Self", ifelse(assoc_rec == "other", "Stranger", NA_character_)),
    Label = label_val,
    Label_Origin_Identity = label_val,
    Label_English_Identity = ifelse(label_val == "我", "Self",
                             ifelse(label_val %in% c("他", "她"), "Other", NA_character_)),
    Label_Standardized_Identity = ifelse(label_val == "我", "Self",
                                  ifelse(label_val %in% c("他", "她"), "Stranger", NA_character_)),
    extraIV1 = extra1,
    stringsAsFactors = FALSE
  )
  if (exp == 2) clean$extraIV2 <- extra2
  clean$Response <- resp_out
  clean$RT_ms <- rt_out
  clean$ACC <- acc_out
  clean <- as.data.table(clean)
  # 兜底：Clean 中任何空字符串一律规范为字面量 NA
  for (cl in names(clean)) if (is.character(clean[[cl]])) clean[[cl]][!nzchar(clean[[cl]])] <- NA_character_

  # ---- raw 列（作者原值，仅保留试次行；加 Subject / Group）----
  raw_cols <- intersect(RAW_KEEP, names(d))
  raw <- data.frame(Subject = sid, Group = group_hint, d[keep, raw_cols, drop = FALSE],
                    stringsAsFactors = FALSE, check.names = FALSE)

  subj <- data.frame(
    Subject_ID = sid, Exp_id = paste0("Wu_2026_Chinaxiv_Exp", exp),
    Age = suppressWarnings(as.numeric(json_get(info_json, "age"))),
    Gender = gender, Handedness = handedness, Color_Blindness_SelfReport = colblind,
    Country = "China", First_Language = "Chinese",
    Group = group_hint, Self_Feature = self_feat,
    stringsAsFactors = FALSE
  )
  if (exp == 2) subj$Relevance_Block_Order <- rel_order
  subj$ColorTest_Answer <- coltest
  subj$Manip_Check_Self <- manip_self
  subj$Manip_Check_Other <- manip_other
  subj$Associated_Dimension <- assoc_dim
  list(clean = clean, raw = raw, subj = subj)
}

# ---- 主流程 -----------------------------------------------------------------
run_exp <- function(exp) {
  if (exp == 1) {
    files <- c(list.files(file.path(raw_root, "exp1/RawData/motion"), "^exp1_subj_.*\\.csv$", full.names = TRUE),
               list.files(file.path(raw_root, "exp1/RawData/color"),  "^exp1_subj_.*\\.csv$", full.names = TRUE))
    outdir <- "Exp1"; base <- "Wu_2026_Chinaxiv_Exp1"
  } else {
    files <- list.files(file.path(raw_root, "exp2/RawData"), "^exp2_subj_.*\\.csv$", full.names = TRUE)
    outdir <- "Exp2"; base <- "Wu_2026_Chinaxiv_Exp2"
  }
  stopifnot(length(files) > 0)
  sid_of <- function(p) as.integer(sub("^.*subj_([0-9]+)\\.csv$", "\\1", basename(p)))
  files <- files[order(sid_of(files))]
  dir.create(outdir, showWarnings = FALSE)

  cleans <- raws <- list(); subs <- list()
  for (p in files) {
    sid <- sid_of(p)
    grp <- if (exp == 1) (if (sid <= 70) "motion" else "colour") else NA_character_  # Exp2 Group 先占位
    r <- process_subject(p, exp, sid, if (exp == 1) grp else "placeholder")
    if (exp == 2) {  # Exp2：Group = 关联维度（被试间平衡变量）
      ad <- r$subj$Associated_Dimension[1]
      r$clean$Group <- ad; r$raw$Group <- ad; r$subj$Group <- ad
      stopifnot(identical(ad, if (sid <= 30) "motion" else "colour"))   # 与编号规则一致
    }
    cleans[[length(cleans) + 1L]] <- r$clean
    raws[[length(raws) + 1L]] <- r$raw
    subs[[length(subs) + 1L]] <- r$subj
  }
  Clean <- rbindlist(cleans, use.names = TRUE, fill = TRUE)
  Raw   <- rbindlist(raws,   use.names = TRUE, fill = TRUE)
  Subj  <- rbindlist(subs,   use.names = TRUE, fill = TRUE)

  # ---- 一致性检查 ----
  want <- if (exp == 1) c(CLEAN_COLS_COMMON, CLEAN_COLS_TAIL) else
           c(CLEAN_COLS_COMMON[1:16], "extraIV2", CLEAN_COLS_TAIL)
  stopifnot(identical(names(Clean), want))                              # 列名与列序（模板 v2）
  stopifnot(!anyDuplicated(Clean, by = c("Subject", "Block", "Trial"))) # 键唯一
  stopifnot(all(Clean$Task %in% c("self-matching", "choice-task")))
  stopifnot(all(Clean$Phase %in% c("staircase", "practice", "main")))
  stopifnot(all(is.na(Clean$Matching) | Clean$Matching %in% c("Matching", "Nonmatching")))
  stopifnot(all(is.na(Clean$ACC) | Clean$ACC %in% ACC_CODES))
  stopifnot(all(is.na(Clean$Shape) | Clean$Shape %in% c("left", "right", "blue", "red")))
  stopifnot(all(is.na(Clean$Shape_Standardized_Identity) | Clean$Shape_Standardized_Identity %in% c("Self", "Stranger")))
  stopifnot(all(is.na(Clean$Label_Standardized_Identity) | Clean$Label_Standardized_Identity %in% c("Self", "Stranger")))
  # Identity 三级完整性（Origin 非空 ⟹ English/Standardized 非空）
  chk <- function(o, e, s) { ok <- !is.na(Clean[[o]]); all(!ok | (!is.na(Clean[[e]]) & !is.na(Clean[[s]]))) }
  stopifnot(chk("Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity"))
  stopifnot(chk("Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity"))
  # 正式段试次数（raw 实测：Exp1 匹配 384 + 辨别 192；Exp2 匹配 192、辨别逐人 192–288）
  main_n  <- Clean[Phase == "main", .N, by = .(Subject, Task)]
  n_match <- main_n[Task == "self-matching", N]
  n_choice <- main_n[Task == "choice-task", N]
  stopifnot(all(n_match == (if (exp == 1) 384L else 192L)))
  if (exp == 1) stopifnot(all(n_choice == 192L)) else stopifnot(all(n_choice >= 192L & n_choice <= 288L))
  # 总行数（与计划 §3.3 一致）
  exp_total <- if (exp == 1) 109040L else 38544L
  if (nrow(Clean) != exp_total)
    warning(sprintf("Exp%d Clean 行数 %d ≠ 计划预期 %d（请核对 phase/block 解析）", exp, nrow(Clean), exp_total))
  # 抽样打印
  cat(sprintf("\n[Exp%d] 被试 %d | Clean 行 %d | raw 行 %d | 列 %d\n",
              exp, uniqueN(Clean$Subject), nrow(Clean), nrow(Raw), ncol(Clean)))
  print(Clean[, .N, by = .(Task, Phase)])
  print(Clean[, .N, by = .(Group, Shape_Origin_Identity)])

  fwrite(Clean, file.path(outdir, paste0(base, "_Clean.csv")), na = "NA")
  fwrite(Raw,   file.path(outdir, paste0(base, "_raw.csv")),   na = "NA")
  fwrite(Subj,  file.path(outdir, paste0(base, "_subj_info.csv")), na = "NA")
  cat(sprintf("WROTE %s/{_Clean,_raw,_subj_info}.csv\n", outdir))
  invisible(TRUE)
}

run_exp(1)
run_exp(2)
cat("\nAll done.\n")
