# ============================================================================
# Wang_2016_JEPHPP_clean.R — Wang, Humphreys & Sui (2016, JEPHPP) Exp1/Exp2 重建
# ----------------------------------------------------------------------------
# v2（2026-09-01，txt 转换后核对版）：
#   数据源改为输入区 6 份 E-Merge txt（E-DataAid 文本导出，UTF-16LE，由项目
#   负责人从 edat2/emrg2 转换）：
#     RawData_Exp1/SelfAssociate_merge_20260831.txt      （Exp1 association）
#     RawData_Exp1/breaking_merge_20260831.txt           （Exp1 breaking, TR4 版, 被试 3-10,24）
#     RawData_Exp1/breaking_mn_merge_20260831.txt        （Exp1 breaking, TR5 版, 被试 11-22）
#     RawData_Exp2/SelfAssociate_merge_20260831.txt      （Exp2 association）
#     RawData_Exp2/breaking_merge_20260831.txt           （Exp2 breaking）
#   作者聚合 CSV（Wang_2016_JEPHPP_Exp{1,2}_{Association,Switch}.csv）仅作
#   验证基准：2_Code/wang2016_verify/verify_merge_vs_csv.py 逐值核对 0 差异
#   （Label/Identity/Shape/ACC/RESP/RT；CSV 缺 Exp2 breaking 的 9 practice 行
#   与两实验 association 的 6 practice 行——txt 均有）。
#
# v2 相对 v1（2026-08，CSV 重建）的变化：
#   1. association 阶段 Label/Matching 填实：association 任务实为 3AFC
#     （形状 + 三个标签同屏，键 b/n/m = 位置 1/2/3，CorrectAnswer = 正确标签
#     所在位置键）；每试次正确标签 = 形状初始指派身份（你/朋友/生人，全被试
#     恒定映射，verify 脚本逐试次验证 0 违例）。Clean Label = 英文标签名
#     （Exp1 大写 / Exp2 小写，与 breaking 一致）；Matching 全为 "Matching"
#     （3AFC 无失配试次）。
#   2. breaking 阶段新增 Block（1-8，TRxBlockList.Sample）与 Trial（1-81，
#      SubTrial）；新增 CorrResponse（= CorrectAnswer，n/m）。
#   3. Exp2 breaking 补入 practice 行（9/被试，作者 CSV 导出时丢弃）——
#     Exp2 每被试现为 657 行（同 Exp1）。
#   4. association practice 行（6/被试）补入。
#   5. 规则 B 守卫升级：用 txt 的 CorrectAnswer/YesNoResp 逐试次验证 Matching
#     （Matching == (CorrectAnswer == yeskey)，yeskey 每被试由 practice 行推断）。
#
# 任务结构（txt 验证，verify_merge_vs_csv.py）：
#   Association: 6 practice + 变长正式（学习到 6 连对/形状，M=2.38 min 论文口径）
#   Breaking:    9 practice + 8 blocks x 81（9 条件 x 72，1/3 匹配）
#   Matching 规则（规则 B，新指令映射）：
#     Exp1: self-shape->stranger, friend->self, stranger->friend
#     Exp2: self->friend, friend->stranger, stranger->self
#   Match = (Label == f(Identity))；Identity = 形状的 Part 1 身份。
#
# ACC/RT：无反应（Target.RESP=="" 且 Target.RT==0）→ NA；其余原样
# （ACC 1=correct / 0=wrong；RT ms）。
# ============================================================================

# ---- 引导块：定位脚本目录与 utils.R ----
.args <- commandArgs(trailingOnly = FALSE)
.script_dir <- sub("^--file=", "", .args[grep("^--file=", .args)])
if (length(.script_dir) == 0 || !nzchar(.script_dir)) .script_dir <- getwd()
.script_dir <- normalizePath(dirname(.script_dir))
source(file.path(.script_dir, "..", "utils.R"))
.root <- spe_root(.script_dir)
.study <- "Wang_2016_JEPHPP"
.sdir <- file.path(.root, "1_Data", .study)
.raw_dir <- file.path(.sdir, paste0(.study, "_Raw"))

