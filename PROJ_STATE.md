# PROJ_STATE.md — SPE Database 项目状态（2026-09-02 精简版）

> **本文档只记录当前项目现状与未解决问题。** 历史会话记录（各研究入库过程、多源交叉核验详情、治理动作、REF 统计明细、效率教训）已于 2026-09-02 精简时全部删除——完整历史可从 git 查询：备份 commit `9e90b8e`（之前版本即精简前全文），各研究/治理动作对应 commit message 可查。

## 1. 当前目标

SPE（自我优先效应）数据库的整理与元数据治理：以「可读、自解释」的研究文件夹名 `<Folder_Name>`（= 该 study 在全库的唯一 ID，格式 `<Author>_<Year>_<期刊缩写>`）作为全项目论文/预印本的关键 ID，以 `1_Data/Dataset_inf.csv` 为主索引，使各研究的命名、年份、DOI、期刊信息与权威记录（Crossref/OSF/论文 JSON）对齐，并为稿件 Table 1 生成可靠数据源。

当前规模：**52 unique 研究 / 114 行**（51 已入库 + 1 暂缓：Scheller_2026_elife；`Hu_YQ_2026_ChinaSciData` = 2 个实验 / 4 行 / 62 人〔Exp1 北京 = 两个任务合并、Exp2 开封〕，Clean 与 raw 各按被试边界分 2 片；`Wu_2026_Chinaxiv` = 2 个实验 / 3 行；`Sun_2026_DataExp` 的 Clean 与 raw 各分 4 片）。全部数据入库或豁免后即达成阶段性成果。

## 2. 核心文件

- `1_Data/Dataset_inf.csv` — **主索引**（UTF-8 带 BOM，**37 列**〔`Study`/`Paper_ID`/`Paper` 三列已废弃、经确认不再恢复，见 §4 决策 20〕；行唯一性 = `Folder_Name`+`Exp`+`subj_Group` 三元组；行序按 ID 列字母序）。
- `1_Data/<Folder_Name>/` ×51 — curated 研究标准文件（standard files：5 类规范产物 = raw / Clean / subj_info / Codebook / paper+exp JSON；磁盘另有 1 个 deferred 输入区文件夹 Scheller_2026_elife）
- `AGENTS.md` — agent 约定与已知 caveats；`README.md` — 人类读者入口；三份相互引用，数据整理任务统一加载 `spe-database-curation` 技能
- `.agents/skills/spe-database-curation/SKILL.md` — 通用 curation 技能（自足独立；**领域术语基准 +「表述规范」工作用语对照表**、命名语法、JSON schema、Codebook 规范、DOI/年份核验）

### 2.1 其他重要文档
- `1_Data/README.md` — **数据使用者入口**（正文归属本文件）：文件夹结构 / 数据 / 实验实施元数据三层标准化的简明说明 + `Task` ≠ 条件变量的高亮提示与已登记示例。
- `For_COLLABORATORS.md` — **合作者推进指南**（正文归属本文件）：待合作者推进的 3 项（Hu_YQ 补输入区原始数据与确认设计口径〔清单见 `3_Reports/Hu_YQ_2026_Issues.md`〕 / Scheller 补匹配任务数据 / Wu_2026_Chinaxiv Exp2 数据版本澄清，末项待项目负责人决定是否联系作者）补齐路径 + 未来新研究入库 4 步 + REF/ 不上 GitHub 的版本同步提醒
- `2_Code/validate_json_metadata.R` — 结构级校验脚本（2026-10 起新增 `Setting`/`Modality`/`Stimulus_order` 受控词表检查，WARN 级；Hu_YQ 偏差已于 2026-10-12 修正、原 KNOWN 豁免删除；W5 新增 `Hu_YQ_2026_ChinaSciData_Exp2` 的 `filler` 登记）；`2_Code/validate_clean_csv.R` — 内容级校验脚本（2026-09-25 起支持 `_Clean_part<N>.csv` 分片：按逻辑数据集聚合 E3/W2、新增 E4 表头一致性；2026-10 起 ACC 值域收紧为 `1`/`0`/`NA`/`-2`/`-3`/`-4`，并按原文本检查空字段；**2026-10-06 起 W5（Matching 值域）与 W4 同款支持 `known` 登记豁免**——用于「任务本身无匹配维度 → 该列为 NA」的研究，已登记 `Wu_2026_Chinaxiv_Exp1/Exp2`）
- `2_Code/split_clean_csv.py` — 大文件分片工具（> 50 MB 的 `*_Clean.csv` 按被试边界切分；默认 dry-run，`--apply` 备份原件后写入并逐字节校验可还原；规则正文见 SKILL §文件与文件夹规范「大文件拆分」）
- `3_Reports/Generate_Table1_v2.R`（**现行 Table 1 工具**，`Rscript` 出 `Output/Table1_v2.csv` + `Table1_v2_summary_stats.csv`，不依赖 quarto）+ `Output/table1_problems.txt`（qmd 时代产物，仍可查）— Table 1 再生成与比对；旧 `Generate_Table1.qmd` 已失效（`Paper_ID` 列移除后无法渲染）
- `3_Reports/Table1_Issues_Solvability.md` — Table 1 问题逐项可解性判定（与本文档 §3 双向关联）
- `3_Reports/Verifying_original_results_issues.md` — **作者原始结果验证问题统一记录处**（Issue 1–9，与本文档 §3 类别三关联）
- `3_Reports/Hu_YQ_2026_Issues.md` — **Hu_YQ_2026_ChinaSciData 未解决问题清单**（只记未解决项：H1 输入区原始数据、H2 开封公开版本、H3 任务映射、H5/H6/H8/H9/H14③ 设计与口径、N1–N3、N5 开封交付缺漏；已解决编号不再保留；与本文档 §3 类别二行关联）
- `3_Reports/Wu_2026_Chinaxiv_Ingestion_Plan.md` — **Wu_2026_Chinaxiv 入库计划**（列序/自变量映射、试次结构与分块、三方核对、exp JSON 字段完整性与 Codebook 编写计划、§10 Issues 清单 = Wu Issue 1–8 独立编号；与本文档 §3 类别三新增行关联）
- `2_Code/qjep_verify/`、`2_Code/mcivor_verify/`、`2_Code/orellano2020_verify/`、`2_Code/wang2016_verify/`、`2_Code/hobbs_verify/`、`2_Code/wozniak2020_verify/` — 各研究多源交叉核验脚本固化
- `REF/README_html2md.md` — REF 全文 HTML→MD 转换管线使用说明（正文归属本文件，AGENTS/PROJ_STATE 只放指针）
- `3_Reports/CodeReview_and_v16.2_Consistency_Report.md` — **稿件 v16.2 生成 + 三段分析代码审查报告**（2026-09-24；含代码 bug 清单 B1–B6、v2 结果、Table 1 差异 41 处、参考文献审计）；产物 = `_v2` 代码/图 + `Generate_Table1_v2.R` + `Datasets/4_Writing/SPE_数据库_v16.2.docx`

