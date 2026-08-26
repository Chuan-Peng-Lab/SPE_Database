# PROJ_STATE.md — SPE Database 项目状态（2026-08 更新）

## 当前目标

SPE（自我优先效应）数据库的整理与元数据治理：以「可读、自解释」的文件夹名（<Author>_<Year>_<期刊缩写>）作为全项目论文/预印本的关键 ID，以 1_Data/Dataset_inf.csv 为主索引，使 34 个已入库研究、9 个待入库条目的命名、年份、DOI、期刊信息与权威记录（Crossref/OSF/论文 JSON）对齐，并为稿件 Table 1 的再生成与比对提供可靠数据源。

## 已完成（均已验证）

- **关键 ID 迁移**：Folder_Name 成为全项目关键 ID（文件系统、CSV、Table 1 均以其为键）；Paper_ID/Paper 列标记 deprecated（仅作与旧稿件的过渡映射，保留一个版本周期）。
- **主表切换**：1_Data/Dataset_inf.csv 为唯一主索引（39 列、73 行、43 个唯一 Folder_Name、UTF-8 带 BOM）；旧 Dataset_inf.xlsx（旧 schema、无 Folder_Name 列）确认无 CSV 之外的数据，待合作者确认后删除；3_Reports/Output/data/ 下的旧快照（Dataset_inf.csv、Dataset_info.xlsx）已删除。
- **文件夹可读化改名**：26 个文件夹改名（EPHPP→JEPHPP、ERPH→IJERPH、CP→JCogPsych/CurrPsych、AP→ActaPsych、CC→ConsciousCog、BMC→BMCPsych、PR→PsychRes、NI→NeuroImage、HBM→HumBrainMap、BJP→BritJPsy、PM→PsychMed、CE→CogEmo、Psy→Psychophysiol、CP→CollabraPsy/CogRes、无后缀→psyarxiv/unpub/DataExp），含各文件夹内部全部 JSON/CSV/Codebook 前缀同步（per-participant 原始导出未动）。
- **DOI 填充**：64/73 行有论文 DOI（40 行取自 paper JSON，22 行经 Crossref 按作者+年份+期刊+题名核对）；Repo_Link 仅存数据链接，DOI 一律为论文 DOI。
- **年份对齐**：以 Crossref 正式印刷年为准（在线年仅用于纯在线期刊），修正 3 个文件夹年份（Constable 2021、McIvor 2021、Xu 2022）、1 处 CSV 年份（Wozniak 2022）；两篇预印本（Hu_2023_psyarxiv、Navon_2021_psyarxiv）经人工确认未发表，以最新版年份（2023/2021）为准。
- **四文档分工建立**：README.md（人类读者：数据使用指引+新命名目录树）、AGENTS.md（agent 效率约定：省 token、防无效搜索——Crossref/OSF 用法、会话收尾强制更新 PROJ_STATE.md）、SKILL.md（DOI 与年份核验流程、清洗工具指引、Dataset_inf.csv 39 列说明、validator 盲区说明、多语言 Identity 对照）、PROJ_STATE.md（会话状态快照）。AGENTS.md 已按四标准（省时/省token/准确/一致）审查修正：数字口径改为实测（43/73）、过滤措辞统一、<Suffix> 命名统一、已知问题补全（4 研究缺 paper JSON、Sun 缺实验 JSON）。
- **Table 1 管线**：Generate_Table1.qmd 输出 ID 列改为 Folder_Name；与稿件 v16 的逐行比对改用 CSV 行号键 + Paper_ID→行号 过渡映射，问题清单以 Folder_Name|ExpN 显示。
- **补 CSV 空 Exp（2026-08 会话）**：按 Paper_ID 的 E 后缀回填 10 行空 Exp——Lee Pu5E1/E2→1/2、Orellana-Corrales_2021_APP Pu9E1/E2→1/2、Schaefer P54E2/E3→2/3、Svensson_2023_QJEP Pu10E1→1、Sun_2026_DataExp Pu6E1→1、Hu_2023_SDB Pt5E1→1、Pan_2025_unpub Pu8E1→1；与文件夹/Table 1 对应值一致。Scheller_2026_elife 无 Paper_ID，无法推导，保留空白（见已知问题）。编辑保持字节保真（BOM+CRLF+无末尾换行，往返测试通过）；validator EXIT=0。
- **C 类命名修复（2026-08）**：Wang_2016_JEPHPP 与 Smith_2024_Cortex 的 trial 级原始文件由 `*_Exp1_Raw.csv`（大写 R）规范化为 `*_Exp1_raw.csv`（git mv 保留历史）；`Clean_Data.Rmd` 内旧引用为历史死引用（Wang 一条指向旧文件夹名 EPHPP），按惯例未改；复测 validator EXIT=0。
- **subj_info 补齐 + Exp_id 统一（2026-08）**：① 为 Lee_2023_Cognition（Exp1/2，47/51 行，age/sex/education/handedness 取自 raw.csv）、Smith_2024_Cortex（Exp1，48 行，剔除空 participant；age/gender 取自 raw.csv，未记录者填 /）、Svensson_2023_QJEP（Exp1，65 行，人口学填 /）生成 `*_subj_info.csv`，行数与 CSV Valid_Subj 吻合；② 全部 52 个 `*_subj_info.csv` 的 `Exp_id` 由旧 Paper_ID 统一为新格式 `<Folder_Name>_Exp<N>`（如 `Lee_2023_Cognition_Exp1`），48 个被跟踪文件经严格列级 diff 验证仅 Exp_id 列变化（BOM/行尾/引号风格保真）；validator EXIT=0。
- **Kirk_2025_BritJPsy subj_info 补全（2026-08）**：由 raw.csv 生成（Exp1 用 Participant Private ID，35 行 = CSV Valid_Subj；Exp2 用 NewGorillaID，90 行 = CSV Valid_Subj；人口学无来源填 /），替换原 2 个空占位文件。至此缺 subj_info 仅剩 Orellana-Corrales_2021_APP。
- **Martinez-Perez CSV 修正（2026-08，经合作者确认）**：该研究仅纳入 Exp2（其 Exp1 不含 self-matching task 故排除）；CSV 行 Exp 1→2（与 Paper_ID Pt27E2、文件夹 Exp2 文件一致），Note 列记录 "Exp1 excluded: no self-matching task; this row = Exp2"。字节保真编辑（BOM+CRLF+无末尾换行保持，diff 仅目标行 2 个单元格），validator EXIT=0。
- **subj_info 命名统一（2026-08）**：确认 `*_subj_info.csv`（原 `*_raw_Subject.csv`）内容为每实验被试基本信息/人口学表（Subject_ID/Exp_id + 人口学，个别含量表列，无聚合统计）；全库 52 个文件批量重命名（48 个 git mv 保留历史 + 4 个新文件），同步更新 SKILL.md/AGENTS.md/README.md/PROJ_STATE.md/Subject_Table.Rmd/Table1_Issues_Solvability.md 共 42 处引用（后两者的旧文件夹名仍属历史引用，未动）；validator EXIT=0。
- **.gitignore 更新（2026-08）**：12 个研究文件夹模式更新为当前命名（2026-08 改名后的 `<Author>_<Year>_<Suffix>`）并加前导 `/` 锚定根目录（消除无前导斜杠对 1_Data/ 新文件的误忽略，此后新文件提交无需 `git add -f`）；删除 2 条失效路径（Sun_2025、Zhang_2023_NI 旧命名文件，均不存在）。

