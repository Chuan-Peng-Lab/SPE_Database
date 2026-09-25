# Hu_2015_unpub —— 数据集说明

> Hu et al.（2015，未发表）自我优势效应训练效应正式实验（实验 1 与实验 2）· 清洗后标准化行为数据集

## 作者（Authors）

胡传鹏（南京师范大学心理学院，中国南京；清华大学心理学系，中国北京）

彭凯平（清华大学心理学系，中国北京）

隋洁（阿伯丁大学心理学院，英国阿伯丁）

## 概述

本子数据集包含 Hu et al.（2015，未发表）两个正式训练实验（实验 1 / Task 1 与实验 2 / Task 2）的清洗后逐试次数据。实验任务改编自 Sui 等人（2012）的知觉匹配范式，被试学习图形—标签联结，随后判断每个呈现的图形—标签配对是否与习得联结匹配。

## 被试

共 36 名来自清华大学的在校大学生有偿参与实验。所有被试均为右利手，视力或矫正视力正常。其中 30 人贝克抑郁量表（BDI）得分低于 10（对照组），6 人 BDI 得分高于 20（亚临床抑郁组）。对照组中 3 名被试（6008、6015、6031）因无效试次、程序故障等原因导致缺乏有效数据而被剔除。最终纳入 27 名低 BDI（对照）被试与 6 名高 BDI 被试。

本实验已通过清华大学心理学系伦理审查委员会（IRB）审批。所有被试均已充分知情并同意参与，实验结束后获得相应报酬。

**备注（Notes）：**

- 需剔除的被试：6008、6015、6031
- 高 BDI 被试：6005、6006、6010、6022、6025、6036
- `data/` 目录保留全部 36 个被试文件夹（`sub-6001` … `sub-6036`）；组别（对照 / 亚临床抑郁）通过 `Hu_2015_unpub_subj_info.xlsx` 中的 BDI 得分记录。

## 实验流程（Procedure）

任务改编自 Sui 等人（2012）。被试在光线昏暗的房间内单独完成实验，刺激呈现与反应采集使用 E-Prime 2.0，显示器分辨率 1024 × 768、刷新率 100 Hz。数据采集时间为 2015 年 10 月 21 日至 2015 年 12 月 2 日。

到达实验室后，被试先签署书面知情同意书，随后依次完成三部分内容：行为实验 1、行为实验 2 及问卷。全部实验约需 80 分钟。

### 实验 1（Exp1 / Task 1）

混合设计：**2（匹配 / 不匹配）× 3（联结类型：自我–他人、高奖赏–低奖赏、快乐–悲伤）× 6（组块）× 2（被试类型：对照 / 亚临床抑郁）**。被试类型为被试间变量；匹配、联结类型、组块为被试内变量。被试学习三类联结：自我 vs. 他人、快乐面孔 vs. 中性面孔、低奖赏 vs. 高奖赏。

- 图形刺激（6 种几何图形）：`C`=圆形 Circle、`D`=菱形 Diamond、`Tra`=梯形 Trapezoid、`P`=五边形 Pentagon、`S`=正方形 Square、`T`=三角形 Triangle
- 标签词（中文）：`你`(self)、`生人`(other)、`高兴`(happy)、`中性`(neutral)、`￥1`(low reward)、`￥16`(high reward)
- 反应按键：`1`、`2`；ITI 1000 ms

### 实验 2（Exp2 / Task 2）

混合设计：**2（匹配 / 不匹配）× 3（身份：自我、好友、陌生人）× 4（情绪：控制、中性、快乐、悲伤）× 6（组块）× 2（被试类型：对照 / 亚临床抑郁）**。被试将三种不同的圆形（`c`、`hc`、`vc`）分别与自我、最好的朋友、陌生人建立联结；每种圆形以 4 种情绪表情呈现（控制、快乐、中性、悲伤），共 12 种图形—情绪组合。

- 标签词（中文）：`自己`(self)、`朋友`(friend)、`生人`(stranger)
- 反应按键：`m`、`n`；ITI 1000 ms；`Selfpic`/`Strangerpic` 图片代码（`c`/`hc`/`vc`）在被试间平衡

