# Stage 3.1 四方交叉复核——未解决问题清单

对应 PROJ_STATE.md「阶段 3.1：无问题条目独立复核」。**21 研究 / 37 行全部复核完成**（样板 3 + 剩余 18），方法 = 机械比对（2_Code/stage31_crosscheck.py）+ REF 全文人工核对。

**处理原则（2026-08 确认）**：
- 自动修改依据 = **论文全文 + 原始数据**（JSON/CSV 均为衍生产物）
- **N 口径 = 数据口径优先**：`Sample_Size` = Clean 中被试总数；`Valid_Subj`/`Drop_Subj` 为派生值（清洗不过滤，通常 = Sample_Size / 0）；论文口径记 Note 列（`Paper_N:` 前缀）
- pair 粒度研究（Constable_2019 E4、Constable_2020）**单独处理**（P1–P2）

**已自动更新（2026-08）**：CSV 61 单元格 + JSON 44 处，两级校验全绿（详见文末「已解决」）。**第二轮（2026-08，用户决策）**：P15–P20 全部消解（CSV 再改 34 单元格：numTrials 统一 total、Practice_Trial/Country/City/License/Environmental_Info/Note）；P7–P9 经先前 agent 调查（3 个 exp JSON detail 注明实际行数特征，公开数据可能经作者预清洗）标记**已解决**；**P5 已解决（2026-08）**：Bed 条件码解码并经 psycharchives 聚合数据验证，Exp2 Clean 重建（Matching + Label 侧 Identity），见上表。本文件剩余未解决：**无（P3 已于 2026-08 第三轮解决，见下）**。

---

## 一、数据粒度与结构（P1–P6）

| 编号 | 研究 | 问题 | 说明 |
|---|---|---|---|
| ~~P1~~ | ~~Constable_2019_JEPHPP E4~~ | ~~pair 粒度~~ | **已处理（2026-08）**：保持人数口径 40/92 + Note 记 pair 粒度；E4 Female 14→26（论文 L173）；详见 P_Issues_Analysis_Plan.md A 组 |
| ~~P2~~ | ~~Constable_2020_ActaPsych E1~~ | ~~pair 粒度~~ | **已处理（2026-08）**：同上（Note 记 46 pairs/92 participants） |
| ~~P3~~ | ~~Constable_2019_JEPHPP E4~~ | ~~Clean 无法区分 Self vs Coactor（队友）~~ | **已解决（2026-08 第三轮）**：输入区 `E4InferentialDATA.csv` 的 `MatchParticipant` 列提供每 pair 的 match responder（=自己；20 pairs 中 10 Person1/10 Person2，每 pair 恒定）；用该映射重建 Label/Shape Std——自己→`Self`、队友→**`ingroup`**（2026-08 用户决策）、Team→`Self`（we 口径）、Stranger/StrangerTeam→`Stranger`（分布 Self 5120/ingroup 2560/Stranger 5120）；统计复现论文 L191（Self 674.3/Coactor 751.4/Stranger 733.6 ms vs 论文 670/744/728 ✓，差异=论文异常值排除）；Rmd E4 段重写（join MatchParticipant）、Codebook 枚举 `Self;ingroup;Stranger`、SKILL 记 ingroup 自定义值先例；`E4AllDATA.csv` 与 raw MD5 相同（P2Age/P1Age 为 pair 级年龄，不能区分归属） |
| ~~P4~~ | ~~Liang_2022_HumBrainMap~~ | ~~CSV 3 行（Exp1/2/3，各 Sample_Size=109）vs 实际 1 研究 3 TMS 组×2 阶段~~ | **已处理（2026-08，用户决策）**：1 实验 3 组，**每 group 一行**（Exp=1/1/1，subj_Group=LpSTS/DLPFC/sham，各填组内 N 38/35/36、组内性别、Drop=0）；行唯一性=Folder+Exp+Group（全库组间研究 9 行→21 行同步展开，见 P_Issues_Analysis_Plan.md 组展开节）；详见 P_Issues_Analysis_Plan.md B 组 |
| ~~P5~~ | ~~Schaefer_2019_JCogPsych E2~~ | ~~Clean 无 Shape/Label/Matching 列（仅 ACC 等）~~ | **已解决（2026-08）**：raw 导出无刺激内容列（target/flanker/targetform 全空），仅 Condition(=Bed) 条件码 + MT4.ACC/RT；**Bed 解码**：2 字母码，第 1 字母=label 身份（i/m/b/n=Ich/Mutter/Bekannter/Nichts），第 2 字母=匹配状态（m/n）——经 psycharchives 聚合 SPSS（列名 RTim/RTin/RTmm/RTmn/RTbm/RTbn/RTnm/RTnn）验证（288 被试-条件单元 MAE 13.8 ms）；**Clean 重建**：补 Matching + Label 侧 3 级 Identity（9 列），Shape 侧不可恢复（每被试 shape-label 分配未记录，论文按 label 归类 nonmatch）；psycharchives group1=group2（Exp1 重复上传）、group3=Exp3、Exp2 无仓库版本；V1–V4 版本 Ich 24 匹配/12 不匹配（原始版 18/18）；Codebook 重写 + exp JSON detail 注明 + Rmd 段同步 |
| ~~P6~~ | ~~Kolvoort_2020_HumBrainMap E1~~ | ~~缺 `*_subj_info.csv` 文件~~ | **已处理（2026-08）**：实为命名问题——`..._Exp1_foreff_raw/subj_info.csv` 均存在且标准，git mv 改名为 `_Exp1_raw/subj_info.csv`（保留历史）；validator W4 消失 |

