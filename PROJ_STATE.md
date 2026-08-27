# PROJ_STATE.md — SPE Database 项目状态（2026-08 更新）

## 当前目标

SPE（自我优先效应）数据库的整理与元数据治理：以「可读、自解释」的文件夹名（<Author>_<Year>_<期刊缩写>）作为全项目论文/预印本的关键 ID，以 1_Data/Dataset_inf.csv 为主索引，使 34 个已入库研究、9 个待入库条目的命名、年份、DOI、期刊信息与权威记录（Crossref/OSF/论文 JSON）对齐，并为稿件 Table 1 的再生成与比对提供可靠数据源。
当前最重要推进线路见「下一步任务」分层清单（L1 精细化 → L2 数据判定 → L3 入库 → 清理收口）。

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
- **Table 1 问题清单刷新 + 文档双向关联（2026-08-27）**：CSV Exp 回填后重渲染 `Generate_Table1.qmd`（RENDER_EXIT=0），table1_problems.txt 118 → 111 行——8 条「稿件 ExpN vs qmd 空」类 Exp 不一致消失（Lee/Orellana/Schaefer/Sun/Svensson，CSV 回填后与稿件一致），Martinez-Perez 新增 1 条（稿件 Exp1 vs CSV Exp2——CSV 已按合作者确认修正，稿件待改）；`Table1_Issues_Solvability.md` 按新清单复核更新（108 项：可自动确定 ~64 / 需人工 ~44），并与本文件建立双向关联（未解决清单 ↔ 可解性判定）。
- **subj_info 全覆盖（2026-08-27）**：① Orellana-Corrales_2021_APP ×2：由 Clean.csv 唯一 Subject 生成（Exp1 34 行 / Exp2 33 行，人口学全 /）——该研究无任何原始数据，Clean 是唯一来源；② Sui_2015_unpub ×2：由 `*_Raw/` 人口学记录文件（`PractExperiment_<Exp>_Subject_<N>_Ses_<S>.csv`，每文件 1 行 Experiment/Subject_Number/Initials/Gender/Age/Session）生成（Exp1 20 行 / Exp2 21 行，Age/Gender 取自记录；Exp2 subject 0 无人口学记录填 /；sub17 性别记录 'fm' 原文保留待确认）；③ Pan_2025_unpub：subj_info 由 raw.csv 重新生成（40 行，Subject_ID=1001–1040；Age=2025−出生年（raw `year` 列 2000–2005）推算，Education 保留原始编码 5），替换原 1 行异常占位文件，CSV 行 Sample_Size/Valid_Subj 补 40（字节保真编辑）。全库 56 个 `*_subj_info.csv`，格式与既有文件一致（无 BOM、LF、末尾换行）；validator EXIT=0；Table 1 重渲染 RENDER_EXIT=0（Pan N：稿件 40(—) vs qmd 40）。
- **Sui_2015_unpub 清洗脚本化 + 数据修复（2026-08，本次会话）**：① 新增 `1_Data/Sui_2015_unpub/Sui_2015_unpub_clean.R`（由 `Clean_Data.Rmd` 的 Sui_2015 两段提取：内嵌 read.mat、修正失效路径 `Sui_2015_Raw/Source/`→`Sui_2015_unpub_Raw/Source/`、写入 `Exp1|Exp2/Sui_2015_unpub_ExpN_Clean.csv`，CRLF 行尾与库内惯例一致）；② Exp2 排除测试被试 subject 0（`PractExperiment_2_Subject_3_Ses_1_.mat` 内部 num=0 的测试运行，240 行），Exp2_Clean.csv 9600→9360 行（subject 1-20，subject 3 仅剩 session 2），Exp1 不变（9600 行，与旧文件逐值一致）；③ Exp2_subj_info.csv 删除 subject 0 行、subject 3 人口学更正（0/fm→20/f，取自 Ses_2 真实记录 KB/f/20），21→20 行；④ Dataset_inf.csv Exp2 Sample_Size/Valid_Subj 21→20（字节保真编辑，BOM/CRLF/无末尾换行保持，diff 仅目标行 2 单元格），validator EXIT=0；⑤ 两个 codebook 补 ACC 3/4 说明（3=超时 RT≥1000 ms、4=无反应 RT=0）；⑥ `Clean_Data.Rmd` 两段同步修正（路径+subject 0 过滤+标题），diff 仅此 6 处。
- **12 个待收录条目信息登记（2026-08，本次会话）**：稿件 `SPE_database_manu_v16.docx` Table 1 中 12 个无数据文件夹条目（Bukowski×2、Golubickis×2、Hobbs、Mcivor、Orellana-Corrales_2023_QJEP×3、Svensson_2022×3）经核对全部已存在于 Dataset_inf.csv（Paper_ID 一一对应：P19E1/2、Pn4E1/2、Pt2E1、P45E1、Pn14E1-3、Pn16E1-3）；本次将稿件提供的 Exp_Implement 登记入 Note 列（`Manu_Table1: Lab/Online Experiment (pending)`，12 行；Golubickis Exp1 追加）；N/Trials 冲突均以 CSV 现值为准（稿件多处复制错误：Svensson 三行同值 25/400、Bukowski 两行同值 111、Orellana E2=E3 同值 36）；Crossref 核实 6 个 pending DOI 年份全部与 CSV 一致（Orellana-Corrales_2023_QJEP=2023，稿件 Study 标签 (2020) 错误）。字节保真编辑（BOM+CRLF+无末尾换行保持，diff 仅 12 行 Note 单元格），validator EXIT=0。
- **决策：稿件 v16 废弃（2026-08，本次会话）**：`SPE_database_manu_v16.docx` 不再作为 Table 1 比对基准（其核心信息——12 个待收录条目——已登记入 CSV Note 列）；`Generate_Table1.qmd` 稿件比对环节默认关闭（YAML `params: compare_manu: false`），稿件版本更新时以 `--param compare_manu:true` 启用；历史问题清单 `table1_problems.txt`（111 行）与 `Table1_Issues_Solvability.md` 判定冻结，仅作未来稿件更新时的修正清单。
- **自动化地基（2026-08，本次会话）**：① SKILL.md 新增 Raw input zone（输入区规范：`1_Data/<Study>/<Study>_Raw/` 放下载原始数据，只读、不参与校验）与 Metadata draft workflow（元数据草稿流程：Crossref 预填 paper JSON、数据推导 exp JSON 字段、来源分级 [D]/[C]/[P]/[H]）；② 新增内容级校验器 `2_Code/validate_clean_csv.R`（E1 缺 Subject / E2 Identity 三级不完整 / E3 nSubj vs subj_info；W1-W4 提示；支持 --data-dir 参数；known 白名单 16 条历史遗留），首扫 59 文件 0 ERROR；③ SKILL.md 新增 Human decision points（10 条人工决策清单）与 End-to-end workflow（自动化入库 10 步）。
- **自动化试点（2026-08，本次会话，三研究）**：从 Clean_Data.Rmd 提取独立清洗脚本并全量验证与现有产物一致——Sui_2014_unpub（17280 行逐值全等）、Navon_2021_psyarxiv（四实验 MD5 全同，4680/9720/10080/9720 行）、Vicovaro_2022_JEPHPP（295,680 单元格 0 差异）；脚本暂存 /tmp（vicovaro_clean.R / navon_clean.R / sui2014_clean.R），1_Data/ 零改动；串测：7 个新产物过 validate_clean_csv.R 全部 0 ERROR；元数据草稿 Crossref 预填与现有 paper JSON 一致（Vicovaro/Navon）。
- **清洗脚本落盘与统一（2026-08，本次会话）**：四个独立清洗脚本正式落盘（Vicovaro_2022_JEPHPP / Navon_2021_psyarxiv / Sui_2014_unpub / Sui_2015_unpub 各 <Study>_clean.R），统一架构：引导块定位脚本目录 → source 1_Data/utils.R（通用函数 spe_root/write_clean_csv，与脚本同库、不跨文件夹引用）→ 清洗逻辑 → 输出守卫；utils.R 由 2_Code/ 迁至 1_Data/。重构后全量重跑验证：Vicovaro/Navon/Sui_2014 输出与正式产物逐值一致；Sui_2015 仅 80/67 行 RT 末位显示差异（~1e-15 相对差，按数值等价约定视为一致）。
- **AGENTS.md 效率治理（2026-08，本次会话）**：新增「⚡ 效率全局原则」（与全局最高级规则同级：低效=严重问题——同类错误反复试错 / 重复验证 / 经验不调用 / 验证假象 / 不固化模式五项违规）；「工具链纪律」5 条（代码文件写 /tmp 纯文本、bash 验证看真实退出码与 stderr、文件移动用 bash mv/cp、R 语法备忘、subagent 结果靠通知）；清理过时内容 8 处（Clean_Data.Rmd 降级为历史配方参考、*_Raw/ 输入区化、Generate_Table1 比对默认关闭、caveats 稿件 v16 废弃与 Sun JSON 已补、两级校验、exFAT 规则扩展至一切写盘操作）。
- **SKILL.md 同库约定（2026-08）**：§清洗工具 新增「通用函数与独立脚本同库」——1_Data/utils.R 与 <Study>_clean.R 同在 1_Data/ 下 source 引用，不跨文件夹。
- **阶段 1 元数据补齐完成（2026-08-27，本次会话）**：① 4 个 paper JSON（Lee_2023_Cognition / Smith_2024_Cortex / Svensson_2023_QJEP / Orellana-Corrales_2021_APP）——[C] 字段经 Crossref 核对（标题/作者/期刊/年份/DOI 与 CSV 一致）、Summary/Conclusion 由论文摘要/全文/补充材料生成、Country/City/Email 取 CSV 现值（Svensson Email 取自论文通讯信息）；② 6 个实验级 JSON（v2 五组件）——方法细节来源分级：Lee 由论文正文+OSF 补充材料（匹配任务 PMT1+PMT2，fixation 500ms→配对 150ms→空白至响应/1500ms→反馈 500ms；3 practice×8 + 正式 3×16/轮，数据含两轮=96 试次/被试）、Smith 由 REF/ 论文 HTML+OSF 预注册（PsychoPy2、3 面孔、20s 学习、500/500/100ms、12 熟悉化+3×120、键 c/m；Dell monitor 仅预注册有）、Svensson 由 PMC 全文（Prolific 在线、500/100ms、12 practice+120 试次、V/B 键；软件字段未知留 /）、Orellana 由 Springer 全文（E-Prime 2.0、50cm、4 practice+128 试次、d/k 键；Study 2 非词关联 4×3000ms）；③ 6 个 Codebook（单 Sheet1 4 列，行数=Clean 列数，枚举值取自数据含 NA/timeout/None 等特殊值）；④ 两级校验：结构级 90 JSON EXIT=0、内容级 59 文件 0 ERROR/40 WARN（无新增）。
- **阶段 1 流程沉淀（2026-08-27，本次会话）**：① 本次获取的论文全文/资料落盘 `REF/`（Lee_2023_Cognition.pdf + _supp.docx、Orellana-Corrales_2021_APP.html、Svensson_2023_QJEP_PMC.xml、Smith_2024_Cortex_prereg.pdf + _OSF_README.docx，叠加用户已有的 Smith_2024_Cortex.html/.pdf）；② SKILL.md 以「Metadata & ingestion workflow（元数据入库/补齐统一流程）」替换并融合原「End-to-end workflow」与「Metadata draft workflow」两节——双场景统一 10 步流程（场景 A backfill=已有数据补元数据 / 场景 B ingestion=全新入库），汇合点元数据核心（[C] Crossref / [P] 论文全文 / [D] 数据推导 / 人工确认 / Codebook），收尾两级校验+文档同步；**关键约定：论文全文查找顺序强制为 ① 查 REF/ → ② 先问用户是否已有全文 → ③ 才走 OA 渠道**，避免重复搜索。
- **元数据规则约定（2026-08-27）**：**Setting = Online 时，`Physical_Environment.Location` 与 Dataset_inf.csv / paper JSON 的 `City` 可不填**（在线被试可分布于任何地点，位置无意义）——填 `/` 或 `N/A` 均可，无需追查。已沉淀入 SKILL.md §Five-component task framework，并落实于 Svensson_2023_QJEP exp JSON detail。
- **工具脚本落盘（2026-08-27，本次会话）**：阶段 1 沉淀的两个可复用工具保存至 `2_Code/`——`make_codebooks.R`（Codebook 生成器，阶段 5 新研究入库复用；SKILL.md §Codebook authoring rules 已引用）与 `analyze_csv_blanks.py`（Dataset_inf.csv 空白扫描器，阶段 2 前置重扫基线用）。
- **阶段 2 CSV 文献/流程字段补全完成（2026-08，本次会话）**：L1 七研究 13 行 24 单元格单次写入——Kirk×2（Country=United Kingdom、Stim_language=English、City=`/` 按 Online/Prolific 规则）、Martinez-Perez（Country=Spain、City=Murcia）、Sui_2014_APP×4（License=`/`）、Wang_2016（Country=China、City=Beijing、Stim_language=English）、Wozniak_2022×3（Country=Hungary、City=Budapest）、Pan（Stim_language=Chinese、License=`/`）、Sui_2014_unpub（License=`/`）。字段来源：REF/ 全文核对（Kirk=苏格兰英语单语被试+英文标签、Martinez=University of Murcia 本科生、Sui_2014=清华被试、Wang=中文拼音被试名+2013 采集+英文标签、Wozniak=CEU Budapest）+ paper JSON。**用户决策**：① License 指数据许可，无 OSF/数据链接信息用 `/`；② Kirk City 留 `/`；③ Wang Country/City 以数据采集地为准填 China/Beijing，且 Sui_2014_APP.json 与 Wang_2016_JEPHPP.json 的 paper JSON Country/City 同步 UK/Oxford → China/Beijing（Wang paper JSON 按同一「数据采集地」原则一并修改）。字节保真（BOM+CRLF+无末尾换行，diff 仅 13 行目标行）；validator EXIT=0（90 JSON 全绿）。**工具修复**：`analyze_csv_blanks.py` 硬编码外接盘路径 `/Volumes/T3/...` 改为脚本相对路径（原会读到 T3 旧副本导致基线误报）。
- **5 篇论文全文一致性核查 + 修复（2026-08，本次会话）**：对照 REF/ 全文 HTML 核查 5 篇已发表论文，修复 31 单元格——① Kirk×2：Journal 拼写 `British Journal of Psycholog`→`British Journal of Psychology`、Self 列 `Slef`→`Self`、Others `Other`→`Stranger`（论文第三身份为 stranger）、补 Environmental_Info=Gorilla Experiment Builder / Practice_Trial=12 / numBlocks=3 / numTrials=216 / Male=35(Exp1)·90(Exp2) / Female=0（论文两实验全男性被试）；② Sui_2014_APP×4：补 Environmental_Info=E-Prime 1.1 / Practice_Trial=18 / numBlocks=6；③ Martinez-Perez：Practice_Trial 20→48（采用匹配任务口径，论文匹配任务练习为 48 试次；20 是 AB 任务练习）。**保持不改**：Wang Email 按用户指示保持 CSV 现值 `jie.sui@abdn.ac.uk`（全文/paper JSON 为 psy.ox.ac.uk，用户选择 CSV 现值）；Martinez License=CC BY 4.0 保持（用户确认：License 列=数据许可而非文章许可，文章 HTML 显示 CC BY-NC-ND 4.0 属论文许可，两者不混）。validator EXIT=0。
- **项目迁移至内部磁盘 + AGENTS.md 外接硬盘内容移除（2026-08，本次会话）**：项目已迁至内部 APFS 磁盘（`/dev/disk3s5`，工作路径 `~/Downloads/Collaborations/SPE_Database/SPE_Database`），不再位于外接 exFAT 盘 `/Volumes/T3`（T3 仍挂载但无仓库副本，已核实）。据此删除 AGENTS.md 全部外接硬盘专属内容：整个 exFAT 章节（强制 `._*` 清理命令、`git gc --prune=now` 规则、write/edit 的 /tmp+cp 变通、卸盘职责、慢 I/O 提示）、Document map「环境约束（exFAT）」、省 token 节「USB 盘 I/O 慢」、「会话收尾」中「清理规则」引用；通用规则保留并移入新的「会话约定（通用）」节（探索需用户批准 / 后台任务时限 / 不提交 macOS cruft、不把 `._*` 当数据）。验证：grep 确认 AGENTS.md 已无 exFAT/T3/USB 残留。


