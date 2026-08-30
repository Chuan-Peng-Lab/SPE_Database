# PROJ_STATE.md — SPE Database 项目状态（2026-08 更新）

## 当前目标

SPE（自我优先效应）数据库的整理与元数据治理：以「可读、自解释」的文件夹名（<Author>_<Year>_<期刊缩写>）作为全项目论文/预印本的关键 ID，以 1_Data/Dataset_inf.csv 为主索引，使 35 个已入库研究、8 个待入库条目的命名、年份、DOI、期刊信息与权威记录（Crossref/OSF/论文 JSON）对齐，并为稿件 Table 1 的再生成与比对提供可靠数据源。
当前最重要推进线路见「下一步任务」分层清单（L1 精细化 → L2 数据判定 → L3 入库 → 清理收口）。

## 已完成（均已验证）

### 项目基础（关键 ID 体系与主索引）

- **关键 ID 迁移**：Folder_Name 成为全项目关键 ID（文件系统、CSV、Table 1 均以其为键）；Paper_ID/Paper 列标记 deprecated（仅作与旧稿件的过渡映射，保留一个版本周期）。
- **主表切换**：1_Data/Dataset_inf.csv 为唯一主索引（40 列、74 行、43 个唯一 Folder_Name、UTF-8 带 BOM）；2026-08 新增 `subj_Group` 列（被试分组）；旧 Dataset_inf.xlsx（旧 schema、无 Folder_Name 列）确认无 CSV 之外的数据，待合作者确认后删除；3_Reports/Output/data/ 下的旧快照（Dataset_inf.csv、Dataset_info.xlsx）已删除。
- **文件夹可读化改名**：26 个文件夹改名（EPHPP→JEPHPP、ERPH→IJERPH、CP→JCogPsych/CurrPsych、AP→ActaPsych、CC→ConsciousCog、BMC→BMCPsych、PR→PsychRes、NI→NeuroImage、HBM→HumBrainMap、BJP→BritJPsy、PM→PsychMed、CE→CogEmo、Psy→Psychophysiol、CP→CollabraPsy/CogRes、无后缀→psyarxiv/unpub/DataExp），含各文件夹内部全部 JSON/CSV/Codebook 前缀同步（per-participant 原始导出未动）。
- **DOI 填充**：64/73 行有论文 DOI（40 行取自 paper JSON，22 行经 Crossref 按作者+年份+期刊+题名核对）；Repo_Link 仅存数据链接，DOI 一律为论文 DOI。
- **年份对齐**：以 Crossref 正式印刷年为准（在线年仅用于纯在线期刊），修正 3 个文件夹年份（Constable 2021、McIvor 2021、Xu 2022）、1 处 CSV 年份（Wozniak 2022）；两篇预印本（Hu_2023_psyarxiv、Navon_2021_psyarxiv）经人工确认未发表，以最新版年份（2023/2021）为准。
- **Table 1 管线**：Generate_Table1.qmd 输出 ID 列改为 Folder_Name；与稿件 v16 的逐行比对改用 CSV 行号键 + Paper_ID→行号 过渡映射，问题清单以 Folder_Name|ExpN 显示。
- **四文档分工建立**：README.md（人类读者：数据使用指引）、AGENTS.md（agent 效率约定：省 token、防无效搜索——Crossref/OSF 用法、会话收尾强制更新 PROJ_STATE.md）、SKILL.md（DOI/年份核验、清洗工具指引、Dataset_inf.csv 40 列说明、validator 盲区、多语言 Identity 对照）、PROJ_STATE.md（会话状态快照）。AGENTS.md 已按四标准（省时/省token/准确/一致）审查修正：数字口径改为实测（43/74）、过滤措辞统一、<Suffix> 命名统一、已知问题补全。

### 阶段 1–3 已完成（2026-08-27 / 2026-08）

- 阶段 1（元数据补齐 + subj_info 全覆盖 + Table 1 清单刷新）、阶段 2（CSV 文献/流程字段补全 + 全文核查）、阶段 3（N 口径核实 + Vicovaro Exp2 重建）完成详情已合并入「下一步任务」对应划线阶段条目，此处不重复。

### 2026-08 — 自动化地基、试点与清洗脚本统一

- **自动化地基（SKILL.md）**：新增 Raw input zone（输入区规范：`1_Data/<Study>/<Study>_Raw/` 只读、不参与校验）、Metadata draft workflow（Crossref 预填 paper JSON、数据推导 exp JSON 字段、来源分级 [D]/[C]/[P]/[H]）、内容级校验器 `2_Code/validate_clean_csv.R`（E1 缺 Subject / E2 Identity 三级不完整 / E3 nSubj vs subj_info；W1-W4 提示；known 白名单 16 条历史遗留；支持 --data-dir）、Human decision points（10 条人工决策清单）、End-to-end workflow（自动化入库 10 步）。
- **自动化试点（三研究）**：从 Clean_Data.Rmd 提取独立清洗脚本并全量验证与现有产物一致——Sui_2014_unpub（17280 行逐值全等）、Navon_2021_psyarxiv（四实验 MD5 全同）、Vicovaro_2022_JEPHPP（295,680 单元格 0 差异）；7 个新产物过 validate_clean_csv.R 全部 0 ERROR；元数据草稿 Crossref 预填与现有 paper JSON 一致。
- **清洗脚本落盘与统一**：4 个独立清洗脚本正式落盘 1_Data/（Vicovaro / Navon / Sui_2014_unpub / Sui_2015_unpub 各 `<Study>_clean.R`），统一架构（引导块定位脚本目录 → source 1_Data/utils.R → 清洗逻辑 → 输出守卫）；utils.R 由 2_Code/ 迁至 1_Data/（与脚本同库、不跨文件夹引用，已入 SKILL.md §清洗工具）。重构后全量重跑：Vicovaro/Navon/Sui_2014 输出与正式产物逐值一致；Sui_2015 仅 RT 末位显示差异（~1e-15 相对差，按数值等价约定视为一致）。

### 2026-08 — 其他数据修复与决策

- **补 CSV 空 Exp**：按 Paper_ID 的 E 后缀回填 10 行空 Exp（Lee Pu5E1/E2→1/2、Orellana-Corrales_2021_APP Pu9E1/E2→1/2、Schaefer P54E2/E3→2/3、Svensson_2023_QJEP Pu10E1→1、Sun_2026_DataExp Pu6E1→1、Hu_2023_SDB Pt5E1→1、Pan_2025_unpub Pu8E1→1）；与文件夹/Table 1 对应值一致；Scheller_2026_elife 无 Paper_ID 无法推导，保留空白（见已知问题）。字节保真，validator EXIT=0。
- **C 类命名修复**：Wang_2016_JEPHPP 与 Smith_2024_Cortex 的 trial 级原始文件由 `*_Exp1_Raw.csv`（大写 R）规范化为 `*_Exp1_raw.csv`（git mv 保留历史）；Clean_Data.Rmd 内旧引用为历史死引用，按惯例未改。
- **Martinez-Perez CSV 修正（经合作者确认）**：该研究仅纳入 Exp2（Exp1 不含 self-matching task 故排除）；CSV 行 Exp 1→2（与 Paper_ID Pt27E2、文件夹 Exp2 文件一致），Note 列记录 "Exp1 excluded: no self-matching task; this row = Exp2"。
- **.gitignore 更新**：12 个研究文件夹模式更新为当前命名并加前导 `/` 锚定根目录（消除对 1_Data/ 新文件的误忽略）；删除 2 条失效路径。
- **Sui_2015_unpub 清洗脚本化 + 数据修复**：① `<Study>_clean.R` 落盘（修正失效路径、CRLF 与库内惯例一致）；② Exp2 排除测试被试 subject 0，Clean 9600→9360 行（Exp1 不变）；③ subj_info 删除 subject 0 行、subject 3 人口学更正（0/fm→20/f），21→20 行；④ CSV Exp2 Sample_Size/Valid_Subj 21→20（字节保真）；⑤ codebook 补 ACC 3/4 说明；⑥ Clean_Data.Rmd 两段同步修正（路径+subject 0 过滤+标题）。validator EXIT=0。
- **12 个待收录条目信息登记**：稿件 v16 Table 1 中 12 个无数据文件夹条目（Bukowski×2、Golubickis×2、Hobbs、Mcivor、Orellana-Corrales_2023_QJEP×3、Svensson_2022×3）经核对全部已存在于 Dataset_inf.csv（Paper_ID 一一对应）；将稿件 Exp_Implement 登记入 Note 列（`Manu_Table1: Lab/Online Experiment (pending)`，12 行）；N/Trials 冲突均以 CSV 现值为准（稿件多处复制错误）；Crossref 核实 6 个 pending DOI 年份全部与 CSV 一致。字节保真，validator EXIT=0。
- **决策：稿件 v16 废弃**：`SPE_database_manu_v16.docx` 不再作为 Table 1 比对基准（核心信息已登记 CSV Note）；`Generate_Table1.qmd` 稿件比对默认关闭（YAML `params: compare_manu: false`），稿件版本更新时以 `--param compare_manu:true` 启用；历史问题清单（table1_problems.txt 111 行）与可解性判定冻结，仅作未来稿件更新时的修正清单。

