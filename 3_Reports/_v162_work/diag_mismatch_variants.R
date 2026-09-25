# ============================================================================
# DIAGNOSTIC (not a deliverable): mismatch bootstrap under variants
#   A = v1 code as-is (Subject pooled across datasets)
#   B = unique subject key (Source|Subject)
#   C = B + RT sanity filter
# ============================================================================
suppressPackageStartupMessages({ library(data.table) })
setwd("D:/GitHub_programe/GitHub/SPE_Database/3_Reports")

N_BOOTSTRAP  <- 500
MIN_SAMPLE_N <- 10
STEP_N       <- 10
BOOT_SEED    <- 20260412
RT_MAX_MS    <- 10000
raw_data_dir <- "../1_Data"

files <- list.files(raw_data_dir, pattern = "_Clean\\.csv$", recursive = TRUE, full.names = TRUE)
read_one <- function(f) {
  h <- names(fread(f, nrows = 0))
  keep <- intersect(c("Subject", "RT_ms", "ACC", "Matching",
                      "Shape_Standardized_Identity", "Label_Standardized_Identity"), h)
  d <- fread(f, select = keep, showProgress = FALSE)
  d[, Source := basename(dirname(f))]
  d
}
merged <- rbindlist(lapply(files, read_one), fill = TRUE)
merged[, Subject := as.numeric(Subject)]
merged[, RT_ms := as.numeric(RT_ms)]
merged[, ACC := as.numeric(ACC)]
merged[, SubjKey := paste(Source, Subject, sep = "_")]
if (!"Label_Standardized_Identity" %in% names(merged))
  merged[, Label_Standardized_Identity := Shape_Standardized_Identity]

mm <- merged[Matching == "Nonmatching"]
cat(sprintf("mismatch rows=%d  datasets=%d\n", nrow(mm), uniqueN(mm$Source)))

cohens_d <- function(g1, g2) {
  n1 <- length(g1); n2 <- length(g2)
  if (n1 < 2 || n2 < 2) return(NA_real_)
  psd <- sqrt(((n1 - 1) * var(g1) + (n2 - 1) * var(g2)) / (n1 + n2 - 2))
  if (!is.finite(psd) || psd == 0) return(NA_real_)
  (mean(g1) - mean(g2)) / psd
}
filter_valid_subjects <- function(dt, id_col, subj_col) {
  dt[, .(ok = ("Self" %in% get(id_col)) && ("Stranger" %in% get(id_col)) &&
            uniqueN(na.omit(get(id_col))) >= 3), by = subj_col][ok == TRUE][[subj_col]]
}
process_data <- function(dt, analysis_type, approach, subj_col) {
  if (nrow(dt) == 0) return(dt[0])
  pri <- if (analysis_type == "Shape") "Shape_Standardized_Identity" else "Label_Standardized_Identity"
  sec <- if (analysis_type == "Shape") "Label_Standardized_Identity" else "Shape_Standardized_Identity"
  d <- copy(dt)
  d[, Primary := fifelse(get(pri) %in% c("Self", "Stranger"), get(pri), "Other")]
  d[, Secondary := fifelse(get(sec) %in% c("Self", "Stranger"), get(sec), "Other")]
  if (approach == "Conservative") {
    vs <- filter_valid_subjects(d, pri, subj_col)
    d <- d[get(subj_col) %in% vs]
    d <- d[Primary == "Self" | (Primary == "Stranger" & Secondary != "Self") | Primary == "Other"]
  } else {
    d <- d[Primary %in% c("Self", "Stranger")]
  }
  d
}
calc_subject_d <- function(dt, measure, subj_col, rt_filter) {
  if (rt_filter && measure == "RT") dt <- dt[!is.na(RT_ms) & RT_ms > 0 & RT_ms <= RT_MAX_MS]
  out <- list()
  for (k in unique(dt[[subj_col]])) {
    s <- dt[get(subj_col) == k]
    if (measure == "RT") {
      sv <- s[Primary == "Self" & ACC == 1, RT_ms]
      ov <- s[Primary == "Stranger" & ACC == 1, RT_ms]
    } else {
      sv <- s[Primary == "Self", ACC]
      ov <- s[Primary == "Stranger", ACC]
    }
    sv <- sv[!is.na(sv)]; ov <- ov[!is.na(ov)]
    if (length(sv) < 2 || length(ov) < 2) next
    d <- if (measure == "RT") cohens_d(ov, sv) else cohens_d(sv, ov)
    if (!is.na(d)) out[[length(out) + 1]] <- data.table(Subj = k, d = d)
  }
  rbindlist(out)
}
bootstrap_analysis <- function(v, n_boot = N_BOOTSTRAP, min_n = MIN_SAMPLE_N, step = STEP_N, max_n = NULL) {
  total_n <- length(v)
  if (total_n < min_n) return(data.table())
  if (is.null(max_n)) max_n <- total_n
  max_n <- min(max_n, total_n)
  ss <- seq(min_n, max_n, by = step)
  if (max_n %% step != 0 && !max_n %in% ss) ss <- c(ss, max_n)
  ss <- sort(unique(ss[ss <= total_n]))
  set.seed(BOOT_SEED)
  rbindlist(lapply(ss, function(n) {
    bm <- replicate(n_boot, mean(sample(v, size = n, replace = TRUE)))
    data.table(SampleSize = n, Mean_d = mean(bm),
               CI_lower = quantile(bm, .025, na.rm = TRUE),
               CI_upper = quantile(bm, .975, na.rm = TRUE))
  }))
}
first_excl <- function(s) {
  a <- s[CI_lower > 0]; b <- s[CI_upper < 0]
  if (nrow(a)) return(min(a$SampleSize))
  if (nrow(b)) return(min(b$SampleSize))
  NA_real_
}

variants <- list(A = list(subj = "Subject", rt = FALSE),
                 B = list(subj = "SubjKey", rt = FALSE),
                 C = list(subj = "SubjKey", rt = TRUE))
for (v in names(variants)) {
  cfg <- variants[[v]]
  cat(sprintf("\n########## variant %s (subj=%s rt_filter=%s) ##########\n", v, cfg$subj, cfg$rt))
  for (appr in c("Conservative", "Liberal")) {
    for (meas in c("RT", "ACC")) {
      sd_ <- process_data(mm, "Shape", appr, cfg$subj)
      ld_ <- process_data(mm, "Label", appr, cfg$subj)
      sc <- calc_subject_d(sd_, meas, cfg$subj, cfg$rt)
      lc <- calc_subject_d(ld_, meas, cfg$subj, cfg$rt)
      if (appr == "Conservative") {
        mx <- min(nrow(sc), nrow(lc)); kind <- "aligned"
      } else {
        mx <- NULL; kind <- "max"
      }
      for (nm in c("Shape", "Label")) {
        cc <- if (nm == "Shape") sc else lc
        bb <- if (appr == "Conservative") bootstrap_analysis(cc$d, max_n = mx) else bootstrap_analysis(cc$d)
        if (!nrow(bb)) { cat(sprintf("  %s %s %s: EMPTY\n", appr, meas, nm)); next }
        fin <- bb[SampleSize == max(SampleSize)]
        cat(sprintf("  %-12s %-3s %-5s | N=%4d d=%+.4f CI[%+.4f,%+.4f] firstExcl=%s | subj_d_n=%d\n",
                    appr, meas, nm, fin$SampleSize, fin$Mean_d, fin$CI_lower, fin$CI_upper,
                    ifelse(is.na(first_excl(bb)), "never", as.character(first_excl(bb))), nrow(cc)))
      }
    }
  }
}
cat("\nDONE\n")