# ============================================================================
# E-Merge 扁平 txt 解析（E-DataAid 文本导出：第 1-3 行类型/等级/列数，第 4 行列名）
# ============================================================================
read_merge_txt <- function(f) {
  con <- file(file.path(.raw_dir, f), open = "r", encoding = "UTF-16LE")
  lines <- readLines(con, warn = FALSE)
  close(con)
  hdr <- strsplit(lines[4], "\t")[[1]]
  rows <- lines[-(1:4)]
  list(hdr = hdr, rows = rows)
}
gcol <- function(parts, hdr, col) {
  i <- match(col, hdr)
  if (is.na(i) || i > length(parts)) return(NA_character_)
  v <- parts[i]
  if (v %in% c("", "NULL")) NA_character_ else v
}
norm_id <- function(v) {
  if (is.na(v)) return(NA_character_)
  switch(tolower(v), self = "Self", friend = "Friend", stranger = "Stranger",
         none = "Stranger", v)
}
lab_en <- function(v) {
  vapply(v, function(x) {
    if (is.na(x)) return(NA_character_)
    switch(x, "你" = "Self", "朋友" = "Friend", "生人" = "Stranger",
           self = "Self", friend = "Friend", stranger = "Stranger",
           Self = "Self", Friend = "Friend", Stranger = "Stranger", x)
  }, character(1))
}

# 解析 association 合并 txt：返回 per-subject list(practice, formal) data.frame
parse_assoc_txt <- function(f) {
  m <- read_merge_txt(f)
  subj_list <- list()
  for (ln in m$rows) {
    p <- strsplit(ln, "\t")[[1]]
    if (length(p) < 2 || is.na(p[2]) || p[2] == "") next
    s <- p[2]
    if (is.null(subj_list[[s]])) subj_list[[s]] <- list(practice = list(), formal = list())
    run <- gcol(p, m$hdr, "Running[SubTrial]")
    is_prac <- !is.na(run) && grepl("Prac", run)
    if (is_prac) {
      subj_list[[s]]$practice[[length(subj_list[[s]]$practice) + 1]] <-
        list(Identity = gcol(p, m$hdr, "Shape[SubTrial]"), Shape = gcol(p, m$hdr, "Target[SubTrial]"),
             ACC = gcol(p, m$hdr, "Target.ACC[SubTrial]"), RESP = gcol(p, m$hdr, "Target.RESP[SubTrial]"),
             RT = gcol(p, m$hdr, "Target.RT[SubTrial]"), CA = gcol(p, m$hdr, "CorrectAnswer[SubTrial]"),
             T1 = gcol(p, m$hdr, "T1[SubTrial]"), T2 = gcol(p, m$hdr, "T2[SubTrial]"), T3 = gcol(p, m$hdr, "T3[SubTrial]"),
             Age = gcol(p, m$hdr, "Age"), Sex = gcol(p, m$hdr, "Sex"), Handedness = gcol(p, m$hdr, "Handedness"),
             Group = gcol(p, m$hdr, "Group"), SessionDate = gcol(p, m$hdr, "SessionDate"),
             SubjCounterblance = gcol(p, m$hdr, "SubjCounterblance"))
    } else if (!is.na(gcol(p, m$hdr, "Procedure[LogLevel5]"))) {
      subj_list[[s]]$formal[[length(subj_list[[s]]$formal) + 1]] <-
        list(Identity = gcol(p, m$hdr, "Shape[LogLevel5]"), Shape = gcol(p, m$hdr, "Target[LogLevel5]"),
             ACC = gcol(p, m$hdr, "Target.ACC[LogLevel5]"), RESP = gcol(p, m$hdr, "Target.RESP[LogLevel5]"),
             RT = gcol(p, m$hdr, "Target.RT[LogLevel5]"), CA = gcol(p, m$hdr, "CorrectAnswer[LogLevel5]"),
             T1 = gcol(p, m$hdr, "T1[LogLevel5]"), T2 = gcol(p, m$hdr, "T2[LogLevel5]"), T3 = gcol(p, m$hdr, "T3[LogLevel5]"),
             Age = gcol(p, m$hdr, "Age"), Sex = gcol(p, m$hdr, "Sex"), Handedness = gcol(p, m$hdr, "Handedness"),
             Group = gcol(p, m$hdr, "Group"), SessionDate = gcol(p, m$hdr, "SessionDate"),
             SubjCounterblance = gcol(p, m$hdr, "SubjCounterblance"))
    }
  }
  subj_list
}

