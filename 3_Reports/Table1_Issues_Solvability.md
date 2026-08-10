# Table 1 问题可解性分析（基于 1_Data/ 现有内容）

**日期**: 2026-08-10
**来源**: `Generate_Table1.qmd` 输出的问题清单（`3_Reports/Output/table1_problems.txt`）逐一核查 `1_Data/` 中已有内容后的可解性判定。
**结论**: 大部分问题可依据 `1_Data/` 中的原始数据/元数据找到权威答案；少数需要人工确认（含外部来源或稿件口径）。

---

## 一、可依据 1_Data/ 内容确定答案的问题

### A. Exp 编号不一致（13 条）— 全部可解 ✅

证据来源：**文件夹 ExpN 子目录结构 + `*_ExpN_Clean.csv` 文件名 + Exp JSON 文件名**。

| Paper_ID | 稿件(错) | qmd(对) | 文件夹证据 |
|---|---|---|---|
| P5E1 | Exp4 | Exp1 | `Constable_2019_EPHPP/Exp1/` |
| P5E2 | Exp4 | Exp2 | `Constable_2019_EPHPP/Exp2/` |
| P5E3 | Exp4 | Exp3 | `Constable_2019_EPHPP/Exp3/` |
| P5E4 | Exp4 | Exp4 | `Constable_2019_EPHPP/Exp4/` |
| P46E1 | Exp2 | Exp1 | `Constable_2020_CE/Exp1/` |
| P46E2 | Exp4 | Exp2 | `Constable_2020_CE/Exp2/` |
| Pu5E1 | Exp1 | Exp1* | `Lee_2023_Cognition/Exp1/` |
| Pu5E2 | Exp2 | Exp2* | `Lee_2023_Cognition/Exp2/` |
| Pu9E1 | Exp1 | Exp1* | `Orellana-Corrales_2021_APP/Exp1/` |
| Pu9E2 | Exp2 | Exp2* | `Orellana-Corrales_2021_APP/Exp2/` |
| P54E2 | Exp2 | Exp2* | `Schaefer_2019_CP/Exp2/` |
| P54E3 | Exp3 | Exp3* | `Schaefer_2019_CP/Exp3/` |
| Pu6E1 | Exp1 | Exp1* | `Sun_2025_Exp1_Clean.csv` |

*注：CSV 中这些行的 Exp 列为空，qmd 显示空；文件夹结构证明稿件正确。

**推荐**: 稿件 `P5E1`–`P5E3` 的 "Exp4" 是复制粘贴错误，应改为 Exp1/2/3；`P46E1`/`P46E2` 同理（稿件 Exp2/Exp4 → 实为 Exp1/Exp2）。其余 6 条为 CSV Exp 列缺失，应从文件夹回填。

### B. N（被试数）不一致 — 大部分可解 ✅

证据来源：**`*_raw_Subject.csv` 数据行数**（最权威，每行 1 名被试）。

