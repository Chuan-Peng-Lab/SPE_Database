---
name: spe-database-curation
description: SPE Database curation conventions — FAIR folder structure, file naming
  grammar, JSON metadata schemas (paper + experiment v2 hierarchical), and the
  five-component self-matching task standardization framework. Use when adding or
  curating a study/experiment folder under 1_Data/, authoring or editing *_raw/_Clean
  CSVs, Codebook_*.xlsx, .json metadata, or filling experiment design table fields.
license: MIT
metadata:
  audience: data-curators
---

## What I am

SPE Database (self-matching task, Sui et al. 2012) curation rules. The database
follows the FAIR principle (Wilkinson et al. 2016) with a three-level structure:
root → study → experiment. Every level carries machine-readable JSON metadata.

## When to use me

Use me when you are:
- Adding a new study or experiment folder under `1_Data/`
- Authoring or editing any `.json` metadata (paper-level or experiment-level)
- Naming or renaming `*_raw.csv`, `*_raw_Subject.csv`, `*_Clean.csv`, `Codebook_*.xlsx`
- Filling in experiment design `table`/component fields
- Validating metadata after a change

## Folder structure

- **Root**: `1_Data/Dataset_inf.xlsx` — master index (NOT `Dataset_inf.csv`).
  Each row = one dataset, keyed by `Paper_Id` (e.g., `P5E1`, `Pt3E1`, `Pn13E1`).
  Sheet `Label` holds full metadata; `Sheet1` maps `Paper_Id` → `File_Name`.
- **Study folder**: `<Author>_<Year>_<Journal>/` containing the paper-level
  `<Author>_<Year>_<Journal>.json` at its root.
- **Single experiment** → files live flat in the study folder
  (e.g., `1_Data/Amodeo_2024_CABN/`):
  ```
  Amodeo_2024_CABN.json                       # paper metadata
  Amodeo_2024_CABN_Exp1.json                  # experiment metadata (v2)
  Amodeo_2024_CABN_Exp1_raw.csv               # raw trial-level data
  Amodeo_2024_CABN_Exp1_raw_Subject.csv       # participant-level data
  Amodeo_2024_CABN_Exp1_Clean.csv             # minimally preprocessed data
  Codebook_Amodeo_2024_CABN_Exp1_Clean.xlsx   # codebook
  ```
- **Multiple experiments** → each experiment gets its own `Exp1/…ExpN/` subfolder
  with the same five files inside; paper JSON stays at the study root
  (e.g., `1_Data/Sui_2014_APP/Exp1/…Exp4/`).
- Known deviation (do NOT propagate): `1_Data/Martinez-Perez_2024_CC/` keeps
  multi-experiment files flat at the study root.

## File naming grammar

`<FirstAuthorLast>_<Year>_<JournalAbbrev>[_Exp<N>][_<tag>]`

- **Year** = official **print** year; online-first year does not go into names
  (e.g., `Kirk_2025_BJP`, not 2024; `Liang_2022_HBM`, not 2021).
- **Journal abbreviations in use**: `CABN, EPHPP, AP, CE, CC, ERPH, Psy, CP, HBM, NI,
  QJEP, PR, PLOS, BJP, PM, EJN, APP, BMC`.
- **No-journal studies** (unpublished/preprint): folder is just `<Author>_<Year>`
  (e.g., `Navon_2021`, `Sui_2014`, `Sui_2015`, `Sun_2025`, `Pan_2025`, `Hu_2023`).
- **Tags**: `_raw` (unprocessed), `_raw_Subject` (participant level), `_Clean`
  (minimally preprocessed), `Codebook_*_Clean.xlsx` for codebooks.
- **Canonical casing**: `Codebook_` (lowercase b), `_raw_` (lowercase).
  Existing outliers (`CodeBook_…`, `Raw/` subfolders) are legacy — do not propagate.
- **Filenames must be pure ASCII** (no diacritics).

## JSON schemas

### Paper-level JSON (`<Study>.json`) — flat 11-field schema
```json
{
  "Paper_name": "…", "Summary": "…", "Year": "2022", "Author": "…",
  "Journal": "…", "Country": "…", "City": "…", "Extra_Var": "/",
  "Email": "…", "DOI": "…", "Conclusion": "…"
}
```
- `Year` must equal the folder year.
- Preprint variant (e.g., `Hu_2023.json`, `Navon_2021.json`):
  `"Journal": "Preprint"` + a PsyArXiv/OSF DOI (e.g., `10.31234/osf.io/9dzm4`).
- Known exception: `Kirk_2025_BJP.json` uses a nested schema
  (`Paper_ID > KIRK_2025_BJP > {…}` with embedded `Experiments`). Accept, do not restructure.

### Experiment-level JSON (`<Study>_Exp<N>.json`) — v2 hierarchical schema
Top-level key MUST match the filename suffix (`exp1` ↔ `_Exp1`). Five components
follow the task-standardization framework:
```json
{
  "exp1": {
    "schema_version": "2",
    "Collected_date": "2014-04",
    "Physical_Environment": {
      "Location": "…", "Setting": "…",
      "Equipment": {"Presenting": "…", "Monitor": "…", "Software": "…"},
      "Viewing_distance": "…"
    },
    "Experimental_Design": {"Conditions": "self-matching, self-mismatching, …"},
    "Block_Structure": {
      "Block_number": "…", "Trial_number": "…", "Practice_trials": "…"
    },
    "Trial_Structure": {
      "Fixation_duration": "…", "Stimulus_duration": "…", "SOA": "…",
      "Stimulus_order": "…", "Response_deadline": "…", "ITI": "…", "Feedback_duration": "…"
    },
    "Stimulus_Properties": {
      "Modality": "…", "Fixation": "…", "Shape": "…", "Label": "…",
      "Colors": {"Stimulus": "…", "Background": "…"}
    },
    "detail": ""
  }
}
```
Allowed exp-level keys: the five components + `schema_version`, `Collected_date`, `detail`.
Values are human-readable strings with units (e.g., `"500 ms"`, `"3.8° × 3.8°"`);
use `"/"` for unknown.

## Five-component task framework

Boundary rules for ambiguous keys:
- **Physical_Environment** — where/how the task was delivered (hardware, room, distance).
- **Experimental_Design** — what is manipulated/compared; `Conditions` extracted from
  the "per condition:" breakdown of `Trial_number` when present, else `"/"`.
  Full factorial design lives in `Dataset_inf.xlsx` (`Design`, `Stim_Type` columns).
- **Block_Structure** — blocks and trial composition within blocks.
- **Trial_Structure** — within-trial timing (fixation, stimulus, SOA, response window, ITI).
  `Shape-label interval` maps to `SOA`; `Stimulus_order` (simultaneous vs sequential) lives here.
- **Stimulus_Properties** — what the stimuli are (modality, sizes, colors).
  `Modality` belongs here, not in Physical_Environment.

## Validation and hygiene

1. After any metadata change run:
   `Rscript 2_Code/validate_json_metadata.R` (checks naming, year drift, exp-key match,
   v2 component completeness; exits non-zero on violations).
2. One-time schema migrations live in `2_Code/migrate_exp_json_to_v2.py`
   (v1 flat `table` → v2 hierarchical); re-run only if legacy files reappear.
3. exFAT drive: purge AppleDouble files (`find . -name '._*' -delete`) before git ops;
   never commit `._*` files.