## 关键决策

1. 期刊缩写须「专业人士可猜出期刊名」（完整对照表见 SKILL.md）；全名短期刊直用（Cognition/Cortex/NeuroImage/elife）；预印本用小写 psyarxiv，未发表数据用 unpub。
2. 年份规则：正式印刷年优先；仍仅在线的用在线年；预印本用最新版本年。
3. 清洗 = 最小预处理，不过滤无效值（ACC -1/2 保留并在 codebook 中说明）。
4. 校验链路：任何元数据改动后必须跑 Rscript 2_Code/validate_json_metadata.R（命名、年份漂移、exp 键、v2 组件完整性、文件夹↔CSV 交叉校验）。
5. 稿件 SPE_database_manu_v16.docx 已废弃（2026-08）：12 个待收录条目信息已登记入 Dataset_inf.csv Note 列（冲突以 CSV 现值为准）；Table 1 以 Generate_Table1.qmd 输出为准；与稿件的自动比对仅在稿件版本更新时手动启用。

## 核心文件

- 1_Data/Dataset_inf.csv — 主索引；1_Data/<Study>_<Year>_<Suffix>/ ×34 — 研究数据
- 2_Code/validate_json_metadata.R — 元数据校验器（含 9 个待入库白名单）
- 3_Reports/Generate_Table1.qmd + Generate_Table1.docx + Output/table1_problems.txt — Table 1 再生成与比对（2026-08-27 重渲染：118 → 111 行问题）
- 3_Reports/Table1_Issues_Solvability.md — Table 1 问题可解性分析（107 项逐项判定：可自动确定 ~68 / 需人工 ~39；近似数以文档汇总表为准；与本文档双向关联）
- 3_Reports/Process_Data.Rmd — 下游分析（已改用 Folder_Name）
- .opencode/skills/spe-database-curation/SKILL.md — 通用 curation 技能（自足独立；命名语法、JSON schema、Codebook 规范、DOI/年份核验）
- AGENTS.md — agent 约定与已知 caveats（含 Document map）
- README.md — 人类读者入口（项目介绍/数据使用）
- 引用关系：本文档与 README.md、AGENTS.md 相互引用；与 3_Reports/Table1_Issues_Solvability.md 双向关联（未解决清单 ↔ 可解性判定）；数据整理任务统一加载 spe-database-curation 技能

