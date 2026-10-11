#!/usr/bin/env Rscript
# =============================================================================
# Hu_YQ_2026_ChinaSciData_clean.R  (rewritten 2026-10-08)
#
# Reproduces Hu_YQ_2026_ChinaSciData_Exp1_Clean.csv (21 columns, template v2).
#
# Data sources:
#   Exp1/Raw/Data_for_Exp1.csv + Data_for_Exp2.csv  (GB18030 E-Prime merged exports)
#   Raw E-Prime logs (UTF-16 .txt): Task1_rawdata/ + Task2_rawdata/
#     (Task1 = Pro_3AssoMatch_*.txt, matching task;
#      Task2 = AssoMatc_depre_hcp_*.txt, self-matching task)
#
# Why the raw E-Prime logs are needed: the GB18030 CSVs dropped the per-trial
# block/trial counters (TrialList*.Sample) and the Chinese shape identity
# (Shape) / stimulus filename (Stimulus, Target). These are recovered from the
# logs and aligned to the CSV rows by a greedy tuple match.
#
# Pipeline (matches the current Clean exactly):
#   1. Read the two GB18030 CSVs (pure character, empty preserved).
#   2. Parse raw E-Prime logs -> per-trial block / trial / shape / shapeE / stimulus.
#   3. Align each CSV row to its E-Prime trial frame (greedy tuple match).
#   4. Build the merged 21-column table; write *_Exp1_Clean.csv (UTF-8 + BOM).
#   5. Write Codebook_*_Exp1_Clean.xlsx (single Sheet1, 4 columns).
# =============================================================================
suppressMessages({
  library(data.table)
  library(readr)
  library(openxlsx)
})

# ---- paths (self-contained; raw E-Prime path configurable) -----------------
args <- commandArgs(trailingOnly = FALSE)
fl <- sub("^--file=", "", args[grep("^--file=", args)])
if (!length(fl)) fl <- "Hu_YQ_2026_ChinaSciData_clean.R"
study_dir    <- normalizePath(dirname(fl))
raw_csv_dir  <- file.path(study_dir, "Exp1", "Raw")
out_dir      <- file.path(study_dir, "Exp1")

# Raw E-Prime logs live OUTSIDE the study folder (temporary workspace). Point
# these at wherever Task1_rawdata/ and Task2_rawdata/ actually are.
eprime1_dir <- "/Users/ack/Desktop/tmp/tpm-Training_effect_of_SPE_from_2_experiments/Data_sent_to_Jie/Task1_rawdata"
eprime2_dir <- "/Users/ack/Desktop/tmp/tpm-Training_effect_of_SPE_from_2_experiments/Data_sent_to_Jie/Task2_rawdata"

# =============================================================================
# Helpers
# =============================================================================
`%||%` <- function(a, b) if (is.null(a) || length(a) == 0L || is.na(a)) b else a

# Read a GB18030 CSV as a pure-character data.table ("" preserved, no NA coercion)
read_gb18030 <- function(path) {
  as.data.table(readr::read_csv(
    path, col_types = readr::cols(.default = readr::col_character()),
    na = character(0), locale = readr::locale(encoding = "GB18030")))
}

# Parse an E-Prime UTF-16 .txt export into header + logframe list
parse_eprime <- function(path) {
  lines <- readr::read_lines(path, locale = readr::locale(encoding = "UTF-16"))
  hdr <- list(); frames <- list(); cur <- NULL; in_hdr <- FALSE
  for (ln in lines) {
    if (grepl("\\*\\*\\* Header Start \\*\\*\\*", ln)) { in_hdr <- TRUE; next }
    if (grepl("\\*\\*\\* Header End \\*\\*\\*", ln))   { in_hdr <- FALSE; next }
    if (in_hdr && grepl(":", ln)) {
      kv <- strsplit(ln, ":", fixed = TRUE)[[1L]]
      hdr[[trimws(kv[1L])]] <- trimws(paste(kv[-1L], collapse = ":")); next
    }
    if (grepl("\\*\\*\\* LogFrame Start \\*\\*\\*", ln)) { cur <- list(); next }
    if (grepl("\\*\\*\\* LogFrame End \\*\\*\\*", ln)) {
      if (!is.null(cur)) { frames[[length(frames) + 1L]] <- cur }; cur <- NULL; next
    }
    if (!is.null(cur) && grepl(":", ln)) {
      kv <- strsplit(ln, ":", fixed = TRUE)[[1L]]
      cur[[trimws(kv[1L])]] <- trimws(paste(kv[-1L], collapse = ":"))
    }
  }
  list(hdr = hdr, frames = frames)
}