# 解析 breaking 合并 txt：返回 per-subject data.frame（全部行，含 practice）
parse_switch_txt <- function(f, use_target1_for_prac) {
  m <- read_merge_txt(f)
  out <- list()
  for (ln in m$rows) {
    p <- strsplit(ln, "\t")[[1]]
    if (length(p) < 2 || is.na(p[2]) || p[2] == "") next
    if (is.na(gcol(p, m$hdr, "Procedure[SubTrial]"))) next
    s <- p[2]
    if (is.null(out[[s]])) out[[s]] <- list()
    trial <- gcol(p, m$hdr, "Trial")
    is_prac <- !is.na(trial) && trial == "1"
    t1 <- is_prac && use_target1_for_prac
    acc <- gcol(p, m$hdr, if (t1) "Target1.ACC" else "Target.ACC")
    resp <- gcol(p, m$hdr, if (t1) "Target1.RESP" else "Target.RESP")
    rt <- gcol(p, m$hdr, if (t1) "Target1.RT" else "Target.RT")
    cresp <- gcol(p, m$hdr, if (t1) "Target1.CRESP" else "Target.CRESP")
    # block: TRxBlockList.Sample（x = 程序变体，Procedure[Block] 形如 TR4Proc）
    blk <- NA_character_
    pb <- gcol(p, m$hdr, "Procedure[Block]")
    if (!is.na(pb)) {
      x <- sub("^TR([0-9]+).*", "\\1", pb)
      if (grepl("^[0-9]+$", x)) blk <- gcol(p, m$hdr, paste0("TR", x, "BlockList.Sample"))
    }
    out[[s]][[length(out[[s]]) + 1]] <-
      list(Label = gcol(p, m$hdr, "Label"), Identity = gcol(p, m$hdr, "Shape"),
           Shape = gcol(p, m$hdr, "Target"), ACC = acc, RESP = resp, RT = rt,
           CA = gcol(p, m$hdr, "CorrectAnswer"), CRESP = cresp,
           YesNoResp = gcol(p, m$hdr, "YesNoResp"), Trial = trial,
           SubTrial = gcol(p, m$hdr, "SubTrial"), Block = blk,
           is_prac = is_prac,
           Age = gcol(p, m$hdr, "Age"), Sex = gcol(p, m$hdr, "Sex"), Handedness = gcol(p, m$hdr, "Handedness"),
           Group = gcol(p, m$hdr, "Group"), SessionDate = gcol(p, m$hdr, "SessionDate"),
           SubjCounterblance = gcol(p, m$hdr, "SubjCounterblance"))
  }
  out
}

# ---- 读取 6 份 txt ----
exp1_assoc <- parse_assoc_txt("RawData_Exp1/SelfAssociate_merge_20260831.txt")
exp2_assoc <- parse_assoc_txt("RawData_Exp2/SelfAssociate_merge_20260831.txt")
exp1_sw1  <- parse_switch_txt("RawData_Exp1/breaking_merge_20260831.txt", FALSE)
exp1_sw2  <- parse_switch_txt("RawData_Exp1/breaking_mn_merge_20260831.txt", FALSE)
exp2_sw   <- parse_switch_txt("RawData_Exp2/breaking_merge_20260831.txt", TRUE)
cat("Exp1 assoc subjects:", length(exp1_assoc), "| Exp2 assoc subjects:", length(exp2_assoc), "\n")
cat("Exp1 switch subjects:", length(exp1_sw1) + length(exp1_sw2), "| Exp2 switch subjects:", length(exp2_sw), "\n")

