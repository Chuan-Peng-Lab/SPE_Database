# Wu_2026_Chinaxiv 入库计划

> 制定日期：2026-10-06（第五轮更新：新增 **§5.1 Codebook 编写计划** 与信息缺口清单）。
> 依据：`spe-database-curation` 技能（10 步流程 + 起点判定 + exp JSON v2 五字段组）、原始导出与作者代码
> 实测、两份 AsPredicted 预注册、§2 的用户决策。
>
> **冲突问题汇总入口 = §10（本研究独立编号 Issue 1–8）**；**Codebook 编写计划与信息缺口 = §5.1**。
>
> **执行状态（2026-10-06）：已全部入库。** 产物 = `Exp1/`、`Exp2/` 各 5 类标准文件（Clean 109,040 / 38,544 行，
> raw 14.0 / 36.1 MB 与 5.0 / 13.5 MB，均 < 50 MB 无需分片）+ `Wu_2026_Chinaxiv.json` + `Wu_2026_Chinaxiv_clean.R`；
> 主索引 3 行（`Wu_2026_Chinaxiv_Exp1_motion/colour`、`_Exp2_All`）；两级校验 `validate_json_metadata.R` EXIT=0、
> `validate_clean_csv.R` 0 ERROR / 29 WARN（W5 两条已按决策 15 登记豁免）；Table 1 已重跑（116 行 / 51 studies）。
> 入库后交叉核验（§4.3 + Exp1 detail 末段）：Exp1 匹配 SPE 复算 +80.4（全试次）/ +96.3（仅正确试次）vs 稿件 +79.49 ms，
> 不匹配 +18.4 vs +16.52，辨别 ≈0；Exp2 采纳 raw 口径（不匹配 −46.8 vs 稿件 −50.53）。

## 0. 研究概况与来源

| 项 | 内容 |
|---|---|
| 论文 | 自我相关性对知觉决策中自我优势效应的影响：任务相关性的调节作用（中文） |
| 作者 | 邬思宇、胡传鹏（南京师范大学心理学院，南京，210024）；通讯邮箱 hcp4715@hotmail.com |
| 来源 | ChinaXiv 预印本 `https://www.chinaxiv.org/abs/202606.00118`（2026-06） |
| DOI | `10.12074/202606.00118`（用户确认；存裸格式） |
| 数据仓库 | `https://github.com/Wsy122/SPE_Rand_Dots`（用户确认；两份预注册均链接该仓库） |
| 预注册 | Exp1 AsPredicted **#246,312**（2025-09-09）`https://aspredicted.org/rmsm-tzcz.pdf`；Exp2 **#281,213**（2026-03-24）`https://aspredicted.org/qy5ky9.pdf` |
| 全文 | `REF/Wu_2026_Chinaxiv.md`（2026-10-06 由 `REF/Wu_2026_Chinaxiv.docx` 转换；GFM，14 表 + `Wu_2026_Chinaxiv_files/` 14 图） |
| 原始数据 | 输入区 `1_Data/Wu_2026_Chinaxiv/Wu_2026_Chinaxiv_Raw/SPE_Rand_Dots-master/` |
| 采集时间 | **Exp1 = 2025；Exp2 = 2026**（用户 2026-10-06 定案，年级粒度） |
| 采集环境 | **两实验均为行为实验室**（用户 2026-10-06 定案，以稿件字面为准）；`Country = China`、`City = Nanjing` |
| 数据许可 | `CC BY 4.0`（项目负责人确认为自有数据） |
| 呈现软件 | jsPsych v7（`1_Procedure/exp*/jspsych-7.0`） |

## 1. 起点判定（SKILL §入库工作流）

输入区已有原始导出、无标准文件 → **起点 = 第 1–3 步（全新数据全流程）**，随后第 4–10 步。

## 2. 决策记录（用户 2026-10-06）

| # | 决策点 | 结论 |
|---|---|---|
| 1 | 数据集划分 | **2 个数据集 = 论文 Exp1/Exp2**；每实验 1 份 Clean，两任务用 `Task` 列区分；主索引 **3 行**（Exp1 拆 motion 70 / color 71 + Exp2 All 60）；布局 `Wu_2026_Chinaxiv/Exp1|Exp2/` |
| 2 | `Task` 列取值 | 匹配任务 = `self-matching`；辨别任务 = **`choice-task`**（登记进 SKILL 受控值清单） |
| 3 | 辨别任务的 `Shape` / `Label` | `Shape` = 承载身份的感觉特征（运动组 `left`/`right`；颜色组 `blue`/`red`，按被试绑定恢复）；`Label` = 该特征所指身份标签（`我`/`他`/`她`）；Codebook 注明辨别任务未呈现标签 |
| 4 | 试次保留 | **全部保留**：`Phase = staircase / practice / main`；主索引 `numTrials` 记正式试次。**2026-10-06 修订**：色盲筛查行为**问卷题、非实验试次** → 不入 Clean，答案转 `subj_info`（用户确认，见 §5.1 缺口 1） |
| 5 | 辨别任务 `Matching` | 填 `NA` + `validate_clean_csv.R` 的 `known` 例外登记（§9 第 4 条） |
| 6 | License | `CC BY 4.0` |
| 7 | 作者清洗产物不一致 | **按 raw 重建 Exp1 + Exp2**；作者产物仅作参照；发现汇总登记于本计划 §10 + exp JSON `detail` + 主索引 `Note` |
| 8 | 采集时间 | Exp1 = `2025`、Exp2 = `2026`（年级粒度，不追精确月份） |
| 9 | 采集环境 | **两实验均 `Setting = Laboratory`**（以稿件字面为准；`Country = China`、`City = Nanjing`） |
| 10 | 显示器参数 | **按稿件记录 23.8 英寸 / 1080 × 768 / 60 Hz**；raw 的 canvas 宽 1920 px 与像素-视角核算结果记入 `detail`（§3.6） |
| 11 | 是否联系作者 | 由项目负责人决定（超库范围不主动执行） |
| 12 | Exp2 数据版本 | **按 raw 重建**（作者 `CleanData` 仅作参照）；三版本冲突登记 Issue + exp JSON `detail` + 主索引 `Note` |
| 13 | 稿件口径不一致 | **先登记 Issue + `detail`，本轮不改稿件**（Exp2 试次数 256→192、RT 窗口 3000→4000 ms 待预印本修订时处理） |
| 14 | Exp2 5 人 canvas 宽 1440–1536 px | **仅作 `detail` 记录**（不追查、不阻塞入库） |
| 15 | 校验脚本 W5 | **修改 `validate_clean_csv.R`，按 W4 同款模式让 W5 读取 `known`**，并登记 `Wu_2026_Chinaxiv_Exp1` / `_Exp2` 两条（存量 Zhang_2023 / Hu_YQ 的 W5 告警不受影响） |
| 16 | 报酬形式 / 伦理批号 | **不填**（论文未报告，且不在 exp JSON schema 内） |