# Greedy sequential tuple alignment: csv_key and ep_key are lists of character
# vectors (tuples), both in chronological order. Returns an integer index into
# ep_key for each csv row (0 = no match, e.g. an all-blank placeholder row).
greedy_align <- function(csv_key, ep_key) {
  n_csv <- length(csv_key); n_ep <- length(ep_key)
  res <- integer(n_csv); ep_ptr <- 1L
  for (i in seq_len(n_csv)) {
    tup <- csv_key[[i]]
    if (all(tup == "")) { res[i] <- 0L; next }
    while (ep_ptr <= n_ep && !identical(tup, ep_key[[ep_ptr]])) ep_ptr <- ep_ptr + 1L
    if (ep_ptr <= n_ep) { res[i] <- ep_ptr; ep_ptr <- ep_ptr + 1L } else res[i] <- 0L
  }
  res
}

# =============================================================================
# Read the two GB18030 CSVs
# =============================================================================
d1 <- read_gb18030(file.path(raw_csv_dir, "Data_for_Exp1.csv"))
d2 <- read_gb18030(file.path(raw_csv_dir, "Data_for_Exp2.csv"))

# --- Exp1 raw: merge Data_for_Exp1 + Data_for_Exp2 (union of columns + Task) ---
raw1 <- rbindlist(list(
  copy(d1)[, Task := "matching"],
  copy(d2)[, Task := "self-matching"]
), use.names = TRUE, fill = TRUE)
for (j in names(raw1)) set(raw1, which(is.na(raw1[[j]])), j, "")
RAW1_COLS <- c("Subject", "Task", setdiff(union(names(d1), names(d2)), "Subject"))
raw1 <- raw1[, ..RAW1_COLS]
fwrite(raw1, file.path(study_dir, "Exp1", "Hu_YQ_2026_ChinaSciData_Exp1_raw.csv"), quote = "auto", bom = TRUE, na = "")
message("Wrote Exp1 raw (", nrow(raw1), " rows)")

# =============================================================================
# Parse raw E-Prime logs
# =============================================================================
T1_PROCS <- c("PracTrialProcS", "TrialProcS", "PracTrialProcE", "TrialProcE",
              "PracTrialProc", "TrialProc")
T2_PROCS <- c("TrialProc", "PracTrialProc")

# --- Exp1 (Task1): each trial frame -> Subject/Session/Procedure/sample/shape/shapeE/stimulus/match/label/ca
ep1_list <- list()
for (p in list.files(eprime1_dir, pattern = "\\.txt$", full.names = TRUE)) {
  parsed <- parse_eprime(p)
  subj <- parsed$hdr[["Subject"]]; sess <- parsed$hdr[["Session"]]
  for (fr in parsed$frames) {
    proc <- fr[["Procedure"]]
    if (is.null(proc) || !proc %in% T1_PROCS) next
    ep1_list[[length(ep1_list) + 1L]] <- list(
      Subject = subj, Session = sess, Procedure = proc,
      Sample = fr[["TrialListS.Sample"]] %||% fr[["TrialListE.Sample"]] %||%
               fr[["TrialList.Sample"]] %||% fr[["PracTrialListS.Sample"]] %||%
               fr[["PracTrialListE.Sample"]] %||% fr[["PracTrialList.Sample"]] %||% "",
      Shape  = fr[["Shape"]] %||% "", ShapeE = fr[["ShapeE"]] %||% "",
      Stimulus = fr[["Stimulus"]] %||% "",
      Match  = fr[["Match"]] %||% "", Label = fr[["Label"]] %||% "",
      CA     = fr[["CorrectAnswer"]] %||% "")
  }
}