## 数据文件（Data files）

本目录（`clean/Hu_2015_unpub/`）当前文件构成如下：

```
Hu_2015_unpub/
├── data/                                        ← 清洗后逐被试数据（36 个文件夹）
│   └── sub-<ID>/                                ← sub-6001 … sub-6036
│       ├── Hu_2015_unpub_Exp1_<ID>_Clean.xlsx   ← 实验 1 清洗数据（19 列）
│       └── Hu_2015_unpub_Exp2_<ID>_Clean.xlsx   ← 实验 2 清洗数据（24 列）
├── Codebook_Hu_2015_unpub_Exp1_Clean.xlsx       ← 实验 1 变量字典
├── Codebook_Hu_2015_unpub_Exp2_Clean.xlsx       ← 实验 2 变量字典
├── Hu_2015_unpub_Exp1.json                      ← 实验 1 机器可读元信息
├── Hu_2015_unpub_Exp2.json                      ← 实验 2 机器可读元信息
├── Hu_2015_unpub_subj_info.xlsx                 ← 被试信息表
├── Hu_2015_unpub_questionnaire.xlsx             ← 问卷数据
└── Readme.md                                    ← 本说明文档（中英文双语）
```

| 文件 | 说明 |
|---|---|
| `data/sub-<ID>/Hu_2015_unpub_Exp1_<ID>_Clean.xlsx` | 实验 1 清洗后逐试次数据，每名被试一个文件（19 列） |
| `data/sub-<ID>/Hu_2015_unpub_Exp2_<ID>_Clean.xlsx` | 实验 2 清洗后逐试次数据，每名被试一个文件（24 列） |
| `Codebook_Hu_2015_unpub_Exp1_Clean.xlsx` | 实验 1 变量字典（字段名、含义、取值编码、数据类型） |
| `Codebook_Hu_2015_unpub_Exp2_Clean.xlsx` | 实验 2 变量字典 |
| `Hu_2015_unpub_Exp1.json` | 实验 1 元信息（schema_version 2） |
| `Hu_2015_unpub_Exp2.json` | 实验 2 元信息（schema_version 2） |
| `Hu_2015_unpub_subj_info.xlsx` | 被试信息表（`Subject_ID, Age, Gender, Handedness, BDI_Score, BAI_Score`） |
| `Hu_2015_unpub_questionnaire.xlsx` | 问卷数据（工作表 `All_Data_Original`、`scores`） |

## 字段说明（Field standard）

清洗后逐试次文件的最终列顺序如下（完整取值编码见 CodeBook）。

### 实验 1（19 列）

`Subject, Clock.StartTimeOfDay, Task, Session, SubTrial, BlockList.Sample, Matching, Shape, Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity, Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity, CorrectAnswer, ACC, Response, RT_ms`

| 变量 | 含义 | 取值 / 单位 |
|---|---|---|
| `Subject` | 被试编号 | 6001–6036 |
| `Clock.StartTimeOfDay` | 试次开始时刻 | datetime（m/d/yy h:mm）；NA = 缺失 |
| `Task` | 任务类型 | self-matching / reward / emotion；NA = 无法判定 |
| `Session` | 实验场次 | 1–7 |
| `SubTrial` | 子试次阶段 | 1（练习）；2–3（正式） |
| `BlockList.Sample` | 试次组块号 | 1–2；NA = 练习或其他任务 |
| `Matching` | 匹配性 | Matched / Mismatched；NA |
| `Shape` | 图形刺激 | Circle / Diamond / Trapezoid / Pentagon / Square / Triangle |
| `Shape_Origin_Identity` | 图形原始身份 | self / other / happy / neutral / 1 / 16 |
| `Shape_English_Identity` | 图形英文身份 | Self / Other / Happy / Neutral / Low_reward / High_reward |
| `Shape_Standardized_Identity` | 图形标准化身份 | Self / Stranger / Happy / Neutral / Low_reward / High_reward |
| `Label` | 标签词 | 你 / 生人 / 高兴 / 中性 / ￥1 / ￥16 |
| `Label_Origin_Identity` | 标签原始身份 | 你 / 生人 / 高兴 / 中性 / ￥1 / ￥16 |
| `Label_English_Identity` | 标签英文身份 | Self / Other / Happy / Neutral / Low_reward / High_reward |
| `Label_Standardized_Identity` | 标签标准化身份 | Self / Stranger / Happy / Neutral / Low_reward / High_reward |
| `CorrectAnswer` | 正确答案 | 1 / 2 |
| `ACC` | 正确率 | 1 = 正确；0 = 错误；NA = 无响应 |
| `Response` | 按键反应 | 1 / 2；NA = 无响应 |
| `RT_ms` | 反应时 | 数值（毫秒）；NA = 无响应 |