## 关键决策

1. 期刊缩写须「专业人士可猜出期刊名」（完整对照表见 SKILL.md）；全名短期刊直用（Cognition/Cortex/NeuroImage/elife）；预印本用小写 psyarxiv，未发表数据用 unpub。
2. 年份规则：正式印刷年优先；仍仅在线的用在线年；预印本用最新版本年。
3. 清洗 = 最小预处理，不过滤无效值（ACC -1/2 保留并在 codebook 中说明）。
4. 校验链路：任何元数据改动后必须跑 Rscript 2_Code/validate_json_metadata.R（命名、年份漂移、exp 键、v2 组件完整性、文件夹↔CSV 交叉校验）。

## 核心文件

- 1_Data/Dataset_inf.csv — 主索引；1_Data/<Study>_<Year>_<Suffix>/ ×34 — 研究数据
- 2_Code/validate_json_metadata.R — 元数据校验器（含 9 个待入库白名单）
- 3_Reports/Generate_Table1.qmd + Generate_Table1.docx + Output/table1_problems.txt — Table 1 再生成与比对
- 3_Reports/Process_Data.Rmd — 下游分析（已改用 Folder_Name）
- .opencode/skills/spe-database-curation/SKILL.md — 通用 curation 技能（自足独立；命名语法、JSON schema、Codebook 规范、DOI/年份核验）
- AGENTS.md — agent 约定与已知 caveats（含 Document map）
- README.md — 人类读者入口（项目介绍/数据使用）
- 引用关系：本文档与 README.md、AGENTS.md 相互引用；数据整理任务统一加载 spe-database-curation 技能

## 测试结果（已实测）

- validator：EXIT=0（73 个 JSON、34 个文件夹、CSV 全部一致；9 个 pending 白名单放行）；2026-08 补 Exp 后复测仍 EXIT=0。
- Table 1 渲染：RENDER_EXIT=0；比对结果 58 行（qmd）vs 70 行（稿件），差异清单在 table1_problems.txt。
- git：5 个 commit（docs / data / reports + 2026-08 补 Exp 的 data / docs 两个 commit），工作区干净，未 push。

