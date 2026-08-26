---
name: spe-database-curation
description: SPE Database curation conventions — FAIR folder structure, file naming
  grammar (journal/database abbreviations), JSON metadata schemas (paper + experiment
  v2 hierarchical), five-component self-matching task framework, Identity
  standardization (Origin → English → Standardized), Codebook_*.xlsx authoring rules,
  minimal-preprocessing conventions, DOI/year verification (Crossref), and Dataset_inf.csv
  master-index rules. Use when adding or curating
  a study/experiment folder under 1_Data/, authoring or editing *_raw/_Clean CSVs,
  Codebook_*.xlsx, .json metadata, identity columns, or filling experiment design
  table fields.
license: MIT
metadata:
  audience: data-curators
---

## What I am

SPE Database (self-matching task, Sui et al. 2012) curation rules. The database
follows the FAIR principle (Wilkinson et al. 2016) with a three-level structure:
root → study → experiment. Every level carries machine-readable JSON metadata.

This skill is **self-contained**: it does not depend on repository-level documents
(README/AGENTS/PROJ_STATE) and is meant to stay general — the same conventions
apply to any SPE-style database using this folder/JSON layout. Repo-specific tool
paths appear only as operational notes.

## When to use me

Use me when you are:
- Adding a new study or experiment folder under `1_Data/`
- Authoring or editing any `.json` metadata (paper-level or experiment-level)
- Naming or renaming `*_raw.csv`, `*_subj_info.csv`, `*_Clean.csv`, `Codebook_*.xlsx`
- Creating or updating a `Codebook_*_Clean.xlsx`
- Standardizing Identity columns (Origin → English → Standardized)
- Filling in experiment design `table`/component fields
- Updating `Dataset_inf.csv` (master index; legacy `Dataset_inf.xlsx` pending removal)
- Validating metadata after a change

## Folder structure

- **Root**: `1_Data/Dataset_inf.csv` — master index (the newest version;
  UTF-8 with BOM — see checklist step 7). One row per experiment, keyed by
  `Folder_Name` (== study folder; **project-wide key ID for papers/preprints**)
  + `Exp`; 39 columns incl. `DOI`, `Country`, `Stim_language`, `Stim_Type`,
  `License`, `numTrials`, `Sample_Size`/`Male`/`Female`.
  `Paper_ID`/`Paper` columns are **deprecated** (legacy mapping to the old
  manuscript Table 1; do NOT create new values).
- **Legacy**: `1_Data/Dataset_inf.xlsx` is an OUTDATED earlier layout (different
  schema: no `Folder_Name`; sheets `Label` + `Sheet1`) — do NOT edit; scheduled
  for deletion once collaborators confirm the CSV (audit 2026-08: it holds no data
  beyond the CSV).
- **`Dataset_inf.csv` 列说明（39 列，按用途分组）**：
  - 键列：`ID`（行号）、`Folder_Name`（关键 ID）、`Exp`（实验号）、`Study`（论文内序号）、`Paper_ID`/`Paper`（**deprecated**，勿新建值）
  - 文献信息：`FirstAuthor`、`Year`（印刷年）、`PubType`（Journal/preprint/unpublished data）、`Journal`、`DOI`（论文 DOI）、`Country`、`City`、`Corresponding_author`、`Email`、`Repo_Link`（数据链接）、`License`、`Note`
  - 样本量：`Sample_Size`、`Male`、`Female`、`Valid_Subj`、`Drop_Subj`
  - 设计：`Design`、`Extra_Ind_Var`、`Stim_Type`、`Stim_language`、`Self`、`Close`、`Others`
  - 流程：`Practice_Block`、`Practice_Trial`、`numBlocks`、`numTrials`、`Environmental_Info`（**刺激呈现软件**，非 Lab/Online 设置）
  - 状态：`Status`、`Behavior_Data`、`Questionnaire_Data`、`EEG/fMRI Data`
  同论文多实验行共享的字段（作者/邮箱/年/期刊/DOI 等）只填一次，其余行留空或同步传播均可——以组内非空值一致为准。
