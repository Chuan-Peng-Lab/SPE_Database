---
name: spe-database-curation
description: SPE Database curation conventions — 以 agent 工作流为中心：入库 10 步流程与入口判定、
  人工决策点、文件命名语法、JSON 元数据 schema（paper + experiment v2 五组件）、Identity 三级标准化、
  ACC 统一编码、Codebook 编写规则、DOI/年份核验（Crossref）、Dataset_inf.csv 主索引规则、两级校验。
  原始数据解析先例（E-Prime/PsychoPy/MATLAB/作者产物）见附属文件 parsing-examples.md，工具细节见 tools.md。
  使用场景：在 1_Data/ 下新增或整理研究/实验文件夹、编写或编辑 *_raw/_Clean CSV、Codebook_*.xlsx、
  .json 元数据、Identity 列、Dataset_inf.csv 主索引，或校验元数据。
license: MIT
metadata:
  audience: data-curators
---

## 技能定位

SPE Database（self-matching task, Sui et al. 2012）整理与入库规则：root → study → experiment 三层，
每层带机器可读 JSON 元数据。本技能是 curation 规范，**规则正文自足**（文件命名/JSON schema/Identity
三级标准化/ACC 编码/列序模板 v2/Codebook/主索引字段语义/缺失三态/校验规则不依赖仓库级文档，可迁移
任何采用本布局的 SPE 风格数据库）。**仅本仓库适用的内容**（迁移他库时删除）：工具路径与命令注记
（`2_Code/`、`1_Data/utils.R`、`read_dataset_inf.py`、`Rscript …validate_*.R`，细节在 tools.md）；
仓库集成收尾注记（PROJ_STATE.md 登记、AGENTS/README 计数、exFAT 卫生——正文在 AGENTS.md）。

**文件组成**：`SKILL.md`（本文件，工作流+核心规则+速查表，日常加载）；`parsing-examples.md`
（原始数据解析与验证先例详细版，按格式分组，遇对应格式时按速查表读取）；`tools.md`（工具端点与用法，少数任务才读）。

## 多语言与编码约定（多语言数据库的包容性）

本库数据本身是多语言的：各研究刺激值/标签/身份原文来自不同语言（中文/荷兰语/德语/英语等），
`Shape`/`Label` 等数据列与 `*_Origin_Identity` 一律**保留原文语言**（不英化、不转写），Codebook
枚举照实列出；跨语言可比性由 `*_English_Identity`/`*_Standardized_Identity` 层与 6 类受控词表提供
（见 §数据标准化）。文件与元数据层统一：文件名纯 ASCII（§文件与文件夹规范）、JSON 字段值英文
（§元数据 JSON）。

**编码约定**：CSV 产物一律 UTF-8；主索引 `Dataset_inf.csv` 为 UTF-8 **带 BOM** + CRLF +
QUOTE_MINIMAL + 末行无换行。BOM 不是某个语言的特殊处理，而是**多语言兼容约定**：带 BOM 的 UTF-8
在被按本地默认编码打开的工具（如默认 GBK 的中文 Windows Excel）中仍能正确显示 CJK/`ö é ü` 等
内容，无 BOM 则可能乱码；读取对 BOM/行尾透明（用封装或 `utf-8-sig`）。任何编辑必须字节保真
（往返测试 → 写入 → diff 仅目标单元格），细则见 §主索引「写入纪律：CSV 字节保真编辑」。

## 入库工作流（10 步 + 入口判定 + 四方核对 + 收尾检查清单）

### 入口判定：按论文文件夹现状选择起点

加载本技能后**第一步**：查看目标论文的 `1_Data/<Study>/` 现状，按下表选入口，不要从头跑 10 步：

| 文件夹现状 | 入口 | 对应原场景 |
|---|---|---|
| 全新数据（输入区已有原始导出，无五件套） | 第 1 步全流程 | 场景 B（ingestion） |
| raw/Clean/subj_info 已齐、缺 JSON/Codebook | 第 5 步（元数据核心） | 场景 A（backfill） |
| Clean 已齐、缺标准 `*_raw.csv` | 第 3 步清洗脚本，或按豁免原则判定（见下） | 阶段 4 |
| 五件套已齐、仅需校验/收口 | 第 10 步 | — |
| 已有文件夹但 CSV 无行（known_unlisted） | 先登记 Dataset_inf.csv（第 10 步前置），再按上表 | — |

### 统一流程（10 步）

**数据产出（仅全新数据需要；其余入口跳过）**
1. **建文件夹 + 输入区**：`1_Data/<Study>/<Study>_Raw/`（命名语法见「文件与文件夹规范」：印刷年、纯 ASCII、期刊/库缩写）。
2. **扫描输入区**：识别 实验/被试/会话 结构；格式异常或多格式混存 → 暂停（决策点 #7）；先查「原始数据解析与验证先例」速查表定位格式条目。
3. **清洗脚本**：`<Study>_clean.R`（对照标准列新写；规范见「工具与脚本」§独立清洗脚本）→ 产出 `*_raw.csv`（标准 trial 级）+ `*_ExpN_Clean.csv`；`*_subj_info.csv` 从 raw/输入区人口学生成。
4. **内容级校验**：`Rscript 2_Code/validate_clean_csv.R`（E1–E3 必须 0 ERROR；W 级提示记录）。

**元数据核心（场景 A/B 共用）**
5. **[C] 字段（paper JSON）**：`Paper_name`/`Author`/`Year`/`Journal`/`DOI` 由 Crossref API 预填（`works/<DOI>`）；Journal 用 `container-title`；preprint 固定 `Journal: "Preprint"` 且 DOI 存裸格式；unpublished 无 DOI → 模板手工填；**DOI 本地优先**（先查 paper JSON / Dataset_inf.csv）；`Year` == 文件夹年份（见「DOI 与年份核验」）。
6. **[P] 字段（论文内容）**：`Summary`/`Conclusion` + Methods 五组件细节从论文提取。**全文查找顺序（强制）**：① 查 `REF/`（`<Folder_Name>.pdf/.html`）→ ② 无则先向用户确认是否已有全文 → ③ 用户无才走 OA 渠道（unpaywall → eprints/PMC/出版社页面）→ ④ 实无全文：Europe PMC 摘要 + OSF README/预注册/补充材料 + 数据推导；仍缺字段留 `/` 并注明。下载到的全文落盘 `REF/`（`<Folder_Name>.pdf/.html` + `_supp.docx`/`_prereg.pdf`/`_OSF_README.docx`/`_PMC.xml`）。
   `[H]` `Country`/`City`/`Email` 需人工（可用 Dataset_inf.csv 现值）；`Extra_Var` 无则 `/`。
7. **[D] 字段（experiment JSON）**：`Block_Structure.Trial_number` 从 Clean 行数÷被试数推算（与论文/CSV `numTrials` 交叉核对口径：per-block vs total；行数不整除时以论文值为准并注明）；`Stimulus_Properties.Modality` 从 CSV `Stim_Type` 映射；`Equipment.Software` 从 CSV `Environmental_Info`（空则查论文，未知 `/`）；`Setting` 受控词表（Laboratory/Online/组合，见「元数据 JSON」§五组件）。
8. **草稿 + 人工确认**：草稿写 /tmp（paper JSON 11 字段 / exp JSON v2 五组件 + `detail` 注明字段来源分级与遗留）；列出全部 `[P]`/`[H]` 不确定项（任务身份、软件、N 口径、Email、年份、License 等）→ **用户确认前不落盘**。
9. **Codebook**：按「Codebook 编写规则」生成（单 `Sheet1` 4 列，覆盖全部 Clean 列，行数==Clean 列数；枚举值取数据 unique 含 NA/timeout/None 等特殊值）。