## 二、数据完整性（P7–P10）——**P7/P8/P9 已解决（2026-08），P10 已消解**

| 编号 | 研究 | 问题 | 说明 |
|---|---|---|---|
| ~~P7~~ | ~~Sui_2023_ConsciousCog E1~~ | ~~Clean 17974 行/20 被试 不整除~~ | **已解决（2026-08）**：exp JSON detail 注明——17974 行/20 被试 = 656–952 行/被试（预期 960 = 16 blocks×60；不完整 session 按最小预处理规则原样保留；公开数据可能经作者预清洗）；保持现状 |
| ~~P8~~ | ~~Kolvoort_2020_HumBrainMap E1~~ | ~~Clean 11051 行/31 不整除~~ | **已解决（2026-08）**：exp JSON detail 注明——11051 行/31 被试 = 203–380 行/被试（预期 400 = 4 blocks×100；不完整 session 按最小预处理规则原样保留）；保持现状 |
| ~~P9~~ | ~~Svensson_2023_QJEP E1~~ | ~~Clean 7370 行/65 不整除~~ | **已解决（2026-08）**：exp JSON detail 注明——7370 行/65 被试 = 45–120 行/被试（预期 120，仅 18 名被试满 120；保持现状；同条注记 CSV Valid_Subj=51/Drop=5 口径差异待查） |
| ~~P10~~ | ~~Wozniak_2018_PLOS E1~~ | ~~Clean 11676 行/18 不整除~~ | **已消解（2026-08）**：raw 12594 = 11676 正式（PracticeMode='No'，=Clean）+ 918 practice 行（每被试 54）；Clean 正确剔除 practice，每被试 672=CSV numTrials；exp JSON/Codebook 可注明 raw 含 practice |

## 三、Identity 映射（P11–P14）

