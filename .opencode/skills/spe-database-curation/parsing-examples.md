# 原始数据解析与验证先例（附属参考文件 — 按需读取）

本文件是 `SKILL.md` 的附属参考：遇到特定数据格式/作者产物特征时，按主文件「原始数据解析与验证先例」速查表定位到对应节，只读所需节即可。每条先例 = 规则 + 案例 + 出处，来自 2026-08 阶段 4/5 与 2026-09-01 各研究入库沉淀。

## E-Prime

### `.txt` 日志（UTF-16LE）

通用解析函数 `read_eprime_txt` / `parse_header` / `parse_matching_blocks` 已入 `1_Data/utils.R`（先例 `Orellana-Corrales_2021_APP_clean.R`）：

- `readLines(encoding="UTF-16LE")` 直接读取（`rawToChar` 遇内嵌 nul 报错勿用）
- 按 `*** LogFrame Start/End ***` 切块
- **中断被试末尾可有未闭合块**（无 End 标记、无 MT.ACC 记录的未完成试次）→ 解析允许 start 比 end 多 1 且跳过无记录块（案例：Orellana-2021 Exp2 nonwords-01 仅 68/128 试次，源数据问题）

### 合并导出（.xlsx）列陷阱（2026-09-01 Mcivor 先例）

E-Merge/DataAid 式合并导出可能含：

1. **语义重复列**（Mcivor 的 `Label` vs `Label2`——正式试次 `Label` 全空、`Label2` 才有值；CellLabel 内嵌身份为小写如 'Happyselfmatch'，与 Label 列大写 'Self' 不同）——取用前逐列统计空值/取值分布，勿假设两列等价
2. 导出的 `Group` 字段可能**不是设计/临床分组**（Mcivor 的 Group 0/1/2 与临床分组完全无关，控制/抑郁两组均含多种码）——临床/设计分组以作者问卷/诊断清单文件（如 M.I.N.I.）名单为准，并用论文统计量（年龄 M/SD、性别计数、量表均值、共病计数）逐位复现验证映射
3. 会话元数据列（StudioVersion 等）可能仅部分行有值（软件版本以论文/多数证据为准，矛盾记 exp JSON detail）
4. 日期单元格三类混杂（'MM-DD-YYYY' 文本 / ISO 日期时间 / Excel 5 位序列号）——subj_info 统一 ISO 前先分诊（序列号 as.Date(origin="1899-12-30")）

### `.edat2`/`.emrg2`（二进制，库内不可解析）

无现成二进制解析工具（E-DataAid/E-Merge 官方唯一；rprime/convert-eprime/eMergeR 均只处理文本导出；pyedat2 pip 不可装；olefile 可开 OLE2 容器但私有流编码无公开文档）——**用户决定自行将 edat2/emrg2 转为 txt**（案例：Wang_2016 交接文档 `3_Reports/Wang_2016_JEPHPP_Stage4_Notes.md` §7 待核对清单；Bukowski Exp1 待用户转换）。

## PsychoPy

### 无响应 = 字符串 "None"（2026-08-30 Hobbs 教训）

Builder 导出无响应试次的 `keys` 列填字符串 `"None"`（不是 NA）——读取后须 `resp[resp == "None"] <- NA` 再判 ACC（否则无响应被误编码为 0）。pandas 读 csv 时 "None" 会被默认 na_values 当 NaN，掩盖该问题——以 xlsx（readxl 读原值）为准核对。

### 每被试导出（宽格式 csv）（先例 `Orellana-Corrales_2023_QJEP_clean.R`）

- v1~v8 子目录 = 实验版本；RT 为秒需 ×1000 取整
- **被试编号需与作者合并脚本一致**（本库案例：作者 1-mergeAndSubset.R 按 v1→v8 文件序 rbind 后 `factor(date, levels=unique(date))` 编号，清洗脚本须复刻否则无法与作者聚合文件对齐验证）
- 刺激字段（label/bild 等）可能仅存在于原始导出而被作者合并产物丢弃——raw 重建优先用原始导出而非合并产物

### 同数据 xlsx 与 csv 可能有表示层差异（2026-08-30 Hobbs 教训）

作者同时提供 xlsx/csv 时以**作者清洗脚本读的那个为准**（Hobbs 的 Associative_cleaning.R 用 xlsx；其 csv 的 NA 编码、形状分配列值不同）。清理前先逐列对比两版本，勿默认等价。

### RT 单位判断（2026-08-30 Vicovaro 教训）