**收尾**
10. **落盘 + 校验 + 同步（通用收尾）**：`cp` /tmp → 目标；更新 `Dataset_inf.csv`（每实验一行
    `Folder_Name`+`Exp`，UTF-8 **带 BOM** 字节保真——写入纪律见 §主索引「写入纪律：CSV 字节保真编辑」，
    不动 legacy `Dataset_inf.xlsx`）；`validate_json_metadata.R` EXIT=0 + `validate_clean_csv.R` 0 ERROR；
    `known_pending`/`known_unlisted` 白名单同步。**本仓库集成注记（仅 SPE_Database 适用，迁移他库删除）**：
    更新 PROJ_STATE.md（3 节类别行 + 5 节快照数字，见下方检查清单）；AGENTS/README 计数同步（如有）；
    exFAT 卫生（git 前清理 `._*`、不提交 macOS cruft——正文见 AGENTS.md §会话约定，此处仅指针）。

### 入库后四方核对（场景 B 收尾必做）

论文全文 ↔ 作者分析代码（OSF dataPrep/SPSS 脚本）↔ 库内数据（CSV/JSON/Clean/raw）↔ OSF 原始导出，逐字段交叉 + **论文描述性统计核对**（论文报告的均值/正确率/方向，按作者脚本口径聚合）。**用户指示：只核对描述性统计，不复现统计检验/回归模型结果**——逐值/聚合数据一致性验证仍必做（方法见 parsing-examples.md §作者脚本逐值验证法）。发现的问题按「可自动确定（有全文/数据证据）→ 修改；需人工 → 记录于 `3_Reports/Verifying_original_results_issues.md`（Issue 编号）+ exp JSON detail/CSV Note」处置；**是否联系作者由项目负责人决定**（超库范围不主动执行）。
**验证时机建议**：作者聚合逐值验证宜在**清洗脚本产出后、CSV 行收口前**完成——数据层证据（列解码、身份映射、ACC/RT 口径）先行确认，发现问题时只需改清洗脚本重跑，避免 CSV/JSON 已写死后再返工；论文方向性核对与 CSV 收口可同步进行。

### 收尾检查清单（第 10 步，不含渲染）

```
**通用收尾（迁移他库保留）**
□ 五件套齐全且命名合规（raw/Clean/subj_info/Codebook/paper+exp JSON）
□ 两级校验：validate_json_metadata.R EXIT=0 + validate_clean_csv.R 0 ERROR
□ Dataset_inf.csv 收口（字节保真：往返测试 → 写入 → diff 仅目标单元格 → ID 行序保持；
  纪律见 §主索引「写入纪律：CSV 字节保真编辑」）
□ known_pending/known_unlisted 白名单同步

**本仓库集成（仅 SPE_Database 适用，迁移他库删除）**
□ PROJ_STATE.md 登记：3 节对应类别行更新 + 5 节现状快照数字同步（完成进度不追加——只入 git commit）
□ AGENTS/README 计数同步（如有）
□ exFAT 卫生：git 前清理 ._*、不提交 macOS cruft（正文见 AGENTS.md §会话约定）
（Table 1 渲染不做：qmd 为动态 keep-by-folder 逻辑，新研究自动入表；仅在稿件版本更新时 --param compare_manu:true 渲染）
```

## 人工决策点（13 条 — 遇到即暂停，等待确认）

自动化整理中以下环节**必须人工确认**，agent 不得自行推断覆盖：

1. **年份口径**：Crossref 无 `published-print` 且非纯在线期刊、预印本版本年有争议时，暂停确认。
2. **期刊缩写**：无现成缩写对照时（新期刊/新库），人工定缩写（可读性原则）。
3. **N 口径**：`Sample_Size` = Clean 中被试总数；`Valid_Subj` = 作者 summary-data 初步分析后保留的被试量（最小预处理不删除故通常 = Sample）；`Drop_Subj` = Sample − Valid；招募/论文 N 与 Clean 不一致时记 Note 列 `Paper_N:` 前缀；任一不一致 → 暂停人工确认。规则正文见「主索引 Dataset_inf.csv」。
4. **License**：**License 列 = 数据许可，不是论文/文章许可**——只看数据存储库/数据页声明（OSF 等），期刊文章页的 CC 图标属于文章许可，两者不可混。无数据许可声明时**留空**（空白 = 不确定；三态见「主索引」缺失标记规则），数据页/论文明确声明时按声明填写；明确无许可时标 `NA`。规则正文见「主索引 Dataset_inf.csv」。
5. **Identity 映射歧义**：原文多义（如 `fm`、friend vs close 边界）→ 保留原文到 Origin 列，English/Standardized 暂填并注释待确认。
6. **实验编号**：无 Paper_ID 且文件夹结构无法推导 Exp 时，留空待人工。
7. **输入区异常**：多格式混存、损坏文件、per-participant 命名无法对应实验/会话时，暂停人工判断。
8. **数据获取**：Repo_Link 缺失/失效、数据未公开时，暂停（不得用稿件/旧产物反推数据）。
9. **unpublished 研究**：无 DOI，paper JSON 手工填写（Summary/Conclusion 可 `"/"`），年份以数据收集年为准。
10. **稿件/旧产物**：一律仅作参考线索，永不作为数据来源覆盖 1_Data/（稿件 v16 已废弃）。
11. **多任务论文口径**：同一论文含多个任务（如 AB + 匹配）时，`Practice_Trial`/`numBlocks`/`numTrials` 取产生该行数据那个任务的值；发现论文中存在但 CSV 未收录的实验行，登记待入库，不擅自补行。
12. **已发表论文核查对照全文，不只扫空白**：元数据补全/核查时直接对照 `REF/` 全文（期刊名拼写、身份列拼写、Others 措辞、N 口径、实验行数都可能与空白清单外的问题共存，案例：Kirk `Psycholog`/`Slef`、Sui_2014 N 不符、Wang 缺 Exp2）。
13. **缺失标记三态分类**：单元格属 `missing`（明确无法获得）/ 空白（不确定有无）/ `NA`（明确没有/不适用）中哪一类属人工判断——分类不明或证据不足时暂停确认；改标前先查 exp JSON detail / 论文 / 数据，禁止凭值猜测。规则正文见「主索引 Dataset_inf.csv」缺失标记。

## 文件与文件夹规范

### 文件命名语法

`<FirstAuthorLast>_<Year>_<Suffix>[_Exp<N>][_<tag>]`

- **Year** = official **print** year; online-first year does not go into names
  (e.g., `Kirk_2025_BritJPsy`, not 2024; `Liang_2022_HumBrainMap`, not 2021).