## 测试结果（已实测）

- validator：EXIT=0（结构级）；2026-08-27 复测：**90 个 JSON 全绿**（阶段 1 新增 Lee/Smith/Svensson/Orellana 的 4 paper + 6 exp JSON；此前 80 全绿；34 文件夹 ↔ CSV 交叉一致）。
- 内容级校验器 validate_clean_csv.R：59 文件 0 ERROR / 16 KNOWN / 40 WARN（口径差异与替代列提示）；支持 --data-dir（新产物串测用）。
- git：8b1d4b8（start to work on whole pipeline）之后工作区有 21 项未提交改动（4 脚本 + utils.R + 7 个新 JSON + 双校验器 + AGENTS/SKILL/PROJ_STATE 等），未 push。
- Table 1 渲染（2026-08-27 两次重渲染）：RENDER_EXIT=0；qmd 58 行 vs 稿件 70 行（12 个 pending 无文件夹）；table1_problems.txt 118 → 111 行（CSV Exp 回填后 8 条 Exp 不一致消失、新增 Martinez 1 条；Pan N 回填后其行显示 稿件 40(—) vs qmd 40）。
- git：5 个 commit（docs / data / reports + 2026-08 补 Exp 的 data / docs 两个 commit）；2026-08-27 阶段 1 之后工作区有 **22 项未提交改动**（4 修改：.gitignore、SKILL.md、AGENTS.md、PROJ_STATE.md；18 新增：阶段 1 四研究 JSON×10 + Codebook×6 + 2_Code 的 analyze_csv_blanks.py / make_codebooks.R），未 push。阶段 2（2026-08）新增未提交：Dataset_inf.csv（阶段 2 24 单元格 + 全文核查修复 31 单元格）、Sui_2014_APP.json + Wang_2016_JEPHPP.json（Country/City）、analyze_csv_blanks.py（路径修复）、PROJ_STATE.md（本文件）。