# --- Exp2 (Task2): track block via BlockProc (block-END markers); trial frames only
ep2_list <- list()
for (p in list.files(eprime2_dir, pattern = "\\.txt$", full.names = TRUE)) {
  parsed <- parse_eprime(p)
  subj <- parsed$hdr[["Subject"]]; sess <- parsed$hdr[["Session"]]
  cur_blk <- 1L
  for (fr in parsed$frames) {
    proc <- fr[["Procedure"]]
    if (is.null(proc)) next
    if (proc == "BlockProc") { cur_blk <- cur_blk + 1L; next }   # block-END marker
    if (!proc %in% T2_PROCS) next
    ep2_list[[length(ep2_list) + 1L]] <- list(
      Subject = subj, Session = sess, Procedure = proc,
      Block = if (proc == "PracTrialProc") "" else as.character(cur_blk),
      Sample = fr[["TrialList.Sample"]] %||% "",
      Shape  = fr[["Shape"]] %||% "", Words = fr[["Words"]] %||% "",
      Emotion = fr[["Emotion"]] %||% "", CA = fr[["CorrectAnswer"]] %||% "",
      Target = fr[["Target"]] %||% "", RESP = fr[["Target.RESP"]] %||% "",
      RT = fr[["Target.RT"]] %||% "")
  }
}

# =============================================================================
# Identity / valence / emotion mapping tables
# =============================================================================
# Exp1: ShapeE -> (Origin, English, Standardized)
exp1_identity <- data.table(
  ShapeE = c("self", "other", "happy", "neutral", "1", "16"),
  Origin = c("你", "生人", "高兴", "中性", "￥1", "￥16"),
  English = c("self", "other", "happy", "neutral", "1", "16"),
  Std = c("Self", "Stranger", "happy", "neutral", "￥1", "￥16"))
exp1_valence <- c(self = "positive", other = "neutral", happy = "positive",
                  neutral = "neutral", "1" = "neutral", "16" = "positive")

# Exp2: Shape field (Self/Friend/Stranger) -> (Origin, English, Standardized)
exp2_identity <- data.table(
  Shape = c("Self", "Friend", "Stranger"),
  Origin = c("自己", "朋友", "生人"),
  English = c("self", "friend", "stranger"),
  Std = c("Self", "Close", "Stranger"))

# =============================================================================
# Exp1 (matching): align + build
# =============================================================================
# CSV row key + payload
d1_key <- lapply(seq_len(nrow(d1)), function(i)
  c(d1$Match[i], d1$ShapeE[i], d1$Label[i], d1$CorrectAnswer[i]))
# E-Prime frame key
ep1_key <- lapply(ep1_list, function(fr) c(fr$Match, fr$ShapeE, fr$Label, fr$CA))

# group alignment by (Subject, Session)
d1[, rn := .I]
d1_key_split <- split(seq_len(nrow(d1)), list(d1$Subject, d1$Session), drop = TRUE)
ep1_split <- split(seq_along(ep1_list),
                   list(sapply(ep1_list, `[[`, "Subject"), sapply(ep1_list, `[[`, "Session")),
                   drop = TRUE)

align1 <- integer(nrow(d1))
for (grp in names(d1_key_split)) {
  di <- d1_key_split[[grp]]; ei <- ep1_split[[grp]]
  if (is.null(ei)) next
  a <- greedy_align(d1_key[di], ep1_key[ei])
  align1[di] <- ifelse(a > 0L, ei[a], 0L)
}

# helper: pick the single non-empty value among several columns
pick <- function(...) {
  vals <- c(...); vals <- vals[!is.na(vals) & vals != ""]
  if (length(vals)) vals[1L] else ""
}

