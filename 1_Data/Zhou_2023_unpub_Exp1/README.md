# Zhou_2023_unpub_Exp1 数据集说明

> 不匹配训练验证任务 · 自我优势效应训练效应行为数据集

## 作者

周诚皓（纽约大学心理学系，美国纽约）
陈亚楠（河南大学心理学院，中国开封）

## 1. 数据集概述

本数据集为「不匹配训练」（Mismatch Training）验证任务的行为实验数据，实验任务改编自 Sui 等人（2012）的知觉匹配范式，旨在检验「匹配优先 / 不匹配优先」两种注意训练策略对形状—标签联结判断及其自我优势效应（Self-Prioritization Effect, SPE）的影响。

- **数据类型**：行为实验逐试次（trial-level）数据
- **被试规模**：26 名在校大学生（匹配优先组 14 人，不匹配优先组 12 人）
- **采集单位**：河南大学心理学院
- **采集软件与环境**：E-Prime；显示器 1024 × 768，刷新率 85 Hz，观察距离约 57 cm

## 2. 实验设计与流程

### 2.1 实验设计

本实验采用 **2（组别：匹配优先 / 不匹配优先）× 3（一致性：匹配 / 不匹配 / 填充）× 2（身份：自我 / 他人）× 9（阶段：基线 → 训练 1–7 → 正式测试）** 混合实验设计。组别为被试间变量，一致性、身份、阶段均为被试内变量。

被试学习几何图形（正方形、圆形）与人称标签（自我、他人）之间的联结关系，随后判断图形—标签配对是否与习得联结一致：

- **匹配试次**：图形与标签符合习得联结
- **不匹配试次**：图形与标签与习得联结不一致
- **填充试次**：使用无实际语义的中性伪词「白栽」「地入」，字形结构分别参照「自我」「他人」

匹配优先组在训练阶段将注意聚焦于匹配（一致）试次；不匹配优先组在训练阶段将注意聚焦于不匹配（不一致）试次。

### 2.2 两阶段划分

每个试次按 `phase` 列划分为两个阶段：

- **练习阶段（practice）**：正式实验前的练习试次
- **正式阶段（main）**：正式实验试次

### 2.3 实验场次（Session）结构

正式阶段包含 9 个连续 session：`baseline`、`training1` … `training7`、`formal`。

- 练习阶段统一标记：`00_practice`
- 正式阶段按执行顺序标记：`01_baseline`、`02_training1`、`03_training2`、`04_training3`、`05_training4`、`06_training5`、`07_training6`、`08_training7`、`09_formal`

### 2.4 试次时序与参数

刺激呈现 100 ms，空屏 1200 ms，休息 1500 ms，反馈 500 ms；反应时限 1200 ms；刺激间隔（ITI）1200 ms。反应按键为 p / o。练习阶段为 4 个组块 × 10 试次，正式实验为 2 个组块 × 每条件 80 试次。

## 3. 目录结构说明

```
Zhou_2023_unpub_Exp1/
├── cleaned/                                   # 清洗后的标准化被试行为数据（26 个文件）
│   └── sub-<ID>/Zhou_2023_unpub_Exp1_<ID>_Clean.xlsx
├── raw_data/                                  # 按 session 拆分的原始实验数据
│   └── sub-<ID>/ (baseline, training1–7, formal)
├── Codebook_Zhou_2023_unpub_Exp1_Clean.xlsx   # 字段详细说明文档
├── Zhou_2023_unpub_Exp1.json                  # 实验元信息
├── Zhou_2023_unpub_Exp1_subj_info.xlsx             # 被试信息表（Subject_ID, Gender, Group）
└── README.md                                  # 本说明文档
```

各目录 / 文件用途：

- `cleaned/`：清洗后的标准化逐试次行为数据，每名被试一个文件，为本数据集的主要交付数据
- `raw_data/`：按 session（baseline、training1–7、formal）拆分的原始实验数据
- `Codebook_Zhou_2023_unpub_Exp1_Clean.xlsx`：字段详细说明
- `README.md`：本说明文档（中英文双语）

## 4. 数据字段说明

`cleaned/` 目录下每名被试一个数据文件，共 **16 列**