## 3. 当前论文状态分类

### 类别一：已入库、无问题（39 篇）

全部已做全量交叉核对（阶段 2 全文核查 + 阶段 3.1 21 研究 + 入库多源交叉核验 + 描述性统计核对），无推进动作、无问题。（39 = 51 curated 减去类别二/三涉及的 12 篇去重研究；2026-09-25 起 `Hu_YQ_2026_ChinaSciData` 计入类别二。）
2026-09-25 自类别二迁入：`Pan_2025_unpub`（用新补原始材料重清洗后完成确认，Status=1；未发表数据无全文核查/多源交叉核验环节，数据许可由项目负责人确认为 `CC BY 4.0`）。
2026-10-01 自类别二迁入：`Sun_2026_DataExp`（两任务整合重建标准文件：Task1 = SMT_1/Session 2、Task2 = SMT_2/Session 3，**按两任务交集保留 589 被试 / 1,040,880 行**〔本数据特例，不写入 SKILL；见 `removed_subjects_log.md` §8〕；新增 `*_raw.csv` 与 `subj_info` 重建，raw 与 Clean 各按被试边界分 4 片；两级校验 0 ERROR，Sun 的 E3 KNOWN 豁免已移除；发表状态与 DOI 待补见 §4 决策 22；`Design` 列文案由项目负责人撰写）。

### 类别二：已入库、有数据缺口

| 论文 | 缺口 | 处置状态 | 下一步动作 |
|---|---|---|---|
| Orellana-2020 Study 2 | Subject 34 仅 edat2（无 txt）；Subject 1-28 人口学缺失 | 已记 CSV Note | 不主动追；等作者/用户提供原始导出 |
| Zhang-2024 | exp1 数据 43 vs 论文 42 分析（差 1 原因未知）；人口学缺失 | 数据口径 43，论文口径记 Note | 不主动改 |

| Hu_YQ_2026_ChinaSciData（中国科学数据，DOI 10.57760/sciencedb.08117；2 实验 / 4 行 / 62 人） | **无输入区** `Hu_YQ_2026_ChinaSciData_Raw/`（H1）→ 清洗脚本不能在库内重跑、标准文件无法回溯复核；开封数据公开版本未核实（H2）；任务↔文件映射待作者确认（H3）；设计/口径待确认：开封练习段（H5）与 block 口径（H6）、北京练习试次数（H8）、被试级试次差异（H9）、情绪形状任务的 `Stim_Type`（H14③）、开封块/试次编号（N3）；材料待补：开封性别（N1）、6009/6031 年龄（N2）、开封 18 个缺失阶段与 4 处异常导出（N5） | Clean / raw / subj_info / Codebook / exp JSON 齐备；两级校验 0 ERROR（结构级 `validate_json_metadata.R` EXIT=0；内容级 `validate_clean_csv.R` 0 ERROR / 28 WARN，均为已知口径或登记例外） | 合作者提供 H1（含 N5 的缺漏阶段）后重跑 `clean.R` 复核产出并做多源交叉核验；其余项按 `3_Reports/Hu_YQ_2026_Issues.md` 回复更新 |

通用判定原则：Clean 已完成且说明文件（Codebook/JSON）齐全的研究，可豁免 `*_raw.csv`，不强制追补。
- **另见 §6**：16 个 Clean 文件（10 研究）缺 `Shape`/`Label` 可读值列——非回归（自创建起即无该列，非删列），处置待定。

### 类别三：已入库、数据与论文存在出入（Issue 1–9；2026-09-04 新增 Issue 8 = Lee_2026_BritJPsy；2026-10-06 新增 `Wu_2026_Chinaxiv`——其**Wu Issue 1–8 为本研究独立编号**，登记于入库计划 §10，不并入本文件的 Issue 1–8；2026-10-13 新增 Issue 9 = Zhao_2026_PsychonBullRev）