build_exp1 <- function(dt, align) {
  out <- dt[, .(Subject, Session)]
  out[, Task := "matching"]
  out[, Phase := fifelse(align == 0L, "",
                  fifelse(dt$SubTrial == "1", "practice", "main"))]
  # Block/Trial from aligned E-Prime sample
  blk_tri <- lapply(seq_len(nrow(dt)), function(i) {
    if (align[i] == 0L) return(c("", ""))                 # blank placeholder row
    if (dt$SubTrial[i] == "1") return(c("NA", "NA"))      # practice
    fr <- ep1_list[[align[i]]]
    smp <- suppressWarnings(as.integer(fr$Sample))
    if (is.na(smp)) return(c("NA", "NA"))
    c(as.character((smp - 1L) %/% 96L + 1L), as.character((smp - 1L) %% 96L + 1L))
  })
  out[, Block := vapply(blk_tri, `[`, character(1), 1L)]
  out[, Trial := vapply(blk_tri, `[`, character(1), 2L)]
  # renumber Block to global 1-6 (self=0, emotion=1, reward=2)
  st_idx <- fifelse(dt$ShapeE %in% c("self", "other"), 0L,
             fifelse(dt$ShapeE %in% c("happy", "neutral"), 1L, 2L))
  out[, Block := fifelse(Block %in% c("", "NA"), Block,
                         as.character(st_idx * 2L + suppressWarnings(as.integer(Block))))]
  out[, Matching := fifelse(dt$Match == "Matched", "Matching",
                     fifelse(dt$Match == "Mismatched", "Nonmatching", ""))]
  # Shape stimulus filename + Shape identity (from aligned E-Prime)
  out[, Shape := vapply(seq_len(nrow(dt)), function(i)
    if (align[i] == 0L) "" else ep1_list[[align[i]]]$Stimulus, character(1))]
  out[, Shape_Origin_Identity := vapply(seq_len(nrow(dt)), function(i)
    if (align[i] == 0L) "" else ep1_list[[align[i]]]$Shape, character(1))]
  id1 <- exp1_identity[match(dt$ShapeE, exp1_identity$ShapeE)]
  out[, Shape_English_Identity := fcoalesce(id1$English, "")]
  out[, Shape_Standardized_Identity := fcoalesce(id1$Std, "")]
  # Label + Label identity
  out[, Label := dt$Label]
  out[, Label_Origin_Identity := dt$Label]
  out[, Label_English_Identity := fcoalesce(id1$English, "")]
  out[, Label_Standardized_Identity := fcoalesce(id1$Std, "")]
  # extraIV
  out[, extraIV1 := exp1_valence[dt$ShapeE]]
  out[, extraIV1 := fifelse(is.na(extraIV1), "", extraIV1)]
  out[, extraIV2 := "NA"]
  # responses
  out[, CorrResponse := dt$CorrectAnswer]
  resp <- pick3(dt$Target.RESP, dt$TargetE.RESP, dt$TargetS.RESP)
  rt   <- pick3(dt$Target.RT,   dt$TargetE.RT,   dt$TargetS.RT)
  acc  <- pick3(dt$Target.ACC,  dt$TargetE.ACC,  dt$TargetS.ACC)
  noresp <- resp == "" & dt$ShapeE != ""      # 无反应（非全空占位行）
  out[, Response := fifelse(noresp, "NA", resp)]
  out[, RT_ms    := fifelse(noresp, "NA", rt)]
  out[, ACC      := fifelse(noresp, "NA", acc)]
  out
}

pick3 <- function(a, b, c) {
  vapply(seq_along(a), function(i) pick(a[i], b[i], c[i]), character(1))
}

clean1 <- build_exp1(d1, align1)

# =============================================================================
# Exp2 (self-matching): align + build
# =============================================================================
d2_key <- lapply(seq_len(nrow(d2)), function(i)
  c(d2$Shape[i], d2$Words[i], d2$Emotion[i], d2$Target.CRESP[i], d2$Target.RESP[i], d2$Target.RT[i]))
ep2_key <- lapply(ep2_list, function(fr) c(fr$Shape, fr$Words, fr$Emotion, fr$CA, fr$RESP, fr$RT))

d2[, rn := .I]
d2_key_split <- split(seq_len(nrow(d2)), list(d2$Subject, d2$Session), drop = TRUE)
ep2_split <- split(seq_along(ep2_list),
                   list(sapply(ep2_list, `[[`, "Subject"), sapply(ep2_list, `[[`, "Session")),
                   drop = TRUE)

align2 <- integer(nrow(d2))
for (grp in names(d2_key_split)) {
  di <- d2_key_split[[grp]]; ei <- ep2_split[[grp]]
  if (is.null(ei)) next
  a <- greedy_align(d2_key[di], ep2_key[ei])
  align2[di] <- ifelse(a > 0L, ei[a], 0L)
}