# ---- 构建 trial 级 raw（union 列） ----
as_df <- function(lst, phase) {
  rows <- list()
  for (s in names(lst)) {
    for (prac in c(TRUE, FALSE)) {
      blk <- if (prac) lst[[s]]$practice else lst[[s]]$formal
      for (t in blk) {
        rows[[length(rows) + 1]] <- data.frame(
          Subject = as.numeric(s), Phase = phase, Practice = as.integer(prac),
          Block = NA_integer_, Trial = NA_integer_,
          Label = t$T1,  # association 正确标签文本（= 指派身份标签）；由下方按 CA 位置重取
          Identity = norm_id(t$Identity), Shape = t$Shape,
          CorrectAnswer = t$CA, YesNoResp = NA_character_,
          T1 = t$T1, T2 = t$T2, T3 = t$T3,
          Target.ACC = t$ACC, Target.RESP = t$RESP, Target.RT = t$RT,
          Age = t$Age, Sex = t$Sex, Handedness = t$Handedness,
          Group = t$Group, SessionDate = t$SessionDate, SubjCounterblance = t$SubjCounterblance,
          stringsAsFactors = FALSE)
      }
    }
  }
  do.call(rbind, rows)
}
sw_df <- function(lst, phase) {
  rows <- list()
  for (s in names(lst)) {
    for (t in lst[[s]]) {
      rows[[length(rows) + 1]] <- data.frame(
        Subject = as.numeric(s), Phase = phase, Practice = as.integer(t$is_prac),
        Block = as.integer(t$Block), Trial = as.integer(t$SubTrial),
        Label = t$Label, Identity = norm_id(t$Identity), Shape = t$Shape,
        CorrectAnswer = t$CA, YesNoResp = t$YesNoResp,
        T1 = NA_character_, T2 = NA_character_, T3 = NA_character_,
        Target.ACC = t$ACC, Target.RESP = t$RESP, Target.RT = t$RT,
        Age = t$Age, Sex = t$Sex, Handedness = t$Handedness,
        Group = t$Group, SessionDate = t$SessionDate, SubjCounterblance = t$SubjCounterblance,
        stringsAsFactors = FALSE)
    }
  }
  do.call(rbind, rows)
}
exp1_a <- as_df(exp1_assoc, "Association")
exp2_a <- as_df(exp2_assoc, "Association")
exp1_s <- rbind(sw_df(exp1_sw1, "Breaking"), sw_df(exp1_sw2, "Breaking"))
exp2_s <- sw_df(exp2_sw, "Breaking")

# association 试次的呈现标签 = CA 键对应位置上的标签文本（3AFC 位置键 b/n/m = T1/T2/T3）
keypos <- c(b = "T1", n = "T2", m = "T3")
fix_assoc_label <- function(d) {
  lab <- rep(NA_character_, nrow(d))
  for (i in seq_len(nrow(d))) {
    col <- keypos[d$CorrectAnswer[i]]
    if (!is.na(col)) lab[i] <- d[[col]][i]
  }
  d$Label <- lab
  d
}
exp1_a <- fix_assoc_label(exp1_a)
exp2_a <- fix_assoc_label(exp2_a)
stopifnot(all(!is.na(exp1_a$Label)), all(!is.na(exp2_a$Label)))

# 排序（Subject, Phase, Practice 先（1 在前）, Block, Trial）
order_rows <- function(d) {
  key <- data.frame(
    Subject = d$Subject,
    Phase = d$Phase,
    Prac = -d$Practice,
    Block = ifelse(is.na(d$Block), 0L, d$Block),
    Trial = ifelse(is.na(d$Trial), 0L, d$Trial))
  d[do.call(order, key), , drop = FALSE]
}
exp1_raw <- order_rows(rbind(exp1_a, exp1_s))
exp2_raw <- order_rows(rbind(exp2_a, exp2_s))
exp1_raw$Target.RESP[is.na(exp1_raw$Target.RESP)] <- ""
exp2_raw$Target.RESP[is.na(exp2_raw$Target.RESP)] <- "" 
stopifnot(nrow(exp1_raw) == 2176 + 13797)  # assoc(2050+126 prac) + switch(21x657)
stopifnot(nrow(exp2_raw) == 1585 + 16425)  # assoc(1435+150 prac) + switch(25x657)

