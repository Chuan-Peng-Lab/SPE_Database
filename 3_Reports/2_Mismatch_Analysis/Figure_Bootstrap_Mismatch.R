## ----setup, include=FALSE-----------------------------------------------------
knitr::opts_chunk$set(echo = TRUE, warning = FALSE, message = FALSE)
resolve_root <- function() {
  if (requireNamespace("knitr", quietly = TRUE)) {
    ci <- tryCatch(knitr::current_input(), error = function(e) NULL)
    if (!is.null(ci) && nzchar(ci)) {
      return(normalizePath(file.path(dirname(ci), ".."), mustWork = FALSE))
    }
  }
  args <- commandArgs(trailingOnly = FALSE)
  fa <- grep("^--file=", args, value = TRUE)
  if (length(fa)) {
    return(normalizePath(file.path(dirname(sub("^--file=", "", fa[1])), ".."), mustWork = FALSE))
  }
  normalizePath(".", mustWork = FALSE)
}
setwd(resolve_root())
cat("工作目录:", getwd(), "\n")


## ----packages-----------------------------------------------------------------
library(data.table)
library(dplyr)


## ----paths--------------------------------------------------------------------
raw_data_dir <- "../1_Data"
pic_dir      <- "Output/Pic"
data_out_dir <- "Output/data"
dir.create(pic_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(data_out_dir, showWarnings = FALSE, recursive = TRUE)

source("analysis_config.R")
cat(sprintf("\n>>> PRACTICE_POLICY = %s\n", PRACTICE_POLICY))


## ----constants----------------------------------------------------------------
N_BOOTSTRAP  <- 500
MIN_SAMPLE_N <- 10
STEP_N       <- 10
BOOT_SEED    <- 20260412

RT_MIN_MS    <- 0
RT_MAX_MS    <- 10000
VALID_ACC    <- c(0, 1)
SUFFIX       <- if (PRACTICE_POLICY == "keep") "_keepPractice" else ""

SHAPE_COLOR  <- "#2E86AB"
LABEL_COLOR  <- "#A23B72"
VLINE_SHAPE  <- "#1a5c7a"
VLINE_LABEL  <- "#7a2a52"
set.seed(BOOT_SEED)


## ----process-data-------------------------------------------------------------
# ===========================================================================
# 1. 读取（分片自动合并 + Hu_YQ 规则）→ 失配试次 → 个体级 Cohen's d
# ===========================================================================
NEEDED <- c("Subject", "RT_ms", "ACC", "Matching", "Phase", "Task",
            "Shape_Standardized_Identity", "Label_Standardized_Identity")

merged_df <- spe_read_datasets(raw_data_dir, NEEDED)
merged_df <- spe_apply_structure(merged_df)
merged_df[, RT_ms := suppressWarnings(as.numeric(RT_ms))]
merged_df[, ACC   := suppressWarnings(as.numeric(ACC))]
merged_df <- spe_add_subject_key(merged_df)

cat(sprintf("\n合并后: %d 行, %d 个数据集, %d 个唯一被试\n",
            nrow(merged_df), uniqueN(merged_df$Source), uniqueN(merged_df$SubjKey)))

if (!"Label_Standardized_Identity" %in% names(merged_df)) {
  merged_df[, Label_Standardized_Identity := Shape_Standardized_Identity]
}

mismatch_df <- merged_df[Matching == "Nonmatching"]
cat(sprintf("失配试次: %d 行, %d 个数据集, %d 位被试\n",
            nrow(mismatch_df), uniqueN(mismatch_df$Source), uniqueN(mismatch_df$SubjKey)))

cohens_d <- function(g1, g2) {
  n1 <- length(g1); n2 <- length(g2)
  if (n1 < 2 || n2 < 2) return(NA_real_)
  psd <- sqrt(((n1 - 1) * var(g1) + (n2 - 1) * var(g2)) / (n1 + n2 - 2))
  if (!is.finite(psd) || psd == 0) return(NA_real_)
  (mean(g1) - mean(g2)) / psd
}

calc_subject_cohens_d <- function(df, measure = "RT", min_trials = 2) {
  df <- data.table::as.data.table(df)
  results <- list()
  for (k in unique(df$SubjKey)) {
    s <- df[SubjKey == k]
    if (measure == "RT") {
      ok <- !is.na(s$RT_ms) & s$RT_ms > RT_MIN_MS & s$RT_ms <= RT_MAX_MS
      self_v <- s$RT_ms[s$Primary == "Self" & s$ACC == 1 & ok]
      str_v  <- s$RT_ms[s$Primary == "Stranger" & s$ACC == 1 & ok]
    } else {
      ok <- !is.na(s$ACC) & s$ACC %in% VALID_ACC
      self_v <- s$ACC[s$Primary == "Self" & ok]
      str_v  <- s$ACC[s$Primary == "Stranger" & ok]
    }
    self_v <- self_v[!is.na(self_v)]; str_v <- str_v[!is.na(str_v)]
    if (length(self_v) < min_trials || length(str_v) < min_trials) next
    d <- if (measure == "RT") cohens_d(str_v, self_v) else cohens_d(self_v, str_v)
    if (!is.na(d)) results[[length(results) + 1]] <-
      data.frame(SubjKey = k, Source = s$Source[1], Cohens_d = d, stringsAsFactors = FALSE)
  }
  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}


## ----filter-functions---------------------------------------------------------
# ---------------------------------------------------------------------------
# 保守法：仅当同一被试的规范身份 >= 3 类（含 Self 与 Stranger）才纳入。
# v3：只数 6 类规范身份；奖赏（£1/£3/£9）、情绪（Happy/Neutral/...）、
#     伪词（Filler）、ingroup 等非身份取值不计入（v1/v2 会把它们当身份计数）。
# ---------------------------------------------------------------------------
filter_valid_subjects <- function(df, id_col) {
  d <- data.table::as.data.table(df)
  d[, .(ok = spe_has_three_identities(get(id_col))), by = SubjKey][ok == TRUE, SubjKey]
}

process_conservative <- function(df, analysis_type = "Shape") {
  if (is.null(df) || nrow(df) == 0) return(data.frame())
  if (analysis_type == "Shape") {
    primary_col <- "Shape_Standardized_Identity"; secondary_col <- "Label_Standardized_Identity"
  } else {
    primary_col <- "Label_Standardized_Identity"; secondary_col <- "Shape_Standardized_Identity"
  }
  valid_subjects <- filter_valid_subjects(df, primary_col)
  if (length(valid_subjects) == 0) return(data.frame())
  df_f <- as.data.frame(df)[df$SubjKey %in% valid_subjects, , drop = FALSE]
  df_f$Primary   <- ifelse(df_f[[primary_col]]   %in% c("Self", "Stranger"), df_f[[primary_col]],   "Other")
  df_f$Secondary <- ifelse(df_f[[secondary_col]] %in% c("Self", "Stranger"), df_f[[secondary_col]], "Other")
  mask <- (df_f$Primary == "Self") |
          ((df_f$Primary == "Stranger") & (df_f$Secondary != "Self")) |
          (df_f$Primary == "Other")
  df_f[mask, , drop = FALSE]
}

process_liberal <- function(df, analysis_type = "Shape") {
  if (is.null(df) || nrow(df) == 0) return(data.frame())
  primary_col <- if (analysis_type == "Shape") "Shape_Standardized_Identity" else "Label_Standardized_Identity"
  df_f <- as.data.frame(df)
  df_f$Primary <- ifelse(df_f[[primary_col]] %in% c("Self", "Stranger"), df_f[[primary_col]], "Other")
  df_f[df_f$Primary %in% c("Self", "Stranger"), , drop = FALSE]
}

bootstrap_analysis <- function(v, n_bootstrap = 500, min_n = 10, step = 10, max_n = NULL) {
  total_n <- length(v)
  if (total_n < min_n) return(data.frame())
  if (is.null(max_n)) max_n <- total_n
  max_n <- min(max_n, total_n)
  ss <- seq(min_n, max_n, by = step)
  if (max_n %% step != 0 && !max_n %in% ss) ss <- c(ss, max_n)
  ss <- sort(unique(ss[ss <= total_n]))
  set.seed(BOOT_SEED)
  do.call(rbind, lapply(ss, function(n) {
    bm <- replicate(n_bootstrap, mean(sample(v, size = n, replace = TRUE)))
    data.frame(SampleSize = n, Mean_d = mean(bm),
               CI_lower = quantile(bm, 0.025, na.rm = TRUE),
               CI_upper = quantile(bm, 0.975, na.rm = TRUE), stringsAsFactors = FALSE)
  }))
}


## ----run-analysis-------------------------------------------------------------
run_full_analysis <- function(data, approach = "Conservative", n_boot = 500) {
  fn <- if (approach == "Conservative") process_conservative else process_liberal
  aligned <- list(); maxr <- list()
  for (measure in c("RT", "ACC")) {
    shape_data <- fn(data, "Shape"); label_data <- fn(data, "Label")
    sc <- calc_subject_cohens_d(shape_data, measure)
    lc <- calc_subject_cohens_d(label_data, measure)
    n_subj <- if (nrow(sc)) uniqueN(sc$SubjKey) else 0
    n_subj_l <- if (nrow(lc)) uniqueN(lc$SubjKey) else 0
    n_ds <- if (nrow(sc)) uniqueN(sc$Source) else 0
    n_ds_l <- if (nrow(lc)) uniqueN(lc$Source) else 0
    cat(sprintf("  %s %s - Shape d=%d (%d 被试/%d 数据集), Label d=%d (%d 被试/%d 数据集)\n",
                approach, measure, nrow(sc), n_subj, n_ds, nrow(lc), n_subj_l, n_ds_l))
    mx <- min(nrow(sc), nrow(lc), na.rm = TRUE)
    if (is.finite(mx) && mx >= MIN_SAMPLE_N) {
      sa <- bootstrap_analysis(sc$Cohens_d, n_boot, max_n = mx)
      la <- bootstrap_analysis(lc$Cohens_d, n_boot, max_n = mx)
      if (nrow(sa)) sa$Identity <- "Shape"
      if (nrow(la)) la$Identity <- "Label"
      aligned[[measure]] <- rbind(sa, la)
    } else aligned[[measure]] <- data.frame()
    sm <- bootstrap_analysis(sc$Cohens_d, n_boot); lm_ <- bootstrap_analysis(lc$Cohens_d, n_boot)
    if (nrow(sm)) sm$Identity <- "Shape"
    if (nrow(lm_)) lm_$Identity <- "Label"
    maxr[[measure]] <- rbind(sm, lm_)
  }
  list(aligned = aligned, max = maxr)
}

cat("\n--- Conservative ---\n"); cons <- run_full_analysis(mismatch_df, "Conservative", N_BOOTSTRAP)
cat("\n--- Liberal ---\n");      lib  <- run_full_analysis(mismatch_df, "Liberal", N_BOOTSTRAP)

rt_cons <- cons$aligned[["RT"]];  acc_cons <- cons$aligned[["ACC"]]
rt_lib  <- lib$max[["RT"]];       acc_lib  <- lib$max[["ACC"]]

save_boot_csv <- function(df, filename) {
  if (!is.null(df) && nrow(df) > 0)
    write.csv(df, file.path(data_out_dir, filename), row.names = FALSE, fileEncoding = "UTF-8")
}
save_boot_csv(rt_cons,  paste0("bootstrap_rt_conservative_aligned_v6",  SUFFIX, ".csv"))
save_boot_csv(acc_cons, paste0("bootstrap_acc_conservative_aligned_v6", SUFFIX, ".csv"))
save_boot_csv(rt_lib,   paste0("bootstrap_rt_liberal_max_v6",           SUFFIX, ".csv"))
save_boot_csv(acc_lib,  paste0("bootstrap_acc_liberal_max_v6",          SUFFIX, ".csv"))
cat("\n中间数据已保存\n")


## ----load-processed-data------------------------------------------------------
read_boot_csv <- function(filename) {
  fpath <- file.path(data_out_dir, filename)
  if (!file.exists(fpath)) return(data.frame())
  df <- read.csv(fpath, stringsAsFactors = FALSE); df$Identity <- as.factor(df$Identity); df
}
rt_cons  <- read_boot_csv(paste0("bootstrap_rt_conservative_aligned_v6",  SUFFIX, ".csv"))
acc_cons <- read_boot_csv(paste0("bootstrap_acc_conservative_aligned_v6", SUFFIX, ".csv"))
rt_lib   <- read_boot_csv(paste0("bootstrap_rt_liberal_max_v6",           SUFFIX, ".csv"))
acc_lib  <- read_boot_csv(paste0("bootstrap_acc_liberal_max_v6",          SUFFIX, ".csv"))


## ----helpers------------------------------------------------------------------
find_ci_exclusion_n <- function(subset_df) {
  if (nrow(subset_df) == 0) return(list(n = NULL, above = FALSE))
  a <- subset_df[subset_df$CI_lower > 0, ]; b <- subset_df[subset_df$CI_upper < 0, ]
  if (nrow(a)) return(list(n = min(a$SampleSize), above = TRUE))
  if (nrow(b)) return(list(n = min(b$SampleSize), above = FALSE))
  list(n = NULL, above = FALSE)
}

draw_identity_trajectory <- function(subset_df, color, vline_color, cex_n = 0.85) {
  if (nrow(subset_df) == 0) return()
  polygon(c(subset_df$SampleSize, rev(subset_df$SampleSize)),
          c(subset_df$CI_lower, rev(subset_df$CI_upper)),
          col = adjustcolor(color, alpha.f = 0.18), border = NA)
  lines(subset_df$SampleSize, subset_df$Mean_d, col = color, lwd = 2)
  points(subset_df$SampleSize, subset_df$Mean_d, pch = 16, col = color, cex = 0.5)
  conv <- find_ci_exclusion_n(subset_df)
  if (!is.null(conv$n)) {
    cr <- subset_df[subset_df$SampleSize == conv$n, ]
    if (nrow(cr)) {
      ref_y <- if (conv$above) cr$CI_lower[1] else cr$CI_upper[1]
      yl <- par("usr")
      segments(conv$n, yl[3], conv$n, ref_y, col = vline_color, lty = 2, lwd = 1.2)
      mtext(sprintf("N=%d", conv$n), side = 1, line = 2.4, at = conv$n,
            col = vline_color, cex = cex_n, font = 2)
      points(conv$n, yl[3], pch = 25, col = vline_color, bg = vline_color, cex = 0.6)
    }
  }
}


## ----panel-function-----------------------------------------------------------
draw_bootstrap_panel <- function(data, panel_label, measure, approach,
                                 cex_axis = 1.0, cex_lab = 1.0, cex_main = 1.1) {
  if (nrow(data) == 0) { plot.new(); text(0.5, 0.5, "No Data", cex = 1.5); return() }
  shape_df <- data[data$Identity == "Shape", ]; label_df <- data[data$Identity == "Label", ]
  max_n <- max(data$SampleSize, na.rm = TRUE); x_margin <- max(20, round(max_n * 0.08))
  yd <- range(c(data$CI_lower, data$CI_upper), na.rm = TRUE)
  yp <- max(0.05, diff(yd) * 0.15)
  par(mar = c(6.0, 5.4, 3.8, 1.2))
  plot.new(); plot.window(xlim = c(0, max_n + x_margin), ylim = c(yd[1] - yp, yd[2] + yp))
  abline(h = 0, col = "black", lty = 2, lwd = 1.5)
  draw_identity_trajectory(shape_df, SHAPE_COLOR, VLINE_SHAPE)
  draw_identity_trajectory(label_df, LABEL_COLOR, VLINE_LABEL)
  axis(1, cex.axis = cex_axis); axis(2, cex.axis = cex_axis, las = 1); box(bty = "l")
  ylab <- if (measure == "RT") "Cohen's d (Stranger - Self)" else "Cohen's d (Self - Stranger)"
  af <- if (approach == "Conservative") "Conservative Approach" else "Liberal Approach"
  title(main = sprintf("%s: %s  \u2014  %s", panel_label, measure, af),
        font.main = 2, cex.main = cex_main, family = "serif", line = 1.7)
  title(xlab = "Number of Participants (Sample Size)", line = 4.6, cex.lab = cex_lab, font.lab = 2)
  title(ylab = ylab, line = 4.2, cex.lab = cex_lab, font.lab = 2)
  legend("topright", legend = c("\u25A0 Shape", "\u25A0 Label"),
         text.col = c(SHAPE_COLOR, LABEL_COLOR), text.font = 2, cex = 0.9,
         bty = "n", inset = c(0.02, 0.02))
}


## ----combined-figure----------------------------------------------------------
combined_path <- file.path(pic_dir, paste0("combined_figures_v6", SUFFIX, ".png"))
png(combined_path, width = 15, height = 11, units = "in", res = 300)
par(family = "serif"); par(oma = c(0.4, 0.4, 2.0, 0.4))
layout(matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2, byrow = TRUE))
draw_bootstrap_panel(rt_cons,  "A", "RT",  "Conservative")
draw_bootstrap_panel(acc_cons, "B", "ACC", "Conservative")
draw_bootstrap_panel(rt_lib,   "C", "RT",  "Liberal")
draw_bootstrap_panel(acc_lib,  "D", "ACC", "Liberal")
mtext("Bootstrap Estimation of the Self-Prioritization Effect Under Mismatch Conditions",
      side = 3, line = 1.0, outer = TRUE, font = 2, cex = 1.05, family = "serif")
