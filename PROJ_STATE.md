# PROJ_STATE.md — SPE Database 项目状态（2026-09-02 精简版）

> **本文档只记录当前项目现状与未解决问题。** 历史会话记录（各研究入库过程、四方核对详情、治理动作、REF 统计明细、效率教训）已于 2026-09-02 精简时全部删除——完整历史可从 git 查询：备份 commit `9e90b8e`（之前版本即精简前全文），各研究/治理动作对应 commit message 可查。

## 1. 当前目标

SPE（自我优先效应）数据库的整理与元数据治理：以「可读、自解释」的文件夹名（<Author>_<Year>_<期刊缩写>）作为全项目论文/预印本的关键 ID，以 `1_Data/Dataset_inf.csv` 为主索引，使各研究的命名、年份、DOI、期刊信息与权威记录（Crossref/OSF/论文 JSON）对齐，并为稿件 Table 1 生成可靠数据源。

当前规模：**49 unique 研究 / 102 行**（47 已入库 + 2 暂缓：Hu_YQ_2026_ChinaSciData + Scheller_2026_elife）。全部数据入库或豁免后即达成阶段性成果。

## 2. 核心文件

- `1_Data/Dataset_inf.csv` — **主索引**（UTF-8 带 BOM，40 列；行唯一性 = `Folder_Name`+`Exp`+`subj_Group` 三元组；行序按 ID 列字母序）。`Dataset_inf.xlsx` 为旧版，待合作者确认 CSV 后删除。
- `1_Data/<Study>_<Year>_<Suffix>/` ×47 — 研究数据五件套（raw / Clean / subj_info / Codebook / paper+exp JSON）
- `AGENTS.md` — agent 约定与已知 caveats；`README.md` — 人类读者入口；三份相互引用，数据整理任务统一加载 `spe-database-curation` 技能
- `.opencode/skills/spe-database-curation/SKILL.md` — 通用 curation 技能（自足独立；命名语法、JSON schema、Codebook 规范、DOI/年份核验）

### 2.1 其他重要文档
- `For_COLLABORATORS.md` — **合作者推进指南**（正文归属本文件）：4 个待数据研究（Pan/Sun/Hu_YQ/Scheller）补齐路径 + 未来新研究入库 4 步 + REF/ 不上 GitHub 的版本同步提醒
- `2_Code/validate_json_metadata.R` — 结构级校验器；`2_Code/validate_clean_csv.R` — 内容级校验器
- `3_Reports/Generate_Table1.qmd` + `Output/table1_problems.txt` — Table 1 再生成与比对
- `3_Reports/Table1_Issues_Solvability.md` — Table 1 问题逐项可解性判定（与本文档 §3 双向关联）
- `3_Reports/Verifying_original_results_issues.md` — **作者原始结果验证问题统一记录处**（Issue 1–7，与本文档 §3 类别三关联）
- `3_Reports/Stage3_1_CrossCheck_archived.md` — 阶段 3.1 未解决问题编号清单（P1–P22，仅存档）
- `2_Code/qjep_verify/`、`2_Code/mcivor_verify/`、`2_Code/orellano2020_verify/`、`2_Code/wang2016_verify/`、`2_Code/hobbs_verify/`、`2_Code/wozniak2020_verify/` — 各研究四方核对脚本固化
- `REF/README_html2md.md` — REF 全文 HTML→MD 转换管线使用说明（正文归属本文件，AGENTS/PROJ_STATE 只放指针）

## 3. 当前论文状态分类

### 类别一：已入库、无问题（47 篇）

全部已做全量交叉核对（阶段 2 全文核查 + 阶段 3.1 21 研究 + 入库四方核对 + 描述性统计核对），无推进动作、无问题。

### 类别二：已入库、有数据缺口

| 论文 | 缺口 | 处置状态 | 下一步动作 |
|---|---|---|---|
| Sun_2026_DataExp | 无 raw.csv ×1（62 MB Clean 在库，448,800 行/506 被试完整，两级校验 0 ERROR；subj_info 334 为历史遗留 KNOWN） | 已知问题，Clean 确认完整 | 用户后续再决定是否补 raw（不阻塞） |
| Pan_2025_unpub | trial 数据齐全（40 被试 28,037 行 + 40 逐被试导出在库）但人口学与说明性元数据缺失：subj_info Gender/Handedness/Ethnicity/Employment_Status/Country/First_Language 全 `/`（Age 由 raw year 列 2000–2005 推导），paper JSON 仅 Unpublished 手稿占位、exp JSON 方法字段大部 `/`，License 未声明（2026-09-02 用户判定与 Sun 同类） | 已知问题，Clean 确认完整 | 等作者/用户提供原始数据与相关说明文件后补填（不阻塞） |
| Orellana-2020 Study 2 | Subject 34 仅 edat2（无 txt）；Subject 1-28 人口学缺失 | 已记 CSV Note | 不主动追；等作者/用户提供原始导出 |
| Zhang-2024 | exp1 数据 43 vs 论文 42 分析（差 1 原因未知）；人口学缺失 | 数据口径 43，论文口径记 Note | 不主动改 |

