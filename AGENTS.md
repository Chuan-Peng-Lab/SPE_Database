---
mode: primary
---

# AGENTS.md — SPE Database

## 🔒 全局最高级规则（GLOBAL RULE — 优先级高于本文件一切其他规则）

**Agent 永远不要自动执行 `git commit`**，也不要把「提交」当作会话收尾的默认步骤。
只有用户在对话中**明确确认/指示提交**后，才允许执行 commit（例如用户直接说"提交"/"commit"/"可以提交"等）。
以下情况**均不构成**确认：会话惯例、收尾清单、任务"完成"的推断、用户只说"修复/更新/插入/列出"等不含提交指令的话。
**不要每次回复都询问是否提交**：提交事宜只在用户主动询问/指示时处理。任务完成正常汇报结果即可；若有未提交改动，简单提示一句"改动未提交"即可，不重复追问。用户询问提交时，agent 列出待提交文件与 commit message 草案，获得明确确认后再提交。

## ⚠️ CRITICAL: This project lives on a USB drive (exFAT)

The entire repo is stored on an **exFAT-formatted USB drive** mounted at `/Volumes/T3`.

### Why it matters (one line)

exFAT has no macOS xattrs, so macOS writes hidden `._*` AppleDouble sidecars that
leak into `.git/objects/pack/` and break git ("non-monotonic index" errors).

### Mandatory cleanup rule

**At the START of every session** (first tool call), and **before/after any
`git add`/`commit`/`status`/`log` that errors**, run:

```bash
rm -f .git/objects/pack/._pack-*
find . -name '._*' -not -path './.git/objects/pack/._pack-*' -delete 2>/dev/null
find .git -name '._*' -delete 2>/dev/null
```

If corruption persists: `git gc --prune=now` — never delete real
`.git/objects/pack/pack-*` files.

### Guidelines for agents

- **Never** `git add` or commit `._*` files or other macOS cruft (`.DS_Store`,
  `.Rhistory`, `.Rproj.user`, `Thumbs.db`). `.gitignore` already covers most of them.
- **Never** open/read `._*` files as if they were real data files — they are AppleDouble
  metadata, not content. When globbing/listing, filter them out (the repo already uses
  `._*` ignore patterns).
- **Safely eject / unmount** the drive is the user's responsibility — never attempt to
  unmount, remount, or format the drive yourself.
- Expect slow disk I/O on this drive (USB/exFAT). Batch reads/writes when possible.
- **Never** start an exploration task or fire background exploration without explicit user
  approval.
- **Never** fire background exploration tasks that may take more than a few hours.
- **Always** run `git gc --prune=now` before starting a new exploration task.

## Document map（四文档分工与引用关系）

- `README.md` — 面向**人类读者**：项目介绍、数据使用指引。代理也应按需引用。
- `AGENTS.md`（本文件）— 面向**agent**：环境约束（exFAT）、效率约定、caveats。
- `PROJ_STATE.md` — **会话状态快照**：每次工作后必须更新；新会话先读它再开工。
- `.opencode/skills/spe-database-curation/SKILL.md` — **通用 curation 技能**：自足独立、
  不依赖本仓库文档；任何数据整理/入库任务一律加载
  `skill(name="spe-database-curation")`。
- 引用方向：README ↔ AGENTS ↔ PROJ_STATE 三份相互引用，并**统一指向技能**；
  技能不反向依赖这三份文档。

## Agent efficiency conventions（省 token / 防无效搜索）