- **Study folder**: `<Author>_<Year>_<Journal>` containing the paper-level
  `<Author>_<Year>_<Journal>.json` at its root.
- **Single experiment** → files live flat in the study folder
  (e.g., `1_Data/Amodeo_2024_CABN/`):
  ```
  Amodeo_2024_CABN.json                       # paper metadata
  Amodeo_2024_CABN_Exp1.json                  # experiment metadata (v2)
  Amodeo_2024_CABN_Exp1_raw.csv               # raw trial-level data
  Amodeo_2024_CABN_Exp1_subj_info.csv       # participant-level data
  Amodeo_2024_CABN_Exp1_Clean.csv             # minimally preprocessed data
  Codebook_Amodeo_2024_CABN_Exp1_Clean.xlsx   # codebook
  ```
- **Multiple experiments** → each experiment gets its own `Exp1/…ExpN/` subfolder
  with the same five files inside; paper JSON stays at the study root
  (e.g., `1_Data/Sui_2014_APP/Exp1/…Exp4/`).
- Known deviation (do NOT propagate): `1_Data/Martinez-Perez_2024_CC/` keeps
  multi-experiment files flat at the study root.

## File naming grammar

`<FirstAuthorLast>_<Year>_<Suffix>[_Exp<N>][_<tag>]`

- **Year** = official **print** year; online-first year does not go into names
  (e.g., `Kirk_2025_BritJPsy`, not 2024; `Liang_2022_HumBrainMap`, not 2021).
- **`<Suffix>`** = a READABLE journal/database abbreviation (a professional
  should be able to guess the journal from it), a full short journal name, or a
  lowercase preprint/unpublished tag:
  - Journal abbreviations in use (2026-08 readability renaming):
    `CABN` (Cognitive, Affective, & Behavioral Neuroscience), `JEPHPP`
    (JEP: Human Perception and Performance), `ActaPsych` (Acta Psychologica),
    `CogEmo` (Cognition and Emotion), `ConsciousCog` (Consciousness and
    Cognition), `IJERPH` (Int. J. Environmental Research and Public Health),
    `Psychophysiol` (Psychophysiology), `CollabraPsy` (Collabra: Psychology),
    `BritJPsy` (British Journal of Psychology), `HumBrainMap` (Human Brain
    Mapping), `JCogPsych` (Journal of Cognitive Psychology), `CurrPsych`
    (Current Psychology), `CogRes` (Cognitive Research: Principles and
    Implications), `BMCPsych` (BMC Psychology), `QJEP` (Quarterly J.
    Experimental Psychology), `APP` (Attention, Perception, & Psychophysics),
    `PsychRes` (Psychological Research), `PLOS` (PLOS ONE), `PsychMed`
    (Psychological Medicine), `EJN` (European J. Neuroscience), `DataExp`
    (Data Express).
  - Full journal names used verbatim: `Cognition` (`Lee_2023_Cognition`),
    `Cortex` (`Smith_2024_Cortex`), `NeuroImage` (`Zhang_2023_NeuroImage`),
    `elife` (`Scheller_2026_elife`, folder pending).
  - Database abbreviations: `SDB` = Science Databank (`Hu_2023_SDB`, folder
    pending). When the source is a data repository rather than a journal, use the
    repository's abbreviation.
  - Preprint/unpublished tags (lowercase): `psyarxiv` for PsyArXiv preprints
    (e.g., `Navon_2021_psyarxiv`, `Hu_2023_psyarxiv`); `unpub` for
    unpublished data without a preprint server (e.g., `Sui_2014_unpub`,
    `Sui_2015_unpub`, `Pan_2025_unpub`).
- **Tags**: `_raw` (unprocessed), `_subj_info` (participant level), `_Clean`
  (minimally preprocessed), `Codebook_*_Clean.xlsx` for codebooks.
