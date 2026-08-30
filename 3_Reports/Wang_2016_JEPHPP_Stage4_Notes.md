# Wang_2016_JEPHPP — 阶段 4 重建记录与 txt 转换后核对指南（2026-08）

> **本文档用途**：完整记录 Wang, Humphreys & Sui (2016, JEPHPP) 在 2026-08 阶段 4 的
> 重建过程与全部背景事实，并给出**待核对清单**。项目负责人已将输入区全部
> `edat2`/`emrg2` 转换为 E-Prime 文本导出（txt，预计存放于
> `1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_Raw/txt_exports/` 或另行指定）。
> **下个会话的 agent 应先完整阅读本文档**，再基于转换后的 txt 数据执行
> 「§7 待核对清单」。本文档是对 `3_Reports/Verifying_original_results_issues.md
> （Issue 3）」的补充；两者配合使用。

---

## 1. 论文与任务设计

- 论文：Wang, H., Humphreys, G., & Sui, J. (2016). Expanding and retracting from the
  self: Gains and costs in switching self-associations. *JEP: Human Perception and
  Performance, 42*(2), 247–256. DOI: 10.1037/xhp0000125
- 全文：`REF/Wang_2016_JEPHPP.md`（人工转换版）
- 设计：两个实验 + 一个 control（论文正文称 control，即 baseline）。每实验两阶段：
  - **Part 1 Association（学习）**：形状（square/triangle/circle，文件 C.bmp/S.bmp/T.bmp，
    counterbalanced 绑定）与身份标签（self/friend/stranger）配对学习，判断 shape-label
    对是否符合**初始**指派，学习到标准（时间因人而异，论文 M=2.38 min，0.90–5.80）。
  - **Part 2 Breaking/Switch（切换匹配）**：按**新指派**判断 shape-label 对是否匹配。
    切换映射：
    - Exp1：self→stranger、friend→self、stranger→friend（数据文件名 `_s→str`）
    - Exp2：self→friend、friend→stranger、stranger→self（数据文件名 `_s-f`）
  - **Control（baseline，仅 Exp1 有）**：独立被试，只接受 Part 2 指令后直接做匹配判断
    （无 Part 1 学习）。论文 N=22（13 男，19–32 岁，M=23.78）。
- 试次结构（Part 2）：fixation 500 ms → shape 100 ms → blank 200 ms → label 100 ms →
  response window 1,000 ms（Z/M 键，match/mismatch 键位 counterbalanced）→ feedback 500 ms。
  **8 blocks × 81 trials = 648 正式试次（9 条件 × 72）**；论文称含 9 practice trials。
- 论文 N：Exp1 = 21（3 男，19–27 岁，M=22）；Exp2 = 20（12 男，18–30 岁，M=23.70）；
  control = 22（13 男，19–32 岁，M=23.78）。

## 2. 数据来源与输入区布局（`1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_Raw/`）

| 路径 | 内容 | 备注 |
|---|---|---|
| `RawData_Exp1/` | 42 个 edat2（SelfAssociate/breaking，编号 3-24 缺 23）+ 2 个 emrg2 | 论文 Exp1 原始导出（二进制） |
| `RawData_Exp2/` | 50 个 edat2（SelfAssociate + breaking，编号 1-25） | 论文 Exp2 原始导出（二进制） |
| `RawData_Baseline/` | 31 个 edat2（AssoMatc_Self-{1-21,101-110}） | **疑似非论文 control**（见 §3/§7） |
| `Merge Data_Exp1 & Exp 2 & Baseline/` | 4 个二进制文件（emrg/emrg2）+ `Baseline Merge Data/`（Counter1-6.emrg2、Exp6_Merge_Baseline.emrg2、Matching Conditions.xlsx、Tip.docx） | E-Merge 合并产物（二进制） |
| `Wang_2016_JEPHPP_Exp1_Association.csv` | 作者 E-Merge 导出的 trial 级聚合：2050 行 = 21 人（3-24），列 ExperimentName/Subject/Age/Handedness/Sex/Identity/Shape/Target.ACC/Target.RESP/Target.RT | **重建核心数据源** |
| `Wang_2016_JEPHPP_Exp1_Switch.csv` | 13797 行 = 21 人 × 657（9 practice + 648 正式），多 Label/Identity 列 | **重建核心数据源** |
| `Wang_2016_JEPHPP_Exp2_Association.csv` | 1435 行 = 25 人 | **重建核心数据源** |
| `Wang_2016_JEPHPP_Exp2_Switch.csv` | 16200 行 = 25 人 × 648 | **重建核心数据源** |
| `AssoMatc_Self_archive/` | 原库内错误 Exp1 五件套（AssoMatc_Self 数据） | 归档，勿删除 |

要点：聚合 CSV 的 Identity 列 = **形状的 Part 1 身份**（逐被试固定，已与 association
数据交叉验证一致）；Exp1 Label 列大写（Self/Friend/Stranger）、Exp2 小写
（self/friend/stranger），保留原文。聚合 CSV **无 Block/Trial 序号列**、无 CorrectAnswer 列、
无 practice 标志；Exp1 Switch 每被试前 9 行为 practice（9 个 (Label,Identity) 组合各 1，
已逐被试验证）；Exp2 Switch 数据无 practice 行。

## 3. 重大发现：原库内 Exp1 五件套数据源错误（2026-08）

- **事实**：原 `Wang_2016_JEPHPP_Exp1_raw.csv`（→ Clean → subj_info）实为 **AssoMatc_Self
  任务**数据：31 人（编号 1-21 + 101-110）、2013-07~08 收集、单 block、每被试 378 行
  （Trial 1-7 循环 ×54）、含 `Stim_Person1-3`/`Stim_Reward1-3`（人+奖赏参数）、
  SubjCounterblance 1-6。与论文三实验**均不符**：任务结构（非 SelfAssociate/breaking）、
  人口学（31 人 14 男/M=22.9/19-29 vs 论文 Exp1 3 男、control 13 男、Exp2 12 男）、
  编号体系（1-21+101-110 vs Exp1 的 3-24）。
- **证据链**：旧 raw 的 Subject 编号与 `RawData_Baseline/` 的 31 个 edat2 **一一对应**；
  `Clean_Data.Rmd` Wang 段（L3433-3495）就是从该错误 raw 清洗的（仅列映射、无守卫）；
  CSV 行 Sample_Size=21（论文口径）与 Clean 31 人不符，长期只产生 validator W2 警告，
  被当作"已知口径差异"忽略。
- **错误根源**：在 Rmd 之前的 raw 生成环节（仓库外、无记录），疑似当时误选了
  RawData_Baseline 目录导出（AssoMatc_Self 与 SelfAssociate 文件名相似 + "Baseline"
  目录名误导）。AssoMatc_Self 恰好也是 shape-label 匹配任务（Label/Shape/Match/
  Target.ACC/RT 列齐全），Rmd 列映射"碰巧"适用，使错误一路未被发现。
- **处置**：旧五件套归档至 `AssoMatc_Self_archive/`；**AssoMatc_Self 数据的真实归属
  未确认**（可能是作者另一研究/未发表数据），保留待判定（§7-6）。

## 4. 2026-08 重建（当前库内状态）

- 脚本：`1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_clean.R`（从 4 份聚合 CSV 重建；
  引导块 source `1_Data/utils.R`；守卫：行数/被试数/Matching 1:3/practice 9 行/人口学）。
- 布局（多实验规范）：paper JSON + clean.R + `*_Raw/` 在研究根；`Exp1/`、`Exp2/`
  子文件夹各含五件套。
- Clean 列：Subject, Phase(Association/Breaking), Practice(1/0), Shape(bmp),
  Label(原文), Matching, Label 三级身份, Shape 三级身份, Response, RT_ms, RT_sec, ACC。
- **Matching 规则（规则 B，新指令映射）**：`Match = (Label == f(Identity))`，
  Exp1 f={Self:Stranger, Friend:Self, Stranger:Friend}，Exp2 f={Self:Friend,
  Friend:Stranger, Stranger:Self}。验证：双实验 match 试次 RT 按 label 均 self 最快
  （Exp1: 543/610/644 ms，Exp2: 559/593/624 ms），RM-ANOVA F=32.1/12.7 vs 论文
  43.29/17.35（同量级、方向一致、未精确）。
- **association 阶段**：作者聚合导出**无 Label 列**（仅 Identity=形状身份+Shape+ACC/RT），
  显示标签不可恢复 → Clean 的 Label/Matching 为 NA（用户 2026-08 决策：两阶段都入）。
- ACC/RT：无反应（RESP=="" 且 RT==0）→ NA；其余原样（ACC 1/0，RT ms）。
- subj_info：Age/Gender/Handedness 自聚合 CSV 提取（Exp1 21 人：3 男/18 女 ✓ 与论文一致；
  Exp2 25 人：10 男/15 女，M=23.52，18-30）。
- 校验：validate_json_metadata（103 JSON）EXIT=0；validate_clean_csv 67 文件 0 ERROR/38 WARN。

## 5. N 口径与决策记录（用户 2026-08 确认）

| 实验 | 数据口径（库内） | 论文口径 | 决策 |
|---|---|---|---|
| Exp1 | 21（3 男/18 女） | 21（3 男/18 女）一致 ✓ | 无冲突 |
| Exp2 | 25（10 男/15 女） | 20（12 男）分析，无排除名单 | **数据口径 25**，Note 记 Paper_N: 20 |
| control | 不入库（无 trial 数据） | 22 | **整行不入库**，等作者数据 |
| AssoMatc_Self | 非论文数据 | — | 保留输入区存档，不作任何实验数据 |

- CSV 行：Exp1 = ID 58（numTrials=648、Practice_Trial=9、numBlocks=8、Self/Close/Others、
  Note 说明重建）；**Exp2 = ID 89（新增行，Status=1，Paper_ID 留空**——deprecated 列勿新建值）。

## 6. 统计复现与 Issue 3（详见 Verifying_original_results_issues.md）

- 论文全部匹配任务统计 df(2,38) 隐含分析 N=20，与论文报告 N=21（Exp1）不符；
  Exp2 数据 25 人 > 论文 20 人。
- match 试次 RT 的 F：Exp1 32.1 vs 43.29、Exp2 12.7 vs 17.35——方向一致、同量级、
  未逐位精确复现（leave-one-out 最高 37.1）；疑因作者分析前未披露的试次/被试排除
  （论文未提 RT 异常值剔除）。
- Exp2 人口学不符（数据 10 男/15 女 vs 论文 12 男）——上传数据无法对齐论文分析样本。
- 处置：库内数据按聚合 CSV 重建、规则与论文设计一致；差异记录 Issue 3；
  **是否联系作者由项目负责人决定**。

## 7. txt 转换后的待核对清单（下个会话执行）

项目负责人将全部 edat2/emrg2 转为 E-Prime 文本导出。转换 txt 为 UTF-16LE 时可直接用
`1_Data/utils.R` 的 `read_eprime_txt`/`parse_header`/`parse_matching_blocks`（先例
`Orellana-Corrales_2021_APP_clean.R`）。核对按优先级：

1. **核对聚合 CSV 与 edat2 txt 的一致性**（Exp1/Exp2 全部被试）：Subject 编号、Identity/
   Label/Shape 值、Target.ACC/RESP/RT 逐值对比（先例：作者脚本逐值验证法）；确认
   聚合 CSV 无导出损失（重点：Exp2 的 practice 行是否真的不存在、Exp1 practice 前 9 行
   判定）。
2. **补 association 阶段 Label 列**：从 txt 恢复显示标签 → Clean 的 Label/Matching 填实
   （改写 clean.R 后重跑，关联 subj_info/Codebook/exp JSON）。
3. **用 txt 的 CorrectAnswer/Match 列直接验证规则 B**（§4），并核对 9 条件 × 72 试次结构
   与 8 blocks 划分（聚合 CSV 无 block 列，txt 应有 Block 信息）。
4. **论文统计量精确复现**：用完整 txt 数据（含 block/practice 标志、作者可能做过的
   试次排除）重跑论文分析（match/mismatch 的 error/RT ANOVA、Exp1 F=7.65/43.29、
   Exp2 F=3.93/17.35 等）；若能精确复现 → 更新 Issue 3 的结论。
5. **control（baseline）判定**：RawData_Baseline 的 31 个 AssoMatc_Self txt 到底是不是
   论文 control（22 人）？核对：任务结构（是否 8 blocks×81 匹配判断）、人口学
   （13 男/M=23.78/19-32）、与论文 control 统计（F(2,42) 等）对照。若确认是 control：
   按论文口径补 control 行（N=22）与五件套（可能需要用户决策 N 口径——数据 31 文件 vs
   论文 22）。若确认不是 control：维持 §3 结论（非论文数据）。
6. **AssoMatc_Self 数据身份再确认**：结合 txt（含完整变量名/程序版本/日期）判断其归属
   （可能是作者另一研究）；仍无法判定则维持"保留存档"。
7. **人口学补全**：edat2 header 的 Age/Sex/Handedness 可补全 subj_info 缺失值
   （Exp1/Exp2 已有，主要受益者是 AssoMatc_Self 31 人——若其将来入库）。
8. 核对完成后：更新 clean.R/Codebook/exp JSON/CSV（字节保真）→ 两级校验 EXIT=0 →
   更新本文档与 Issue 3/PROJ_STATE。

## 8. 相关指针

- 作者产物问题记录：`3_Reports/Verifying_original_results_issues.md`（Issue 3）
- 重建脚本：`1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_clean.R`
- 输入区聚合 CSV：`1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_Raw/`
- 库内产物：`1_Data/Wang_2016_JEPHPP/Exp1/`、`Exp2/`（五件套）
- 主索引：`1_Data/Dataset_inf.csv`（ID 58 = Exp1、ID 89 = Exp2）
- 全文：`REF/Wang_2016_JEPHPP.md`