| 编号 | 研究 | 问题 | 说明 |
|---|---|---|---|
| ~~P11~~ | ~~Constable_2019_JEPHPP E1–E4~~ | ~~CSV Self/Close/Others 列与数据映射不符（Close=We/Team）~~ | **已处理（2026-08，raw+论文交叉核对）**：CSV 三列=Std 6 类简写（Self 列含 group-self：E1–E3 `Self/We`、E4 `P1/P2/Team`；Close 留空——无 close-other；Others 不变）；SKILL 记 group-self 规则 |
| ~~P12~~ | ~~Lee_2023_Cognition E1/E2~~ | ~~Label_Standardized 用 'Friend'（不在 6 类词表）~~ | **已处理（2026-08）**：E1 Label_Std 'Friend'→'Close'（1128 行，与 Shape 侧一致；Rmd L4168 源头修正）；E2 £9/£1 货币刺激：Label/Shape Std 'NA'→'NonPerson'（各 2448 行）、English 补 '£9'/'£1'（mismatch 行按 Shape_Origin 修正 1224 行）；Codebook 枚举同步；详见 P_Issues_Analysis_Plan.md |
| ~~P13~~ | ~~Amodeo_2024_CABN E1~~ | ~~数据 label 用词 Bekende vs 论文 vriend~~ | **确认保留（2026-08）**：清洗 L3114 Bekende→Friend→Close 为明确选择（SKILL 映射：原文保留 Origin、English=Friend、Std=Close），不改，记录即可 |
| ~~P14~~ | ~~Constable_2019 E3/E4、Navon E2/E3、Qian、Sui_2023、Vicovaro 等~~ | ~~Label 侧 Standardized 缺失或粒度二分类~~ | **已处理（2026-08，raw+论文交叉核对）**：Constable E3/E4 Label_Origin 从 raw 恢复 4/5 值（E3 Self/We/They/You、E4 Person1/Person2/Team/Stranger/StrangerTeam）、English 统一四类术语（E4 字面 Person 1/2）、Std 二分类已由 P3 解决升级（E4 用 MatchParticipant 区分 Self/ingroup，见 P3 行）；Navon E2 Father 保持 Close（用户决策）；Qian/Vicovaro/Sui_2023/Navon E3 无信息丢失保持；Rmd/Codebook/SKILL 同步 |

## 四、口径与惯例（P15–P22）——**P15–P20 已解决（2026-08，用户决策），P21/P22 已处理**

| 编号 | 问题 | 涉及 | 处置（2026-08） |
|---|---|---|---|
| ~~P15~~ | ~~numTrials 库内口径不统一（per-block vs total）~~ | Constable 系列、Sui_2014、Vicovaro、Qian E2、Wozniak_2018 等 | **已解决（用户决策：统一用总试次，且应能按实验条件数整除出每条件试次数）**：CSV numTrials 更新——Constable_2019 E1–E3 96→**288**（3×96）、E4 80→**640**（8×80）；Sui_2014 E1–E4 60→**360**（6×60）；Vicovaro E1 240→**480**（2×240，E2 240 已是 total 不变）；Qian E1 144→**576**（4 sessions×144，Note 注明）、E2 100→**200**（2×100）；Hu_2020 312→**480**（匹配任务 8 条件×60，Note 注明）且 numBlocks 14→**2**。已为 total 口径不变者：Constable_2020（每人 240）、Constable_2021（384/192 论文 total；数据 768/384 = 2×numTrials，系颜色/文本色/位置平衡所致，Note 已注明）、Wozniak_2018（672）、Vicovaro E2（240）。exp JSON 保持 per-block 描述（结构信息仍准确） |
| ~~P16~~ | ~~Constable_2019 E4 Practice_Trial 口径~~ | CSV=50 vs 全文匹配练习 "21 or 41" | **已解决（用户决策）**：50 次是学习刺激映射的训练段（论文 L179），不属于匹配任务练习；匹配任务练习为 "21 or 41"（视 pair 信心，论文 L181）。CSV Practice_Trial 50→**"21 or 41"**（与 exp JSON 一致） |
| ~~P17~~ | ~~多任务论文口径~~ | Hu_2020、Liu_2023、Svensson_2023、Lee_2023 | **已解决（用户决策：仅考虑匹配任务；其他任务数据已纳入的暂且保留）**：各 numTrials/numBlocks 均已核对为匹配任务口径——Liu_2023 64 ✓、Svensson_2023 120 ✓（均为匹配任务 total）；Hu_2020 匹配任务 480（补全）；Lee_2023 数据即匹配任务（PMT1+PMT2，2 runs×48=96），补 numTrials=96、numBlocks=3、Practice_Trial=24（3 练习块×8）；分类/ANT 等其他任务数据未在库中（Lee 分类任务为论文主任务，库中仅匹配任务数据，exp JSON detail 已注明） |
| ~~P18~~ | ~~软件未披露惯例~~ | Constable 系列、Sui_2023、Kolvoort、Lee 等 | **已解决（按 SKILL.md 惯例）**：未披露 → CSV Environmental_Info 留空 + exp JSON Software='/'（Constable 系列/Sui_2023/Kolvoort/Svensson 已符合）；论文披露而 CSV 空的补齐——Lee_2023 E1/E2 Environmental_Info ''→**Testable**（与 exp JSON 一致） |
| ~~P19~~ | ~~Online 研究 Country/City 填法~~ | Perrykkad、Svensson_2023、Liu_2023 | **已解决（用户决策：Prolific 按惯例填 UK）**：Perrykkad（MTurk）→United States（批次 3 已改）；Svensson_2023（Prolific，论文 L45）→UK ✓（已对）；Liu_2023（Prolific，论文 L47）Country "United Kingdom"→**UK**、City "In United Kingdom"→**N/A** |
| ~~P20~~ | ~~Repo_Link/License 待确认~~ | Amodeo、Liang、Constable_2019、Liu_2023、Kolvoort | **已解决（用户决策：论文声明 request 的 License 暂不写）**：Amodeo（论文 L156 "available on reasonable request"）License "On request"→**空**；Kolvoort（论文 L336 request）License "On request"→**空**；Liu_2023（论文 OSF 公开 osf.io/4n6j7、OSF API license=None）License "On request"→**空**；Liang（CC BY-NC-ND，OSF 数据页声明）与 Constable_2019（No License，OSF 数据页声明）保留 |
| ~~P21~~ | ~~ACC 特殊码 Codebook 说明~~ | 多研究 | **已处理（2026-08，方案 A 全库统一编码）**：见上 |
| ~~P22~~ | ~~subj_info 结构~~ | Lee、Constable pair 系列 | **已处理（2026-08）**：见上 |