build_exp2 <- function(dt, align) {
  out <- dt[, .(Subject, Session)]
  out[, Task := "self-matching"]
  # Phase / Block / Trial from aligned frame
  phase_blk <- vapply(seq_len(nrow(dt)), function(i) {
    if (align[i] == 0L) return("practice")
    fr <- ep2_list[[align[i]]]
    if (fr$Procedure == "PracTrialProc") "practice" else "main"
  }, character(1))
  out[, Phase := phase_blk]
  out[, Block := vapply(seq_len(nrow(dt)), function(i)
    if (align[i] == 0L || phase_blk[i] == "practice") "NA" else ep2_list[[align[i]]]$Block, character(1))]
  out[, Trial := vapply(seq_len(nrow(dt)), function(i)
    if (align[i] == 0L || phase_blk[i] == "practice") "NA" else ep2_list[[align[i]]]$Sample, character(1))]
  # Matching from Shape vs Label identity
  id2 <- exp2_identity[match(dt$Shape, exp2_identity$Shape)]
  idl <- exp2_identity[match(dt$Words, exp2_identity$Origin)]
  out[, Matching := fifelse(is.na(id2$Std) | is.na(idl$Std), "",
                     fifelse(id2$Std == idl$Std, "Matching", "Nonmatching"))]
  # Shape stimulus filename + identity
  out[, Shape := vapply(seq_len(nrow(dt)), function(i)
    if (align[i] == 0L) "" else ep2_list[[align[i]]]$Target, character(1))]
  out[, Shape_Origin_Identity := id2$Origin]
  out[, Shape_English_Identity := id2$English]
  out[, Shape_Standardized_Identity := id2$Std]
  out[, Label := dt$Words]
  out[, Label_Origin_Identity := idl$Origin]
  out[, Label_English_Identity := idl$English]
  out[, Label_Standardized_Identity := idl$Std]
  out[, extraIV1 := "NA"]
  out[, extraIV2 := fifelse(dt$Emotion == "neutal", "neutral", dt$Emotion)]
  out[, CorrResponse := dt$Target.CRESP]
  out[, Response := fifelse(dt$Target.RESP == "", "NA", dt$Target.RESP)]
  out[, RT_ms    := fifelse(dt$Target.RESP == "", "NA", dt$Target.RT)]
  out[, ACC      := fifelse(dt$Target.RESP == "", "NA", dt$Target.ACC)]
  out
}

clean2 <- build_exp2(d2, align2)

# =============================================================================
# Merge, order, write
# =============================================================================
FINAL_COLS <- c("Subject", "Session", "Task", "Phase", "Block", "Trial", "Matching",
  "Shape", "Shape_Origin_Identity", "Shape_English_Identity", "Shape_Standardized_Identity",
  "Label", "Label_Origin_Identity", "Label_English_Identity", "Label_Standardized_Identity",
  "extraIV1", "extraIV2", "CorrResponse", "Response", "RT_ms", "ACC")

clean <- rbindlist(list(clean1, clean2), use.names = TRUE, fill = TRUE)
setcolorder(clean, FINAL_COLS)
clean <- clean[order(as.integer(Subject), fifelse(Task == "self-matching", 1L, 0L),
          as.integer(Session), fifelse(Phase == "main", 1L, 0L),
          suppressWarnings(as.integer(Block)), suppressWarnings(as.integer(Trial)), na.last = TRUE)]
# ensure the 6015-6 all-blank placeholder row stays fully blank
blank_rows <- clean[, Reduce(`&`, lapply(.SD, function(v) v == ""))]
clean[blank_rows, (FINAL_COLS) := lapply(.SD, function(v) fifelse(v == "", "", v)), .SDcols = FINAL_COLS]

out_csv <- file.path(out_dir, "Hu_YQ_2026_ChinaSciData_Exp1_Clean.csv")
fwrite(clean, out_csv, quote = "auto", bom = TRUE, na = "")
message("Wrote ", out_csv, " (", nrow(clean), " rows, ", ncol(clean), " cols)")

