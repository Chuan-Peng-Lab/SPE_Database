# ============================================================================
# DIAGNOSTIC (not a deliverable): identity/baseline analysis under variants
#   A = v1 code as-is        (Subject as-is, no RT sanity filter, ACC raw)
#   B = + unique subject id  (Source|Subject nesting)
#   C = + RT sanity filter   (RT_ms in (0, 10000], non-missing)
#   D = + ACC restricted to {0,1}
# ============================================================================
suppressPackageStartupMessages({
  library(data.table)
  library(lme4)
  library(MASS)
})

setwd("D:/GitHub_programe/GitHub/SPE_Database/3_Reports")

IDENTITY_ORDER <- c("NonPerson", "Stranger", "Celebrity", "Acquaintance", "Close")
BOOTSTRAP_N    <- 10000
BOOTSTRAP_SEED <- 20260412
RT_MAX_MS      <- 10000   # sanity cap for RT in ms

raw_data_dir <- "../1_Data"
files <- list.files(raw_data_dir, pattern = "_Clean\\.csv$", recursive = TRUE, full.names = TRUE)
cat(sprintf("files: %d\n", length(files)))

read_one <- function(f) {
  head1 <- names(fread(f, nrows = 0))
  keep <- intersect(c("Subject", "RT_ms", "ACC",
                      "Shape_Standardized_Identity", "Label_Standardized_Identity"), head1)
  d <- fread(f, select = keep, showProgress = FALSE)
  d[, Source := tools::file_path_sans_ext(basename(f))]
  d
}
merged <- rbindlist(lapply(files, read_one), fill = TRUE)
cat(sprintf("merged rows=%d  datasets=%d\n", nrow(merged), uniqueN(merged$Source)))
merged[, Subject := as.numeric(Subject)]
merged[, RT_ms := as.numeric(RT_ms)]
merged[, ACC := as.numeric(ACC)]
merged[, SubjKey := paste(Source, Subject, sep = "_")]

calc_d <- function(g1, g2) {
  n1 <- length(g1); n2 <- length(g2)
  if (n1 < 2 || n2 < 2) return(NA_real_)
  psd <- sqrt(((n1 - 1) * var(g1) + (n2 - 1) * var(g2)) / (n1 + n2 - 2))
  if (!is.finite(psd) || psd == 0) return(NA_real_)
  (mean(g1) - mean(g2)) / psd
}

compute <- function(dt, measure, subj_col, rt_filter = FALSE, acc_filter = FALSE) {
  dt <- copy(dt)
  if (measure == "RT" && rt_filter) {
    dt <- dt[!is.na(RT_ms) & RT_ms > 0 & RT_ms <= RT_MAX_MS]
  }
  if (measure == "ACC" && acc_filter) {
    dt <- dt[!is.na(ACC) & ACC %in% c(0, 1)]
  }
  out <- list()
  for (k in unique(dt[[subj_col]])) {
    s <- dt[get(subj_col) == k]
    if (measure == "RT") {
      self_v <- s[Shape_Standardized_Identity == "Self" & ACC == 1, RT_ms]
    } else {
      self_v <- s[Shape_Standardized_Identity == "Self", ACC]
    }
    self_v <- self_v[!is.na(self_v)]
    if (length(self_v) < 2) next
    for (id in IDENTITY_ORDER) {
      if (measure == "RT") {
        oth <- s[Shape_Standardized_Identity == id & ACC == 1, RT_ms]
      } else {
        oth <- s[Shape_Standardized_Identity == id, ACC]
      }
      oth <- oth[!is.na(oth)]
      if (length(oth) < 2) next
      d <- if (measure == "RT") calc_d(oth, self_v) else calc_d(self_v, oth)
      if (!is.na(d)) {
        out[[length(out) + 1]] <- data.table(
          Subj = k, Source = s$Source[1], Identity = id,
          Cohens_d = d, n_Self = length(self_v), n_Other = length(oth))
      }
    }
  }
  rbindlist(out)
}

run_model <- function(res) {
  res <- copy(res)
  res[, Identity := factor(Identity, levels = IDENTITY_ORDER, ordered = TRUE)]
  res[, Source := factor(Source)]
  res[, Subj := factor(Subj)]
  m <- lmer(Cohens_d ~ 0 + Identity + (1 | Subj) + (1 | Source), data = res, REML = FALSE)
  fx <- fixef(m); V <- as.matrix(vcov(m))
  set.seed(BOOTSTRAP_SEED)
  sm <- mvrnorm(BOOTSTRAP_N, mu = fx, Sigma = V)
  colnames(sm) <- names(fx)
  list(model = m, samples = sm, res = res)
}

pairwise <- function(sm) {
  rows <- list()
  for (i in seq_len(length(IDENTITY_ORDER) - 1)) {
    for (j in (i + 1):length(IDENTITY_ORDER)) {
      a <- IDENTITY_ORDER[i]; b <- IDENTITY_ORDER[j]
      dv <- sm[, paste0("Identity", a)] - sm[, paste0("Identity", b)]
      q <- quantile(dv, c(.025, .5, .975))
      pl <- mean(dv <= 0); pr <- mean(dv >= 0)
      rows[[length(rows) + 1]] <- data.table(A = a, B = b, diff = mean(dv),
        lo = q[1], hi = q[3], p = min(1, 2 * min(pl, pr)))
    }
  }
  rbindlist(rows)
}

variants <- list(
  A = list(subj = "Subject", rt = FALSE, acc = FALSE),
  B = list(subj = "SubjKey", rt = FALSE, acc = FALSE),
  C = list(subj = "SubjKey", rt = TRUE,  acc = FALSE),
  D = list(subj = "SubjKey", rt = TRUE,  acc = TRUE)
)

allres <- list()
for (v in names(variants)) {
  cfg <- variants[[v]]
  for (meas in c("RT", "ACC")) {
    res <- compute(merged, meas, cfg$subj, cfg$rt, cfg$acc)
    fit <- run_model(res)
    means <- colMeans(fit$samples)
    names(means) <- sub("^Identity", "", names(means))
    pw <- pairwise(fit$samples)
    cat(sprintf("\n===== variant %s | %s | rows=%d | unique subj=%d =====\n",
                v, meas, nrow(res), uniqueN(res$Subj)))
    cat("  identity means:", paste(sprintf("%s=%.3f", names(means), means), collapse = "  "), "\n")
    cat("  pairwise (|diff|):\n")
    for (r in seq_len(nrow(pw))) {
      cat(sprintf("    %-13s vs %-13s  d=%+.3f  CI[%+.3f,%+.3f]  p=%.3f\n",
                  pw$A[r], pw$B[r], pw$diff[r], pw$lo[r], pw$hi[r], pw$p[r]))
    }
    allres[[paste(v, meas, sep = "_")]] <- list(means = means, pw = pw, n = nrow(res))
  }
}

saveRDS(allres, "Output/data/_diag_identity_variants.rds")
cat("\nDONE\n")