- **`<Suffix>`** = a READABLE journal/database abbreviation (a professional
  should be able to guess the journal from it), a full short journal name, or a
  lowercase preprint/unpublished tag:
  - Journal abbreviations in use:
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
    `elife` (`Scheller_2026_elife`; deferred — 输入区保留、CSV 行已移除).
  - Database abbreviations: when the source is a data repository rather than a
    journal, use the repository's abbreviation, e.g. `ChinaSciData`
    (`Hu_YQ_2026_ChinaSciData`; deferred — 无文件夹；原 `Hu_2023_SDB`/`SDB` 旧名已废弃).
  - Preprint/unpublished tags (lowercase): `psyarxiv` for PsyArXiv preprints
    (e.g., `Navon_2021_psyarxiv`, `Hu_2023_psyarxiv`); `unpub` for
    unpublished data without a preprint server (e.g., `Sui_2014_unpub`,
    `Sui_2015_unpub`, `Pan_2025_unpub`).
- **Tags**: `_raw` (unprocessed), `_subj_info` (participant level), `_Clean`
  (minimally preprocessed), `Codebook_*_Clean.xlsx` for codebooks.
- **Canonical casing**: `Codebook_` (lowercase b), `_raw_` (lowercase);
  legacy `CodeBook_…`/`Raw/` 变体已统一/不再沿用 — do not propagate.
- **Filenames must be pure ASCII** (no diacritics).

### 文件夹结构

- **Root**: `1_Data/Dataset_inf.csv` — master index（见「主索引 Dataset_inf.csv」节）。
- **Study folder**: `<Author>_<Year>_<Journal>` containing the paper-level
  `<Author>_<Year>_<Journal>.json` at its root.
- **Single experiment** → files live flat in the study folder
  (e.g., `1_Data/Amodeo_2024_CABN/`):
  ```
  Amodeo_2024_CABN.json                       # paper metadata
  Amodeo_2024_CABN_Exp1.json                  # experiment metadata (v2)
  Amodeo_2024_CABN_Exp1_raw.csv               # raw trial-level data
  Amodeo_2024_CABN_Exp1_subj_info.csv         # participant-level data
  Amodeo_2024_CABN_Exp1_Clean.csv             # minimally preprocessed data
  Codebook_Amodeo_2024_CABN_Exp1_Clean.xlsx   # codebook
  ```
- **Multiple experiments** → each experiment gets its own `Exp1/…ExpN/` subfolder
  with the same five files inside; paper JSON stays at the study root
  (e.g., `1_Data/Sui_2014_APP/Exp1/…Exp4/`).
- 例外核查：`1_Data/Martinez-Perez_2024_ConsciousCog/` 为**单实验**（Exp2）平铺 study 根——其
  paper Exp1 无 self-matching 任务未收录（见 CSV Note），属正常单实验布局，非多实验偏差。
- **Raw input zone（输入区）**: downloaded original exports go into
  `1_Data/<Study>/<Study>_Raw/` (study level; all experiments together; a `Source/`
  subfolder for the original download is allowed). Historical lowercase `<Study>_raw/`
  variants coexist and remain legal (both `*_Raw/` and `*_raw/` are gitignored and
  skipped by the validators) — new input zones should use `<Study>_Raw/`. Supported
  formats: `.csv`, `.mat`, `.edat2`/`.emrg*`, `.psydat`/`.dat`, `.txt`, `.xlsx`. The
  input zone is **read-only input** — it does NOT participate in validation
  (`validate_json_metadata.R` and `validate_clean_csv.R` both skip `*_Raw/`, `*_raw/`
  and `Source/`), and its files are not standardized products. The standardized
  trial-level product derived from it is `<Study>_Exp<N>_raw.csv` (in `Exp<N>/` or the
  study root) — do not confuse the two: `*_Raw/` = downloaded originals (as-is),
  `*_raw.csv` = processed standard file.

## 主索引 Dataset_inf.csv

### 列说明（40 列，按用途分组）

- 键列：`ID`（**复合键**：格式 `<Folder_Name>_Exp<Exp>_<subj_Group>`，组名空格以下划线编码（如 `Constable_2021_CogEmo_Exp1_Happy_self`）；行唯一性即 `Folder_Name+Exp+subj_Group` 三元组唯一性；此前为数字行号，历史文档中的数字 ID 引用均为旧口径，不再使用）、`Folder_Name`（关键 ID）、`Exp`（实验号）、`Study`（论文内序号）、`Paper_ID`/`Paper`（**deprecated**，勿新建值）
- **行序约定**：数据行**始终按 ID 列字母序排列**（纯字典序，Python `sorted(key=ID)` 即同款）；新增研究入库时**追加后立即重排**（或直接插入排序位置），任何编辑后行序保持排序；校验手段：`python sorted` 检查或 `git diff` 只应显示内容/插入行而非整体乱序
- 文献信息：`FirstAuthor`、`Year`（印刷年）、`PubType`（Journal/preprint/unpublished data）、`Journal`、`DOI`（论文 DOI）、`Country`、`City`、`Corresponding_author`、`Email`、`Repo_Link`（数据链接）、`License`、`Note`
- 样本量：`Sample_Size`、`Male`、`Female`、`Valid_Subj`、`Drop_Subj`
  - **N 口径**：`Sample_Size` **一律 = Clean 中被试总数**（数据口径）；招募/论文报告 N 与此不一致时记 Note（`Paper_N: X recruited, Y excluded; N in database` 式）。`Valid_Subj` = **作者对 summary-data 初步分析后保留的被试量**（= 论文分析样本）；因本库最小预处理不删除被试，通常 Valid = Sample；仅当作者剔除了**库内仍保留**的被试时 Valid < Sample（先例 Orellana-Corrales_2021_APP E1：Clean 34 / Valid 28）。`Drop_Subj` = Sample − Valid（库内被作者排除数，通常 0）；**未进库的招募排除不占 Drop，只进 Note**。pair 粒度研究按人数口径（Clean Subject=pair ID 时例外）+ Note 记 pair 粒度。
