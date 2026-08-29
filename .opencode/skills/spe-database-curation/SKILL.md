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
- **`Dataset_inf.csv` 列说明（40 列，按用途分组）**：
  - 键列：`ID`（行号）、`Folder_Name`（关键 ID）、`Exp`（实验号）、`Study`（论文内序号）、`Paper_ID`/`Paper`（**deprecated**，勿新建值）
  - 文献信息：`FirstAuthor`、`Year`（印刷年）、`PubType`（Journal/preprint/unpublished data）、`Journal`、`DOI`（论文 DOI）、`Country`、`City`、`Corresponding_author`、`Email`、`Repo_Link`（数据链接）、`License`、`Note`
  - 样本量：`Sample_Size`、`Male`、`Female`、`Valid_Subj`、`Drop_Subj`
  - 设计：`Design`、`subj_Group`（被试分组列，**2026-08 起每 group 一行**：
    行的唯一性 = `Folder_Name` + `Exp` + `subj_Group` 三元组。组间设计研究按组
    拆分为多行（Exp 不变），每行 `subj_Group` 填**单个**原文组名（如
    `LpSTS`，不用分号堆叠——该做法已废弃）；无组间设计保持单行填 `All`。
    展开后每行的 `Sample_Size`/`Valid_Subj`/`Male`/`Female` 填**组内值**
    （数据可拆按数据、否则按论文、论文无则 `/`），总体口径与组名映射记
    Note；展开行的 `ID`/`Paper_ID`/`Paper` 无稿件对应时留空（deprecated
    列，勿新建值）。**组间判定**（2026-08 沉淀）：`Design` 列含
    between-subjects/Group 标记是直接依据，但 Design 未标注不代表无组间——
    需以全文核对（案例：Xu_2022、Constable_2020 Switch Identity、Vicovaro
    E2 self-symmetry/asymmetry 均仅见于全文）；试次级/被试内变量不展开
    （案例：Xu_2022 的 high/low attractiveness 在数据无编码仅按
    acceptance/rejection 展开、Constable_2021 的 Stimuli_Type 为组列）；
    在线研究（MTurk/Prolific 等）按平台被试主体标 Country（如 MTurk→
    United States，2026-08 用户指示）。`Extra_Ind_Var`、`Stim_Type`、`Stim_language`、`Self`、`Close`、`Others`
  - 流程：`Practice_Block`、`Practice_Trial`、`numBlocks`、`numTrials`、`Environmental_Info`（**刺激呈现软件**，非 Lab/Online 设置）
    **numTrials 口径（2026-08 P15 决策）**：一律填**每被试总试次数（total）**，不填 per-block；
    应能与实验条件数整除出每条件试次数（如 8 条件×60=480）。多 session/多 run 设计（如
    Qian E1 4 sessions×144）按全 session 合计。**Practice_Trial（2026-08 P16 决策）** =
    任务正式练习段试次数；学习/训练映射段（如 Constable_2019 E4 的 50 次 "who does this
    stimulus represent" 训练）**不属于练习**，不填入；同一研究练习数视条件而变时填
    "21 or 41" 式文本（与 exp JSON 一致）。
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
- **`Country`/`City` 语义 = 数据采集地，不是作者单位**（2026-08 澄清）：paper JSON 曾误填作者单位（如通讯作者牛津但数据清华采集）；以数据来源为准——被试语言/姓名/采集年/第一作者单位。Dataset_inf.csv 与 paper JSON 需一致；发现 paper JSON 与 CSV 不一致时，先核数据采集地再决定是否同步更新 paper JSON。`Setting`=Online 时 `City` 可填 `/`。
  **采集地判定依据（2026-08 沉淀）**：① 论文直写采集地/被试语言/货币/招募机构（最强）；② **伦理委员会批准机构 = 数据采集机构**（惯例：论文声明获批的伦理机构即采集所在地，2026-08 案例：Constable_2020/Wozniak_2018 均经 Central European University 批准 → 采集地 Budapest）；③ 作者单位 + 全文环境描述（实验室采集）为佐证；④ 作者履历单位（如 Wozniak 的 Australia/Poland/Hungary）**不是**采集地依据。