### 省 token
- 大文件（>10 MB，见 caveats 清单）**绝不整读入上下文**：用 `head` 看表头、Python 流式/按列提取、只取所需结果。
- 优先 `grep`/`glob` 定位，不整文件读取；USB 盘 I/O 慢，读写尽量批量。
- **不要重复"发现"已知问题**：caveats 与 PROJ_STATE.md 里已记录的，直接当作事实引用。
- `Generate_Table1.qmd` 渲染耗时数分钟：仅当输入（文件夹/Dataset_inf.csv/qmd 本身）变化时才重渲染；日常校验用秒级 `Rscript 2_Code/validate_json_metadata.R`。
- 编辑 `Dataset_inf.csv` 保持字节保真：UTF-8 BOM、CRLF 行尾、文件末尾无换行；改前先做往返测试，改后核对 diff 只含目标单元格。
- 一次会话内对同一文件的多处修改合并为一次写入/一次提交。
- 长任务（qmd 渲染、批量改名、大批量网络查询）放后台 job 执行，期间并行推进独立的只读步骤。

### 防无效搜索
- 查论文 DOI：**Crossref API**（`api.crossref.org/works?query.bibliographic=...&query.author=...&filter=container-title:...`）按作者+期刊+年份核对——通用网页搜索噪声大且难确证，勿用。
- 查预印本版本年：OSF API 按 GUID 直取 `api.osf.io/v2/preprints/<guid>/versions/`；`filter[doi]` 返回 HTTP 400，勿用。
- 外查前先查本地权威源：paper JSON（`DOI`/`Year`/`Journal`）、`Repo_Link`、`Dataset_inf.csv`。

### 会话收尾（强制）
- 更新根目录 `PROJ_STATE.md`：目标、已完成（已验证）、关键决策、测试结果、已知问题、失败方案、下一步；只记已确认事实。
- 若本会话沉淀了可复用的约定/流程，同步补充到 `spe-database-curation` 技能（SKILL.md）。
- 如需提交：**必须先获得用户明确确认**（见文首「全局最高级规则」），确认后按「清理规则」删 AppleDouble 文件，再按逻辑分组 commit（≤3 个）。

## Project context

- **What**: SPE (Self-Prioritization Effect) Database — curated trial-level data from
  **43 studies / 73 experiment-level rows** per `Dataset_inf.csv` (34 curated
  folders on disk + 9 pending entries) using the self-matching task
  (Sui, He & Humphreys 2012). Earlier published counts (44 papers / 70 datasets /
  3603 participants) refer to the manuscript and have NOT been re-verified against
  the CSV. Companion to a preregistered meta-analysis (OSF: euqmf).