- 设计：`Design`、`subj_Group`（被试分组列，**每 group 一行**：行的唯一性 = `Folder_Name` + `Exp` + `subj_Group` 三元组。组间设计研究按组拆分为多行（Exp 不变），每行 `subj_Group` 填**单个**原文组名（如 `LpSTS`，不用分号堆叠——该做法已废弃）；无组间设计保持单行填 `All`。展开后每行的 `Sample_Size`/`Valid_Subj`/`Male`/`Female` 填**组内值**（数据可拆按数据、否则按论文、论文无则 `/`），总体口径与组名映射记 Note；展开行的 `ID`/`Paper_ID`/`Paper` 无稿件对应时留空。**组间判定**：`Design` 列含 between-subjects/Group 标记是直接依据，但 Design 未标注不代表无组间——需以全文核对（案例：Xu_2022、Constable_2020 Switch Identity、Vicovaro E2 self-symmetry/asymmetry 均仅见于全文）；试次级/被试内变量不展开；在线研究（MTurk/Prolific 等）按平台被试主体标 Country（如 MTurk→United States）。`Extra_Ind_Var`、`Stim_Type`、`Stim_language`、`Self`、`Close`、`Others`
- 流程：`Practice_Block`、`Practice_Trial`、`numBlocks`、`numTrials`、`Environmental_Info`（**刺激呈现软件**，非 Lab/Online 设置）
  - **numTrials 口径**：一律填**每被试总试次数（total）**，不填 per-block；应能与实验条件数整除出每条件试次数（如 8 条件×60=480）。多 session/多 run 设计（如 Qian E1 4 sessions×144）按全 session 合计。
  - **Session 语义**：`Session` = 完成一个通常意义上的完整心理学实验的一次参加（如 6 blocks、约 1 小时；完成后被试离开实验室或下线）。被试再次来实验室/上线完成另一个完整实验 = 下一个 session（如纵向研究 T2/T3）。同一参加内的重复任务段（如 fMRI 连续 5 个 run）**不叫 session**——用 `Block`（或 Run）列。案例：Atzeni_2026 T2/T3 = 两次独立上线 → Session 列 ✓；Zhang_2026 的 5 个 fMRI "session" 实为同一次扫描内 5 个 run → Clean 列名 Block（作者原列名 session 保留于 raw）。
  - **纵向/多时点研究**：同一任务多个测量时点（如 T2/T3）**不拆 Exp、不拆 subj_Group**——合并为单 Exp 行，Clean 加 `Session` 列区分时点；`Sample_Size` = 跨时点 unique 被试数（数据口径），各时点 N 与重叠记 Note；`numTrials` 填每时点试次数（文本式注明重复/部分 session）。Clean 列一律英文（作者变量名如 'condizione' 用英文对应名 Condition；raw 保留作者原名）。
  - **同批被试完成多个实验**：**确认同一批被试参加了同一论文/研究内的两个或以上实验**（判定依据：原始导出文件按被试对齐且被试号完全重叠、subj_info 人口学逐行一致、raw 结构同构）时——**合并为单个 Clean 数据文件**，实验/条件差异用列区分（如 `Task`、`Condition`、`Session`、`extraIV` 或研究特有列），Dataset_inf 不拆多 Exp 行、`Sample_Size` = 唯一被试数；合并前**必须核查各实验数据是否真实不同**（比较原始 trialMat/响应/刺激/奖励等字段；若逐行相同则是同数据重复/误拆分，若结构同构但 trial 内容不同才是真多实验）。仅当实验为**明确独立的被试间新招募**时才拆 Exp。案例：Sui_2015_unpub Exp1（无奖励）与 Exp2（rewardValues 1/4/16）同批 20 名被试、同刺激体系——**已合并**为单文件（Session→Phase、extraIV1=逐 trial 奖励值 0/1/4/16、保留 Block/Trial）；Liang_2022_HumBrainMap 为组间拆 Clean 先例（Clean 加 `Group` 列区分组，见列顺序模板 [Group]）。核查方法见 parsing-examples.md。
  - **Practice_Trial 口径** = 任务正式练习段试次数；**与正式试次结构相同（仅有或无反馈）的熟悉/练习段计入练习**（先例：Kirk_2025_BritJPsy familiarization 12 试次计入）；纯学习/问答式训练段**不属于练习**，不填入（Constable_2019 E4 的 50 次 "who does this stimulus represent" 训练先例）；同一研究练习数视条件而变时填 "21 or 41" 式文本（与 exp JSON 一致）。缺失/不适用用三态标记（见本节缺失标记规则）。
- 状态：`Status`（**=1 判定标准**：最关键标准是**库内五件套（raw/Clean/subj_info/Codebook/paper+exp JSON）形成逻辑上完全一致、清晰可追溯的结构**——各层级互相印证、缺口已解释（豁免/占位/排除均有依据）；与原论文表述是否完全一致是**次要指标**，不一致不阻塞 Status=1，而是记录于 `3_Reports/Verifying_original_results_issues.md`（Issue 编号）及 exp JSON detail/CSV Note（先例：Zhang_2023_NeuroImage，Issue 5）；raw 豁免的研究不影响标记）、`Behavior_Data`、`Questionnaire_Data`、`EEG/fMRI Data`
- **缺失标记（全库统一三态）**：元数据单元格遇缺失只允许三种表达——① `missing`：**明确无法获得**该信息（如匿名化移除不可恢复、论文未报告且无法补）；② 空白：**不确定**该信息是否存在/有无（默认态，不确定就不要写）；③ `NA`：**明确没有该信息/不适用**（not applicable，如 unpublished 无 DOI、研究明确无练习段）。`/` **仅限 JSON 字段**的未知约定，Dataset_inf.csv 不用 `/`。判定示例：练习计数因匿名化不可恢复→`missing`；练习有无未披露→空白；任务结构明确无练习→`NA`。改标前先查 exp JSON detail/论文/数据，禁止凭值猜测。
- 同论文多实验行共享的字段（作者/邮箱/年/期刊/DOI 等）只填一次，其余行留空或同步传播均可——以组内非空值一致为准。
- Legacy: `1_Data/Dataset_inf.xlsx` is an OUTDATED earlier layout (different
  schema: no `Folder_Name`; sheets `Label` + `Sheet1`) — do NOT edit; scheduled
  for deletion once collaborators confirm the CSV.

### 读取模板

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
  `r[0]`/`[1]` 取值**（ID 在第 1 列、Folder_Name 在第 2 列，位置易错）。
- CLI 速查：`python 2_Code/read_dataset_inf.py [--folder NAME] [--exp N]`

### 写入纪律：CSV 字节保真编辑（正文）

编辑 Dataset_inf.csv 及其他 CSV 产物时必须字节保真（UTF-8 BOM/CRLF/QUOTE_MINIMAL/末行无换行按
文件原格式保持）。操作纪律：

1. **引号风格为 QUOTE_MINIMAL**（仅含逗号/特殊字符的字段加引号）——勿凭 `head` 拆分输出臆断为
   全字段引号；改前先做往返测试（读入原样写出，diff 应为 0）确认格式可复现。
2. **原文件末行无换行符**，csv.writer 默认每行加行尾——**往返测试与写入都必须先把 writer 自动
   追加的末尾 `\r\n` 截掉（`out = out[:-2]`）再比较/落盘**：直接比较必然 False，那是格式预期差异
   而非内容差异；先截断，截断后仍 False 的部分才是需要查的真差异（教训：Hobbs 入库编辑时
   `roundtrip equal: False`——测试环节就要先截断，不要等 diff 失败再定位）。
3. **读字段一律用 `header.index('列名')` 定位索引再取值**，禁止假设 `r[0]`/`r[1]` 的列顺序
   （教训：加 `subj_Group` 列时 `r[0]` 误当 Folder_Name（实为 ID 列）致 74 行组名全失配填 All——
   值合法、validator 不报错，靠抽查非默认值行数才暴露）。
4. **改后三重验证**：diff 仅目标列变化 + 非目标列 0 差异 + 抽查非默认值行数符合预期（"值合法但
   内容错"validator 检测不到，靠人工核对兜底）。
5. **非主索引 CSV（`*_subj_info.csv` 等）格式各异**：subj_info 可能是 UTF-8 无 BOM + LF 行尾，
   与 Dataset_inf 的 BOM+CRLF 不同（教训：往返测试连败 2 次才发现）——编辑前先 `xxd`/`head -c`
   检测 BOM 与行尾，按原格式写回（含末行无换行），往返测试按检测结果放宽末尾行尾。

