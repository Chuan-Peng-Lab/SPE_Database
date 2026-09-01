d <- read.csv("/tmp/wang_trials.csv", stringsAsFactors = FALSE)
d <- d[d$Practice == 0, ]
sw <- d[d$Phase == "Breaking", ]
sw$Matching <- ifelse(
  (sw$Exp == 1 & sw$Label == ifelse(sw$Identity == "Self", "Stranger", ifelse(sw$Identity == "Friend", "Self", "Friend"))) |
  (sw$Exp == 2 & sw$Label == ifelse(sw$Identity == "Self", "Friend", ifelse(sw$Identity == "Friend", "Stranger", "Self"))),
  "Matching", "Nonmatching")
rmF <- function(df, val, cond, subj) {
  df <- df[is.finite(df[[val]]), ]
  m <- aggregate(df[[val]], by = list(s = df[[subj]], c = df[[cond]]), FUN = mean)
  w <- reshape(m, idvar = "s", timevar = "c", direction = "wide")
  mat <- as.matrix(w[, -1]); n <- nrow(mat); k <- ncol(mat); GM <- mean(mat)
  SS_cond <- n * sum((colMeans(mat) - GM)^2); SS_subj <- k * sum((rowMeans(mat) - GM)^2)
  SS_sxc <- sum((mat - GM)^2) - SS_cond - SS_subj
  (SS_cond / (k - 1)) / (SS_sxc / ((k - 1) * (n - 1)))
}
e2m <- sw[sw$Exp == 2 & sw$Matching == "Matching", ]
subs <- sort(unique(e2m$Subject))
comb <- combn(subs, 20)
rt_dat <- e2m[e2m$ACC == 1 & e2m$RT > 0, c("Subject", "Label", "RT")]
er_dat <- e2m[, c("Subject", "Label", "ACC")]
rt_all <- numeric(ncol(comb)); er_all <- numeric(ncol(comb))
for (j in seq_len(ncol(comb))) {
  sel <- comb[, j]
  rt <- rt_dat[rt_dat$Subject %in% sel, ]
  er <- er_dat[er_dat$Subject %in% sel, ]; er$v <- as.numeric(er$ACC == 0 | is.na(er$ACC))
  rt_all[j] <- rmF(rt, "RT", "Label", "Subject")
  er_all[j] <- rmF(er, "v", "Label", "Subject")
}
cat("RT F: min", round(min(rt_all), 3), "max", round(max(rt_all), 3),
    "| closest to 17.35:", round(rt_all[which.min(abs(rt_all - 17.35))], 4),
    "subset:", comb[, which.min(abs(rt_all - 17.35))], "\n")
cat("err F: min", round(min(er_all), 3), "max", round(max(er_all), 3),
    "| closest to 3.93:", round(er_all[which.min(abs(er_all - 3.93))], 4),
    "subset:", comb[, which.min(abs(er_all - 3.93))], "\n")
cat("RT hits within 0.05 of 17.35:", sum(abs(rt_all - 17.35) < 0.05), "\n")
cat("err hits within 0.05 of 3.93:", sum(abs(er_all - 3.93) < 0.05), "\n")
