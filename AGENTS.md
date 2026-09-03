---
mode: primary
---

# AGENTS.md — SPE Database

## 🔒 全局最高级规则（GLOBAL RULE — 优先级高于本文件一切其他规则）

**Agent 永远不要自动执行 `git commit`**，也不要把「提交」当作会话收尾的默认步骤。
只有用户在对话中**明确确认/指示提交**后，才允许执行 commit（例如用户直接说"提交"/"commit"/"可以提交"等）。
以下情况**均不构成**确认：会话惯例、收尾清单、任务"完成"的推断、用户只说"修复/更新/插入/列出"等不含提交指令的话。
**不要每次回复都询问是否提交**：提交事宜只在用户主动询问/指示时处理。任务完成正常汇报结果即可；若有未提交改动，简单提示一句"改动未提交"即可，不重复追问。用户询问提交时，agent 列出待提交文件与 commit message 草案，获得明确确认后再提交。

**Agent 禁止过度无效思考（三试即止原则）**：遇到阻碍（解析失败/编号对不上/验证不通过/结构不清），**最多尝试 3 次不同方法；第 3 次仍无法解决，立即停下并向用户报告，禁止继续反复读取/反复推理**。报告格式：一句话说清「我卡在 X，已试 A/B/C 三种方法，原因是 Y，需要您决定/提供 Z」。具体触发即止场景：
1. **同一数据反复读取**：为"找答案"反复读取同一批文件（sav/xlsx/txt header 等）超过 2 轮 → 停止。数据不会因多读一遍而变，答案要么在已读内容里、要么需要用户提供，不会在第 3 遍读取时出现。
2. **同一细节反复提出新假设**：编号重复、口径差异等问题，第 2 个假设失败后 → 停止，把已排除的假设 + 证据列给用户，请用户裁决。
3. **无思路的试探性命令**：动手前先写一句话思路（问题是什么 → 权威来源是谁 → 用什么键连接 → 预期输出是什么），写不出来 → 先问用户，不执行。
4. **用户指定来源 = 唯一权威**：用户明确说"读 X 文件/以 X 为准"后，只用 X 推进，不主动引入其他文件交叉验证纠缠（用户要求的四方核对等验证除外）。
5. **用户催促/否定 = 立即停**：用户说"不要再看 X""不要浪费时间""别瞎思考"时，立即停止当前路径，转为提问或改走用户指示的方向，不解释、不辩解、不"最后再看一眼"。

反面教材（Bukowski Exp2 会话）：被试编号确认环节反复读取 sav/Book1/txt header 多轮（>3 次尝试）、对 E-Prime Subject 重复与 sav Mea_* 口径提出多个未经验证的假设，用户多次打断（"你糊涂就把你的问题提出来""不要做任何的思考了""不要再看.sav文件了"）。正确做法：第 1 轮确认「txt header Subject 有重复 + sav 编号体系不同」后，应立即把冲突事实 + 候选方案提交用户裁决（用户随后用 fix_subjID.xlsx 一锤定音）。

## 会话约定（通用）

- **Never** start an exploration task or fire background exploration without explicit user
  approval.
- **Never** fire background exploration tasks that may take more than a few hours.
- **Never** `git add`/commit macOS cruft（`.DS_Store`、`.Rhistory`、`.Rproj.user`、
  `Thumbs.db`；`.gitignore` 已覆盖多数），也不要把 `._*` AppleDouble sidecar 当真实数据读取。
- **exFAT 卫生（正文归属此处）**：git 操作前先 purge AppleDouble（`find . -name '._*' -delete`），
  绝不提交 `._*`/`.DS_Store`（SKILL.md §校验与卫生「文件操作安全纪律」及收尾清单对该纪律仅放指针）。

## Document map（四文档分工与引用关系）

- `README.md` — 面向**人类读者**：项目介绍、数据使用指引。代理也应按需引用。
- `AGENTS.md`（本文件）— 面向**agent**：环境约束、效率约定、caveats；**只写 agent 做事的规则与避坑经验，不写状态性文字**（规模计数/待办/逐研究状态一律归 PROJ_STATE.md）。
- `PROJ_STATE.md` — **会话状态快照**：**每个 session 结束时统一更新一次**（工作过程中不逐条实时记录，避免文档冗长）；新会话先读它再开工。
- `.opencode/skills/spe-database-curation/SKILL.md` — **curation 技能（SPE_Database 规范）**：规则正文
  自足（不依赖本仓库文档，可迁移他库）；工具路径与仓库集成注记仅本仓库适用，见下方引用方向；任何数据整理/入库任务一律加载
  `skill(name="spe-database-curation")`。