| 论文 | Issue | 一句话摘要 | 处置 |
|---|---|---|---|
| Orellana-Corrales_2023_QJEP | 1 | OSF data_clean.csv in*/fm* 列互换（脚本打印顺序 bug），论文匹配统计基于错位数据；真实数据 SPE 定性仍成立 | 登记暂缓（2_Code/qjep_verify/） |
| Orellana-Corrales_2020_ExpPsych | 2 | mt_data.lst 未修正编号中间产物；三份 LST 的 Tukey 口径不一；Study 2 排除名单未公开（枚举 528 组合 = Subject 24/30）；Study 3 统计无法复现 | 登记暂缓（2_Code/orellano2020_verify/） |
| Wang_2016_JEPHPP | 3 | 论文 df(2,38) 隐含 N=20 vs 报告 21/数据 25；Exp2 人口学不符；Exp1 match-RT F 近似命中、Exp2 20 人子集可精确复现但排除名单不可唯一反推；association 实为 3AFC；breaking 键 n/m | 登记暂缓（2_Code/wang2016_verify/） |
| Wozniak_2020_PLOS | 4 | xlsx 编号不对称；ER 列实为正确率；3 个 .dat 文件名 vs SubNum 不一致；脚本内固定为 1500 ms，未采用论文报告的 2.5 MAD 标准 | 登记暂缓（2_Code/wozniak2020_verify/） |
| Zhang_2023_NeuroImage | 5 | subject 源文件 347 vs 论文分析样本 348（~8 名未共享 trial 数据） | 登记暂缓 |
| Qi_2025_SciData | 6 | 论文 "square" vs 数据 rectangle.png（刺激命名差异，无统计影响） | 登记暂缓 |
| Golubickis_2021_ActaPsych | 7 | Appendix B 单 RT SD 单元格无法复现（论文 112 vs 复算 122.5，无统计影响） | 登记暂缓 |
| Lee_2026_BritJPsy Exp2 | 8 | 论文 Methods 句称非自我 prime 为 best friend's first name，但 E3a.iqx 脚本与数据为 stranger 名（Figure 5 标题亦写 "Self vs Friend"）；Abstract/Intro/Results/OSF Rmd 均用 self/stranger | 登记暂缓（exp JSON detail + Dataset_inf Note） |
| Wu_2026_Chinaxiv | Wu 1–8 | 作者共享 Exp2 CleanData 与 raw 不可对应（三版本；半数被试行不可追溯）；Exp2 匹配试次 192（raw）vs 256（稿件）；Exp2 RT 窗口 4000 ms（预注册/数据）vs 3000（稿件）；7 个早期版本导出缺 `task_type`；Exp1 作者 `data_color` 重复计入 Subject 70；显示器 1080×768（稿件）vs canvas 1920 px（raw）；5 人 canvas 1440–1536 px；稿件红/蓝 HSL 标注写反 | 登记暂缓（Wu Issue 1–8 见 `3_Reports/Wu_2026_Chinaxiv_Ingestion_Plan.md` §10 + 两份 exp JSON detail + 主索引 Note；**不并入 Verifying_original_results_issues.md**，2026-10-06 用户定案） |
| Zhao_2026_PsychonBullRev | 9 | Exp1 有 17/48 份原始日志的练习段未以「连续正确 6 次」结束（结尾连续正确 0–5 次、练习长度 6–73 试次），与归档程序 `SPE.psyexp` 的终止规则不符；17 份均为 2025-03-31 之前的场次（程序文件最后修改日），疑当时使用较早版本；Exp2/Exp3 全部符合 | 登记暂缓（练习试次作者分析时已排除 → 不影响论文结果；已记三份 exp JSON detail + 主索引 Exp1 行 Note，原始日志完整保留练习试次） |

统一处置：全部**登记暂缓**（Issue 1–9 详情见 Verifying_original_results_issues.md；`Wu_2026_Chinaxiv` 的 Wu Issue 1–8 见其入库计划 §10），不阻塞 Status=1；**是否联系作者由项目负责人决定**（超库范围不主动执行）；触发动作：稿件版本更新时按暂缓清单处置。

### 类别四：未入库（deferred）

| 论文 | 状态 | 原因 / 前置条件 | 下一步动作 |
|---|---|---|---|
| Scheller_2026_elife | deferred（CSV 行已移除） | OSF 仅 TOJ trial 数据、匹配任务数据从未上传；用户指示不下载 OSF | 作者提供匹配数据后重入（known_unlisted 豁免保留） |

入库流程：用户将原始数据放入输入区后，加载 `spe-database-curation` 技能走 10 步流程；**入库后必做多源交叉核验**（论文-代码-数据-原始数据 + 描述性统计核对）；验收：标准文件齐全、命名合规、CSV 行更新、两级校验 EXIT=0、`Rscript 3_Reports/Generate_Table1_v2.R` 重跑成功。

### CSV 遗留空白