### 2026-08 — 阶段 3.1 无问题条目独立复核（21 研究 / 37 行）

- **复核完成**：21 研究（样板 3 + 剩余 18）四方交叉（CSV ↔ paper/exp JSON ↔ Clean/Codebook ↔ REF 全文）全部完成；**18 研究全部发现差异，无一完全一致**——证实早期人工填写错误普遍。差异明细见 `3_Reports/Stage3_1_CrossCheck.md`（现为未解决问题编号清单 P1–P22）。
- **新增工具**：`2_Code/read_dataset_inf.py`（Dataset_inf.csv 统一读取入口，封装 BOM/引号/列名定位）+ `2_Code/stage31_crosscheck.py`（四方机械比对）+ `1_Data/utils.R` 加 `read_dataset_inf()` R 函数；SKILL.md 新增「Dataset_inf.csv 标准读取模板」。
- **Dataset_inf.csv 新增 `subj_Group` 列**（40 列）：组间设计填原文组名（分号分隔）、无组间填 `All`；初填 8 个组间研究后复核又修正 3 处漏判（Constable_2020 Switch、Xu_2022 4 组、Vicovaro E2）——Design 列不是组间判定的充分依据（教训入 SKILL.md）。
- **可自动改项 4 批次更新（依据 = 论文全文 + 原始数据）**：
  - 批次 1：CSV 30 单元格 + JSON 40 处（paper DOI 去前缀 6、采集地、subj_Group 修正 3、试次字段补全 17、Practice 4、Valid_Subj 1、软件 2、Journal 拼写 2、exp Setting 词表 25）
  - 批次 2（N 口径 = 数据口径）：7 研究 Sample_Size/Valid_Subj 更新为 Clean nSubj、Drop_Subj→0、论文口径记 Note 列（`Paper_N:` 前缀）；pair 研究（Constable_2019 E4、Constable_2020）按用户指示**单独处理**暂不改
  - 批次 3：Liang 删冗余 `Exp1_Clean.csv`（git 跟踪可恢复，备份 /tmp/liang_trash/）；Dalmaso E2 Country→Italy、paper JSON→"Japan, Italy"；Perrykkad→United States（MTurk 在线，用户指示）
  - 批次 4（采集地，CEU 证据）：Constable_2020 City→Budapest；Wozniak_2018 Country→Hungary、City→Budapest（伦理委员会批准机构 = 采集机构，教训入 SKILL.md）
- **文档同步**：AGENTS.md 加「CSV 字节保真编辑纪律」（QUOTE_MINIMAL 往返/去末尾换行/header.index 定位/三重验证）；SKILL.md 更新 N 口径定义（数据口径优先）、subj_Group 判定、采集地判定规则、读取模板；Stage3_1_CrossCheck.md 重写为未解决清单。
- **验证**：validate_json_metadata EXIT=0（90 JSON）；validate_clean_csv 59 文件 0 ERROR/40 WARN（基线持平）；CSV 字节保真（diff 仅目标单元格）。
- **第二轮（2026-08，用户决策，P15–P20 消解 + P7–P9/P5 标记解决）**：
  - **P15 numTrials 统一 total**：CSV 14 行 numTrials 更新——Constable_2019 E1–E3 96→288（3×96）、E4 80→640（8×80）；Sui_2014 ×4 60→360（6×60）；Vicovaro E1 240→480（2×240）；Qian E1 144→576（4 sessions×144）、E2 100→200；Hu_2020 312→480（匹配 8 条件×60）且 numBlocks 14→2；Lee_2023 ×2 空→96/3/24（PMT 2 runs×48）。原值已是 total 不变：Constable_2020（每人 240）、Constable_2021（384/192，数据 768/384=2×系颜色/文本色/位置平衡，Note 注明）、Wozniak_2018（672）、Vicovaro E2（240）。依据均论文全文（如 Vicovaro L88 "each block 240"、Sui_2014 L48 "six blocks of 60"、Qian L60/L121、Hu_2020 L86 "60 per condition×8"、Constable L74/L181）。
  - **P16 Practice_Trial 口径**：Constable_2019 E4 50→"21 or 41"（50 为学习映射训练段 L179 非练习；匹配练习 21 or 41 视 pair 信心 L181，与 exp JSON 一致）。
  - **P17 多任务口径**：Hu_2020/Liu_2023/Svensson_2023/Lee_2023 的 numTrials/numBlocks 全部核对为**匹配任务**口径（Liu 64、Svensson 120 已对；Lee 数据即 PMT 匹配任务）；其他任务数据已纳入者（无）暂且保留；分类/ANT 数据不在库中。
  - **P18 软件惯例**：未披露 → CSV 留空 + exp JSON '/'（Constable 系列/Sui_2023/Kolvoort/Svensson 已符合）；Lee_2023 ×2 Environmental_Info 空→Testable（论文披露，JSON 已填）。
  - **P19 Online 采集地**：Prolific 研究 Country=UK（Svensson ✓ 已对；Liu_2023 United Kingdom→UK、City "In United Kingdom"→N/A）；Perrykkad MTurk→United States（批次 3）。
  - **P20 License**：论文声明 request 者 License 留空——Amodeo ×2（论文 L156）、Kolvoort（L336）、Liu_2023（论文 OSF 公开 osf.io/4n6j7 但 OSF API license=None）"On request"→空；Liang（CC BY-NC-ND）/Constable_2019（No License）数据页明确声明保留。
  - **P5（Schaefer_2019_JCogPsych E2 Clean 缺列）已解决（2026-08）**：raw 导出无刺激内容列（target/flanker/targetform 全空），仅 Condition(=Bed) 条件码 + MT4.ACC/RT。**Bed 解码**：2 字母码，第 1 字母=label 身份（i/m/b/n=Ich/Mutter/Bekannter/Nichts）、第 2 字母=匹配状态（m/n）——经 psycharchives 聚合 SPSS 验证（列名 RTim/RTin/RTmm/RTmn/RTbm/RTbn/RTnm/RTnn；288 单元 MAE 13.8 ms）。**Clean 重建**：补 Matching + Label 侧 3 级 Identity（9 列：Subject/Condition/Matching/Label_Origin/English/Std/RT_ms/RT_sec/ACC）；Shape 侧不可恢复（每被试 shape-label 分配未记录，论文按 label 归类 nonmatch）。psycharchives（10.23668/psycharchives.2642）：group1=group2（Exp1 重复上传）、group3=Exp3（均与库内一致）、**Exp2 无仓库版本**（库内 raw 唯一来源）。数据特征：V1–V4 版本 Ich 24 匹配/12 不匹配（原始版 18/18），各身份 36 试次/被试。连带更新：Codebook 重写（9 行）、exp JSON detail、Rmd 段同步、CSV 行（Exp2/3 补 numTrials=144/numBlocks=3/Practice_Trial=48 + Self/Close/Others；Exp1 Close 'Mother/Acquaintance'→'Mother' 按 SKILL 惯例——Acquaintance 属 Others 类）。校验：validate_clean_csv 0 ERROR（Exp2 过 E1–E3，缺 Shape/Label 列 2 条 WARN 系不可恢复）；validate_json_metadata EXIT=0。
  - **psycharchives 下载数据存档输入区（2026-08）**：5 个仓库文件（Exp. group 1/2/3_raw data.tsv ×3、聚合 .sav、license.txt）放入 `1_Data/Schaefer_2019_JCogPsych/Schaefer_2019_JCogPsych_Raw/`（输入区规范，不参与校验；group1/3 与库内 Exp1/3 raw 内容一致，group2=group1 重复）。阶段 4 先例：下载的仓库原始数据统一入 `<Study>_Raw/` 存档。
  - **阶段 4 辅助工具固化（2026-08，2_Code/）**：`repo_fetch.py`（OSF/PsychArchives 下载辅助：osf-list/osf-get/pa-search/pa-files/pa-get，先列清单再下载、目标已存在拒绝覆盖）+ `scan_raw.py`（raw 扫描：每被试行数/列值分布/交叉表，大文件 --sample 流式）——均源自 P5 手写模式，用法见脚本 docstring + SKILL.md 指针；实测通过（Schaefer/Sun 62MB 抽样/OSF 4n6j7 递归列文件）。