- 引用方向：README ↔ AGENTS ↔ PROJ_STATE 三份相互引用，并**统一指向技能**；技能规则正文不反向依赖这三份文档（仓库文档对技能仅允许一行指针引用，如 SKILL.md §主索引「写入纪律」正文反向收编后，AGENTS 仅保留对该节的一行指针）。

### 其他重要文档：
- `3_Reports/Table1_Issues_Solvability.md` — **Table 1 问题可解性分析**：逐项判定稿件 Table 1 差异的可解性（可自动确定 / 需人工），与 PROJ_STATE.md 双向关联（未解决清单 ↔ 可解性判定）；依据 `Generate_Table1.qmd` 输出的 `table1_problems.txt`。
- `3_Reports/Verifying_original_results_issues.md` — **作者原始结果验证问题统一记录处**：入库四方核对中发现作者/OSF 原始产物与论文或数据不一致、或论文统计量无法复现的问题，一律记录于此（不再单独建文档）；正文见该文件头部，AGENTS/PROJ_STATE 只放指针。
- `REF/README_html2md.md` — **REF 全文 HTML → MD 转换管线使用说明**：`REF/html2Json.py`（HTML→JSON）+ `REF/json2md.py`（JSON→MD）的批量用法、摘要验收清单、新模板适配；全文正文归属本文件，AGENTS/PROJ_STATE 只放指针。
- `For_COLLABORATORS.md` — **给合作者的推进指南**（人类读者操作文档）：待数据研究补齐路径（数据放哪 + agent 指令模板）、未来新研究入库 4 步、REF/ 不上 GitHub 需联系 hcp4715 同步版本；正文归属本文件，其余文档只放指针。

## 项目总体逻辑（单向数据管道）

本项目是一条**单向数据管道**：`原始公开数据 → 规范数据 → 稿件产出`。
数据只向前流动；稿件永不反向作为数据源（稿件 v16 已废弃，其待收录条目信息
已登记入 Dataset_inf.csv Note 列）。

**阶段一：整理与入库（agent + skill 自动化）**
- 输入：各研究公开数据（论文/preprint/unpublished）下载至**输入区**
  `1_Data/<Study>/<Study>_Raw/`（只读，不参与校验；详见 SKILL.md §文件与文件夹规范（Raw input zone）
- 执行：agent 加载 `spe-database-curation` 技能 → 扫描输入区识别
  实验/被试/会话 → 生成独立清洗脚本 `<Study>_clean.R`（列映射 +
  Identity 三级标准化；配方参考 Clean_Data.Rmd，其降级为历史参考）→
  产出 `*_raw.csv` / `*_ExpN_Clean.csv` / `*_subj_info.csv` /
  Codebook / paper+实验 JSON → 更新 Dataset_inf.csv（字节保真）
- 校验（两级，任何改动后必跑）：`Rscript 2_Code/validate_json_metadata.R`
  （结构级）+ `Rscript 2_Code/validate_clean_csv.R`（内容级）

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
- 编辑 `Dataset_inf.csv` 保持字节保真：UTF-8 BOM、CRLF 行尾、文件末尾无换行；改前先做往返测试，改后核对 diff 只含目标单元格（完整 how-to 见 SKILL.md §主索引「写入纪律：CSV 字节保真编辑」）。
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

### 防坑（agent 操作纪律；纪律正文统一在 SKILL.md §校验与卫生「文件操作安全纪律」，此处保留教训与指针）

