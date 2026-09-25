l2 <- read.table("1_Data/Orellana-Corrales_2020_ExpPsych/Orellana-Corrales_2020_ExpPsych_Raw/3ke4f-osfstorage-archive/exp2_MT.lst", header = TRUE)
l2 <- l2[!l2$Subject %in% c(24, 30), ]
cat("N =", nrow(l2), "（论文 df=30 → N=31 ✓）\n")
long <- data.frame(Subject = factor(rep(l2$Subject, 4)), RT_ms = c(l2$imRTmean, l2$inRTmean, l2$fmRTmean, l2$fnRTmean),
                   Ich = factor(rep(c("Ich","Ich","Fremder","Fremder"), each = nrow(l2)), levels=c("Ich","Fremder")),
                   MT = factor(rep(c("Matching","Nonmatching","Matching","Nonmatching"), each = nrow(l2)), levels=c("Matching","Nonmatching")))
print(summary(aov(RT_ms ~ Ich * MT + Error(Subject/(Ich*MT)), data = long)))
