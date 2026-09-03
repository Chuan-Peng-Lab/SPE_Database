---
mode: primary
---

# AGENTS.md — SPE Database

## 🔒 全局最高级规则（GLOBAL RULE — 优先级高于本文件一切其他规则）

**Agent 永远不要自动执行 `git commit`**，也不要把「提交」当作会话收尾的默认步骤。
只有用户在对话中**明确确认/指示提交**后，才允许执行 commit（例如用户直接说"提交"/"commit"/"可以提交"等）。
以下情况**均不构成**确认：会话惯例、收尾清单、任务"完成"的推断、用户只说"修复/更新/插入/列出"等不含提交指令的话。
**不要每次回复都询问是否提交**：提交事宜只在用户主动询问/指示时处理。任务完成正常汇报结果即可；若有未提交改动，简单提示一句"改动未提交"即可，不重复追问。用户询问提交时，agent 列出待提交文件与 commit message 草案，获得明确确认后再提交。

**Agent 禁止过度无效思考（三试即止原则）**：遇到阻碍（解析失败/编号对不上/验证不通过/结构不清），**最多尝试 3 次不同方法；第 3 次仍无法解决，立即停下并向用户报告**——一句话说清「我卡在 X，已试 A/B/C 三种方法，原因是 Y，需要您决定/提供 Z」，禁止继续反复读取/反复推理。触发即止场景：
1. **同一数据反复读取**：为"找答案"反复读同一批文件（sav/xlsx/txt header 等）超 2 轮 → 停。数据不会因多读而变，答案要么在已读内容里、要么需用户提供。
2. **同一细节反复提假设**：编号重复/口径差异等，第 2 个假设失败后 → 停，把已排除假设 + 证据列给用户裁决。
3. **无思路的试探性命令**：动手前写不出一句话思路（问题 → 权威来源 → 连接键 → 预期输出）→ 先问用户，不执行。
4. **用户指定来源 = 唯一权威**：用户说"读 X 文件/以 X 为准"后，只用 X 推进，不引入其他文件交叉纠缠（用户要求的四方核对等验证除外）。
5. **用户催促/否定 = 立即停**：立即停止当前路径，转提问或改走用户指示方向，不解释、不辩解、不"最后再看一眼"。

反面教材（Bukowski Exp2）：被试编号确认中反复读 sav/txt header（>3 次）、连续提未经验证的编号口径假设，被用户多次打断。正确做法：第 1 轮确认冲突事实（txt header Subject 有重复 + sav 编号体系不同）后，立即把冲突 + 候选方案提交用户一锤定音（用户随后用 fix_subjID.xlsx 解决）。

## 数据文件格式约定（全局规则，全项目任何文件操作一律遵守）

- 主索引 `1_Data/Dataset_inf.csv`：UTF-8 **带 BOM** + CRLF + QUOTE_MINIMAL + 文件末尾无换行。**BOM 勿去**——中文 Windows Excel 默认 GBK 打开，BOM 是 `ö/é/ü` 等不乱码的唯一保障；BOM/行尾对标准读取透明（读取用 `read_dataset_inf.py` / `utils.R` 封装，或 Python `utf-8-sig` / R `fileEncoding="UTF-8-BOM"`）。
- **任何编辑 CSV 产物必须字节保真**：改前先做往返测试（读入原样写出 diff=0；writer 自动追加的末尾 `\r\n` 先截掉再比较）→ 写入 → 改后 diff 仅目标单元格、非目标列 0 差异。非主索引 CSV（`*_subj_info.csv` 等）格式各异（可能无 BOM + LF 行尾），编辑前先检测、按原格式回写。
- 操作细则与教训正文：SKILL.md §多语言与编码约定（原则 + BOM 理由的通用表述）与 §主索引「写入纪律：CSV 字节保真编辑」（操作细则）——本文件不重复正文。

## 会话约定