### 实验 2（24 列）

`Subject, Clock.StartTimeOfDay, Task, Session, BlockList.Sample, TrialList, TrialList.Cycle, Matching, Shape, Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity, Selfpic, Friendpic, Strangerpic, Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity, Emotion, CorrectAnswer, Response, RT_ms, ACC`

| 变量 | 含义 | 取值 / 单位 |
|---|---|---|
| `Subject` | 被试编号 | 6001–6036 |
| `Clock.StartTimeOfDay` | 试次开始时刻 | datetime；NA = 缺失 |
| `Task` | 任务类型 | self-matching |
| `Session` | 实验场次 | 1–7 |
| `BlockList.Sample` | 试次组块号 | 1–6；NA = 练习 |
| `TrialList` | 试次顺序 | 1–36；NA = 练习 |
| `TrialList.Cycle` | 试次轮次 | 2–36；NA = 练习 |
| `Matching` | 匹配性 | Matching（n）/ Nonmatching（m） |
| `Shape` | 图形刺激 | c / hc / vc × 4 情绪，共 12 种组合 |
| `Shape_Origin_Identity` | 图形原始身份 | self / friend / stranger |
| `Shape_English_Identity` | 图形英文身份 | self / friend / stranger |
| `Shape_Standardized_Identity` | 图形标准化身份 | self / friend / stranger |
| `Selfpic` | 自我图片代码 | c / hc / vc |
| `Friendpic` | 朋友图片代码 | c / hc / vc |
| `Strangerpic` | 陌生人图片代码 | c / hc / vc |
| `Label` | 标签词 | 自己 / 朋友 / 生人 |
| `Label_Origin_Identity` | 标签原始身份 | self / friend / stranger |
| `Label_English_Identity` | 标签英文身份 | self / friend / stranger |
| `Label_Standardized_Identity` | 标签标准化身份 | self / friend / stranger |
| `Emotion` | 情绪 | happy / sad / neutal（=neutral）/ control |
| `CorrectAnswer` | 正确答案 | m / n |
| `Response` | 按键反应 | m / n；NA = 无响应 |
| `RT_ms` | 反应时 | 数值（毫秒）；NA = 无响应 |
| `ACC` | 正确率 | 1 = 正确；0 = 错误；NA = 无响应 |

## 数据清洗规范

### 实验 1

1. **列合并** —— 按任务拆分的并行列 `BlockList.Sample/E/S`、`Target.ACC/E/S`、`Target.RESP/E/S`、`Target.RT/E/S` 分别合并为 `BlockList.Sample`、`ACC`、`Response`、`RT_ms`。
2. **列重命名** —— `Match` → `Matching`；`ShapeE` → `Shape_Origin_Identity`。
3. **新增 `Shape` 列** —— 由原始 `.txt` 刺激导出数据填充，将刺激编码映射为图形英文名。
4. **身份列** —— 在 `Shape` 后新增三列、`Label` 后新增三列，记录原始 / 英文 / 标准化身份。
5. **`Task` 列** —— 紧跟 `Subject` 后新增任务标签。
6. **匿名化** —— `Handedness`、`Sex` 提取至 `Hu_2015_unpub_subj_info.xlsx` 并从逐试次文件删除。
7. **缺失值统一** —— 空 `BlockList.Sample`、`Response` 填 `NA`；`Response` 缺失行 `RT_ms`（原 0）改 `NA`，`ACC` 对齐 `NA`。
8. **Clock 列** —— `Clock.StartTimeOfDay` 从原始数据补回，置于第 2 列。