## 已知问题（未解决）

**条目级缺失汇总（2026-08 全量递归扫描，覆盖缺元数据/缺原始数据/缺 subject 级数据三类）**
分级标准：中度 = 缺元数据（codebook / JSON）；重度 = 缺 trial 级原始数据（`*_raw.csv`）。同一严重程度内按条目名 alphabetical 排列，整体由轻到重。

| 条目名（作者-年-期刊缩写） | 问题描述 | 缺少文件的数量 | 问题严重程度 |
|---|---|---|---|
| Lee_2023_Cognition | 无 codebook ×2、无 paper/实验级 JSON ×3（subj_info 已于 2026-08 补齐） | 5 | 中度 |
| Smith_2024_Cortex | 无 codebook ×1、无 paper/实验级 JSON ×2（subj_info 已于 2026-08 补齐） | 3 | 中度 |
| Svensson_2023_QJEP | 无 codebook ×1、无 paper/实验级 JSON ×2（subj_info 已于 2026-08 补齐） | 3 | 中度 |
| Orellana-Corrales_2021_APP | 无 raw.csv ×2、无 codebook ×2、无 JSON ×3、无 subj_info ×2（仅 2 个 Clean.csv，无任何原始数据） | 9 | 重度 |
| Sun_2026_DataExp | 无 raw.csv ×1、无实验级 JSON ×1（CSV 行信息稀疏；62 MB Clean 在库） | 2 | 重度 |
| Zhang_2023_NeuroImage | 无 raw.csv ×1（本次扫描新发现，待核实原始数据是否在外部仓库） | 1 | 重度 |

- Smith_2024_Cortex：raw 数据仅 48 名被试（含剔除 1 个空 participant），与 CSV Sample_Size=59 / Valid_Subj=58 差约 10 名——raw 导出疑似不全，待人工核对。

- CSV 遗留空白：Exp 空 1 行（Scheller_2026_elife，无 Paper_ID 无法按 E 后缀推导，待人工确认）、Country 空 9、City 空 13、Journal 空 4、Year 空 2（均为无同组源值或待人工确认的条目）；另有 License 空 8（Sui_2014_APP ×4、Pan、Sui_2014_unpub、Sui_2015_unpub ×2）、Stim_language 空 7（Kirk ×2、Scheller、Wang_2016、Wozniak_2020、Hu_2023_SDB、Pan）——2026-08 会话逐行核验补充。
- 稿件 Table 1 与数据仍有多处差异（12 个 pending 行、Exp 编号错位如 P5E1–E4 均标 Exp4、N/Trials/Language/Exp_Implement 不一致），详见 table1_problems.txt。
- Kirk_2025_BritJPsy.json 嵌套 schema 例外（内部键 KIRK_2025_BJP 保留不动）。
- Hu_2023_psyarxiv（PsyArXiv 预印本）与 Hu_2023_SDB（Science Data Bank）为两个独立条目，已确认分别保留。
- 历史管线 Clean_Data.Rmd 内仍引用旧文件夹名（纯历史记录，未改）。

## 失败方案（已弃用，勿重试）

1. Table 1 比对键用 (Folder_Name, Exp)：因 CSV 中存在重复组合（Kirk/Liang/Wozniak 曾各有多个 Exp=1 行）而失败 → 改用 CSV 行号键。
2. 通用网页搜索查 DOI：结果噪声大、难确证 → 改用 Crossref API（作者+年份+期刊+题名过滤）。
3. OSF API 的 filter[doi] 查询返回 400 → 改用预印本 GUID 直取。

## 下一步任务

1. （已完成 2026-08）补 CSV 空 Exp（按 Paper_ID 的 E 后缀回填 10 行；仅剩 Scheller_2026_elife 待人工确认）。
2. 为 4 个缺 JSON 的研究补 paper 级 JSON（需从论文提取摘要/结论，先出草稿确认）。
3. 创建 Sun_2026_DataExp_Exp1.json（v2 schema，未知项用 /）。
4. 合作者确认后：删除 Dataset_inf.xlsx、移除 deprecated 的 Paper_ID/Paper 列并简化 qmd 过渡映射。
5. 按 table1_problems.txt 逐项修正稿件 Table 1。
6. 人工补全剩余 Country/City/Journal/Year 空白。
7. 核实 Zhang_2023_NeuroImage 原始数据是否存于外部仓库（查 paper JSON 的 Repo_Link / OSF）；确认后补 raw.csv 或记录结论。
8. 待人工确认 Smith_2024_Cortex 样本差异（raw 48 vs CSV Sample_Size 59 / Valid_Subj 58）。
9. （已完成 2026-08）Martinez-Perez_2024_ConsciousCog：确认仅纳入 Exp2（Exp1 无 self-matching task），CSV 已修正并在 Note 记录。