## 元数据 JSON

**缺失表达分工**：JSON 字段沿用 `"/"` = 未知/不可得 的 JSON 层约定（配合 `detail` 注明来源）；**Dataset_inf.csv 一律不用 `/`**，缺失按三态：`missing`（明确无法获得）/ 空白（不确定）/ `NA`（明确没有/不适用）。两套表达各自独立、不对齐逐字翻译——写 CSV 用三态，写 JSON 用 `/`。正文见「主索引 Dataset_inf.csv」缺失标记规则。

### Paper-level JSON（`<Study>.json`）— flat 11-field schema

```json
{
  "Paper_name": "…", "Summary": "…", "Year": "2022", "Author": "…",
  "Journal": "…", "Country": "…", "City": "…", "Extra_Var": "/",
  "Email": "…", "DOI": "…", "Conclusion": "…"
}
```

- **JSON 内容一律英文**（用户指示）：paper/exp JSON 的字段值（含 `detail` 注释）不使用中文；中文说明性内容放仓库中文文档或清洗脚本注释。
- `Year` must equal the folder year.
- **`Country`/`City` 语义 = 数据采集地，不是作者单位**：paper JSON 曾误填作者单位（如通讯作者牛津但数据清华采集）；以数据来源为准——被试语言/姓名/采集年/第一作者单位。Dataset_inf.csv 与 paper JSON 需一致；发现不一致时，先核数据采集地再决定是否同步更新。
  **采集地判定依据**：① 论文直写采集地/被试语言/货币/招募机构（最强）；② **伦理委员会批准机构 = 数据采集机构**（惯例：论文声明获批的伦理机构即采集所在地，案例：Constable_2020/Wozniak_2018 均经 Central European University 批准 → 采集地 Budapest）；③ 作者单位 + 全文环境描述（实验室采集）为佐证；④ 作者履历单位**不是**采集地依据。
- **`Email` 以 Dataset_inf.csv 现值为准**：CSV Email 常为通讯作者当前单位邮箱，与论文发表时邮箱可能不同；paper JSON 与 CSV 不一致时不自动"修正"，问用户。
- Preprint variant (e.g., `Hu_2023_psyarxiv.json`, `Navon_2021_psyarxiv.json`):
  `"Journal": "Preprint"` + a PsyArXiv/OSF DOI (e.g., `10.31234/osf.io/9dzm4`).
- Known exception: `Kirk_2025_BritJPsy.json` uses a nested schema
  (`Paper_ID > KIRK_2025_BJP > {…}` with embedded `Experiments`; the inner key
  keeps the old paper ID). Accept, do not restructure.

### Experiment-level JSON（`<Study>_Exp<N>.json`）— v2 hierarchical schema

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
use `"/"` for unknown. All existing experiment JSONs are v2 — new files must be v2 as well.

### 五组件任务框架（Boundary rules for ambiguous keys）

- **Physical_Environment** — where/how the task was delivered (hardware, room, distance).
  `Setting` must use a controlled vocabulary: `Laboratory`, `Online`, or a combined
  value (e.g., `Laboratory + Online`); use `"/"` only when truly unknown. Do NOT
  invent free-text variants (e.g., "quiet room", "chamber", "remote"): the manuscript
  Table 1 pipeline (`Generate_Table1.qmd`) infers `Exp_Implement` by regex-matching
  `Setting`, so non-standard wording silently degrades to NA.
  **Setting = Online 时**：`Physical_Environment.Location` 与 Dataset_inf.csv / paper JSON 的
  `City` 可不填（在线被试可分布于任何地点，位置无意义）——JSON `Location` 填 `/`，Dataset_inf.csv `City` 填 `NA`（不适用，案例 Kirk/Perrykkad）或留空，无需追查。
- **Experimental_Design** — what is manipulated/compared; `Conditions` extracted from
  the "per condition:" breakdown of `Trial_number` when present, else `"/"`.
  Full factorial design lives in `Dataset_inf.csv` (`Design`, `Stim_Type` columns).
- **Block_Structure** — blocks and trial composition within blocks.
- **Trial_Structure** — within-trial timing (fixation, stimulus, SOA, response window, ITI).
  `Shape-label interval` maps to `SOA`; `Stimulus_order` (simultaneous vs sequential) lives here.
- **Stimulus_Properties** — what the stimuli are (modality, sizes, colors).
  `Modality` belongs here, not in Physical_Environment.

## 数据标准化（`*_Clean.csv`）

- Standardized columns: `Subject`, `Shape`, `Label`, `Matching`, `ACC`, `RT_ms`
  (plus optional `Block`, `Trial`, `Phase`, `Response`, `RT_sec`).
- **Shape/Label 列 = 原实验呈现的刺激本身（shape 层统一原则）**：
  - Shape 层与 Label 层是两层刺激，**不一定真是几何图形**（可为面孔文件/声音文件/说话者/情绪类型等）。
  - `Shape` 列存原实验呈现的形状侧刺激（几何形状名如 TRIANGLE、面孔文件如 asian/a_f.jpg、说话者如 S1、
    联结类型如 Positive/Negative）；`Label` 列存原实验呈现的标签文字（you/friend/stranger 等）。
  - **无法确认原刺激时填 `missing`**（如 raw 只记录身份词、几何/文件信息不可恢复）：身份信息一律由
    Identity 三层（Origin/English/Standardized）承载，不在 Shape/Label 列重复身份词。
  - **`Shape_Subtype`**（可选列，紧随 Shape 后）：shape 层刺激的子类型/具体实例——如 Kirk 的 Voice
    （说话者=Shape、具体音频文件=Shape_Subtype）、Wozniak 2018 的 face_gender（面孔文件=Shape、性别=Shape_Subtype）。
  - **`ShapeLoc`**（全库通用可选列）：形状-标签布局，默认 shape 上、label 下；平衡位置的研究（Constable 系列）
    记录实际值 Top/Bottom。
  - 先例：Dalmaso（Face→Shape）、Liu（Face→Shape）、Wozniak 2018（Face_Gender→Shape_Subtype）、
    Kirk（Speaker→Shape、Voice→Shape_Subtype、E2 Shape=Own/M5/M10 从 soundfile 前缀推导）、
    Constable 2021（Shape=Positive/Negative 联结类型）、Constable 2020/2019 E1-3（Shape=几何形状从 raw 绑定恢复）、
    Constable 2019 E4 + Dalmaso E2 Label（missing，原刺激不可得）。
  - **删除分层索引列后须保证键唯一**：清洗删除冗余索引列（如 Bin）后，
    `(Subject, Block, Trial)` 必须仍唯一；不唯一时把被删列维度**合入 Trial 编号**
    （Hu_2020 先例：Trial 1-24 每 bin 循环，删 Bin 后 `Trial = (Bin-1)*24 + Trial` → block 内 1-120 唯一）。
    反向排查方法：全库扫描 Clean 的 `(Subject, Block, Trial)` 重复键（仅 Hu_2020/Hu_2023_psyarxiv/Zhang_2023
    命中；Hu_2023 原为跨 Session 重复——Session 列曾被旧清洗丢弃，重入库已保留 Session 并按其
    分组排序解决，校验键 (Subject, Session, Block, Trial) 唯一）。
    独立脚本模式（Wozniak_2018/Hu_2020 同款）：Rmd 段删除留指针注释、`<Study>_clean.R` 从 Rmd 原代码复制
    仅改问题处、守卫按有效被试断言（无效被试已知重复不参与唯一性断言）。
