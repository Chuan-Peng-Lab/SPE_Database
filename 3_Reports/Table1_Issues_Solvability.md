# Table 1 问题可解性分析（基于 1_Data/ 现有内容）

**初稿日期**: 2026-08-10
**复核日期**: 2026-08-27（CSV Exp 回填、subj_info 全覆盖、Pan 样本量回填后两次重渲染 `Generate_Table1.qmd` 刷新问题清单）；2026-08 增补复核（Sui_2015_unpub Exp2 排除测试被试 subject 0、CSV 21→20 后重渲染，问题清单 111 行不变；Ps4E2 N 数值已一致）
**来源**: `Generate_Table1.qmd` 输出的问题清单（`3_Reports/Output/table1_problems.txt`，2026-08-27 重渲染 118 → 111 行；2026-08 重渲染仍 111 行，其中 Sui_2015_unpub Exp2 N 行由「稿件 20 (—) vs qmd 21」变为「稿件 20 (—) vs qmd 20」，数值一致、剩余为稿件 (—) 格式噪音）逐一核查 `1_Data/` 中已有内容后的可解性判定。
**关联**: 本文档与根目录 `PROJ_STATE.md` **双向关联**——未解决问题清单与处理进度以 PROJ_STATE.md 为准；本文档给出逐项可解性判定（可依 1_Data/ 自动确定 / 需人工或外部来源）。
**结论**: 大部分问题可依据 `1_Data/` 中的原始数据/元数据找到权威答案；少数需要人工确认（含外部来源或稿件口径）。

---

## 一、可依据 1_Data/ 内容确定答案的问题

### A. Exp 编号不一致（11 条）— 全部可解 ✅（全部为稿件标注错误）

证据来源：**文件夹 ExpN 子目录结构 + `*_ExpN_Clean.csv` 文件名 + Exp JSON 文件名**。

| Paper_ID | 稿件(错) | qmd(对) | 文件夹证据 |
|---|---|---|---|
| P5E1 | Exp4 | Exp1 | `Constable_2019_JEPHPP/Exp1/` |
| P5E2 | Exp4 | Exp2 | `Constable_2019_JEPHPP/Exp2/` |
| P5E3 | Exp4 | Exp3 | `Constable_2019_JEPHPP/Exp3/` |
| P46E1 | Exp2 | Exp1 | `Constable_2021_CogEmo/Exp1/` |
| P46E2 | Exp4 | Exp2 | `Constable_2021_CogEmo/Exp2/` |
| Pu4E2 | Exp1 | Exp2 | `Kirk_2025_BritJPsy/Exp2/` |
| Pt3E2 | Exp1 | Exp2 | `Liang_2022_HumBrainMap/Exp2/` |
| Pt3E3 | Exp1 | Exp3 | `Liang_2022_HumBrainMap/Exp3/` |
| Pt9E2 | Exp1 | Exp2 | `Wozniak_2022_PsychRes/Exp2/` |
| Pt9E3 | Exp1 | Exp3 | `Wozniak_2022_PsychRes/Exp3/` |
| Pt27E2 | Exp1 | Exp2 | `Martinez-Perez_2024_ConsciousCog/Exp2/`（CSV 已按合作者确认由 Exp1 修正为 Exp2） |

**推荐**: 稿件中 P5E1–P5E3 的 "Exp4" 改为 Exp1/2/3；P46E1/2 的 Exp2/Exp4 改为 Exp1/2；Kirk（Pu4E2）、Liang（Pt3E2/E3）、Wozniak（Pt9E2/E3）、Martinez-Perez（Pt27E2）的 "Exp1" 改为对应实验号。

**已消解（2026-08，不再计入）**: 初稿（2026-08-10）的 13 条中，8 条属「CSV Exp 空」类（Lee ×2、Orellana-Corrales_2021_APP ×2、Schaefer ×2、Sun ×1、Svensson ×1，问题清单显示为「稿件 ExpN vs qmd 空」）——CSV 空 Exp 已按 Paper_ID 的 E 后缀回填，回填后与稿件一致，条目从问题清单消失（table1_problems.txt 118 → 111 行）；P5E4 为一致参考行。仅剩 Scheller_2026_elife 的 CSV Exp 空白（无 Paper_ID 无法推导）待人工确认。

### B. N（被试数）不一致（43 条）— 大部分可解 ✅

