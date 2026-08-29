---
mode: primary
---

# AGENTS.md — SPE Database

## 🔒 全局最高级规则（GLOBAL RULE — 优先级高于本文件一切其他规则）

**Agent 永远不要自动执行 `git commit`**，也不要把「提交」当作会话收尾的默认步骤。
只有用户在对话中**明确确认/指示提交**后，才允许执行 commit（例如用户直接说"提交"/"commit"/"可以提交"等）。
以下情况**均不构成**确认：会话惯例、收尾清单、任务"完成"的推断、用户只说"修复/更新/插入/列出"等不含提交指令的话。
**不要每次回复都询问是否提交**：提交事宜只在用户主动询问/指示时处理。任务完成正常汇报结果即可；若有未提交改动，简单提示一句"改动未提交"即可，不重复追问。用户询问提交时，agent 列出待提交文件与 commit message 草案，获得明确确认后再提交。

## 会话约定（通用）

- **Never** start an exploration task or fire background exploration without explicit user
  approval.
- **Never** fire background exploration tasks that may take more than a few hours.
- **Never** `git add`/commit macOS cruft（`.DS_Store`、`.Rhistory`、`.Rproj.user`、
  `Thumbs.db`；`.gitignore` 已覆盖多数），也不要把 `._*` AppleDouble sidecar 当真实数据读取。

## Document map（四文档分工与引用关系）

- `README.md` — 面向**人类读者**：项目介绍、数据使用指引。代理也应按需引用。
- `AGENTS.md`（本文件）— 面向**agent**：环境约束、效率约定、caveats。
- `PROJ_STATE.md` — **会话状态快照**：**每个 session 结束时统一更新一次**（工作过程中不逐条实时记录，避免文档冗长）；新会话先读它再开工。
- `3_Reports/Table1_Issues_Solvability.md` — **Table 1 问题可解性分析**：逐项判定稿件 Table 1 差异的可解性（可自动确定 / 需人工），与 PROJ_STATE.md 双向关联（未解决清单 ↔ 可解性判定）；依据 `Generate_Table1.qmd` 输出的 `table1_problems.txt`。
- `REF/README_html2md.md` — **REF 全文 HTML → MD 转换管线使用说明**：`REF/html2Json.py`（HTML→JSON）+ `REF/json2md.py`（JSON→MD）的批量用法、摘要验收清单、新模板适配；全文正文归属本文件，AGENTS/PROJ_STATE 只放指针。
- `.opencode/skills/spe-database-curation/SKILL.md` — **通用 curation 技能**：自足独立、
  不依赖本仓库文档；任何数据整理/入库任务一律加载
  `skill(name="spe-database-curation")`。
- 引用方向：README ↔ AGENTS ↔ PROJ_STATE 三份相互引用，并**统一指向技能**；
  Table1_Issues_Solvability.md ↔ PROJ_STATE.md 双向关联；技能不反向依赖这三份文档。

## 项目总体逻辑（单向数据管道）

本项目是一条**单向数据管道**：`原始公开数据 → 规范数据 → 稿件产出`。
数据只向前流动；稿件永不反向作为数据源（稿件 v16 已废弃，其 12 个
待收录条目信息已登记入 Dataset_inf.csv Note 列，见 PROJ_STATE.md）。

**阶段一：整理与入库（agent + skill 自动化，2026-08 起）**
- 输入：各研究公开数据（论文/preprint/unpublished）下载至**输入区**
  `1_Data/<Study>/<Study>_Raw/`（只读，不参与校验；详见 SKILL.md Raw input zone）
- 执行：agent 加载 `spe-database-curation` 技能 → 扫描输入区识别
  实验/被试/会话 → 生成独立清洗脚本 `<Study>_clean.R`（列映射 +
  Identity 三级标准化；配方参考 Clean_Data.Rmd，其降级为历史参考）→
  产出 `*_raw.csv` / `*_ExpN_Clean.csv` / `*_subj_info.csv` /
  Codebook / paper+实验 JSON → 更新 Dataset_inf.csv（字节保真）