## 已知问题（未解决）

**条目级缺失汇总（2026-08 全量递归扫描，覆盖缺元数据/缺原始数据/缺 subject 级数据三类）**
分级标准：中度 = 缺元数据（codebook / JSON）；重度 = 缺 trial 级原始数据（`*_raw.csv`）。同一严重程度内按条目名 alphabetical 排列，整体由轻到重。

| 条目名（作者-年-期刊缩写） | 问题描述 | 缺少文件的数量 | 问题严重程度 |
|---|---|---|---|
| Lee_2023_Cognition | 元数据已齐（2026-08-27 阶段 1 补齐 paper/exp JSON ×3 + Codebook ×2）；raw/subj_info/Clean 齐全 | 0 | 已解决 |
| Smith_2024_Cortex | 元数据已齐（2026-08-27 阶段 1 补齐 paper/exp JSON ×2 + Codebook ×1）；raw 导出疑似不全（48 vs CSV 59/58，归阶段 4 判定） | 1 | 重度 |
| Svensson_2023_QJEP | 已全部补齐（2026-08-27 阶段 1：paper/exp JSON ×2 + Codebook ×1） | 0 | 已解决 |
| Orellana-Corrales_2021_APP | 无 raw.csv ×2（subj_info 已于 2026-08-27 由 Clean.csv 唯一 Subject 生成，Exp1 34 行 / Exp2 33 行，人口学 /；元数据 2026-08-27 阶段 1 已补齐；raw 追补归阶段 4，用户+agent 共同决定） | 2 | 重度 |
| Sun_2026_DataExp | 无 raw.csv ×1（62 MB Clean 在库；raw 追补归阶段 4，用户+agent 共同决定）、无实验级 JSON ×1（CSV 行信息稀疏） | 2 | 重度 |
| Zhang_2023_NeuroImage | 无 raw.csv ×1（本次扫描新发现；归阶段 4：核实外部仓库后决定追补或豁免） | 1 | 重度 |