证据来源：**`*_subj_info.csv` 数据行数**（最权威，每行 1 名被试）。

| Paper_ID | 稿件 | qmd(CSV) | subj_info 行数 | 判定 |
|---|---|---|---|---|
| P5E1 | 40 (14/14) | 28 (12/16) | **28** | qmd 对，稿件错 |
| P5E2 | 40 (14/14) | 28 (6/22) | **28** | qmd 对，稿件错 |
| P5E3 | 40 (14/14) | 28 (8/14) | **28** | qmd 对，稿件错 |
| P46E1 | 56 (25/31) | 56 (28/28) | **56** | 总量对，性别比稿件 (25/31) 更可信，需人工核对 |
| P46E2 | 40 (14/14) | 56 (25/31) | **56** | qmd 对，稿件错（稿件抄了 P5E 的行） |
| P6E1 | 56 (25/31) | 92 (19/73) | **46** | 均不符，raw 为 46，需人工确认（可能含排除） |
| Ps2E1 | 23 (—) | 23 | **23** | 一致，可补 M/F |
| P34E1 | 31 (—) | 31 (17/14) | **31** | 一致，可补 M/F |
| Pt18E1 | 20 (—) | 20 (12/8) | **20** | 一致，可补 M/F |
| Pt28E1 | 70 | 70 (49/21) | **67** | raw=67 与稿件/qmd 均不符，需人工确认 |
| Pt13E1 | 84 (—) | 84 (13/70) | **102** | raw=102 与两者均不符，需人工确认 |
| Pu2E1 | 32 (5/27) | 40 (19/21) | **40** | qmd 对（raw=40），稿件错 |
| Pn13E1 | 26 (9/18) | 13 (3/10) | **13** | qmd 对，稿件错 |
| Pn13E2 | 26 (9/18) | 27 (9/18) | **27** | qmd 对，稿件错 |
| Pn13E3 | 26 (9/18) | 27 (12/15) | **28** | 均不符，raw=28，需人工确认 |
| P51E1 | 26 (7/19) | 26 (10/16) | **24** | 均不符，raw=24，需人工确认 |
| P54E1 | 35 (—) | 32 | **32** | qmd 对 |
| P54E2 | 35 (—) | 36 | **36** | qmd 对 |
| P54E3 | 35 (—) | 35 | **35** | 一致 |
| Ps3E1 | 20 (—) | 24 | **24** | qmd 对 |
| Ps5E1 | 20 (—) | 24 | **24** | qmd 对 |
| Ps5E2 | 20 (—) | 18 | **18** | qmd 对 |
| Ps5E3 | 20 (—) | 22 | **22** | qmd 对 |
| Ps5E4 | 20 (—) | 20 | **20** | 一致 |
| Pt6E1 | 104 (14/90) | 30 (14/16) | **30** | qmd 对（稿件抄错） |
| Pt6E2 | — | — | **95** | 稿件无此行问题，参考 |
| Pt9E1 | 18 (0/18) | 23 (7/11) | **18** | 稿件对，qmd 错（CSV 需改） |
| Pt9E2 | 21 (—) | 21 (6/12) | **18** | raw=18 与两者均不符，需人工确认 |
| Pt9E3 | 18 (—) | 18 (0/18) | **18** | 一致 |
| P95E1 | 20 (9/9) | 19 (9/9) | **18** | 均不符，raw=18，需人工确认 |
| P95E2 | 20 (—) | 20 (9/9) | **18** | 均不符，raw=18，需人工确认 |
| Pt10E1 | 380 (—) | 380 (198/182) | **347** | raw=347 与两者均不符，需人工确认 |
| Pt7E1 | 328 (—) | 328 | **288** | raw=288 与两者均不符，需人工确认 |
| Pt27E2 | 32 | 32 (5/27) | **32** | 一致 |
| Pu4E2 | 126 (—) | 126 | **90** | subj_info=90（Kirk Exp2，2026-08 补齐），与 qmd/稿件 126 均不符，需人工确认 |
| Pu5E1 | 65 (—) | 57 | **47** | subj_info=47（Lee Exp1，2026-08 补齐），三方均不符，需人工确认 |
| Pu5E2 | 65 (—) | 65 | **51** | subj_info=51（Lee Exp2，2026-08 补齐），与 qmd 65 不符，需人工确认 |
| Pu9E1 | 36 (7/29) | 34 (9/25) | **34** | subj_info=34（2026-08-27 由 Clean.csv 唯一 Subject 生成，无原始数据，人口学 /），**qmd 对**，稿件错 |
| Pu9E2 | 36 (7/29) | 34 (11/23) | **33** | subj_info=33（Clean 生成），与 qmd 34 / 稿件 36 均不符，需人工确认（CSV Sample_Size=34 亦不符） |
| Ps4E1 | 21 (—) | 20 | **20** | subj_info=20（由 *_Raw/ 人口学记录生成；80 个 .mat 全为正常被试），**qmd 对**，稿件 21 无数据支持 |
| Ps4E2 | 20 (—) | 20 | **20 正常** | **已解决（2026-08）**：subject 0（测试运行，.mat 内部编号 0/默认人口学/按键反转）已从 Clean 排除（Exp2_Clean.csv 9600→9360 行），CSV Sample_Size/Valid_Subj 已 21→20，subj_info 已删 subject 0 行；稿件 20 与数据一致，清单余行为稿件 (—) 格式噪音 |
| Pu8E1 | 40(—) | 40 | **40** | subj_info=40（2026-08-27 由 raw.csv 重新生成，替换原 1 行异常文件），**一致**（CSV Sample_Size/Valid_Subj 已补 40） |
| Pu6E1 | 506(—) | — | **334** | subj_info=334（与 raw 一致），稿件 506 可能是全部样本，需人工确认 |
| Pu10E1 | 25 (7/18) | 65 (20/45) | **65** | subj_info=65（Svensson Exp1，2026-08 补齐），**qmd 对，稿件错** |