# ---- 转换 Clean ----
clean_exp <- function(d, exp_label) {
  fmap <- if (exp_label == "Exp1") c(Self = "Stranger", Friend = "Self", Stranger = "Friend") else
    c(Self = "Friend", Friend = "Stranger", Stranger = "Self")
  # yeskey：breaking practice 行中 YesNoResp=yes 的 CorrectAnswer（每被试恒定，守卫）
  yeskey <- tapply(ifelse(d$Phase == "Breaking" & d$Practice == 1 &
                            !is.na(d$YesNoResp) & tolower(d$YesNoResp) == "yes" &
                            !is.na(d$CorrectAnswer), d$CorrectAnswer, NA), d$Subject,
                   function(x) {
                     x <- x[!is.na(x) & x != ""]
                     if (length(unique(x)) != 1) stop("yeskey 不一致: ", paste(unique(x), collapse = ","))
                     x[1]
                   })
  d$yeskey <- yeskey[as.character(d$Subject)]
  # Matching：breaking 按规则 B；association 全为 Matching（3AFC 正确标签=指派身份）
  is_match <- ifelse(d$Phase == "Breaking",
                     lab_en(d$Label) == fmap[d$Identity],
                     TRUE)
  d$Matching <- ifelse(is_match, "Matching", "Nonmatching")
  # 守卫：Matching == (CorrectAnswer == yeskey)（breaking 全部行）
  ca_yes <- d$CorrectAnswer == d$yeskey
  bad <- d$Phase == "Breaking" & !is.na(ca_yes) & (is_match != ca_yes)
  stopifnot(!any(bad))
  # ACC/RT/Response：无反应 → NA
  noresp <- is.na(d$Target.RESP) | d$Target.RESP == ""
  d$ACC <- as.numeric(d$Target.ACC); d$ACC[noresp] <- NA
  d$RT_ms <- as.numeric(d$Target.RT); d$RT_ms[noresp] <- NA
  d$Response <- d$Target.RESP; d$Response[noresp] <- NA
  # 身份三层
  std_map <- c(Self = "Self", Friend = "Close", Stranger = "Stranger")
  lab_en_v <- lab_en(d$Label)
  out <- data.frame(
    Subject = d$Subject,
    Task = "self-matching",
    Phase = d$Phase,
    Block = d$Block,
    Trial = d$Trial,
    Practice = d$Practice,
    Matching = d$Matching,
    Shape = d$Shape,
    Shape_Origin_Identity = d$Identity,
    Shape_English_Identity = d$Identity,
    Shape_Standardized_Identity = unname(std_map[d$Identity]),
    Label = lab_en_v,
    Label_Origin_Identity = lab_en_v,
    Label_English_Identity = lab_en_v,
    Label_Standardized_Identity = unname(std_map[lab_en_v]),
    CorrResponse = d$CorrectAnswer,
    Response = d$Response,
    RT_ms = d$RT_ms,
    RT_sec = d$RT_ms / 1000,
    ACC = d$ACC,
    stringsAsFactors = FALSE
  )
  out
}
exp1_clean <- clean_exp(exp1_raw, "Exp1")
exp2_clean <- clean_exp(exp2_raw, "Exp2")

# ---- 守卫 ----
stopifnot(length(unique(exp1_clean$Subject)) == 21)
stopifnot(length(unique(exp2_clean$Subject)) == 25)
stopifnot(nrow(exp1_clean) == nrow(exp1_raw), nrow(exp2_clean) == nrow(exp2_raw))
br <- function(d) d[d$Phase == "Breaking", ]
stopifnot(abs(sum(br(exp1_clean)$Matching == "Matching") / nrow(br(exp1_clean)) - 1 / 3) < 0.01)
stopifnot(abs(sum(br(exp2_clean)$Matching == "Matching") / nrow(br(exp2_clean)) - 1 / 3) < 0.01)
stopifnot(all(tapply(br(exp1_clean)$Practice, br(exp1_clean)$Subject, sum) == 9))
stopifnot(all(tapply(br(exp2_clean)$Practice, br(exp2_clean)$Subject, sum) == 9))
stopifnot(all(tapply(exp1_clean$Practice[exp1_clean$Phase == "Association"],
                     exp1_clean$Subject[exp1_clean$Phase == "Association"], sum) == 6))
stopifnot(all(tapply(exp2_clean$Practice[exp2_clean$Phase == "Association"],
                     exp2_clean$Subject[exp2_clean$Phase == "Association"], sum) == 6))
# 8 blocks x 81、9 条件 x 72
chk_struct <- function(d) {
  b <- br(d)[br(d)$Practice == 0, ]
  blk <- table(b$Subject, b$Block)
  stopifnot(all(colnames(blk) == as.character(1:8)), all(blk == 81))
  cond <- table(b$Subject, b$Label, b$Shape_Origin_Identity)
  stopifnot(all(cond == 72))
  TRUE
}
chk_struct(exp1_clean); chk_struct(exp2_clean)
# association Label == Identity 英文名
stopifnot(all(tolower(exp1_clean$Label[exp1_clean$Phase == "Association"]) ==
                tolower(exp1_clean$Identity[exp1_clean$Phase == "Association"])))