- Smith_2024_Cortex：raw 数据仅 48 名被试（含剔除 1 个空 participant），与 CSV Sample_Size=59 / Valid_Subj=58 差约 10 名——raw 导出疑似不全，归阶段 4 由用户+agent 共同决定（追补 raw 或确认豁免并记录口径）。

- CSV 遗留空白（2026-08 阶段 2 完成后基线）：Exp 无空白（Scheller 两行 Exp=1/2 均已填）；Year 无空白；Journal 空 2（Orellana-Corrales_2021_APP ×2 → L2）；License 空 2（Sui_2015_unpub ×2 → L2；其余 Sui_2014_APP ×4/Pan/Sui_2014_unpub 已按无数据许可声明填 `/`）；Stim_language 空 4（Scheller ×2、Wozniak_2020、Hu_2023_SDB → L3）；Country 空 3（Scheller ×2、Wozniak_2020 → L3）；City 空 7（Scheller ×2、Wozniak_2020 → L3；Sun → L2；Sui_2014_unpub 无采集地证据暂留空；Sui_2015_unpub ×2 → L2）。分层处理：L1 完整规范研究 13 行已全部补全（阶段 2 完成）；L2 缺 raw 研究（Orellana/Sun/Sui_2015_unpub）→ 阶段 4 判定后收尾；L3 pending（Scheller/Wozniak_2020/Hu_2023_SDB）→ 阶段 5 入库时填齐。
- 稿件 Table 1 与数据差异（11 条 Exp 标注、N/Trials/Language/Stimulus/Exp_Implement 不一致等）：**稿件 v16 已废弃（2026-08），不再与其比对**；历史问题清单（table1_problems.txt，111 行）与逐项可解性判定（Table1_Issues_Solvability.md，107 项：可自动 ~68 / 需人工 ~39）冻结保留，待稿件版本更新时作为修正清单使用（渲染 qmd 传 --param compare_manu:true 刷新）。12 个 pending 条目（无文件夹）的稿件 Exp_Implement 信息已登记入 CSV Note 列。
- Orellana-Corrales_2021_APP Exp2：Clean/subj_info 33 名被试 vs CSV Sample_Size 34 / Valid_Subj 31——N 口径待人工确认（稿件 36 亦不符；归阶段 4 数据判定后一并处理）。
- Pan_2025_unpub：subj_info 的 Age 按 2025−出生年（raw `year` 列 2000–2005）推算、Education 为原始编码 5（含义未文档化）——待作者确认；CSV Sample_Size/Valid_Subj 已按 raw 40 名被试回填。
- Sui_2014_APP：Exp1/Exp3 数据 N（24/22）与论文（22/19）不符（2026-08 全文核查发现；subj_info/Clean 与论文不一致，Exp2/Exp4 一致）——归阶段 3 以数据为准复核。
- Kirk_2025_BritJPsy.json 嵌套 schema 例外（内部键 KIRK_2025_BJP 保留不动）。
- Hu_2023_psyarxiv（PsyArXiv 预印本）与 Hu_2023_SDB（Science Data Bank）为两个独立条目，已确认分别保留。
- 历史管线 Clean_Data.Rmd 内仍引用旧文件夹名（纯历史记录，未改，部分可能在修订过程中进行了修改）。
- **自动化试点新发现（2026-08，待决策）**：① ~~Navon Exp3 Label 标准化 bug~~ **已修复（2026-08）**：脚本与 Rmd 的 case_when "Friend"→"Father"，Exp3 Clean 3360 行 NA→Close，Exp1/2/4 零变化（下游分析结果将变化，属预期修正）；② Vicovaro Exp2：原始空 participant ID 块（240 行）重编号为 Subject 1（无人口学）；4 名被试（AC99/LS99/MS98/SD99）selfS 块 480 行含重复行未去重；Asymmetry 块被配方丢弃；③ ~~Sui_2014_unpub 缺实验级 JSON~~ **已补（2026-08）**：新建 Sui_2014_unpub_Exp1.json（v2 五组件，数据可推导字段填充、未知 /；validator 通过）；④ ~~Navon paper JSON DOI 前缀~~ **已修正（2026-08）**为裸格式 10.31234/osf.io/9dzm4。