通用判定原则：Clean 已完成且说明文件（Codebook/JSON）齐全的研究，可豁免 `*_raw.csv`，不强制追补。

### 类别三：已入库、数据与论文存在出入（Issue 1–7）

| 论文 | Issue | 一句话摘要 | 处置 |
|---|---|---|---|
| Orellana-Corrales_2023_QJEP | 1 | OSF data_clean.csv in*/fm* 列互换（脚本打印顺序 bug），论文匹配统计基于错位数据；真实数据 SPE 定性仍成立 | 冻结记录（2_Code/qjep_verify/） |
| Orellana-Corrales_2020_ExpPsych | 2 | mt_data.lst 未修正编号中间产物；三份 LST 的 Tukey 口径不一；Study 2 排除名单未公开（枚举 528 组合 = Subject 24/30）；Study 3 统计无法复现 | 冻结记录（2_Code/orellano2020_verify/） |
| Wang_2016_JEPHPP | 3 | 论文 df(2,38) 隐含 N=20 vs 报告 21/数据 25；Exp2 人口学不符；Exp1 match-RT F 近似命中、Exp2 20 人子集可精确复现但排除名单不可唯一反推；association 实为 3AFC；breaking 键 n/m | 冻结记录（2_Code/wang2016_verify/） |
| Wozniak_2020_PLOS | 4 | xlsx 编号不对称；ER 列实为正确率；3 个 .dat 文件名 vs SubNum 不一致；脚本 1500 ms 硬编码 vs 论文 "2.5 MAD" | 冻结记录（2_Code/wozniak2020_verify/） |
| Zhang_2023_NeuroImage | 5 | subject 源文件 347 vs 论文分析样本 348（~8 名未共享 trial 数据） | 冻结记录 |
| Qi_2025_SciData | 6 | 论文 "square" vs 数据 rectangle.png（刺激命名差异，无统计影响） | 冻结记录 |
| Golubickis_2021_ActaPsych | 7 | Appendix B 单 RT SD 单元格无法复现（论文 112 vs 复算 122.5，无统计影响） | 冻结记录 |

统一处置：全部**冻结记录**（详情见 Verifying_original_results_issues.md），不阻塞 Status=1；**是否联系作者由项目负责人决定**（超库范围不主动执行）；触发动作：稿件版本更新时按冻结清单处置。

### 类别四：未入库（deferred）

| 论文 | 状态 | 原因 / 前置条件 | 下一步动作 |
|---|---|---|---|
| Hu_YQ_2026_ChinaSciData | deferred（原 Hu_2023_SDB） | 无输入区数据 | 输入区数据就位后入库（CSV 行保留，空白随行填齐） |
| Scheller_2026_elife | deferred（CSV 行已移除） | OSF 仅 TOJ trial 数据、匹配任务数据从未上传；用户指示不下载 OSF | 作者提供匹配数据后重入（known_unlisted 豁免保留） |

入库流程：用户将原始数据放入输入区后，加载 `spe-database-curation` 技能走 10 步流程；**入库后必做四方核对**（论文-代码-数据-原始数据 + 描述性统计核对）；验收：五件套齐全、命名合规、CSV 行更新、两级校验 EXIT=0、Generate_Table1.qmd 重渲染 RENDER_EXIT=0。

### CSV 遗留空白

- **License 空 39 行 / 17 研究**（无数据许可声明留空；2026-09-02 更新：6 个 `/` 转空白，Sui_2014_APP/Sui_2014_unpub/Pan 计入）：Amodeo×2、Atzeni×1、Bukowski×7、Golubickis×2、Kolvoort×1、Liu×1、Orellana-2020×3、Orellana-2023_QJEP×2、Pan×1、Sui_2014_APP×4、Sui_2014_unpub×1、Sui_2015×2、Svensson×3、Vicovaro×2、Wozniak_2020×3、Zhang_2024×2、Zhang_2026×2
- **City 空 3 行**：Sui_2014_unpub×1、Sui_2015×2；**City `NA`（Online 研究不适用）3 行**：Kirk×2、Perrykkad×1
- Stim_language 空 1 行（Hu_YQ_2026_ChinaSciData，deferred 入库时填齐）；Country 空 0；Journal 空 0（Journal `NA` 10 行 = preprint/unpublished 无期刊，not applicable）