- **Structure**:
  - `1_Data/` — 34 study folders (`<Author>_<Year>_<Journal>/`), plus `Dataset_inf.csv`
    master index (legacy `Dataset_inf.xlsx` outdated — pending deletion after
    collaborators confirm the CSV). Each folder contains:
    - raw data: `*_raw.csv` (trial-level), `*_raw_Subject.csv` (subject-level),
      sometimes `*_Raw/` subfolders with per-participant exports (E-Prime `.edat2`,
      MATLAB `.mat`, PsychoPy `.psydat`).
    - cleaned data: `*_ExpN_Clean.csv`.
    - metadata: `Codebook_*_Clean.xlsx` (variable codebooks; 50 files total:
      22 canonical `Codebook_` + 28 legacy `CodeBook_`),
      study-level `.json` (paper metadata) and experiment-level `.json`
      (methodology, v2 hierarchical schema: five components under `exp<N>`).
  - `1_Data/Dataset_inf.csv` — **master index** (newest version; `Dataset_inf.xlsx`
    is outdated, no `Folder_Name` column, and is scheduled for deletion once
    collaborators confirm the CSV), **UTF-8 with BOM** (do NOT strip the BOM —
    Chinese collaborators open it in Excel on Chinese Windows which defaults to GBK;
    the BOM is what keeps diacritics like `ö`/`é`/`ü` from garbling).
    39-column structure (incl. `DOI`), key columns:
    `Folder_Name` (== study folder; **project-wide key ID for papers/preprints** —
    one row per experiment: `Folder_Name` + `Exp`), `Paper_ID` (**deprecated** —
    legacy link to the old manuscript Table 1; do NOT create new values), `Country`,
    `Stim_language`, `Stim_Type`, `License`, `numTrials`, `Sample_Size`/`Male`/`Female`.
    NOTE: `Environmental_Info` stores the **stimulus-presentation software**
    (E-prime/Gorilla/PsychoPy/Matlab), NOT Lab-vs-Online setting — do not conflate the
    two. The manuscript Table 1 column `Exp_Implement` (Lab/Online/Mixed) does NOT exist
    in the CSV; derive it from experiment JSON `Physical_Environment.Setting`.
  - `.opencode/skills/spe-database-curation/` — curation-conventions skill (folder
    structure, file naming grammar, JSON schemas, five-component task framework,
    Identity standardization, codebook authoring, DOI/year verification workflow).
    Load via `skill(name="spe-database-curation")` when adding/editing study metadata.
  - `2_Code/` — data cleaning tooling, three parallel implementations of the same
    standardization logic:
    - `Clean_Data.Rmd` (5053 lines) — master per-paper manual pipeline (authoritative).
    - `SPE_Interactive_Clean_V3.R` — console-based interactive cleaner (single/batch).
    - `SPE_Shiny_App_V4.2.R` — Shiny web app (single/batch, ZIP download).
  - `3_Reports/` — analysis: `Reports.Rmd`, `Process_Data.Rmd`, `Subject_Table.Rmd`,
    `R_rainclouds.R`, plus `1_Identity_Analysis/`, `2_Mismatch_Analysis/`,
    `3_Exploratory_Analysis/` (each a self-contained Rmd), `4_Post/`, and `Output/`
    (aggregated CSVs in `Output/data/`, figures in `Output/Pic/`).
    - `Generate_Table1.qmd` — regenerates the manuscript Table 1 (flow:
      `1_Data/* folders → Dataset_inf.csv → Table 1`; Table 1 `ID` column =
      `Folder_Name`; comparison treats manuscript "Not specified"=missing and
      `CC0`=`CC0 1.0 Universal` as equal). Outputs `Generate_Table1.docx` +
      `Output/table1_problems.txt` (known issue classes listed there); render with
      RStudio's bundled quarto. Operational details: PROJ_STATE.md.
    - `Consistency_Check_Table1_vs_DatasetInf_vs_Folders.md` — Chinese report of the
      3-way consistency check (manuscript Table 1 vs CSV vs folders).
- **Stack**: R / R Markdown / Shiny. RStudio project (`SPE_Database.Rproj`).
- **Key conventions**: cleaned variables standardized to `Subject`, `Shape`, `Label`,
  `Matching`, `ACC`, `RT_ms`, and 3-level Identity columns
  (Origin → English → Standardized: NonPerson/Self/Close/Acquaintance/Celebrity/Stranger).
  Cleaned file naming: `<Author>_<Year>_<Suffix>_ExpN_Clean.csv` (Suffix = readable
  journal/database abbreviation, full short journal name, or psyarxiv/unpub tag;
  see the curation skill).
- **Raw data formats**: CSV dominant (331 files); also E-Prime `.edat2`/`.emrg`,
  MATLAB `.mat`/`.m`, PsychoPy `.psydat`/`.dat`. No parquet anywhere.
- **Version**: v0.1.5 (2026-06-28). See `README.md` for full changelog.
- **Current state**: see `PROJ_STATE.md` (root) for the latest verified status,
  known issues, failed approaches and next steps; update it at the end of every session.

## Known data-quality caveats (verified 2026-08)

Treat these as known issues, not new discoveries — do not "find" them again:

- **4 studies lack codebooks AND paper-level JSONs** (no `Codebook_*_Clean.xlsx`,
  no `<Study>.json`): `Lee_2023_Cognition`, `Orellana-Corrales_2021_APP`,
  `Smith_2024_Cortex`, `Svensson_2023_QJEP` (`*_raw_Subject.csv` 已于 2026-08 补齐：
  Lee/Smith/Svensson 由各自 `*_raw.csv` 生成；Orellana-Corrales_2021_APP 仍无任何原始数据，
  仅 2 个 `*_Clean.csv`；Svensson_2023_QJEP 仍无任何 JSON)。
