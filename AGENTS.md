---
mode: primary
---

# AGENTS.md — SPE Database

## ⚠️ CRITICAL: This project lives on a USB drive (exFAT)

The entire repo is stored on an **exFAT-formatted USB drive** mounted at `/Volumes/T3`.

### Why this matters

1. **exFAT does not support macOS extended attributes (xattrs).** To preserve file
   metadata (icons, quarantine flags, etc.), macOS writes hidden **AppleDouble sidecar
   files** named `._<original-name>` next to every file it touches.
2. **These `._*` files leak into the git object store.** When git operations or any
   macOS tooling touches packed objects, macOS may create files like:
   ```
   .git/objects/pack/._pack-<hash>.pack
   .git/objects/pack/._pack-<hash>.idx
   .git/objects/pack/._pack-<hash>.rev
   ```
3. **They break git.** Git scans `.git/objects/pack/` and tries to parse
   `._pack-*.idx` as a real index → errors like:
   ```
   error: non-monotonic index .git/objects/pack/._pack-....idx
   ```

### Mandatory cleanup rule

**At the START of every session** (first tool call), run:

```bash
rm -f .git/objects/pack/._pack-*
```

Also purge any other stray AppleDouble files before git operations:

```bash
find . -name '._*' -not -path './.git/objects/pack/._pack-*' -delete 2>/dev/null
# then remove the ones in .git (find skips hidden dirs by default unless specified)
find .git -name '._*' -delete 2>/dev/null
```

Re-run the cleanup **before and after** any `git add` / `git commit` / `git status`
/ `git log` command if errors appear.

### Guidelines for agents

- **Never** `git add` or commit `._*` files or other macOS cruft (`.DS_Store`,
  `.Rhistory`, `.Rproj.user`, `Thumbs.db`). `.gitignore` already covers most of them.
- **Never** open/read `._*` files as if they were real data files — they are AppleDouble
  metadata, not content. When globbing/listing, filter them out (the repo already uses
  `._*` ignore patterns).
- **Safely eject / unmount** the drive is the user's responsibility — never attempt to
  unmount, remount, or format the drive yourself.
- Expect slow disk I/O on this drive (USB/exFAT). Batch reads/writes when possible.
- If `git` reports `non-monotonic index` or `error: git upload-pack` style corruption,
  first try the cleanup above, then `git gc --prune=now` — do **not** delete real
  `.git/objects/pack/pack-*` files.

## Project context

- **What**: SPE (Self-Prioritization Effect) Database — curated trial-level data from
  44 papers / 70 datasets / 3603 participants using the self-matching task
  (Sui, He & Humphreys 2012). Companion to a preregistered meta-analysis (OSF: euqmf).
- **Structure**:
  - `1_Data/` — 34 study folders (`<Author>_<Year>_<Journal>/`), plus `Dataset_inf.xlsx`
    inventory. Each folder contains:
    - raw data: `*_raw.csv` (trial-level), `*_raw_Subject.csv` (subject-level),
      sometimes `*_Raw/` subfolders with per-participant exports (E-Prime `.edat2`,
      MATLAB `.mat`, PsychoPy `.psydat`).
    - cleaned data: `*_ExpN_Clean.csv`.
    - metadata: `Codebook_*_Clean.xlsx` (variable codebooks, ~100 files),
      study-level `.json` (paper metadata) and experiment-level `.json`
      (methodology, v2 hierarchical schema: five components under `exp<N>`).
  - `.opencode/skills/spe-database-curation/` — curation-conventions skill (folder
    structure, file naming, JSON schemas, five-component task framework). Load via
    `skill(name="spe-database-curation")` when adding/editing study metadata.
  - `2_Code/` — data cleaning tooling, three parallel implementations of the same
    standardization logic:
    - `Clean_Data.Rmd` (5053 lines) — master per-paper manual pipeline (authoritative).
    - `SPE_Interactive_Clean_V3.R` — console-based interactive cleaner (single/batch).
    - `SPE_Shiny_App_V4.2.R` — Shiny web app (single/batch, ZIP download).
  - `3_Reports/` — analysis: `Reports.Rmd`, `Process_Data.Rmd`, `Subject_Table.Rmd`,
    `R_rainclouds.R`, plus `1_Identity_Analysis/`, `2_Mismatch_Analysis/`,
    `3_Exploratory_Analysis/` (each a self-contained Rmd), `4_Post/`, and `Output/`
    (aggregated CSVs in `Output/data/`, figures in `Output/Pic/`).
- **Stack**: R / R Markdown / Shiny. RStudio project (`SPE_Database.Rproj`).
- **Key conventions**: cleaned variables standardized to `Subject`, `Shape`, `Label`,
  `Matching`, `ACC`, `RT_ms`, and 3-level Identity columns
  (Origin → English → Standardized: NonPerson/Self/Close/Acquaintance/Celebrity/Stranger).
  Cleaned file naming: `<Author>_<Year>_<Journal>_ExpN_Clean.csv`.
- **Raw data formats**: CSV dominant (331 files); also E-Prime `.edat2`/`.emrg`,
  MATLAB `.mat`/`.m`, PsychoPy `.psydat`/`.dat`. No parquet anywhere.
- **Version**: v0.1.5 (2026-06-28). See `README.md` for full changelog.

## Known data-quality caveats (verified 2026-08)

Treat these as known issues, not new discoveries — do not "find" them again:

- **4 studies lack codebooks** (no `Codebook_*_Clean.xlsx`): `Lee_2023_Cognition`,
  `Orellana-Corrales_2021_APP`, `Smith_2024_Cortex`, `Svensson_2023_QJEP`
  (also have no `*_raw_Subject.csv`).
- **Missing raw data**: `Sun_2025/` has `Sun_2025_Exp1_Clean.csv` (largest cleaned file,
  62 MB) but no `*_raw.csv`.
- **Pending study — no data folder yet (do NOT "fix")**: `Dataset_inf.xlsx` lists
  `Wozniak_2020_PLOS` (DOI `10.1371/journal.pone.0235627`, OSF `osf.io/2q9w7`) but no
  `1_Data/Wozniak_2020_PLOS/` folder exists — expected, data not yet curated.
  Paper = Woźniak & Hohwy, PLOS ONE, 2020.
- **Preprocessing is NOT complete**: cleaning is filtering, not full preprocessing —
  `ACC` may include invalid values (e.g., `-1` no response, `2` incorrect key).
  Users must preprocess per their own analysis goals.
- **Missing code references**: `2_Code/README_Auto_Clean.md` references
  `SPE_Auto_Clean.R` and `Test_Auto_Clean.R`, which do not exist in the repo.
- **Large files (>10 MB)**: `Sun_2025_Exp1_Clean.csv` (62 MB), `Processed_Data_Filtered.csv`
  (60 MB), `Haciahmet_2023_Psy_Exp1_raw.csv` (42 MB), `Share_Data.RData` (31 MB).
  Avoid loading these into memory / context casually.

## Repo state (verified 2026-08)

- Single branch `main` (tracks `origin/main`).
- Root-level `._*` files and `Contact*.xlsx` are gitignored; study folders
  `Smith_2024_Cortex/`, `Lee_2023_Cognition/`, etc. are also gitignored at repo root
  (only their `1_Data/...` paths are tracked).

## TODO / planned work

- Add detailed instruction about how to create `Codebook_*` files for each dataset  in the skill `spe-database-curation` (what each `Codebook_<Study>_ExpN_Clean.xlsx` must document — variable definitions, valid values, units, missing-data codes, cleaning decisions, and how to create such files from available data/information).