## 3. 已核实的数据结构与实施细节

### 3.1 被试与样本

| 实验 / 组 | 人数 | 被试编号 | 文件数 | 论文报告 |
|---|---|---|---|---|
| Exp1 运动组 | 70 | 1–70 | 70 | 招募 75，5 人未通过练习 → 70（56 女/14 男，*M*<sub>age</sub> = 21.02，*SD* = 2.07） |
| Exp1 颜色组 | 71 | 71–141 | 71 | 招募 75，4 人未通过练习 → 71（56 女/15 男，*M*<sub>age</sub> = 20.35，*SD* = 1.96） |
| Exp2 | 60 | 1–30、36–65（缺 31–35） | 60 | 招募 65，5 人未通过练习 → 60（49 女/11 男，*M*<sub>age</sub> = 22.67，*SD* = 1.98） |

- 未通过练习者的编号在 raw 中整体缺席 → `Sample_Size` = `Valid_Subj` = 70 / 71 / 60，`Drop_Subj` = 0。
- 人口学由每个 raw 文件的 `survey` 行生成（`sex` / `age` / `hands` / `color_blindness`），与论文数字核对。

### 3.2 设计与自变量

- **Exp1**：2（association，被试内）× 4（difficulty，被试内）× 2（perceptual dimension：motion/color，
  **被试间**，编号 1–70 / 71–141 固定分组）混合设计；先匹配任务、后辨别任务。
- **Exp2**：2（association）× 2（difficulty：easy/hard）× 2（task relevance：relevant/irrelevant，被试内、
  分块、顺序被试间平衡）；**关联维度为被试间平衡变量**（实测：编号 1–30 关联运动方向、36–65 关联颜色，30/30 对分）。

### 3.3 试次结构与分块（raw 实测，被试间一致）

| 实验 | Phase | 试次数 | 分块结构 |
|---|---|---|---|
| Exp1 | （非试次） | 1（色盲图片筛查，`part = color_test`、`trial_type = survey-text`）——**问卷题，不入 Clean**（§5.1 缺口 1） | — |
| Exp1 | `staircase` | 96（8 组 × 12；运动组 `motion_test`、颜色组 `color_test`） | 8 组 |
| Exp1 | `practice` | 逐人：匹配 32–544、辨别 16–64 | 32/轮（辨别 16/轮），达 65% 进入正式段 |
| Exp1 | `main` | 匹配 **384**（16 条件 × 24）+ 辨别 **192**（8 × 24） | 匹配 8 块 × 48；辨别 4 块 × 48 |
| Exp2 | `staircase` | 96（`motion_test` 48 + `color_test` 48；另有 1 个色盲筛查问卷题不入 Clean） | 8 组 |
| Exp2 | `practice` | 逐人：匹配 32–384、辨别 16–224 | 32/轮（辨别 16/轮） |
| Exp2 | `main` | 匹配 **192**（8 × 24，60 人一致）；辨别 **192–288**（逐人，序列设计提前停止） | 匹配 4 块 × 48；辨别每相关块 4 块 × 32 |

- 计划写入 Clean 的行数：**Exp1 = 109,040 行**、**Exp2 = 38,544 行** → 均 < 50 MB，**无需分片**。
- 主索引 `numTrials`：Exp1 = `576`；Exp2 = `192 (matching) + 192-288 (choice task, adaptive stopping)`。
- 反应窗口 = **3000 ms**（raw 全部试次 `trial_duration = 3000`、`response_ends_trial = true`）。

### 3.4 两个版本的程序文件（重要）→ Issue 5

Exp2 有 7 个早期版本导出（被试 **25、26、27、28、58、59、60**）：表头无 `task_type` 列，且"非关联维度"块
（如关联运动者的 `RDK_color` 块）`association` 字段为空 → 按该被试正式匹配段的绑定重建身份，按
"块维度 == 关联维度 → relevant"推出任务相关性；重建须在 Codebook + exp JSON `detail` 双处标注。

### 3.5 身份绑定（逐被试平衡、可从 raw 恢复）

- 运动组：`coherent_direction` 0/180 ↔ self/other（subj1：0 = self；subj2：180 = self）。
- 颜色组：`dot_color_final` 顺序 ↔ self/other（`hsl(225,50%,50%)` = 蓝、`hsl(0,50%,50%)` = 红）。
- 程序内置两套反向绑定数组（`conditions_match_selfLeft` / `conditions_match_selfRight`）→ 与数据一致。
- 实验后问卷（`survey_isMatch`）收集被试自报绑定 → 作操纵检查写入 subj_info。
- 标签：匹配任务呈现 "我" / "他"（女被试为 "她"）；辨别任务不呈现标签。

### 3.6 采集环境与设备（证据与遗漏）

- 稿件 Exp1 §2.1.2：23.8 英寸屏、分辨率 1080 × 768、60 Hz、视距 60 cm、下巴托架、安静无光线干扰的行为实验室；
  稿件 Exp2 §3.1.2 仅写"仪器与材料均与实验1相同"→ **两实验按实验室记录**（用户定案）。
- 程序侧一致证据：`jsPsychFullscreen`（全屏成功 141/141、60/60）；虚拟下巴托架段（`card` / `resized_stimulus`）
  在最终时间线中**被注释掉**——与实验室使用实体下巴托架的描述一致 ✓。
- 设备指纹：canvas 宽度随浏览器窗口（`window.innerWidth`）。Exp1 正式匹配任务 **141/141 均为 1920 px**；
  Exp2 为 1920（55 人）、**1536（3 人）、1440（2 人）**。→ 5 名 Exp2 被试的窗口更窄，原因未明
  （另一台设备/窗口未全屏/缩放差异；属待记录项）→ **Issue 7**。
- 分辨率与刺激物理尺寸的核算（记入 `detail`，不改变 §2 决策 10）→ **Issue 6**：按 23.8 英寸 16:9 屏、视距 60 cm
  （屏宽视角 47.4°）：若屏宽 **1080 px** → 孔径 300 px = **13.2°**、点直径 6 px = **0.263°**
  （与稿件 8°、0.15° 不符）；若屏宽 **1920 px** → 孔径 = **7.4°**、点直径 = **0.148°**
  （与稿件 8°、0.15° 吻合）。即稿件"1080 × 768"与其自身的视角数值不自洽，raw canvas 宽 1920 px 支持
  实际为 1920 × 1080 —— 本项仅作 `detail` 说明，字段值仍按稿件填（用户决策 10）。

## 4. 三方核对：原始导出 ↔ 作者清洗产物 ↔ 稿件

复核方法：以 raw 逐被试导出为基准，按作者代码记录的规则重构（`part` 过滤、练习段剔除、RT 窗口；
模型用 `correct == 1`），与作者 `3_Data/*/CleanData/*.csv` 做被试级计数 + 逐行取值多重集比对，再与稿件
简单效应（他人−自我）对照。**方法校准**：Exp1 由 raw 复算得运动组匹配 +80.4 ms（几何均值差）、
颜色组 +85.3 ms、辨别 ≈0，与稿件 +79.49 / +80.13 / ≈0 吻合（误差 1–5 ms）→ 方法可靠。