## 失败方案（已弃用，勿重试）

1. Table 1 比对键用 (Folder_Name, Exp)：因 CSV 中存在重复组合（Kirk/Liang/Wozniak 曾各有多个 Exp=1 行）而失败 → 改用 CSV 行号键。
2. 通用网页搜索查 DOI：结果噪声大、难确证 → 改用 Crossref API（作者+年份+期刊+题名过滤）。
3. OSF API 的 filter[doi] 查询返回 400 → 改用预印本 GUID 直取。

## 效率教训（2026-08 Sui_2015_unpub 会话，已沉淀进 AGENTS.md 效率约定）

本次会话被用户点名「太慢 / over thinking」，根源与对策：
1. **过度验证已核实的结论**：前序 agent 已确认 subject 0 与 ACC 编码，仍完整重验（扫 80 个 .mat + 重建对比 + 字节对比 3 轮）。→ 对已记录事实只做一次轻量抽查。
2. **纠结数值无关紧要的格式差异**：脚本输出与旧文件浮点末位显示不同（R %.15g vs Python repr，~1e-13 相对差），花多轮追根源（R 版本/printf/scipy），用户喊停。→ 数值等价即一致，格式差异一句话记录，不重写旧文件。
3. **在 CRLF/LF 行尾上浪费多轮**：脚本输出 LF 覆盖 CRLF 文件后反复恢复/转换，用 grep 验证还丢回车。→ **CRLF/LF 差异直接无视**（用户明确指示）：git text=auto 归一化行尾比较，diff 只显示内容改动，无需为行尾重写/恢复文件（注意 grep/awk 等工具处理 CRLF 的行为差异即可）。
4. **write/edit 工具在 exFAT 上原子写失败**（ENOTSUP: link）浪费一轮。→ 固化 /tmp 中转 + cp 模式。（2026-08 项目迁至内部 APFS 磁盘后此条不再适用：write/edit 直接可用，勿再 /tmp+cp）
5. **验证输出不截断**：裸跑整文件 diff 输出数万字节污染上下文。→ 用 head/wc/diff | wc -l。
6. 教训：执行前把「哪些差异需要解决、哪些可忽略」列清楚，比反复探查更省时间。