---

## 已解决（2026-08 自动更新，依据全文+原始数据；以下编号为当时版本，已重排）

**批次 1（可自动改数据侧错误）**：
- **CSV 30 单元格**：采集地（Kolvoort→Canada/Ottawa、Constable_2020→Hungary、Hu_2020→Beijing）、subj_Group 修正 3（Constable_2020=Partner;Stranger、Xu_2022=4 组、Vicovaro E2=self-symmetry;self-asymmetry）、试次字段 17（Svensson_2023/Dalmaso/Constable_2021 E2/Schaefer 等补全）、Practice 4（Qian E1 20、Feldborg 22、Haciahmet 24、Constable_2021 E1 4）、Valid_Subj 1（Constable_2021 E2 20→50）、软件 2（Perrykkad→Inquisit Web、Feldborg→Inquisit）、Journal 拼写 2（Wozniak_2018→PLOS ONE）
- **JSON 40 处**：paper DOI 去前缀 6、paper 采集地 7、exp Setting 词表 25（→Laboratory×22、→Online×3）、Liu Practice 具体化 1

**批次 2（N 口径 = 数据口径）**：7 研究 Sample_Size/Valid_Subj 更新为 Clean nSubj、Drop_Subj→0、论文口径记入 Note 列（`Paper_N:` 前缀）——
- Amodeo 67/67/0（Note: 70 recruited/66 behavioral/4 excluded）、Feldborg 102/102/0（Note: 84）、Perrykkad 334/334/0（Note: 328/40/288）、Hu_2020 44/44/0（Note: 2 studies 35/29 & 46/42）、Navon E3 28/28/0（Note: 27）、Navon E4 27/27/0（Note: 27/1/26）、Haciahmet 40/40/0（Note: 43/3/40）
- pair 研究（Constable_2019 E4、Constable_2020）按用户指示**单独处理**，不在批次 2 范围