### 实验 2

1. **列重命名** —— `Target.ACC` → `ACC`、`Target.RESP` → `Response`、`Target.RT` → `RT_ms`、`Target.CRESP` → `CorrectAnswer`。
2. **冗余列删除** —— 删除 `Clock.StartTimeOfDay`（临时）与 `Words_en`；`Clock.StartTimeOfDay` 随后作为第 2 列补回。
3. **新增 `Task` 列** —— 所有行填 `self-matching`。
4. **新增 `Matching` 列** —— 由 `CorrectAnswer` 派生（`n`→Matching，`m`→Nonmatching）。
5. **`Shape` 列** —— `Target` 重命名为 `Shape` 并移至 `Matching` 之后。
6. **身份列** —— 新增 `Shape_*_Identity`（由 self/friend/stranger 图片列填充）与 `Label_*_Identity`（由 `Words_en` 填充）。
7. **图片列** —— 新增 `Friendpic`（全部填 `hc`），`Stranger` 重命名为 `Strangerpic`。
8. **匿名化** —— `Handedness`、`Sex` 核对一致后删除。
9. **列顺序** —— `ACC` 移至 `RT_ms` 之后。

## 使用说明（Usage）

- **数据格式**：Excel（.xlsx），UTF-8 编码；推荐使用 R、Python（pandas / openpyxl）等工具读取。
- **变量编码** 以配套 CodeBook（`Codebook_Hu_2015_unpub_Exp1/Exp2_Clean.xlsx`）为权威参考。
- **缺失值** 统一为文本 `NA`（表示无响应 / 缺失 / 空，非数值 0），分析时应作为缺失值处理。
- **`Task` 含义**：本数据集中 `Task` 标记任务 / 联结类型（`self-matching` / `reward` / `emotion`）；与 `Zhou_2023_unpub_Exp1` 数据集中的 `TrialType`（`match` / `mismatch` / `fill`）含义不同，跨数据集合并前须先厘清。
- **版本**：数据 schema 对齐 SPE_Database 标准 v0.1.5；元信息 `schema_version` 2。
- **伦理**：数据已完成匿名化处理，不含个人可识别信息。

---

# Hu_2015_unpub — Dataset README

> The formal training experiments (Experiment 1 & Experiment 2) of Hu et al. (2015, unpublished) · cleaned, standardized behavioral dataset

## Authors

Hu Chuan-Peng (School of Psychology, Nanjing Normal University, Nanjing, China; Department of Psychology, Tsinghua University, Beijing, China)

Kaiping Peng (Department of Psychology, Tsinghua University, Beijing, China)

Jie Sui (School of Psychology, the University of Aberdeen, Aberdeen, UK)

## Overview

This sub-dataset contains the cleaned trial-level data of two formal training experiments (Experiment 1 / Task 1 and Experiment 2 / Task 2) from Hu et al. (2015, unpublished). The task is adapted from the perceptual matching paradigm of Sui et al. (2012): participants learned shape–label associations and then judged whether each presented shape–label pair matched the learned association.

## Participants

36 college students from the Tsinghua University community participated in the experiment and were compensated. All were right-handed and had normal or corrected-to-normal vision. 30 scored below 10 on the Beck Depression Inventory (BDI; control group), and 6 scored above 20 (subclinical-depression group). In the control group, three participants (6008, 6015, 6031) were excluded due to invalid trials, program malfunctions, or other reasons that resulted in a lack of valid data. A total of 27 low-BDI (control) and 6 high-BDI participants were included in the final analysis.

This experiment was approved by the IRB at the Department of Psychology, Tsinghua University. All participants were fully informed and agreed to participate; they were compensated for their time after the experiment.

**Notes:**