## 效率教训（2026-08 阶段 2 会话）

本会话 7 项 agent 犯错教训（工具硬编码路径验证假象 / License=数据许可语义 / Country-City=数据采集地 / Email 以 CSV 为准 / 多任务口径 / 编辑锚点 / 全文核查）的**规则正文已沉淀至**：AGENTS.md §防坑（工具路径、编辑锚点两条操作纪律）+ spe-database-curation 技能 SKILL.md（Human decision points #4 License / #11 多任务口径 / #12 全文核查；paper JSON 节 Country-City=采集地、Email 以 CSV 为准）——此处不再复制。会话事实（改动内容、用户决策）见「已完成」阶段 2 与全文核查条目。**沉淀本身也犯了错**（跨文件复制正文、SKILL 文件内重复、指针编号失同步），去重规则已固化进 AGENTS.md §会话收尾「沉淀去重」条。

## 下一步任务（当前最重要推进线路 — 分层清单 2026-08-27）

推进逻辑：按数据完整度分层——L1 完整规范（有文件夹 + 标准 `*_raw.csv`）→ 阶段 1–3；
L2 有文件夹但无标准 raw → 阶段 4；L3 无文件夹（9 个 pending）→ 阶段 5。先精细化、后补底子、
再收口。**git 提交类事项不列为任务**（仅用户指示时处理；当前工作区有未提交改动，见「测试结果」）。

### ~~阶段 1：元数据补齐~~ **已完成（2026-08-27）**：4 paper JSON + 6 exp JSON + 6 Codebook 全部落盘；两级校验全绿（90 JSON EXIT=0；59 Clean 0 ERROR）。验收达标：JSON 80→90、Codebook 行数==Clean 列数、paper JSON Year/DOI 与 CSV 一致。遗留说明：Svensson exp JSON `Equipment.Software` 论文未披露留 `/`；Lee 数据为匹配任务（PMT1+PMT2）而非论文主任务（分类任务），已在 exp JSON detail 注明。

### ~~阶段 2：CSV 文献/流程字段补全~~ **已完成（2026-08，本次会话）**：L1 七研究 13 行 24 单元格全部补齐（详见「已完成」阶段 2 条目）。验收达标：字节保真（BOM+CRLF+无末尾换行，diff 仅 13 行目标行）；剩余空值仅存于 L2/L3（Orellana Journal×2、Sun City、Sui_2015_unpub City/License×2 → 阶段 4；Scheller/Wozniak_2020/Hu_2023_SDB → 阶段 5）及 Sui_2014_unpub City（无采集地证据暂留空）；validator EXIT=0。