PsychoPy 导出 RT 通常是秒，但作者可能已 ×1000 存为 ms——**以数值量级判断**（匹配任务 RT 正常 300-1000 量级；Vicovaro_2024_PeerJ 的 Exp2 值域 0.33-1082 与 Exp1 的 ms 值域一致 → 已是 ms，勿按秒再乘 1000；误乘后 SPE 均值变 5×10^5 即暴露）。负值（提前按键）与超窗值按最小预处理保留。

## MATLAB / Psychtoolbox

### 空格分隔 `.dat` 导出（2026-08-31 Wozniak_2020 先例）

库内首次遇到的专有格式：

1. **列定义权威 = 实验脚本的 `fprintf` 格式串**（本案例 RUN.m 一行 fprintf 定义全部 22 列：被试/实验/键映射/试次/按键/标签名/标签码/形状/排列参数/性别/匹配状态/ACC/RT 等）——先读脚本再解析，勿猜列
2. 读取用 `read.table(sep="", colClasses="character")` 全字符读入后逐列语义解码（混合文本列无法整体数值化）
3. 练习试次可能根本不写入导出文件（本案例 .dat 只有 270 正式试次，24 练习不落盘——不要误判"缺数据"）
4. 无反应由作者约定键表示（本案例 'x'，RT 为伪值 ~2000 ms）→ 库内 ACC=NA、RT_ms=NA，raw 保留原值
5. 多实验混存同一目录时按被试编号段区分（1xxx/2xxx/3xxx = 实验 1/2/3）

### Excel 外链公式的缓存值（2026-08-31 Wozniak_2020 先例）

作者聚合 xlsx 的单元格可能是**外链公式**（如 `='[1]General info'!D73`，引用未随附的工作簿）——openpyxl `data_only=True` 或 readxl 可读**缓存值**（作者在有源文件的机器上保存过），无缓存时读 NA；公式字符串本身（data_only=False）不是数据。此类 xlsx 常**双重用途**：作者产物验证对象（逐值对比）+ subj_info 人口学来源（Age/Gender/Handedness/FaceRace 等）。

### 多任务同构脚本 + 每试次标签确定性恢复（2026-09-01 Wozniak_2022 先例）

一个研究含两个任务（标准 self-matching + 伪词任务），脚本同构（MD5 相同）、.dat 列语义部分不同：

1. **配对码（pairing code）唯一决定 (shape, personlabel, type)**：testlist 第 1 列 objnumber（1-9）→ 1/2/3 正确配对、4-9 错误配对；`personlabel 索引 = f(objnumber)`（{1,5,9}→1、{2,6,7}→2、{3,4,8}→3）、`shape 槽位 = f(objnumber)`（{1,4,7}→1、{2,5,8}→2、{3,6,9}→3）。
2. **每试次呈现标签未写入 .dat 但可恢复**：标签数组（V10-V12 槽位标签 / 伪词按 version 分配）逐行重复写入，呈现标签 = 标签数组[f(objnumber)]——**确定性恢复后生成单值 Label 列**（Label1/2/3 式宽格式 = 槽位绑定、被试内恒定，≠ 每试次呈现标签，勿混用）。
3. **验证法**：① .dat 与库内 raw 逐行 0 差异；② 按作者聚合脚本口径（正确试次 RT 均值 + MAD/200 上下限）重算其 xlsx 逐格对比——命中即确认解码正确；不命中先怀疑**作者脚本自身笔误**（Wozniak_2022 perm6 sequence 数组重复 5 缺 8，9 名 perm6 被试的 NM/NMLab 两格全偏，45/54 被试 9 格 100% 命中）。
4. **伪词任务身份映射**：伪词无翻译（English 层保留原样），Standardized 层 = 该伪词在该被试槽位分配中的身份（V13 直给自我伪词）；两任务合并入库时用 `Task` 列区分（self-matching / self-pseudoWords），同一 Clean 文件（每被试两段各 360 行）。

## 作者共享产物特征

### 文件级预清洗 → 每被试试次数低于设计值（2026-09-01 Svensson_2022 先例）

作者共享的 xlsx/csv 可能已按分析口径排除试次（本案例：RT min = 200 恰为论文 "faster than 200 ms excluded" 口径、无 NA 行 → 未响应试次也被排除；每被试试次数 118-199/200、215-399/400，缺失原因论文/OSF 未说明）——**原样入库（最小预处理，不补滤不补行）**，numTrials 填设计值（论文口径），预清洗事实记 exp JSON detail + CSV Note（Golubickis 同款先例：文件层缺 4.8%）；不要按缺失率推断"数据不完整"而拒绝入库。

### 作者共享文件可能按条件/ACC 排序而非试次顺序（2026-09-01 Svensson_2022 先例）