- **`Email` 以 Dataset_inf.csv 现值为准**：CSV Email 常为通讯作者当前单位邮箱，与论文发表时邮箱可能不同；paper JSON 与 CSV 不一致时不自动"修正"，问用户。
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
  **Setting = Online 时**：`Physical_Environment.Location` 与 Dataset_inf.csv / paper JSON 的
  `City` 可不填（在线被试可分布于任何地点，位置无意义）——填 `/` 或 `N/A` 均可，无需追查。
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
  **非身份刺激特例（2026-08 P12 沉淀）**：非自我参照的刺激（如奖赏参照
  任务的货币金额 `£9`/`£1`，Lee_2023_Cognition E2）Standardized 按**原样**
  保留（`£9`/`£1`），不强行归入 6 类词表——它不是身份类别，原样记录保留
  任务语义；Codebook 枚举同步列出。
  **自定义 Std 值先例（2026-08）**：6 类词表外的自定义 Standardized 值已有
  先例——`£9`/`£1`（货币刺激，Lee E2）、`ingroup`（内群体成员/搭档，
  Constable_2019 E4 的 Coactor：pair 中另一名队友；论文行为与 Stranger 无
  差异但语义为组内成员，2026-08 用户决策）。使用条件：语义无法归入 6 类时
  允许原样/自定义值，须在 Codebook 枚举注明。
  **集体自我（group-self）规则（2026-08 P11/P14 沉淀，Constable_2019 系列）**：
  集体自我身份（we/team 类）全库仅 Constable_2019 使用。处理：① Origin 层
  保留原文（We/Team/Person1/Person2 等）；② English 层统一术语
  `Individual_Self/Group-Self/Individual_Stranger/Group-Stranger`（Shape 与
  Label 侧一致；E4 pair 研究 English 用字面 "Person 1"/"Person 2"）；③ Std
  层按论文口径归 Self（如 Constable 论文 "Self: Me and We" 二分类）；④ **CSV
  的 `Self`/`Close`/`Others` 三列 = Std 6 类的简写表达**：Self 列 = Std Self
  类身份集合（含 group-self，如 `Self/We`）、Close 列 = Std Close 类（无
  close-other 时留空）、Others 列
  = 其余身份——CSV 与 Std 必须同一口径，group-self 不得放入 Close 列
  （Close=亲近他人语义）；⑤ pair 研究中 Person 归属不可知时（如 Constable
  E4），CSV Self 列列全部候选（`P1/P2/Team`）并 Note 说明。