- **Missing raw data**: `Sun_2026_DataExp/` has `Sun_2026_DataExp_Exp1_Clean.csv`
  (largest cleaned file, 62 MB) but no `*_raw.csv` and no experiment-level JSON
  (`Sun_2026_DataExp_Exp1.json` missing).
- **Pending study — no data folder yet (do NOT "fix")**: `Dataset_inf.csv` lists
  `Wozniak_2020_PLOS` (DOI `10.1371/journal.pone.0235627`, OSF `osf.io/2q9w7`) but no
  `1_Data/Wozniak_2020_PLOS/` folder exists — expected, data not yet curated.
  Paper = Woźniak & Hohwy, PLOS ONE, 2020.
- **9 more CSV `Folder_Name` entries have no folder (verified 2026-08)**: `Bukowski_2021_ActaPsych`,
  `Golubickis_2021_ActaPsych`, `Hobbs_2023_PsychMed`, `Hu_2023_SDB`, `Mcivor_2021_EJN`,
  `Orellana-Corrales_2023_QJEP`, `Scheller_2026_elife`, `Svensson_2022_PsychRes`,
  `Wozniak_2020_PLOS` — listed in Dataset_inf.csv but no `1_Data/` folder; expected
  pending/uncatalogued, do NOT "fix". The validator (`validate_json_metadata.R`)
  whitelists all of them (`known_pending` list); `Generate_Table1.qmd` excludes all 9
  from the generated Table 1.
- **Manuscript Table 1 vs data has known discrepancies (verified 2026-08)**: Exp-number
  copy-paste errors (e.g. `P5E1`–`P5E4` all labeled "Exp4" in the manuscript),
  N-count differences (manuscript "—" vs CSV concrete values), Trials wording
  differences (`numTrials` vs per-block counts), and some Study-label attributions
  (`P46E2`, `Pu2E1`, `Pt9E1`). These are tracked as open issues in
  `Consistency_Check_Table1_vs_DatasetInf_vs_Folders.md` and surfaced by
  `Generate_Table1.qmd` — do not re-report them as new findings.
- **Preprocessing is NOT complete**: cleaning is minimal preprocessing (variable
  selection & standardization only, NO trial/value filtering) — `ACC` may include
  invalid values (e.g., `-1` no response, `2` incorrect key), kept on purpose and
  documented in codebooks. Users must preprocess per their own analysis goals.
- **Missing code references**: `2_Code/README_Auto_Clean.md` references
  `SPE_Auto_Clean.R` and `Test_Auto_Clean.R`, which do not exist in the repo.
- **Large files (>10 MB)**: `Sun_2026_DataExp_Exp1_Clean.csv` (62 MB),
  `Processed_Data_Filtered.csv` (60 MB), `Haciahmet_2023_Psychophysiol_Exp1_raw.csv`
  (42 MB), `Share_Data.RData` (31 MB). Avoid loading these into memory / context casually.

## Repo state (verified 2026-08)

- Single branch `main` (tracks `origin/main`).
- Root-level `._*` files and `Contact*.xlsx` are gitignored; study folders
  `Smith_2024_Cortex/`, `Lee_2023_Cognition/`, etc. are also gitignored at repo root
  (only their `1_Data/...` paths are tracked).

## TODO / planned work

- (Done 2026-08) Codebook authoring rules added to `spe-database-curation` SKILL.md:
  §Codebook authoring rules specifies the single-`Sheet1` 4-column template
  (`Variable_name | Variable_description | Variable_value | Variable_category`),
  per-column content rules (definitions, valid values, units, missing/invalid codes)
  and the creation workflow from the Clean.csv header + paper methods + data values.