- Participants whose data need to be excluded: 6008, 6015, 6031
- Participants with high BDI score: 6005, 6006, 6010, 6022, 6025, 6036
- The `data/` directory retains all 36 participant folders (`sub-6001` … `sub-6036`); group membership (control vs. subclinical depression) is documented via the BDI scores in `Hu_2015_unpub_subj_info.xlsx`.

## Procedure

The task is modified from Sui et al. (2012). Participants finished the tasks individually in a dimly lit room. Stimuli were presented and responses collected using E-Prime 2.0 on a PC; the monitor was 1024 × 768 at 100 Hz. Data were collected from 2015-10-21 to 2015-12-02.

Upon arrival, participants were given written informed consent. After reading and signing, they completed three parts: behavioral experiment 1, behavioral experiment 2, and the questionnaires. The whole experiment took approximately 80 minutes.

### Experiment 1 (Exp1 / Task 1)

Mixed design: **2 (match vs. non-match) × 3 (association type: self–other, high reward–low reward, happy–sad) × 6 (block) × 2 (group: control vs. subclinical depression)**. Group is between-subjects; matching, association type, and block are within-subjects. Participants learned three associations: self vs. other, happy face vs. neutral face, and low reward vs. high reward.

- Shape stimuli (6 geometric shapes): `C`=Circle, `D`=Diamond, `Tra`=Trapezoid, `P`=Pentagon, `S`=Square, `T`=Triangle
- Labels (Chinese): `你`(self), `生人`(other), `高兴`(happy), `中性`(neutral), `￥1`(low reward), `￥16`(high reward)
- Response keys: `1`, `2`; ITI 1000 ms

### Experiment 2 (Exp2 / Task 2)

Mixed design: **2 (match vs. non-match) × 3 (identity: self, friend, stranger) × 4 (emotion: control, neutral, happy, sad) × 6 (block) × 2 (group: control vs. subclinical depression)**. Participants associated three different circles (`c`, `hc`, `vc`) with self, best friend, and stranger; each circle type appeared with 4 emotional expressions (control, happy, neutral, sad), for 12 shape–emotion combinations.

- Labels (Chinese): `自己`(self), `朋友`(friend), `生人`(stranger)
- Response keys: `m`, `n`; ITI 1000 ms; `Selfpic`/`Strangerpic` picture codes (`c`/`hc`/`vc`) counterbalanced across participants

## Data files

The current contents of `clean/Hu_2015_unpub/` are:

```
Hu_2015_unpub/
├── data/                                        ← cleaned per-participant data (36 folders)
│   └── sub-<ID>/                                ← sub-6001 … sub-6036
│       ├── Hu_2015_unpub_Exp1_<ID>_Clean.xlsx   ← Experiment 1 cleaned data (19 columns)
│       └── Hu_2015_unpub_Exp2_<ID>_Clean.xlsx   ← Experiment 2 cleaned data (24 columns)
├── Codebook_Hu_2015_unpub_Exp1_Clean.xlsx       ← variable dictionary (Exp1)
├── Codebook_Hu_2015_unpub_Exp2_Clean.xlsx       ← variable dictionary (Exp2)
├── Hu_2015_unpub_Exp1.json                      ← machine-readable metadata (Exp1)
├── Hu_2015_unpub_Exp2.json                      ← machine-readable metadata (Exp2)
├── Hu_2015_unpub_subj_info.xlsx                 ← participant information table
├── Hu_2015_unpub_questionnaire.xlsx             ← questionnaire data
└── Readme.md                                    ← this document (Chinese & English)
```