- **P7–P9（Sui_2023 17974 行、Kolvoort 11051 行、Svensson 7370 行不整除）**：先前 agent 已调查（3 个 exp JSON detail 注明实际行数特征：Sui_2023 656–952/被试 vs 预期 960、Kolvoort 203–380/被试 vs 预期 400、Svensson 45–120/被试 vs 预期 120 仅 18 人满 120；公开数据可能经作者预清洗、不完整 session 按最小预处理规则保留）→ **保持现状，标记已解决**。**P3（Constable E4 Self/Coactor）已解决（2026-08 第三轮）**：输入区 `E4InferentialDATA.csv` 的 `MatchParticipant` 列 = 每 pair 的 match responder（=自己，10 Person1/10 Person2）；统计复现论文 L191（Self 674.3/Coactor 751.4/Stranger 733.6 vs 670/744/728 ✓）；Clean E4 Label/Shape Std 重建（自己→Self、队友→`ingroup`（用户决策）、Team→Self、Stranger/StrangerTeam→Stranger）；Rmd join + Codebook + SKILL（ingroup 自定义值先例）同步；`E4AllDATA.csv` 与 raw MD5 相同不可区分（P2Age/P1Age 为 pair 级年龄）。
  - **验证**：validate_json_metadata EXIT=0；validate_clean_csv 58 文件 0 ERROR/39 WARN（较原 40 WARN 少 1 = 批次 3 Liang 冗余 Clean 删除所致）；CSV 字节保真（diff 34 单元格，列集合 {numTrials, numBlocks, Practice_Trial, Environmental_Info, Country, City, License, Note}）。
  - **第三轮（2026-08，本会话，P1–P22 全部解决）**：A 组 pair 口径（40/92 + Note + E4 Female 14→26 + E1–E3 Note 清理）；P4/组展开（subj_Group 每 group 一行，9 行→21 行，8 研究展开）；P6 Kolvoort 改名；P12 Lee（'Friend'→'Close'、£9/£1 原样）；P21 ACC 方案 A 统一编码；P11/P14（CSV=Std 类简写、group-self 规则、E3/E4 Label 重建、English 四类术语）；P3（E4InferentialDATA MatchParticipant 映射重建 Self/ingroup，统计复现 L191）；P7–P9 记录（exp JSON detail）。分析细节见 `3_Reports/P_Issues_Analysis_Plan.md`（本会话报告）。

### 2026-08-30 — 阶段 4（Orellana-2021 APP raw 追补）+ 阶段 5 首例（Orellana-2023 QJEP 入库）+ 双研究四方核对

- **阶段 4 完成：Orellana-Corrales_2021_APP raw 追补**（用户下载 OSF g7wrc/4cwrv 完整存档入输入区）：
  - 清洗脚本 `Orellana-Corrales_2021_APP_clean.R` 落盘（E-Prime UTF-16LE txt 解析：LogFrame 块、中断被试未闭合块跳过无记录试次）；产出 `Exp1_raw.csv`（4,352 行 = 34×128）与 `Exp2_raw.csv`（4,292 行 = 33×128 + nonwords-01 的 68 行），与现有 Clean **逐值全等**（守卫验证）；nonwords-01 匹配任务中断仅 68 试次（源数据问题：txt 日志自然终止、OSF 无其 edat2；txt 含完整 dot-probe 数据 176 响应行）。
  - **Dataset_inf.csv 收口**（ID 69/70）：Journal=Attention, Perception, & Psychophysics、numTrials=128、Practice_Trial=4、numBlocks=1、Environmental_Info=E-Prime 2.0、Note 记排除名单（Exp1 {5,6,20,23,24,27} / Exp2 {4,33}，SPSS 脚本硬编码）；**Exp2 Stim_Type 修正为 letter string**（原从 Exp1 复制错误）；Exp2 N 口径闭合：34 招募 = 33 Clean（nonwords-01 不完整移除）+ 1，论文分析 N=31 = 33−{4,33}（df=30 吻合）。
  - **subj_info 人口学补全**（原全 "/"）：Exp1 34 名、Exp2 33 名 Age/Gender/Handedness 自 merged.tsv 与 txt 头部提取（25F/9M、23F/10M+01 男 = CSV 11M 自洽）。
- **阶段 5 首例完成：Orellana-Corrales_2023_QJEP 入库**（QJEP 2023, DOI 10.1177/17470218221124928, "Does an experimentally induced self-association elicit affective self-prioritisation?"；OSF v8r2p）：
  - **CSV 原 3 行（ID 26-28）实为 2020 论文错误信息**（dot-probe cuing & IOR、osf.io/3ke4f、E-Prime、Tübingen）——修正为 2 行（Exp=1 × subj_Group=familiar (words) N=71 [M46/F25] / new (shapes) N=65 [M42/F23]；numTrials=140/Practice=4/blocks=1；PsychoPy；Repo=v8r2p；License 空=OSF 无声明；Others=NonPerson；ID 28 删除）；known_pending 白名单移除（剩 8 个）；Generate_Table1 重渲染 RENDER_EXIT=0（docx 含 QJEP 2 行；table1_problems.txt 111 行为冻结历史清单，稿件比对默认关闭不重写）。
  - 清洗脚本 `Orellana-Corrales_2023_QJEP_clean.R`（PsychoPy 每被试导出 v1-v8 解析；**subject 编号复刻作者 1-mergeAndSubset.R 口径**并与 data_merged.tsv 逐值全等验证）；产出 raw/Clean（19,040 行 = 136×140，label=Ich/Möbel、bild=Kreis/Dreieck1-5.png 自原始导出恢复——data_merged.tsv 已丢弃）、subj_info（136 名；3 名 Age 缺失：subject 41 出生年 5 位手误 '19998'、49/121 未填）、paper+exp JSON（v2 五组件，detail 英文）、Codebook（14 行）。
  - **N 口径**：136 招募（words 71 + shapes 65）、29 名 Tukey 排除（SPSS 3-Syntax.sps 名单，words 16 + shapes 13）→ 分析 N=107（论文 t(54)/t(51) 吻合）；**论文 "69 male" 为分析样本口径笔误**（全样本数据 88 male/48 female，与作者 data_clean.csv 一致）。
- **双研究全量四方核对（论文-代码-数据-原始数据，subagent 并行）**：
  - **APP 2021**：论文 8 均值复现 0–1 ms 全等（683/931/855/898、615/701/658/670）；Clean ↔ 作者 MT.lst/matching_3.lst 逐被试 0 差；raw ↔ E-Prime txt/merged.tsv 逐值 0 差；License（OSF license=None）与 CSV "No License" 一致；**数据管道零错误**。
  - **QJEP 2023：重大发现（作者产物问题，库内数据不受影响）**——作者 `2-dataprep_mt.py` 打印顺序（mi→mf→ni→nf）与 OSF `data_clean.csv` 表头（im→in→fm→fn）不一致，致 **in*/fm* 两列互换**（逐值实证：subject 1 真实 i_m=729/f_m=948/i_n=816/f_n=850 vs data_clean im/in/fm/fn=729/948/816/850）；另 subject 2/73 无合格试次时 imRTmean 残留上一被试值。论文匹配任务全部统计量（F=199.28/77.08/111.13/255.76/5.90/4.63、均值 694/802/779/793）可**逐位精确复现自错位文件**：主效应标签互换、两中间格均值互换、非匹配 follow-up 方向反转（真实 self-nonmatch 803 > furn 795，F=4.80 p=.031）、d′ 基于错位 ER。**真实数据下 SPE 定性结论仍成立**（matching self 695 vs furn 779，F=120.80）。处置：详细说明文档 `3_Reports/Orellana-Corrales_2023_QJEP_Author_DataIssue.md`（论文原文引文+作者代码+agent 复现三证据链）；核对脚本固化 `2_Code/qjep_verify/`（原 /tmp 临时脚本，8 文件+README）；exp JSON detail 记录摘要；**是否联系作者由用户决定**。