dev.off()
cat("\n组合图已保存:", combined_path, "\n")


## ----summary------------------------------------------------------------------
print_summary <- function(data, approach, measure) {
  if (nrow(data) == 0) return(invisible(NULL))
  cat(sprintf("\n--- %s %s ---\n", approach, measure))
  for (id in c("Shape", "Label")) {
    sub <- data[data$Identity == id, ]; if (!nrow(sub)) next
    mx <- max(sub$SampleSize); fin <- sub[sub$SampleSize == mx, ][1, ]
    conv <- find_ci_exclusion_n(sub)
    cat(sprintf("  %s: N=%d, d=%.3f, CI[%.3f, %.3f], Sig:%s%s\n", id, mx,
                fin$Mean_d, fin$CI_lower, fin$CI_upper,
                ifelse(fin$CI_lower > 0 || fin$CI_upper < 0, "Yes", "No"),
                if (!is.null(conv$n)) sprintf(", CI excludes 0 at N=%d", conv$n) else ", CI never excludes 0"))
  }
}
cat("\n========== Bootstrap Analysis Results ==========\n")
print_summary(rt_cons, "Conservative", "RT");  print_summary(acc_cons, "Conservative", "ACC")
print_summary(rt_lib, "Liberal", "RT");        print_summary(acc_lib, "Liberal", "ACC")

