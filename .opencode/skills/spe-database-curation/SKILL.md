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
- **Raw input zone（输入区，2026-08 起规范）**: downloaded original exports go into
  `1_Data/<Study>/<Study>_Raw/` (study level; all experiments together; a `Source/`
  subfolder for the original download is allowed). Supported formats: `.csv`, `.mat`,
  `.edat2`/`.emrg`, `.psydat`/`.dat`, `.txt`, `.xlsx`. The input zone is **read-only
  input** — it does NOT participate in validation (`validate_json_metadata.R` and
  `validate_clean_csv.R` both skip `*_Raw/` and `Source/`), and its files are not
  standardized products. The standardized trial-level product derived from it is
  `<Study>_Exp<N>_raw.csv` (in `Exp<N>/` or the study root) — do not confuse the two:
  `*_Raw/` = downloaded originals (as-is), `*_raw.csv` = processed standard file.
  Workflow: download → drop into `<Study>_Raw/` → agent scans the input zone →
  produces `*_raw.csv`, `*_ExpN_Clean.csv`, `*_subj_info.csv` → validates.

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
- **通用函数与独立脚本同库（2026-08）**：独立清洗脚本与 `1_Data/utils.R`（spe_root/write_clean_csv）
  同在 `1_Data/` 下，`source()` 同库引用，**不跨文件夹引用**（不要放 2_Code/ 再跨层 source）。
- **自动化整理（2026-08 方向）**：新研究入库/重整理由 agent 加载本技能完成——
  下载的原始数据放 `<Study>_Raw/` 输入区 → 扫描识别实验/被试/会话结构 → 生成
  独立清洗脚本 `<Study>_clean.R`（先例 `Sui_2015_unpub_clean.R`，配方参考
  `Clean_Data.Rmd` 对应段）→ 产出 `*_ExpN_Clean.csv` / `*_subj_info.csv` →
  元数据（paper/exp JSON、Codebook、Dataset_inf.csv）→ 两级校验
  （validate_json_metadata.R + validate_clean_csv.R）。`Clean_Data.Rmd` 降级为
  历史配方参考，其逐研究段逐步提取为独立脚本/配置。

## End-to-end workflow: adding a new study（入库工作流，2026-08 自动化版）

1. 建文件夹并**下载数据到输入区** `1_Data/<Study>/<Study>_Raw/`（命名语法：印刷年、纯 ASCII、期刊/库缩写）。
2. **扫描输入区**（agent）：识别 实验/被试/会话 结构；格式异常或多格式混存 → 暂停（Human decision points #7）。
3. **生成并运行独立清洗脚本** `<Study>_clean.R`（从 `Clean_Data.Rmd` 对应段提取配方，或对照标准列新写；
   模式见 §清洗工具提取规范与先例 `Sui_2015_unpub_clean.R`）→ 产出 `*_raw.csv`（标准 trial 级）与
   `*_ExpN_Clean.csv`；`*_subj_info.csv` 从 raw/输入区人口学生成。
4. **内容级校验**：`Rscript 2_Code/validate_clean_csv.R`（E1–E3 必须 0 ERROR；W 级提示记录）。
5. **元数据草稿**：按 §Metadata draft workflow 生成 paper JSON（Crossref 预填）+ 实验 JSON（v2 五组件），
   `[P]`/`[H]` 字段过 §Human decision points 人工确认。
6. **Codebook**：按 §Codebook authoring rules 生成（单 `Sheet1` 4 列，覆盖全部 Clean 列）。
7. **更新 `Dataset_inf.csv`**（主索引）：每实验一行 `Folder_Name` + `Exp`；UTF-8 **带 BOM** 字节保真；
   不动 legacy `Dataset_inf.xlsx`。
8. **结构级校验**：`Rscript 2_Code/validate_json_metadata.R`（命名、年份漂移、exp-key、v2 组件完整性）并修复。
9. **收尾**：若原在 `known_pending` 白名单 → 移出；`Generate_Table1.qmd` 重渲染（稿件比对默认关闭，
   仅稿件版本更新时 `--param compare_manu:true`）；更新 PROJ_STATE.md。
10. exFAT 卫生：git 操作前清理 `._*`；绝不提交 `._*`/`.DS_Store`。

## Metadata draft workflow（入库元数据草稿生成流程，2026-08 试点）

新研究入库时按以下顺序生成元数据草稿（字段标注来源分级：
`[D]` 数据可推导 / `[C]` Crossref 可预填 / `[P]` 需读论文 Methods（LLM 提取后人工核对）/ `[H]` 仅人工）：

