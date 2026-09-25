#!/usr/bin/env Rscript
# ============================================================================
# 2_Code/hobbs_verify/verify_stats.R — Hobbs_2023_PsychMed 论文统计量复现
# ----------------------------------------------------------------------------
# 复现论文 Table 2（Associative Learning Task 与抑郁的线性回归）：
#   "Results from linear regression models examining the association between
#   accuracy and reaction times for each task condition (predictors) in the
#   associative learning task with depression (Outcome: PHQ-9/BDI-II)"
# 模型（作者 Analysis Rmd 口径，如 assoc_self_acc_PHQ_model）：
#   lm(outcome ~ prop_acc_<3 stimuli> | mean_rt_<3 stimuli>)，每 Task 独立；
#   β = 变量标准化后重拟合的系数（standardize_parameters method="refit"）。
# 数据：作者 associative_long_matching_collapsed_anon.csv（库内数据重算聚合
#   已与之一致，见 verify_trial.py；PHQ_tot/BDI_tot 来自 qs session 2，问卷
#   不在库内范围，直接取作者合并值）。
# 用法：Rscript verify_stats.R [--root DIR]
# ============================================================================
args <- commandArgs(trailingOnly = TRUE)
root <- if (length(args) && args[1] != "--root") args[1] else getwd()
if (grepl("^--root=", args[1])) root <- sub("^--root=", "", args[1])
coll_path <- file.path(root, "1_Data", "Hobbs_2023_PsychMed",
                       "Hobbs_2023_PsychMed_raw", "Aggregated Data for Analysis",
                       "Data", "Associative Learning",
                       "associative_long_matching_collapsed_anon.csv")
stopifnot(file.exists(coll_path))
coll <- read.csv(coll_path, stringsAsFactors = FALSE, check.names = FALSE)

# ---- 宽化：每被试×每任务一行，3 刺激的 prop_acc / mean_rt_mult ----
wide <- reshape(coll[, c("subject", "Task", "stimuli", "prop_acc",
                         "mean_rt_mult")],
                idvar = c("subject", "Task"), timevar = "stimuli",
                direction = "wide")
stopifnot(nrow(wide) == 144 * 3)   # PHQ/BDI 个别 NA（问卷缺失）由 lm 剔除
phq <- coll[!duplicated(coll$subject), c("subject", "PHQ_tot", "BDI_tot")]
wide <- merge(wide, phq, by = "subject")
stopifnot(nrow(wide) == 144 * 3)

# 论文 Table 2 值（供打印对比）
paper <- list(
  Self = list(ACC = data.frame(
      var = c("Intercept", "Self", "Friend", "Stranger"),
      PHQ_b = c(11.44, -0.06, -0.04, 0.05), BDI_b = c(14.51, -0.15, 0.03, 0.11)),
    RT = data.frame(
      var = c("Intercept", "Self", "Friend", "Stranger"),
      PHQ_b = c(11.50, 0.00, -0.01, 0.00), BDI_b = c(24.45, 0.00, -0.04, 0.02))),
  Reward = list(ACC = data.frame(
      var = c("Intercept", "High (£9)", "Medium (£3)", "Low (£1)"),
      PHQ_b = c(6.07, -0.06, 0.10, -0.03), BDI_b = c(8.59, -0.19, 0.24, 0.02)),
    RT = data.frame(
      var = c("Intercept", "High (£9)", "Medium (£3)", "Low (£1)"),
      PHQ_b = c(4.53, 0.01, -0.01, 0.00), BDI_b = c(7.89, 0.03, -0.01, -0.01))),
  Valence = list(ACC = data.frame(
      var = c("Intercept", "Happy", "Neutral", "Sad"),
      PHQ_b = c(6.05, -0.02, 0.03, 0.01), BDI_b = c(10.72, -0.05, 0.06, 0.04)),
    RT = data.frame(
      var = c("Intercept", "Happy", "Neutral", "Sad"),
      PHQ_b = c(7.51, 0.01, 0.00, 0.00), BDI_b = c(14.33, 0.00, 0.00, 0.00)))
)

task_map <- list(Self = "Self", Reward = "Reward", Valence = "Valence")
stim_order <- list(Self = c("Self", "Friend", "Stranger"),
                   Reward = c("£9", "£3", "£1"),
                   Valence = c("Happy", "Neutral", "Sad"))
# 论文 Table 2 标签（Reward 行用 "High (£9)" 等表述）
paper_label <- list(Self = c("Intercept", "Self", "Friend", "Stranger"),
                    Reward = c("Intercept", "High (£9)", "Medium (£3)",
                               "Low (£1)"),
                    Valence = c("Intercept", "Happy", "Neutral", "Sad"))
ok_all <- TRUE
for (task in names(task_map)) {
  d <- wide[wide$Task == task_map[[task]], ]
  for (metric in c("ACC", "RT")) {
    preds <- paste0(ifelse(metric == "ACC", "prop_acc.", "mean_rt_mult."),
                    stim_order[[task]])
    for (outcome in c("PHQ_tot", "BDI_tot")) {
      f <- as.formula(paste0(outcome, " ~ ",
                             paste(paste0("`", preds, "`"), collapse = " + ")))
      m <- lm(f, data = d)
      b <- coef(m)
      # 标准化 β（refit：全部变量 scale 后重拟合）
      ds <- as.data.frame(lapply(d[, c(outcome, preds)], scale))
      names(ds) <- c(outcome, preds)   # lapply 会 make.names（£→.），恢复原列名
      ms <- lm(as.formula(paste0(outcome, " ~ ",
                                 paste(paste0("`", preds, "`"),
                                       collapse = " + "))), data = ds)
      beta <- coef(ms)
      ref <- paper[[task]][[metric]]
      pvar <- if (metric == "ACC") paste0("prop_acc.", stim_order[[task]])
              else paste0("mean_rt_mult.", stim_order[[task]])
      refv <- c("(Intercept)", pvar)
      # coef 名规则：合法列名反引号被剥（prop_acc.Self），非法名保留
      # （`prop_acc.£9`）→ 两种都试
      coef_at <- function(nm, v) {
        if (nm %in% names(v)) return(unname(v[[nm]]))
        unname(v[[paste0("`", nm, "`")]])
      }
      bv <- sapply(refv, coef_at, v = b)
      betav <- sapply(refv, coef_at, v = beta)
      cat(sprintf("\n[%s | %s | %s]\n", task, metric,
                  ifelse(outcome == "PHQ_tot", "PHQ-9", "BDI-II")))
      for (i in seq_along(refv)) {
        lab <- paper_label[[task]][i]
        pb <- ref$PHQ_b[ref$var == lab]
        if (outcome == "BDI_tot") pb <- ref$BDI_b[ref$var == lab]
        match_b <- abs(bv[i] - pb) < 0.011   # 论文保留两位小数
        if (!match_b) ok_all <<- FALSE
        cat(sprintf("  %-12s paper b=%6.2f | ours b=%6.3f  %s\n",
                    lab, pb, bv[i],
                    ifelse(match_b, "OK", "*** MISMATCH ***")))
      }
    }
  }
}
cat("\n===== 复现结论：", ifelse(ok_all, "Table 2 全部 b 系数与论文一致（±0.011）",
                             "存在不一致，见上方 *** MISMATCH ***"), "=====\n")
if (!ok_all) quit(status = 1)