- **任务与附加自变量命名（全库统一）**：
  - `Task` 列：**全库标准列**，区分"联结对象是否含自参照身份"的任务类型。默认值 `self-matching`
    （形状↔自我/他人联结，数据库核心）；其他受控值：`facialExpression-matching`（联结纯情绪面孔）、
    `monetaryValue-matching`（联结金钱价值）、`self-pseudoWords`（形状↔伪词配对，Wozniak_2022）。
    多任务研究（如 Hobbs 三任务）按行填对应值；单任务研究填默认值。判定标准：
    **联结对象含自参照身份 → self-matching（任务内其他操纵归 extraIV）；不含 → 其他 Task 值**。
  - `extraIV1`/`extraIV2`：self-matching 任务内的**额外操纵自变量**（第 3/4 自变量）统一命名
    （如 Blocktype→extraIV1、Expectancy→extraIV1、Domain→extraIV1 + Valence→extraIV2 等）。
    每研究的 extraIV 具体语义（值、操纵定义、论文文字对应）**必须登记在 Codebook 与 exp JSON detail**
    （同名列在不同研究语义不同，Codebook 分别描述，如 Qian E1 的 Mood vs E2 的 cue 均叫 extraIV1）。
    仅当列可被其他列+extraIV 完全推导（冗余编码）或为派生/评定/常量时才可删除或保留原名；
    删除列须 raw 保留原值。**列顺序（模板 v2，硬性规范）**：`Subject → [Group] →
    [Session] → Task → [Phase] → [Condition] → Block → Trial → [Practice] → Matching → Shape →
    [ShapeLoc] → [Shape_Subtype] → Shape-Identity×3 → Label → Label-Identity×3 → [extraIV1] →
    [extraIV2] → [CorrResponse] → [Response] → RT_ms → RT_sec → ACC → [研究特有保留列尾部]`；
    `CorrResponse` = 按实验设计的正确反应键（仅当 raw 有 CRESP/CorrectAnswer 类列可直接取时补，否则不加）；
    新增/重命名/重排后 Codebook 行序必须与 Clean 列序一致。
    **列顺序合规要求（此前 Sui_2015 合并误将 Phase/Task/extraIV1 前置，故强化）**：
    ① 模板 v2 是**唯一合法列序**，所有新建/重排的 `*_Clean.csv` 必须**逐列对齐模板的相对顺序**
    （模板中带 `[ ]` 的可选列不存在时跳过，但**已存在列的相对先后不得改变**）；产出后把表头与
    模板逐列对照自查——**模板 v2 本身即规范**；合规样例 = `Bukowski_2021_ActaPsych_Exp1_Clean.csv`
    （该文件为本库样张，非规范本身，他库以模板文字为准）。
    ② 关键易错点（曾经踩坑，必须逐条核对）：
      - `Task` 紧跟 `Subject/[Group]/[Session]` 之后，**不得**放到 Shape/Label 后；
      - `Phase`/`Condition` 位于 `Task` 之后、`Block` 之前，**不得**前置到 `Task` 前；
      - `extraIV1`/`extraIV2` 位于 `Label-Identity×3` 之后、`[CorrResponse]`/`[Response]` 之前，
        **不得**提前到列首（即使它是核心操纵变量）；
      - `Shape` 在前、`Label` 在后，各带自己的 Identity×3（Shape-Identity×3 紧跟 Shape、
        Label-Identity×3 紧跟 Label），**不得**把 Shape/Label 两个 Identity 块堆叠在最后。
    ③ 校验手段：Clean 表头与模板 v2 逐列比对（写清洗脚本后 `stopifnot` 断言列名顺序 == 模板
    子序列）；任何列的新增/改名/重排同时更新 Codebook 行序与 exp JSON detail。历史遗留的
    legacy 列序文件需在重清洗时一并纠正，**不得**以"历史文件如此"为新文件放错列开脱。
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
  German `Möbel→furniture→NonPerson`（先例：中性对象类 furniture 归
  **NonPerson**，非 Stranger；同例 Zhang_2024_PsychJ Exp2 的两个中性形状 Standardized 亦归
  NonPerson）；English `self→Self`, `friend→Close`, `stranger→Stranger`.
  Analyses must use the `*_Standardized_Identity` column.
  **非身份刺激特例**：非自我参照的刺激（如奖赏任务的货币金额 `£9`/`£1`，
  Lee_2023_Cognition E2）Standardized 按**原样**保留，不强行归入 6 类词表——它不是身份类别，
  原样记录保留任务语义；Codebook 枚举同步列出。
  **自定义 Std 值先例**：6 类词表外的自定义 Standardized 值已有先例——`£9`/`£1`
  （货币刺激，Lee E2）、`ingroup`（内群体成员/搭档，Constable_2019 E4 的 Coactor：pair 中另一名
  队友；论文行为与 Stranger 无差异但语义为组内成员，用户决策）。使用条件：语义无法归入
  6 类时允许原样/自定义值，须在 Codebook 枚举注明。
  **集体自我（group-self）规则（Constable_2019 系列）**：
  集体自我身份（we/team 类）全库仅 Constable_2019 使用。处理：① Origin 层保留原文
  （We/Team/Person1/Person2 等）；② English 层统一术语 `Individual_Self/Group-Self/
  Individual_Stranger/Group-Stranger`（Shape 与 Label 侧一致；E4 pair 研究 English 用字面
  "Person 1"/"Person 2"）；③ Std 层按论文口径归 Self（如 Constable 论文 "Self: Me and We"
  二分类）；④ **CSV 的 `Self`/`Close`/`Others` 三列 = Std 6 类的简写表达**：Self 列 = Std Self
  类身份集合（含 group-self，如 `Self/We`）、Close 列 = Std Close 类（无 close-other 时留空）、
  Others 列 = 其余身份——CSV 与 Std 必须同一口径，group-self 不得放入 Close 列
  （Close=亲近他人语义）；⑤ pair 研究中 Person 归属不可知时（如 Constable E4），CSV Self 列列
  全部候选（`P1/P2/Team`）并 Note 说明。
- **Shape/Label 列取值约定（用户指示）**：`Shape` 列存实际呈现的几何刺激
  （形状名如 circle/square/triangle，或原始刺激文件名如 Kreis.png），`Label` 列存实际标签
  文字（you/friend/stranger 等），不用数字编码（对下游使用者费解）。数据原始编码保留在 raw
  `<Stim>Code` 列（ShapeCode/LabelCode）与 Identity 三级列的 `*_Origin_Identity` 层；
  Matching 等逻辑用编码计算、写出前映射为可读值（先例 Zhang_2024_PsychJ_clean.R）。
