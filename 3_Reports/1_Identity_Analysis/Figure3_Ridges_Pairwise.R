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
library(lme4)
library(MASS)


## ----paths--------------------------------------------------------------------
# 研究数据 / 输出目录（相对 3_Reports/）
raw_data_dir <- "../1_Data"
pic_dir      <- "Output/Pic"
data_out_dir <- "Output/data"
dir.create(pic_dir, showWarnings = FALSE, recursive = TRUE)
dir.create(data_out_dir, showWarnings = FALSE, recursive = TRUE)

# 共用数据装配层（分片合并、Hu_YQ 规则、practice 策略、规范身份判定）
source("analysis_config.R")
cat(sprintf("\n>>> PRACTICE_POLICY = %s\n", PRACTICE_POLICY))


## ----constants----------------------------------------------------------------
# ===========================================================================
# 全局常量
# ===========================================================================
IDENTITY_ORDER <- BASELINE_IDENTITIES

IDENTITY_COLORS <- c(
  "NonPerson"     = "#DB3124",
  "Stranger"      = "#FC8C5A",
  "Celebrity"     = "#FFDF92",
  "Acquaintance"  = "#90BED8",
  "Close"         = "#4B74B2"
)

RIDGE_HEIGHT    <- 0.85
BOX_OFFSET      <- 0.11
BOX_HEIGHT      <- 0.10
BOOTSTRAP_N     <- 10000
BOOTSTRAP_SEED  <- 20260412
FIG_DPI         <- 320

RT_MIN_MS       <- 0
RT_MAX_MS       <- 10000
VALID_ACC       <- c(0, 1)
# 输出后缀：practice=exclude 为正式版本；keep 作为敏感性分析并存
SUFFIX          <- if (PRACTICE_POLICY == "keep") "_keepPractice" else ""


## ----compute-subject-cohens-d-------------------------------------------------
# ===========================================================================
# 1. 读取（分片自动合并 + Hu_YQ 结构规则）→ subject-level Cohen's d
# ===========================================================================
NEEDED <- c("Subject", "RT_ms", "ACC", "Matching", "Phase", "Task",
            "Shape_Standardized_Identity", "Label_Standardized_Identity")

merged <- spe_read_datasets(raw_data_dir, NEEDED)
merged <- spe_apply_structure(merged)

merged[, RT_ms := suppressWarnings(as.numeric(RT_ms))]
merged[, ACC   := suppressWarnings(as.numeric(ACC))]
merged <- spe_add_subject_key(merged)

cat(sprintf("\n合并后: %d 行, %d 个数据集, %d 个唯一被试（数据集×Subject）\n",
            nrow(merged), uniqueN(merged$Source), uniqueN(merged$SubjKey)))

calc_cohens_d <- function(group1, group2) {
  n1 <- length(group1); n2 <- length(group2)
  if (n1 < 2 || n2 < 2) return(NA_real_)
  psd <- sqrt(((n1 - 1) * var(group1) + (n2 - 1) * var(group2)) / (n1 + n2 - 2))
  if (!is.finite(psd) || psd == 0) return(NA_real_)
  (mean(group1) - mean(group2)) / psd
}

compute_spe_cohens_d <- function(data, measure = "RT", min_trials = 2) {
  results <- list()
  for (k in unique(data$SubjKey)) {
    s <- data[SubjKey == k]
    if (measure == "RT") {
      ok <- !is.na(s$RT_ms) & s$RT_ms > RT_MIN_MS & s$RT_ms <= RT_MAX_MS
      self_v <- s$RT_ms[s$Shape_Standardized_Identity == "Self" & s$ACC == 1 & ok]
    } else {
      ok <- !is.na(s$ACC) & s$ACC %in% VALID_ACC
      self_v <- s$ACC[s$Shape_Standardized_Identity == "Self" & ok]
    }
    self_v <- self_v[!is.na(self_v)]
    if (length(self_v) < min_trials) next
    for (id in IDENTITY_ORDER) {
      if (measure == "RT") {
        oth <- s$RT_ms[s$Shape_Standardized_Identity == id & s$ACC == 1 & ok]
      } else {
        oth <- s$ACC[s$Shape_Standardized_Identity == id & ok]
      }
      oth <- oth[!is.na(oth)]
      if (length(oth) < min_trials) next
      d <- if (measure == "RT") calc_cohens_d(oth, self_v) else calc_cohens_d(self_v, oth)
      if (!is.na(d)) {
        results[[length(results) + 1]] <- data.frame(
          Source = s$Source[1], Subject = s$Subject[1], SubjKey = k,
          Identity = id, Measure = measure, Cohens_d = d,
          n_Self = length(self_v), n_Other = length(oth), stringsAsFactors = FALSE)
      }
    }
  }
  if (length(results) == 0) return(data.frame())
  do.call(rbind, results)
}