| File | Description |
|---|---|
| `data/sub-<ID>/Hu_2015_unpub_Exp1_<ID>_Clean.xlsx` | Cleaned trial-level data of Experiment 1, one file per participant (19 columns) |
| `data/sub-<ID>/Hu_2015_unpub_Exp2_<ID>_Clean.xlsx` | Cleaned trial-level data of Experiment 2, one file per participant (24 columns) |
| `Codebook_Hu_2015_unpub_Exp1_Clean.xlsx` | Variable dictionary for Experiment 1 (name, meaning, value coding, type) |
| `Codebook_Hu_2015_unpub_Exp2_Clean.xlsx` | Variable dictionary for Experiment 2 |
| `Hu_2015_unpub_Exp1.json` | Machine-readable metadata of Experiment 1 (schema_version 2) |
| `Hu_2015_unpub_Exp2.json` | Machine-readable metadata of Experiment 2 (schema_version 2) |
| `Hu_2015_unpub_subj_info.xlsx` | Participant information (`Subject_ID, Age, Gender, Handedness, BDI_Score, BAI_Score`) |
| `Hu_2015_unpub_questionnaire.xlsx` | Questionnaire data (sheets `All_Data_Original`, `scores`) |

## Field standard

The final column order of the cleaned trial files is given below (see the codebook for full value coding).

### Experiment 1 (19 columns)

`Subject, Clock.StartTimeOfDay, Task, Session, SubTrial, BlockList.Sample, Matching, Shape, Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity, Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity, CorrectAnswer, ACC, Response, RT_ms`

| Variable | Meaning | Value / Unit |
|---|---|---|
| `Subject` | participant ID | 6001–6036 |
| `Clock.StartTimeOfDay` | trial start time of day | datetime (m/d/yy h:mm); NA = missing |
| `Task` | task type | self-matching / reward / emotion; NA = undetermined |
| `Session` | session number | 1–7 |
| `SubTrial` | trial stage | 1 (practice); 2–3 (formal) |
| `BlockList.Sample` | block number | 1–2; NA = practice / other task |
| `Matching` | matching | Matched / Mismatched; NA |
| `Shape` | shape stimulus | Circle / Diamond / Trapezoid / Pentagon / Square / Triangle |
| `Shape_Origin_Identity` | shape original identity | self / other / happy / neutral / 1 / 16 |
| `Shape_English_Identity` | shape English identity | Self / Other / Happy / Neutral / Low_reward / High_reward |
| `Shape_Standardized_Identity` | shape standardized identity | Self / Stranger / Happy / Neutral / Low_reward / High_reward |
| `Label` | label word | 你 / 生人 / 高兴 / 中性 / ￥1 / ￥16 |
| `Label_Origin_Identity` | label original identity | 你 / 生人 / 高兴 / 中性 / ￥1 / ￥16 |
| `Label_English_Identity` | label English identity | Self / Other / Happy / Neutral / Low_reward / High_reward |
| `Label_Standardized_Identity` | label standardized identity | Self / Stranger / Happy / Neutral / Low_reward / High_reward |
| `CorrectAnswer` | correct answer | 1 / 2 |
| `ACC` | accuracy | 1 = correct; 0 = error; NA = no response |
| `Response` | key response | 1 / 2; NA = no response |
| `RT_ms` | reaction time | numeric (ms); NA = no response |

### Experiment 2 (24 columns)

`Subject, Clock.StartTimeOfDay, Task, Session, BlockList.Sample, TrialList, TrialList.Cycle, Matching, Shape, Shape_Origin_Identity, Shape_English_Identity, Shape_Standardized_Identity, Selfpic, Friendpic, Strangerpic, Label, Label_Origin_Identity, Label_English_Identity, Label_Standardized_Identity, Emotion, CorrectAnswer, Response, RT_ms, ACC`

