# Table 1 问题可解性分析（基于 1_Data/ 现有内容）

**初稿日期**: 2026-08-10
**复核日期**: 2026-08-27（CSV Exp 回填、subj_info 全覆盖、Pan 样本量回填后两次重渲染 `Generate_Table1.qmd` 刷新问题清单）；2026-08 增补复核（Sui_2015_unpub Exp2 排除测试被试 subject 0）；**2026-10-14 按当前数据逐项重核并删除全部「答案已定案」条目**（§一 107 → 36 项；§二 5 → 2 项）
**来源**: 原 `Generate_Table1.qmd` 输出的问题清单（`3_Reports/Output/table1_problems.txt`，111 行）逐一核查 `1_Data/` 中已有内容后的可解性判定。
**删除口径（2026-10-14 用户定案）**: 凡「答案已由 `1_Data/` 定案」的条目——判定为 `qmd 对` / `稿件对` / `一致` / `稿件错已确认`——一律删除（稿件 v16 已废弃、库内值即为权威，无需再动）。本文件仅保留**仍需人工/外部确认**、**库内仍需改（CSV 需改/需补）** 与**三方均不符**的条目。
**键**: 行键 = 实验 identifier `<Folder_Name>_Exp<N>`（即该实验标准文件的命名前缀；`<Folder_Name>` = study 在全库的唯一 ID）。原 `Paper_ID` 为历史口径，已不再使用。
**关联**: 本文档与根目录 `PROJ_STATE.md` **双向关联**——处理进度以 PROJ_STATE.md §3 为准；本文档给出逐项可解性判定（可依 1_Data/ 自动确定 / 需人工或外部来源）。

---

## 一、仍需处理的问题（需人工判定或库内待改）

### B. N（被试数）不一致 — 16 条（需人工）

证据来源：**`*_subj_info.csv` 数据行数**（最权威，每行 1 名被试）+ `*_raw.csv`。

| Experiment_ID | 稿件 | 当前 CSV (subj_info) | 判定 |
|---|---|---|---|
| Constable_2020_ActaPsych_Exp1 | 56 (25/31) | 92（Partner 48 + Stranger 44；subj_info 46） | 三方均不符，需人工确认（可能含排除） |
| Amodeo_2024_CABN_Exp1 | 70 | 67 (37+30) | raw=67 与稿件 70 均不符，需人工确认 |
| Feldborg_2021_IJERPH_Exp1 | 84 (—) | 102 (53+49) | 均不符，需人工确认 |
| Navon_2021_psyarxiv_Exp3 | 26 (9/18) | 28 (12/15) | 均不符，需人工确认 |
| Qian_2020_QJEP_Exp1 | 26 (7/19) | 24 (9/15) | 均不符，需人工确认 |
| Wozniak_2022_PsychRes_Exp1 | 18 (0/18) | 18 (7/11) | N 一致，M/F 不一致（CSV 需改） |
| Wozniak_2022_PsychRes_Exp2 | 21 (—) | 18 (6/12) | 均不符，需人工确认 |
| Wozniak_2018_PLOS_Exp1 | 20 (9/9) | 18 (9/9) | 均不符，需人工确认 |
| Wozniak_2018_PLOS_Exp2 | 20 (—) | 18 (9/9) | 均不符，需人工确认 |
| Zhang_2023_NeuroImage_Exp1 | 380 (—) | 346 (172/174) | 均不符，需人工确认 |
| Perrykkad_2022_BMCPsych_Exp1 | 328 (—) | 334 | 均不符，需人工确认 |
| Kirk_2025_BritJPsy_Exp2 | 126 (—) | 90 | 均不符，需人工确认 |
| Lee_2023_Cognition_Exp1 | 65 (—) | 47 | 均不符，需人工确认 |
| Lee_2023_Cognition_Exp2 | 65 (—) | 51 | 均不符，需人工确认 |
| Orellana-Corrales_2021_APP_Exp2 | 36 (7/29) | 33 (11/23)（CSV Sample_Size 33 / Valid_Subj 31） | 均不符，需人工确认（含 N 口径） |
| Sun_2026_DataExp_Exp1 | 506 (—) | 589（Sample_Size 589 / Valid_Subj 503） | 均不符，需人工确认（全部样本 vs 有效样本口径） |

### C. Language 不一致 — 4 条（需人工）

证据来源：**raw CSV 中的身份标签实际字符**（最权威）+ CSV `Stim_language`。

| Experiment_ID | 稿件 | 当前 CSV | 证据 | 判定 |
|---|---|---|---|---|
| Constable_2020_ActaPsych_Exp1 | English | Hungarian | raw 无直接语言标记 | 需人工 |
| Dalmaso_2024_ConsciousCog_Exp1 | Spanish | Japanese | raw 含 `esperimento`/`si`/`no`（意大利语） | **均不符**，实为 Italian，需人工确认 |
| Dalmaso_2024_ConsciousCog_Exp2 | Japanese | Italian | raw 含 `yes`/`no`（英语化） | 需人工 |
| Zhang_2023_NeuroImage_Exp1 | Chinese | English | — | 需人工确认 |

### D. Stimulus 不一致 — 5 条（需人工）

证据来源：**JSON `Stimulus_Properties.Shape` + raw 数据形状名**。