rt_results  <- compute_spe_cohens_d(merged, "RT")
acc_results <- compute_spe_cohens_d(merged, "ACC")
if (nrow(rt_results) == 0) stop("RT 结果为空")

cat(sprintf("\nRT : %d 行 / %d 被试 / %d 数据集\n",
            nrow(rt_results), uniqueN(rt_results$SubjKey), uniqueN(rt_results$Source)))
cat(sprintf("ACC: %d 行 / %d 被试 / %d 数据集\n",
            nrow(acc_results), uniqueN(acc_results$SubjKey), uniqueN(acc_results$Source)))

# 各基线身份的数据集覆盖（供正文报告）
cat("\n各基线身份的数据集覆盖（RT）：\n")
for (id in IDENTITY_ORDER) {
  sub <- rt_results[rt_results$Identity == id, ]
  cat(sprintf("   %-13s datasets=%3d  subjects=%5d\n",
              id, uniqueN(sub$Source), uniqueN(sub$SubjKey)))
}


## ----fit-mixed-model----------------------------------------------------------
# ===========================================================================
# 2. 混合模型 + 参数化 Bootstrap
# ===========================================================================
prepare_data <- function(df) {
  df$SubjKey  <- as.factor(df$SubjKey)
  df$Source   <- as.factor(df$Source)
  df$Identity <- factor(df$Identity, levels = IDENTITY_ORDER, ordered = TRUE)
  df
}
rt_results  <- prepare_data(rt_results)
acc_results <- prepare_data(acc_results)

rt_model  <- lmer(Cohens_d ~ 0 + Identity + (1 | SubjKey) + (1 | Source),
                  data = rt_results, REML = FALSE)
acc_model <- lmer(Cohens_d ~ 0 + Identity + (1 | SubjKey) + (1 | Source),
                  data = acc_results, REML = FALSE)
cat("\nRT Model:\n");  print(summary(rt_model))
cat("\nACC Model:\n"); print(summary(acc_model))

set.seed(BOOTSTRAP_SEED)
bootstrap_model <- function(model, identity_order) {
  fixed <- fixef(model); V <- as.matrix(vcov(model))
  sm <- mvrnorm(n = BOOTSTRAP_N, mu = fixed, Sigma = V)
  colnames(sm) <- names(fixed)
  do.call(rbind, lapply(identity_order, function(id) {
    cn <- paste0("Identity", id)
    if (!cn %in% colnames(sm)) return(NULL)
    data.frame(Identity = id, Predicted_Value = sm[, cn], stringsAsFactors = FALSE)
  }))
}
rt_dist  <- bootstrap_model(rt_model,  IDENTITY_ORDER)
acc_dist <- bootstrap_model(acc_model, IDENTITY_ORDER)

compute_pairwise <- function(model, identity_order) {
  fixed <- fixef(model); V <- as.matrix(vcov(model))
  samples <- mvrnorm(n = BOOTSTRAP_N, mu = fixed, Sigma = V)
  col_map <- setNames(paste0("Identity", identity_order), identity_order)
  rows <- list()
  for (i in seq_len(length(identity_order) - 1)) {
    for (j in (i + 1):length(identity_order)) {
      a <- identity_order[i]; b <- identity_order[j]
      dv <- samples[, col_map[a]] - samples[, col_map[b]]
      dv <- dv[is.finite(dv)]
      if (!length(dv)) next
      qs <- quantile(dv, c(0.025, 0.5, 0.975), na.rm = TRUE)
      p2 <- min(1, 2 * min(mean(dv <= 0), mean(dv >= 0)))
      rows[[length(rows) + 1]] <- data.frame(
        Identity_A = a, Identity_B = b, diff_mean = mean(dv), diff_sd = sd(dv),
        diff_median = qs[2], ci95_lower = qs[1], ci95_upper = qs[3],
        p_value_bootstrap = p2, significant = (qs[1] > 0 || qs[3] < 0),
        stringsAsFactors = FALSE)
    }
  }
  pw <- do.call(rbind, rows)
  pw[order(pw$diff_mean), ]
}
rt_pairwise  <- compute_pairwise(rt_model,  IDENTITY_ORDER)
acc_pairwise <- compute_pairwise(acc_model, IDENTITY_ORDER)
cat(sprintf("\nRT : %d/10 显著\nACC: %d/10 显著\n",
            sum(rt_pairwise$significant), sum(acc_pairwise$significant)))