- 校验（两级，任何改动后必跑）：`Rscript 2_Code/validate_json_metadata.R`
  （结构级）+ `Rscript 2_Code/validate_clean_csv.R`（内容级，2026-08 新增）

**阶段二：信息提取与分析产出**
- 工具：`3_Reports/` 各 Rmd（Process_Data、Subject_Table、Reports、
  Generate_Table1、1_Identity、2_Mismatch、3_Exploratory）
- 产物：`Output/data/` 聚合 CSV、`Output/Pic/` 图、`Generate_Table1.docx`
- 与稿件比对默认关闭（`--param compare_manu:true` 按版本触发）；禁止以稿件/旧产物反推数据

**任务判别**：整理/入库 → 加载 skill，产出写 `1_Data/`；分析/出数 →
直接用 `3_Reports/` 代码与规范数据，产出写 `3_Reports/Output/`。
历史遗留（manu_v16、Dataset_inf.xlsx、非标准命名变体等）不主动修改。

## Agent efficiency conventions（省 token / 防无效搜索）

### 省 token
- 大文件（>10 MB，见 caveats 清单）**绝不整读入上下文**：用 `head` 看表头、Python 流式/按列提取、只取所需结果。
- 优先 `grep`/`glob` 定位，不整文件读取；读写尽量批量。
- **不要重复"发现"已知问题**：caveats 与 PROJ_STATE.md 里已记录的，直接当作事实引用。
- `Generate_Table1.qmd` 渲染耗时数分钟：仅当输入（文件夹/Dataset_inf.csv/qmd 本身）变化时才重渲染；日常校验用秒级 `Rscript 2_Code/validate_json_metadata.R`。
- 编辑 `Dataset_inf.csv` 保持字节保真：UTF-8 BOM、CRLF 行尾、文件末尾无换行；改前先做往返测试，改后核对 diff 只含目标单元格。
- 一次会话内对同一文件的多处修改合并为一次写入/一次提交。
- 长任务（qmd 渲染、批量改名、大批量网络查询）放后台 job 执行，期间并行推进独立的只读步骤。
- **CRLF/LF 差异直接无视**（用户明确指示）：不检查、不转换、不保持行尾一致；git 的 text=auto 会归一化行尾比较，diff 天然只显示内容改动；处理 CRLF 文件时注意 grep/awk 等工具的行为差异即可，无需为行尾重写或恢复文件。
- 数值等价（浮点容差内）即视为一致：脚本输出与旧文件的末位显示差异（R %.15g vs Python repr 等）不追根源、不改数据、不重写旧文件。
- 验证命令输出要截断（head/wc -l/diff | wc -l），禁止裸跑大 diff 或长 R 输出进上下文。
- 对 PROJ_STATE.md / 前序 agent 已核实的事实做一次轻量抽查即可，不要完整重验；已记录的结论直接引用。

### 防无效搜索
- 查论文 DOI：**Crossref API**（`api.crossref.org/works?query.bibliographic=...&query.author=...&filter=container-title:...`）按作者+期刊+年份核对——通用网页搜索噪声大且难确证，勿用。
- 查预印本版本年：OSF API 按 GUID 直取 `api.osf.io/v2/preprints/<guid>/versions/`；`filter[doi]` 返回 HTTP 400，勿用。
- 外查前先查本地权威源：paper JSON（`DOI`/`Year`/`Journal`）、`Repo_Link`、`Dataset_inf.csv`。