| Experiment_ID | 稿件 | 当前 CSV | 判定 |
|---|---|---|---|
| Constable_2020_ActaPsych_Exp1 | grey scale squares | geometric shape | JSON 无明确形状，与稿件相反，需人工 |
| Lee_2023_Cognition_Exp1 | geometric shape / nm. | geometric shape | 无 JSON，稿件更具体，需人工 |
| Lee_2023_Cognition_Exp2 | geometric shape / nm. | geometric shape | 无 JSON，同上，需人工 |
| Sui_2015_unpub_Exp1 | geometric shape and face | geometric shape | 无 JSON，需人工 |
| Sui_2015_unpub_Exp2 | geometric shape | geometric shape and face | 无 JSON，需人工（库内 `Sui_2015_unpub` 现仅 Exp1，Exp2 适用性需确认） |

### E. Trials 不一致 — 8 条（需人工 / qmd 待补）

证据来源：**JSON `Block_Structure.Trial_number` + CSV `numTrials`**。

| Experiment_ID | 稿件 | 当前 CSV | 判定 |
|---|---|---|---|
| Constable_2021_CogEmo_Exp2 | 80 | 192 | qmd 需补（JSON 记 384 total / 96 per block），稿件 80 疑抄自他行 |
| Qian_2020_QJEP_Exp1 | 100 | 576 | 需人工确认口径 |
| Sui_2014_unpub_Exp1 | 60 | 720 | 无 JSON，需人工 |
| Sui_2015_unpub_Exp2 | 60 | — | 无 JSON，需人工（库内现仅 Exp1） |
| Dalmaso_2024_ConsciousCog_Exp1 | 240 | 360 | qmd 需补（JSON 记 360，180/block），稿件 240 待确认 |
| Orellana-Corrales_2021_APP_Exp1 | 240 | 128 | 无 JSON，需人工 |
| Orellana-Corrales_2021_APP_Exp2 | 240 | 128 | 无 JSON，需人工 |
| Svensson_2023_QJEP_Exp1 | 400 | 120 | 无 JSON，需人工 |

### F. Country 不一致 — 0 条（已定案删除）

原 2 条均已定案：`Svensson_2023_QJEP_Exp1` 稿件 `United Kingdom` vs CSV `UK` 属表述差异（UK == United Kingdom），视为一致；`Wozniak_2022_PsychRes_Exp1` 稿件 `Australia` 为稿件错（paper JSON Country=Hungary，CSV 已为 Hungary）。

### G. Exp_Implement 不一致 — 3 项（需人工）

证据来源：**JSON `Physical_Environment.Setting` + `Equipment.Software` + CSV `Environmental_Info`（软件名）**。多数研究已可由软件名推断（E-Prime/Inquisit/Matlab→Lab，Gorilla/jsPsych/Testable→Online），下列仍无充分证据：

| Experiment_ID | 情况 | 判定 |
|---|---|---|
| Vicovaro_2022_JEPHPP_Exp1–Exp2 | 稿件 "Mixed (Lab + Online)"，JSON Setting 含 "Online experiment" + "Dimly lit room"，CSV 现为 Lab | 稿件对（Mixed），需人工确认 |
| Constable_2019_JEPHPP_Exp1–Exp4 | JSON Setting 全为 `/`、CSV 无软件 | 需人工（稿件说 Lab Experiment） |
| Svensson_2023_QJEP_Exp1 | 无 JSON、CSV 无软件 | 需人工 |

---

## 二、无法从 1_Data/ 解决的（需外部来源或人工确认）

1. **N 中 raw/CSV 与稿件三方均不符者**（见 §一.B，共 16 条）— 可能含排除标准 / 全部样本 vs 有效样本口径，需人工判定
2. **Stimulus / Language / Trials / Exp_Implement 中无 JSON 且 raw 无明确信息者**（见 §一.C/D/E/G）— 需查阅论文原文

（已解决移出：原 §二 第 1 条「12 个稿件有但 qmd 未生成的 ID / 6 个文件夹不存在」——Bukowski、Golubickis、Hobbs、Mcivor、Orellana-Corrales_2023_QJEP、Svensson_2022_PsychRes 均已入库；第 3 条 subj_info 已全覆盖；第 5 条 `Smith_2024_Cortex` CSV Sample_Size 已为 48。）

---

## 三、汇总统计（2026-10-14 重核）

| 类别 | 保留（未决） | 已定案删除 |
|---|---|---|
| Exp 编号 | 0 | 11 |
| N (被试数) | **16** | 26 |
| Language | **4** | 4 |
| Stimulus | **5** | 3 |
| Trials | **8** | 3 |
| Country | 0 | 2 |
| Exp_Implement | **3** | 22 |
| **合计** | **36** | **71** |

注：原 §一 107 项，本次删除 71 项、保留 36 项；原 §二 5 项，删除 3 项、保留 2 项。删除条目（判定为 `qmd 对` / `稿件对` / `一致` / `稿件错已确认`）的结论不再保留于本文件；如稿件版本更新需回溯，见 git 历史（2026-10-14 之前版本）。

---

## 四、建议处理流程

1. **人工确认项**（按"论文原文 → 原始数据 → 合作者确认"顺序核实）：§一.B 的 16 条 N 三方不符项（注意排除标准）；§一.C/D/E 中无 JSON 的 Language/Stimulus/Trials 项；§一.G 的 3 项 Exp_Implement
2. **库内待改项**：`Wozniak_2022_PsychRes_Exp1` 的 M/F（CSV 需改）；`Constable_2021_CogEmo_Exp2` 与 `Dalmaso_2024_ConsciousCog_Exp1` 的 `numTrials`（qmd 需补）
3. **进度跟踪**：处理进度以根目录 `PROJ_STATE.md` §3 为准（双向关联）
