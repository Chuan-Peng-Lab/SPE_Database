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
#   cross-check: 1_Data/Dataset_inf.csv Folder_Name column <-> study folders
#                 (every folder must be indexed; every indexed Folder_Name must
#                  have a folder, except known-pending studies -- see below)
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
  data_dir <- here::here("1_Data")
}
stopifnot(dir.exists(data_dir))

# --- helpers -------------------------------------------------------------------
is_ascii <- function(x) !is.na(iconv(x, from = "UTF-8", to = "ASCII", sub = NA))

year_in <- function(x) {
  m <- regmatches(x, regexpr("(18|19|20)[0-9]{2}", x))
  if (length(m)) m[[1]] else NA_character_
}

# Recursively find the first "Year" field (accommodates Kirk's nested schema)
find_year <- function(x) {
  if (!is.list(x)) return(NULL)
  if ("Year" %in% names(x)) return(x[["Year"]])
  for (nm in names(x)) {
    y <- find_year(x[[nm]])
    if (!is.null(y)) return(y)
  }
  NULL
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
    yr_field  <- find_year(parsed)
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

    eo <- parsed[[key_expected]]
    if (!is.list(eo)) next
    if (!identical(eo$schema_version, "2"))
      report("EXP SCHEMA VERSION: %s (expected '2', found %s)", rel,
             if (is.null(eo$schema_version)) "<missing>" else paste0("'", eo$schema_version, "'"))
    components <- c("Physical_Environment", "Experimental_Design", "Block_Structure",
                    "Trial_Structure", "Stimulus_Properties")
    missing <- setdiff(components, names(eo))
    if (length(missing))
      report("EXP MISSING COMPONENT: %s (%s)", rel, paste(missing, collapse = ", "))
    allowed <- c(components, "schema_version", "Collected_date", "detail")
    extra <- setdiff(names(eo), allowed)
    if (length(extra))
      report("EXP UNKNOWN KEY: %s (%s)", rel, paste(extra, collapse = ", "))
  }
}

# --- cross-check Dataset_inf.csv (Folder_Name) vs study folders ----------------
# Dataset_inf.csv lives inside 1_Data/ and is the master inventory (the legacy
# Dataset_inf.xlsx is outdated and pending deletion). Its Folder_Name column is
# the project-wide key ID for papers/preprints and must agree with the actual
# study folders: (a) every folder must be listed, and (b) every listed
# Folder_Name must have a folder. Studies whose data have not been curated yet
# are allowed to be listed without a folder; they are tracked in known_pending
# so they stay visible without failing the check.
dataset_inf <- file.path(data_dir, "Dataset_inf.csv")

# Known-pending studies: listed in Dataset_inf.csv but data not yet curated
# (documented in AGENTS.md). Add new pending entries here explicitly.
known_pending <- c(
  "Bukowski_2021_ActaPsych", "Golubickis_2021_ActaPsych",
  "Hu_2023_SDB", "Mcivor_2021_EJN",
  "Scheller_2026_elife", "Svensson_2022_PsychRes", "Wozniak_2020_PLOS"
)

# Known un-listed folders: input-zone folders whose data arrived but that are
# not yet ingested into Dataset_inf.csv (stage-5 ingestion in progress).
# Mirror of known_pending in the opposite direction; remove once the study is
# listed in the CSV. (Currently none.)
known_unlisted <- character(0)

folders <- list.dirs(data_dir, recursive = FALSE, full.names = FALSE)
folders <- folders[!grepl("^\\._", folders)]  # drop AppleDouble sidecars
folders <- sort(folders)

if (!file.exists(dataset_inf)) {
  report("DATASET_INF MISSING: %s (expected master inventory next to 1_Data/)",
         dataset_inf)
} else {
  inf <- tryCatch(
    read.csv(dataset_inf, stringsAsFactors = FALSE, check.names = FALSE,
             na.strings = c("", "NA")),
    error = function(e) NULL)
  if (is.null(inf)) {
    report("DATASET_INF UNREADABLE: %s", dataset_inf)
  } else if (!("Folder_Name" %in% names(inf))) {
    report("DATASET_INF MISSING COLUMN: %s has no 'Folder_Name' column", dataset_inf)
  } else {
    listed <- unique(trimws(as.character(inf[["Folder_Name"]])))
    listed <- listed[!is.na(listed) & nzchar(listed)]

    # (a) folders with no matching row in Dataset_inf.csv
    no_listing <- setdiff(folders, listed)
    no_listing <- setdiff(no_listing, known_unlisted)
    if (length(no_listing))
      report("FOLDER NOT IN DATASET_INF: %s (no Folder_Name row in %s)",
             paste(no_listing, collapse = ", "), basename(dataset_inf))

    # (b) listed File_Name with no matching folder
    no_folder <- setdiff(listed, folders)
    pending   <- intersect(no_folder, known_pending)
    if (length(pending))
      cat(sprintf("  [INFO] %d known-pending study(ies) without folder yet (allowed): %s\n",
                  length(pending), paste(pending, collapse = ", ")))
    no_folder <- setdiff(no_folder, known_pending)
    if (length(no_folder))
      report("DATASET_INF FOLDER_NAME WITHOUT FOLDER: %s (missing folder in %s)",
             paste(no_folder, collapse = ", "), data_dir)
  }
}

# ------------------------------------------------------------------------------
# Experiment-level JSON completeness (2026-08 enhancement): every standard-named
# *_Exp<N>_Clean.csv must have a matching <Study>_Exp<N>.json (v2 schema) in the
# same folder or the study root. Missing files are reported as WARN (known gaps
# are documented in PROJ_STATE.md; new studies must not add more). Non-standard
# variants (e.g. _Exp1.1_ files) are excluded from the check.
# ------------------------------------------------------------------------------
clean_files <- list.files(data_dir, pattern = "_Exp[0-9]+_Clean[.]csv$",
                          recursive = TRUE, full.names = TRUE)
clean_files <- clean_files[!grepl("/[.]_", clean_files)]
clean_files <- clean_files[!grepl("(_Raw/|_raw/|/Raw/|/Source/)", clean_files)]
missing_exp_json <- character(0)
for (cf in clean_files) {
  base <- sub("_Clean[.]csv$", "", basename(cf))   # <Study>_Exp<N>
  if (!file.exists(file.path(dirname(cf), paste0(base, ".json"))) &&
      !file.exists(file.path(dirname(dirname(cf)), paste0(base, ".json")))) {
    missing_exp_json <- c(missing_exp_json, sub(paste0(data_dir, "/"), "", cf))
  }
}
if (length(missing_exp_json)) {
  cat(sprintf(paste0("  [WARN] %d *_Exp<N>_Clean.csv without experiment-level JSON ",
                     "(create <base>.json, v2 schema):\n"), length(missing_exp_json)))
  for (m in missing_exp_json) cat("         ", m, "\n", sep = "")
}

# --- report -------------------------------------------------------------------
cat(sprintf("Validated %d JSON files under %s\n", length(json_files), data_dir))
if (file.exists(dataset_inf))
  cat(sprintf("Cross-checked %d study folder(s) against %s\n",
              length(folders), basename(dataset_inf)))
if (length(violations)) {
  cat("\n", length(violations), " violation(s) found:\n", sep = "")
  for (v in violations) cat("  [FAIL] ", v, "\n", sep = "")
  quit(status = 1)
}
cat("All JSON metadata files and Dataset_inf.csv conform to the conventions.\n")
quit(status = 0)