- **License 空 40 行 / 17 研究**（无数据许可声明留空；2026-09-09 +4 = Zhao_2026_PsychonBullRev×4 待 OSF 公开后确认；2026-10-13 −4 = 该研究 OSF 仓库已公开并声明 CC BY 4.0，据数据页填实 `CC BY 4.0`；含 Lee_2026_BritJPsy×3 新入库行；2026-09-25 −1 = Pan_2025_unpub 确认为 CC BY 4.0）：Amodeo×2、Atzeni×1、Bukowski×7、Golubickis×2、Kolvoort×1、Lee_2026×3、Liu×1、Orellana-2020×3、Orellana-2023_QJEP×2、Sui_2014_APP×4、Sui_2014_unpub×1、Sui_2015×1、Svensson×3、Vicovaro×2、Wozniak_2020×3、Zhang_2024×2、Zhang_2026×2
- **City 空白 4 行**：Sui_2014_unpub×1、Sui_2015×1、Dalmaso×2（跨日本/意大利两国、REF 全文未点名城市 → 三态「不确定」；2026-09-25 由 `NA` 改正）
- **City `NA`（Online 研究不适用）13 行**：Kirk×2、Perrykkad×1、Lee_2026×3、Pan×1、Golubickis×2、Lee_2023×2、Liu_2023×1、Svensson_2023×1；其中 8 行为 2026-09-25 由非规范拼写 `N/A` 统一（线上依据 = 各 REF 全文明述 Prolific / SONA / Testable / Inquisit），同日 4 个 paper JSON 的 `City` 与 Golubickis 两个 exp JSON 的 `Location` 亦由 `N/A` 改为 SKILL 规定的 JSON 记号 `/`
- Stim_language 空 0 行（Zhao_2026×4 于 2026-10-13 据作者程序与原始日志填 `Chinese`；Hu_YQ_2026_ChinaSciData 的 4 行已于 2026-09-25 填 `Chinese`）；Country 空 0；Journal 空 0（Journal `NA` 10 行 = preprint/unpublished 无期刊，not applicable）


### 其他暂缓项

稿件 Table1 暂缓清单（table1_problems.txt 111 行 + Table1_Issues_Solvability.md 36 项——2026-10-14 按当前数据重核，已定案条目 71 项删除，稿件版本更新时启用）；Kirk_2025_BritJPsy.json 嵌套 schema 例外（内部键 KIRK_2025_BJP 保留）；Hu_2023_psyarxiv（PsyArXiv 预印本）与 Hu_YQ_2026_ChinaSciData（ChinaSciData）为两个独立条目，确认分别保留；历史管线 Clean_Data.Rmd 内仍引用旧文件夹名（纯历史记录，未改）。

### 条件触发的工作（跨类别）

横切约束：元数据改动 → `validate_json_metadata.R` EXIT=0；数据改动 → 加跑 `validate_clean_csv.R` 0 ERROR；Dataset_inf.csv 字节保真（改前往返测试、改后 diff 仅目标单元格）；同一文件多处修改合并一次写入；与已核实事实冲突的判断暂停问人，不自行覆盖。

## 4. 关键决策（22 条；规则正文唯一归属 SKILL.md）

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
20. **主索引维持 37 列**（2026-09-25 确认）：`Study`/`Paper_ID`/`Paper` 三列已废弃、**不再恢复**；列集以 SKILL §主索引「列说明（37 列）」为准，历史文档的「40 列」口径作废。

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
17. **稿件 v16 已废弃**：Table 1 以 `3_Reports/Generate_Table1_v2.R` 输出为准（2026-10 定案；旧 qmd 已失效，历史报告不改）；与稿件自动比对仅在稿件版本更新时手动启用。
18. **Status=1 判定标准**：**最关键标准 = 库内标准文件形成逻辑上完全一致、清晰可追溯的结构**（各层级互相印证、缺口已解释）；与原论文表述是否一致是次要指标——不一致不阻塞 Status=1，记录于 Verifying_original_results_issues.md（Issue 编号）+ exp JSON detail/CSV Note。
19. **Task/extraIV 命名规范**：`Task` 列区分联结任务类型（默认 `self-matching`；纯情绪面孔/金钱/伪词等用受控值）；任务内额外操纵自变量统一命名 `extraIV1`/`extraIV2`（语义入 Codebook+exp JSON detail）；列顺序统一模板（Subject→[Group]→[Session]→Task→[Phase]→[Condition]→Block→Trial→[Practice]→Matching→Shape→[ShapeLoc]→[Shape_Subtype]→Shape-Identity×3→Label→Label-Identity×3→[extraIV1/2]→[CorrResponse]→[Response]→RT_ms→RT_sec→ACC→研究特有尾部）。