1. **paper JSON 草稿**（11 字段）:
   - `[C]` `Paper_name`/`Author`/`Year`/`Journal`/`DOI` 由 Crossref API 预填（`works/<DOI>`）；
     Journal 用 `container-title`；preprint（`posted-content`）固定 `Journal: "Preprint"` 且 DOI 存裸格式（去掉 `https://doi.org/` 前缀）；unpublished 无 DOI → 模板手工填。
   - `[P]` `Summary`/`Conclusion` 由论文摘要/结论生成；`[H]` `Country`/`City`/`Email` 需人工；`Extra_Var` 无则 `/`。
   - 校验：`Year` == 文件夹年份（Crossref 年份规则见 §DOI 与年份核验）。
2. **experiment JSON 草稿**（v2 五组件）:
   - `[D]` `Block_Structure.Trial_number` 从 Clean 行数÷被试数推算（与论文/CSV `numTrials` 交叉核对口径：per-block vs total）；
     `Stimulus_Properties.Modality` 从 CSV `Stim_Type` 映射；`Equipment.Software` 从 CSV `Environmental_Info`。
   - `[P]` `Physical_Environment`/`Trial_Structure`/`Experimental_Design`/`Stimulus_Properties` 细节从论文 Methods 提取；
     `Setting` 必须用受控词表（Laboratory/Online/组合，见 §Five-component task framework）。
3. **人工确认**：所有 `[P]`/`[H]` 字段过一遍 Human decision points 清单。
4. **校验**：`validate_json_metadata.R` + `validate_clean_csv.R`（新增 exp JSON 后重跑）。

试点验证（2026-08，三个测试研究）：Vicovaro_2022_JEPHPP（Journal）与 Navon_2021_psyarxiv（Preprint）的
paper JSON 草稿字段（title/authors/year/journal）与现有文件完全一致；Sui_2014_unpub（unpublished）走手工模板。

## Human decision points（人工决策清单 — 遇到即暂停，等待确认）

自动化整理中以下环节**必须人工确认**，agent 不得自行推断覆盖：

1. **年份口径**：Crossref 无 `published-print` 且非纯在线期刊、预印本版本年有争议时，暂停确认。
2. **期刊缩写**：无现成缩写对照时（新期刊/新库），人工定缩写（可读性原则）。
3. **N 口径冲突**：`Sample_Size`（入组）vs `Valid_Subj`（有效）vs `*_subj_info.csv` 行数 vs Clean Subject 数，
   任一不一致 → 暂停人工确认；排除被试（测试运行/无数据/默认人口学）必须在脚本注释中写明证据。
4. **License**：数据页/论文未明确声明时，填 "No License" 需人工确认（与稿件 "Not specified" 的语义等同关系）。
5. **Identity 映射歧义**：原文多义（如 `fm`、friend vs close 边界）→ 保留原文到 Origin 列，English/Standardized 暂填并注释待确认。
6. **实验编号**：无 Paper_ID 且文件夹结构无法推导 Exp 时，留空待人工。
7. **输入区异常**：多格式混存、损坏文件、per-participant 命名无法对应实验/会话时，暂停人工判断。
8. **数据获取**：Repo_Link 缺失/失效、数据未公开时，暂停（不得用稿件/旧产物反推数据）。
9. **unpublished 研究**：无 DOI，paper JSON 手工填写（Summary/Conclusion 可 `"/"`），年份以数据收集年为准。
10. **稿件/旧产物**：一律仅作参考线索，永不作为数据来源覆盖 1_Data/（稿件 v16 已废弃）。

## Validation and hygiene

1. After any metadata change run:
   `Rscript 2_Code/validate_json_metadata.R` (checks naming, year drift, exp-key match,
   v2 component completeness; exits non-zero on violations).
2. After any clean-data change run the **content-level checker** (2026-08):
   `Rscript 2_Code/validate_clean_csv.R` — for every `*_Clean.csv` outside the raw
   input zone: E1 missing `Subject` column; E2 incomplete Identity triple
   (`X_Origin_Identity` without `X_English_Identity`/`X_Standardized_Identity`);
   E3 Subject count vs `*_subj_info.csv` rows; W1 missing standard columns (with
   alternative-column hints); W2 Subject count vs CSV `Valid_Subj`/`Sample_Size`
   (known caliber differences); W3 ACC value domain; W4 non-standard filenames.
   ERROR → exit 1; historical exceptions are listed in the script `known` vector
   (KNOWN, exempted; remove the entry once fixed — same pattern as `known_pending`).
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