1. Exp3 文件按 (ACC desc, block, trial number) 排序——正确试次全部在前、错误在后，且 block 内 trial 1-200 升序 → Block 由**每个 ACC 组内 trial 序号重启**重建（每 ACC 组恰 2 段），两 ACC 组 expectancy 顺序一致则对齐可靠（守卫：两组长/序一致、重启次数 = block 数-1）
2. Exp2 文件按 block（expectancy run）排序——每被试恰 2 run → Block = run 序号
3. 排序键不明确时先检查行内 trial 序号单调性再决定 Block 派生方式；Block 是 block-level 条件（如频率操纵）分析的必要列，值得派生并在 Codebook/JSON 注释

### 聚合验证的 round 边界（2026-08-30 Hobbs 教训）

库内 RT_ms 取整（round(rt×1000)）与作者原始 rt 阈值（如 <200 ms 排除）在边界行（如 199.67 ms → round 200）可能一保留一排除——验证脚本按作者精确值判定边界行，差异为 round 显示差异（<0.5 ms）非数据错误；库内保留原值。

### 作者聚合产物的身份编号体系先验证再对比（2026-08-31 Wozniak_2020 教训，详见 Issue 4）

作者 xlsx/聚合文件的编号可能与库内解析不对称（案例：cue 用固定内部码、face 用槽号/permutation 决定，仅 perm=1 的被试一致）——先用少量被试枚举排列（按 permutation 等设计参数）找对齐规则，再全量逐值对比，直接按假设对比会大量误报。

### 聚合文件 "ER"/"ACC" 类列语义先确认（2026-08-31 Wozniak_2020 教训）

Wozniak xlsx 的 ER 列实为正确率，且按「正确且 RT 有效」计数，非错误率。

### 作者脚本实现口径 vs 论文文字可能不一致（2026-08-31 Wozniak_2020 教训）

Wozniak 论文 "2.5 MAD" 排除 vs 脚本硬编码 highestRT=1500 ms——逐值验证用脚本实现口径，差异记录进 Issue。

### 逐被试导出文件名 vs 行内 Subject 编号不一致（2026-08-31 Wozniak_2020 教训）

作者整理时重命名过文件时，以作者最终产物（如 xlsx 被试列表）口径为准定被试 ID，行内原值保留 raw 并记录（Wozniak 3 个 .dat：1010/2008/2011 行内 SubNum=1110/2004/2010）。

## 作者脚本逐值验证法（强验证，强烈建议）

清洗脚本解析结果与作者合并/聚合产物逐值对比（subject 编号、条件、ACC、RT×1000 取整），stopifnot 全等；再按作者分析口径（正确试次、RT 阈值、每被试 Tukey 上限——**注意不同研究上限倍数不同**：Orellana-2021 用 q3+3×IQR、QJEP 用 q3+1.5×IQR，hinge 法分位数）核对论文**描述性统计**（论文报告的均值/正确率/方向，±几 ms 内即一致）。

- **2026-08-30 用户指示：后续入库只核对描述性统计，不复现统计检验/回归模型结果**（Hobbs 为最后一例全量复现，其 Table 2 48 系数核对脚本 `2_Code/hobbs_verify/verify_stats.R` 保留作参考）；论文统计检验与库内数据不一致的问题仍照常记录于 `3_Reports/Verifying_original_results_issues.md`。
- 2026-08 QJEP 案例证明逐值核对的价值：作者 data_clean.csv 列错位（脚本打印顺序与表头不一致）导致论文统计基于错位数据，被逐值核对发现；核对脚本固化于 `2_Code/qjep_verify/`，详情报 `3_Reports/Verifying_original_results_issues.md（Issue 1）`。
- d′ 描述性核对口径试配（2026-09-01 Mcivor 先例）：论文只报告派生描述统计（如 d′ 均值）时，按论文公式实现后对口径试配（FA 含/不含无反应、RT 剔除基准），命中论文报告值即确认作者口径（Mcivor：FA 含无反应（ACC≠1 on nonmatch）+ onset-RT<200 剔除命中论文控制 happy 1.70 / neutral 1.56；核对脚本固化 2_Code/mcivor_verify/）；论文文字与数据的小差异（如 RT<200 剔除比例 "<0.0001%" vs 实际 0.04%；问卷量表范围文字 vs 数据）记 exp JSON detail/CSV Note，不建 Issue（Golubickis Appendix 计数差异同款处置）。

## 验证时机（2026-08-31 Wozniak 先例）

作者聚合逐值验证宜在**清洗脚本产出后、CSV 行收口前**完成——数据层证据（列解码、身份映射、ACC/RT 口径）先行确认，发现问题时只需改清洗脚本重跑，避免 CSV/JSON 已写死后再返工；论文方向性核对与 CSV 收口可同步进行。