- **覆盖/替换已有文件也必须经过用户确认**（教训：`curl -o` 静默覆盖用户刚下载的 Scheller html——curl 失败（HTTP 406）时 `-o` 把 1 MB 完整文件清成 0 字节，gitignore 目录无备份、内容永久丢失）。纪律正文（覆盖前 `ls -la`、下载先 /tmp 再 mv、写后核对）见 SKILL.md §校验与卫生「文件操作安全纪律」。
- **删除文件必须万分谨慎，尤其是不在 git 中记录的文件**（教训：`REF/` 全目录被 `.gitignore` 忽略，一次清理 `_files` 删 390 文件 + 误删 Scheller html/json/md 均不可恢复，用户重新下载才找回）。纪律正文（git check-ignore 确认跟踪、删除清单确认、_trash_ 暂存、删后汇报、范围复述）见 SKILL.md §校验与卫生「文件操作安全纪律」。
- **工具若含绝对路径，先确认它读的就是当前文件**（教训：`analyze_csv_blanks.py` 曾指向 `/Volumes/T3/...`，读到旧副本且输出"恰好与预期一致"掩盖错误）。纪律正文（改前 grep 工具源码确认数据源、异常先怀疑路径）见 SKILL.md §校验与卫生「文件操作安全纪律」。
- **编辑文档追加条目时用将被保留的现有文本作锚点**（教训：曾把 PROJ_STATE「项目迁移」条目整体替换掉）。纪律正文见 SKILL.md §校验与卫生「文件操作安全纪律」。
- **CSV 字节保真编辑（Dataset_inf.csv 等）纪律正文见 SKILL.md §主索引「写入纪律：CSV 字节保真编辑」**（教训：加 `subj_Group` 列时 `r[0]` 误当 Folder_Name 致 74 行组名失配填 All；Hobbs 往返测试先截末尾 `\r\n`；subj_info 无 BOM+LF 行尾 vs Dataset_inf BOM+CRLF）——此处仅指针，不重复正文。
- 字段语义类约定（License=数据许可 / Country-City=数据采集地 / Email 以 CSV 为准 / 多任务口径 / 全文核查）见 `spe-database-curation` 技能（SKILL.md），此处不重复。

### 会话收尾（强制）
- 更新根目录 `PROJ_STATE.md`（「现状 + 未解决问题」结构）：**更新重点是第 3 节「当前推进的线路图」（四类状态 + 问题清单）与第 5 节「库内现状快照」数字**——每次收尾时逐论文检查其状态是否发生变化（问题消解/新增、类别迁移、入库进展），状态变化更新到 3 节对应类别行，本次会话完成的具体动作**不再追加历史记录**（历史已精简，只入 git commit）；其余节仅在确有必要时微调。只记已确认事实。
- **更新时机：只在 session 收尾统一更新一次**，工作过程中不逐条实时写入 PROJ_STATE.md（避免文档膨胀）；同一 session 内的多次修改合并为收尾一次写入。若 session 尚未结束，改动先记在对话/待办中，不写文档。
- 若本会话沉淀了可复用的约定/流程，同步补充到 `spe-database-curation` 技能（SKILL.md）。
- **沉淀去重**：四文档按分工各存专属正文、相互指针引用，**不复制同样内容到多个文件**——每条规则正文只写一个归属文件（AGENTS.md=agent 仓库纪律与教训（会话收尾、exFAT、commit 规则等）+ 防坑教训指针 / SKILL.md=curation 规则正文，含字段语义与可执行纪律正文（写入纪律、文件操作安全纪律等）/ PROJ_STATE.md=会话事实快照），其余文件只放一行指针（含目标节/编号）。操作要求：① 写入前 `grep` 目标文件确认该规则尚无正文，避免文件内重复；② 删除/重编号后立即同步更新所有指针中的引用位置；③ 沉淀后 `grep` 复核每条规则只有一处正文、其余为指针。
- 如需提交：**必须先获得用户明确确认**（见文首「全局最高级规则」），确认后按逻辑分组 commit（≤3 个）。

## Project context

- **What**: SPE (Self-Prioritization Effect) Database — 使用 self-matching task
  (Sui, He & Humphreys 2012) 的研究的 curated trial-level 数据库（逐研究五件套 +
  `1_Data/Dataset_inf.csv` 主索引）。收录规模/待办/逐研究状态属状态性信息，
  一律以 `PROJ_STATE.md` 为准（本文件不记录）。