### 4.1 Exp1：作者产物与 raw 完全可复现 ✅

- `data_motion.csv`（70 人 38,953 行）：逐被试行数 **70/70 一致**，抽查 subj 3、42 逐行取值相同。
- `data_color.csv`：71 名颜色组被试同样一致（抽查 subj 100、141 逐行相同）。
- **作者侧缺陷**：`data_color.csv` 额外含 **Subject 70** 的 563 行（与 `data_motion.csv` 中该被试在共有列上
  逐行相同）→ 重复计数；原因 = 作者代码第 322 行 `subj_idx %in% seq(70, 141)` 与其分组定义（71–141）差一位。
- 结论：**Exp1 稿件模型所用数据 = 库内 raw 正式段（[100, 3000] ms）+ `correct == 1`**。
- **→ Issue 1**（`data_color` 含 Subject 70 的重复计数）。

### 4.2 Exp2：作者共享产物与 raw **无法对应** ❌

| 检查项 | 结果 |
|---|---|
| 逐被试行数（`data_match.csv`） | 95–256 行/人（均值 202），与 raw 正式匹配段固定 192 不符 |
| 条件格平衡 | 8 格完全平衡者仅 **2/60** 人 |
| 逐行可追溯性（60 人） | 仅 **6,193/12,113（51.1%）** 可在该被试 raw `match_RDK` 中找到；**30/60 人 < 50%**（12 人 ≤ 2 行） |
| `data_rdk.csv` | 可追溯 **6,708/13,736（48.8%）**，24 人 < 50% |
| 内部关系 | `data_all.csv` = `data_match.csv` + `data_rdk.csv` ✅ |
| 不可追溯者编号 | **奇偶交替**（1、3…29 与 36、38…64 可追溯；2、4…30 与 37、39…65 不可追溯）→ 提示两批导出的编号映射问题 |

**→ Issue 2**（Exp2 作者产物与 raw 不可对应，含三版本与代码路径问题）。

### 4.3 稿件、raw、作者产物三方数值对照（Exp2，他人−自我 ms）

稿件：匹配条件 **+112.11**（[24.87, 198.32]）；不匹配 **−50.53**（[−142.18, 42.21]）；辨别 β = **0.01**（[−0.02, 0.05]）
≈ 0。全部按分析代码规则 `correct == 1` 复算：

| 来源 | 匹配 | 不匹配 | 辨别（relevant / irrelevant） | \|Δ\|匹配 | \|Δ\|不匹配 |
|---|---|---|---|---|---|
| **raw 正式段，100–4000 ms**（Exp2 预注册窗口）算术 | +57.1 | **−46.8** | −7.1 / −21.8 | 55.0 | **3.7** |
| raw 正式段，100–4000 ms 几何 | +63.7 | −43.5 | −0.6 / −18.7 | 48.4 | 7.0 |
| raw 正式段，100–3000 ms（稿件文字窗口）算术 | +63.0 | −22.7 | −15.4 / −34.9 | 49.1 | 27.9 |
| 作者 `data_all.csv`（as-is）算术 | +70.8 | +8.1 | +36.6 / +7.7 | **41.3** | 58.6 |
| 作者 `data_all.csv`（as-is）几何 | +74.5 | +2.2 | +35.7 / +6.3 | **37.6** | 52.8 |

**结论——raw 更贴近稿件**：① 稿件最具体的指纹"不匹配条件反转"（−50.53）raw 几乎命中（**−46.8**，差 3.7 ms），
作者数据方向相反（+8.1）；② 辨别任务 ≈0：raw 为 −7.1/−21.8（relevant 几何 −0.6），作者数据出现稿件未报告的
+36.6/+7.7；③ 正确率上稿件报告无稳定自我优势（β = −0.28，CI 含 0），raw ≈0，作者数据为 +3.4 pp。
仅匹配条件量级作者略近（|Δ| 37.6 vs 44.8），但两者都在稿件宽 CI 内。

**版本问题**：`BHM_Analysis.Rmd` 声明 Exp2 输入为 `../../3_Data/3_2_exp2/CleanData/data_all.csv`（该路径在
仓库中不存在）→ 作者侧至少存在**三个数据版本**（raw 导出 / 仓库 CleanData / 稿件实际分析数据）。

**→ Issue 2**（三版本与代码路径）、**→ Issue 3**（匹配试次数 192 vs 256）。

### 4.4 预注册证据

| 项 | Exp1（#246,312） | Exp2（#281,213） |
|---|---|---|
| 设计 | 2 × 4 × 2 混合 | 2 × 2 × 2 被试内 |
| 试次计划 | 未规定每条件试次数 | **"32 trials per condition"**（仅针对辨别任务） |
| 剔除规则 | RT < 100 ms 或 **> 3000 ms** | RT < 100 ms 或 **> 4000 ms** |
| 停止规则 | BF₁₀ ≥ 10 或 ≤ 0.1；最多 70 人/任务 | 同；最多 60 人 |

- **更正第一轮结论**：作者 Exp2 三个文件的实际窗口是预注册的 **[100, 4000] ms**（`data_all` 的 rt 最大值恰为
  4.000 s、最小值 0.174 s）；**稿件文字与 exp2 代码注释写 3000 ms**。Exp1 的预注册、稿件、代码、数据四者一致
  （3000 ms）→ Exp2 属**稿件 vs 预注册**的表述不一致，不是"未过滤"。
- 稿件 Exp2 匹配任务"每条件 32、共 256"与 raw 实测（4 块 × 48 = 192 = 24/条件）不符；预注册的"32/条件"只针对
  辨别任务，且辨别任务 raw 实测每相关块 4 块 × 32（4 条件 × 32 = 128 ✓）→ **匹配任务的 256 为稿件笔误**
  （同理 Exp1"每个条件下48个试次，共384"应为"每**组块** 48 个"）。

**→ Issue 3**（匹配试次数与 Exp1 措辞）、**→ Issue 4**（RT 剔除窗口 4000 vs 3000 ms）。

### 4.5 处置原则

标准文件一律从 raw 重建；作者 `CleanData/*` 仅作参照、不修改不删除；所有冲突/不一致问题**统一登记、
编号与处置见 §10 Issues 清单**（本研究独立编号，仅登记于本计划与库内 `detail`/`Note`）。

## 5. 目标产物清单

```
1_Data/Wu_2026_Chinaxiv/
├── Wu_2026_Chinaxiv.json                    # paper 级元数据（flat 11 字段）
├── Wu_2026_Chinaxiv_clean.R                 # 独立清洗脚本（输出 Exp1/Exp2 产物）
├── Exp1/  Wu_2026_Chinaxiv_Exp1.json / _raw.csv / _Clean.csv / _subj_info.csv
│          Codebook_Wu_2026_Chinaxiv_Exp1_Clean.xlsx      # Clean 109,040 行
└── Exp2/  Wu_2026_Chinaxiv_Exp2.json / _raw.csv / _Clean.csv / _subj_info.csv
           Codebook_Wu_2026_Chinaxiv_Exp2_Clean.xlsx      # Clean 38,544 行
```