| 字段 | 含义 | 取值 / 单位 |
|---|---|---|
| Subject | 被试编号 | 11001–11011 / 12001–12010 / 21001–21003 / 22001–22002 |
| phase | 阶段 | practice（练习）/ main（正式） |
| Session | 实验场次 | 00_practice；01_baseline … 09_formal |
| TrialType | 试次类型 | match / mismatch / fill |
| Shape | 图形刺激 | circle / square |
| Shape_Origin_Identity | 图形原始身份 | self / other |
| Shape_English_Identity | 图形英文身份 | Self / Other |
| Shape_Standardized_Identity | 图形标准化身份 | Self / Stranger |
| Label | 标签词 | 自我 / 他人 / 地入 / 白栽 |
| Label_Origin_Identity | 标签原始身份 | 自我 / 他人 / 地入 / 白栽 |
| Label_English_Identity | 标签英文身份 | Self / Other / Filler |
| Label_Standardized_Identity | 标签标准化身份 | Self / Stranger / Filler |
| Response | 按键反应 | p / o；NA = 无响应 |
| CorrectAnswer | 正确答案 | p / o |
| RT_ms | 反应时 | 数值（毫秒）；NA = 无响应 |
| ACC | 正确率 | 1 = 正确；0 = 错误；NA = 无响应 |

**数据清洗说明**：清洗阶段已移除 9 列冗余时间戳字段（`Clock.StartTimeOfDay`、`stim_start`、`res_time`、`stim_end`、`blank_start`、`blank_end`、`feedback_start`、`feedback_end`、`relax_start`），当前版本仅保留核心行为变量。`Session` 列位于 `phase` 列之后（第 3 列），取值规则见 2.3 节。

## 5. 数据缺失情况说明

### 5.1 缺失类型

- **实验场次缺失**：某被试在 raw_data 中缺少某个 session 的整段数据（该 session 文件夹缺失，或文件夹存在但正式数据文件缺失）
- **试次缺失**：单个试次内被试未在反应时限内按键（无响应，Response = NA）

### 5.2 缺失分布

**实验场次级缺失**：26 名被试中有 **15 名**存在至少一个 session 的数据缺失，**11 名**被试 9 个 session 完整。缺失情况如下：

- 整段实验场次（文件夹）缺失：
  - training4：11001、11005、11007、12003、12004
  - training5：11009
  - training6：12008
  - training3：12009
  - training2、training4：21003
  - training4、training7：11011
- 正式数据文件缺失（文件夹存在但无 main 文件）：
  - training2：11002
  - baseline：12001
  - training7：12002
  - training3、training6：12007
  - training4：22001

**试次级缺失**：全数据集共 79,592 个试次，其中无响应试次 **1,782 个（占 2.24%）**。无响应试次全部出现在正式阶段（占正式试次 67,760 个的 2.63%），练习阶段（11,832 个试次）无无响应试次。

### 5.3 缺失原因

- **实验场次级缺失**：具体原因在原始数据中未记录，可能包括设备临时故障、被试缺席、程序报错等
- **试次级无响应**：被试未在 1200 ms 反应时限内按键

### 5.4 处理方式

- **实验场次级缺失**：清洗过程不对缺失 session 进行填充或补值，`Session` 列仅包含实际存在的实验场次标签（缺失 session 对应标签不出现）
- **试次级无响应**：`Response`、`ACC` 与 `RT_ms` 标记为 `NA`（代表缺失，非数值 0）；仅 `CorrectAnswer` 保留原值

### 5.5 使用提示

- 分析训练轨迹（baseline → formal）时，需注意部分被试缺少个别训练 session，可按需排除相应被试或采用适当的缺失数据处理方法
- 计算正确率或反应时分析时，应剔除无响应试次（Response = NA / ACC = NA），并将 `NA` 作为缺失值处理，而非数值 0

## 6. 使用说明与注意事项

- **数据格式**：Excel（.xlsx），UTF-8 编码
- **推荐分析工具**：R、Python（pandas / openpyxl）等
- **引用规范**：使用本数据集请引用原始研究与数据论文，并遵循数据集随附的引用信息
- **版本信息**：数据 schema 对齐 SPE_Database 标准 v0.1.5；元信息 `schema_version` 为 2
- **伦理提示**：本数据已完成匿名化处理（被试编号为重新编制的匿名编号），不含任何个人可识别信息；使用数据时请遵守伦理规范

---

# Zhou_2023_unpub_Exp1 Dataset