- **Structure**:
  - `1_Data/` — curated study folders (`<Author>_<Year>_<Journal>/`), plus `Dataset_inf.csv`
    master index（旧版 `Dataset_inf.xlsx` 已过时，勿用）。Each folder contains:
    - raw data: `*_raw.csv` (trial-level), `*_subj_info.csv` (subject-level),
      sometimes `*_Raw/` subfolders with per-participant exports (E-Prime `.edat2`,
      MATLAB `.mat`, PsychoPy `.psydat`).
    - cleaned data: `*_ExpN_Clean.csv`.
    - metadata: `Codebook_*_Clean.xlsx`,
      study-level `.json` (paper metadata) and experiment-level `.json`
      (methodology, v2 hierarchical schema: five components under `exp<N>`).
  - `1_Data/Dataset_inf.csv` — **master index**（旧版 `Dataset_inf.xlsx` 过时且无
    `Folder_Name` 列，勿用）, **UTF-8 with BOM** (do NOT strip the BOM —
    Chinese collaborators open it in Excel on Chinese Windows which defaults to GBK;
    the BOM is what keeps diacritics like `ö`/`é`/`ü` from garbling).
    40-column structure (incl. `DOI`), key columns:
    `Folder_Name` (== study folder; **project-wide key ID for papers/preprints** —
    row key = `Folder_Name` + `Exp` + `subj_Group`, see `subj_Group` below), `Paper_ID` (**deprecated** —
    legacy link to the old manuscript Table 1; do NOT create new values), `Country`,
    `Stim_language`, `Stim_Type`, `License`, `numTrials`, `Sample_Size`/`Male`/`Female`,
    `subj_Group` (被试分组：**每 group 一行**，行唯一性 = `Folder_Name`+`Exp`+`subj_Group`
    三元组；组间研究按组拆行、每行填单个组名，无组间填 `All`；详见 SKILL.md §主索引).
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
    - `Clean_Data.Rmd` (5053 lines) — 历史配方参考；现行主路径 =
      独立清洗脚本 `<Study>_clean.R`，见 SKILL.md §工具与脚本）。
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
      RStudio's bundled quarto（实测路径：
      `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render
      Generate_Table1.qmd`——注意是 `app/quarto/bin/`，不是 `app/bin/quarto/`）。
      Operational details: PROJ_STATE.md §5.
    - `Consistency_Check_Table1_vs_DatasetInf_vs_Folders.md` — Chinese report of the
      3-way consistency check (manuscript Table 1 vs CSV vs folders).
- **Stack**: R / R Markdown / Shiny. RStudio project (`SPE_Database.Rproj`).
- **Key conventions**: cleaned variables standardized to `Subject`, `Shape`, `Label`,
  `Matching`, `ACC`, `RT_ms`, and 3-level Identity columns
  (Origin → English → Standardized: NonPerson/Self/Close/Acquaintance/Celebrity/Stranger).
  `Task` 列（默认 `self-matching`，其他受控值 facialExpression-matching /
  monetaryValue-matching / self-pseudoWords）+ 任务内额外自变量 `extraIV1`/`extraIV2` +
  **固定列顺序模板 v2（硬性规范，不可自定义）**：`Subject→[Group]→[Session]→Task→[Phase]→
   [Condition]→Block→Trial→[Practice]→Matching→Shape→[ShapeLoc]→[Shape_Subtype]→
   Shape-Identity×3→Label→Label-Identity×3→[extraIV1]→[extraIV2]→[CorrResponse]→[Response]→
   RT_ms→RT_sec→ACC→[研究特有保留列尾部]`（可选列不存在则跳过，但已存在列相对顺序不得改变）。
   **列顺序为强制校验项**：新建/重排 Clean 后必须把表头与上述模板逐列对照自查（Task 紧跟
   Subject 后、Phase 在 Task 后、extraIV1 在 Label-Identity×3 后，均不得提前到列首），以
   `Bukowski_2021_ActaPsych_Exp1_Clean.csv` 为合规样板；产出前在清洗脚本内用 stopifnot 断言
   列序；Codebook 行序与 Clean 列序必须一致。易错点与校验细则见 SKILL.md §数据标准化
   「列顺序合规要求」。**严禁照抄本文件历史旧版模板**（该模板曾把 Task
   置于 Shape/Label 后、Identity 块堆叠末尾，与 v2 冲突）。
  Cleaned file naming: `<Author>_<Year>_<Suffix>_ExpN_Clean.csv` (Suffix = readable
  journal/database abbreviation, full short journal name, or psyarxiv/unpub tag;
  see the curation skill).
- **Raw data formats**: CSV dominant; also E-Prime `.edat2`/`.emrg*`
  MATLAB `.mat`/`.m`, PsychoPy `.psydat`/`.dat`. No parquet anywhere.
- **Version**: v0.1.5. See `README.md` for full changelog.

## Known data-quality caveats

Treat these as known issues, not new discoveries — do not "find" them again:

- **Manuscript Table 1 vs data has known discrepancies**: Exp-number
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

## Repo layout（git 卫生，防误判）

- Root-level `._*` files and `Contact*.xlsx` are gitignored；部分研究在仓库根的
  同名条目亦被 gitignore（如 `Smith_2024_Cortex/`、`Lee_2023_Cognition/`），
  实际跟踪路径只有 `1_Data/<Study>/...`——勿因根目录缺文件而误判缺失。
- 分支/工作区状态一律以 `git status` 为准，本文件不记录。