- **工具与代码沉淀**：
  - `2_Code/repo_fetch.py` 修复：OSF 下载端点 `api.osf.io/v2/files/{fid}/download` 失效（404）→ 改用 `osf.io/{guid}/download`（GUID 自 API `attributes.guid`；24-hex fid 会落到 SPA 页面）；docstring 注明。
  - `1_Data/utils.R` 新增 E-Prime 解析通用函数（`read_eprime_txt`/`parse_header`/`parse_matching_blocks`，含中断被试未闭合块处理）；APP 清洗脚本改为调用（提取后重跑逐值一致）。
  - `2_Code/validate_json_metadata.R`：known_pending 移除 QJEP。
  - SKILL.md 沉淀：E-Prime/PsychoPy 解析先例、作者脚本逐值验证法（含 Tukey 上限倍数差异：Orellana-2021 q3+3×IQR vs QJEP q3+1.5×IQR）、Möbel→furniture→NonPerson 映射、**JSON 内容一律英文**（用户指示）、入库后四方核对步骤（场景 B 收尾必做）。
  - AGENTS.md：计数口径 35+8；防坑新增「非主索引 CSV（subj_info 等）格式各异（无 BOM+LF vs BOM+CRLF），编辑前先检测」。
  - README.md：计数同步 35+8 / 81 行。

### 2026-08-28 — REF/ 全文 HTML → MD 批量转换管线

- **管线建成**：`REF/html2Json.py`（HTML→JSON，适配 Elsevier 新旧模板 / Springer / Wiley / eLife 按出版商提取学术结构；`--force` 全量）+ `REF/json2md.py`（JSON→MD：YAML frontmatter、标题层级、图注+`![alt](src)`、Markdown 表格、参考文献 `[n]`、脚注、Acknowledgements/Correspondence）+ `pdf2md.py` 备用。用法与验收清单见 `REF/README_html2md.md`。
- **产物**：**10 篇 md**（Kirk / Lee / Martinez / Orellana / Scheller / Smith / Sui / Wang / Wozniak / Zhang）全部转换完成、图片全部本地无缺失（eLife 图按出现顺序映射本地 `_files/default.jpg, default(1).jpg, ...`，本地不足时 IIIF 远程兜底；含括号文件名自动转义）；Wang 为上一会话人工转换（PsycNet 模板未适配，`--force` 时生成空 json 已删除，json2md 对无 body 的 json 自动跳过以保护已有 md）。
- **已知边界（记录于 REF/README_html2md.md）**：Elsevier 复杂表格 rowspan/colspan 按行展平（表头略错位但数据完整）；Kirk 页头元数据缺失故作者/期刊等取自 Crossref 兜底（脚本内 `METADATA_OVERRIDES`）；Wiley/SAGE 页面 meta 缺失 → Crossref 补；BMC 参考文献是 `<ol>` 非 `<ul>`；PDF 双栏交错/表格重复是源版式固有边界，DeepSeek `_DS` 版更优。
- **操作纪律沉淀（AGENTS.md §防坑）**：删除前确认/不可跟踪文件先移暂存（REF/ 被 gitignore 误删 390 文件不可恢复）；覆盖前查目标、下载先落 /tmp 验证再 mv（`curl -o` 曾静默覆盖 Scheller html 致 1 MB→0 字节永久丢失）。
- **版本控制**：REF/ 内容按 .gitignore 策略不跟踪（仅 html2Json.py / json2md.py / README_html2md.md / html2md_PROMPT.md 4 个工具文件强制跟踪）。

### 2026-08 — 文档与治理

- **项目迁移至内部 APFS 磁盘**：项目不再位于外接 exFAT 盘 `/Volumes/T3`（T3 仍挂载但无仓库副本，已核实）；据此删除 AGENTS.md 全部外接硬盘专属内容（exFAT 章节、Document map 环境约束、省 token USB I/O 提示、会话收尾清理规则引用），通用规则移入新的「会话约定（通用）」节；grep 确认无 exFAT/T3/USB 残留。
- **AGENTS.md 效率治理**：新增「⚡效率全局原则」（与全局最高级规则同级：低效=严重问题——同类错误反复试错 / 重复验证 / 经验不调用 / 验证假象 / 不固化模式五项违规）与「工具链纪律」5 条（代码文件写 /tmp 纯文本、bash 验证看真实退出码与 stderr、文件移动用 bash mv/cp、R 语法备忘、subagent 结果靠通知）；清理过时内容 8 处（Clean_Data.Rmd 降级为历史配方、*_Raw/ 输入区化、Generate_Table1 比对默认关闭、caveats 稿件 v16 废弃与 Sun JSON 已补、两级校验、exFAT 规则扩展至一切写盘操作）。
- **PROJ_STATE 更新时机规范**：PROJ_STATE.md 只在 session 收尾统一更新一次（不逐条实时写入），同一 session 多次修改合并为收尾一条「已完成」条目——已写入 AGENTS.md Document map 与会话收尾两处。

## 关键决策

1. 期刊缩写须「专业人士可猜出期刊名」（完整对照表见 SKILL.md）；全名短期刊直用（Cognition/Cortex/NeuroImage/elife）；预印本用小写 psyarxiv，未发表数据用 unpub。
2. 年份规则：正式印刷年优先；仍仅在线的用在线年；预印本用最新版本年。
3. 清洗 = 最小预处理，不过滤无效值（ACC -1/2 保留并在 codebook 中说明）。
4. 校验链路：任何元数据改动后必须跑 Rscript 2_Code/validate_json_metadata.R（命名、年份漂移、exp 键、v2 组件完整性、文件夹↔CSV 交叉校验）。
5. 稿件 SPE_database_manu_v16.docx 已废弃（2026-08）：12 个待收录条目信息已登记入 Dataset_inf.csv Note 列（冲突以 CSV 现值为准）；Table 1 以 Generate_Table1.qmd 输出为准；与稿件的自动比对仅在稿件版本更新时手动启用。
6. 自动修改数据/元数据的依据 = **论文全文 + 原始数据**（JSON/CSV 均为衍生产物，互相矛盾时以全文/数据为准；2026-08 阶段 3.1 确认）。
7. **N 口径 = 数据口径优先**（2026-08 阶段 3.1 确认，入 SKILL.md）：`Sample_Size` = Clean 中被试总数；`Valid_Subj`/`Drop_Subj` 为派生值（清洗不过滤，通常 = Sample_Size / 0）；论文口径记 Note 列（`Paper_N:` 前缀）。pair 粒度研究（Constable_2019 E4、Constable_2020）2026-08 第三轮已决：**保持人数口径 40/92**（两人均有数据，A 组证据）+ Note 记 pair 粒度；E4 Female 14→26（论文 L173）。
8. `subj_Group` 列语义（2026-08 第三轮更新，废弃分号堆叠）：**每个 group 一行**，行唯一性 = `Folder_Name` + `Exp` + `subj_Group` 三元组；组间研究按组拆行、每行填单个组名（组内 N/性别填组内值、总体口径记 Note），无组间保持单行 `All`（全库 9 行→21 行已展开）。**Design 列不是组间判定的充分依据**——需以全文核对（Xu_2022/Constable_2020/Vicovaro E2 漏判案例）；试次级变量不展开（Xu high/low 数据不可还原，按 Acceptance/Rejection 2 行）。
9. 采集地判定（2026-08 入 SKILL.md）：**伦理委员会批准机构 = 数据采集机构**（CEU 批准 → Budapest）；作者履历单位不是采集地依据。

10. **ACC 统一编码**（2026-08 第三轮，方案 A 全库统一，入 SKILL.md）：`1`=正确、`0`=错误（范围内错键）、`NA`=无反应、`-2`=范围外按键、`-3`=提前、`-4`=超时；**负码仅在有明确证据时编码，否则 NA**（12 文件重编码 + 12 Codebook 同步）。
11. **自定义 Std 值先例**（2026-08 第三轮，入 SKILL.md）：6 类词表外允许原样/自定义值（`£9`/`£1` 奖赏刺激 Lee E2、`ingroup` 内群体成员 Constable E4 Coactor），须 Codebook 枚举注明。
12. **CSV `Self`/`Close`/`Others` 三列 = Std 6 类简写**（2026-08 第三轮，入 SKILL.md）：Self 列含 group-self（`Self/We`）、Close 列=Std Close 类（无 close-other 留空）、Others=其余；CSV 与 Std 必须同一口径。
13. **Exp2 Stim_Type 定值 `letter string`**（2026-08-30，Orellana-2021 Exp2 非词研究；库内 Stim_Type 值域新增，无现成先例，人工定值）。
14. **元数据 JSON 内容一律英文**（2026-08-30 用户指示）：paper/exp JSON 字段值（含 detail）不使用中文；中文说明性内容放仓库中文文档或脚本注释。
15. **QJEP 作者产物错位发现处置**（2026-08-30）：论文/OSF data_clean.csv 列错位（详见 3_Reports/Orellana-Corrales_2023_QJEP_Author_DataIssue.md）——库内数据正确不受影响；文档+JSON detail 记录归档，**是否联系作者由项目负责人决定**（超库范围不主动执行）。