### 其他冻结项

稿件 Table1 冻结清单（table1_problems.txt 111 行 + Table1_Issues_Solvability.md 107 项，稿件版本更新时启用）；Kirk_2025_BritJPsy.json 嵌套 schema 例外（内部键 KIRK_2025_BJP 保留）；Hu_2023_psyarxiv（PsyArXiv 预印本）与 Hu_YQ_2026_ChinaSciData（ChinaSciData）为两个独立条目，确认分别保留；历史管线 Clean_Data.Rmd 内仍引用旧文件夹名（纯历史记录，未改）。

### 触发式工作（跨类别）

横切约束：元数据改动 → `validate_json_metadata.R` EXIT=0；数据改动 → 加跑 `validate_clean_csv.R` 0 ERROR；Dataset_inf.csv 字节保真（改前往返测试、改后 diff 仅目标单元格）；同一文件多处修改合并一次写入；与已核实事实冲突的判断暂停问人，不自行覆盖。

## 4. 关键决策（19 条；规则正文唯一归属 SKILL.md）

### A. 命名与年份
1. **期刊缩写须「专业人士可猜出期刊名」**（完整对照表见 SKILL.md）；全名短期刊直用；预印本用小写 psyarxiv，未发表数据用 unpub。
2. **年份规则**：正式印刷年优先；仍仅在线的用在线年；预印本用最新版本年。

### B. 数据口径与修改依据
3. **清洗 = 最小预处理，不过滤无效值**（ACC -1/2 保留并在 codebook 中说明）。
4. **自动修改数据/元数据的依据 = 论文全文 + 原始数据**（JSON/CSV 均为衍生产物，互相矛盾时以全文/数据为准）。
5. **N 口径（2026-09-02 修订，正文见 SKILL.md §主索引）**：`Sample_Size` 一律 = Clean 中被试总数；`Valid_Subj` = 作者 summary-data 初步分析后保留的被试量（最小预处理不删除故通常 = Sample）；`Drop_Subj` = Sample − Valid；招募/论文口径记 Note（`Paper_N:` 前缀）。
6. **Exp2 Stim_Type 定值 `letter string`**（非词研究，库内值域新增，人工定值）。

### C. 主索引结构
7. **Dataset_inf.csv ID 列 = 复合键**：`ID` = `<Folder_Name>_Exp<Exp>_<subj_Group>`（组名空格→下划线）；行唯一性 = 三元组；已核实无下游依赖。
8. **Dataset_inf.csv 行序 = 按 ID 列字母序**：任何编辑后保持排序（新增研究追加后立即重排）。

### D. 身份与数据标准化
9. **`subj_Group` 每 group 一行**：组间研究按组拆行、每行填单个组名（组内 N/性别填组内值、总体口径记 Note），无组间保持单行 `All`。**Design 列不是组间判定的充分依据**。
10. **ACC 统一编码**：`1`=正确、`0`=错误（范围内错键）、`NA`=无反应、`-2`=范围外按键、`-3`=提前、`-4`=超时；负码仅在有明确证据时编码，否则 NA。
11. **自定义 Std 值先例**：6 类词表外允许原样/自定义值（奖赏刺激 `£9`/`£1`、内群体成员 `ingroup`），须 Codebook 枚举注明。
12. **CSV `Self`/`Close`/`Others` 三列 = Std 6 类简写**：CSV 与 Std 必须同一口径。
13. **元数据 JSON 内容一律英文**：中文说明性内容放仓库中文文档或脚本注释。
14. **Session 语义 / 纵向多时点研究**：`Session` = 一次完整实验参加；同一参加内重复任务段用 `Block` 列；纵向同一任务多时点不拆 Exp/组——合并单 Exp 行加 `Session` 列；`Sample_Size` = 跨时点 unique 被试数；`numTrials` 填每时点试次数（文本注明）。

### E. 采集地
15. **采集地判定**：**伦理委员会批准机构 = 数据采集机构**；作者履历单位不是采集地依据。