**Clean 列序（模板 v2 对齐，脚本内 `stopifnot()` 检查）**：
`Subject → Group → Task → Phase → Block → Trial → Matching → Shape →
Shape_Origin_Identity → Shape_English_Identity → Shape_Standardized_Identity → Label →
Label_Origin_Identity → Label_English_Identity → Label_Standardized_Identity →
extraIV1 → [extraIV2] → Response → RT_ms → ACC`

（**无 `Condition`、无 `Session`、无 `CorrResponse`、无研究特有尾部列**；Exp1 无 `extraIV2`，Exp2 有。）

**自变量映射**（依据 SKILL「联结含自参照身份 → self-matching，**任务内其他操纵归 extraIV**」+
「`extraIV1`/`extraIV2` = 第 3/4 自变量」；全部设计自变量落入标准列，**不落尾部**）：

| 自变量 | 两实验取值 | 承载列 |
|---|---|---|
| 第 1 自变量 association（self/other） | self / other | `Shape`/`Label` 的 Identity 三级（Standardized = `Self`/`Stranger`，非单独列） |
| 第 2 自变量 matchness（匹配/不匹配） | match / mismatch | `Matching` |
| 第 3 自变量 difficulty（知觉难度） | Exp1：very_easy/easy/difficult/very_difficult；Exp2：easy/hard | **`extraIV1`** |
| 第 4 自变量 task relevance（任务相关性） | relevant / irrelevant（仅 Exp2 辨别任务） | **`extraIV2`** |
| 组间自变量（Exp1 知觉维度 / Exp2 关联维度） | motion / color | `Group` |

- `Group`：Exp1 = `motion`/`color`（设计组，编号 1–70 / 71–141）；Exp2 = `motion`/`color`（关联维度，
  被试间平衡变量，编号 1–30 / 36–65；同时写入 subj_info）。
- `Task`：`self-matching`（匹配任务）/ `choice-task`（辨别任务）；两任务同 session 内先后完成，由 `Task` 区分。
- `Phase`：`staircase` / `practice` / `main`（色盲筛查行属问卷题、不入 Clean，见 §5.1 缺口 1）。
- `Matching`：`Matching`/`Nonmatching`；`choice-task` 与 `staircase` 行 = `NA`（登记豁免，§10 Issue 无关，属任务结构）。
- `extraIV1`（difficulty）：Exp1 = `very_easy`/`easy`/`difficult`/`very_difficult`（raw `difficulty` 1–4 映射，
  作者代码 `factor(levels=c(1,2,3,4), labels=c("very easy","easy","difficult","very difficult"))`，对应阶梯目标
  90/80/70/60%）；Exp2 = `easy`/`hard`（raw 原样）；`staircase` 行 = `NA`（此时难度尚在标定）。
- `extraIV2`（task relevance，仅 Exp2 辨别任务）：`relevant`/`irrelevant`；匹配任务与 `staircase` 行 = `NA`；Exp1 无此列。
- `Shape`：承载身份的感觉特征值 `left`/`right`（运动组）或 `blue`/`red`（颜色组），由 raw `coherent_direction` /
  `dot_color_final` 按被试绑定恢复（§3.5）；Identity 三级 Origin 原文 → English（`Left`/`Right`/`Blue`/`Red`）→
  Standardized（`Self`/`Stranger`）。
- `Label`：`我`/`他`/`她`（辨别任务未实际呈现，Codebook 注明）；Identity 三级 → Standardized `Self`/`Stranger`。
- `Response`：实际按键（`f`/`j` 或 `arrowleft`/`arrowright`）；`RT_ms` 保留原始毫秒值；`ACC` 按 SKILL 统一编码（无反应 = `NA`）。
- **不设 `CorrResponse`**：raw 的 `correct_response`/`correct_choice` 导出为空（`correct` 由插件运行时计算后写回，
  无可直接取用的正确键列；SKILL「仅当 raw 有 CRESP/CorrectAnswer 类列可直接取时补，否则不加」）。
- **不设研究特有尾部列**（原计划的 `Coherence`/`Judged_Dimension`/`Staircase_Target_Accuracy` 全部移出 Clean）：
  - `Judged_Dimension`（Exp2 判断维度）可由 `Group × extraIV2` 完全推导 → 冗余编码，删除（raw `part` =
    `RDK_motion`/`RDK_color` 保留原值）；
  - `coherence` / `target_color_proportion`（difficulty 的物理实现，逐被试阶梯标定）→ 刺激参数，保留在 `*_raw.csv`，
    不入 Clean；Codebook 与 exp JSON `detail` 说明其与 `extraIV1` 的对应关系；
  - `Staircase_Target_Accuracy` → 阶梯段参数，仅存 raw。
- `Block`/`Trial` 编号须保证 `(Subject, Block, Trial)` 唯一（跨 `Task`/`Phase` 连续编号，或按 phase 内编号并在 Codebook 说明）。
- Exp2 辨别任务两相关块的**呈现顺序**（相关先/无关先，被试间平衡）不是设计自变量，可由 raw 块序推导 → 写入
  `*_subj_info.csv`（如 `Relevance_Block_Order`）备查，不入 Clean 列。

### 5.1 Codebook 编写计划（含信息缺口）

**规格**（SKILL §Codebook 编写规则）：每份 `*_Clean.csv` 配 1 个 `Codebook_<Folder_Name>_Exp<N>_Clean.xlsx`
（同目录、canonical `Codebook_` 小写 b）；单 `Sheet1`、恰 4 列
`Variable_name | Variable_description | Variable_value | Variable_category`；**每个 Clean 列恰 1 行、行序 == Clean 列序**；
描述用 plain English；`Variable_value` 数值列写单位或 `Number`、分类列用 `;` 分隔列全部取值（**含 `NA` 等特殊值**）；
用 openxlsx / openpyxl 生成，禁止手改 xlsx XML。

**生成工具与所需扩展**：用 `2_Code/make_codebooks.R`（jobs 列表 → xlsx；值枚举取数据 `unique()`；
`Rscript 2_Code/make_codebooks.R Wu_2026_Chinaxiv` 可按子串只跑 Wu 的 job）。但该脚本的 `describe()` 是**全库泛化描述**，
且对未映射列**静默写 `"NA"`** → 不满足 SKILL「研究特有语义必须登记 Codebook」→ 需为 jobs 增加**逐任务描述覆盖**
（per-job `desc` 表，向后兼容其他 job；与决策 15 的校验脚本改动同性质）；否则
`Group`/`Task`/`Phase`/`Shape`/`Label`/`extraIV1`/`extraIV2`/`ACC`/`RT_ms`/`Response` 的描述不达标。