### G. 文件组织
21. **大文件分片（> 50 MB）**：单一 `*_Clean.csv` **或 `*_raw.csv`** > 50 MB 时按**被试边界**拆为 `<Folder_Name>_Exp<N>_Clean_part1/2.csv`… / `<Folder_Name>_Exp<N>_raw_part1/2.csv`…（每片 ≤ 50 MB）；**仍属 1 个数据集**——不新增 Exp/主索引行，共用 1 份 exp JSON（Clean 另共用 1 份 Codebook；raw 无 Codebook、不参与校验），两级校验按各片合计口径并新增表头一致性检查（正文见 SKILL.md §文件与文件夹规范「大文件拆分」；工具 `2_Code/split_clean_csv.py`，2026-10 起同时接受 `*_raw.csv`）。
22. **Sun_2026_DataExp 发表状态（2026-10 定案）**：`PubType = Journal`、`Journal = Data Express`（论文在 revision 中）；**`DOI` 暂空、待正式发表后补填**——此项已定，后续不再作为待决策/待办问题反复提出。
23. **术语与受控值收口（2026-10-02 定案）**：① 主术语 = `self-matching task`（`shape–label matching` / `perceptual matching` 仅作别名注明），跨领域工作行话一律不用（定义与对照表见 SKILL §领域术语基准）；② `Setting`/`Modality`/`Stimulus_order` 三字段已全库受控化，由结构级校验脚本按 WARN 把关；③ ACC 全库收口为 `1`/`0`/`NA`/`-2`/`-3`/`-4`，**无反应一律字面量 `NA`**（不写空字段），内容级校验脚本按原文本判空；④ `Hu_YQ_2026_ChinaSciData` 的受控值/编码偏差已于 2026-10-12 全部修正（受控词表 KNOWN 豁免删除；Exp2 的 `Matching = filler` 与身份列非身份取值改为登记例外）。
24. **`subj_info` 的 `Gender` 全库统一 `Female`/`Male`（2026-10-08 定案）**：`F`/`M`/`f`/`m`/小写全称一律展开为 `Female`/`Male`；作者原始歧义值（`fm`）与非二元类别（`Other`、`A-different-gender`）原样保留；人口学缺失写 `/`（规则正文见 SKILL §数据标准化「`*_subj_info.csv` 列值口径」）。本轮同步：Zhang_2026_JNeurosci、Smith_2024_Cortex、Zhang_2023_NeuroImage、Sui_2015_unpub、Orellana-Corrales_2023_QJEP 及其清洗脚本。
25. **Zhao_2026_PsychonBullRev 按作者原始日志全量重建（2026-10-13 定案）**：输入区收齐作者原始 PsychoPy 程序与逐被试日志后，标准文件**不以作者过滤后的 OSF 分析文件为数据源**，改按原始日志重建（规则正文见 SKILL §数据标准化「作者共享分析文件（已过滤）与原始逐被试导出并存时以原始导出为准」）：保留全部被试（含作者因低于机遇水平排除的 Exp1 3 人 / Exp2 2 人 → `Sample_Size` 48/49、`Valid_Subj` 45/47、`Drop_Subj` 3/2）与全部试次（含无反应与 RT<200 ms），练习试次以 `Phase = practice` + `Block = NA` 保留；补 `Shape`（形状文件名）、`Label`（中文标签词）、`Block`/`Trial`、`CorrResponse`/`Response`（物理键 z/m）与研究特有列 `Counterbalance`；OSF 分析文件移入输入区作核对基准，重建产物应用作者过滤口径后**逐行复现**该文件（15,659 / 16,528 / 15,376 行）。CSV 同步：`Environmental_Info = PsychoPy 2022.2.4`、`Stim_language = Chinese`、`License = CC BY 4.0`（OSF 仓库已公开）、Status=1。

## 5. 当前库内现状汇总（2026-10-12 实测）

- **主索引**：Dataset_inf.csv **114 行 / 51 unique Folder_Name**（实测 37 列）；磁盘 **52 个研究文件夹** = 51 curated + Scheller_2026_elife（仅输入区，无 CSV 行）
- **Status**：`1` **114 行**；空白 **0 行**（Zhao_2026_PsychonBullRev×4 已于 2026-10-13 按原始日志重建并完成确认置 1，见 §3 类别三 Issue 9）
- **Codebook**：**93 个**（= 逻辑数据集数；全库统一 canonical `Codebook_*_Clean.xlsx` 命名）
- **JSON**：**144 个**（51 paper 级〔50 平铺 Paper_name + 1 Kirk_2025_BritJPsy 嵌套 Paper_ID〕+ 93 实验级）
- **Clean 文件**：**97 个物理文件 / 93 个逻辑数据集**（含 2 个已分片数据集：`Sun_2026_DataExp_Exp1`〔4 片〕、`Hu_YQ_2026_ChinaSciData_Exp1`〔2 片〕，逐字节可还原；规则见 SKILL.md §文件与文件夹规范「大文件拆分」）
- **raw 文件**：**99 个物理文件 / 95 个逻辑数据集**；`Sun_2026_DataExp_Exp1` 4 片；`Hu_YQ_2026_ChinaSciData_Exp1` raw 73.2 MB（含由 E-Prime 日志恢复的 `Stimulus`/`TrialListS.Sample`/`TrialListE.Sample`/`TrialList.Sample` 四列）分 2 片
- **校验基线**（2026-10-12 实测）：
  - 结构级：`validate_json_metadata.R` EXIT=0（**144 JSON / 52 文件夹** ↔ CSV 交叉一致；known_pending 0 个；known_unlisted 1 个 = Scheller_2026_elife；分片与主文件按同一数据集只检查一次）；受控词表检查 **WARN 0**、**KNOWN 豁免 0**
  - 内容级：`validate_clean_csv.R` **0 ERROR / 28 WARN**（files=97 datasets=93；分片按各片合计计被试数并检查 E4 表头一致性）。计数 28 = W1 缺标准列 27（16 个 Clean 缺 `Shape`/`Label`，见 §6）+ W5 1（`Zhang_2023_NeuroImage_Exp1`）；另打印 **44 条**不计数的 W2 口径差异（Lee_2026×3、Hu_YQ_2026_ChinaSciData×4、Zhao_2026_PsychonBullRev Exp1 48 vs Valid 45 / Exp2 49 vs 47 / Exp3 44 vs 组内 22、Sun_2026_DataExp 589 vs 503、Wu_2026_Chinaxiv_Exp1 141 vs 70/71 等）。**ACC 值域全库已收口**：实测仅 `1`/`0`/`NA`/`-2`/`-4`，域外值 0、空字段 0。登记例外（`known`）：Constable_2020、Zhang_2023、Perrykkad_2022、Wu_2026×2、**Hu_YQ_2026_ChinaSciData_Exp2（`Matching = filler`）**
  - Table 1：**已重跑（2026-10-13）**——`Rscript 3_Reports/Generate_Table1_v2.R` 输出 `Output/Table1_v2.csv` **114 行** + `Table1_v2_summary_stats.csv`（51 文件夹 / 92 unique study-exp / 被试合计 5732）；Zhao_2026_PsychonBullRev 四行已随重建更新（N 48/49/22/22、Language `Chinese`、License `CC BY 4.0`、Exp_Implement `Lab Experiment`；Exp2 的 M/F 18/29 为 47 名被分析被试，2 名被排除者无人口学，见 §3 类别三 Issue 9 与主索引 Note）
  - git：分支 `main`（工作区状态以 git status 为准）