# =============================================================================
# Codebook
# =============================================================================
codebook_rows <- list(
  c("Subject", "Participant ID", "6001-6036", "Categorical"),
  c("Session", "Session number (training time point / lab visit)", "Number (1-6; 7 = subject 6031 only)", "Numerical"),
  c("Task", "Task type: matching (self/emotion/reward associations) vs self-matching (self/friend/stranger association)", "matching; self-matching", "Categorical"),
  c("Phase", "Trial phase", "practice; main", "Categorical"),
  c("Block", "Block number (global 1-6 across sub-tasks)", "Number (1-6); NA = practice", "Numerical"),
  c("Trial", "Trial order within block", "Number (1-96 matching; 1-240 self-matching); NA = practice", "Numerical"),
  c("Matching", "Whether the presented shape-label pair matches the learned association (Matching) or not (Nonmatching)", "Matching; Nonmatching", "Categorical"),
  c("Shape", "Shape stimulus image filename", "C.bmp; D.bmp; P.bmp; S.bmp; T.bmp; Tra.bmp; c.bmp; c_eh.bmp; c_en.bmp; c_es.bmp; hc.bmp; hc_eh.bmp; hc_en.bmp; hc_es.bmp; vc.bmp; vc_eh.bmp; vc_en.bmp; vc_es.bmp", "Categorical"),
  c("Shape_Origin_Identity", "Original-language identity of the shape stimulus", "你; 生人; 高兴; 中性; ￥1; ￥16; 自己; 朋友", "Categorical"),
  c("Shape_English_Identity", "English identity of the shape stimulus", "self; other; happy; neutral; 1; 16; friend; stranger", "Categorical"),
  c("Shape_Standardized_Identity", "Standardized identity (6-category vocabulary: Self/Close/Stranger/NonPerson/Acquaintance/Celebrity; non-identity stimuli kept as-is)", "Self; Stranger; happy; neutral; ￥1; ￥16; Close", "Categorical"),
  c("Label", "Label word presented (original language)", "你; 生人; 高兴; 中性; ￥1; ￥16; 自己; 朋友", "Categorical"),
  c("Label_Origin_Identity", "Original-language identity of the label", "你; 生人; 高兴; 中性; ￥1; ￥16; 自己; 朋友", "Categorical"),
  c("Label_English_Identity", "English identity of the label", "self; other; happy; neutral; 1; 16; friend; stranger", "Categorical"),
  c("Label_Standardized_Identity", "Standardized identity (6-category vocabulary)", "Self; Stranger; happy; neutral; ￥1; ￥16; Close", "Categorical"),
  c("extraIV1", "Valence: positive (self/happy/high-reward) vs neutral (other/neutral/low-reward)", "positive; neutral; NA (not applicable: self-matching task)", "Categorical"),
  c("extraIV2", "Emotion embedded in the shape", "control; happy; neutral; sad; NA (not applicable: matching task)", "Categorical"),
  c("CorrResponse", "Correct response key", "1; 2 (matching); m; n (self-matching)", "Categorical"),
  c("Response", "Actual key response; NA = no response", "1; 2 (matching); m; n (self-matching); NA (no response)", "Categorical"),
  c("RT_ms", "Reaction time in milliseconds; NA = no response", "ms; NA = no response", "Numerical"),
  c("ACC", "Accuracy", "1 (correct); 0 (error); NA (no response)", "Categorical")
)
cb <- rbindlist(lapply(codebook_rows, function(r) as.list(r)))
setnames(cb, c("Variable_name", "Variable_description", "Variable_value", "Variable_category"))
wb <- createWorkbook(); addWorksheet(wb, "Sheet1")
writeData(wb, "Sheet1", cb)
saveWorkbook(wb, file.path(out_dir, "Codebook_Hu_YQ_2026_ChinaSciData_Exp1_Clean.xlsx"), overwrite = TRUE)
message("Wrote Codebook (", nrow(cb), " vars)")
# =============================================================================
# Exp2 (Zhou 2023, PsychoPy) — build raw + Clean from Exp2/Raw/sub-*/
# =============================================================================
PHASES2 <- c("baseline","training1","training2","training3","training4","training5","training6","training7","formal")
zhou_group <- c("1" = "matching-first", "2" = "nonmatching-first")

read_xlsx_raw <- function(path) {
  df <- as.data.table(readxl::read_excel(path, col_types = "text"))
  nm <- names(df)
  if (nm[1L] %in% c("", "..1", "...1", "X1")) df[, (1L) := NULL]
  for (j in names(df)) set(df, which(is.na(df[[j]])), j, "")
  df
}

raw2_list <- list()
for (subj_dir in list.dirs(file.path(study_dir, "Exp2", "Raw"), recursive = FALSE, full.names = TRUE)) {
  if (!grepl("^sub-", basename(subj_dir))) next
  id <- sub("^sub-", "", basename(subj_dir))
  for (ph in PHASES2) {
    phdir <- file.path(subj_dir, ph)
    if (!dir.exists(phdir)) next
    for (fname in c(paste0(id, ".xlsx"), paste0(id, "练习.xlsx"))) {
      p <- file.path(phdir, fname)
      if (!file.exists(p)) next
      df <- read_xlsx_raw(p)
      df[, ID := id]                                    # folder name as ID (fix mislabeling)
      df[, Session := ph]
      df[, Phase := fifelse(grepl("练习", fname), "practice", "main")]
      raw2_list[[length(raw2_list) + 1L]] <- df
    }
  }
}
raw2 <- rbindlist(raw2_list, use.names = TRUE, fill = TRUE)
for (j in names(raw2)) set(raw2, which(is.na(raw2[[j]])), j, "")   # NA -> ""