write.csv(rt_dist,  file.path(data_out_dir, paste0("use_example_ridge_distribution_RT_11",  SUFFIX, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(acc_dist, file.path(data_out_dir, paste0("use_example_ridge_distribution_ACC_11", SUFFIX, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(rt_pairwise,  file.path(data_out_dir, paste0("use_example_pairwise_differences_RT_11",  SUFFIX, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")
write.csv(acc_pairwise, file.path(data_out_dir, paste0("use_example_pairwise_differences_ACC_11", SUFFIX, ".csv")), row.names = FALSE, fileEncoding = "UTF-8")

identity_summary_df <- rbind(
  do.call(rbind, lapply(IDENTITY_ORDER, function(id) {
    v <- rt_dist$Predicted_Value[rt_dist$Identity == id]
    data.frame(Measure = "RT", Identity = id, n_boot = length(v), d_mean = mean(v),
               d_sd = sd(v), ci95_lower = quantile(v, .025), ci95_upper = quantile(v, .975),
               n_datasets = uniqueN(rt_results$Source[rt_results$Identity == id]),
               n_subjects = uniqueN(rt_results$SubjKey[rt_results$Identity == id]),
               stringsAsFactors = FALSE)
  })),
  do.call(rbind, lapply(IDENTITY_ORDER, function(id) {
    v <- acc_dist$Predicted_Value[acc_dist$Identity == id]
    data.frame(Measure = "ACC", Identity = id, n_boot = length(v), d_mean = mean(v),
               d_sd = sd(v), ci95_lower = quantile(v, .025), ci95_upper = quantile(v, .975),
               n_datasets = uniqueN(acc_results$Source[acc_results$Identity == id]),
               n_subjects = uniqueN(acc_results$SubjKey[acc_results$Identity == id]),
               stringsAsFactors = FALSE)
  }))
)
write.csv(identity_summary_df, file.path(data_out_dir, paste0("identity_baseline_summary", SUFFIX, ".csv")),
          row.names = FALSE, fileEncoding = "UTF-8")
print(identity_summary_df, row.names = FALSE)


## ----load-processed-data------------------------------------------------------
rt_dist  <- read.csv(file.path(data_out_dir, paste0("use_example_ridge_distribution_RT_11", SUFFIX, ".csv")), stringsAsFactors = FALSE)
acc_dist <- read.csv(file.path(data_out_dir, paste0("use_example_ridge_distribution_ACC_11", SUFFIX, ".csv")), stringsAsFactors = FALSE)
rt_pairwise  <- read.csv(file.path(data_out_dir, paste0("use_example_pairwise_differences_RT_11", SUFFIX, ".csv")), stringsAsFactors = FALSE)
acc_pairwise <- read.csv(file.path(data_out_dir, paste0("use_example_pairwise_differences_ACC_11", SUFFIX, ".csv")), stringsAsFactors = FALSE)


## ----ridge-core-function------------------------------------------------------
calc_scipy_equiv_bw <- function(x) 0.32 * length(x)^(-0.2) * sd(x)

draw_ridge_with_box <- function(dist_data, xlim, xlabel, title = NULL,
                                label_column = "Identity",
                                cex_axis = 0.85, cex_lab = 1.10, cex_main = 1.15) {
  order_ids <- IDENTITY_ORDER
  n_ids <- length(order_ids)
  y_positions <- setNames((n_ids - 1 - seq(0, n_ids - 1)) * 1.2, order_ids)
  y_bottom <- min(y_positions) - 0.85
  y_top    <- max(y_positions) + 0.95

  line_in <- par("cin")[2]
  w_lab <- max(strwidth(order_ids, units = "inches", cex = cex_axis))
  ylab_line <- 1 + w_lab / line_in + 1.6
  par(mar = c(4.6, ylab_line + 1.7, 3.4, 1.2))
  plot.new(); plot.window(xlim = xlim, ylim = c(y_bottom, y_top))

  density_cache <- list(); global_dmax <- 0
  for (id in order_ids) {
    vals <- dist_data$Predicted_Value[dist_data[[label_column]] == id]
    vals <- vals[is.finite(vals)]
    if (length(vals) < 2) next
    kde <- density(vals, bw = calc_scipy_equiv_bw(vals), kernel = "gaussian",
                   n = 900, from = xlim[1], to = xlim[2])
    dens <- kde$y; dens[!is.finite(dens)] <- 0; dens[dens < 0] <- 0
    density_cache[[id]] <- list(x = kde$x, y = dens)
    global_dmax <- max(global_dmax, max(dens), na.rm = TRUE)
  }
  if (!is.finite(global_dmax) || global_dmax <= 0) global_dmax <- 1

  for (id in order_ids) {
    vals <- dist_data$Predicted_Value[dist_data[[label_column]] == id]
    vals <- vals[is.finite(vals)]
    if (length(vals) < 2 || is.null(density_cache[[id]])) next
    xs <- density_cache[[id]]$x; dens <- density_cache[[id]]$y; y0 <- y_positions[id]
    dens_scaled <- dens / global_dmax * RIDGE_HEIGHT
    mask <- dens_scaled > (RIDGE_HEIGHT * 0.01)
    if (any(mask)) {
      polygon(c(xs[mask], rev(xs[mask])),
              c(rep(y0, sum(mask)), y0 + rev(dens_scaled[mask])),
              col = adjustcolor(IDENTITY_COLORS[id], alpha.f = 0.8), border = NA)
      lines(xs[mask], y0 + dens_scaled[mask], col = IDENTITY_COLORS[id], lwd = 1.0)
    }
    qs <- quantile(vals, c(0.025, 0.25, 0.5, 0.75, 0.975))
    yb <- y0 - BOX_OFFSET; cap_h <- BOX_HEIGHT * 0.45
    segments(qs[1], yb, qs[2], yb, col = "#5a5a5a", lwd = 0.7)
    segments(qs[4], yb, qs[5], yb, col = "#5a5a5a", lwd = 0.7)
    segments(qs[1], yb - cap_h / 2, qs[1], yb + cap_h / 2, col = "#5a5a5a", lwd = 0.7)
    segments(qs[5], yb - cap_h / 2, qs[5], yb + cap_h / 2, col = "#5a5a5a", lwd = 0.7)
    rect(qs[2], yb - BOX_HEIGHT / 2, qs[4], yb + BOX_HEIGHT / 2,
         col = "#f4f4f4", border = "#5a5a5a", lwd = 0.8)
    segments(qs[3], yb - BOX_HEIGHT / 2, qs[3], yb + BOX_HEIGHT / 2, col = "#3a3a3a", lwd = 0.9)
  }
  abline(v = 0, col = "#d27d7d", lty = 2, lwd = 1.0)
  ticks <- seq(ceiling(xlim[1] / 0.25) * 0.25, floor(xlim[2] / 0.25) * 0.25, by = 0.25)
  axis(1, at = ticks, cex.axis = cex_axis)
  axis(2, at = y_positions[order_ids], labels = order_ids, las = 1, cex.axis = cex_axis)
  title(xlab = xlabel, cex.lab = cex_lab)
  title(ylab = "Standardized Identity", line = ylab_line, cex.lab = cex_lab)
  if (!is.null(title)) title(main = title, font.main = 2, cex.main = cex_main)
  box(bty = "l")
}


## ----forest-core-function-----------------------------------------------------
draw_pairwise_forest <- function(pairwise_df, title = NULL,
                                 xlabel = "Difference in Cohen's d",
                                 cex_axis = 0.80, cex_lab = 1.05, cex_main = 1.10) {
  df <- pairwise_df
  df$label <- paste(df$Identity_A, "vs", df$Identity_B)
  df <- df[order(df$diff_mean), ]
  n_pairs <- nrow(df); y_pos <- seq_len(n_pairs) - 1
  colors <- ifelse(df$significant, "#2E7D32", "#9E9E9E")
  x_min <- min(df$ci95_lower, na.rm = TRUE); x_max <- max(df$ci95_upper, na.rm = TRUE)
  pad <- (x_max - x_min) * 0.1
  line_in <- par("cin")[2]
  w_lab <- max(strwidth(df$label, units = "inches", cex = cex_axis))
  par(mar = c(4.8, 1 + w_lab / line_in + 1.5, 3.4, 1.2))
  plot.new(); plot.window(xlim = c(x_min - pad, x_max + pad), ylim = c(-0.8, n_pairs - 0.2))
  grid(nx = NULL, ny = NA, col = "grey85", lty = "dashed", lwd = 0.5)
  abline(v = 0, col = "#d27d7d", lty = 2, lwd = 1.2)
  for (i in seq_len(n_pairs)) {
    y <- y_pos[i]; row <- df[i, ]
    old <- par("lend"); par(lend = 2)
    segments(row$ci95_lower, y, row$ci95_upper, y, col = colors[i], lwd = 2.5)
    par(lend = old)
    points(row$diff_mean, y, pch = 21, bg = colors[i], col = "white", cex = 1.2, lwd = 0.6)
  }
  axis(1, cex.axis = cex_axis)
  axis(2, at = y_pos, labels = df$label, las = 1, cex.axis = cex_axis)
  title(xlab = xlabel, cex.lab = cex_lab)
  if (!is.null(title)) title(main = title, font.main = 2, cex.main = cex_main)
  box(bty = "l")
  usr <- par("usr")
  legend(x = usr[2], y = usr[3] + (usr[4] - usr[3]) * 0.03,
         legend = c("Sig. (CI excludes 0)", "N.S. (CI includes 0)"),
         pch = 21, pt.bg = c("#2E7D32", "#9E9E9E"), col = "white",
         pt.lwd = 0.6, pt.cex = 1.0, xjust = 1, yjust = 0, cex = 0.75, bty = "n")
}


## ----combined-figure----------------------------------------------------------
combined_path <- file.path(pic_dir, paste0("p_ridges_pairwise_combined_11", SUFFIX, ".png"))
png(combined_path, width = 20, height = 22, units = "in", res = FIG_DPI)
par(family = "serif"); par(oma = c(0.4, 0.4, 0.5, 0.4))

all_v <- c(rt_dist$Predicted_Value, acc_dist$Predicted_Value)
xr <- range(all_v, na.rm = TRUE); xpad <- diff(xr) * 0.06
XLIM <- c(floor((xr[1] - xpad) / 0.25) * 0.25, ceiling((xr[2] + xpad) / 0.25) * 0.25)
if (XLIM[2] <= XLIM[1]) XLIM[2] <- XLIM[1] + 0.25
cat(sprintf("自动 XLIM = [%.2f, %.2f]\n", XLIM[1], XLIM[2]))

layout(matrix(c(1, 2, 3, 4), nrow = 2, ncol = 2, byrow = TRUE), heights = c(1.0, 0.85))
draw_ridge_with_box(rt_dist, XLIM,
  xlabel = "Cohen's d (Other \u2212 Self Identity) in RT",
  title  = "A.  RT SPE by Social Identity")
draw_ridge_with_box(acc_dist, XLIM,
  xlabel = "Cohen's d (Self \u2212 Other Identity) in ACC",
  title  = "B.  ACC SPE by Social Identity")
draw_pairwise_forest(rt_pairwise,  title = "C.  RT: Pairwise Differences",
  xlabel = "Difference in Cohen's d (\u0394 = d_A \u2212 d_B)")
draw_pairwise_forest(acc_pairwise, title = "D.  ACC: Pairwise Differences",
  xlabel = "Difference in Cohen's d (\u0394 = d_A \u2212 d_B)")
dev.off()
cat("\n组合图已保存:", combined_path, "\n")


## ----summary-table------------------------------------------------------------
cat("\n========== RT 成对比较 ==========\n")
rt_display <- rt_pairwise[, c("Identity_A", "Identity_B", "diff_mean", "ci95_lower", "ci95_upper", "p_value_bootstrap", "significant")]
for (cc in c("diff_mean", "ci95_lower", "ci95_upper")) rt_display[[cc]] <- round(rt_display[[cc]], 4)
print(rt_display, row.names = FALSE)
cat(sprintf("\nRT: %d/10 显著\n", sum(rt_pairwise$significant)))

cat("\n========== ACC 成对比较 ==========\n")
acc_display <- acc_pairwise[, c("Identity_A", "Identity_B", "diff_mean", "ci95_lower", "ci95_upper", "p_value_bootstrap", "significant")]
for (cc in c("diff_mean", "ci95_lower", "ci95_upper")) acc_display[[cc]] <- round(acc_display[[cc]], 4)
print(acc_display, row.names = FALSE)
cat(sprintf("\nACC: %d/10 显著\n", sum(acc_pairwise$significant)))

