# Stage 3.1 四方交叉复核——未解决问题清单

对应 PROJ_STATE.md「阶段 3.1：无问题条目独立复核」。**21 研究 / 37 行全部复核完成**（样板 3 + 剩余 18），方法 = 机械比对（2_Code/stage31_crosscheck.py）+ REF 全文人工核对。

**处理原则（2026-08 确认）**：
- 自动修改依据 = **论文全文 + 原始数据**（JSON/CSV 均为衍生产物）
- **N 口径 = 数据口径优先**：`Sample_Size` = Clean 中被试总数；`Valid_Subj`/`Drop_Subj` 为派生值（清洗不过滤，通常 = Sample_Size / 0）；论文口径记 Note 列（`Paper_N:` 前缀）
- pair 粒度研究（Constable_2019 E4、Constable_2020）**单独处理**（P1–P2）

**已自动更新（2026-08）**：CSV 61 单元格 + JSON 44 处，两级校验全绿（详见文末「已解决」）。本文件仅保留**无法自动修改的问题**，编号 P1–P22。

---

## 一、数据粒度与结构（P1–P6）

| 编号 | 研究 | 问题 | 说明 |
|---|---|---|---|
| P1 | Constable_2019_JEPHPP E4 | **pair 粒度（单独处理）**：CSV Sample_Size/Valid_Subj=40（人）vs Clean nSubj=20（pair） | 全文 L173 "20 pairs (40 人)"；清洗代码 L1691 `Subject=Pair.Number`；subj_info 20 行 Pair_ID 结构 |
| P2 | Constable_2020_ActaPsych E1 | **pair 粒度（单独处理）**：CSV Sample_Size=92（人）vs Clean nSubj=46（pair） | 全文 L44 "46 pairs (92 participants)"；subj_info 46 行 Pair_ID 结构 |
| P3 | Constable_2019_JEPHPP E4 | Clean 无法区分 Self vs Coactor（队友） | 清洗代码 L1709-1710 将 Person1/Person2 均→"Individual_Self"；论文 L189 明确区分二者（自己 670ms vs Coactor 744ms）；pair 粒度下无法还原 |
| P4 | Liang_2022_HumBrainMap | CSV 3 行（Exp1/2/3，各 Sample_Size=109）vs 实际 1 研究 3 TMS 组×2 阶段 | 全文 L51 三组（LpSTS 38/DLPFC 35/sham 36）；行结构无法与磁盘 3 Clean 文件（Exp1.1=dlpfc/1.2=sham/1.3=psts）对应 |
| P5 | Schaefer_2019_JCogPsych E2 | Clean 无 Shape/Label/Matching 列（仅 ACC 等） | 机械比对 Shape_Std=['']、Matching=['']——数据异常，需查 raw/清洗段 |
| P6 | Kolvoort_2020_HumBrainMap E1 | 缺 `*_subj_info.csv` 文件 | 其余研究 subj_info 全覆盖；该研究缺 |

## 二、数据完整性（P7–P10）

| 编号 | 研究 | 问题 | 说明 |
|---|---|---|---|
| P7 | Sui_2023_ConsciousCog E1 | Clean 17974 行/20 被试 不整除 | 960 trials×20 应为 19200；差 1226 行待查 |
| P8 | Kolvoort_2020_HumBrainMap E1 | Clean 11051 行/31 不整除 | 4 blocks×100=400×31 应为 12400 |
| P9 | Svensson_2023_QJEP E1 | Clean 7370 行/65 不整除 | 120×65 应为 7800 |
| P10 | Wozniak_2018_PLOS E1 | Clean 11676 行/18 不整除 | 336(一种性别)×? 口径待查 |

## 三、Identity 映射（P11–P14）

| 编号 | 研究 | 问题 | 说明 |
|---|---|---|---|
| P11 | Constable_2019_JEPHPP E1–E4 | CSV Self/Close/Others 列与数据映射不符（Close=We/Team） | 论文 L91/L95 将 Me+We 合并为 self-referential；数据 We→Group-Self→Self；CSV Close=We/Team 语义为 group-self 非 close other |
| P12 | Lee_2023_Cognition E1/E2 | Label_Standardized 用 'Friend'（不在 6 类词表） | Std 词表应为 Close；且 E2 Shape/Label_Std 含 'NA'、E1 Label_Std 含 'NonPerson'——映射口径待定 |
| P13 | Amodeo_2024_CABN E1 | 数据 label 用词 Bekende vs 论文 vriend | 清洗代码 L3114 Bekende→Friend→Close 为明确选择；论文 L58 写 "vriend"（friend）；保留但记录 |
| P14 | Constable_2019 E3/E4、Navon E2/E3、Qian、Sui_2023、Vicovaro 等 | Label 侧 Standardized 缺失或粒度二分类 | 部分研究 Label_Std 为空列（需查是否 raw 有身份信息被丢弃）；Constable E3/E4 为清洗代码 case_when 二分类（与 E1/E2 细粒度不一致） |

## 四、口径与惯例（P15–P22）

| 编号 | 问题 | 涉及 | 说明 |
|---|---|---|---|
| P15 | numTrials 库内口径不统一（per-block vs total） | Constable 系列、Sui_2014、Vicovaro、Qian E2、Wozniak_2018 等 | 如 Constable_2019 96（per-block）vs Amodeo 360（total）；需定统一口径或每行注明 |
| P16 | Constable_2019 E4 Practice_Trial 口径 | CSV=50（训练 50）vs 全文匹配 practice "21 or 41"（L179/L181） | 两个数字分别对应训练与匹配练习，CSV 填哪个待定 |
| P17 | 多任务论文口径 | Hu_2020（matching+categorization）、Liu_2023（matching+recognition）、Svensson_2023（matching+ANT）、Lee_2023（matching+classification） | 各行 numTrials/numBlocks 对应产生数据那个任务；跨任务值不混填（需逐行核对口径） |
| P18 | 软件未披露惯例 | Constable 系列、Sui_2023、Kolvoort、Lee 等 | Environmental_Info 空 vs exp JSON Software='/'——未披露时留空 or '/' 需定惯例 |
| P19 | Online 研究 Country/City 填法 | Perrykkad（MTurk）、Svensson_2023（Prolific）、Liu_2023 | 在线被试无固定采集地——Country 填平台限制（如 UK）或 '/' 需定 |
| P20 | Repo_Link/License 待确认 | Amodeo（Repo 填论文 DOI，数据仅 request）、Liang（License=CC BY-NC-ND、Repo view_only 链接）、Constable_2019（License=No License、Note=Pair Number） | Human decision #4/#8：数据许可与公开性需数据页/OSF 确认 |
| P21 | ACC 特殊码 Codebook 说明 | Constable_2019（ACC=3）、Hu_2020（-1/2）、Dalmaso（2）、Xu/Sui_2023（NA）、Vicovaro（NA） | 枚举值存在但部分 Codebook 未解释含义（E-Prime 惯例 3=no response 等）；需补说明 |
| P22 | subj_info 结构 | Lee（None 空列）、Constable pair 系列（P1_Age/P2_Age 行=pair 而非个人） | 粒度与列结构与 CSV 个人数口径不一致（见 P1–P2） |

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