## 核心文件

- 1_Data/Dataset_inf.csv — 主索引；1_Data/<Study>_<Year>_<Suffix>/ ×34 — 研究数据
- 2_Code/validate_json_metadata.R — 元数据校验器（含 8 个待入库白名单，2026-08-30 QJEP 移除）；2_Code/validate_clean_csv.R — 内容级校验器
- 3_Reports/Generate_Table1.qmd + Generate_Table1.docx + Output/table1_problems.txt — Table 1 再生成与比对（2026-08-27 重渲染：118 → 111 行问题）
- 3_Reports/Table1_Issues_Solvability.md — Table 1 问题可解性分析（107 项逐项判定：可自动确定 ~68 / 需人工 ~39；近似数以文档汇总表为准；与本文档双向关联）
- 3_Reports/Stage3_1_CrossCheck.md — 阶段 3.1 未解决问题编号清单（P1–P22；与本文档「已知问题」双向关联）
- 3_Reports/Orellana-Corrales_2023_QJEP_Author_DataIssue.md — QJEP 作者 data_clean.csv 列错位详细说明（2026-08-30 新增；论文原文+作者代码+agent 复现三证据链；核对脚本 2_Code/qjep_verify/）
- 2_Code/qjep_verify/ — QJEP 四方核对脚本固化（8 文件 + README；源自 /tmp 临时脚本，2026-08-30 固化）
- 3_Reports/Process_Data.Rmd — 下游分析（已改用 Folder_Name）
- REF/README_html2md.md — REF 全文 HTML→MD 管线使用说明（html2Json.py/json2md.py/pdf2md.py 用法、验收清单、模板适配；全文正文归属本文件，AGENTS/PROJ_STATE 只放指针）
- .opencode/skills/spe-database-curation/SKILL.md — 通用 curation 技能（自足独立；命名语法、JSON schema、Codebook 规范、DOI/年份核验）
- AGENTS.md — agent 约定与已知 caveats（含 Document map）
- README.md — 人类读者入口（项目介绍/数据使用）
- 引用关系：本文档与 README.md、AGENTS.md 相互引用；与 3_Reports/Table1_Issues_Solvability.md 双向关联（未解决清单 ↔ 可解性判定）；数据整理任务统一加载 spe-database-curation 技能

## REF/ 全文收录统计（2026-08-28 快照）

- **现状**：REF/ 覆盖 **39 个研究**全文材料（31 已入库 + 8 pending）；格式：html ×30、pdf ×9、md ×37（含 7 个 `*_DS.md`）、json ×29、Rmd ×2（Hu_2023_psyarxiv）、PMC.xml ×1、docx ×2。md/rmd 覆盖：40 个应有全文（43 − 3 unpublished）中 **38 个已有**；仅 Wang_2016_JEPHPP 为人工转换（PsycNet 模板未适配）。
- **`*_DS.md`**：7 个文件（Constable_2019/2021、Navon、Qian、Schaefer、Vicovaro、Hobbs）**经 DeepSeek 在线对话生成**，质量优于 pdf2md.py 原版（完整 frontmatter/结构化标题/Markdown 表格/无混排），原版已删；pdf2md.py 保留备用。
- **暂不考虑（无 md/rmd）**：`Sun_2026_DataExp`（数据论文，无传统全文）、`Hu_2023_SDB`（用户指示暂缓）。
- **重要教训（沉淀于 REF/README_html2md.md）**：① 转换优先走 `html2Json.py + json2md.py` 自动管线（已适配 Springer/Elsevier/Wiley/eLife/MDPI/Collabra/SAGE/PLOS 8 模板）；② Wiley/SAGE 页面 meta 缺失 → 用 Crossref 补 `METADATA_OVERRIDES`；③ BMC 参考文献是 `<ol>` 非 `<ul>`（曾漏 80 条）；④ PDF 用 pymupdf `words` 模式（span 层丢 APA 字距空格）；⑤ PDF 双栏交错/表格重复是源版式固有边界，DeepSeek `_DS` 版更优；⑥ pdf2md 自动跳过已有 md 的 PDF（html 版优先）。全文归属见 AGENTS.md Document map（管线详见 REF/README_html2md.md）。

## 测试结果（已实测）