- **Never** start exploration task or fire background exploration without explicit user approval；可能耗时数小时的更不例外。
- **Never** `git add`/commit macOS cruft（`.DS_Store`、`.Rhistory`、`.Rproj.user`、`Thumbs.db`；`.gitignore` 已覆盖多数）。
- **exFAT 卫生**：git 操作前先 purge AppleDouble（`find . -name '._*' -delete`）；绝不提交 `._*`/`.DS_Store`，也不把 `._*` sidecar 当真实数据读取（纪律正文指针：SKILL.md §校验与卫生「文件操作安全纪律」）。

## Document map（文档分工与指针引用）

- `README.md` — 人类读者入口：项目介绍、数据使用指引、版本 changelog。
- `AGENTS.md`（本文件）— agent 干活规则 + 避坑经验；**不写状态性文字**（规模计数/待办/逐研究状态一律归 PROJ_STATE.md）。
- `PROJ_STATE.md` — 会话状态快照：新会话先读它再开工；每 session 收尾更新一次（见 §会话收尾）。
- `.opencode/skills/spe-database-curation/SKILL.md` — curation 规则正文归属（自足、可迁移他库）；任何数据整理/入库任务一律先加载 `skill(name="spe-database-curation")`。
- 引用方向：README ↔ AGENTS ↔ PROJ_STATE 相互引用并**统一指向技能**；每条规则正文只写一个归属文件，其余文件只放一行指针（含目标节）。
- 其他重要文档（正文均在各自文件，此处只放指针）：`3_Reports/Table1_Issues_Solvability.md`（稿件 Table 1 差异逐项可解性判定，与 PROJ_STATE §3 双向关联）；`3_Reports/Verifying_original_results_issues.md`（四方核对发现的问题统一记录处）；`REF/README_html2md.md`（REF 全文 html→json→md 管线用法）；`For_COLLABORATORS.md`（给合作者的推进指南：待数据补齐路径、新研究入库 4 步、REF 不上 GitHub 需联系 hcp4715）。

## 项目逻辑与任务判别（单向数据管道）

数据只向前流动：`原始公开数据 → 规范数据 → 稿件产出`；**稿件永不反向作为数据源**（稿件 v16 已废弃，其待收录条目信息已登记入 Dataset_inf.csv Note 列）。

- **整理/入库任务**：原始数据放输入区 `1_Data/<Study>/<Study>_Raw/`（只读、gitignore、不参与校验）→ 加载 SKILL 走 10 步流程：扫描识别实验/被试/会话 → 生成独立清洗脚本 `<Study>_clean.R`（配方见 SKILL §工具与脚本；`Clean_Data.Rmd` 仅为历史参考）→ 产出五件套（`*_raw.csv` / `*_ExpN_Clean.csv` / `*_subj_info.csv` / `Codebook_*_Clean.xlsx` / paper + 实验 JSON）→ 更新 `Dataset_inf.csv`（字节保真）→ 入库收口时重渲染 Table 1 并做四方核对。
- **分析/出数任务**：直接用规范数据与 `3_Reports/` 代码，产出写 `3_Reports/Output/`；与稿件比对默认关闭（`--param compare_manu:true` 按版本触发），禁止以稿件/旧产物反推数据。
- **两级校验（任何改动后必跑）**：结构级 `Rscript 2_Code/validate_json_metadata.R`（EXIT=0）+ 内容级 `Rscript 2_Code/validate_clean_csv.R`（0 ERROR）。
- 历史遗留（manu_v16、Dataset_inf.xlsx、非标准命名变体等）不主动修改。

## 干活效率规则（省 token）

- 大文件（>10 MB，见 caveats）**绝不整读入上下文**：用 `head` 看表头、Python 流式/按列提取；优先 `grep`/`glob` 定位；读写批量；验证输出截断（head/wc -l），禁止裸跑大 diff 或长 R 输出。
- **不要重复"发现"已知问题**：caveats 与 PROJ_STATE.md 已记录的当事实引用；对前序 agent 已核实事实做轻量抽查即可，不完整重验。
- `Generate_Table1.qmd` 渲染耗时数分钟：仅当输入（文件夹/Dataset_inf.csv/qmd）变化时才重渲染；日常校验用秒级 `validate_json_metadata.R`。
- 编辑 `Dataset_inf.csv` 须字节保真（格式与往返测试见 §数据文件格式约定；细则见 SKILL §主索引「写入纪律」）。
- 同一文件多处修改合并一次写入/提交；长任务（渲染、批量改名、大批量网络查询）放后台 job，并行推进只读步骤。
- **CRLF/LF 差异直接无视**（git text=auto 会归一化，diff 只显内容差异；处理 CRLF 文件注意 grep/awk 行为即可）；数值等价（浮点容差内）即视为一致，不追末位显示差异。

