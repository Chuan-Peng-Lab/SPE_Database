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
    return(normalizePath(file.path(dirname(sub("^--file=", "", fa[1])), ".."),
                         mustWork = FALSE))
  }
  normalizePath(".", mustWork = FALSE)
}
setwd(resolve_root())
cat("工作目录:", getwd(), "\n")


## ----packages-----------------------------------------------------------------
library(data.table)
library(dplyr)


## ----paths--------------------------------------------------------------------
# ===========================================================================
# 路径设置（相对于 3_Reports/ 项目根目录）
# ===========================================================================
raw_data_dir <- "../1_Data"
pic_dir      <- "Output/Pic"
data_out_dir <- "Output/data"

dir.create(pic_dir,      showWarnings = FALSE, recursive = TRUE)
dir.create(data_out_dir, showWarnings = FALSE, recursive = TRUE)

cat("原始数据目录:", raw_data_dir, "\n")
cat("中间数据输出:", data_out_dir, "\n")
cat("图片输出:", pic_out <- pic_dir, "\n")


## ----bootstrap-constants------------------------------------------------------
# ===========================================================================
# 全局参数
# ===========================================================================
# v2 相对 v1 的口径修正：
#  (1) 被试唯一键 = 数据集 × Subject（v1 直接按 Subject 分组，跨研究串号）；
#  (2) 数据集标识 = Clean 文件全名（v1 用 basename(dirname(f))，多实验研究退化为 "Exp1"/"Exp2"）；
#  (3) RT 合理性窗口 (0, 10000] ms（原始数据含 2^32-1 哨兵值与负值）；
#  (4) ACC 参与分析时仅保留合法取值 {0, 1}。

N_BOOTSTRAP   <- 500
MIN_SAMPLE_N  <- 10
STEP_N        <- 10
BOOT_SEED     <- 20260412

RT_MIN_MS     <- 0
RT_MAX_MS     <- 10000
VALID_ACC     <- c(0, 1)

SHAPE_COLOR   <- "#2E86AB"
LABEL_COLOR   <- "#A23B72"
VLINE_SHAPE   <- "#1a5c7a"
VLINE_LABEL   <- "#7a2a52"

set.seed(BOOT_SEED)


## ----process-data-------------------------------------------------------------
# ===========================================================================
# 1. 读取 → 合并 → 过滤 → 计算 Cohen's d → Bootstrap
# ===========================================================================

cat("========== Step 1: 读取 Clean.csv 文件 ==========\n")

clean_files <- list.files(raw_data_dir,
                          pattern = "_Clean\\.csv$",
                          recursive = TRUE,
                          full.names = TRUE)
cat(sprintf("找到 %d 个 Clean.csv 文件\n", length(clean_files)))

NEEDED_COLS <- c("Subject", "RT_ms", "ACC", "Matching",
                 "Shape_Standardized_Identity", "Label_Standardized_Identity")

read_one <- function(f) {
  header <- names(data.table::fread(f, nrows = 0, showProgress = FALSE))
  keep   <- intersect(NEEDED_COLS, header)
  d <- data.table::fread(f, select = keep, showProgress = FALSE)
  # v2 修复 (2)：数据集标识 = Clean 文件全名（唯一，且与身份分析同一口径）
  d[, Source := tools::file_path_sans_ext(basename(f))]
  d
}

all_data_list <- lapply(clean_files, function(f) tryCatch(read_one(f), error = function(e) NULL))
all_data_list <- Filter(Negate(is.null), all_data_list)
merged_df <- data.table::rbindlist(all_data_list, fill = TRUE)
if (nrow(merged_df) == 0) stop("未找到任何 Clean.csv 文件或文件为空")

merged_df[, Subject := suppressWarnings(as.numeric(Subject))]
merged_df[, RT_ms   := suppressWarnings(as.numeric(RT_ms))]
merged_df[, ACC     := suppressWarnings(as.numeric(ACC))]