**批次 3（P11/P12/P15 依用户指示，当时编号）**：
- **P11 Liang**：删除冗余 `Exp1_Clean.csv`（与 Exp1.1=dlpfc 组内容相同；git 跟踪可恢复，备份 /tmp/liang_trash/）
- **P12 Dalmaso**：CSV E2 Country Japan→**Italy**（E1 保持 Japan，全文 L59/L109）；paper JSON Country→**Japan, Italy**（跨文化两国）；City 均 N/A（全文未披露采集城市）
- **P15 Perrykkad**：CSV + paper JSON Country→**United States**、City→**/**（MTurk 在线，用户指示标美国；原 Australia/Clayton 为作者单位）

**批次 4（P11/P12 采集地，依 CEU 证据）**：
- **P11 Constable_2020 City**：CSV City Newcastle→**Budapest**、paper JSON City '/'→**Budapest**（依据：作者单位含 CEU L10/L13-14 + 匈牙利语被试/EPKEB/HUF L44；CEU 位于布达佩斯）
- **P12 Wozniak_2018 多国**：CSV + paper JSON Country→**Hungary**、City→**Budapest**（依据：CEU 伦理委员会批准 L54/138/182/294/340/358 六处——伦理机构=采集机构；原 Australia, Poland, Hungary 为作者履历无采集依据）

**验证**：validate_json_metadata EXIT=0（90 JSON）；validate_clean_csv 59 文件 0 ERROR/40 WARN（基线持平）；CSV 字节保真（diff 仅目标单元格）

**第二轮（2026-08，P15–P20 按用户决策消解）**：
- **P15（numTrials 统一 total）**：CSV 14 行 numTrials 更新（Constable_2019 E1–E3→288/E4→640、Sui_2014 ×4→360、Vicovaro E1→480、Qian E1→576/E2→200、Hu_2020→480、Lee_2023 ×2→96），Hu_2020 numBlocks 14→2；Constable_2020/2021、Wozniak_2018、Vicovaro E2 原值已是 total 不变；Constable_2021 数据 2×numTrials（颜色/文本色/位置平衡）与 Hu_2020 数据 360–600 行不齐、Qian E1 4 sessions 结构均记 Note
- **P16**：Constable_2019 E4 Practice_Trial 50→"21 or 41"（50 为学习映射训练段，非匹配任务练习）
- **P17**：多任务论文（Hu_2020/Liu_2023/Svensson_2023/Lee_2023）numTrials/numBlocks 全部核对为匹配任务口径；Lee_2023 补 numTrials=96/numBlocks=3/Practice_Trial=24
- **P18**：惯例确认（未披露 → CSV 空 + JSON '/'）；Lee_2023 ×2 Environmental_Info →Testable
- **P19**：Prolific 研究 Country=UK（Svensson ✓ 已对；Liu_2023 United Kingdom→UK、City→N/A）
- **P20**：论文声明 request 的 License 留空（Amodeo ×2、Kolvoort、Liu_2023 "On request"→空）；Liang/Constable_2019 数据页明确声明保留
- **P7–P9（行数不整除）**：先前 agent 已调查——3 个 exp JSON detail 注明实际行数特征（Sui_2023：656–952/被试 vs 预期 960；Kolvoort：203–380/被试 vs 预期 400；Svensson：45–120/被试 vs 预期 120，仅 18 人满 120），公开数据可能经作者预清洗、不完整 session 按最小预处理规则保留 → **保持现状，标记已解决**
- **P5（Schaefer Exp2 Clean 缺列）**：见第二节 P5 行——Bed 条件码解码（.sav 聚合验证 MAE 13.8 ms）→ Clean 重建（Matching + Label 侧 3 级 Identity，9 列）；Shape 侧不可恢复已注明；连带：Exp2/Exp3 CSV 行补 numTrials=144/numBlocks=3/Practice_Trial=48 + Self/Close/Others，Exp1 Close 列按 SKILL 惯例修正（'Mother/Acquaintance'→'Mother'，Acquaintance 属 Others 类）；Codebook 重写、exp JSON detail、Rmd 段同步
- **验证**：validate_json_metadata EXIT=0；validate_clean_csv 0 ERROR（58 文件，WARN 38 = 基线内，Exp2 缺 Shape/Label 列 2 条 WARN 系 Shape 侧不可恢复所致）；CSV 字节保真（diff 48 单元格，列集合 {numTrials, numBlocks, Practice_Trial, Environmental_Info, Country, City, License, Note, Self, Close, Others}）