- **刺激-身份绑定恢复（Vicovaro 先例）**：作者导出可能只记录身份而丢弃几何
  形状、且绑定 counterbalanced——从作者实验代码/逐被试配置恢复（Vicovaro OrdineP#.xlsx 的
  identificazione 行）；无法恢复全部时暂停问用户，规律外推须 Codebook/JSON/CSV Note 三处
  标注。几何形状判断以程序代码/用户目视为准（像素分析不可靠，曾猜反 Zhang 的圆/方）。
- **作者内部码的语义表必须逐实验核对（Wozniak_2020 先例）**：同一研究内作者
  内部身份码可能**跨实验语义不同**——Wozniak 的 You/Neutral/AntiYou 三码：Exp1 中
  AntiYou=陌生脸 2 号（Stranger）、Exp2/3 中 AntiYou=**本人真实面孔**（Self）；"You" 码
  在 Exp1/3 为自关联陌生脸（Self）、Exp2 为普通陌生名（Stranger）。解码依据 = 作者
  脚本头注释/论文逐实验核对，**禁止跨实验假设码义一致**；同实验内同一码在 Label 侧与
  Shape 侧语义也可不同——Label 与 Shape 侧分别建语义表。本人真实面孔及其关联标签 → Self
  （Origin 保留名字原样，English 层区分 'Own face'/'Own-face name' 与
  'Self-associated face'/'Self label (You)'）。
- **ACC 统一编码（全库统一值域）**：实际按键相对应按键的比较，共 6 类（覆盖全部可能性）：

  | 码 | 含义 | 对应类别 |
  |---|---|---|
  | `1` | 正确：与应按键一致 | ① 按键一致 |
  | `0` | 错误：在响应窗口内按键但按错（属于规定按键范围） | ② 范围内错键 |
  | `NA` | 无反应：响应窗口内没有按键 | ③ 无按键 |
  | `-2` | 范围外按键：与应按键不一致且不在规定按键范围（如要求 f/j 却按 k） | ④ 范围外键 |
  | `-3` | 提前按键：刺激尚未出现就按键 | ⑤ 提前（少见，多数程序不记录） |
  | `-4` | 超时按键：响应窗口结束后才按键 | ⑥ 反应过迟（少见） |

  规则：① 清洗产物统一用上表编码；② **`-2`/`-3`/`-4` 仅在有明确证据时编码**，无明确
  证据时编码为 `NA` 即可（宁缺毋滥，不臆断）；③ 无反应一律 `NA`（不用数字码）；④ 重编码前
  必须逐研究确认原特殊码语义（Codebook/raw/清洗段/论文，E-Prime 惯例 3=no response 等），
  不得凭值猜测；⑤ 有 `Response` 实际按键列的文件可用「应按键 vs 实际键」验证或重建 ACC；
  无 `Response` 列的文件只能依据原码语义映射或留待 raw 追补；⑥ Codebook 的 `Variable_value`
  同步列出码义。特殊码涉及的文件（重编码前逐研究确认）：Constable 系列 ACC=3、Dalmaso ACC=2、
   Hu_2020 ACC=-1/2、Sui_2015 ACC=3/4、Vicovaro/Xu/Zhang/Sun/Hu_2023 ACC=NA。
- **Matching 列取值全库统一（2026-09-04 定案）**：`Matching` = 呈现的 Shape-Label 对与已学联结一致；`Nonmatching` = 不一致（重组合）。**严格二值**：空白/NA 一律视为非规范值（不允许缺失标记），`validate_clean_csv.R` W5 报错且不列出错值。清洗脚本把作者原始词（match/unmatch、matching/mismatching、Matched/Mismatched、Yes/No 等）映射为规范取值；raw 保留作者原词。Codebook `Variable_value` 同步列出。已知例外：`Zhang_2023_NeuroImage_Exp1` 全 NA 占位行（subject 62，源数据空行、历史保留，已记 CSV Note）→ 报 W5 WARN，待合作者核查数据后再处置，勿静默删除/改写。
- **Minimal preprocessing, NO filtering**: cleaning only renames/reorganizes variables
  and standardizes Identity; it keeps ALL trials, participants and values. Invalid
  values stay in the file (e.g., `ACC = -1` no response, `2` wrong key; `RT_ms`
  outliers). Practice trials, if retained, are flagged (e.g., a `Phase` column)
  rather than dropped. Such codes are documented in the codebook, not removed;
  full preprocessing (filtering, outlier removal, accuracy coding) is the user's
  responsibility.

## Codebook 编写规则

- One `Codebook_<Study>_Exp<N>_Clean.xlsx` per `*_Clean.csv`, in the same folder,
  canonical casing `Codebook_` (lowercase b — 全库唯一命名，legacy `CodeBook_` 已全部改名)。
- **Structure**: a single worksheet `Sheet1` with exactly 4 columns and one row per variable of the Clean.csv:

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
- **现成模板**：`2_Code/make_codebooks.R`——R openxlsx 实现（单 Sheet1 4 列、
  枚举值取数据 unique 含特殊码），改 `jobs` 列表即可复用。空白基线扫描可用
  `2_Code/analyze_csv_blanks.py`。

## DOI 与年份核验（添加/更新论文时必做）

- **DOI 填论文的 DOI，不是数据链接**：`Repo_Link` 存数据存储库链接（OSF/Zenodo/ScienceDB），`DOI` 列与 paper JSON 的 `DOI` 字段一律填正式论文的 DOI。
- **本地优先**：先查 paper JSON 的 `DOI` 字段；其次查 `Repo_Link` 中是否含 `doi.org/10....`；都没有才外查。
- **外查用 Crossref API，不用通用网页搜索**（网页搜索噪声大、难确证）：
  `https://api.crossref.org/works?query.bibliographic=<题名>&query.author=<作者>&filter=container-title:<期刊名>&rows=3`
  核对返回记录的 作者 / 期刊 / 年份 / 卷期 全部吻合才采用；DOI 存裸格式（去掉 `https://doi.org/` 前缀）。
- **年份 = 正式印刷年**：Crossref 记录的 `published-print`（卷期所属年份）；纯在线期刊（PLOS/eLife/MDPI/Collabra 等）无印刷卷期时用 `issued`（在线发表年）；仍为预印本的用**最新版本年份**。
- **预印本版本年查询**：OSF API 按 GUID 直取——`https://api.osf.io/v2/preprints/<guid>/versions/`（`filter[doi]` 查询返回 HTTP 400，勿用）；GUID 即 PsyArXiv DOI 的后段（如 `10.31234/osf.io/9dzm4` → `9dzm4`）。

## 原始数据解析与验证先例（速查表；详细版见 parsing-examples.md）

遇到输入区数据时先查此表定位条目，再读 parsing-examples.md 对应节：

