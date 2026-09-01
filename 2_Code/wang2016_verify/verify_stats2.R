#!/usr/bin/env Rscript
# wang2016_verify/verify_stats2.R — 口径扫描：命中论文 F 即确认作者分析口径
suppressMessages({
  library(dplyr)
  library(tidyr)
})
d <- read.csv("/tmp/wang_trials.csv", stringsAsFactors = FALSE)
d <- d[d$Practice == 0, ]
sw <- d[d$Phase == "Breaking", ]
as <- d[d$Phase == "Association", ]
sw$Matching <- ifelse(
  (sw$Exp == 1 & sw$Label == ifelse(sw$Identity == "Self", "Stranger", ifelse(sw$Identity == "Friend", "Self", "Friend"))) |
  (sw$Exp == 2 & sw$Label == ifelse(sw$Identity == "Self", "Friend", ifelse(sw$Identity == "Friend", "Stranger", "Self"))),
  "Matching", "Nonmatching")

F_from_long <- function(long, val, cond, subj) {
  long <- long[is.finite(long[[val]]), ]
  fit <- aov(as.formula(paste(val, "~", cond, "+ Error(factor(", subj, ") / ", cond, ")")), data = long)
  summary(fit)[[2]][[1]]$`F value`[1]
}

# ---- 1. Exp1 留一：RT / errors / mismatch-errors / assoc-errors ----
cat("== Exp1 leave-one-out ==\n")
e1m <- sw[sw$Exp == 1 & sw$Matching == "Matching", ]
for (excl in sort(unique(e1m$Subject))) {
  dd <- e1m[e1m$Subject != excl, ]
  rt <- dd %>% filter(ACC == 1, RT > 0) %>% group_by(Subject, Label) %>% summarise(v = mean(RT), .groups = "drop")
  er <- dd %>% group_by(Subject, Label) %>% summarise(v = mean(ACC == 0), .groups = "drop")
  cat(sprintf("excl %2d: RT F=%6.2f  err F=%5.2f", excl, F_from_long(rt, "v", "Label", "Subject"),
              F_from_long(er, "v", "Label", "Subject")), "\n")
}
cat("all 21: RT F=43.02 err F=6.66 (基准)\n")

# ---- 2. Exp1 留一：mismatch 错误率 ----
e1mm <- sw[sw$Exp == 1 & sw$Matching == "Nonmatching", ]
cat("== Exp1 mismatch-errors leave-one-out (论文 F=1.66) ==\n")
for (excl in sort(unique(e1mm$Subject))) {
  dd <- e1mm[e1mm$Subject != excl, ]
  er <- dd %>% group_by(Subject, Identity) %>% summarise(v = mean(ACC == 0), .groups = "drop")
  cat(sprintf("excl %2d: F=%5.2f", excl, F_from_long(er, "v", "Identity", "Subject")), "\n")
}
er <- e1mm %>% group_by(Subject, Identity) %>% summarise(v = mean(ACC == 0), .groups = "drop")
cat("all: F=", F_from_long(er, "v", "Identity", "Subject"), "\n")

# ---- 3. Exp2 全 20 子集扫描 ----
cat("== Exp2 all-20-subsets scan (RT F=17.35, err F=3.93) ==\n")
e2m <- sw[sw$Exp == 2 & sw$Matching == "Matching", ]
subs <- sort(unique(e2m$Subject))
comb <- combn(subs, 20)
cat("n subsets:", ncol(comb), "\n")
rt_target <- 17.35; err_target <- 3.93
rt_hits <- list(); err_hits <- list()
rt_all <- numeric(ncol(comb)); err_all <- numeric(ncol(comb))
for (j in seq_len(ncol(comb))) {
  sel <- comb[, j]
  dd <- e2m[e2m$Subject %in% sel, ]
  rt <- dd %>% filter(ACC == 1, RT > 0) %>% group_by(Subject, Label) %>% summarise(v = mean(RT), .groups = "drop")
  er <- dd %>% group_by(Subject, Label) %>% summarise(v = mean(ACC == 0), .groups = "drop")
  fr <- F_from_long(rt, "v", "Label", "Subject"); fe <- F_from_long(er, "v", "Label", "Subject")
  rt_all[j] <- fr; err_all[j] <- fe
  if (abs(fr - rt_target) < 0.02) rt_hits[[length(rt_hits) + 1]] <- sel
  if (abs(fe - err_target) < 0.02) err_hits[[length(err_hits) + 1]] <- sel
}
cat("RT hit count (within .02 of 17.35):", length(rt_hits), "\n")
if (length(rt_hits)) print(rt_hits[[1]])
cat("err hit count (within .02 of 3.93):", length(err_hits), "\n")
if (length(err_hits)) print(err_hits[[1]])
cat("RT F range:", round(range(rt_all), 2), "| err F range:", round(range(err_all), 2), "\n")

# 同时看 20 子集中 RT 最接近 17.35 的
best <- which.min(abs(rt_all - rt_target))
cat("best RT subset:", comb[, best], "F=", round(rt_all[best], 3), "\n")
best2 <- which.min(abs(err_all - err_target))
cat("best err subset:", comb[, best2], "F=", round(err_all[best2], 3), "\n")

# ---- 4. Exp2 mismatch-errors / assoc-errors 全 20 子集 ----
cat("== Exp2 mismatch-errors 20-subsets (F=3.96) ==\n")
e2mm <- sw[sw$Exp == 2 & sw$Matching == "Nonmatching", ]
best3 <- Inf; best3s <- NULL
for (j in seq_len(ncol(comb))) {
  sel <- comb[, j]
  dd <- e2mm[e2mm$Subject %in% sel, ]
  er <- dd %>% group_by(Subject, Identity) %>% summarise(v = mean(ACC == 0), .groups = "drop")
  f <- F_from_long(er, "v", "Identity", "Subject")
  if (abs(f - 3.96) < abs(best3 - 3.96)) { best3 <- f; best3s <- sel }
}
cat("best:", round(best3, 3), "subset:", best3s, "\n")
cat("== Exp2 assoc-errors 20-subsets (F=0.02) ==\n")
e2a <- as[as$Exp == 2, ]
best4 <- Inf; best4s <- NULL
for (j in seq_len(ncol(comb))) {
  sel <- comb[, j]
  dd <- e2a[e2a$Subject %in% sel, ]
  er <- dd %>% group_by(Subject, Identity) %>% summarise(v = mean(ACC == 0), .groups = "drop")
  f <- F_from_long(er, "v", "Identity", "Subject")
  if (abs(f - 0.02) < abs(best4 - 0.02)) { best4 <- f; best4s <- sel }
}
cat("best:", round(best4, 3), "subset:", best4s, "\n")