## 6. 散落未解决问题（自历史记录提取，不属于上述四类表）
- **Dalmaso E2 Label 列 = missing**（2026-09-01 记录）：意大利语原文无一手资料，待 OSF 原始数据补充后填实（现状核实：14400 行全为 `missing` 占位）。
- **16 个 Clean 文件缺 `Shape`/`Label` 可读值列**（2026-09-25 核实；非回归、无删列历史）：93 个 in-scope 逻辑数据集中 16 个（10 研究）——11 个两个可读值列皆无、自创建起仅存 Identity 三级（`Qian_2020_QJEP` E1/E2、`Schaefer_2019_JCogPsych` E2/E3、`Sui_2014_APP` E1–E4、`Sui_2023_ConsciousCog`、`Svensson_2023_QJEP`、`Orellana-Corrales_2021_APP` E2）；4 个缺 `Label`（`Liang_2022_HumBrainMap` E1、`Navon_2021_psyarxiv` E2、`Vicovaro_2022_JEPHPP` E1/E2）；1 个缺 `Shape`（`Smith_2024_Cortex` E1）。逐提交表头回溯（`git log --follow`）：Label 在 16 个中的 15 个从未出现过（唯 Smith 自始即有），Shape 在 16 个中的 12 个从未出现过（Liang/Navon 自始即有，`Vicovaro_2022_JEPHPP` E1/E2 于 2025-10-20 `6254f09` 补入）；各文件创建时点跨 2024-04-09 ~ 2025-10-31（原始入库批次，早于可读化标准）。2026-08-30 可读化标准（README）后的三波列标准化（`af3be8e`/`d0fbaa5`/`e588bcc`）只改列名与列序、未补录这两列；`validate_clean_csv.R` W1 报 27 条（Label 15 + Shape 12）。处置待定：需逐研究刺激-身份绑定证据（Vicovaro 式恢复）或按 SKILL「无法确认原刺激时填 `missing`」落列。
- **清洗脚本与库内 Clean 的列结构曾系统性不一致（2026-10-08 核查并同步）**：两次列标准化提交（`d0fbaa5`、`e588bcc`——后者 commit message 自陈 "many errors might be introduced"）只改数据文件、未同步清洗脚本。核查方法 = 逐个重跑 28 个 `*_clean.R` 并与 committed 文件逐单元格比对（运行前后快照还原，脚本本身不被改动）。结果：**16 个研究**的脚本需修（缺 `Task`/`extraIV1`/`CorrResponse`，`Blocktype`/`Expectancy`/`Symmetry`/`Emotion` 未改标准名，或列序不符），已全部同步并加 `stopifnot(identical(names(...), c(...)))` 一致性检查，重跑验证**表头与逐格取值零差异**（仅引号/行尾风格差异；committed 数据文件本身不改）；其余脚本原本已一致（`Bukowski_2021_ActaPsych`、`Hu_2020_CollabraPsy`、`Hu_2023_psyarxiv`、`Lee_2026_BritJPsy`、`Pan_2025_unpub`、`Sui_2015_unpub`（`_merge.R`）、`Wang_2016_JEPHPP`、`Wozniak_2018_PLOS`、`Wu_2026_Chinaxiv`、`Zhao_2026_PsychonBullRev`）。未核验：`Sun_2026_DataExp`（体量大）、`Hu_YQ_2026_ChinaSciData`（**输入区缺失〔H1〕→ 库内不能重跑脚本核验**）。
- **全库 Clean 列序统一为模板 v2（2026-10-08，用户定案）**：45 个物理 `*_Clean.csv`（30 个研究）由旧列序（典型为 `Task` 落在 `Label` 之后、`Matching` 落在 `Shape` 之后）重排为 SKILL 模板 v2；同批同步 **45 份 Codebook 行序**（取值不变，仅 HTML 实体 `&lt;`/`&gt;` 规范化为 `<`/`>`）与 **15 个研究的清洗脚本**（含新增/更新 `stopifnot(identical(names(...), c(...)))` 检查）。重排为逐格搬列：对 HEAD 逐文件校验「列集合不变 + 每行取值不变」，0 单元格差异；脚本重跑与工作区文件逐值比对 0 差异。5 个脚本带「产物已存在即中止」防覆盖检查（`Hobbs_2023_PsychMed`、`Orellana-Corrales_2020_ExpPsych`、`Orellana-Corrales_2023_QJEP`、`Vicovaro_2024_PeerJ`、`Zhang_2024_PsychJ`），重跑核验须先把既有产物移至临时目录。
- **`CorrResponse` 列错位（2026-10-08 发现并修正，用户确认）**：`e588bcc` 批量加列时按 raw 行序整列粘贴、未与试次对齐——`Amodeo_2024_CABN` Exp1（可比 23,244 行中 11,658 行，50.2%）与 `Navon_2021_psyarxiv` Exp1–4（44–49%）。判定口径 = 正确反应键下 ACC 应等于 `Response == CorrResponse`。修正：Navon 在 `arrange(Subject)` **之前**把 raw `Target.CRESP` 绑定到行（脚本 + 4 个 CSV，每文件 4,666–4,854 格）；Amodeo 按「被试内 raw 行序 ↔ Clean (Block, Trial) 顺序」逐行对应（该对应先用 Response/ACC/RT 在 24,120/24,120 行上验证），修正 12,064 格（该研究无 clean.R，修正仅落于 CSV）。修正后两研究违例均为 0；库内其余含该列文件 0 违例（`Orellana-Corrales_2020_ExpPsych` Exp1 的 59 行为 `k`/`K` 大小写差异，非错位）。
- **`Orellana-Corrales_2021_APP` 清洗脚本（2026-10-08 补全）**：`_clean.R` 原写作 `STUDY_DIR/<Folder_Name>/…`（多一层同名目录，实际不存在），脚本在 `dir.exists()` 处即中止 → 已改为实际输入区 `Orellana-Corrales_2021_APP_raw/…`；该脚本原只产出 `*_raw.csv`，**Clean 无脚本可复现**（历史 `Clean_Data.Rmd` 产物）→ 已补入 Clean 生成段（Exp1 4,352 行 / Exp2 4,224 行 = 被试 1 数据不完整、仅存 raw），重跑与库内 Clean 逐值零差异，provenance 缺口闭合。**遗留待决**：Exp1 的 `Shape_*_Identity` 沿用历史口径 = 按形状文件名固定（Kreis.png→Fremder/Stranger、Dreieck.png→Ich/Self），34 名被试中 **17 名**与「由 raw Matching 推出的学习绑定」相反（反平衡被试被写死）→ 现值已按库内 Clean 复现，是否按 raw 修正待用户决定。 **provenance（2026-10-08 追加）**：绑定改为**直读作者 E-Prime 学习阶段帧**（`targLocation` + 同侧 shape），并以「由 raw Matching 反推」作逐行交叉检查（`stopifnot`，实测 68/68 被试×形状一致）；取值不变，Exp1 exp JSON `detail` 已记录该来源。
- **全库一致性审计（2026-10-08，用户要求「看看是否还有其他问题」）**：对 93 个逻辑数据集做内部一致性核查——① `Matching` vs `Shape_Std == Label_Std`；② `ACC` vs `Response == CorrResponse`；③ Identity 三级映射是否为函数；④ Std 值域；⑤ (Subject,Block,Trial) 键唯一性；⑥ `RT_ms`/`RT_sec` 换算。**结果**：
  - **已确认并修正 `Xu_2022_CurrPsych` Exp1**：Clean 的 `Matching` 由「作者正确键 == 固定 'j'」推得，而该研究的 yes 键逐被试反平衡（raw `Yes` 列 j/f）→ **105 名被试中 52 名的 21,048 行 Matching 全部反向**；依据 raw「`Correctanswer == Yes` ⟺ `Shape == Label`（42,444/42,444 行）」修正，修后矛盾 0。
