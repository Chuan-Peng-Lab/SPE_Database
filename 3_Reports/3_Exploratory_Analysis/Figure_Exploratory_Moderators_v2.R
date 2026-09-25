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
library(dplyr)
library(ggplot2)
library(patchwork)


## ----paths--------------------------------------------------------------------
# ===========================================================================
# 路径设置（相对于 3_Reports/ 项目根目录）
# ===========================================================================
# Python v11 pipeline 输出：在 2026-09 数据库（89 个 Clean 文件）上重跑，
# 已排除 Pan_2025_unpub、Wang_2016_JEPHPP，并对 Stranger cohens_dz 做 |z|>3 离群剔除。
data_dir <- "../Datasets/8_Exploratory_Analysis/Output/11"

pic_dir      <- "Output/Pic"
data_out_dir <- "Output/data"

dir.create(pic_dir,      showWarnings = FALSE, recursive = TRUE)
dir.create(data_out_dir, showWarnings = FALSE, recursive = TRUE)


## ----load-data----------------------------------------------------------------
# ===========================================================================
# 1. 加载预计算的 visualization 数据（v11 pipeline）
# ===========================================================================
analysis_df <- read.csv(file.path(data_dir, "visualization_analysis_dataset.csv"),
                        stringsAsFactors = FALSE)
num_results <- read.csv(file.path(data_dir, "visualization_numeric_results.csv"),
                        stringsAsFactors = FALSE)
sensitivity <- read.csv(file.path(data_dir, "sensitivity_trial_number_exclude_top3.csv"),
                        stringsAsFactors = FALSE)
excluded    <- read.csv(file.path(data_dir, "excluded_datasets.csv"),
                        stringsAsFactors = FALSE)

# 仅保留 Stranger identity（防御性过滤，与 Python 一致）
analysis_df  <- analysis_df[analysis_df$comparison_identity == "Stranger", ]
num_results  <- num_results[num_results$comparison_identity == "Stranger", ]

cat(sprintf("分析数据: %d 行\n", nrow(analysis_df)))
cat(sprintf("数值结果: %d 行\n", nrow(num_results)))
print(num_results[, c("moderator", "measure", "n_datasets", "spearman_rho",
                      "spearman_p", "spearman_rho_boot_ci_lower",
                      "spearman_rho_boot_ci_upper", "spearman_rho_boot_p")])
cat("\n敏感性分析（trial number 去掉最大 3 个数据集）:\n")
print(sensitivity)
cat("\n被排除的数据集:\n")
print(excluded)


## ----constants----------------------------------------------------------------
# ===========================================================================
# 2. 绘图常量（APA 黑白/灰度）
# ===========================================================================
MEASURE_LABELS <- c("RT_ms" = "RT SPE (Cohen's dz)", "ACC" = "ACC SPE (Cohen's dz)")

PANEL_TITLES <- c(
  "stimulus_duration_ms_first_RT_ms" = "A. RT SPE by stimulus duration",
  "stimulus_duration_ms_first_ACC"   = "B. ACC SPE by stimulus duration",
  "trial_number_max_RT_ms"           = "C. RT SPE by trial number",
  "trial_number_max_ACC"             = "D. ACC SPE by trial number"
)

X_LABELS <- c(
  "stimulus_duration_ms_first" = "Stimulus presentation duration (ms)",
  "trial_number_max"           = "Maximum trial number"
)

apa_theme <- theme_classic(base_size = 15, base_family = "serif") +
  theme(
    plot.title = element_text(hjust = 0.5, face = "bold", size = 16),
    axis.title = element_text(face = "bold", size = 15),
    axis.text  = element_text(size = 14),
    axis.line  = element_line(color = "black", size = 0.6),
    axis.ticks = element_line(color = "black"),
    axis.ticks.length = unit(0.12, "cm"),
    plot.margin = margin(8, 8, 8, 8),
    panel.grid = element_blank()
  )


## ----panel-function-----------------------------------------------------------
# ===========================================================================
# 3. 单面板绘图函数（黑白/灰度）
# ===========================================================================
draw_panel_ggplot <- function(raw_df, measure, is_duration, title) {
  x <- raw_df$moderator_value
  x_min <- floor((min(x) - 20) / 100) * 100
  x_max <- ceiling((max(x) + 20) / 100) * 100
  if (x_max <= x_min) x_max <- x_min + 100

  x_grid <- seq(x_min, x_max, length.out = 120)
  fit  <- lm(cohens_dz ~ moderator_value, data = raw_df)
  pred <- predict(fit, newdata = data.frame(moderator_value = x_grid),
                  interval = "confidence", level = 0.95)
  line_df <- data.frame(x = x_grid, y = pred[, "fit"],
                        lwr = pred[, "lwr"], upr = pred[, "upr"])

  ggplot(raw_df, aes(x = moderator_value, y = cohens_dz)) +
    geom_ribbon(data = line_df, aes(x = x, ymin = lwr, ymax = upr),
                inherit.aes = FALSE, fill = "grey85", alpha = 0.55) +
    geom_line(data = line_df, aes(x = x, y = y), inherit.aes = FALSE,
              color = "black", size = 0.8) +
    geom_point(color = "black", size = 2.1, alpha = 0.65) +
    geom_hline(yintercept = 0, color = "grey50", linetype = "dashed", size = 0.45) +
    coord_cartesian(xlim = c(x_min, x_max)) +
    labs(title = title,
         x = X_LABELS[[if (is_duration) "stimulus_duration_ms_first" else "trial_number_max"]],
         y = MEASURE_LABELS[[measure]]) +
    apa_theme
}


