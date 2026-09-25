tukey_upper <- function(x, k = 1.5) {
  x <- sort(as.numeric(x)); n <- length(x)
  med_pos <- if (n %% 2 == 0) ((n/2) + (n+1)/2)/2 else (n+1)/2
  hinge <- (med_pos + 1)/2
  if (hinge == floor(hinge)) { q1 <- x[hinge]; q3 <- x[n-hinge+1]
  } else { h <- floor(hinge); q1 <- (x[h]+x[h+1])/2; q3 <- (x[n-h]+x[n-h+1])/2 }
  q1 <- floor(q1); q3 <- ceiling(q3); q3 + k*(q3-q1)
}
lst <- read.table("1_Data/Orellana-Corrales_2020_ExpPsych/Orellana-Corrales_2020_ExpPsych_Raw/3ke4f-osfstorage-archive/exp1_MT.lst", header=TRUE)
lst <- lst[!lst$Subject %in% c(19,20,23,28), ]
cat("作者 LST 整数均值：imRTmean 平均 =", mean(lst$imRTmean), "| fmRTmean 平均 =", mean(lst$fmRTmean), "\n")
# matching 单因素（配对 t -> F）
tt <- t.test(lst$fmRTmean, lst$imRTmean, paired = TRUE)
cat("LST 整数格 matching t =", tt$statistic, "| F =", tt$statistic^2, "（论文 F=50.73）\n")
# 用 LST 整数格跑完整 2×2（列序按 GLM 语法 im in fm fn）
long <- data.frame(
  Subject = factor(rep(lst$Subject, 4)),
  RT_ms = c(lst$imRTmean, lst$inRTmean, lst$fmRTmean, lst$fnRTmean),
  ShapeID = factor(rep(c("Self","Self","Stranger","Stranger"), each = nrow(lst)), levels=c("Self","Stranger")),
  Matching = factor(rep(c("Matching","Nonmatching","Matching","Nonmatching"), each = nrow(lst)), levels=c("Matching","Nonmatching")))
s <- summary(aov(RT_ms ~ ShapeID * Matching + Error(Subject/(ShapeID*Matching)), data = long))
print(s)