- **Canonical casing**: `Codebook_` (lowercase b), `_raw_` (lowercase).
  Existing outliers (`CodeBook_…` — 28 legacy files, `Raw/` subfolders) are
  legacy — do not propagate to new files.
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
- Preprint variant (e.g., `Hu_2023_psyarxiv.json`, `Navon_2021_psyarxiv.json`):
  `"Journal": "Preprint"` + a PsyArXiv/OSF DOI (e.g., `10.31234/osf.io/9dzm4`).
- Known exception: `Kirk_2025_BritJPsy.json` uses a nested schema
  (`Paper_ID > KIRK_2025_BJP > {…}` with embedded `Experiments`; the inner key
  keeps the old paper ID). Accept, do not restructure.

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
use `"/"` for unknown. All 15 existing experiment JSONs are already v2 — new files
must be v2 as well.

## Five-component task framework

Boundary rules for ambiguous keys:
- **Physical_Environment** — where/how the task was delivered (hardware, room, distance).
  `Setting` must use a controlled vocabulary: `Laboratory`, `Online`, or a combined
  value (e.g., `Laboratory + Online`); use `"/"` only when truly unknown. Do NOT
  invent free-text variants (e.g., "quiet room", "chamber", "remote"): the manuscript
  Table 1 pipeline (repo tool: `Generate_Table1.qmd`) infers the Table 1 column
  `Exp_Implement` (Lab Experiment / Online Experiment / Mixed) by regex-matching
  `Setting`, so non-standard wording silently degrades to NA.
- **Experimental_Design** — what is manipulated/compared; `Conditions` extracted from
  the "per condition:" breakdown of `Trial_number` when present, else `"/"`.
  Full factorial design lives in `Dataset_inf.csv` (`Design`, `Stim_Type` columns).
- **Block_Structure** — blocks and trial composition within blocks.
- **Trial_Structure** — within-trial timing (fixation, stimulus, SOA, response window, ITI).
  `Shape-label interval` maps to `SOA`; `Stimulus_order` (simultaneous vs sequential) lives here.
- **Stimulus_Properties** — what the stimuli are (modality, sizes, colors).
  `Modality` belongs here, not in Physical_Environment.

## Data standardization (`*_Clean.csv`) conventions

- Standardized columns: `Subject`, `Shape`, `Label`, `Matching`, `ACC`, `RT_ms`
  (plus optional `Block`, `Trial`, `Phase`, `Response`, `RT_sec`).
- **Identity columns — 3 levels per identity-bearing stimulus column**
  `X` ∈ {Shape, Label}:
  `X_Origin_Identity` (verbatim as in the raw data, original language) →
  `X_English_Identity` (English translation) →
  `X_Standardized_Identity` (canonical 6-category vocabulary:
  `NonPerson`, `Self`, `Close`, `Acquaintance`, `Celebrity`, `Stranger`).
  Verified mapping example (Amodeo_2024_CABN): `Ikzelf→Self`, `Vreemde→Stranger`,
  `Bekende→Friend→Close`. Typical origin-language mappings seen in the DB:
  Chinese `我→Self`, `她/他→Close`; Dutch `Ikzelf→Self`, `Vreemde→Stranger`,
  `Bekende→Close`; German `Ich→Self`, `Mutter→Close`, `Bekannter→Stranger`;
  English `self→Self`, `friend→Close`, `stranger→Stranger`.
  Analyses must use the `*_Standardized_Identity` column.
- **Minimal preprocessing, NO filtering**: cleaning only renames/reorganizes variables
  and standardizes Identity; it keeps ALL trials, participants and values. Invalid
  values stay in the file (e.g., `ACC = -1` no response, `2` wrong key; `RT_ms`
  outliers). Practice trials, if retained, are flagged (e.g., a `Phase` column)
  rather than dropped. Such codes are documented in the codebook, not removed;
  full preprocessing (filtering, outlier removal, accuracy coding) is the user's
  responsibility.