## ----build-panels-------------------------------------------------------------
# ===========================================================================
# 4. 构建四个面板
# ===========================================================================
specs <- list(
  list(mod = "stimulus_duration_ms_first", meas = "RT_ms", dur = TRUE),
  list(mod = "stimulus_duration_ms_first", meas = "ACC",   dur = TRUE),
  list(mod = "trial_number_max",           meas = "RT_ms", dur = FALSE),
  list(mod = "trial_number_max",           meas = "ACC",   dur = FALSE)
)

panel_n <- sapply(specs, function(s) {
  nrow(analysis_df[analysis_df$moderator_name == s$mod & analysis_df$measure == s$meas, ])
})
cat("各面板数据点:", paste(panel_n, collapse = ", "), "\n")

panels <- lapply(specs, function(s) {
  raw <- analysis_df[analysis_df$moderator_name == s$mod & analysis_df$measure == s$meas, ]
  key <- paste0(s$mod, "_", s$meas)
  draw_panel_ggplot(raw, s$meas, s$dur, PANEL_TITLES[[key]])
})
names(panels) <- sapply(specs, function(s) paste0(s$mod, "_", s$meas))


## ----combined-figure----------------------------------------------------------
# ===========================================================================
# 5. 2×2 组合图
# ===========================================================================
combined <- (panels[["stimulus_duration_ms_first_RT_ms"]] |
             panels[["stimulus_duration_ms_first_ACC"]]) /
            (panels[["trial_number_max_RT_ms"]] |
             panels[["trial_number_max_ACC"]])

combined_path <- file.path(pic_dir, "Figure_Exploratory_Moderators_Main_v2.png")
ggsave(combined_path, combined, width = 12, height = 8, dpi = 300)
cat("\n组合图已保存:", combined_path, "\n")


## ----individual-figures-------------------------------------------------------
# ===========================================================================
# 6. 四张单面板图
# ===========================================================================
indiv_specs <- list(
  list(name = "Figure_StimulusDuration_RT_Stranger_v2.png",  mod = "stimulus_duration_ms_first", meas = "RT_ms"),
  list(name = "Figure_StimulusDuration_ACC_Stranger_v2.png", mod = "stimulus_duration_ms_first", meas = "ACC"),
  list(name = "Figure_TrialNumber_RT_Stranger_v2.png",       mod = "trial_number_max",           meas = "RT_ms"),
  list(name = "Figure_TrialNumber_ACC_Stranger_v2.png",      mod = "trial_number_max",           meas = "ACC")
)

for (s in indiv_specs) {
  key <- paste0(s$mod, "_", s$meas)
  ggsave(file.path(pic_dir, s$name), panels[[key]], width = 6, height = 4.5, dpi = 300)
  cat("已保存:", s$name, "\n")
}


## ----captions-----------------------------------------------------------------
# ===========================================================================
# 7. 图注（统计量移出图内，供正文图注使用）
# ===========================================================================
caption_rows <- num_results %>%
  mutate(
    panel = case_when(
      moderator == "stimulus_duration_ms_first" & measure == "RT_ms" ~ "A",
      moderator == "stimulus_duration_ms_first" & measure == "ACC"   ~ "B",
      moderator == "trial_number_max"           & measure == "RT_ms" ~ "C",
      moderator == "trial_number_max"           & measure == "ACC"   ~ "D",
      TRUE ~ NA_character_
    ),
    caption = sprintf(
      "n = %d; Spearman \u03C1 = %.3f, p = %.3f; bootstrap 95%% CI [%.3f, %.3f]; p_boot = %.4f",
      n_datasets, spearman_rho, spearman_p,
      spearman_rho_boot_ci_lower, spearman_rho_boot_ci_upper, spearman_rho_boot_p
    ),
    note = sprintf("Excluded %s; |z|>3 outliers removed from Stranger Cohen's dz.",
                   paste(excluded$dataset_id, collapse = ", "))
  ) %>%
  arrange(panel)

print(caption_rows[, c("panel", "caption")], row.names = FALSE)
write.csv(caption_rows, file.path(data_out_dir, "exploratory_figure_captions_v2.csv"),
          row.names = FALSE)
cat("\n图注已保存:", file.path(data_out_dir, "exploratory_figure_captions_v2.csv"), "\n")

sens_out <- sensitivity %>%
  mutate(caption = sprintf("n = %d; Spearman \u03C1 = %.3f, p = %.3f",
                           n_datasets, spearman_rho, spearman_p))
write.csv(sens_out, file.path(data_out_dir, "exploratory_sensitivity_v2.csv"),
          row.names = FALSE)
cat("敏感性分析已保存: Output/data/exploratory_sensitivity_v2.csv\n")