- **ACC 统一编码（2026-08 P21 方案 A，全库统一值域）**：
  实际按键相对应按键的比较，共 6 类（覆盖全部可能性）：

  | 码 | 含义 | 对应类别 |
  |---|---|---|
  | `1` | 正确：与应按键一致 | ① 按键一致 |
  | `0` | 错误：在响应窗口内按键但按错（属于规定按键范围） | ② 范围内错键 |
  | `NA` | 无反应：响应窗口内没有按键 | ③ 无按键 |
  | `-2` | 范围外按键：与应按键不一致且不在规定按键范围（如要求 f/j 却按 k） | ④ 范围外键 |
  | `-3` | 提前按键：刺激尚未出现就按键 | ⑤ 提前（少见，多数程序不记录） |
  | `-4` | 超时按键：响应窗口结束后才按键 | ⑥ 反应过迟（少见） |

  规则：① 清洗产物统一用上表编码；② **`-2`/`-3`/`-4` 仅在有明确证据时
  编码**（如 raw/Response 列显示实际按键超出规定范围、或程序明确记录提前/
  超时事件），无明确证据时编码为 `NA` 即可（宁缺毋滥，不臆断）；③ 无反应
  一律 `NA`（不用数字码）；④ 重编码前必须逐研究确认原特殊码语义
  （Codebook/raw/清洗段/论文，E-Prime 惯例 3=no response 等），不得凭值
  猜测；⑤ 有 `Response` 实际按键列的文件可用「应按键 vs 实际键」验证或
  重建 ACC；无 `Response` 列的文件只能依据原码语义映射或留待 raw 追补；
  ⑥ Codebook 的 `Variable_value` 同步列出码义（如 `1 (correct); 0
  (incorrect); NA (no response); -2 (out-of-range key); -3 (early
  response); -4 (late response)`）。全库摸底（2026-08）：58 个 Clean 文件
  中 44 个为 0/1 标准码；特殊码涉及 10 个文件（Constable 系列 ACC=3、
  Dalmaso ACC=2、Hu_2020 ACC=-1/2、Sui_2015 ACC=3/4、Vicovaro/Xu/Zhang/
  Sun/Hu_2023 ACC=NA）；37 个文件有 Response 列、21 个无。
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
- **现成模板（2026-08-27 起）**：`2_Code/make_codebooks.R`——R openxlsx 实现（单 Sheet1 4 列、
  枚举值取数据 unique 含特殊码），改 `jobs` 列表即可复用；阶段 1 已用其生成 6 个 Codebook。
  阶段 2 前置可用 `2_Code/analyze_csv_blanks.py` 重扫 Dataset_inf.csv 空白基线。

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
- **Subject 编号与数据对齐规则（2026-08 阶段 3 沉淀，Vicovaro_2022_JEPHPP Exp2 教训）**：
  1. **编号只承载唯一性，条件信息由数据列承载**：Subject 编号不编码 block/条件（Symmetry/Matching 等由 Clean 数据列表达）。raw participant_id 重复（多段/跨 block 共用同一 ID）时，统一按段号加后缀 `_1`/`_2`…，不引入条件后缀分支（如不写 `_selfS`/`_selfA`）；条件归属查数据列即可。
  2. **重复 ID 判定看"该 ID 总段数 > 1"，而非当前段号**：凡 participant_id 名下段数 > 1 → **所有段**都加段号后缀（不能只给后段加，否则第一段不唯一）；守卫 `stopifnot(length(unique(Subject)) == 预期被试数)`。
  3. **subj_info 与 Clean 的 Subject 对齐用键，不用行序**：构建期保留临时映射列（如 `Subject_raw = participant_id|block|seg_no`），subj_info 人口学按映射键对齐；**禁止依赖文件行序**（行序脆弱，键稳定）。写出 Clean 前删除临时列。
  4. **构建期中间映射内嵌脚本，不落盘独立文件**：Subject↔原始 ID 映射由脚本内存对象生成，明细写入脚本注释；研究文件夹只允许标准产物（raw/Clean/subj_info/Codebook/JSON + <Study>_clean.R），不产生 subject_map 等中间 CSV。
- **通用函数与独立脚本同库（2026-08）**：独立清洗脚本与 `1_Data/utils.R`（spe_root/write_clean_csv）
  同在 `1_Data/` 下，`source()` 同库引用，**不跨文件夹引用**（不要放 2_Code/ 再跨层 source）。
- **自动化整理（2026-08 方向）**：新研究入库/重整理由 agent 加载本技能完成——
  下载的原始数据放 `<Study>_Raw/` 输入区 → 扫描识别实验/被试/会话结构 → 生成
  独立清洗脚本 `<Study>_clean.R`（先例 `Sui_2015_unpub_clean.R`，配方参考
  `Clean_Data.Rmd` 对应段）→ 产出 `*_ExpN_Clean.csv` / `*_subj_info.csv` →
  元数据（paper/exp JSON、Codebook、Dataset_inf.csv）→ 两级校验
  （validate_json_metadata.R + validate_clean_csv.R）。`Clean_Data.Rmd` 降级为
   历史配方参考，其逐研究段逐步提取为独立脚本/配置。