### C. Language 不一致（8 条）— 大部分可解 ✅

证据来源：**raw CSV 中的身份标签实际字符**（最权威）+ CSV `Stim_language`。

| Paper_ID | 稿件 | qmd(CSV) | raw 数据证据 | 判定 |
|---|---|---|---|---|
| P5E1 | English | Hungarian | raw 含列值 `Hungarian` | **qmd 对**，稿件错 |
| P5E2 | English | Hungarian | 同上 | **qmd 对**，稿件错 |
| P5E3 | English | Hungarian | 同上 | **qmd 对**，稿件错 |
| P6E1 | English | Hungarian | raw 无直接语言标记 | CSV 为 Hungarian，需人工 |
| Pu2E1 | Spanish | Japanese | raw 含 `esperimento`/`si`/`no`（意大利语） | **均不符**，实为 Italian，需人工确认 |
| Pu2E2 | Japanese | Italian | raw 含 `yes`/`no`（英语化） | CSV=Italian，需人工 |
| Pu8E1 | Chinese | NA | raw 含 `自我`/`他人`/`朋友`（中文） | **稿件对**（Chinese），CSV 需补 |
| Pt10E1 | Chinese | English | — | 需人工确认（Zhang_2023_NeuroImage） |

### D. Stimulus 不一致（8 条）— 大部分可解 ✅

证据来源：**JSON `Stimulus_Properties.Shape` + raw 数据形状名**。

| Paper_ID | 稿件 | qmd(CSV) | 证据 | 判定 |
|---|---|---|---|---|
| P46E2 | geometric shape | grey scale squares | JSON Shape="Luminance squares used, no geometric shapes" | **qmd 对**，稿件错 |
| P6E1 | grey scale squares | geometric shape | JSON 无明确形状 | CSV 与稿件相反，需人工 |
| Pu2E1 | geometric shape | face | JSON Shape="faces (300×300)" | **qmd 对**，稿件错 |
| Pu5E1 | geometric shape/ nm. | geometric shape | 无 JSON | 稿件更具体，需人工 |
| Pu5E2 | geometric shape/ nm. | geometric shape | 无 JSON | 同上 |
| Pu10E1 | geometric shape | NA | 无 JSON | CSV 需补，需人工 |
| Ps4E1 | geometric shape and face | geometric shape | 无 JSON | 需人工 |
| Ps4E2 | geometric shape | geometric shape and face | 无 JSON | 需人工 |

### E. Trials 不一致（11 条）— 部分可解 ⚠️

证据来源：**JSON `Block_Structure.Trial_number` + CSV `numTrials`**。