### 防坑（2026-08 阶段 2 会话沉淀，agent 操作纪律）
- **覆盖/替换已有文件也必须经过用户确认**（2026-08-28 教训：`curl -o` 静默覆盖了用户刚下载的 Scheller html——curl 失败（HTTP 406）时 `-o` 把 1 MB 完整文件清成 0 字节，gitignore 目录无备份、内容永久丢失）。操作纪律：① 任何会写文件的命令（`curl -o`、shell 重定向 `>`、write 工具）执行前先 `ls -la` 检查目标路径是否已存在；目标已存在且非本会话自己刚创建的产物 → 先向用户确认，或改存别的名字；② 下载类命令一律先下到 `/tmp/xxx.tmp`，`stat -f %z` 确认非空后再 `mv` 到目标，禁止直接 `-o`/`>` 覆盖现有文件；③ 覆盖/写入后立即 `ls -la` 核对大小与时间戳，与预期不符马上报告，不自我安慰"恰好一致"。
- **删除文件必须万分谨慎，尤其是不在 git 中记录的文件**（2026-08-28 教训：`REF/` 全目录被 `.gitignore` 忽略，一次清理 `_files` 删 390 文件 + 误删 Scheller html/json/md 均不可恢复，用户重新下载才找回）。操作纪律：① 删除前先 `git check-ignore <路径>` / `git ls-files` 确认是否被跟踪——不被跟踪的文件 `rm` 即永久丢失；② 批量删除前先列出「将被删除清单」并向用户确认保留策略（如"只删 js/css，图片全保留"），不要自作主张按引用白名单删；③ 非明确垃圾（0 字节残留、浏览器缓存）以外的删除，先 `mv` 到 `REF/_trash_<日期>/` 暂存，用户确认后再物理删除；④ 删除后立即汇报删了什么（文件数+类别），便于用户及时发现误删；⑤ 对用户的删除指令理解不确定时（如"删整个文件夹"），先复述删除范围再执行，不要扩大范围。
- **工具若含绝对路径，先确认它读的就是当前文件**：校验器/扫描脚本可能硬编码已迁移的旧路径（如 `analyze_csv_blanks.py` 曾指向 `/Volumes/T3/...`），运行时读到旧副本且输出"恰好与预期一致"会掩盖错误。改数据前 `grep` 工具源码确认数据源路径；改后重跑若输出异常，先怀疑工具路径而非数据本身。
- **编辑文档追加条目时用将被保留的现有文本作锚点**：edit 的 oldString 不要误取整条历史记录（曾把 PROJ_STATE「项目迁移」条目整体替换掉）；改后立即 grep 确认旧内容仍在。
- **CSV 字节保真编辑（Dataset_inf.csv）读取/写入纪律**（2026-08-28 教训：加 `subj_Group` 列时 `r[0]` 误当 Folder_Name（实为 ID 列）致 74 行组名全失配填 All——值合法、validator 不报错，靠抽查非默认值行数才暴露）。操作纪律：① 引号风格为 **QUOTE_MINIMAL**（仅含逗号/特殊字符的字段加引号），勿凭 `head` 拆分输出臆断为全字段引号；改前先做往返测试（读入原样写出，diff 应为 0）确认格式可复现；② 原文件**末行无换行符**，csv.writer 默认每行加行尾——写入后 truncate 掉末尾 `\r\n` 才字节保真；③ 读字段一律用 `header.index('列名')` 定位索引再取值，**禁止假设 `r[0]`/`r[1]` 的列顺序**；④ 改后三重验证：diff 仅目标列变化 + 非目标列 0 差异 + 抽查非默认值行数符合预期（"值合法但内容错"validator 检测不到，靠人工核对兜底）。
- 字段语义类约定（License=数据许可 / Country-City=数据采集地 / Email 以 CSV 为准 / 多任务口径 / 全文核查）见 `spe-database-curation` 技能（SKILL.md），此处不重复。