make_summary_table <- function(data, approach, measure) {
  if (nrow(data) == 0) return(NULL)
  do.call(rbind, lapply(c("Shape", "Label"), function(id) {
    sub <- data[data$Identity == id, ]; if (!nrow(sub)) return(NULL)
    mx <- max(sub$SampleSize); fin <- sub[sub$SampleSize == mx, ][1, ]
    conv <- find_ci_exclusion_n(sub)
    data.frame(Approach = approach, Measure = measure, Dimension = id, N_max = mx,
               Cohens_d = fin$Mean_d, CI_lower = fin$CI_lower, CI_upper = fin$CI_upper,
               N_min = ifelse(is.null(conv$n), NA_real_, conv$n),
               CI_excludes_zero_at_max = (fin$CI_lower > 0 || fin$CI_upper < 0),
               stringsAsFactors = FALSE)
  }))
}
mm_summary <- rbind(
  make_summary_table(rt_cons,  "Conservative (aligned)", "RT"),
  make_summary_table(acc_cons, "Conservative (aligned)", "ACC"),
  make_summary_table(rt_lib,   "Liberal (max)",          "RT"),
  make_summary_table(acc_lib,  "Liberal (max)",          "ACC"))
write.csv(mm_summary, file.path(data_out_dir, paste0("mismatch_bootstrap_summary", SUFFIX, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")
print(mm_summary, row.names = FALSE)