# v2 修复 (1)：被试唯一键 = 数据集 × Subject
merged_df[, SubjKey := paste(Source, Subject, sep = "_")]

cat(sprintf("合并后总数据: %d 行, %d 个数据集, %d 个唯一被试\n",
            nrow(merged_df), uniqueN(merged_df$Source), uniqueN(merged_df$SubjKey)))

if (!"Label_Standardized_Identity" %in% colnames(merged_df)) {
  merged_df$Label_Standardized_Identity <- merged_df$Shape_Standardized_Identity
}

mismatch_df <- merged_df[merged_df$Matching == "Nonmatching", ]
cat(sprintf("Mismatch 试次: %d 行, %d 个数据集, %d 位被试\n",
            nrow(mismatch_df), uniqueN(mismatch_df$Source), uniqueN(mismatch_df$SubjKey)))

# ---------------------------------------------------------------------------
# 1b. Cohen's d 计算函数
# ---------------------------------------------------------------------------
cohens_d <- function(group1, group2) {
  n1 <- length(group1); n2 <- length(group2)
  if (n1 < 2 || n2 < 2) return(NA_real_)
  m1 <- mean(group1); m2 <- mean(group2)
  v1 <- var(group1); v2 <- var(group2)
  pooled_sd <- sqrt(((n1 - 1) * v1 + (n2 - 1) * v2) / (n1 + n2 - 2))
  if (!is.finite(pooled_sd) || pooled_sd == 0) return(NA_real_)
  (m1 - m2) / pooled_sd
}

# ---------------------------------------------------------------------------
# 1c. 个体级 Cohen's d 计算（按 SubjKey 分组）
# ---------------------------------------------------------------------------
calc_subject_cohens_d <- function(df, measure = "RT", min_trials = 2) {
  df <- data.table::as.data.table(df)
  results <- list()
  for (k in unique(df$SubjKey)) {
    subj_df <- df[SubjKey == k]

    if (measure == "RT") {
      rt_ok <- !is.na(subj_df$RT_ms) & subj_df$RT_ms > RT_MIN_MS & subj_df$RT_ms <= RT_MAX_MS
      self_vals     <- subj_df$RT_ms[subj_df$Primary == "Self"     & subj_df$ACC == 1 & rt_ok]
      stranger_vals <- subj_df$RT_ms[subj_df$Primary == "Stranger" & subj_df$ACC == 1 & rt_ok]
    } else {
      acc_ok <- !is.na(subj_df$ACC) & subj_df$ACC %in% VALID_ACC
      self_vals     <- subj_df$ACC[subj_df$Primary == "Self"     & acc_ok]
      stranger_vals <- subj_df$ACC[subj_df$Primary == "Stranger" & acc_ok]
    }
    self_vals     <- self_vals[!is.na(self_vals)]
    stranger_vals <- stranger_vals[!is.na(stranger_vals)]

    if (length(self_vals) < min_trials || length(stranger_vals) < min_trials) next

    d <- if (measure == "RT") {
      cohens_d(stranger_vals, self_vals)   # RT: Stranger - Self
    } else {
      cohens_d(self_vals, stranger_vals)   # ACC: Self - Stranger
    }

    if (!is.na(d)) {
      results[[length(results) + 1]] <- data.frame(
        SubjKey = k, Cohens_d = d, stringsAsFactors = FALSE)
    }
  }
  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}


## ----filter-functions---------------------------------------------------------
# ---------------------------------------------------------------------------
# 1d. Conservative 过滤
# ---------------------------------------------------------------------------
filter_valid_subjects <- function(df, id_col) {
  df <- data.table::as.data.table(df)
  valid <- character(0)
  for (k in unique(df$SubjKey)) {
    ids <- unique(df[SubjKey == k][[id_col]])
    ids <- ids[!is.na(ids)]
    if ("Self" %in% ids && "Stranger" %in% ids && length(ids) >= 3) {
      valid <- c(valid, k)
    }
  }
  valid
}