stopifnot(all(tolower(exp2_clean$Label[exp2_clean$Phase == "Association"]) ==
                tolower(exp2_clean$Identity[exp2_clean$Phase == "Association"])))
stopifnot(all(exp1_clean$Matching[exp1_clean$Phase == "Association"] == "Matching"))
stopifnot(all(exp2_clean$Matching[exp2_clean$Phase == "Association"] == "Matching"))
cat("Clean rows: Exp1 =", nrow(exp1_clean), "| Exp2 =", nrow(exp2_clean), "\n")

# ---- subj_info（txt header；NULL 视为缺失，多文件取首个非空） ----
mk_subj_info <- function(assoc_lst, sw_lsts, exp_id) {
  all <- list()
  for (s in names(assoc_lst)) {
    for (t in c(assoc_lst[[s]]$practice, assoc_lst[[s]]$formal)) {
      all[[length(all) + 1]] <- list(subj = s, Age = t$Age, Sex = t$Sex, Handedness = t$Handedness)
    }
  }
  for (lst in sw_lsts) for (s in names(lst)) for (t in lst[[s]]) {
    all[[length(all) + 1]] <- list(subj = s, Age = t$Age, Sex = t$Sex, Handedness = t$Handedness)
  }
  subjs <- unique(vapply(all, function(x) x$subj, character(1)))
  subjs <- subjs[order(as.numeric(subjs))]
  pick <- function(field) {
    vapply(subjs, function(s) {
      vals <- unique(vapply(all, function(x) if (x$subj == s) x[[field]] else NA_character_, character(1)))
      vals <- vals[!is.na(vals)]
      if (length(vals) == 0) "/" else vals[1]
    }, character(1))
  }
  data.frame(
    Subject_ID = subjs,
    Exp_id = exp_id,
    Age = pick("Age"),
    Gender = tolower(pick("Sex")),
    Handedness = tolower(pick("Handedness")),
    Ethnicity = "/", Employment_Status = "/", Country = "/",
    First_Language = "/", Education = "/",
    stringsAsFactors = FALSE, row.names = NULL
  )
}
exp1_si <- mk_subj_info(exp1_assoc, list(exp1_sw1, exp1_sw2), "Wang_2016_JEPHPP_Exp1")
exp2_si <- mk_subj_info(exp2_assoc, list(exp2_sw), "Wang_2016_JEPHPP_Exp2")
stopifnot(nrow(exp1_si) == 21, nrow(exp2_si) == 25)
stopifnot(all(exp1_si$Handedness != "null"), all(exp2_si$Handedness != "null"))

# ---- 写出（多实验布局：每实验一个 ExpN/ 子文件夹，SKILL.md 规范） ----
dir.create(file.path(.sdir, "Exp1"), showWarnings = FALSE)
dir.create(file.path(.sdir, "Exp2"), showWarnings = FALSE)
write_clean_csv(exp1_raw, file.path(.sdir, "Exp1", "Wang_2016_JEPHPP_Exp1_raw.csv"))
write_clean_csv(exp2_raw, file.path(.sdir, "Exp2", "Wang_2016_JEPHPP_Exp2_raw.csv"))
write_clean_csv(exp1_clean, file.path(.sdir, "Exp1", "Wang_2016_JEPHPP_Exp1_Clean.csv"))
write_clean_csv(exp2_clean, file.path(.sdir, "Exp2", "Wang_2016_JEPHPP_Exp2_Clean.csv"))
write_clean_csv(exp1_si, file.path(.sdir, "Exp1", "Wang_2016_JEPHPP_Exp1_subj_info.csv"))
write_clean_csv(exp2_si, file.path(.sdir, "Exp2", "Wang_2016_JEPHPP_Exp2_subj_info.csv"))

cat("DONE. Exp1 rows:", nrow(exp1_clean), "| Exp2 rows:", nrow(exp2_clean), "\n")
cat("Exp1 M/F:", table(exp1_si$Gender), "\n")
cat("Exp2 M/F:", table(exp2_si$Gender), "\n")