## DOI 与年份核验（添加/更新论文时必做）

- **DOI 填论文的 DOI，不是数据链接**：`Repo_Link` 存数据存储库链接（OSF/Zenodo/ScienceDB），`DOI` 列与 paper JSON 的 `DOI` 字段一律填正式论文的 DOI。
- **本地优先**：先查 paper JSON 的 `DOI` 字段；其次查 `Repo_Link` 中是否含 `doi.org/10....`；都没有才外查。
- **外查用 Crossref API，不用通用网页搜索**（网页搜索噪声大、难确证）：
  `https://api.crossref.org/works?query.bibliographic=<题名>&query.author=<作者>&filter=container-title:<期刊名>&rows=3`
  核对返回记录的 作者 / 期刊 / 年份 / 卷期 全部吻合才采用；DOI 存裸格式（去掉 `https://doi.org/` 前缀）。
- **年份 = 正式印刷年**：Crossref 记录的 `published-print`（卷期所属年份）；纯在线期刊（PLOS/eLife/MDPI/Collabra 等）无印刷卷期时用 `issued`（在线发表年）；仍为预印本的用**最新版本年份**。
- **预印本版本年查询**：OSF API 按 GUID 直取——`https://api.osf.io/v2/preprints/<guid>/versions/`（`filter[doi]` 查询返回 HTTP 400，勿用）；GUID 即 PsyArXiv DOI 的后段（如 `10.31234/osf.io/9dzm4` → `9dzm4`）。

## Codebook authoring rules

- One `Codebook_<Study>_Exp<N>_Clean.xlsx` per `*_Clean.csv`, in the same folder,
  canonical casing `Codebook_` (legacy `CodeBook_` must not be propagated).
- **Structure** (verified across existing codebooks): a single worksheet `Sheet1`
  with exactly 4 columns and one row per variable of the Clean.csv:

  | Column | Content |
  |---|---|
  | `Variable_name` | exact column name in the Clean.csv — cover EVERY column |
  | `Variable_description` | plain-English meaning of the variable; `NA` if unknown |
  | `Variable_value` | Numerical: unit or "Number" (e.g., `ms`); Categorical: semicolon-separated valid values, including missing/invalid codes with their meaning (e.g., `-1 (no response); 0 (incorrect); 1 (correct); 2 (wrong key)`) |
  | `Variable_category` | `Numerical` or `Categorical` |

- **How to create**:
  1. Read the Clean.csv header → the variable list
     (R: `read.csv(file, nrows = 1)`; Python: `csv.DictReader.fieldnames`).
  2. Fill `Variable_description` from the paper's Method section and the raw-data
     documentation.
  3. Enumerate `Variable_value` from the actual data (`unique()` of each column),
     including special/missing codes.
  4. Write the xlsx with R `openxlsx::write.xlsx` or Python `openpyxl` (never
     hand-edit xlsx XML).
  5. Verify every Clean.csv column has exactly one codebook row.

## 清洗工具（三套并行实现，逻辑一致）