**逐列内容计划**（两实验共用，差异处已注明；拟写英文描述）

| Clean 列 | `Variable_description`（拟写） | `Variable_value` | Category |
|---|---|---|---|
| `Subject` | Participant number as used by the authors in the shared repository (raw files `exp1_subj_<N>.csv` / `exp2_subj_<N>.csv`). Exp1: 1–70 = motion group, 71–141 = colour group. Exp2: 1–30 and 36–65 (31–35 not shared after failing practice) | Number | Numerical |
| `Group` | Between-subjects factor. Exp1: perceptual dimension of the RDK task (motion = judge overall motion direction; colour = judge dominant colour). Exp2: the dimension associated with the identity, counterbalanced across participants | motion; colour | Categorical |
| `Task` | Task type. `self-matching` = identity-matching task (learned feature–identity association; identity-bearing feature = RDK motion direction or dominant colour, label = image of 我/他/她). `choice-task` = two-alternative feature discrimination of the random-dot kinematogram (no matching judgement) | self-matching; choice-task | Categorical |
| `Phase` | Session phase. `staircase` = adaptive threshold estimation (8 groups × 12 trials) run before the association instructions; `practice` = association practice blocks (criterion ≥65% correct); `main` = formal blocks | staircase; practice; main | Categorical |
| `Block` | Block number; delimited by self-paced rest breaks and numbered according to the scheme documented here（写法随 §5.1 缺口 3 的定案） | Number | Numerical |
| `Trial` | Trial number within the block | Number | Numerical |
| `Matching` | Whether the presented feature–label pair agrees with the association learned before the task. `NA` = not applicable (choice-task and staircase trials have no matching dimension) | Matching; Nonmatching; NA | Categorical |
| `Shape` | Identity-bearing stimulus layer: the RDK feature associated with an identity — motion direction (`left`/`right`) for the motion group, dominant colour (`blue`/`red`) for the colour group. The feature–identity binding was counterbalanced across participants (self = left/right; self = blue/red). **Not a geometric shape** | left; right; blue; red | Categorical |
| `Shape_Origin_Identity` | Identity of the shape-side stimulus as recorded in the raw data (raw column `association`) | self; other; NA | Categorical |
| `Shape_English_Identity` | English form of the raw identity label | Self; Other; NA | Categorical |
| `Shape_Standardized_Identity` | Standardized identity category: `Self` = self-associated feature, `Stranger` = other-associated feature; `NA` = no identity established yet (staircase trials) | Self; Stranger; NA | Categorical |
| `Label` | Identity label presented as an image in the matching task (我 = self; 他/她 = other, matching the participant's gender). Not presented in the choice task, where the value is the identity the feature is associated with | 我; 他; 她; NA | Categorical |
| `Label_Origin_Identity` | Identity of the label as recorded in the raw data (raw column `label`) | 我; 他; 她; NA | Categorical |
| `Label_English_Identity` | English form of the label identity (我 = Self; 他/她 = Other) | Self; Other; NA | Categorical |
| `Label_Standardized_Identity` | Standardized identity category of the label | Self; Stranger; NA | Categorical |
| `extraIV1` | Difficulty level (manipulated IV 3). Exp1: `very_easy`/`easy`/`difficult`/`very_difficult` (raw `difficulty` 1–4; staircase targets ≈90/80/70/60% correct). Exp2: `easy`/`hard` (≈85%/70%). Implemented as RDK coherence (motion group) or target-colour proportion (colour group), titrated per participant by the staircase; those physical values stay in the raw file (`coherence` / `target_color_proportion`). `NA` = not applicable (staircase trials) | Exp1: very_easy; easy; difficult; very_difficult; NA ／ Exp2: easy; hard; NA | Categorical |
| `extraIV2`（仅 Exp2） | Task relevance of the association (manipulated IV 4): `relevant` = the judged feature is the identity-associated feature; `irrelevant` = the judged feature is the other feature; `NA` = not applicable (matching task and staircase trials) | relevant; irrelevant; NA | Categorical |
| `Response` | Key pressed: `f`/`j` (matching task; response-to-key mapping counterbalanced across participants) or `arrowleft`/`arrowright` (choice task and staircase); `NA` = no response within the 3000 ms response window | f; j; arrowleft; arrowright; NA | Categorical |
| `RT_ms` | Reaction time in milliseconds from stimulus onset (raw column `rt`); raw value −1 (no response) is written as `NA` | Number | Numerical |
| `ACC` | Response accuracy: `1` = correct, `0` = incorrect (key within the response set), `NA` = no response (raw `rt` = −1). The raw `correct` flag is `false` for no-response trials and is not treated as an error | 1; 0; NA | Categorical |

**生成后校验**（并入 §8 清单）：行数 == Clean 列数 + 1；每个 Clean 列名在 `Variable_name` 中恰出现 1 次且顺序一致；
`Variable_description` 中**无遗留 `"NA"`**（工具对未映射列会静默写 NA，必须显式检查）；分类列 `Variable_value` 与数据
`unique()` 一致（含字面量 `NA`）；两份 Codebook 与 exp JSON `detail` 语义一致（`choice-task`、`extraIV1` = difficulty、
`extraIV2` = task relevance、`Shape` 非几何图形）。

**信息缺口（编写前需确认/补齐）**——缺口 1 已由用户确认（2026-10-06）；缺口 2–8 为拟定处置，随本计划一并执行。

1. **问卷题行的处置（已确认，决策 4 修订）**：raw 中 `survey`（人口学）、`color_test`（色盲图片筛查，1 题，
   `{"Q0":"BE"}`）、`survey_isMatch`（绑定操纵检查；运动组键 `move_left`/`move_right`，颜色组 `color_red`/`color_blue`）
   均为**问卷题而非实验试次**（`trial_type` = `survey`/`survey-text`，无 RT/ACC，response 为文本/JSON）→ **不入 Clean**；
   三处问卷答案写入 `*_subj_info.csv`（`ColorTest_Answer`、`Manip_Check_Self`/`Manip_Check_Other`）。
   `Phase` 只保留 `staircase`/`practice`/`main`。**行数不受影响**（原 109,040 / 38,544 行本就未含该行）。
2. **阶梯段各列的 NA**：raw 阶梯试次的 `association`/`difficulty`/`label` 均为空 → `Shape` 仍填呈现的特征值
   （left/right 或 blue/red），而 `Label`、`Shape/Label` 的 Identity×3、`Matching`、`extraIV1`、`extraIV2` 一律 `NA`；
   NA 语义（"该阶段尚未建立联结/不适用"）须写入 Codebook。
3. **`Block`/`Trial` 编号方案（采用建议方案）**：为满足 `(Subject, Block, Trial)` 唯一，**Block 在被试内跨 Task/Phase
   连续编号**（阶梯 8 组 → 练习 N 轮 → 正式块，按 raw 块序），**Trial = 块内序号（从 1 起）**。Codebook 的 `Block` 描述
   与此一致。
4. **`subj_info` 列集与其文档位置**：标准核心（`Subject_ID`/`Exp_id`/`Age`/`Gender`/`Handedness`/`Country`/`First_Language`）
   + 研究特有（`Group`、`Associated_Dimension`（Exp2）、`Self_Feature`（该被试自我关联的特征值，用于解读 `Shape` 的
   `blue`/`red` 与 `left`/`right`）、`Relevance_Block_Order`（Exp2）、`ColorTest_Answer`、`Manip_Check_Self`/`Manip_Check_Other`）。
   **Codebook 只覆盖 Clean 列**，subj_info 列无正式登记位 → 建议其语义在 exp JSON `detail` 中登记（本库既有做法）。
5. **无反应编码（已实测）**：raw 无反应 = `rt = -1` + `response` 空 + `correct = "false"` → Clean 必须写
   `RT_ms = NA`、`ACC = NA`、`Response = NA`；**不得**记为 ACC = 0（否则错误率被高估）。清洗脚本与 Codebook 双处明确。
6. **`coherence` / `target_color_proportion` 不在 Clean**：它们是 `extraIV1`（difficulty）的物理实现、逐被试阶梯标定
   → 仅存 raw；Codebook 在 `extraIV1` 描述中给出 raw 列名，避免下游找不到信号强度。
7. **`choice-task` 与 `Group` 的语义三处一致**：两份 Codebook、两个 exp JSON `detail`、SKILL `Task` 受控值清单（决策 2 落地）。
8. **主索引数据标志**：本研究仅有人口学 + 色盲筛查 + 绑定操纵检查，无问卷量表 → `Questionnaire_Data = 0`、
   `Behavior_Data = 1`、`EEG/fMRI Data = 0`（与库内多数条目一致；如需另计请在入库前说明）。

## 6. 实验元数据（exp JSON v2）字段完整性评估

图例：✅ 直接可填（论文/程序/数据证据）；🟡 可填但需 `detail` 注明来源或口径冲突。

### 6.1 Physical_Environment

| 字段 | 值 | 来源 | 状态 |
|---|---|---|---|
| `Location` | `Nanjing, China` | 论文署名（南京师范大学）+ 招募描述 | ✅ |
| `Setting` | `Laboratory`（两实验） | 论文 Exp1 §2.1.2 + Exp2 §3.1.2；用户定案 | ✅ |
| `Equipment.Presenting` | 实验室台式电脑（浏览器运行 jsPsych） | 论文（仅给屏幕参数） | 🟡 detail 注明未报告机型/系统/浏览器版本 |
| `Equipment.Monitor` | `23.8-inch, 1080 × 768, 60 Hz` | 论文 | ✅（`detail` 记 raw canvas 宽 1920 px 与像素-视角核算，§3.6） |
| `Equipment.Software` | `jsPsych v7` | 程序目录 + 论文 | ✅ |
| `Viewing_distance` | `60 cm (chin rest)` | 论文 | ✅ |

### 6.2 Experimental_Design / Block_Structure

| 字段 | Exp1 | Exp2 | 来源 | 状态 |
|---|---|---|---|---|
| `Conditions` | 匹配 16 条件（2 × 2 × 4）；辨别 8 条件（2 × 4）；组间：运动/颜色 | 匹配 8 条件（2 × 2 × 2）；辨别 8 条件（2 关联 × 2 难度 × 2 任务相关性） | 论文 + raw | ✅ |
| `Block_number` | 匹配 8 块 × 48；辨别 4 块 × 48 | 匹配 4 块 × 48；辨别 每相关块 4 块 × 32 | raw（141/60 人一致） | ✅ |
| `Trial_number` | 384（匹配）+ 192（辨别） | 192（匹配）+ 192–288（辨别，逐人） | raw | 🟡 与稿件 Exp2 文字冲突（**Issue 3**），detail 记录 |
| `Practice_trials` | 匹配 32/轮、辨别 16/轮；65% 达标（轮数逐人） | 同 | 论文 + 程序 + raw | ✅ |

### 6.3 Trial_Structure

| 字段 | 值（两实验相同，另注除外） | 来源 | 状态 |
|---|---|---|---|
| `Fixation_duration` | `500 ms`（白色 "+"，48 px） | 论文 + 程序（`fixation.trial_duration = 500`）+ raw | ✅ |
| `Stimulus_duration` | 直至反应（`response_ends_trial = true`），上限 3000 ms | raw | ✅ |
| `SOA` | `0 ms (simultaneous)`（散点与标签同时呈现） | 论文"同时呈现" + 程序 | ✅ |
| `ISI` | ≈ `0 ms`（注视点 offset → 刺激 onset，程序紧接） | 程序逻辑推断 | 🟡 detail 注明属推断 |
| `Stimulus_order` | `Simultaneous`（辨别任务仅呈现散点、无标签） | 论文 + 程序 | ✅ |
| `Response_deadline` | `3000 ms` | raw `trial_duration`（论文未写） | ✅ |
| `ITI` | `300–1000 ms (random)`，其后接 500 ms 注视点 | 程序 `default_iti`（论文未写） | 🟡 detail 注明来源为程序代码 |
| `Feedback_duration` | `500 ms`（仅练习段；太快 < 250 ms、无反应 = 太慢） | 论文 + 程序 `feedbackTrial` | ✅ |

### 6.4 Stimulus_Properties

| 字段 | 值 | 来源 | 状态 |
|---|---|---|---|
| `Modality` | `Visual` | 论文 + 数据 | ✅ |
| `Fixation` | 白色 "+"，48 px | raw `stimulus` + 程序 | ✅ |
| `Shape` | RDK：100 个点、点直径 0.15°、孔径 8°、速度 3°/s、点生命无限（`dot_life = -1`）；程序内为像素值（点半径 3 px、孔径 300 px、`canvas_height` 420） | 论文 + raw | ✅（`detail` 记像素与视角的对应，§3.6） |
| `Label` | 图片 "我" / "他"（女被试 "她"），230 × 220 px，位于散点下方；仅匹配任务呈现 | 论文 | ✅ |
| `Colors.Stimulus` | 红 `hsl(0, 50%, 50%)` 与蓝 `hsl(225, 50%, 50%)` | raw `dot_color` | 🟡 论文括号内把两者 HSL 写反（**Issue 8**），detail 注明以 raw 为准 |
| `Colors.Background` | `black` | 论文 + raw | ✅ |

### 6.5 结论

- 五字段组共 **24 个字段：19 个 ✅、5 个 🟡、0 个 ❌**（🟡 = `Presenting`、`Trial_number`、`ISI`、`ITI`、
  `Colors.Stimulus`，均可填，只需 `detail` 说明来源或口径；其中属**冲突**的 `Trial_number` = Issue 3、
  `Colors.Stimulus` = Issue 8，来源类说明 `Presenting`/`ISI`/`ITI` 不进 Issues 清单）。
- 组外字段 `Collected_date` = `2025`（Exp1）/ `2026`（Exp2），由用户提供（年级粒度）。
- 组外字段 `schema_version` = `"2"`、`detail` = §10 Issues 清单 + §3.4/§3.6 说明。
- 不属于 schema、建议一并写入主索引 `Note` 的信息：招募 75/75/65 人、未通过练习 5/4/5 人、被试报酬形式
  （论文未报告，可选补充）。

## 7. 执行步骤（映射 SKILL 10 步）

1. 建 `Exp1/`、`Exp2/` 子文件夹（输入区已在位）。
2. 写 `Wu_2026_Chinaxiv_clean.R`：逐被试读 raw → 解析 `Phase`（instruction 标记 + 尾部计数；Exp2 两个辨别块
   各自起点；7 个早期版本文件按 §3.4 重建）→ 列重命名 + Shape/Identity 映射 → `stopifnot()` 列序/行数/被试数
   检查 → 写 `*_raw.csv`、`*_Clean.csv`（`na = "NA"`）、`*_subj_info.csv`。
3. `Rscript 2_Code/validate_clean_csv.R` 首次校验（E1–E3 必须 0 ERROR）。
4. 写 paper JSON（preprint 固定 `Journal: "Preprint"`、`DOI` 裸格式）+ 两个 exp JSON v2（§6 的值 + §4.5 detail）。
5. 生成两份 Codebook（单 `Sheet1` 4 列，行数 == Clean 列数）。
6. 草稿经用户确认后写入目标路径。
7. 更新 `Dataset_inf.csv`（3 行；`City` 均 `Nanjing`、`Country` = `China`、`License` = `CC BY 4.0`、
   `Environmental_Info` = jsPsych v7；字节保真、按 ID 重排）。
8. 两级校验：`validate_json_metadata.R` EXIT=0 + `validate_clean_csv.R` 0 ERROR（先按决策 15 让 W5 支持
   `known` 登记并登记 Wu 两条）。
9. 多源交叉核验（论文 ↔ 作者代码 ↔ 库内数据 ↔ raw；描述性统计，不复现统计检验），按 §4.5 记录。
10. 收尾：`PROJ_STATE.md`（§3 类别行 + §5 现状数字）、SKILL `Task` 受控值补 `choice-task`、`known` 登记、
    `Generate_Table1_v2.R` 重跑。

## 8. 校验与完成确认清单

- [ ] Exp1/Exp2 五类标准文件齐全、命名合规
- [ ] Clean 列序对齐模板 v2（脚本 `stopifnot()`）
- [ ] 两文件均 < 50 MB（否则按被试边界分片）
- [ ] `validate_json_metadata.R` EXIT=0；受控词表（`Setting`/`Modality`/`Stimulus_order`）WARN 0
- [ ] `validate_clean_csv.R` 0 ERROR；W5 两条 NA 已登记 `known`（脚本 W5 分支已按决策 15 支持 `known`）
- [ ] `Dataset_inf.csv` 3 行（70 / 71 / 60；字节保真、ID 行序）
- [ ] §10 Issues 清单（Issue 1–8）写入 exp JSON `detail` + 主索引 `Note`（涉作者分析口径者另入 Codebook）
- [ ] Codebook 两份：行数 == Clean 列数 + 1、列名与顺序一一对应、`Variable_description` 无遗留 `"NA"`、
      分类列取值与数据 `unique()` 一致（含字面量 `NA`）、与 exp JSON `detail` 语义一致（§5.1 校验条）
- [ ] `PROJ_STATE.md` §3/§5 同步；Table 1 重跑成功

## 9. 待确认事项

**无 —— 全部事项已定案**（原 5 条 = 决策 12–16；色盲筛查等问卷题不入 Clean、`Phase` 去掉 `screen` =
决策 4 修订，2026-10-06 用户确认）。计划可执行；执行顺序建议 Exp1 先行（作者产物与 raw 完全可复现、风险最低），
随后 Exp2。

已定案的 5 条（备查）：
1. **Exp2 数据版本** → 按 raw 重建，冲突登记 Issue（决策 12）。
2. **稿件口径不一致**（Exp2 试次数 192 vs 256；RT 窗口 4000 vs 3000 ms）→ 登记 Issue + `detail`，本轮不改稿件（决策 13）。
3. **Exp2 5 人 canvas 宽 1440–1536 px** → 仅作 `detail` 记录（决策 14）。
4. **`validate_clean_csv.R` 的 W5 豁免** → 修改脚本使 W5 支持 `known` 登记，并登记 Wu 两条（决策 15）。
5. **报酬形式 / 伦理批号** → 不填（决策 16）。

## 10. Issues 清单（全部冲突/不一致问题的统一登记）

> **本节是本研究冲突与不一致问题的唯一汇总入口**；采用**本研究独立编号 Issue 1–8**，入库时按编号写入
> exp JSON `detail` 与主索引 `Note`。
> **统一处置 = 登记暂缓**（SKILL/决策 13）：不影响库内标准文件正确性、不阻塞 Status=1；稿件层面的更正待预印本修订时处理。
> 范围说明：§6 中标 🟡 但属"来源说明"而非冲突的项（`Presenting` 未报告机型、`ISI` 属程序推断、`ITI` 来源为程序代码）
> 不进本清单；本清单只收**互相矛盾**的事实。

| Issue | 一句话摘要 | 类型 | 证据（本计划） | 影响字段/文件 |
|---|---|---|---|---|
| **1** | Exp1 作者 `data_color.csv` 把运动组 Subject 70 重复计入颜色组（颜色组被计成 72 人） | 作者产物 | §4.1 | 库内不受影响（不入库作者产物） |
| **2** | Exp2 作者共享 CleanData 与 raw 导出不可对应（三版本；仅 51.1%/48.8% 行可追溯；30/60 人 < 50%；编号奇偶交替；分析代码输入路径不存在；`tail(256)` 规则与数据不符） | 作者产物 / 版本 | §4.2、§4.3 | Exp2 标准文件一律以 raw 重建 |
| **3** | Exp2 匹配任务试次数：稿件 256（32/条件）vs raw 192（24/条件，4 块 × 48）；Exp1"每个条件下48个试次"应为每组块 48 | 稿件 vs 数据 | §3.3、§4.4 | exp2 JSON `Trial_number`（按 raw 填 + detail） |
| **4** | Exp2 RT 剔除窗口：稿件文字与 `exp2/Data_clean.Rmd` 注释 3000 ms vs 预注册与数据 4000 ms（Exp1 四来源一致 3000 ms） | 稿件 vs 预注册 | §4.4 | Codebook + exp JSON detail（作者分析口径） |
| **5** | Exp2 7 个早期版本导出（被试 25–28、58–60）缺 `task_type` 列、非关联块 `association` 为空 | 程序版本 | §3.4 | Clean 的重建列 + Codebook/JSON detail |
| **6** | 显示器分辨率与刺激视角不自洽：稿件 1080 × 768；raw canvas 宽 1920 px；8°/0.15° 仅与屏宽 1920 px 自洽（1080 px 时为 13.2°/0.263°） | 稿件 vs 程序 | §3.6 | exp JSON `Monitor`/`Shape` 的 detail（字段值按稿件） |
| **7** | Exp2 5 名被试（共 60）canvas 宽 1440–1536 px，其余 55 人为 1920 px（固定实验室设备口径下的未解释项） | 设备 | §3.6 | exp2 JSON detail |
| **8** | 稿件红/蓝与 HSL 标注写反（HSL 225 为蓝、HSL 0 为红；raw `dot_color` 为准） | 稿件 vs 数据 | §6.4 | exp JSON `Colors.Stimulus` 的 detail（值按 raw） |

### 逐条要点

**Issue 1 — Exp1 颜色组多计 1 人**
- 证据：`data_color.csv` 含 ID 70 的 563 行，与 `data_motion.csv` 中 ID 70 在共有列上**逐行相同**；作者代码
  `exp1/Data_clean.Rmd` 第 322 行 `subj_idx %in% seq(70, 141)`（注释"后70为颜色"）与其自身分组定义（71–141）差一位。
- 影响：作者报告的颜色组统计含 72 人；本库不入库作者产物 → 库内数据与主索引（71 人）不受影响。
- 登记：`Wu_2026_Chinaxiv_Exp1.json` `detail` + 主索引 Exp1 两行 `Note`（一句说明）。

**Issue 2 — Exp2 作者产物与 raw 不可对应（数据版本问题）**
- 证据：`data_match.csv` 95–256 行/人（8 格平衡者仅 2/60）；逐行可追溯 51.1%（`data_rdk` 48.8%）；30/60 人 < 50%、
  12 人 ≤ 2 行（在全部 60 个 raw 文件中最高重合 2–4%）；不可追溯者编号**奇偶交替**（2/4…30、37/39…65）；
  `BHM_Analysis.Rmd` 声明输入 `../../3_Data/3_2_exp2/CleanData/data_all.csv`（仓库中不存在该路径）；
  `Data_clean.Rmd` 的 `tail(256)`/`tail(128)` 与 raw 正式段（192/每块 32）不符。
- 影响：Exp2 标准文件的**数据源决定**；本库按 raw 重建，作者产物仅作交叉核验参照。
- 登记：`Wu_2026_Chinaxiv_Exp2.json` `detail` + 主索引 Exp2 行 `Note`。

**Issue 3 — Exp2 匹配任务试次数 192 vs 256**
- 证据：raw 60/60 人为 4 块 × 48 = 192（8 条件 × 24，条件格完全平衡）；稿件 §3.1.3 写"每个条件下32个试次，共256个"；
  预注册的"32 trials per condition"只针对辨别任务（raw 每相关块 4 块 × 32 = 128 ✓，逐人延长至 144）。
  附：Exp1 稿件"每个条件下48个试次，共384"亦为措辞错误（384 = 8 块 × 48，16 条件 × 24）。
- 影响：`Trial_number` 按 raw 填；`detail` 说明稿件口径差异。
- 登记：`Wu_2026_Chinaxiv_Exp2.json` `detail` + 主索引 Exp2 行 `Note`。

**Issue 4 — Exp2 RT 剔除窗口 3000 vs 4000 ms**
- 证据：Exp2 预注册 #281,213 写 "shorter than 100 ms or longer than 4000 ms"；`data_all.csv` 的 rt 最大值恰为
  **4.000 s**、最小值 0.174 s（与 [100, 4000] 一致）；稿件方法段与 `exp2/Data_clean.Rmd` 注释写 3000 ms；
  Exp1 预注册、稿件、代码、数据四者一致为 3000 ms。
- 影响：库内 Clean 保留全部试次（不过滤），作者分析口径写入 Codebook 与 `detail`。
- 登记：两份 Codebook + `Wu_2026_Chinaxiv_Exp2.json` `detail`。

**Issue 5 — Exp2 7 个早期版本导出字段缺口**
- 证据：被试 25、26、27、28、58、59、60 的 raw 表头**无 `task_type`**，其非关联维度块（如关联运动者的
  `RDK_color`）`association` 全为空；其余 53 人两列齐全。
- 影响：这 7 人 × 1 块的任务相关性与身份需按"块维度 vs 关联维度""匹配段绑定"重建（先例：SKILL
  §数据标准化「刺激-身份绑定恢复」）；重建规则必须三处标注（Codebook / exp JSON detail / 主索引 Note）。
- 登记：`Codebook_Wu_2026_Chinaxiv_Exp2_Clean.xlsx` + `Wu_2026_Chinaxiv_Exp2.json` `detail`。

**Issue 6 — 显示器分辨率与刺激视角不自洽**
- 证据：稿件写"23.8 英寸、分辨率 1080 × 768、60 Hz"；raw 全屏下 canvas 宽 = 窗口宽 = **1920 px**（Exp1 141/141）；
  按 23.8 英寸 16:9、视距 60 cm（屏宽视角 47.4°）核算：屏宽 1080 px → 孔径 300 px = **13.2°**、点直径 6 px = **0.263°**；
  屏宽 1920 px → **7.4°** / **0.148°**，与稿件 8° / 0.15° 吻合。
- 影响：字段值按稿件填（决策 10）；核算过程与 raw 观察写入 `detail`（下游换算视角时可自查）。
- 登记：`Wu_2026_Chinaxiv_Exp1/Exp2.json` 的 `Physical_Environment.Equipment.Monitor` 与
  `Stimulus_Properties.Shape` 的 `detail`。

**Issue 7 — Exp2 5 名被试 canvas 宽 1440–1536 px**
- 证据：Exp2 正式匹配任务 canvas 宽 1920（55 人）、1536（3 人）、1440（2 人）；Exp1 为 141/141 的 1920；
  全屏进入成功率两组均 100%（`fullScreen` 试次 `success = true`）。
- 影响：不影响库内数据；`detail` 记录（决策 14），如后续发现属"第二台设备/未全屏/缩放设置"可补注。
- 登记：`Wu_2026_Chinaxiv_Exp2.json` `detail`。

**Issue 8 — 稿件红/蓝与 HSL 标注写反**
- 证据：稿件写"一半的点为红色（HSL 225, 50%, 50%），一半为蓝色（HSL 0, 50%, 50%）"；HSL 225° 属蓝、0° 为红；
  raw `dot_color = ["hsl(225, 50%, 50%)", "hsl(0, 50%, 50%)"]`（`dot_color_final` 顺序与 self/other 绑定，
  逐被试平衡）。
- 影响：`Colors.Stimulus` 按 raw 填，`detail` 注明稿件括号标注相反。
- 登记：`Wu_2026_Chinaxiv_Exp1/Exp2.json` 的 `Stimulus_Properties.Colors.Stimulus` 的 `detail`。