| Paper_ID | 稿件 | qmd(CSV) | raw_Subject 行数 | 判定 |
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
| Pt9E1 | 18 (0/18) | 23 (7/11) | **18** | 稿件对，qmd 错 |
| Pt9E2 | 21 (—) | 21 (6/12) | **18** | raw=18 与两者均不符，需人工确认 |
| Pt9E3 | 18 (—) | 18 (0/18) | **18** | 一致 |
| P95E1 | 20 (9/9) | 19 (9/9) | **18** | 均不符，raw=18，需人工确认 |
| P95E2 | 20 (—) | 20 (9/9) | **18** | 均不符，raw=18，需人工确认 |
| Pt10E1 | 380 (—) | 380 (198/182) | **347** | raw=347 与两者均不符，需人工确认 |
| Pt7E1 | 328 (—) | 328 | **288** | raw=288 与两者均不符，需人工确认 |
| Pt27E2 | 32 | 32 (5/27) | **32** | 一致 |
| Pu4E2 | 126 (—) | 126 | **文件缺失** | 无 raw_Subject，需人工 |
| Pu5E1 | 65 (—) | 57 | **文件缺失** | 无 raw_Subject，需人工 |
| Pu5E2 | 65 (—) | 65 | **文件缺失** | 无 raw_Subject，需人工 |
| Pu9E1 | 36 (7/29) | 34 (9/25) | **文件缺失** | 无 raw_Subject，需人工 |
| Pu9E2 | 36 (7/29) | 34 (11/23) | **文件缺失** | 无 raw_Subject，需人工 |
| Ps4E1 | 21 (—) | 20 | **文件缺失** | 无 raw_Subject，需人工 |
| Ps4E2 | 20 (—) | 21 | **文件缺失** | 无 raw_Subject，需人工 |
| Pu8E1 | 40(—) | — | **1 (异常)** | raw_Subject 仅 1 行，异常，需人工 |
| Pu6E1 | 506(—) | — | **334** | raw=334，稿件 506 可能是全部样本，需人工确认 |
| Pu10E1 | 25 (7/18) | 65 (20/45) | **文件缺失** | 无 raw_Subject，需人工 |

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
| Pt10E1 | Chinese | English | — | 需人工确认（Zhang_2023_NI） |

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
| JSON Setting 明确（如 "Sound-proofed rooms", "Online experiment"） | 3 | `Schaefer_2019_CP`(Lab)、`Vicovaro_2022_EPHPP`(Mixed，Setting 含 "Online experiment" 与 "Dimly lit room") | **可解** |
| CSV Environmental_Info 有软件名（E-prime→Lab, Gorilla→Online） | 多数 | 见 CSV `Environmental_Info` 列 | **可解**（以软件推断） |
| 完全无证据（JSON Setting=/ 且无软件） | 剩余 | — | **需人工** |

**关键具体项**:
- `Pt6E1`/`Pt6E2` (Vicovaro): 稿件 "Mixed (Lab + Online)"，JSON 含 "Online experiment" + "Dimly lit room"，qmd 判为 Online → **稿件对（Mixed）**，需人工确认
- `Constable_2019_EPHPP` (P5E1-4): JSON Setting 全为 `/`，无软件 → 需人工（稿件说 Lab Experiment）
- `Kirk_2025_BJP`/`Lee_2023_Cognition`/`Orellana-Corrales_2021_APP`/`Pan_2025`/`Smith_2024_Cortex`/`Sun_2025`/`Svensson_2023_QJEP`: 无 JSON → 需人工

---

## 二、无法从 1_Data/ 解决的（需外部来源或人工确认）

1. **12 个"稿件有但 qmd 未生成"的 ID**（Bukowski/Golubickis/Hobbs/Mcivor/Orellana-Corrales_EP/Svensson_PR）— 对应 6 个文件夹不存在，需**收录数据**后解决
2. **N 中 raw 与稿件、CSV 三方均不符者**（P6E1=46, Pt13E1=102, Pt28E1=67, Pn13E3=28, P51E1=24, Pt9E2=18, P95E1/2=18, Pt10E1=347, Pt7E1=288, Pu6E1=334）— 可能含排除标准/全部样本 vs 有效样本，需人工判定口径
3. **无 raw_Subject 文件的研究**（Pu4E1/2, Pu5E1/2, Pu9E1/2, Ps4E1/2, Pu10E1）— 数据缺失
4. **Pu8E1 (Pan_2025)**: raw_Subject 仅 1 行，明显异常，需检查原始文件
5. **Stimulus/Language/Trials 中无 JSON 且 raw 无明确信息者** — 需查阅论文原文

---

## 三、汇总统计

| 类别 | 总数 | 可自动确定 | 需人工 |
|---|---|---|---|
| Exp 编号 | 13 | **13** | 0 |
| N (被试数) | 43 | ~24 | ~19 |
| Language | 8 | **5** | 3 |
| Stimulus | 8 | 2 | 6 |
| Trials | 11 | 4 | 7 |
| Country | 2 | **2** | 0 |
| Exp_Implement | 25 | ~15 | ~10 |
| **合计** | **110** | **~65** | **~45** |

---

## 四、建议处理流程

1. **先修可自动确定项**（~65 条）：修改稿件 docx Table 1（Exp 编号、N、Language 等），或修改 CSV/qmd 数据源
2. **人工确认项**（~45 条）：按"论文原文 → 原始数据 → 合作者确认"顺序核实，特别是：
   - N 三方不符的 10 项（注意排除标准）
   - Pu8E1 的 raw_Subject 异常
   - Exp_Implement 无证据的 10 项
3. **待收录研究**（12 个 ID）：需合作者提供数据后入库