| Variable | Meaning | Value / Unit |
|---|---|---|
| `Subject` | participant ID | 6001–6036 |
| `Clock.StartTimeOfDay` | trial start time of day | datetime; NA = missing |
| `Task` | task type | self-matching |
| `Session` | session number | 1–7 |
| `BlockList.Sample` | block number | 1–6; NA = practice |
| `TrialList` | trial order | 1–36; NA = practice |
| `TrialList.Cycle` | trial cycle | 2–36; NA = practice |
| `Matching` | matching | Matching (n) / Nonmatching (m) |
| `Shape` | shape stimulus | c / hc / vc × 4 emotions, 12 combinations |
| `Shape_Origin_Identity` | shape original identity | self / friend / stranger |
| `Shape_English_Identity` | shape English identity | self / friend / stranger |
| `Shape_Standardized_Identity` | shape standardized identity | self / friend / stranger |
| `Selfpic` | self picture code | c / hc / vc |
| `Friendpic` | friend picture code | c / hc / vc |
| `Strangerpic` | stranger picture code | c / hc / vc |
| `Label` | label word | 自己 / 朋友 / 生人 |
| `Label_Origin_Identity` | label original identity | self / friend / stranger |
| `Label_English_Identity` | label English identity | self / friend / stranger |
| `Label_Standardized_Identity` | label standardized identity | self / friend / stranger |
| `Emotion` | emotion | happy / sad / neutal (=neutral) / control |
| `CorrectAnswer` | correct answer | m / n |
| `Response` | key response | m / n; NA = no response |
| `RT_ms` | reaction time | numeric (ms); NA = no response |
| `ACC` | accuracy | 1 = correct; 0 = error; NA = no response |

## Data cleaning

### Experiment 1

1. **Column merging** — the parallel per-task columns `BlockList.Sample/E/S`, `Target.ACC/E/S`, `Target.RESP/E/S`, and `Target.RT/E/S` were merged into `BlockList.Sample`, `ACC`, `Response`, and `RT_ms`.
2. **Column renaming** — `Match` → `Matching`; `ShapeE` → `Shape_Origin_Identity`.
3. **New `Shape` column** — filled from the raw `.txt` stimulus export, mapping stimulus codes to English shape names.
4. **Identity columns** — three columns added after `Shape` and three after `Label`, recording original / English / standardized identity.
5. **`Task` column** — task label added immediately after `Subject`.
6. **De-identification** — `Handedness` and `Sex` extracted into `Hu_2015_unpub_subj_info.xlsx` and removed from the trial files.
7. **Missing-value harmonization** — empty `BlockList.Sample` and `Response` cells filled with `NA`; for rows where `Response` is missing, `RT_ms` (originally 0) was set to `NA`, and `ACC` aligned to `NA`.
8. **Clock column** — `Clock.StartTimeOfDay` restored from the raw data as the second column.

### Experiment 2

1. **Column renaming** — `Target.ACC` → `ACC`, `Target.RESP` → `Response`, `Target.RT` → `RT_ms`, `Target.CRESP` → `CorrectAnswer`.
2. **Redundant-column removal** — `Clock.StartTimeOfDay` (temporary) and `Words_en` removed; `Clock.StartTimeOfDay` subsequently restored as the second column.
3. **New `Task` column** — all rows filled with `self-matching`.
4. **New `Matching` column** — derived from `CorrectAnswer` (`n`→Matching, `m`→Nonmatching).
5. **`Shape` column** — `Target` renamed to `Shape` and repositioned after `Matching`.
6. **Identity columns** — `Shape_*_Identity` (filled from the self/friend/stranger picture columns) and `Label_*_Identity` (filled from `Words_en`) added.
7. **Picture columns** — `Friendpic` added (all rows `hc`); `Stranger` renamed to `Strangerpic`.
8. **De-identification** — `Handedness` and `Sex` removed once verified.
9. **Column ordering** — `ACC` moved to follow `RT_ms`.

## Usage

- **Data format**: Excel (.xlsx), UTF-8 encoding; R, Python (pandas / openpyxl), etc., are recommended.
- **Variable coding** is documented in the accompanying codebooks (`Codebook_Hu_2015_unpub_Exp1/Exp2_Clean.xlsx`), which are the authoritative reference for value labels and units.
- **Missing data** are uniformly coded as `NA` (no response / missing / empty, never `0`); treat `NA` as a missing value in analysis.
- **`Task` meaning**: in this dataset `Task` labels the association/task type (`self-matching` / `reward` / `emotion`). This differs from the `TrialType` column (`match` / `mismatch` / `fill`) in `Zhou_2023_unpub_Exp1`; reconcile this difference before merging across datasets.
- **Version**: data schema aligned with the SPE_Database standard v0.1.5; metadata `schema_version` 2.
- **Ethics**: the data have been de-identified and contain no personally identifiable information.