### F. 状态与流程治理
16. **校验链路**：元数据改动必跑 validate_json_metadata.R；数据改动加跑 validate_clean_csv.R。
17. **稿件 v16 已废弃**：Table 1 以 Generate_Table1.qmd 输出为准；与稿件自动比对仅在稿件版本更新时手动启用。
18. **Status=1 判定标准**：**最关键标准 = 库内五件套形成逻辑上完全一致、清晰可追溯的结构**（各层级互相印证、缺口已解释）；与原论文表述是否一致是次要指标——不一致不阻塞 Status=1，记录于 Verifying_original_results_issues.md（Issue 编号）+ exp JSON detail/CSV Note。
19. **Task/extraIV 命名规范**：`Task` 列区分联结任务类型（默认 `self-matching`；纯情绪面孔/金钱/伪词等用受控值）；任务内额外操纵自变量统一命名 `extraIV1`/`extraIV2`（语义入 Codebook+exp JSON detail）；列顺序统一模板（Subject→[Group]→[Session]→Task→[Phase]→[Condition]→Block→Trial→[Practice]→Matching→Shape→[ShapeLoc]→[Shape_Subtype]→Shape-Identity×3→Label→Label-Identity×3→[extraIV1/2]→[CorrResponse]→[Response]→RT_ms→RT_sec→ACC→研究特有尾部）。

## 5. 当前库内现状快照（2026-09-02 实测）

- **主索引**：Dataset_inf.csv **102 行 / 48 unique Folder_Name**；磁盘 **48 个研究文件夹**（47 curated + Scheller_2026_elife 输入区保留）；合计 49 研究 = 47 curated + 2 deferred
- **Status**：`1` 99 行；空白 **3 行**（Hu_YQ_2026_ChinaSciData=deferred；Pan_2025_unpub 与 Sun_2026_DataExp=类别二数据缺口，收口前有意留空，见 §3）
- **Codebook**：84 个（全库统一 canonical `Codebook_*_Clean.xlsx` 命名；2026-09-02 Liang 三分片 Codebook 随 Clean 合并净减 2）
- **JSON**：**131 个**（47 paper 级〔46 平铺 Paper_name + 1 Kirk_2025_BritJPsy 嵌套 Paper_ID〕+ 84 实验级；2026-09-02 按顶层键实测校正拆分口径，此前记「46 paper + 85 exp」系把文件名含 `ExpPsych` 的 Orellana-2020 paper JSON 误计入实验级）
- **校验基线**：
  - 结构级：`validate_json_metadata.R` EXIT=0（131 JSON / 48 文件夹 ↔ CSV 交叉一致；known_pending 1 个 = Hu_YQ_2026_ChinaSciData；known_unlisted 1 个 = Scheller_2026_elife）
  - 内容级：`validate_clean_csv.R` **84 文件 0 ERROR / 27 WARN**（2026-09-02 实测；Liang 三分片合并后 86→84 文件，组拆行口径 W2 保留；此前记 87 为含输入区 2 个 `*_Clean.csv` 的过计数，已修正）
  - Table 1 渲染：RENDER_EXIT=0；docx 主表 101 数据行（102 CSV 行 − Hu_YQ 无文件夹；2026-09-02 后未重渲染，行数按 CSV 推算）；table1_problems.txt 111 行冻结清单
  - git：分支 `main`（工作区状态以 git status 为准）

## 6. 散落未解决问题（自历史记录提取，不属于上述四类表）
- **Dalmaso E2 Label 列 = missing**（2026-09-01 记录）：意大利语原文无一手资料，待 OSF 原始数据补充后填实。
- **白名单豁免**：known_pending 1（Hu_YQ_2026_ChinaSciData）+ known_unlisted 1（Scheller_2026_elife）——入库时移除。

## 7. 历史归档说明

精简时删除的内容（均可从 git 找回）：

| 原章节 | 内容 | 归档位置 |
|---|---|---|
| §5 效率教训与弃用方案 | 一次 unpub 会话教训、阶段 2 犯错教训、弃用方案 3 条 | 规则已沉淀于 AGENTS.md §效率教训与防坑 + SKILL.md；弃用方案对应 git 历史 commit |
| §6 REF/ 全文收录统计 | 44 研究覆盖明细、模板适配记录、`*_DS.md` 说明、管线教训 | REF/README_html2md.md（正文归属）+ git 历史 |
| §7 完成进度 | 全量历史会话记录表（2026-08 ~ 2026-09-02，约 30 行，含各研究入库详情、四方核对、治理动作、全局校验基线） | **git 历史**：备份 commit `9e90b8e` 之前版本为精简前全文；各动作对应 commit message 可定位 |

查询方式：`git log --oneline -- PROJ_STATE.md` 或按研究/动作关键词 `git log --grep="<关键词>"`。全局校验基线（127 JSON / 82 Clean 0 ERROR / Table 1 97 行）已作为当前状态移入 §5，不随历史删除。