RAW2_COLS <- c("Session","Phase","ID","Gender","Date","Group",
  "point_start","point_end","point_duration","stim_start","res_time","stim_end",
  "blank_start","blank_end","feedback_start","feedback_end","relax_start",
  "stim_shape","stim_text","reaction","is_match","expect_match","expect_res")
for (c in setdiff(RAW2_COLS, names(raw2))) raw2[, (c) := ""]
raw2 <- raw2[, ..RAW2_COLS]
raw2 <- raw2[order(as.integer(ID), match(Session, PHASES2), Phase == "main")]
fwrite(raw2, file.path(study_dir, "Exp2", "Hu_YQ_2026_ChinaSciData_Exp2_raw.csv"), quote = "auto", bom = TRUE, na = "")
message("Wrote Exp2 raw (", nrow(raw2), " rows)")

# Clean
parity <- as.integer(raw2$ID) %% 2L
shape_origin <- fifelse(raw2$stim_shape == "circle",
                 fifelse(parity == 0L, "self", "other"),
                 fifelse(parity == 0L, "other", "self"))
corr <- fifelse(raw2$expect_match != "", raw2$expect_match, raw2$expect_res)
rt_ms <- fifelse(raw2$reaction == "[]", "NA",
          as.character(round((as.numeric(raw2$res_time) - as.numeric(raw2$stim_start)) * 1000, 1)))

clean2 <- data.table(
  Subject = raw2$ID,
  Group = zhou_group[substr(raw2$ID, 2L, 2L)],
  Session = raw2$Session,
  Task = "self-matching",
  Phase = raw2$Phase,
  Matching = fifelse(raw2$is_match == "match", "Matching",
              fifelse(raw2$is_match == "mismatch", "Nonmatching", "filler")),
  Shape = raw2$stim_shape,
  Shape_Origin_Identity = shape_origin,
  Shape_English_Identity = fifelse(shape_origin == "self", "Self", "Other"),
  Shape_Standardized_Identity = fifelse(shape_origin == "self", "Self", "Stranger"),
  Label = raw2$stim_text,
  Label_Origin_Identity = raw2$stim_text,
  Label_English_Identity = fifelse(raw2$stim_text == "自我", "Self",
                            fifelse(raw2$stim_text == "他人", "Other", "Filler")),
  Label_Standardized_Identity = fifelse(raw2$stim_text == "自我", "Self",
                                 fifelse(raw2$stim_text == "他人", "Stranger", "Filler")),
  CorrResponse = corr,
  Response = fifelse(raw2$reaction == "[]", "NA", raw2$reaction),
  RT_ms = rt_ms,
  ACC = fifelse(raw2$reaction == "[]", "NA", fifelse(raw2$reaction == corr, "1", "0"))
)
clean2 <- clean2[order(as.integer(Subject), match(Session, PHASES2), Phase == "main")]
fwrite(clean2, file.path(study_dir, "Exp2", "Hu_YQ_2026_ChinaSciData_Exp2_Clean.csv"), quote = "auto", bom = TRUE, na = "")
message("Wrote Exp2 Clean (", nrow(clean2), " rows)")

# Exp2 Codebook
cb2_rows <- list(
  c("Subject", "Participant ID", "11001-11011; 12001-12010; 21001-21003; 22001-22002", "Categorical"),
  c("Group", "Between-subjects training group (2nd ID digit)", "matching-first; nonmatching-first", "Categorical"),
  c("Session", "Session / training time point", "baseline; training1; training2; training3; training4; training5; training6; training7; formal (= post-test)", "Categorical"),
  c("Task", "Task type", "self-matching", "Categorical"),
  c("Phase", "Trial phase", "practice; main", "Categorical"),
  c("Matching", "Trial type: Matching (shape-label consistent) / Nonmatching (inconsistent) / filler (no-identity)", "Matching; Nonmatching; filler (no-identity trial)", "Categorical"),
  c("Shape", "Shape stimulus (shape-label correspondence counterbalanced by ID parity)", "circle; square", "Categorical"),
  c("Shape_Origin_Identity", "Original-language identity of the shape stimulus", "self; other", "Categorical"),
  c("Shape_English_Identity", "English identity of the shape stimulus", "Self; Other", "Categorical"),
  c("Shape_Standardized_Identity", "Standardized identity (6-category)", "Self; Stranger", "Categorical"),
  c("Label", "Label word presented", "自我 (self); 他人 (other); 白栽; 地入 (filler pseudo-words)", "Categorical"),
  c("Label_Origin_Identity", "Original-language identity of the label", "自我; 他人; 白栽; 地入", "Categorical"),
  c("Label_English_Identity", "English identity of the label", "Self; Other; Filler", "Categorical"),
  c("Label_Standardized_Identity", "Standardized identity (6-category)", "Self; Stranger; Filler", "Categorical"),
  c("CorrResponse", "Correct response key", "p; o", "Categorical"),
  c("Response", "Actual key response; NA = no response", "p; o; NA (no response)", "Categorical"),
  c("RT_ms", "Reaction time in milliseconds; NA = no response", "ms; NA = no response", "Numerical"),
  c("ACC", "Accuracy", "1 (correct); 0 (error); NA (no response)", "Categorical")
)
cb2 <- rbindlist(lapply(cb2_rows, function(r) as.list(r)))
setnames(cb2, c("Variable_name", "Variable_description", "Variable_value", "Variable_category"))
wb2 <- createWorkbook(); addWorksheet(wb2, "Sheet1")
writeData(wb2, "Sheet1", cb2)
saveWorkbook(wb2, file.path(study_dir, "Exp2", "Codebook_Hu_YQ_2026_ChinaSciData_Exp2_Clean.xlsx"), overwrite = TRUE)
message("Wrote Exp2 Codebook (", nrow(cb2), " vars)")