## 防无效搜索

- 查论文 DOI：**Crossref API**（`api.crossref.org/works?query.bibliographic=...&query.author=...&filter=container-title:...`）按作者+期刊+年份核对——通用网页搜索噪声大且难确证，勿用。
- 查预印本版本年：OSF API 按 GUID 直取 `api.osf.io/v2/preprints/<guid>/versions/`；`filter[doi]` 返回 HTTP 400，勿用。
- 外查前先查本地权威源：paper JSON（`DOI`/`Year`/`Journal`）、`Repo_Link`、`Dataset_inf.csv`。

## 防坑（教训在此；纪律正文在 SKILL.md §校验与卫生「文件操作安全纪律」）

- **覆盖/替换已有文件也必须经过用户确认**（教训：`curl -o` 失败（HTTP 406）把刚下载的 1 MB Scheller html 静默清成 0 字节——gitignore 目录无备份、内容永久丢失）。纪律：覆盖前 `ls -la`、下载先 /tmp 再 mv、写后核对。
- **删除文件必须万分谨慎，尤其是不在 git 中记录的文件**（教训：REF/ 全目录被 gitignore，一次清理 `_files` 误删 390 文件 + Scheller html/json/md 均不可恢复）。纪律：git check-ignore 确认跟踪、删除清单确认、`_trash_` 暂存、删后汇报、范围复述。
- **工具若含绝对路径，先确认它读的就是当前文件**（教训：脚本曾指向 `/Volumes/T3/...` 旧副本，输出"恰好与预期一致"掩盖错误）。纪律：改前 grep 工具源码确认数据源、异常先怀疑路径。
- **编辑文档追加条目时用将被保留的现有文本作锚点**（教训：曾把 PROJ_STATE「项目迁移」条目整体替换掉）。
- **CSV 字节保真编辑纪律见 SKILL.md §主索引「写入纪律」**（教训：加 `subj_Group` 列时 `r[0]` 误当 Folder_Name 致 74 行组名失配填 All；Hobbs 往返测试先截末尾 `\r\n`；subj_info 无 BOM+LF vs Dataset_inf BOM+CRLF）——此处仅指针。
- 字段语义类约定（License=数据许可 / Country-City=采集地 / Email 以 CSV 为准 / 多任务口径 / 全文核查）归 SKILL.md，此处不重复。

## 会话收尾（强制）

- 只在 session 收尾统一更新一次根目录 `PROJ_STATE.md`（「现状 + 未解决问题」结构），工作过程中不逐条写入：**更新重点是 §3 线路图（四类状态 + 问题清单）与 §5 快照数字**，逐论文检查状态变化（消解/新增/类别迁移/入库进展）；本次会话具体动作不再追加历史记录（只入 git commit）；只记已确认事实；同一 session 多处修改合并为收尾一次写入。
- 若本会话沉淀了可复用的约定/流程，补充到 SKILL.md（正文归属唯一处；写入前 grep 目标文件防重复，改后 grep 复核每条规则只有一处正文、其余为指针）。
- 提交：必须先获用户明确确认（见文首），按逻辑分组 commit（≤3 个）。

## 最小结构地图（细则正文归 SKILL/README/PROJ_STATE）