- validator：EXIT=0（结构级）；2026-08-27 复测：**90 个 JSON 全绿**（阶段 1 新增 Lee/Smith/Svensson/Orellana 的 4 paper + 6 exp JSON；34 文件夹 ↔ CSV 交叉一致）。2026-08-30（QJEP 入库后）：**92 个 JSON 全绿**（+2 QJEP；35 文件夹 ↔ CSV 交叉一致；known_pending 8 个）。
- 内容级校验器 validate_clean_csv.R：59 文件 0 ERROR / 38 WARN（2026-08-30；含 QJEP Exp1 新文件；Orellana-2021 的 W2 口径 WARN 为已知类，subj_Group 拆行研究普遍现象）；支持 --data-dir（新产物串测用）。
- Table 1 渲染（2026-08-30 QJEP 入库后重渲染）：RENDER_EXIT=0；docx 含 QJEP 2 行（familiar words / new shapes）；table1_problems.txt 保持 111 行（冻结历史清单，稿件比对默认关闭不重写——2026-08-27 后无变化属预期）。
- git：分支 main。工作区未提交改动（2026-08-30 会话）：Dataset_inf.csv（Orellana 收口 + QJEP 3→2 行 + Stim_Type/Environmental_Info）、1_Data/Orellana-Corrales_2021_APP/{Exp1,Exp2}/*_raw.csv ×2 + subj_info ×2（人口学补全）、Orellana-Corrales_2021_APP_clean.R（新）、1_Data/Orellana-Corrales_2023_QJEP/ 全套新文件（raw/Clean/subj_info/Codebook/JSON ×2/clean.R）、2_Code/repo_fetch.py（OSF 端点修复）、2_Code/validate_json_metadata.R（白名单）、2_Code/qjep_verify/（新，8 文件 + README）、1_Data/utils.R（E-Prime 函数）、3_Reports/Orellana-Corrales_2023_QJEP_Author_DataIssue.md（新）、SKILL.md、AGENTS.md、README.md、PROJ_STATE.md（本文档）；输入区新增（Orellana-2021 双 OSF 存档、QJEP v8r2p 存档）不纳入版本控制属预期。

## 已知问题（未解决）

**条目级缺失汇总（2026-08 全量递归扫描，覆盖缺元数据/缺原始数据/缺 subject 级数据三类）**
分级标准：中度 = 缺元数据（codebook / JSON）；重度 = 缺 trial 级原始数据（`*_raw.csv`）。同一严重程度内按条目名 alphabetical 排列，整体由轻到重。

| 条目名（作者-年-期刊缩写） | 问题描述 | 缺少文件的数量 | 问题严重程度 |
|---|---|---|---|
| Smith_2024_Cortex | 元数据已齐（2026-08-27 阶段 1 补齐 paper/exp JSON ×2 + Codebook ×1）；raw 导出疑似不全（48 vs CSV 59/58，归阶段 4 判定） | 1 | 重度 |
| Sun_2026_DataExp | 无 raw.csv ×1（62 MB Clean 在库；raw 追补归阶段 4，用户+agent 共同决定）、无实验级 JSON ×1（CSV 行信息稀疏） | 2 | 重度 |
| Zhang_2023_NeuroImage | 无 raw.csv ×1（本次扫描新发现；归阶段 4：核实外部仓库后决定追补或豁免） | 1 | 重度 |

- **Orellana-Corrales_2021_APP 已补 raw（2026-08-30 阶段 4 完成）**：Exp1/Exp2 raw.csv 就位（34×128、33×128+01 的 68 行），从严重度表移除；subj_info 人口学已补全；CSV 行收口（Journal/numTrials/Practice/numBlocks/Environmental_Info/Stim_Type/Note）。
- **Orellana-Corrales_2023_QJEP 已入库（2026-08-30 阶段 5 首例完成）**：五件套就位、CSV 2 行（原 3 行错误信息修正）、白名单移除；新增已知问题见下条。
- **QJEP 作者产物列错位（2026-08-30 四方核对发现，作者/OSF 问题，库内数据正确）**：OSF `data_clean.csv` 的 in*/fm* 列互换（作者 2-dataprep_mt.py 打印顺序 bug），论文匹配任务全部统计量基于错位数据（主效应标签互换、中间格均值互换、非匹配 follow-up 方向反转、d′ 错）；真实数据下 SPE 定性结论仍成立。详情见 `3_Reports/Orellana-Corrales_2023_QJEP_Author_DataIssue.md`；**是否联系作者由项目负责人决定**。
- Smith_2024_Cortex：raw 数据仅 48 名被试（含剔除 1 个空 participant），与 CSV Sample_Size=59 / Valid_Subj=58 差约 10 名——raw 导出疑似不全，归阶段 4 由用户+agent 共同决定（追补 raw 或确认豁免并记录口径）。
- CSV 遗留空白（2026-08-30 更新）：Journal 空 0（Orellana 已填）；License 空 3（Sui_2015_unpub ×2 → L2；QJEP ×2 无 OSF 声明留空）；Stim_language 空 4（Scheller ×2、Wozniak_2020、Hu_2023_SDB → L3）；Country 空 3（Scheller ×2、Wozniak_2020 → L3）；City 空 8（Scheller ×2、Wozniak_2020 → L3；Sun → L2；Sui_2014_unpub 无采集地证据暂留空；Sui_2015_unpub ×2 → L2；QJEP 在线留空）。分层处理：L2 缺 raw 研究（Orellana/Sun/Sui_2015_unpub）→ 阶段 4 判定后收尾（Orellana 已完成）；L3 pending（Scheller/Wozniak_2020/Hu_2023_SDB）→ 阶段 5 入库时填齐。
- 稿件 Table 1 与数据差异（11 条 Exp 标注、N/Trials/Language/Stimulus/Exp_Implement 不一致等）：**稿件 v16 已废弃（2026-08），不再与其比对**；历史问题清单（table1_problems.txt，111 行）与逐项可解性判定（Table1_Issues_Solvability.md，107 项：可自动 ~68 / 需人工 ~39）冻结保留，待稿件版本更新时作为修正清单使用（渲染 qmd 传 --param compare_manu:true 刷新）。12 个 pending 条目（无文件夹）的稿件 Exp_Implement 信息已登记入 CSV Note 列。
- ~~Orellana-Corrales_2021_APP Exp2：Clean/subj_info 33 名被试 vs CSV Sample_Size 34 / Valid_Subj 31——N 口径待人工确认（稿件 36 亦不符；归阶段 4 数据判定后一并处理）。~~ **已闭合（2026-08-30）**：34 招募 = 33 Clean（nonwords-01 数据不完整移除，源数据问题）+ 1；论文分析 N=31 = 33 − {4,33}（SPSS 排除名单，df=30 吻合）；口径已记 CSV Note 与本文档阶段 4 条目。
- Pan_2025_unpub：subj_info 的 Age 按 2025−出生年（raw `year` 列 2000–2005）推算、Education 为原始编码 5（含义未文档化）——**待作者确认**（2026-08 用户决策：移到最后阶段解决）；CSV Sample_Size/Valid_Subj 已按 raw 40 名被试回填。
- Kirk_2025_BritJPsy.json 嵌套 schema 例外（内部键 KIRK_2025_BJP 保留不动）。
- Hu_2023_psyarxiv（PsyArXiv 预印本）与 Hu_2023_SDB（Science Data Bank）为两个独立条目，已确认分别保留。
- 历史管线 Clean_Data.Rmd 内仍引用旧文件夹名（纯历史记录，未改，部分可能在修订过程中进行了修改）。
- **阶段 3.1 全部解决（2026-08 第三轮后）**：21 研究复核完成、可自动改项两轮更新（CSV 61+48 单元格 + JSON 44 处），P15–P20 消解、P7–P9 标记解决（exp JSON detail 注明行数特征）、P5 解决（Bed 解码重建 Exp2 Clean）、**P3 解决（第三轮：MatchParticipant 映射重建 Self/ingroup，统计复现 L191）**。问题编号清单见 `3_Reports/Stage3_1_CrossCheck_archived.md`（本文件为存档）。

## 失败方案（已弃用，勿重试）

1. Table 1 比对键用 (Folder_Name, Exp)：因 CSV 中存在重复组合（Kirk/Liang/Wozniak 曾各有多个 Exp=1 行）而失败 → 改用 CSV 行号键。
2. 通用网页搜索查 DOI：结果噪声大、难确证 → 改用 Crossref API（作者+年份+期刊+题名过滤）。
3. OSF API 的 filter[doi] 查询返回 400 → 改用预印本 GUID 直取。

## 效率教训（已沉淀进 AGENTS.md 效率约定 / SKILL.md 规则，此处只留要点）

- **Sui_2015_unpub 会话（被用户点名「太慢 / over thinking」）**：① 对已核实结论过度完整重验 → 只做一次轻量抽查；② 纠结浮点末位显示差异（~1e-13 相对差）→ 数值等价即一致，一句话记录；③ CRLF/LF 上浪费多轮 → CRLF/LF 差异直接无视（git text=auto 归一化）；④ write/edit 在 exFAT 上原子写失败 → 固化 /tmp 中转 + cp（2026-08 迁至内部 APFS 后此条不再适用）；⑤ 验证输出不截断污染上下文 → 用 head/wc/diff | wc -l；⑥ 执行前把「哪些差异需解决、哪些可忽略」列清楚。
- **阶段 2 会话（7 项 agent 犯错教训）**：工具硬编码路径验证假象 / License=数据许可语义 / Country-City=数据采集地 / Email 以 CSV 为准 / 多任务口径 / 编辑锚点 / 全文核查——规则正文已沉淀至 AGENTS.md §防坑 + SKILL.md（Human decision points #4 License / #11 多任务口径 / #12 全文核查；paper JSON 节 Country-City=采集地、Email 以 CSV 为准），此处不再复制。沉淀本身曾犯跨文件复制正文、指针编号失同步的错——去重规则已固化进 AGENTS.md §会话收尾「沉淀去重」条。

## 下一步任务（当前最重要推进线路 — 分层清单 2026-08-27）

推进逻辑：按数据完整度分层——L1 完整规范（有文件夹 + 标准 `*_raw.csv`）→ 阶段 1–3；
L2 有文件夹但无标准 raw → 阶段 4；L3 无文件夹（8 个 pending）→ 阶段 5。先精细化、后补底子、
再收口。**git 提交类事项不列为任务**（仅用户指示时处理；当前工作区有未提交改动，见「测试结果」）。

### 论文全集三分类（全量交叉核对推进框架）

全部 43 个唯一 Folder_Name 按「交叉核对进度」分两大类(2026-08-29更新)，后续全量核对按此框架推进：

| 类别 | 数量 | 成员 | 说明 |
|---|---|---|---|
| **一、已完成全量交叉核对** | 28 | Kirk_2025_BritJPsy、Martinez-Perez_2024_ConsciousCog、Sui_2014_APP、Wang_2016_JEPHPP、Wozniak_2022_PsychRes、Orellana-Corrales_2021_APP、Orellana-Corrales_2023_QJEP 及阶段3.1| 阶段 2 已做「全文核查 + 交叉对比」并修复 31 单元格，不再重复核对 + 阶段3.1全量交叉核对（Stage3_1_CrossCheck_archived.md）+ **2026-08-30 阶段 4/5 四方核对（Orellana-2021 APP、Orellana-2023 QJEP，见本文档 2026-08-30 条目）** |
| **二、未来全量交叉核对** | 15 | 分两小类（见下） | 待数据或说明文档补齐后再核对 |
| ├ 二a：有数据但无说明文档/论文全文 | 3 | Hu_2023_psyarxiv、Sui_2014_unpub、Pan_2025_unpub | 数据五件套已齐但**无正式论文全文可依**；均为用户团队成员负责的数据项目，未来进行方法文档补充 |
| └ 二b：缺数据（有或没有说明文档/全文） | 12 | 阶段 4 三研究（Sun/Zhang/Smith）+ 阶段 5 八 pending（Bukowski/Golubickis/Hobbs/Hu_2023_SDB/Mcivor/Scheller/Svensson_2022/Wozniak_2020）+ Sui_2015_unpub（.mat 判定） | 先由阶段 4（补 raw）/阶段 5（整条目入库）补齐数据，入库后按其数据完整度并流程收尾 |