- **阶段 4 辅助工具（2026-08 新增，2_Code/）**：
  - `repo_fetch.py` — 数据仓库下载辅助（OSF / PsychArchives）：`osf-list`/`osf-get`
    （按文件名子串匹配下载）/`pa-search`/`pa-files`/`pa-get`；先列文件清单再下载，
    目标已存在拒绝覆盖（用法见脚本 docstring；P5 沉淀：先 --list 可发现仓库重复
    上传/缺失，避免白下载）。
  - `scan_raw.py` — 原始数据快速扫描：列名/行数/每被试行数（整除判定）/
    列值分布/两列交叉表；大文件用 `--sample N`（行数与被试统计仍全量流式）。
    阶段 4 判定 raw 完整性（如 Smith 48 vs 59）与还原任务结构用。

## Dataset_inf.csv 标准读取模板（2026-08）

主索引格式约束（UTF-8 BOM + CRLF + QUOTE_MINIMAL + 末行无换行）对标准读取透明，
**优先用统一封装**，勿每次手写读取逻辑：

- **Python（推荐）**：`from read_dataset_inf import read_dataset_inf, find_rows`
  （`2_Code/read_dataset_inf.py`，已封装 BOM/引号/列名定位；`find_rows(rows, Folder_Name, exp=...)`
  按关键 ID 过滤）。不 import 时等价写法：
  `rows = list(csv.DictReader(open("1_Data/Dataset_inf.csv", encoding="utf-8-sig", newline="")))`
- **R**：`source("1_Data/utils.R"); inf <- read_dataset_inf()`（自动
  `fileEncoding="UTF-8-BOM"` + `check.names=FALSE`，第一列名不残留 `\ufeff`）。
  等价写法：`read.csv("1_Data/Dataset_inf.csv", check.names=FALSE, fileEncoding="UTF-8-BOM")`
- **取值一律用列名**：Python `row["Folder_Name"]` / R `inf$Folder_Name`，**禁止按列位置
  `r[0]`/`[1]` 取值**（ID 在第 1 列、Folder_Name 在第 2 列，位置易错——见 AGENTS.md
  §防坑「CSV 字节保真编辑纪律」）；改 CSV 前的往返测试与写后 truncate 纪律同见该节。
- CLI 速查：`python 2_Code/read_dataset_inf.py [--folder NAME] [--exp N]`

## Metadata & ingestion workflow（元数据入库/补齐统一流程，2026-08-27 沉淀）

适用于两种场景，统一 10 步流程（场景 B 专属步 + 汇合点元数据核心 + 共用收尾）：

### 适用场景
- **场景 A：元数据补齐（backfill）**——数据文件已存在（raw/Clean/subj_info 齐），缺 JSON/Codebook。
  触发：PROJ_STATE 已知问题 / validator 盲区（缺 paper JSON、缺 codebook）。
- **场景 B：新研究入库（ingestion）**——全新数据。触发：新数据到达 / `known_pending` 条目开始入库。

### 统一流程（10 步）

**场景 B 专属：数据产出（场景 A 跳过，仅做盘点）**
1. **建文件夹 + 输入区**：`1_Data/<Study>/<Study>_Raw/`（命名语法：印刷年、纯 ASCII、期刊/库缩写）。
2. **扫描输入区**：识别 实验/被试/会话 结构；格式异常或多格式混存 → 暂停（Human decision points #7）。
3. **清洗脚本**：`<Study>_clean.R`（从 `Clean_Data.Rmd` 对应段提取配方或对照标准列新写；模式见 §清洗工具提取规范与先例 `Sui_2015_unpub_clean.R`）→ 产出 `*_raw.csv`（标准 trial 级）+ `*_ExpN_Clean.csv`；`*_subj_info.csv` 从 raw/输入区人口学生成。
4. **内容级校验**：`Rscript 2_Code/validate_clean_csv.R`（E1–E3 必须 0 ERROR；W 级提示记录）。
- 场景 A 入口：**盘点缺口**——目标研究缺哪些 paper/exp JSON、Codebook（`ls` 各文件夹 + 与 Dataset_inf.csv 交叉；validator 盲区项需人工核对）。