- **What**：SPE (Self-Prioritization Effect) Database — 使用 self-matching task（Sui, He & Humphreys 2012）的研究的 curated trial-level 数据库（逐研究五件套 + `1_Data/Dataset_inf.csv` 主索引）；收录规模/状态见 PROJ_STATE.md。
- 研究数据：`1_Data/<Author>_<Year>_<Suffix>/`（输入区 `<Study>_Raw/` + 五件套，见 §项目逻辑）。主索引 `Dataset_inf.csv`（格式约定见 §数据文件格式约定）：行 = `Folder_Name`+`Exp`+`subj_Group` 三元组，`Folder_Name` 为全项目关键 ID；`Paper_ID` deprecated 勿新建；旧版 `Dataset_inf.xlsx` 勿用；`Environmental_Info` = 刺激呈现软件而非 Lab/Online（后者由 exp JSON `Physical_Environment.Setting` 推导）——语义细则见 SKILL §主索引。
- 工具：`2_Code/`（独立清洗脚本 `<Study>_clean.R` 为现行主路径 + 两级校验器；历史：`Clean_Data.Rmd`、交互式/Shiny 清洗器）。
- 分析：`3_Reports/`（Process_Data / Subject_Table / Reports / Generate_Table1 / 1_Identity / 2_Mismatch / 3_Exploratory + `Output/`）。
- 全文库：`REF/`（`<Folder_Name>.pdf/.html`；整目录 gitignore、不上 GitHub）。

## Key conventions（正文唯一来源 = SKILL.md §数据标准化；此处仅样板与教训）

- 任何数据整理/入库先加载 SKILL，按其正文执行；AGENTS 不重复 SKILL 正文——**避免双源漂移**：本文件历史旧版模板曾把 Task 置于 Shape/Label 后与 v2 冲突，**严禁照抄本文件历史版本**。
- 产出前自查：Clean 表头逐列对照 SKILL 固定列顺序模板 v2（Subject→[Group]→[Session]→Task→[Phase]→…→Matching→Shape→Shape-Identity×3→Label→Label-Identity×3→[extraIV1/2]→[CorrResponse]→[Response]→RT_ms→RT_sec→ACC→研究特有尾部）；合规样板 = `Bukowski_2021_ActaPsych_Exp1_Clean.csv`；清洗脚本内 stopifnot 断言列序；Codebook 行序与 Clean 列序一致。
- Clean 命名语法 `<Author>_<Year>_<Suffix>_ExpN_Clean.csv` 及列/Identity 标准化规则按 SKILL。

## Known data-quality caveats（避坑：视为已知，勿重新"发现"）

1. **稿件 Table 1 与数据存在已知出入**（Exp 编号错抄如 P5E1–P5E3 全标 Exp4、N 口径差异、Trials 措辞、Study 归属等）——冻结于 `3_Reports/Consistency_Check_Table1_vs_DatasetInf_vs_Folders.md`，逐项可解性见 `Table1_Issues_Solvability.md`，`Generate_Table1.qmd` 输出 `table1_problems.txt`；勿再当新发现报告。
2. **清洗 = 最小预处理，不过滤**：ACC 等可能含无效值（-1 无反应、2 错键），有意保留并记录于 Codebook；使用者须按自己分析目标预处理。
3. **缺失代码引用**：`2_Code/README_Auto_Clean.md` 引用的 `SPE_Auto_Clean.R`/`Test_Auto_Clean.R` 不存在，勿寻找。
4. **大文件（>10 MB）勿整读**：`Sun_2026_DataExp_Exp1_Clean.csv` 62 MB、`Processed_Data_Filtered.csv` 60 MB、`Haciahmet_2023_Psychophysiol_Exp1_raw.csv` 42 MB、`Share_Data.RData` 31 MB。
5. **Table 1 渲染命令（RStudio 自带 quarto）**：`/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render Generate_Table1.qmd`——注意是 `app/quarto/bin/`，不是 `app/bin/quarto/`（流程 `1_Data → Dataset_inf.csv → Table 1`，ID 列 = Folder_Name，比对口径"Not specified"=missing、CC0=CC0 1.0 Universal；操作细节 PROJ_STATE §5）。

## Repo layout（git 卫生，防误判）

- Root-level `._*` files and `Contact*.xlsx` are gitignored；部分研究在仓库根的同名条目亦被 gitignore（如 `Smith_2024_Cortex/`、`Lee_2023_Cognition/`），实际跟踪路径只有 `1_Data/<Study>/...`——勿因根目录缺文件而误判缺失。
- 分支/工作区状态一律以 `git status` 为准，本文件不记录。