分类依据（判定顺序）：① 是否已做过全文核查+交叉对比（阶段 2 五研究 + 阶段3.1 21研究）→ ② REF/ 是否有正式论文全文 md/rmd（无 → 三a）→ ③ 是否缺数据/未入库（缺 → 三b，即阶段 4/5 对象。二a 与二b 区分：**二a 有数据缺文档**（用户查文档补全元数据），**二b 缺数据**（阶段 4/5 补数据）；二者均有全文者（如 Sun_2026_DataExp 无全文、Zhang_2023_NeuroImage 有 REF md）按自身情况在补数后归入对应流程。

### ~~阶段 1：元数据补齐~~ **已完成（2026-08-27）**
- **元数据补齐**：4 paper JSON（Lee / Smith / Svensson / Orellana-Corrales_2021_APP，[C] 字段经 Crossref 核对、Summary/Conclusion 由论文摘要/全文生成）+ 6 实验级 JSON（v2 五组件，方法细节来源分级：Lee 正文+OSF、Smith REF/ HTML+OSF 预注册、Svensson PMC、Orellana Springer）+ 6 Codebook（单 Sheet1 4 列，行数=Clean 列数）。遗留说明：Svensson exp JSON `Equipment.Software` 论文未披露留 `/`；Lee 数据为匹配任务（PMT1+PMT2）而非论文主任务（分类任务），已在 exp JSON detail 注明。
- **subj_info 全覆盖**：全库 56 个 `*_subj_info.csv` 就位——补齐 Lee（47/51）、Smith（48）、Svensson（65）、Kirk（35/90）；Orellana（34/33）由 Clean.csv 唯一 Subject 生成、Sui_2015_unpub（20/21）由 `*_Raw/` 人口学记录生成、Pan（40）由 raw.csv 重生成并回填 CSV Sample_Size/Valid_Subj。命名统一（48 git mv + 4 新增）、Exp_id 统一为 `<Folder_Name>_Exp<N>`；6 文档 42 处引用同步。
- **Table 1 问题清单刷新**：重渲染 RENDER_EXIT=0，table1_problems.txt **118 → 111 行**（8 条「稿件 ExpN vs qmd 空」类不一致消失，Martinez-Perez 新增 1 条）；Table1_Issues_Solvability.md 复核更新（**107 项：可自动确定 ~68 / 需人工 ~39**）并与本文档双向关联。
- **元数据规则约定**：Setting=Online 时 `Physical_Environment.Location` 与 `City` 可不填（入 SKILL.md §Five-component，落实于 Svensson exp JSON）。
- **工具脚本落盘**：`make_codebooks.R` 与 `analyze_csv_blanks.py` 存至 `2_Code/`。
- 验收：两级校验全绿（90 JSON EXIT=0；59 Clean 0 ERROR）；JSON 80→90、Codebook 行数==Clean 列数、paper JSON Year/DOI 与 CSV 一致。

### ~~阶段 2：CSV 文献/流程字段补全~~ **已完成（2026-08，本次会话）**
- **L1 七研究 13 行 24 单元格单次写入**：Kirk×2、Martinez-Perez、Sui_2014_APP×4、Wang_2016、Wozniak_2022×3、Pan、Sui_2014_unpub（来源 REF/ 全文 + paper JSON；用户决策：License=数据许可、Country/City=数据采集地、Wang/Sui_2014_APP paper JSON 同步 China/Beijing）。
- **5 篇论文全文一致性核查 + 修复 31 单元格**：Kirk×2（Journal 拼写、Self、Others→Stranger、补 Gorilla 环境/练习/块数/216 试次/全男）、Sui_2014_APP×4（E-Prime 1.1/18 练习/6 块）、Martinez-Perez（Practice_Trial 20→48）。保持不改：Wang Email（CSV 现值）、Martinez License=CC BY 4.0（数据许可 vs 文章许可）。
- **工具修复**：`analyze_csv_blanks.py` 硬编码外接盘路径改为脚本相对路径。
- 验收：字节保真（diff 仅 13 行目标行）；剩余空值仅存于 L2/L3（Orellana Journal×2、Sun City、Sui_2015_unpub City/License×2 → 阶段 4；Scheller/Wozniak_2020/Hu_2023_SDB → 阶段 5）及 Sui_2014_unpub City（无采集地证据暂留空）；validator EXIT=0。

### ~~阶段 3：N 口径核实~~ **已完成（2026-08，本次会话）**
- Lee/Kirk Exp2：核实 CSV 正确（论文排除后 N 与 CSV 一致），无需修改。
- Sui_2014_APP：按用户决策以数据为准（Sample_Size 保持 24/18/22/20），Exp1/Exp3 Note 记录论文差异。
- Vicovaro Exp2 重建：纳入 selfS+selfA 全部数据，Clean **12480→24960 行 / 48→104 Subject**（保留原始 participant_id，重复 ID 加段号后缀，条件由 Symmetry 列承载）；subj_info 重建 95→104 行；CSV Valid_Subj/Drop_Subj 修正（Exp1 27→30/3→0、Exp2 102→104/2→0）；validator 白名单移除该条。
- 经验沉淀：Subject 编号与数据对齐 4 条规则入 SKILL.md §清洗工具。
- ~~遗留：Pan~~ → **移到最后阶段解决**（见阶段 6 之后「最后阶段」）
- 验收：两级校验全绿（90 JSON EXIT=0；59 Clean 0 ERROR/40 WARN 与基线持平）。

### ~~阶段 3.1：无问题条目独立复核（对象：21 研究 / 37 行）~~ **全部完成（2026-08 第三轮，P1–P22 全部解决）**

**定位**：Dataset_inf.csv 中**先前判定无问题**的条目（不在已知问题清单、不在阶段 4 追补清单、不在 pending 清单）——这些字段多为早期人工填写，从未经过独立交叉验证。本阶段由 agent 对全部「无问题条目」做一次**独立复核**，以 REF/ 全文 + paper/exp JSON + Clean 数据为权威来源，逐字段与 CSV 现值比对，重点排查人工填写引入的隐性错误（拼写、错值、口径误填）。本阶段对应「论文全集三分类」**类别二**：类别一（5 已核查）排除不重复；类别三a（Hu_2023_psyarxiv / Sui_2014_unpub / Pan_2025_unpub，有数据无正式全文）由用户手动查文档后再核；类别三b（阶段 4/5 缺数据）由对应阶段补齐后再核。

**对象清单（43 个唯一 Folder_Name − 5 已核查（类别一）− 3 三a（Hu_2023_psyarxiv / Sui_2014_unpub / Pan_2025_unpub）− 5 L2 追补 − 9 pending = 21）**

| 研究 | CSV 行 | REF/ 全文来源 | 备注 |
|---|---|---|---|
| Amodeo_2024_CABN | 1 | Amodeo_2024_CABN.md | |
| Constable_2019_JEPHPP | 4 | Constable_2019_JEPHPP_DS.md | |
| Constable_2020_ActaPsych | 1 | Constable_2020_ActaPsych.md | |
| Constable_2021_CogEmo | 2 | Constable_2021_CogEmo_DS.md | |
| Dalmaso_2024_ConsciousCog | 2 | Dalmaso_2024_ConsciousCog.md | |
| Feldborg_2021_IJERPH | 1 | Feldborg_2021_IJERPH.md | |
| Haciahmet_2023_Psychophysiol | 1 | Haciahmet_2023_Psychophysiol.md | |
| Hu_2020_CollabraPsy | 1 | Hu_2020_CollabraPsy.md | |
| Kolvoort_2020_HumBrainMap | 1 | Kolvoort_2020_HumBrainMap.md | |
| Lee_2023_Cognition | 2 | Lee_2023_Cognition.md | 阶段 1 新补齐，重点 |
| Liang_2022_HumBrainMap | 3 | Liang_2022_HumBrainMap.md | |
| Liu_2023_CogRes | 1 | Liu_2023_CogRes.md | |
| Navon_2021_psyarxiv | 4 | Navon_2021_psyarxiv_DS.md | 预印本 |
| Perrykkad_2022_BMCPsych | 1 | Perrykkad_2022_BMCPsych.md | |
| Qian_2020_QJEP | 2 | Qian_2020_QJEP_DS.md | |
| Schaefer_2019_JCogPsych | 3 | Schaefer_2019_JCogPsych_DS.md | |
| Sui_2023_ConsciousCog | 1 | Sui_2023_ConsciousCog.md | |
| Svensson_2023_QJEP | 1 | Svensson_2023_QJEP.md | 阶段 1 新补齐，重点 |
| Vicovaro_2022_JEPHPP | 2 | Vicovaro_2022_JEPHPP_DS.md | 阶段 3 重建，重点 |
| Wozniak_2018_PLOS | 2 | Wozniak_2018_PLOS.md | |
| Xu_2022_CurrPsych | 1 | Xu_2022_CurrPsych.md | |