process_conservative <- function(df, analysis_type = "Shape") {
  if (is.null(df) || nrow(df) == 0) return(data.frame())

  if (analysis_type == "Shape") {
    primary_col   <- "Shape_Standardized_Identity"
    secondary_col <- "Label_Standardized_Identity"
  } else {
    primary_col   <- "Label_Standardized_Identity"
    secondary_col <- "Shape_Standardized_Identity"
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

# ---------------------------------------------------------------------------
# 1e. Liberal 过滤
# ---------------------------------------------------------------------------
process_liberal <- function(df, analysis_type = "Shape") {
  if (is.null(df) || nrow(df) == 0) return(data.frame())

  primary_col <- if (analysis_type == "Shape") {
    "Shape_Standardized_Identity"
  } else {
    "Label_Standardized_Identity"
  }

  df_f <- as.data.frame(df)
  df_f$Primary <- ifelse(df_f[[primary_col]] %in% c("Self", "Stranger"),
                         df_f[[primary_col]], "Other")
  df_f[df_f$Primary %in% c("Self", "Stranger"), , drop = FALSE]
}

# ---------------------------------------------------------------------------
# 1f. Bootstrap 分析
# ---------------------------------------------------------------------------
bootstrap_analysis <- function(cohens_d_vec, n_bootstrap = 500,
                               min_n = 10, step = 10, max_n = NULL) {
  total_n <- length(cohens_d_vec)
  if (total_n < min_n) return(data.frame())

  if (is.null(max_n)) max_n <- total_n
  max_n <- min(max_n, total_n)

  sample_sizes <- seq(min_n, max_n, by = step)
  if (max_n %% step != 0 && !max_n %in% sample_sizes) {
    sample_sizes <- c(sample_sizes, max_n)
  }
  sample_sizes <- sort(unique(sample_sizes[sample_sizes <= total_n]))

  set.seed(BOOT_SEED)
  results <- list()
  for (n in sample_sizes) {
    boot_means <- replicate(n_bootstrap, mean(sample(cohens_d_vec, size = n, replace = TRUE)))
    results[[length(results) + 1]] <- data.frame(
      SampleSize = n,
      Mean_d     = mean(boot_means),
      CI_lower   = quantile(boot_means, 0.025, na.rm = TRUE),
      CI_upper   = quantile(boot_means, 0.975, na.rm = TRUE),
      stringsAsFactors = FALSE
    )
  }
  do.call(rbind, results)
}


## ----run-analysis-------------------------------------------------------------
# ===========================================================================
# 2. 运行完整分析
# ===========================================================================
cat("\n========== Step 2: 运行 Bootstrap 分析 ==========\n")

run_full_analysis <- function(data, approach = "Conservative", n_boot = 500) {
  if (is.null(data) || nrow(data) == 0) {
    cat(sprintf("  %s: 无有效数据，跳过\n", approach))
    return(list(aligned = list(RT = data.frame(), ACC = data.frame()),
                max     = list(RT = data.frame(), ACC = data.frame())))
  }

  results_aligned <- list()
  results_max     <- list()
  fn <- if (approach == "Conservative") process_conservative else process_liberal

  for (measure in c("RT", "ACC")) {
    dm <- data
    shape_data <- fn(dm, "Shape")
    label_data <- fn(dm, "Label")

    shape_cohens <- calc_subject_cohens_d(shape_data, measure)
    label_cohens <- calc_subject_cohens_d(label_data, measure)

    cat(sprintf("  %s %s - Shape N=%d, Label N=%d\n",
                approach, measure, nrow(shape_cohens), nrow(label_cohens)))

    max_n_aligned <- min(nrow(shape_cohens), nrow(label_cohens), na.rm = TRUE)
    if (is.finite(max_n_aligned) && max_n_aligned >= MIN_SAMPLE_N) {
      shape_boot_a <- bootstrap_analysis(shape_cohens$Cohens_d, n_boot, max_n = max_n_aligned)
      label_boot_a <- bootstrap_analysis(label_cohens$Cohens_d, n_boot, max_n = max_n_aligned)
      if (nrow(shape_boot_a) > 0) shape_boot_a$Identity <- "Shape"
      if (nrow(label_boot_a) > 0) label_boot_a$Identity <- "Label"
      results_aligned[[measure]] <- rbind(shape_boot_a, label_boot_a)
    } else {
      results_aligned[[measure]] <- data.frame()
    }

    shape_boot_m <- bootstrap_analysis(shape_cohens$Cohens_d, n_boot)
    label_boot_m <- bootstrap_analysis(label_cohens$Cohens_d, n_boot)
    if (nrow(shape_boot_m) > 0) shape_boot_m$Identity <- "Shape"
    if (nrow(label_boot_m) > 0) label_boot_m$Identity <- "Label"
    results_max[[measure]] <- rbind(shape_boot_m, label_boot_m)
  }
  list(aligned = results_aligned, max = results_max)
}

cat("\n--- Conservative Approach ---\n")
cons_results <- run_full_analysis(mismatch_df, "Conservative", N_BOOTSTRAP)

cat("\n--- Liberal Approach ---\n")
lib_results  <- run_full_analysis(mismatch_df, "Liberal", N_BOOTSTRAP)

# ===========================================================================
# 3. 提取绘图所需的数据框（与 v1 一致：conservative 用 aligned，liberal 用 max）
# ===========================================================================
cat("\n========== Step 3: 提取绘图数据框 ==========\n")

rt_cons  <- cons_results$aligned[["RT"]]
acc_cons <- cons_results$aligned[["ACC"]]
rt_lib   <- lib_results$max[["RT"]]
acc_lib  <- lib_results$max[["ACC"]]

for (nm in c("rt_cons", "acc_cons", "rt_lib", "acc_lib")) {
  df <- get(nm)
  if (!is.null(df) && nrow(df) > 0) {
    cat(sprintf("  %s: %d rows, max N=%d\n", nm, nrow(df), max(df$SampleSize)))
  } else {
    cat(sprintf("  %s: EMPTY\n", nm))
  }
}

# ===========================================================================
# 4. 保存中间数据
# ===========================================================================
cat("\n========== Step 4: 保存中间数据 ==========\n")

save_boot_csv <- function(df, filename) {
  if (!is.null(df) && nrow(df) > 0) {
    write.csv(df, file.path(data_out_dir, filename), row.names = FALSE, fileEncoding = "UTF-8")
  }
}

save_boot_csv(rt_cons,  "bootstrap_rt_conservative_aligned_v6_v2.csv")
save_boot_csv(acc_cons, "bootstrap_acc_conservative_aligned_v6_v2.csv")
save_boot_csv(rt_lib,   "bootstrap_rt_liberal_max_v6_v2.csv")
save_boot_csv(acc_lib,  "bootstrap_acc_liberal_max_v6_v2.csv")

cat("中间数据已保存至:", data_out_dir, "\n")


## ----load-processed-data------------------------------------------------------
# ===========================================================================
# 5. 读取处理好的数据
# ===========================================================================
read_boot_csv <- function(filename) {
  fpath <- file.path(data_out_dir, filename)
  if (file.exists(fpath)) {
    df <- read.csv(fpath, stringsAsFactors = FALSE)
    df$Identity <- as.factor(df$Identity)
    cat(sprintf("  %s: %d rows\n", filename, nrow(df)))
    return(df)
  } else {
    cat(sprintf("  %s: NOT FOUND\n", filename))
    return(data.frame())
  }
}

rt_cons  <- read_boot_csv("bootstrap_rt_conservative_aligned_v6_v2.csv")
acc_cons <- read_boot_csv("bootstrap_acc_conservative_aligned_v6_v2.csv")
rt_lib   <- read_boot_csv("bootstrap_rt_liberal_max_v6_v2.csv")
acc_lib  <- read_boot_csv("bootstrap_acc_liberal_max_v6_v2.csv")


## ----helpers------------------------------------------------------------------
# ===========================================================================
# 6. 绘图辅助函数
# ===========================================================================

find_ci_exclusion_n <- function(subset_df) {
  if (nrow(subset_df) == 0) return(list(n = NULL, above = FALSE))
  above_zero <- subset_df[subset_df$CI_lower > 0, ]
  below_zero <- subset_df[subset_df$CI_upper < 0, ]
  if (nrow(above_zero) > 0) {
    return(list(n = min(above_zero$SampleSize), above = TRUE))
  } else if (nrow(below_zero) > 0) {
    return(list(n = min(below_zero$SampleSize), above = FALSE))
  } else {
    return(list(n = NULL, above = FALSE))
  }
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
    conv_n <- conv$n
    conv_row <- subset_df[subset_df$SampleSize == conv_n, ]
    if (nrow(conv_row) > 0) {
      ref_y <- if (conv$above) conv_row$CI_lower[1] else conv_row$CI_upper[1]
      y_lims <- par("usr")
      segments(conv_n, y_lims[3], conv_n, ref_y, col = vline_color, lty = 2, lwd = 1.2)
      mtext(sprintf("N=%d", conv_n), side = 1, line = 2.4, at = conv_n,
            col = vline_color, cex = cex_n, font = 2)
      points(conv_n, y_lims[3], pch = 25, col = vline_color, bg = vline_color, cex = 0.6)
    }
  }
}


## ----panel-function-----------------------------------------------------------
# ===========================================================================
# 7. 单面板绘图函数
# ===========================================================================

draw_bootstrap_panel <- function(data, panel_label, measure, approach,
                                 cex_axis = 1.0, cex_lab = 1.0, cex_main = 1.1) {
  if (nrow(data) == 0) {
    plot.new(); text(0.5, 0.5, "No Data", cex = 1.5); return()
  }

  shape_df <- data[data$Identity == "Shape", ]
  label_df <- data[data$Identity == "Label", ]

  max_n    <- max(data$SampleSize, na.rm = TRUE)
  x_margin <- max(20, round(max_n * 0.08))

  y_data <- range(c(data$CI_lower, data$CI_upper), na.rm = TRUE)
  y_pad  <- max(0.05, diff(y_data) * 0.15)
  y_lim  <- c(y_data[1] - y_pad, y_data[2] + y_pad)

  par(mar = c(6.0, 5.4, 3.8, 1.2))
  plot.new()
  plot.window(xlim = c(0, max_n + x_margin), ylim = y_lim)

  abline(h = 0, col = "black", lty = 2, lwd = 1.5)

  draw_identity_trajectory(shape_df, SHAPE_COLOR, VLINE_SHAPE)
  draw_identity_trajectory(label_df, LABEL_COLOR, VLINE_LABEL)

  axis(1, cex.axis = cex_axis)
  axis(2, cex.axis = cex_axis, las = 1)
  box(bty = "l")

  y_label <- if (measure == "RT") "Cohen's d (Stranger - Self)" else "Cohen's d (Self - Stranger)"
  approach_full <- if (approach == "Conservative") "Conservative Approach" else "Liberal Approach"
  panel_title <- sprintf("%s: %s  \u2014  %s", panel_label, measure, approach_full)
  title(main = panel_title, font.main = 2, cex.main = cex_main, family = "serif", line = 1.7)
  title(xlab = "Number of Participants (Sample Size)", line = 4.6, cex.lab = cex_lab, font.lab = 2)
  title(ylab = y_label, line = 4.2, cex.lab = cex_lab, font.lab = 2)

  legend("topright", legend = c("\u25A0 Shape", "\u25A0 Label"),
         text.col = c(SHAPE_COLOR, LABEL_COLOR), text.font = 2, cex = 0.9,
         bty = "n", inset = c(0.02, 0.02))
}


## ----combined-figure----------------------------------------------------------
# ===========================================================================
# 8. 生成 2×2 组合图
# ===========================================================================
combined_path <- file.path(pic_dir, "combined_figures_v6_v2.png")

png(combined_path, width = 15, height = 11, units = "in", res = 300)
par(family = "serif")
par(oma = c(0.4, 0.4, 2.0, 0.4))

layout_matrix <- matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2, byrow = TRUE)
layout(layout_matrix)