> Mismatch Training verification task · Self-Prioritization Effect (SPE) training-effect behavioral dataset

## Authors

Zhou Chenghao (Department of Psychology, New York University, New York, USA)
Chen Yanan (School of Psychology, Henan University, Kaifeng, China)

## 1. Dataset Overview

This dataset contains the behavioral data of a **Mismatch Training** verification task, adapted from the perceptual matching paradigm of Sui et al. (2012). It examines how "matching-first" versus "nonmatching-first" attention-training strategies shape shape–label association judgments and their Self-Prioritization Effect (SPE).

- **Data type**: trial-level behavioral data
- **Participants**: 26 university students (matching-first group, 14; nonmatching-first group, 12)
- **Collection site**: School of Psychology, Henan University
- **Software & environment**: E-Prime; 1024 × 768 monitor at 85 Hz, viewing distance ~57 cm

Within the current project (a two-experiment behavioral dataset on the training effect of the self-prioritization effect), this dataset serves as an **independent verification experiment** that supplements the main experiment (Hu et al., 2015) by testing the paradigm boundary of the training effect — specifically, whether training modulates the SPE by shifting attentional allocation to matching versus nonmatching trials.

## 2. Experimental Design & Procedure

### 2.1 Design

The experiment uses a mixed design: **2 (group: matching-first / nonmatching-first) × 3 (consistency: matching / nonmatching / filler) × 2 (identity: self / other) × 9 (phase: baseline → training 1–7 → formal test)**. Group is a between-subjects factor; consistency, identity, and phase are within-subjects factors.

Participants learned the association between geometric shapes (square, circle) and person labels (self, other), then judged whether each shape–label pair was consistent with the learned association:

- **Matching trials**: the shape–label pair matches the learned association
- **Nonmatching trials**: the shape–label pair is inconsistent with the learned association
- **Filler trials**: neutral pseudo-word labels "白栽" and "地入", whose character structure references "自我" (self) and "他人" (other), respectively

The matching-first group focused on matching (consistent) trials during training; the nonmatching-first group focused on nonmatching (inconsistent) trials.

### 2.2 Two-Stage Division

Each trial is coded in the `phase` column into two stages:

- **Practice phase (`practice`)**: practice trials preceding the formal experiment
- **Formal phase (`main`)**: formal experimental trials

### 2.3 Session Structure

The formal phase comprises 9 consecutive sessions: `baseline`, `training1` … `training7`, `formal`. The `Session` column uses a "numeric-prefix + semantic-name" coding so that the numeric prefix preserves the order of experimental execution:

- Practice phase is uniformly coded as `00_practice`
- Formal sessions are coded in execution order: `01_baseline`, `02_training1`, `03_training2`, `04_training3`, `05_training4`, `06_training5`, `07_training6`, `08_training7`, `09_formal`

### 2.4 Trial Timing & Parameters

Stimulus duration 100 ms, blank 1200 ms, rest 1500 ms, feedback 500 ms; response deadline 1200 ms; inter-trial interval (ITI) 1200 ms. Response keys are p / o. Practice: 4 blocks × 10 trials; formal experiment: 2 blocks × 80 trials per condition.

## 3. Directory Structure

```
Zhou_2023_unpub_Exp1/
├── cleaned/                                   # Cleaned, standardized per-participant data (26 files)
│   └── sub-<ID>/Zhou_2023_unpub_Exp1_<ID>_Clean.xlsx
├── raw_data/                                  # Session-split raw data (read-only archive)
│   └── sub-<ID>/ (baseline, training1–7, formal)
├── Codebook_Zhou_2023_unpub_Exp1_Clean.xlsx   # Detailed variable dictionary
├── Zhou_2023_unpub_Exp1.json                  # Machine-readable experiment metadata
├── Zhou_2023_unpub_Exp1_subj_info.xlsx             # Participant information (Subject_ID, Gender, Group)
└── README.md                                  # This document (Chinese & English)
```

Description of each directory / file:

- `cleaned/`: cleaned, standardized trial-level behavioral data, one file per participant — the primary deliverable of this dataset
- `raw_data/`: raw experimental data split by session (baseline, training1–7, formal), read-only and never modified
- `Codebook_Zhou_2023_unpub_Exp1_Clean.xlsx`: field-level documentation (variable name, meaning, value coding, data type)
- `README.md`: this documentation (Chinese & English)