**核对内容（四方交叉，逐字段）**
1. **Dataset_inf.csv ↔ paper JSON**：Folder_Name/Year/DOI/Journal/Country/City/Stim_language/Stim_Type/License/Sample_Size/Male/Female/numTrials/Practice_Trial/numBlocks/Environmental_Info/Repo_Link——两处不一致以 CSV 现值为基准核对权威来源（Crossref/全文），判定修改侧。
2. **paper/exp JSON ↔ Clean CSV**：nSubj vs Clean 唯一 Subject 数；每实验 trial 数（numTrials vs Clean 行数/被试数，注意多轮/多块口径）；exp JSON 五组件（Participants/Stimuli/Procedure/Equipment/Physical_Environment）中的参数与 Clean 数据实际值是否吻合（如 Identity 类别集合、Matching 定义、RT/ACC 单位）。
3. **Clean CSV ↔ 论文全文**：Identity 标签映射（Origin→English→Standardized 三级是否与全文一致，重点核对 Self/Close/Acquaintance/Stranger 归属）、Matching 任务定义（shape-label 配对 vs 分类）、trial 数/块数/练习试次、刺激呈现参数（时长/键位/反馈）、被试数及排除标准、人口学。
4. **Codebook ↔ Clean CSV**：Codebook 列数 == Clean 列数；枚举值（含 NA/timeout/None 特殊值）已覆盖；单位与 missing/invalid 码说明。
5. **差异分级**：能由权威来源（Crossref/全文/数据本身）确定 → 可自动确定；需人工（如 N 口径、无证据的元数据）→ 登记待确认（参照 Table1_Issues_Solvability.md 的判定方法）。

**执行流程**
1. 加载 `spe-database-curation` 技能，先读 PROJ_STATE.md「已完成」「已知问题」与 `3_Reports/Table1_Issues_Solvability.md`，确认哪些差异已记录、避免重复发现；`analyze_csv_blanks.py` 重扫空白基线。
2. 按对象清单逐研究独立复核（**不预设「无问题」**，每个字段都向权威来源求证）：读 REF/ 全文 md（先 `head` 看结构，`grep` 定位关键段落，大文件不整读）→ 对照 paper/exp JSON 与 Dataset_inf.csv 行 → 对照 Clean CSV（列名、行数、Identity 分布、nSubj）。
3. 每研究输出一张差异表：字段 | CSV | JSON | Clean | 全文 | 判定（一致/需修改/需人工）。
4. 可自动确定且明确属数据侧错误的 → 修改（Dataset_inf.csv 字节保真编辑：BOM+CRLF+无末尾换行；JSON 改后跑 validator）；需人工的 → 登记进 PROJ_STATE.md 已知问题，不自行覆盖。
5. **禁止**：修改稿件/REF 原文；以稿件反推数据；对 pending（L3）、阶段 4 追补对象或已核查 5 研究做任何改动；重新追补 raw。

**验收**
- 两级校验 EXIT=0（改过 JSON → validate_json_metadata.R；改过数据 → validate_clean_csv.R）
- 21 研究差异表收齐；可自动确定项已消解；需人工项已登记（含 Orellana Exp2 N 口径、Pan Age/Education 等既有项不动，仅确认是否需新增）
- 核对结果（差异表 + 处置记录）写入本文件「已完成」或单独一节，供阶段 7 稿件更新时复用

### ~~阶段 4：原始数据追补~~ **Orellana-Corrales_2021_APP 已完成（2026-08-30）**，剩余：
- 判定原则：**Clean 数据已完成且说明文件（Codebook/JSON）齐全的研究，可豁免 `*_raw.csv`，不强制追补**
- 逐项（剩 4）：Sun_2026_DataExp、Zhang_2023_NeuroImage（查 paper JSON Repo_Link/OSF）、Smith_2024_Cortex（raw 48 vs 59 导出不全）、Sui_2015_unpub（输入区有 .mat，判定是否生成标准 raw.csv；其 subj_info 人口学已有，raw 追补可与 QJEP/APP 先例同法）
- **Wang_2016_JEPHPP Exp2 + control（2026-08 全文核查新增）**：论文含 Exp2 (N=20) 与 control (N=22)，raw 输入区已有 RawData_Exp2/ 与 RawData_Baseline/——整理原始数据后补 CSV 行与五件套（Exp2 与 control 是否均入库由用户确认）
- 收尾：该研究 CSV 空白与 N 口径一并收口，不重复编辑同一 CSV
- 验收：每项产出 raw.csv（输入区→清洗脚本→两级校验 EXIT=0）**或**确认豁免并记录结论；严重度表/白名单同步

### ~~阶段 5：pending 条目入库~~ **Orellana-Corrales_2023_QJEP 已完成（2026-08-30，首例）**，剩余 8：
- 用户将原始数据放入输入区后，加载 spe-database-curation 技能走 Metadata & ingestion workflow 场景 B（统一 10 步流程，SKILL.md 2026-08-27 版；**2026-08-30 补充：入库后必做四方核对**——论文-代码-数据-原始数据 + 论文统计复现）
- QJEP 先例要点：CSV 行可能为稿件错误信息需修正（QJEP 原 3 行实为 2020 论文信息）；subj_Group 拆行填组内 N/性别；License 无 OSF 声明留空；JSON 一律英文
- 其 CSV 空白（Scheller/Wozniak_2020/Hu_2023_SDB 的 Country/City/Stim_language）在入库时随行自然填齐
- 验收（每研究）：五件套齐全（raw/Clean/subj_info/Codebook/paper+exp JSON）、命名合规；从 known_pending 移除；两级校验 EXIT=0；Generate_Table1.qmd 重渲染 RENDER_EXIT=0、qmd 行数相应增加

### 阶段 6：清理与简化（依赖合作者确认 CSV）
- 删除 Dataset_inf.xlsx（先二次确认无独有信息）；移除 deprecated Paper_ID/Paper 列并简化 Generate_Table1.qmd 过渡映射；README/AGENTS/SKILL 引用同步（历史文档旧引用按惯例保留并标注）
- 验收：validator EXIT=0；qmd 渲染 EXIT=0 且问题清单无新增行

### 阶段 7：稿件更新支持（触发式，非例行）
- 稿件版本更新时：Generate_Table1.qmd --param compare_manu:true 渲染 → 按 Table1_Issues_Solvability.md 先「可自动确定」批（~68 项）后「需人工」批（~39 项）
- 验收：渲染 EXIT=0；每项消项关联数据侧改动证据（两级校验 EXIT=0）或人工判定记录；修正只改数据/元数据，永不反向以稿件覆盖 1_Data/

### 最后阶段：Pan 收尾（2026-08 用户决策，从阶段 3 移入；现归「论文全集三分类」三a）
- **Pan_2025_unpub**：subj_info 的 Age 按 2025−出生年（raw `year` 列 2000–2005）推算、Education 为原始编码 5（含义未文档化）——**待作者确认**后修正或记录口径入 Note；该研究无正式论文全文，属三a（有数据缺文档），说明文档查不到时按用户确认用 NA 填充
- 触发：与作者取得联系确认 Age 推算口径与 Education 编码含义
- 验收：确认后更新 subj_info（或 Note 记录口径）；两级校验 EXIT=0

### 横切约束（每阶段适用）
- 元数据改动 → validate_json_metadata.R EXIT=0；数据改动 → 加跑 validate_clean_csv.R 0 ERROR
- Dataset_inf.csv 字节保真（改前往返测试、改后 diff 仅目标单元格）；同一文件多处修改合并一次写入
- 写盘操作直接 write/edit（内部 APFS 磁盘原子写正常，无需 /tmp 中转）；文件移动用 bash mv/cp
- 与已核实事实冲突的判断暂停问人，不自行覆盖