| Paper_ID | 稿件 | qmd(CSV) | JSON 证据 | 判定 |
|---|---|---|---|---|
| P5E1 | 80 | 96 | "96 trials per block (288 total)" | **qmd 对**（稿件 80 抄自 Exp4） |
| P5E2 | 80 | 96 | 同上 | **qmd 对** |
| P5E3 | 80 | 96 | 同上 | **qmd 对** |
| P46E2 | 80 | NA | "384 trials total (96 per block)" | qmd 需补 384/96，稿件 80 错 |
| P51E1 | 100 | 144 | JSON "144" / "200" | 需人工确认口径 |
| Ps3E1 | 60 | 40 | 无 JSON | 需人工 |
| Ps4E2 | 60 | 40 | 无 JSON | 需人工 |
| Pu2E1 | 240 | NA | "360 trials (180 per block)" | qmd 需补，稿件 240 待确认 |
| Pu9E1 | 240 | NA | 无 JSON | 需人工 |
| Pu9E2 | 240 | NA | 无 JSON | 需人工 |
| Pu10E1 | 400 | NA | 无 JSON | 需人工 |

### F. Country 不一致（2 条）— 部分可解 ⚠️

| Paper_ID | 稿件 | qmd(CSV) | 证据 | 判定 |
|---|---|---|---|---|
| Pu10E1 | United Kingdom | UK | paper JSON 无 Country；CSV=UK | 表述差异（UK == United Kingdom），**视为一致** |
| Pt9E1 | Australia | NA | paper JSON Country=Hungary | **稿件错**，应为 Hungary（qmd 需补） |

### G. Exp_Implement 不一致（25 条）— 部分可解 ⚠️

证据来源：**JSON `Physical_Environment.Setting` + `Equipment.Software` + CSV `Environmental_Info`（软件名）**。

| 情况 | 数量 | 证据 | 判定 |
|---|---|---|---|
| JSON Setting 为 `/` 或缺失，但 Software 明确（E-Prime/Pavlovia） | ~8 | Software 可推断：Pavlovia→Online；E-Prime→Lab（大概率） | **部分可解**（Lab 需谨慎） |
| JSON Setting 明确（如 "Sound-proofed rooms", "Online experiment"） | 3 | `Schaefer_2019_JCogPsych`(Lab)、`Vicovaro_2022_JEPHPP`(Mixed，Setting 含 "Online experiment" 与 "Dimly lit room") | **可解** |
| CSV Environmental_Info 有软件名（E-prime→Lab, Gorilla→Online） | 多数 | 见 CSV `Environmental_Info` 列 | **可解**（以软件推断） |
| 完全无证据（JSON Setting=/ 且无软件） | 剩余 | — | **需人工** |

**关键具体项**:
- `Pt6E1`/`Pt6E2` (Vicovaro_2022_JEPHPP): 稿件 "Mixed (Lab + Online)"，JSON 含 "Online experiment" + "Dimly lit room"，qmd 判为 Online → **稿件对（Mixed）**，需人工确认
- `Constable_2019_JEPHPP` (P5E1-4): JSON Setting 全为 `/`，无软件 → 需人工（稿件说 Lab Experiment）
- `Kirk_2025_BritJPsy`/`Lee_2023_Cognition`/`Orellana-Corrales_2021_APP`/`Pan_2025_unpub`/`Smith_2024_Cortex`/`Sun_2026_DataExp`/`Svensson_2023_QJEP`: 无 JSON → 需人工

---

## 二、无法从 1_Data/ 解决的（需外部来源或人工确认）