- `2_Code/Clean_Data.Rmd` — 逐论文手工管线（**权威**）；按论文逐个清洗，含旧文件夹名注释（历史记录，不改）。
- `2_Code/SPE_Interactive_Clean_V3.R` — 控制台交互清洗（单个/批量 `*_raw.csv`，变量映射 + Identity 标准化）。
- `2_Code/SPE_Shiny_App_V4.2.R` — Shiny 网页版（交互界面、批量处理、ZIP 下载）。
- 三者产出相同的标准化列（`Subject/Shape/Label/Matching/ACC/RT_ms` + 三级 Identity）与 `*_ExpN_Clean.csv` 命名；**清洗 = 最小预处理，不过滤**（见 Data standardization 一节）。
- 从 Clean_Data.Rmd 提取**独立清洗脚本**（如 1_Data/<Study>/<Study>_clean.R，2026-08 起先例：Sui_2015_unpub_clean.R）的规范：
  - 内嵌脚本依赖的辅助函数（如 read.mat），不依赖 Rmd 上下文；开头注释写明来源行号与相对原版的修改点。
  - 路径用脚本所在目录的相对路径，并修正 Rmd 中的失效路径（旧文件夹名）；脚本内做工作目录自适应（Rscript 的 --file= 参数）。
  - 输出 *_Clean.csv 带一致性守卫（如 stopifnot 行数/被试数）；行尾 CRLF/LF 差异直接无视，不做转换。
  - 排除已确认的问题被试（如测试运行）时，在脚本注释中写明证据（内部编号/默认人口学/按键反转等）与依据条目（PROJ_STATE.md 已知问题）。
  - 修改数据文件后同步更新同目录 subj_info、Dataset_inf.csv（字节保真）与 codebook；Clean_Data.Rmd 对应段如需同步修改，diff 应只含目标改动。

## End-to-end checklist: adding a new study

1. Fix the folder name per the naming grammar (print year, ASCII-only, journal/database suffix).
2. Create the study folder with raw files: `*_raw.csv` (trial-level) and
   `*_subj_info.csv` (participant-level). Keep per-participant exports in a
   `*_Raw/` subfolder only when they already exist (legacy layout — do not create new ones).
3. Produce `*_ExpN_Clean.csv` per the minimal-preprocessing conventions.
4. Author the paper-level JSON (11 flat fields; `Year` == folder year;
   `"Journal": "Preprint"` variant for preprints).
5. Author the experiment-level JSON (v2 schema; top-level key `exp<N>` matches
   `_Exp<N>`; five components; controlled `Setting` vocabulary; `"/"` for unknown;
   units inside strings).
6. Author the codebook (single `Sheet1`, 4 columns, every variable covered).
7. Update `Dataset_inf.csv` (the master index) — add one row per experiment:
   `Folder_Name` (the key ID) + `Exp` numbering. Keep it UTF-8 **with BOM**
   (Chinese collaborators open
   it in Excel on Chinese Windows, which defaults to GBK; the BOM keeps diacritics
   like `ö`/`é`/`ü` from garbling). Do NOT edit the legacy `Dataset_inf.xlsx`.
8. Run `Rscript 2_Code/validate_json_metadata.R` and fix every violation (naming,
   year drift, exp-key match, v2 component completeness).
9. Render the manuscript Table 1 pipeline (repo tool: `Generate_Table1.qmd`) and
   inspect its problem output for NEW discrepancies vs the manuscript Table 1.
10. exFAT hygiene: purge `._*` files before git ops; never commit `._*`/`.DS_Store`.

## Validation and hygiene

1. After any metadata change run:
   `Rscript 2_Code/validate_json_metadata.R` (checks naming, year drift, exp-key match,
   v2 component completeness; exits non-zero on violations).
2. The validator whitelists not-yet-curated studies (`known_pending`, currently
   9: `Bukowski_2021_ActaPsych`, `Golubickis_2021_ActaPsych`, `Hobbs_2023_PsychMed`,
   `Hu_2023_SDB`, `Mcivor_2021_EJN`, `Orellana-Corrales_2023_QJEP`,
   `Scheller_2026_elife`, `Svensson_2022_PsychRes`, `Wozniak_2020_PLOS`) that
   are allowed to lack a folder; once such a study is curated, remove it from the
   whitelist.
3. **Validator blind spots**（校验器只校验存在的文件，以下缺失不会被发现，需人工核对）：
   缺 paper 级 JSON、缺 codebook、CSV 中重复的 `(Folder_Name, Exp)` 组合。
4. One-time schema migrations live in `2_Code/migrate_exp_json_to_v2.py`
   (v1 flat `table` → v2 hierarchical); re-run only if legacy files reappear.
4. exFAT drive: purge AppleDouble files (`find . -name '._*' -delete`) before git ops;
   never commit `._*` files.
