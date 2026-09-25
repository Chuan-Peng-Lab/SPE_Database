l1 <- read.table("1_Data/Orellana-Corrales_2020_ExpPsych/Orellana-Corrales_2020_ExpPsych_Raw/3ke4f-osfstorage-archive/exp1_MT.lst", header = TRUE)
l1 <- l1[!l1$Subject %in% c(19,20,23,28), ]
tn <- t.test(l1$fnRTmean, l1$inRTmean, paired = TRUE)
cat("Exp1 nonmatching F =", round(tn$statistic^2, 2), "| means:", round(mean(l1$inRTmean),2), round(mean(l1$fnRTmean),2), "（论文 7.68 / 806.88 / 858.12）\n")
dp <- sapply(1:nrow(l1), function(i) {
  r <- l1[i, ]
  c(qnorm((32 - r$imER + 0.5)/33) - qnorm((r$inER + 0.5)/33),
    qnorm((32 - r$fmER + 0.5)/33) - qnorm((r$fnER + 0.5)/33))
})
td <- t.test(dp[2, ], dp[1, ], paired = TRUE)
cat("Exp1 d' F =", round(td$statistic^2, 2), "（论文 28.95）\n")