**汇合点：元数据核心（场景 A/B 共用）**
5. **[C] 字段（paper JSON）**：`Paper_name`/`Author`/`Year`/`Journal`/`DOI` 由 Crossref API 预填（`works/<DOI>`）；Journal 用 `container-title`；preprint 固定 `Journal: "Preprint"` 且 DOI 存裸格式（去掉 `https://doi.org/` 前缀）；unpublished 无 DOI → 模板手工填；**DOI 本地优先**（先查 paper JSON / Dataset_inf.csv）；`Year` == 文件夹年份（年份规则见 §DOI 与年份核验）。
6. **[P] 字段（论文内容）**：`Summary`/`Conclusion` + Methods 五组件细节从论文提取。
   **全文查找顺序（强制，避免重复搜索/下载）**：
   ① 查 `REF/`（`<Folder_Name>.pdf/.html`）→ ② 无则**先向用户确认是否已有全文 PDF/HTML** → ③ 用户无才走 OA 渠道（unpaywall → eprints/PMC/出版社页面）→ ④ 实无全文：Europe PMC 摘要 + OSF README/预注册/补充材料 + 数据推导；仍缺字段留 `/` 并注明。
   **下载到的全文/资料落盘 `REF/`**（命名：`<Folder_Name>.pdf/.html` + `_supp.docx`（补充材料）/`_prereg.pdf`（预注册）/`_OSF_README.docx`/`_PMC.xml`）。
   `[H]` `Country`/`City`/`Email` 需人工（可用 Dataset_inf.csv 现值）；`Extra_Var` 无则 `/`。
7. **[D] 字段（experiment JSON）**：`Block_Structure.Trial_number` 从 Clean 行数÷被试数推算（与论文/CSV `numTrials` 交叉核对口径：per-block vs total；行数不整除时以论文值为准并注明）；`Stimulus_Properties.Modality` 从 CSV `Stim_Type` 映射；`Equipment.Software` 从 CSV `Environmental_Info`（空则查论文，未知 `/`）；`Setting` 受控词表（Laboratory/Online/组合，见 §Five-component task framework）。
8. **草稿 + 人工确认**：草稿写 /tmp（paper JSON 11 字段 / exp JSON v2 五组件 + `detail` 注明字段来源分级与遗留）；列出全部 `[P]`/`[H]` 不确定项（任务身份、软件、N 口径、Email、年份、License 等）→ **用户确认前不落盘**。
9. **Codebook**：按 §Codebook authoring rules 生成（单 `Sheet1` 4 列，覆盖全部 Clean 列，行数==Clean 列数；枚举值取数据 unique 含 NA/timeout/None 等特殊值）。

**收尾（场景 A/B 共用）**
10. **落盘 + 校验 + 同步**：`cp` /tmp → 目标（exFAT 无原子写，先 /tmp 中转）；场景 B 更新 `Dataset_inf.csv`（每实验一行 `Folder_Name`+`Exp`，UTF-8 **带 BOM** 字节保真，不动 legacy `Dataset_inf.xlsx`）；`validate_json_metadata.R` EXIT=0 + `validate_clean_csv.R` 0 ERROR；场景 B 另需：`known_pending` 白名单移除 + `Generate_Table1.qmd` 重渲染（稿件比对默认关闭，仅稿件版本更新时 `--param compare_manu:true`）；更新 PROJ_STATE.md；exFAT 卫生（git 前清理 `._*`，绝不提交 `._*`/`.DS_Store`）。