## 4. Data Field Specification

Each participant in `cleaned/` has one data file with **16 columns**, fully consistent with `Codebook_Zhou_2023_unpub_Exp1_Clean.xlsx`:

| Field | Meaning | Value / Unit |
|---|---|---|
| Subject | Participant ID | 11001–11011 / 12001–12010 / 21001–21003 / 22001–22002 |
| phase | Stage | practice / main |
| Session | Session | 00_practice; 01_baseline … 09_formal |
| TrialType | Trial type | match / mismatch / fill |
| Shape | Shape stimulus | circle / square |
| Shape_Origin_Identity | Shape original identity | self / other |
| Shape_English_Identity | Shape English identity | Self / Other |
| Shape_Standardized_Identity | Shape standardized identity | Self / Stranger |
| Label | Text label | 自我 / 他人 / 地入 / 白栽 |
| Label_Origin_Identity | Label original identity | 自我 / 他人 / 地入 / 白栽 |
| Label_English_Identity | Label English identity | Self / Other / Filler |
| Label_Standardized_Identity | Label standardized identity | Self / Stranger / Filler |
| Response | Key response | p / o; NA = no response |
| CorrectAnswer | Correct answer | p / o |
| RT_ms | Reaction time | numeric (milliseconds); NA = no response |
| ACC | Accuracy | 1 = correct; 0 = error; NA = no response |

**Data cleaning note**: 9 redundant timestamp columns (`Clock.StartTimeOfDay`, `stim_start`, `res_time`, `stim_end`, `blank_start`, `blank_end`, `feedback_start`, `feedback_end`, `relax_start`) were removed during cleaning; the current version retains only the core behavioral variables. The `Session` column is placed immediately after `phase` (column 3); its coding rule is described in Section 2.3.

## 5. Data Missingness

### 5.1 Types of Missingness

- **Session-level missingness**: a participant is missing an entire session in `raw_data` (the session folder is absent, or the folder exists but the formal data file is absent)
- **Trial-level missingness**: the participant did not press a key within the response deadline in a single trial (no response, Response = NA)

### 5.2 Distribution

**Session-level**: **15 of 26** participants have at least one missing session; **11** participants have all 9 sessions complete. Details:

- Entire-session (folder) missing:
  - training4: 11001, 11005, 11007, 12003, 12004
  - training5: 11009
  - training6: 12008
  - training3: 12009
  - training2, training4: 21003
  - training4, training7: 11011
- Formal data file missing (folder present but no main file):
  - training2: 11002
  - baseline: 12001
  - training7: 12002
  - training3, training6: 12007
  - training4: 22001

**Trial-level**: of 79,592 total trials, **1,782 (2.24%)** are no-response trials. All no-response trials occur in the formal phase (2.63% of the 67,760 formal trials); the practice phase (11,832 trials) contains no no-response trials.

### 5.3 Causes

- **Session-level missingness**: the specific cause is not recorded in the raw data; possible causes include temporary equipment failure, participant absence, or program error
- **Trial-level no-response**: the participant did not press a key within the 1200 ms response deadline

### 5.4 Handling

- **Session-level missingness**: cleaning does not impute or pad missing sessions; the `Session` column contains only the labels of sessions that actually exist (labels of missing sessions do not appear)
- **Trial-level no-response**: `Response`, `ACC`, and `RT_ms` are coded as `NA` (missing, not numeric 0); only `CorrectAnswer` retains its original value

### 5.5 Usage Tips

- When analyzing the training trajectory (baseline → formal), note that some participants lack individual training sessions; exclude the affected participants as needed or apply appropriate missing-data methods
- When computing accuracy or reaction-time analyses, exclude no-response trials (Response = NA / ACC = NA) and treat `NA` as a missing value rather than 0

## 6. Usage Notes

- **Data format**: Excel (.xlsx), UTF-8 encoding
- **Recommended tools**: R, Python (pandas / openpyxl), etc.
- **Citation**: cite the original study and the data paper when using this dataset, following the citation information provided with the dataset
- **Version**: data schema aligned with the SPE_Database standard v0.1.5; metadata `schema_version` 2
- **Ethics**: the data have been de-identified (participant IDs are re-assigned anonymous codes) and contain no personally identifiable information; please observe ethical guidelines when using the data