- **`Hobbs_2023_PsychMed` 标签/身份列已按 SKILL 修正（2026-10-08，用户确认）**：① **Label 侧改按「实际呈现的刺激」编码**（此前由形状所属条件派生，导致同一行 `Label` 与 `Label_Origin_Identity` 指向不同刺激）——emotion 任务用呈现的情绪（happy/sad/neutral，Std 仍 NonPerson）、reward 任务用呈现金额（£9/£3/£1，Origin 保留 raw 的 9/3/1），各影响约 8,640 行；② **self 任务**：呈现的是被试提供的名字，作者在匿名化时删除了该列（论文 Methods + 作者 `Associative_cleaning.R` 原文）→ 按新约定 `Label`/`Label_Origin_Identity`/`Label_English_Identity` = 占位值 `subj_name`（规则见 SKILL §数据标准化），`Label_Standardized_Identity` 在 Matching 试次 = 该形状身份、非匹配试次 = `missing`（17,280 行）；③ **`Shape_Origin/English_Identity`** 改填形状承载的身份（raw `Shape` 列原文 Self/Friend/Stranger、Happy/Sad/Neutral、HighReward/MediumReward/LowReward；English 与 Label 侧同词表），不再重复 `Shape` 列的几何名（51,840 行），Std 值不变。脚本/Codebook/raw 同步更新，重跑核验值级 0 差异；脚本新增两条一致性检查（非 self 任务 `Matching ⟺ Shape_English == Label_English`；self 匹配行身份一致、非匹配行 `missing`）。
  - **待逐研究核验（同型矛盾 10–50%，也可能是 Std 词表合并等设计因素）**：Liu_2023（50%）、Wang_2016 Exp1/2（58%/61%）、Hu_2023_psyarxiv Exp3b（50%）、Kolvoort_2020（45%）、Sun_2026（33%）、Lee_2023 Exp1（25%）、Wozniak_2020（22%）、Hu_2020（17%）、Constable_2019（10–17%）、Sui_2014_unpub（17%）。已核实的一例：`Zhao_2026_PsychonBullRev` Exp1（16.7%，2026-10-13 重建后实测）确系词表合并所致——true self 与 general self 同归 Std `Self`，改用 English 层比较则 0 违例（该说明已写入其 Codebook 与 exp JSON detail）。
  - 通过项：`ACC` vs `Response==CorrResponse` 全库 0 违例；Std 值域 0 越界；键唯一性、`RT_ms`/`RT_sec` 换算 0 异常；`Task` 受控值 0 例外（2026-10-12 统一：`matching`/`facialExpression-matching`/`monetaryValue-matching` 并入 `shape-matching`，见 §5）。