draw_bootstrap_panel(rt_cons,  "A", "RT",  "Conservative")
draw_bootstrap_panel(acc_cons, "B", "ACC", "Conservative")
draw_bootstrap_panel(rt_lib,   "C", "RT",  "Liberal")
draw_bootstrap_panel(acc_lib,  "D", "ACC", "Liberal")

mtext("Bootstrap Estimation of the Self-Prioritization Effect Under Mismatch Conditions",
      side = 3, line = 1.0, outer = TRUE, font = 2, cex = 1.05, family = "serif")

dev.off()
cat("\n组合图已保存:", combined_path, "\n")


## ----summary------------------------------------------------------------------
# ===========================================================================
# 9. 结果汇总 + 正文用汇总表
# ===========================================================================

print_summary <- function(data, approach, measure) {
  if (nrow(data) == 0) return()
  cat(sprintf("\n--- %s %s ---\n", approach, measure))
  for (id in c("Shape", "Label")) {
    sub <- data[data$Identity == id, ]
    if (nrow(sub) == 0) next
    max_n <- max(sub$SampleSize)
    final <- sub[sub$SampleSize == max_n, ][1, ]
    sig   <- (final$CI_lower > 0 || final$CI_upper < 0)
    conv  <- find_ci_exclusion_n(sub)
    conv_str <- if (!is.null(conv$n)) sprintf(", CI excludes 0 at N=%d", conv$n) else ", CI never excludes 0"
    cat(sprintf("  %s: N=%d, d=%.3f, CI[%.3f, %.3f], Sig:%s%s\n",
                id, max_n, final$Mean_d, final$CI_lower, final$CI_upper,
                ifelse(sig, "Yes", "No"), conv_str))
  }
}