1. **12 个"稿件有但 qmd 未生成"的 ID**（Bukowski/Golubickis/Hobbs/Mcivor/Orellana-Corrales_2023_QJEP/Svensson_2022_PsychRes）— 对应 6 个文件夹不存在，需**收录数据**后解决
2. **N 中 raw/subj_info 与稿件、CSV 三方均不符者**（P6E1=46, Pt13E1=102, Pt28E1=67, Pn13E3=28, P51E1=24, Pt9E2=18, P95E1/2=18, Pt10E1=347, Pt7E1=288, Pu6E1=334；2026-08 subj_info 补齐后新增：Pu5E1=47, Pu5E2=51, Pu4E2=90, Pu9E2=33）— 可能含排除标准/全部样本 vs 有效样本，需人工判定口径
3. **subj_info 已全覆盖（2026-08-27）**：全库 56 个 `*_subj_info.csv`——Orellana-Corrales_2021_APP ×2 与 Sui_2015_unpub ×2 由 Clean.csv 唯一 Subject / `*_Raw/` 人口学记录生成（无原始数据，人口学部分为 /；见 PROJ_STATE.md「已完成」）
4. **Pu8E1 (Pan_2025_unpub)**: 已解决（2026-08-27）——subj_info 由 raw.csv 重新生成（40 行 = 稿件 40）；CSV Sample_Size/Valid_Subj 已补 40；Age 按 2025−出生年推算，待作者确认
5. **Stimulus/Language/Trials 中无 JSON 且 raw 无明确信息者** — 需查阅论文原文
6. **Smith_2024_Cortex (Pu3E1)**: subj_info/raw 仅 48 名被试（含剔除 1 个空 participant），与 CSV Sample_Size=59 / Valid_Subj=58 差约 10 名——raw 导出疑似不全，待人工核对（见 PROJ_STATE.md 已知问题）
7. ~~**Sui_2015_unpub Exp2 (Ps4E2)**~~ **（已解决 2026-08）**：subject 0 为测试运行（.mat 内部证据：编号 0、默认人口学 XX/fm/0、按键反转 [2,1]），已按排除处理——`Sui_2015_unpub_clean.R` 过滤 Subject != 0（Exp2_Clean.csv 9600→9360 行）、subj_info 删 subject 0 行（subject 3 更正 20/f）、CSV Sample_Size/Valid_Subj 21→20、`Clean_Data.Rmd` 两段同步（见 PROJ_STATE.md 已完成条目）

---

## 三、汇总统计

| 类别 | 总数 | 可自动确定 | 需人工 |
|---|---|---|---|
| Exp 编号 | 11 | **11** | 0 |
| N (被试数) | 43 | ~29 | ~13（Ps4E2 已解决） |
| Language | 8 | **5** | 3 |
| Stimulus | 8 | 2 | 6 |
| Trials | 11 | 4 | 7 |
| Country | 2 | **2** | 0 |
| Exp_Implement | 25 | ~15 | ~10 |
| **合计** | **108** | **~68** | **~39**（Ps4E2 已解决） |

注：相较初稿（2026-08-10，110 项）：8 条「CSV Exp 空」类 Exp 不一致已因回填消解（不再计入），补入原清单已有但初稿未收录的 Kirk/Liang ×2/Wozniak ×2 共 5 条及新出现的 Martinez 1 条稿件 Exp 标注错误（净 −2）；N 类 9 条由「文件缺失/异常」升级为具体行数（Pu5E1=47、Pu5E2=51、Pu10E1=65、Pu4E2=90、Pu9E1=34、Pu9E2=33、Ps4E1=20、Ps4E2=21、Pu8E1=40），其中 4 条新增为可自动确定（Pu9E1、Ps4E1、Ps4E2、Pu8E1；Pu10E1 于上次复核已计入），合计维持 108 项（可自动 ~68 / 需人工 ~40）。（2026-08 增补：Sui_2015_unpub Exp2 N 已消解——CSV 21→20、Clean/subj_info 排除 subject 0，Ps4E2 判定由需人工转为已解决；其余条目不变）

---

## 四、建议处理流程

1. **先修可自动确定项（~64 条）**：修改稿件 docx Table 1（11 条 Exp 标注、N/Language/Trials/Country 等），或修改 CSV/qmd 数据源（如 Pt9E1 Country=Hungary——paper JSON 已有；Pan 的 Stim_language——稿件已给 Chinese）
2. **人工确认项（~40 条）**：按"论文原文 → 原始数据 → 合作者确认"顺序核实，特别是：
   - N 三方不符的 14 项（注意排除标准；含 2026-08 新判定的 Pu5E1=47、Pu5E2=51、Pu4E2=90、Pu9E2=33）
   - Exp_Implement 无证据的 10 项
   - Smith_2024_Cortex raw 48 vs CSV 59/58
   - Orellana-Corrales_2021_APP Exp2 的 N 口径（Clean/subj_info 33 vs CSV Sample_Size 34 / Valid_Subj 31）
3. **待收录研究**（12 个 ID）：需合作者提供数据后入库
4. **进度跟踪**：未解决问题清单与处理进度以根目录 `PROJ_STATE.md` 为准（双向关联）；问题清单随 `Generate_Table1.qmd` 重渲染刷新