- **`Sui_2015_unpub` 脚本归位（2026-10-08，用户定案）**：合并逻辑并入标准脚本名 `Sui_2015_unpub_clean.R`（现行脚本，重跑验证 raw/Clean/subj_info 逐值零差异）；`Sui_2015_unpub_merge.R` 保留为 2026-09 合并步骤的历史记录（头部注明，内容不变）；原双 Exp 版本脚本内容不再保留（见 git 历史）。
- **`Wozniak_2018_PLOS` 补 `Task` 列（2026-10-08）**：Exp1/Exp2 的 Clean 自创建起缺全库标准列 `Task`（其 Codebook 早已记录该列，取值 `self-matching`）→ 已补列（常量 `self-matching`，位置符合模板 v2）、脚本同步（含 `stopifnot` 列序检查）、Exp1 Codebook 补缺失的 `Response` 行（取值 `m`/`z`）。
- **例外清单豁免**：known_pending 0 + known_unlisted 1（Scheller_2026_elife）。
- **`Hu_YQ_2026_ChinaSciData` 未解决项（清单见 `3_Reports/Hu_YQ_2026_Issues.md`）**：**H1 输入区原始数据缺失** `Hu_YQ_2026_ChinaSciData_Raw/`（清洗脚本不能在库内重跑、标准文件无法回溯复核）→ 合作者提供后重跑脚本复核并做多源交叉核验；H2 开封数据公开版本；H3 任务↔文件映射确认；H5/H6 开封练习与 block 口径；H8/H9 北京练习试次数与逐被试试次差异；H14③ 情绪形状任务的 `Stim_Type`；N1 开封性别（程序 `Gender` 列存的是编号首位；主索引记 `missing`、subj_info `Gender = NA`，待人口学表）；N2 6009/6031 年龄（raw Age 跨 session 不一致）；N3 开封块/试次编号；N5 开封 18 个缺失阶段与 4 处异常导出。
- **`Male`/`Female` 缺失口径（2026-10-12 定案，写入 SKILL §主索引）**：原研究有该信息但库内未获得 → `missing`；仅有总体值无法拆到本行 → 留空；确无性别维度 → `NA`。据此 `Hu_YQ_2026_ChinaSciData` 开封两行的 `Male`/`Female` 记为 `missing`（程序把编号首位写进了性别列，交付数据无性别）。
- **全库 `*_Standardized_Identity` 取值域摸底与处置（2026-10-12）**：6 类规范值外的取值已按用户决定登记进 SKILL（货币 `£1`/`£3`/`£9`、`￥1`/`￥16`；情绪 `happy`/`neutral`（仅 Hu_YQ）；`ingroup`（Constable_2019 E4）；`Filler`（仅 Hu_YQ Exp2）；占位/缺失 `NA`、`subj_name`、`missing` 三态语义）。审计中作两处修正（均以论文为依据）：
  - `Hobbs_2023_PsychMed_Exp1` self 任务非匹配行（8,640 行）：`missing` → **`subj_name`**（论文 Methods：被试提供自己/朋友/陌生人的 first name，呈现刺激必为其中之一、但匿名化后无法确定是哪一位）——脚本、Codebook、exp JSON 同步；SKILL 的 `subj_name` 规则同步改写。
  - `Smith_2024_Cortex_Exp1` 的 `Label = You` 行（5,760 行）：`Label_English_Identity`/`Label_Standardized_Identity` 原为 `NA` → **`You`/`Self`**（论文 Methods：标签为 You/Friend/Stranger 三个词，referents = self/friend/stranger）——Codebook 枚举与 exp JSON 同步。
  2026-10-13 起全库 `*_Identity` 列**已无 `missing` 取值**：原唯一用例 `Zhao_2026_PsychonBullRev` Exp1–3 的非匹配行（23,686 行）已随作者原始 PsychoPy 逐被试日志重建、填实为真实标签词（SKILL 的取值登记同步更新）。
- **分析层待重跑（2026-10-12 记录；2026-10-13 部分完成）**：`analysis_config.R` 已升 v4 并适配 Hu_YQ 的两实验结构；**Table 1 已于 2026-10-13 重跑**（见 §5），受影响脚本 `Figure3_Ridges_Pairwise`、`Figure_Bootstrap_Mismatch` 仍未执行。

## 7. 历史归档说明

精简时删除的内容（均可从 git 找回）：

| 原章节 | 内容 | 归档位置 |
|---|---|---|
| §5 效率教训与弃用方案 | 一次 unpub 会话教训、阶段 2 犯错教训、弃用方案 3 条 | 规则已沉淀于 AGENTS.md §干活效率规则 / §防坑 + SKILL.md；弃用方案对应 git 历史 commit |
| §6 REF/ 全文收录统计 | 44 研究覆盖明细、模板适配记录、`*_DS.md` 说明、管线教训 | REF/README_html2md.md（正文归属）+ git 历史 |
| §7 完成进度 | 全量历史会话记录表（2026-08 ~ 2026-09-02，约 30 行，含各研究入库详情、多源交叉核验、治理动作、全局校验基线） | **git 历史**：备份 commit `9e90b8e` 之前版本为精简前全文；各动作对应 commit message 可定位 |
| `3_Reports/Stage3_1_CrossCheck_archived.md`（整文件，2026-10-14 删除） | 阶段 3.1 四方交叉复核 P1–P22 处置记录（全部已解决；相关表述已自核心文件移除） | **git 历史**：`git log -- 3_Reports/Stage3_1_CrossCheck_archived.md` |

查询方式：`git log --oneline -- PROJ_STATE.md` 或按研究/动作关键词 `git log --grep="<关键词>"`。全局校验基线以 §5 为准，不随历史删除。