| 输入格式/特征 | 关键陷阱（一句话） | 详细条目 |
|---|---|---|
| E-Prime `.txt` 日志 | UTF-16LE 读取；LogFrame 切块；中断被试可有未闭合块 | parsing-examples.md §E-Prime |
| E-Prime 合并导出 `.xlsx` | 语义重复列（Label/Label2）；Group 字段可能非设计/临床分组；日期三类混杂 | §E-Prime |
| `.edat2`/`.emrg*` | 二进制私有格式（E-Merge 导出库内见 `.emrg`/`.emrg2`/`.emrg3`），无可解析工具——用户 E-DataAid 转 txt | §E-Prime |
| PsychoPy 导出 | 无响应 `keys` = 字符串 "None"；Builder 宽格式 csv；RT 单位（秒或已×1000） | §PsychoPy |
| MATLAB/Psychtoolbox `.dat` | 空格分隔；列定义权威 = 实验脚本 fprintf 格式串；练习试次可能不落盘 | §MATLAB |
| 作者聚合 `.xlsx` | 外链公式读缓存值；"ER" 列实为正确率；编号体系不对称；文件名 vs 行内编号 | §作者共享产物特征 |
| 作者共享文件特征 | 文件级预清洗（试次数低）；按 ACC/条件排序（Block 重建）；round 边界 | §作者共享产物特征 |
| 作者脚本逐值验证 | 先对齐编号体系再全量对比；脚本实现口径 vs 论文文字可能不一致 | §作者脚本逐值验证法 |

## 工具与脚本（细节见 tools.md）

- **主路径（agent 自动化入库标准方式）**：独立清洗脚本 `<Study>_clean.R`（与 `1_Data/utils.R`
  同库，`source()` 引用）→ 产出标准五件套。`2_Code/Clean_Data.Rmd` 已降级为**历史配方参考**
  （含旧文件夹名注释，不改）；`SPE_Interactive_Clean_V3.R` / `SPE_Shiny_App_V4.2.R`
  为人工备用（控制台/网页交互）。
- **独立清洗脚本规范**：
  - 内嵌脚本依赖的辅助函数（如 read.mat），不依赖 Rmd 上下文；开头注释写明来源与修改点。
  - 路径用脚本所在目录的相对路径；脚本内做工作目录自适应（Rscript 的 --file= 参数）。
  - 输出 *_Clean.csv 带一致性守卫（如 stopifnot 行数/被试数）；行尾 CRLF/LF 差异直接无视。
  - 排除已确认的问题被试（如测试运行）时，在脚本注释中写明证据与依据；修改数据文件后同步
    更新同目录 subj_info、Dataset_inf.csv（字节保真）与 codebook。
- **Subject 编号与数据对齐规则（Vicovaro_2022_JEPHPP Exp2 教训）**：
  1. **编号只承载唯一性，条件信息由数据列承载**：Subject 编号不编码 block/条件。raw participant_id
     重复（多段/跨 block 共用同一 ID）时，统一按段号加后缀 `_1`/`_2`…，不引入条件后缀分支。
  2. **重复 ID 判定看"该 ID 总段数 > 1"，而非当前段号**：凡 participant_id 名下段数 > 1 →
     **所有段**都加段号后缀（不能只给后段加）；守卫 `stopifnot(length(unique(Subject)) == 预期被试数)`。
  3. **subj_info 与 Clean 的 Subject 对齐用键，不用行序**：构建期保留临时映射列，人口学按映射键
     对齐；**禁止依赖文件行序**。写出 Clean 前删除临时列。
  4. **构建期中间映射内嵌脚本，不落盘独立文件**：研究文件夹只允许标准产物 + `<Study>_clean.R`，
     不产生 subject_map 等中间 CSV。
- **辅助工具**（`repo_fetch.py` OSF/PsychArchives 下载、`scan_raw.py` raw 扫描；端点与用法见 tools.md）。

## 校验与卫生

1. After any metadata change run:
   `Rscript 2_Code/validate_json_metadata.R` (checks naming, year drift, exp-key match,
   v2 component completeness; exits non-zero on violations).
2. After any clean-data change run the **content-level checker**:
   `Rscript 2_Code/validate_clean_csv.R` — for every `*_Clean.csv` outside the raw
   input zone: E1 missing `Subject` column; E2 incomplete Identity triple
   (`X_Origin_Identity` without `X_English_Identity`/`X_Standardized_Identity`);
   E3 Subject count vs `*_subj_info.csv` rows; W1 missing standard columns (with
   alternative-column hints); W2 Subject count vs CSV `Valid_Subj`/`Sample_Size`
   (known caliber differences); W3 ACC value domain; W4 non-standard filenames.
   ERROR → exit 1; historical exceptions are listed in the script `known` vector
   (KNOWN, exempted; remove the entry once fixed — same pattern as `known_pending`).
3. The validator whitelists not-yet-curated studies (`known_pending`) that are
   allowed to lack a folder; once such a study is curated, remove it from the
   whitelist. **反向豁免 `known_unlisted`**：有文件夹但 CSV 无行的研究（方向与
   `known_pending` 相反）——用于**条目从 CSV 移除**的情形（数据不可得/撤回 → 删 CSV
   行、输入区文件夹保留并加入 `known_unlisted` 豁免；重入时移除并注释更新；库内 deferred
   条目见 PROJ_STATE.md）。处理原则：删除 CSV 行前先确认（用户决策），输入区文件不删除。
4. **Validator blind spots**（校验器只校验存在的文件，以下缺失不会被发现，需人工核对）：
   缺 paper 级 JSON、缺 codebook、CSV 中重复的 `(Folder_Name, Exp)` 组合。
5. One-time schema migrations live in `2_Code/migrate_exp_json_to_v2.py`
   (v1 flat `table` → v2 hierarchical); re-run only if legacy files reappear.

### 文件操作安全纪律（正文，通用——写/删/下载前必读）

任何会写、删、下载文件的 curation 操作遵守以下纪律（AGENTS.md §防坑保留各条教训案例，
纪律正文以此处为准）：

1. **覆盖保护**：任何会写文件的命令（`curl -o`、shell 重定向 `>`、write 工具）执行前先 `ls -la`
   检查目标路径是否已存在；目标已存在且非本会话自己刚创建的产物 → 先向用户确认，或改存别的名字。
2. **下载两段式**：下载类命令一律先落到临时路径（`/tmp/xxx.tmp`），`stat -f %z` 确认非空后再
   `mv` 到目标；禁止直接 `-o`/`>` 覆盖现有文件（教训：curl 失败时 `-o` 把已有文件清成 0 字节，
   且 gitignore 目录无备份则内容永久丢失）。
3. **写后核对**：覆盖/写入后立即 `ls -la` 核对大小与时间戳，与预期不符马上报告，不自我安慰
   "恰好一致"。
4. **删除谨慎**：删除前先 `git check-ignore <路径>` / `git ls-files` 确认是否被跟踪——不被跟踪的
   文件 `rm` 即永久丢失；批量删除前先列出「将被删除清单」并向用户确认保留策略；非明确垃圾的删除
   先 `mv` 到 `_trash_<日期>/` 暂存，用户确认后再物理删除；删除后立即汇报删了什么（文件数+类别）。
5. **工具路径核查**：工具若含绝对路径，先确认它读的就是当前文件——校验器/扫描脚本可能硬编码已
   迁移的旧路径，运行时读到旧副本且输出"恰好与预期一致"会掩盖错误。改数据前 `grep` 工具源码确认
   数据源路径；改后重跑若输出异常，先怀疑工具路径而非数据本身。
6. **编辑锚点**：编辑文档追加条目时用将被保留的现有文本作锚点，oldString 不要误取整条历史记录；
   改后立即 grep 确认旧内容仍在。
