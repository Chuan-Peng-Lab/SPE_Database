#!/usr/bin/env Rscript
# wang2016_verify/verify_stats.R — Wang 2016 JEPHPP 论文统计量复现（§7-4）
# 数据源：/tmp/wang_trials.csv（由 verify_merge_vs_csv.py 的解析函数从 txt 导出）
# 目标（论文正文）：
#   Exp1: association 错误 F(2,38)=3.35；switch match 错误 F=7.65、match RT F=43.29；
#         mismatch 错误 F=1.66；control 对比 F(1,40)/F(2,80)/F(2,80)=4.08；control 错误 F(2,42)=1.66、RT F(2,42)=2.75
#   Exp2: association 错误 F(2,38)=0.02；switch match 错误 F=3.93、RT F=17.35；mismatch 错误 F=3.96
# 方法：被试内单因素(association: self/friend/stranger) RM-ANOVA；RT 用正确试次均值；
#       错误率 = 该条件下 ACC==0 比例（无反应计错 vs 不计错两口径试配）。
# 只输出 F 值；命中论文值即确认口径。
suppressMessages({
  library(dplyr)
  library(tidyr)
})
d <- read.csv("/tmp/wang_trials.csv", stringsAsFactors = FALSE)
d <- d[d$Practice == 0, ]

rm_anova <- function(df, val_col, subj_col = "Subject", cond_col = "Label") {
  # 返回单因素 RM-ANOVA 的 F(2, n-1)
  wide <- df %>%
    select(!!sym(subj_col), !!sym(cond_col), !!val_col) %>%
    tidyr::pivot_wider(names_from = !!sym(cond_col), values_from = !!val_col) %>%
    as.data.frame()
  n <- nrow(wide)
  # 长格式 aov
  long <- df %>% select(!!sym(subj_col), !!sym(cond_col), !!val_col)
  fit <- aov(as.formula(paste(val_col, "~", cond_col, "+ Error(factor(", subj_col, ") / ", cond_col, ")")), data = long)
  s <- summary(fit)[[2]][[1]]
  Fval <- s$`F value`[1]
  c(F = Fval, n = n, df1 = 2, df2 = n - 1)
}

sw <- d[d$Phase == "Breaking", ]
as <- d[d$Phase == "Association", ]
mk <- function(df) df[df$Matching == "Matching", ]

# 重新计算 Matching（规则 B）
sw$Matching <- ifelse(
  (sw$Exp == 1 & sw$Label == ifelse(sw$Identity == "Self", "Stranger", ifelse(sw$Identity == "Friend", "Self", "Friend"))) |
  (sw$Exp == 2 & sw$Label == ifelse(sw$Identity == "Self", "Friend", ifelse(sw$Identity == "Friend", "Stranger", "Self"))),
  "Matching", "Nonmatching")

cat("== Exp1 switch match 错误率（无反应=错） ==\n")
e1m <- mk(sw[sw$Exp == 1, ])
e1_err <- e1m %>% group_by(Subject, Label) %>% summarise(err = mean(ACC == 0 | is.na(ACC)), .groups = "drop")
print(rm_anova(e1_err, "err"))
cat("== Exp1 switch match 错误率（无反应不计） ==\n")
e1_err2 <- e1m %>% filter(!is.na(ACC)) %>% group_by(Subject, Label) %>% summarise(err = mean(ACC == 0), .groups = "drop")
print(rm_anova(e1_err2, "err"))

cat("== Exp1 switch match RT（正确试次，无剔除） ==\n")
e1_rt <- e1m %>% filter(ACC == 1, !is.na(RT), RT > 0) %>% group_by(Subject, Label) %>% summarise(rt = mean(RT), .groups = "drop")
print(rm_anova(e1_rt, "rt"))

cat("== Exp1 switch match RT（正确试次，RT>200 & <1500） ==\n")
e1_rt2 <- e1m %>% filter(ACC == 1, !is.na(RT), RT > 200, RT < 1500) %>% group_by(Subject, Label) %>% summarise(rt = mean(RT), .groups = "drop")
print(rm_anova(e1_rt2, "rt"))
cat("== Exp1 switch match RT（正确试次，RT>200 & <2000） ==\n")
e1_rt3 <- e1m %>% filter(ACC == 1, !is.na(RT), RT > 200, RT < 2000) %>% group_by(Subject, Label) %>% summarise(rt = mean(RT), .groups = "drop")
print(rm_anova(e1_rt3, "rt"))

cat("== Exp2 switch match 错误率（无反应=错） ==\n")
e2m <- mk(sw[sw$Exp == 2, ])
e2_err <- e2m %>% group_by(Subject, Label) %>% summarise(err = mean(ACC == 0 | is.na(ACC)), .groups = "drop")
print(rm_anova(e2_err, "err"))
cat("== Exp2 switch match RT（正确试次，无剔除） ==\n")
e2_rt <- e2m %>% filter(ACC == 1, !is.na(RT), RT > 0) %>% group_by(Subject, Label) %>% summarise(rt = mean(RT), .groups = "drop")
print(rm_anova(e2_rt, "rt"))
cat("== Exp2 switch match RT（正确试次，RT>200 & <1500） ==\n")
e2_rt2 <- e2m %>% filter(ACC == 1, !is.na(RT), RT > 200, RT < 1500) %>% group_by(Subject, Label) %>% summarise(rt = mean(RT), .groups = "drop")
print(rm_anova(e2_rt2, "rt"))

cat("== Exp1 association 错误率（无反应=错） ==\n")
e1a <- as[as$Exp == 1, ]
e1a_err <- e1a %>% group_by(Subject, Identity) %>% summarise(err = mean(ACC == 0 | is.na(ACC)), .groups = "drop")
print(rm_anova(e1a_err, "err", cond_col = "Identity"))
cat("== Exp2 association 错误率（无反应=错） ==\n")
e2a <- as[as$Exp == 2, ]
e2a_err <- e2a %>% group_by(Subject, Identity) %>% summarise(err = mean(ACC == 0 | is.na(ACC)), .groups = "drop")
print(rm_anova(e2a_err, "err", cond_col = "Identity"))

cat("== Exp1 switch mismatch 错误率（无反应=错） ==\n")
e1mm <- sw[sw$Exp == 1 & sw$Matching == "Nonmatching", ]
e1mm_err <- e1mm %>% group_by(Subject, Identity) %>% summarise(err = mean(ACC == 0 | is.na(ACC)), .groups = "drop")
print(rm_anova(e1mm_err, "err", cond_col = "Identity"))
cat("== Exp2 switch mismatch 错误率（无反应=错） ==\n")
e2mm <- sw[sw$Exp == 2 & sw$Matching == "Nonmatching", ]
e2mm_err <- e2mm %>% group_by(Subject, Identity) %>% summarise(err = mean(ACC == 0 | is.na(ACC)), .groups = "drop")
print(rm_anova(e2mm_err, "err", cond_col = "Identity"))
