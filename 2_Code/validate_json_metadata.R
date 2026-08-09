#!/usr/bin/env Rscript
# =============================================================================
# validate_json_metadata.R
#
# Validate SPE_Database JSON metadata files against the naming conventions
# documented in README.md:
#
#   paper-level:      <Author>_<Year>_<Journal>.json
#                     - filename stem  == folder name
#                     - internal "Year" field matches the year in the name
#   experiment-level: <Author>_<Year>_<Journal>_Exp<N>.json
#                     - top-level JSON key == "exp<N>" (matches _Exp<N> suffix)
#   all JSON filenames must be pure ASCII (no diacritics such as ä / ź)
#
# Usage:
#   Rscript validate_json_metadata.R [path/to/1_Data]
#
# Defaults to 1_Data relative to this script (i.e. ../1_Data when run from
# 2_Code/). Prints a report and exits non-zero if any violation is found.
# Run after adding or renaming any study metadata.
# =============================================================================

suppressPackageStartupMessages(library(jsonlite))

# --- resolve data directory ---------------------------------------------------
args <- commandArgs(trailingOnly = TRUE)
if (length(args) >= 1) {
  data_dir <- normalizePath(args[1], mustWork = TRUE)
} else {
  file_args <- commandArgs(FALSE)
  flag <- grep("^--file=", file_args)
  script <- if (length(flag)) sub("^--file=", "", file_args[flag[1]]) else "validate_json_metadata.R"
  data_dir <- normalizePath(file.path(dirname(script), "..", "1_Data"), mustWork = TRUE)
}
stopifnot(dir.exists(data_dir))

# --- helpers -------------------------------------------------------------------
is_ascii <- function(x) !is.na(iconv(x, from = "UTF-8", to = "ASCII", sub = NA))

year_in <- function(x) {
  m <- regmatches(x, regexpr("(18|19|20)[0-9]{2}", x))
  if (length(m)) m[[1]] else NA_character_
}

violations <- character(0)
report <- function(fmt, ...) violations <<- c(violations, sprintf(fmt, ...))

# --- collect JSON files (skip AppleDouble sidecars) ----------------------------
json_files <- list.files(data_dir, pattern = "\\.json$",
                         recursive = TRUE, full.names = TRUE)
json_files <- json_files[!grepl("/\\._", json_files)]
if (!length(json_files)) {
  cat("No JSON files found under", data_dir, "\n")
  quit(status = 1)
}

for (f in sort(json_files)) {
  rel    <- sub(paste0("^", normalizePath(data_dir), "/"), "", f)
  folder <- basename(dirname(f))
  stem   <- sub("\\.json$", "", basename(f))

  # 1) ASCII-only filenames ----------------------------------------------------
  if (!is_ascii(basename(f)))
    report("NON-ASCII FILENAME: %s (rename to ASCII, e.g. drop diacritics)", rel)

  # 2) top-level folder vs filename year drift ---------------------------------
  #    the study root is the first path component under 1_Data
  parts <- strsplit(rel, .Platform$file.sep, fixed = TRUE)[[1]]
  study <- parts[1]

  # 3) parse JSON ---------------------------------------------------------------
  parsed <- tryCatch(fromJSON(f, simplifyVector = FALSE),
                     error = function(e) NULL)
  if (is.null(parsed)) {
    report("UNPARSEABLE JSON: %s (%s)", rel,
           sub("\n.*", "", sub("^.*: ", "", tryCatch({fromJSON(f); ""},
                 error = function(e) conditionMessage(e)))))
    next
  }

  exp_match <- regmatches(stem, regexpr("_Exp[0-9]+(\\.[0-9]+)?$", stem))
  is_exp <- length(exp_match) > 0 && startsWith(stem, study)

  if (!is_exp) {
    # ---- paper-level file ----------------------------------------------------
    if (stem != study)
      report("PAPER NAME DRIFT: %s (stem '%s' != study folder '%s')", rel, stem, study)

    yr_stem   <- year_in(stem)
    yr_folder <- year_in(study)
    yr_field  <- parsed$Year
    yr_ok <- !is.null(yr_field) && length(yr_field) == 1L &&
             !is.na(yr_field) && nzchar(as.character(yr_field))
    if (!yr_ok) {
      report("PAPER MISSING YEAR FIELD: %s", rel)
    } else {
      yr_field <- as.character(yr_field)
      if (!is.na(yr_folder) && yr_field != yr_folder)
        report("PAPER YEAR MISMATCH: %s (Year field '%s' != folder year '%s')",
               rel, yr_field, yr_folder)
      else if (!is.na(yr_stem) && yr_field != yr_stem)
        report("PAPER YEAR MISMATCH: %s (Year field '%s' != filename year '%s')",
               rel, yr_field, yr_stem)
    }
  } else {
    # ---- experiment-level file ----------------------------------------------
    exp_suffix <- exp_match[[1]]                          # "_Exp1" / "_Exp1.2"
    key_expected <- paste0("exp", sub("^_Exp", "", exp_suffix))
    keys <- names(parsed)
    if (!identical(keys, key_expected))
      report("EXP KEY MISMATCH: %s (filename %s but top-level key%s %s; expected '%s')",
             rel, exp_suffix,
             if (length(keys) > 1) "s" else "", paste0("'", keys, "'", collapse = ", "),
             key_expected)
  }
}

# --- report -------------------------------------------------------------------
cat(sprintf("Validated %d JSON files under %s\n", length(json_files), data_dir))
if (length(violations)) {
  cat("\n", length(violations), " violation(s) found:\n", sep = "")
  for (v in violations) cat("  [FAIL] ", v, "\n", sep = "")
  quit(status = 1)
}
cat("All JSON metadata files conform to the naming conventions.\n")
quit(status = 0)