### 阶段 3：N 口径核实（对象：仅 L1 口径矛盾研究）
- Lee（subj_info 47/51 vs qmd 57/65）、Kirk Exp2（90 vs 126）、Pan（Age 推算/Education 编码 5 待作者确认）、Vicovaro Exp2（空 ID→Subject 1、4 被试 selfS 重复行、Asymmetry 块被弃 → 数据决策）
- **Sui_2014_APP（2026-08 全文核查新增）**：Exp1/Exp3 N 数据(24/22) vs 论文(22/19)——以当前数据为准复核（subj_info/Clean 均为 24/18/22/20，论文报告 22/18/19/20），判定后修正 CSV Sample_Size 或记录口径入 Note
- 推迟：Smith（raw 导出不全）、Orellana（依赖原始数据）→ 阶段 4
- 验收：每项结论（修正附证据 / 记录口径入 Note）；数据修改则两级校验 EXIT=0 + 脚本注释写明证据

### 阶段 4：原始数据追补（对象：L2 五研究 — 用户+agent 共同决定）
- 判定原则：**Clean 数据已完成且说明文件（Codebook/JSON）齐全的研究，可豁免 `*_raw.csv`，不强制追补**
- 逐项：Sun_2026_DataExp、Zhang_2023_NeuroImage（查 paper JSON Repo_Link/OSF）、Orellana-Corrales_2021_APP（osf.io/g7wrc、osf.io/4cwrv）、Smith_2024_Cortex（raw 48 vs 59 导出不全）、Sui_2015_unpub（输入区有 .mat，判定是否生成标准 raw.csv）
- **Wang_2016_JEPHPP Exp2 + control（2026-08 全文核查新增）**：论文含 Exp2 (N=20) 与 control (N=22)，raw 输入区已有 RawData_Exp2/ 与 RawData_Baseline/——整理原始数据后补 CSV 行与五件套（Exp2 与 control 是否均入库由用户确认）
- 收尾：该研究 CSV 空白与 N 口径一并收口，不重复编辑同一 CSV
- 验收：每项产出 raw.csv（输入区→清洗脚本→两级校验 EXIT=0）**或**确认豁免并记录结论；严重度表/白名单同步

### 阶段 5：pending 条目入库（对象：L3 九条目 — 用户加入原始数据后 skill 自动/半自动入库）
- 用户将原始数据放入输入区后，加载 spe-database-curation 技能走 Metadata & ingestion workflow 场景 B（统一 10 步流程，SKILL.md 2026-08-27 版）
- 其 CSV 空白（Scheller/Wozniak_2020/Hu_2023_SDB 的 Country/City/Stim_language）在入库时随行自然填齐
- 验收（每研究）：五件套齐全（raw/Clean/subj_info/Codebook/paper+exp JSON）、命名合规；从 known_pending 移除；两级校验 EXIT=0；Generate_Table1.qmd 重渲染 RENDER_EXIT=0、qmd 行数相应增加

### 阶段 6：清理与简化（依赖合作者确认 CSV）
- 删除 Dataset_inf.xlsx（先二次确认无独有信息）；移除 deprecated Paper_ID/Paper 列并简化 Generate_Table1.qmd 过渡映射；README/AGENTS/SKILL 引用同步（历史文档旧引用按惯例保留并标注）
- 验收：validator EXIT=0；qmd 渲染 EXIT=0 且问题清单无新增行

### 阶段 7：稿件更新支持（触发式，非例行）
- 稿件版本更新时：Generate_Table1.qmd --param compare_manu:true 渲染 → 按 Table1_Issues_Solvability.md 先「可自动确定」批（~68 项）后「需人工」批（~39 项）
- 验收：渲染 EXIT=0；每项消项关联数据侧改动证据（两级校验 EXIT=0）或人工判定记录；修正只改数据/元数据，永不反向以稿件覆盖 1_Data/

### 横切约束（每阶段适用）
- 元数据改动 → validate_json_metadata.R EXIT=0；数据改动 → 加跑 validate_clean_csv.R 0 ERROR
- Dataset_inf.csv 字节保真（改前往返测试、改后 diff 仅目标单元格）；同一文件多处修改合并一次写入
- 写盘操作直接 write/edit（内部 APFS 磁盘原子写正常，无需 /tmp 中转）；文件移动用 bash mv/cp
- 与已核实事实冲突的判断暂停问人，不自行覆盖