### 会话收尾（强制）
- 更新根目录 `PROJ_STATE.md`：目标、已完成（已验证）、关键决策、测试结果、已知问题、失败方案、下一步；只记已确认事实。
- **更新时机：只在 session 收尾统一更新一次**，工作过程中不逐条实时写入 PROJ_STATE.md（避免文档膨胀）；同一 session 内的多次修改合并为收尾时一条「已完成」条目。若 session 尚未结束，改动先记在对话/待办中，不写文档。
- 若本会话沉淀了可复用的约定/流程，同步补充到 `spe-database-curation` 技能（SKILL.md）。
- **沉淀去重（2026-08 阶段 2 教训）**：四文档按分工各存专属正文、相互指针引用，**不复制同样内容到多个文件**——每条规则正文只写一个归属文件（AGENTS.md=agent 操作纪律 / SKILL.md=curation 字段语义 / PROJ_STATE.md=会话事实快照），其余文件只放一行指针（含目标节/编号）。操作要求：① 写入前 `grep` 目标文件确认该规则尚无正文，避免文件内重复；② 删除/重编号后立即同步更新所有指针中的引用位置；③ 沉淀后 `grep` 复核每条规则只有一处正文、其余为指针。
- 如需提交：**必须先获得用户明确确认**（见文首「全局最高级规则」），确认后按逻辑分组 commit（≤3 个）。

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
    - raw data: `*_raw.csv` (trial-level), `*_subj_info.csv` (subject-level),
      sometimes `*_Raw/` subfolders with per-participant exports (E-Prime `.edat2`,
      MATLAB `.mat`, PsychoPy `.psydat`).
    - cleaned data: `*_ExpN_Clean.csv`.
    - metadata: `Codebook_*_Clean.xlsx` (variable codebooks; 56 files total:
      28 canonical `Codebook_` + 28 legacy `CodeBook_`; 2026-08-27 阶段 1 新增 6 个 canonical),
      study-level `.json` (paper metadata) and experiment-level `.json`
      (methodology, v2 hierarchical schema: five components under `exp<N>`).
  - `1_Data/Dataset_inf.csv` — **master index** (newest version; `Dataset_inf.xlsx`
    is outdated, no `Folder_Name` column, and is scheduled for deletion once
    collaborators confirm the CSV), **UTF-8 with BOM** (do NOT strip the BOM —
    Chinese collaborators open it in Excel on Chinese Windows which defaults to GBK;
    the BOM is what keeps diacritics like `ö`/`é`/`ü` from garbling).
    40-column structure (incl. `DOI`), key columns:
    `Folder_Name` (== study folder; **project-wide key ID for papers/preprints** —
    one row per experiment: `Folder_Name` + `Exp`), `Paper_ID` (**deprecated** —
    legacy link to the old manuscript Table 1; do NOT create new values), `Country`,
    `Stim_language`, `Stim_Type`, `License`, `numTrials`, `Sample_Size`/`Male`/`Female`,
    `subj_Group` (被试分组：**每 group 一行**，行唯一性 = `Folder_Name`+`Exp`+`subj_Group`
    三元组；组间研究按组拆行、每行填单个组名，无组间填 `All`；详见 SKILL.md 列说明).
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

- **4 studies previously lacked codebooks AND paper-level JSONs — 已补齐（2026-08-27 阶段 1）**: `Lee_2023_Cognition`, `Orellana-Corrales_2021_APP`, `Smith_2024_Cortex`, `Svensson_2023_QJEP` 现均有 paper JSON + 实验级 JSON + `Codebook_*_Clean.xlsx`（各研究 subj_info 当时已全覆盖：Lee/Smith/Svensson 由各自 `*_raw.csv` 生成（2026-08），Orellana-Corrales_2021_APP 由 Clean.csv 唯一 Subject 生成（2026-08-27，仍无任何原始数据，人口学 /）；Svensson exp JSON 的 `Equipment.Software` 论文未披露留 `/`）。
- **Missing raw data**: `Sun_2026_DataExp/` has `Sun_2026_DataExp_Exp1_Clean.csv`
  (largest cleaned file, 62 MB) but no `*_raw.csv`（实验级 JSON 已于 2026-08 补齐；
  raw 追补归阶段 4，用户+agent 共同决定）。
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
  copy-paste errors (e.g. `P5E1`–`P5E3` all labeled "Exp4" in the manuscript),
  N-count differences (manuscript "—" vs CSV concrete values), Trials wording
  differences (`numTrials` vs per-block counts), and some Study-label attributions
  (`P46E2`, `Pu2E1`, `Pt9E1`). These are tracked as open issues in
  `Consistency_Check_Table1_vs_DatasetInf_vs_Folders.md` and surfaced by
  `Generate_Table1.qmd` — do not re-report them as new findings. Per-item solvability
  judgments (auto-resolvable vs need-human) live in
  `3_Reports/Table1_Issues_Solvability.md` (linked from PROJ_STATE.md).
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