# =============================================================================
# subj_info (participant level; Age 手工维护，脚本不生成)
# =============================================================================
info_xlsx <- "/Users/ack/Desktop/tmp/tpm-Training_effect_of_SPE_from_2_experiments/Data_sent_to_Jie/Info_participants.xlsx"

# --- Exp1 subj_info (Sex/Handedness 来自 E-Prime 表头; BDI/BAI 来自 Info_participants) ---
ep1_hdr <- rbindlist(lapply(list.files(eprime1_dir, pattern = "\\.txt$", full.names = TRUE), function(p) {
  hdr <- parse_eprime(p)$hdr
  data.table(Subject = hdr[["Subject"]] %||% "", Sex = hdr[["Sex"]] %||% "",
             Handedness = hdr[["Handedness"]] %||% "")
}))
ep1_hdr <- unique(ep1_hdr[Subject != ""], by = "Subject")

info1 <- as.data.table(readxl::read_excel(info_xlsx))
info1 <- info1[!is.na(ID)]
info1[, ID := as.character(ID)]
info1[, BDI_Score := fifelse(is.na(`BDI得分`), "NA", as.character(`BDI得分`))]
info1[, BAI_Score := fifelse(is.na(`BAI得分`), "NA", as.character(`BAI得分`))]
info1 <- info1[, .(ID, BDI_Score, BAI_Score)]

si1 <- merge(ep1_hdr, info1, by.x = "Subject", by.y = "ID", all.x = TRUE)
si1 <- si1[order(as.integer(Subject))]
si1_out <- data.table(
  Subject_ID = si1$Subject,
  Exp_id = "Hu_YQ_2026_ChinaSciData_Exp1",
  Age = "NA",   # 手工维护（和原作者确认后填写）
  Gender = fifelse(si1$Sex == "male", "Male", "Female"),
  Handedness = "R",
  Ethnicity = "/", Employment_Status = "/", Country = "/", First_Language = "/", Education = "/",
  BDI_Score = si1$BDI_Score, BAI_Score = si1$BAI_Score)
fwrite(si1_out, file.path(study_dir, "Exp1", "Hu_YQ_2026_ChinaSciData_Exp1_subj_info.csv"),
       quote = "auto", bom = TRUE, na = "")
message("Wrote Exp1 subj_info (", nrow(si1_out), " rows)")

# --- Exp2 subj_info (Gender=NA 是编号首位 bug; Group 由编号第 2 位推导) ---
exp2_subjects <- sort(unique(raw2$ID))
si2_out <- data.table(
  Subject_ID = exp2_subjects,
  Exp_id = "Hu_YQ_2026_ChinaSciData_Exp2",
  Age = "/",
  Gender = "NA",
  Handedness = "/",
  Ethnicity = "/", Employment_Status = "/", Country = "/", First_Language = "/", Education = "/",
  Group = zhou_group[substr(exp2_subjects, 2L, 2L)])
fwrite(si2_out, file.path(study_dir, "Exp2", "Hu_YQ_2026_ChinaSciData_Exp2_subj_info.csv"),
       quote = "auto", bom = TRUE, na = "")
message("Wrote Exp2 subj_info (", nrow(si2_out), " rows)")

message("DONE")