cat("\n========== Bootstrap Analysis Results ==========\n")
print_summary(rt_cons,  "Conservative", "RT")
print_summary(acc_cons, "Conservative", "ACC")
print_summary(rt_lib,   "Liberal",      "RT")
print_summary(acc_lib,  "Liberal",      "ACC")

make_summary_table <- function(data, approach, measure) {
  if (nrow(data) == 0) return(NULL)
  do.call(rbind, lapply(c("Shape", "Label"), function(id) {
    sub <- data[data$Identity == id, ]
    if (nrow(sub) == 0) return(NULL)
    max_n <- max(sub$SampleSize)
    final <- sub[sub$SampleSize == max_n, ][1, ]
    conv  <- find_ci_exclusion_n(sub)
    data.frame(Approach = approach, Measure = measure, Dimension = id,
               N_max = max_n, Cohens_d = final$Mean_d,
               CI_lower = final$CI_lower, CI_upper = final$CI_upper,
               N_min = ifelse(is.null(conv$n), NA_real_, conv$n),
               CI_excludes_zero_at_max = (final$CI_lower > 0 || final$CI_upper < 0),
               stringsAsFactors = FALSE)
  }))
}

mismatch_summary <- rbind(
  make_summary_table(rt_cons,  "Conservative (aligned)", "RT"),
  make_summary_table(acc_cons, "Conservative (aligned)", "ACC"),
  make_summary_table(rt_lib,   "Liberal (max)",          "RT"),
  make_summary_table(acc_lib,  "Liberal (max)",          "ACC")
)
write.csv(mismatch_summary,
          file.path(data_out_dir, "mismatch_bootstrap_summary_v2.csv"),
          row.names = FALSE, fileEncoding = "UTF-8")
cat("\n正文用汇总表已保存: Output/data/mismatch_bootstrap_summary_v2.csv\n")
print(mismatch_summary, row.names = FALSE)