**试点验证（2026-08）**：Vicovaro_2022_JEPHPP（Journal）与 Navon_2021_psyarxiv（Preprint）的 paper JSON 草稿字段（title/authors/year/journal）与现有文件完全一致；Sui_2014_unpub（unpublished）走手工模板。
**阶段 1 批量回填（2026-08-27）**：Lee/Smith/Svensson/Orellana 4 研究 10 JSON + 6 Codebook——[C] Crossref 核对、[P] 全文来源（Smith=REF/ html、Svensson=PMC XML、Orellana=Springer html、Lee=eprints PDF+补充材料）、[D] Clean 行数÷被试数；两级校验全绿（90 JSON EXIT=0；59 Clean 0 ERROR）。

## Human decision points（人工决策清单 — 遇到即暂停，等待确认）

自动化整理中以下环节**必须人工确认**，agent 不得自行推断覆盖：

1. **年份口径**：Crossref 无 `published-print` 且非纯在线期刊、预印本版本年有争议时，暂停确认。
2. **期刊缩写**：无现成缩写对照时（新期刊/新库），人工定缩写（可读性原则）。
 3. **N 口径（数据口径优先，2026-08 确认）**：`Sample_Size` = Clean 中被试总数（= Clean `unique(Subject)` 数）；`Valid_Subj`/`Drop_Subj` 为派生值——清洗 = 最小预处理不过滤，故通常 `Valid_Subj` = `Sample_Size`、`Drop_Subj` = 0；清洗脚本实际移除的问题被试（测试运行/无数据/默认人口学，需在脚本注释写明证据）计入 `Drop_Subj`。`*_subj_info.csv` 行数应等于 Clean Subject 数。论文的招募/排除口径记入 Note 列（`Paper_N: ...` 前缀）供追溯，不以论文口径覆盖数据口径。任一不一致 → 暂停人工确认。
4. **License**：**License 列 = 数据许可，不是论文/文章许可**——只看数据存储库/数据页声明（OSF 等），期刊文章页的 Creative Commons 图标属于文章许可，两者不可混。无 OSF/数据链接信息时填 `/`（2026-08 用户决策）；数据页/论文明确声明时按声明填写（如 CC BY 4.0、CC BY-NC-ND、No License）。
5. **Identity 映射歧义**：原文多义（如 `fm`、friend vs close 边界）→ 保留原文到 Origin 列，English/Standardized 暂填并注释待确认。
6. **实验编号**：无 Paper_ID 且文件夹结构无法推导 Exp 时，留空待人工。
7. **输入区异常**：多格式混存、损坏文件、per-participant 命名无法对应实验/会话时，暂停人工判断。
8. **数据获取**：Repo_Link 缺失/失效、数据未公开时，暂停（不得用稿件/旧产物反推数据）。
9. **unpublished 研究**：无 DOI，paper JSON 手工填写（Summary/Conclusion 可 `"/"`），年份以数据收集年为准。
10. **稿件/旧产物**：一律仅作参考线索，永不作为数据来源覆盖 1_Data/（稿件 v16 已废弃）。
11. **多任务论文口径**：同一论文含多个任务（如 AB + 匹配）时，`Practice_Trial`/`numBlocks`/`numTrials` 取产生该行数据那个任务的值；发现论文中存在但 CSV 未收录的实验行（如 Wang_2016 Exp2/control），登记待入库，不擅自补行。
12. **已发表论文核查对照全文，不只扫空白**：元数据补全/核查时直接对照 `REF/` 全文（期刊名拼写、身份列拼写、Others 措辞、N 口径、实验行数都可能与空白清单外的问题共存，2026-08 案例：Kirk `Psycholog`/`Slef`、Sui_2014 N 不符、Wang 缺 Exp2）。（2026-08 阶段 2 沉淀）

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
