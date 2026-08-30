c3 <- read.csv("1_Data/Orellana-Corrales_2020_ExpPsych/Exp3/Orellana-Corrales_2020_ExpPsych_Exp3_Clean.csv")
tukey_upper <- function(x, k = 1.5) {
  x <- sort(as.numeric(x)); n <- length(x)
  med_pos <- if (n %% 2 == 0) ((n/2) + (n+1)/2)/2 else (n+1)/2
  hinge <- (med_pos + 1)/2
  if (hinge == floor(hinge)) { q1 <- x[hinge]; q3 <- x[n-hinge+1]
  } else { h <- floor(hinge); q1 <- (x[h]+x[h+1])/2; q3 <- (x[n-h]+x[n-h+1])/2 }
  q1 <- floor(q1); q3 <- ceiling(q3); q3 + k*(q3-q1)
}
agg3 <- function(k) {
  lims <- tapply(c3$RT_ms, c3$Subject, function(x) tukey_upper(x[!is.na(x)], k))
  keep <- !is.na(c3$RT_ms) & c3$RT_ms > 200 & c3$RT_ms < lims[as.character(c3$Subject)] & c3$ACC %in% 1
  dd <- c3[keep, ]
  dd$LabelID <- ifelse(dd$Label_Origin_Identity == "Ich", "Ich", "Fremder")
  agg <- aggregate(RT_ms ~ Subject + LabelID + Matching, dd, mean)
  agg$RT_ms <- round(agg$RT_ms)
  ids <- sort(unique(agg$Subject))
  f <- function(s, li, mt) { v <- agg$RT_ms[agg$Subject == s & agg$LabelID == li & agg$Matching == mt]; if (!length(v)) NA_real_ else v }
  data.frame(Subject = ids, im = sapply(ids, f, "Ich", "Matching"),
             inn = sapply(ids, f, "Ich", "Nonmatching"),
             fm = sapply(ids, f, "Fremder", "Matching"),
             fn = sapply(ids, f, "Fremder", "Nonmatching"))
}
run2x2 <- function(w, excl) {
  w <- w[!w$Subject %in% excl, ]
  long <- data.frame(
    Subject = factor(rep(w$Subject, 4)),
    RT_ms = c(w$im, w$inn, w$fm, w$fn),
    Ich = factor(rep(c("Ich","Ich","Fremder","Fremder"), each = nrow(w)), levels = c("Ich","Fremder")),
    MT = factor(rep(c("Matching","Nonmatching","Matching","Nonmatching"), each = nrow(w)), levels = c("Matching","Nonmatching")))
  s <- summary(aov(RT_ms ~ Ich * MT + Error(Subject/(Ich*MT)), data = long))
  fs <- unlist(lapply(s, function(z) { r <- z[[1]]; i <- grep("Ich|MT", rownames(r)); r[i, "F value"] }))
  c(shape = fs[grepl("Ich$", names(fs))], trial = fs[grepl("MT$", names(fs))],
    int = fs[grepl("Ich:MT", names(fs))])
}
w3 <- agg3(3); w3b <- agg3(1.5)
cat("Exp3 k=3  排除6/33:", paste(names(run2x2(w3, c(6,33))), round(run2x2(w3, c(6,33)), 2), collapse=" "), "\n")
cat("Exp3 k=1.5 排除6/33:", paste(names(run2x2(w3b, c(6,33))), round(run2x2(w3b, c(6,33)), 2), collapse=" "), "\n")
cat("论文 Exp3: shape 22.97 | trial 4.819 | int 28.88\n")

l2 <- read.table("1_Data/Orellana-Corrales_2020_ExpPsych/Orellana-Corrales_2020_ExpPsych_Raw/3ke4f-osfstorage-archive/exp2_MT.lst", header = TRUE)
subs <- l2$Subject
stats2 <- function(d) {
  tt <- t.test(d$fmRTmean, d$imRTmean, paired = TRUE)$statistic^2
  tn <- t.test(d$fnRTmean, d$inRTmean, paired = TRUE)$statistic^2
  dp <- sapply(1:nrow(d), function(i) {
    r <- d[i, ]
    c(qnorm((32 - r$imER + 0.5)/33) - qnorm((r$inER + 0.5)/33),
      qnorm((32 - r$fmER + 0.5)/33) - qnorm((r$fnER + 0.5)/33))
  })
  td <- t.test(dp[2, ], dp[1, ], paired = TRUE)$statistic^2
  c(match = tt, nonmatch = tn, dprime = td)
}
target <- c(match = 29.72, nonmatch = 2.67, dprime = 13.95)
best <- NULL
for (i in 1:(length(subs)-1)) for (j in (i+1):length(subs)) {
  d <- l2[!l2$Subject %in% c(subs[i], subs[j]), ]
  st <- stats2(d)
  err <- sum(abs(st - target))
  if (is.null(best) || err < best$err) best <- list(ij = c(subs[i], subs[j]), st = st, err = err)
}
cat("Exp2 最佳排除:", best$ij, "| F:", paste(round(best$st, 2), collapse=", "), "| 总差:", round(best$err, 3), "\n")
