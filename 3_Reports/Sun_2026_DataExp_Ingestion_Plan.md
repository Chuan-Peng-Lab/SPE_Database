# Sun_2026_DataExp 入库计划（v4 — 决策已全部并入，待用户批准执行）

> 依据：SKILL.md（入库 10 步 / 模板 v2 / 主索引规则）、`AGENTS.md`、`Sun_2026_DataExp_Raw/04_code_and_reproducibility/removed_subjects_log.md`（用户指定权威）、输入区文件与现有五件套实测。
> **v2 更新（用户指示）**：① **SMT_1（Day 2 几何版）入库，为 Task1、Session=2；SMT_2（Day 3 自我参照版）为 Task2、Session=3**；两任务整合为**同名 CSV**（`Sun_2026_DataExp_Exp1_*`），可按被试边界分片。② **`empty_ID_ghost` 分配临时 ID 后入库**。
> 状态：**§4–§7 与 §8 均已执行完毕（2026-10-01）**，库内为 §8 的**交集口径**（589 被试 / 1,040,880 行 / 20 列，两级校验 0 ERROR）；仅 §7.2 第 9 项（`Design` 列文案）仍待用户撰写。本计划不写入任何数据文件。
>
> **执行结果（2026-10-01）**：`Sun_2026_DataExp_clean.R` 重建五件套 → Clean 1,128,096 行 / 682 被试（Task1 603,216 + Task2 524,880），raw 同规模；两者各按被试边界分 4 片（Clean ~43 MB/片、raw ~47.8 MB/片，逐字节可还原）；`Dataset_inf.csv` 18 个字段更新（Status=1、682/503/179、Male/Female 295/295、City=NA、jsPsych 7.3.1、Journal/Data Express、License CC BY 4.0、Repo_Link=SciDB）；`validate_json_metadata.R` EXIT=0、`validate_clean_csv.R` 0 ERROR（Sun 的 E3 KNOWN 豁免已移除）；PROJ_STATE（Sun 迁类别一，§5 数字同步）与 For_COLLABORATORS（待办 4→3 项）已更新；log §7.4 记录执行结果。

---

## 1. 入口判定

| 五件套 | 现状 |
|---|---|
| paper JSON / exp JSON | 有（exp JSON 多个字段为 `/`，且只描述单任务） |
| Clean | 有 `_Clean_part1/2.csv`（506 被试 / 448,800 行，仅 SMT_2） |
| Codebook | 有（18 行） |
| subj_info | 有（334 行，`Subject_ID` = 数字 ParticipantID，**无法与 Clean 的 `phase_XXX_subj_YY` 连接** → 校验器 KNOWN 豁免 E3） |
| `*_Exp1_raw.csv` | **缺**；无 `Sun_2026_DataExp_clean.R`，Clean 不可重跑 |

→ **入口 = 第 3 步（重写清洗脚本，按「两任务整合」全量重建 raw + Clean + subj_info + Codebook），再走第 5、7–10 步。**

现库实测问题（重建时一并修正）：
1. **列序违反模板 v2**：现 `Subject, Phase, Shape, Label, Task, Matching, Label-Identity×3, Shape-Identity×3, extraIV1, extraIV2, …`；规范要求 `Subject → [Session] → Task → Phase → Matching → Shape → Shape-Identity×3 → Label → Label-Identity×3 → extraIV1 → extraIV2 → [CorrResponse] → Response → RT_ms → RT_sec → ACC`。
2. **被试口径两头不靠**：现 506 人 = 作者清洗版 503 人 + 3 人（`phase_010_subj_15`、`phase_010_subj_23`、`phase_017_subj_13`；后者在 log §4 属"重复记录被删"一侧）。
3. **只含 SMT_2**，Day 2 的 SMT_1（604,176 行 / 681 人）完全未入库。

---

## 2. 输入区事实（含本次实测）

| 来源 | 内容 | 规模 |
|---|---|---|
| `01_raw/SMT_1_raw.csv` | **Task1 = SMT_1（Day 2 几何版，ALT1）** 作者发布的 task 级 raw；`task_id ∈ {ALT1, ALT1_1, ALT1_2}`，`screen_id ∈ {prac_ALT1_1, formal_ALT1_1, prac_ALT1_2, formal_ALT1_2}`；condition/word 均为形状名 | 604,176 行 / **681 个 ID**；正式 768 试次·人（679 人）、**2 人 1536**；练习 96–432；**无空 ID 行** |
| `01_raw/questionnaires_day2_raw.zip` → `day1_data.csv`（已解压 862 MB） | Day 2 平台**完整** jsPsych 导出（IAT + SMT_1 + 问卷）；文件编码 = **GB18030 且含非法字节**（须 `errors="replace"` 读，否则 UnicodeDecodeError）；含 trial 级 `time_elapsed`/`time_stamp` | ALT1 行 572,928 / **644 个 ID**；正式 768·人（641）、**3 人 1536**；无空 ID |
| `04_code_and_reproducibility/procedure/day2/SMT_1.js` + `initJspsy.js` | Task1 权威参数：`alt1_sample=24`、`alt1_n=2`、`blockTotalNum_same=7`（+1 = 8 block/子版本）；`acc=60` | — |
| `01_raw/questionnaires_day3_raw.zip` → `day2_data.csv` | Day 3 **真 raw** jsPsych 导出（SRET + SMT_2），774 MB，133 列 | Task2 数据源 |
| `02_cleaned/02_cleaned_data/SMT/ALT2_all.csv` | **Task2 = SMT_2（Day 3 自我参照版，ALT2）** 作者清洗版（= 论文 Table 6 N） | 503 人 / 446,160 行 |
| `04_code_and_reproducibility/procedure/day3/SMT_2.js` + `initJspsy2.js` | Task2 权威参数：`alt2_sample=24`、`alt2_n=2`、`blockTotalNum_same=7`（+1 = 8 block/子任务）；`acc=60` | — |
| `removed_subjects_590_to_503.csv` / `removed_subjects_others.csv` / `590_to_503_subject_qc.py` | Task2 的 87 人剔除明细与复现脚本 | 12 ALT2 精度 + 68 SRET_QC + 1 missing_SRET + **1 空 ID 幽灵** + 5 unexplained |
| `REF/Sun_2026_DataExp.md` | 论文全文（已有） | — |

**来源分歧（Task1，已核查）**：作者文件与平台导出**互不包含**（681 vs 644 人；604,176 vs 572,928 行；"1536 试次"名单不同）。个案证据：`phase_003_subj_14` 在作者文件里有**两遍**（首遍 `formal_ALT1_1` 正确率 0.594 < Day-2 QC 阈值 0.60，第二遍 0.893），平台导出只有**第二遍**（2.07→35.35 min 一段完整记录）→ 作者的 task 级文件保留了那次 QC 未过的首跑。

**被试集合关系（本次实测）**：Task2 的 589 个有效 ID（503 + 86）**全部包含于** Task1 的 681 个 ID 之内；**并集 = 681**。加上幽灵 = **682 条记录**。

**两任务结构（数据与代码一致）**

| | Task1 = SMT_1（Session 2） | Task2 = SMT_2（Session 3） |
|---|---|---|
| 联结 | 形状↔形状（无身份，几何图形版基线） | 形状↔身份标签（我 / 朋友） |
| 刺激 | 8 形状；condition=word=形状名 | 8 形状 × 12 中文标签（好/坏·强/弱 × 我/他/她） |
| 正式 | 768 试次/人 = 2 子版本 × 8 block × 48 | 768 试次/人 = 2 子任务（ability/moral）× 8 block × 48 |
| 练习 | 48/block，自适应重复至正确率 ≥60%（实测 96–432） | 同左（实测 96–480） |
| 试次时序 | 十字 500 ms → 刺激 1000–1200 ms → 作答自 1000 ms，试次 2200 ms → 反馈 500 ms | 同左 |

**SMT_1 无身份维度** → Identity 三层按 `NonPerson` 记（先例：Zhang_2024_PsychJ Exp2 中性形状、Amodeo 家具类）；`extraIV1`/`extraIV2` 填 `NA`（Task1 无 domain/valence 操纵）。

**幽灵记录**：Task2 中 `ID` 空白、864 行、`ParticipantID = 201`、`phase = 15`，与库内保留的 `phase_015_subj_15` 同 PID 同 phase（重复提交）。按用户指示**分配临时 ID 入库**，建议 `phase_015_subj_ghost01`（保留 phase/PID 可溯源，命名即标识"临时"）；该记录**只有 Session 3（Task2）数据**，Session 2 行缺失，须在 JSON `detail` 与 CSV `Note` 标注。Task1（SMT_1）导出中无空 ID 行，不涉此问题。

---

## 3. 数据口径决策（本库"最小预处理、不过滤"）

> ⚠️ **口径提示**：§3–§7 记录的是 2026-10-01 第一次执行时的**并集口径**（682 被试 / 1,128,096 行 / 21 列）。用户随后改为**交集口径**并以 §8 为最终口径（**589 被试 / 1,040,880 行 / 20 列**，无 `Run`；`Sample_Size 589`、`Valid_Subj 503`、`Drop_Subj 86`、Male 294 / Female 295）。凡与 §8 冲突之处，**以 §8 为准**。

按 log §6：不施加论文的 SMT/SRET 剔除，作者剔除者全部保留；唯一例外是空 ID 幽灵——**按用户指示补临时 ID 后保留**。

| 指标 | 建议值 | 依据 |
|---|---|---|
| Clean 被试总数 | **682**（681 + 幽灵 1；若后续决定把平台 `NA` 记录也赋临时 ID 入库则为 683） | 并集实测 |
| `Sample_Size` | **682** | = Clean 被试数（数据口径） |
| `Valid_Subj` | **503**（论文最终分析样本） | 论文 Table 6 / log §1 |
| `Drop_Subj` | **179**（682 − 503） | SKILL：Sample − Valid |
| `Note` | `Paper_N: 603 attempted / 588 valid / 503 final (Table 6); SMT_1 (Day 2) N=681, SMT_2 (Day 3) N=590 records; 12 subjects below SMT_2 quality criteria and 69 SRET-based exclusions retained per minimal-preprocessing; 1 blank-ID ghost record assigned temp ID phase_015_subj_ghost01` | 本计划 §2–3 |
| 每人试次 | Task1 768 + Task2 768 = 1536（两 session 均完成者） | 数据实测 |

- **12 名 Task2 精度未达标者**、**69 名 SRET 原因剔除者**：保留，JSON `detail` 说明，使用者自行剔除。
- **Task1 双跑个案（已核查 + 已定案，明细见 §6.2 与 log §7）**：`phase_003_subj_14` 作者文件含"未过 QC 首遍 + 重跑"，平台只有重跑 → **只保留与平台一致的重跑那遍**；`phase_017_subj_20` 两边均两遍（两条独立 session 记录，`time_elapsed` 重置）→ **两遍均保留**，Clean 加 `Run`（1/2）列 + JSON detail 说明。其余不一致（平台独有 `NA` 记录、平台 2 遍/作者 1 遍的 `phase_003_subj_2`、作者独有 38 人）已逐条记入 `removed_subjects_log.md` §7。

---

## 4. 五件套重建（执行步骤）

### 步骤 1：新建 `1_Data/Sun_2026_DataExp/Sun_2026_DataExp_clean.R`（替代历史交互清洗；库内约定清洗脚本随研究文件夹）
- **Task1 主源 = `01_raw/SMT_1_raw.csv`**（作者发布件、覆盖更广：681 人）→ 进 Clean；平台导出 `day1_data.csv` **仅作佐证**（trial 级 `time_elapsed`/`time_stamp` 用于鉴定双跑；编码 GB18030 + 非法字节，须容错读）。两源行数/被试数不一致属**已知事实**（681 vs 644），不视为错误，写入 JSON detail。
- **Task1 双跑处置（按用户 2026-10 决策，逐案清单见 log §7.2）**：① `phase_003_subj_14` 只保留与平台一致的重跑那遍（丢弃未过 60% 门槛的首遍）；② `phase_017_subj_20` 两遍全保留并标 `Run=1/2`；③ `phase_003_subj_2` 只采用作者文件那 1 遍；④ 平台独有 `NA` 记录**不入库**（作者文件无此记录）。全部差异已记 log §7。
- **Task2**：流式读 `questionnaires_day3_raw.zip → day2_data.csv`（774 MB），取 `task_id ∈ {prac_ALT2_moral, ALT2, prac_ALT2_ability}`；空 ID 行赋临时 ID `phase_015_subj_ghost01`。
- 输出 **`Sun_2026_DataExp_Exp1_raw.csv`**（两任务拼接，作者原列 + 原值，新增 `Session` 列 = 2/3；顺序 `Session → Task → 其余`），补上目前唯一缺件。
- 守卫：被试数、每任务正式试次 768、行数与两个来源计数一致。

### 步骤 2：生成 `Sun_2026_DataExp_Exp1_Clean.csv`（模板 v2 列序；两任务同一文件）
| Clean 列 | Task1（Session 2，SMT_1）来源 | Task2（Session 3，SMT_2）来源 |
|---|---|---|
| `Subject` | `ID`（`phase_XXX_subj_YY`；幽灵 = `phase_015_subj_ghost01`） | 同左（空 ID 行 → `phase_015_subj_ghost01`） |
| `Session` | `2` | `3` |
| `Task` | `shape-matching`（Task1；**已定**，执行时同步在 SKILL 任务词表加该受控值） | `self-matching`（Task2） |
| `Phase` | `screen_id`（`formal_ALT1_1` / `prac_ALT1_1` / `formal_ALT1_2` / `prac_ALT1_2`） | `task_id`（`ALT2` / `prac_ALT2_ability` / `prac_ALT2_moral`） |
| `Matching` | `conditionType`（match/nonmatch → `Matching`/`Nonmatching`） | `identity`（同映射） |
| `Shape` | `condition`（英文形状键：circle/triangle/…） | `Image` |
| `Shape_Origin/English/Standardized_Identity` | `NonPerson` ×3（无身份） | `person`：`self→self→Self`；`friend→friend→Close` |
| `Label` | **中文呈现词**（从 `SMT_1.js` `words1` 恢复：circle→圆形、diamond→菱形、square→方形、triangle→三角、ellipse→椭圆、hexagon→六边、pentagon→五边、trapezoid→梯形）；raw 保留英文键 | `word`（中文标签，呈现词） |
| `Label_Origin/English/Standardized_Identity` | `NonPerson` ×3 | `word` 首字：`我→Self`；`他/她→Friend→Close` |
| `extraIV1` / `extraIV2` | `NA`（无该操纵） | `domain`（moral/ability）/ `valence`（positive/negative） |
| `CorrResponse` | `missing`（作者 `SMT_1_raw.csv` 未含正确反应键列） | 真 raw `correct_response` |
| `Response` | `response`（`f`/`j`；无反应 `NA`） | `response`（无则 `key_press`；无反应 `NA`） |
| `RT_ms` / `RT_sec` | `rt`（无反应 `NA`） | `rt`（无反应 `NA`） |
| `ACC` | `correct`：`true→1`、`false→0`、`NA/空→NA` | `True→1`、`False→0`、`null→NA` |
| ~~`Run`（研究特有尾部列）~~ | **已被 §8 取代：交集口径下删除该列**（唯一双跑者 `phase_017_subj_20` 无 Session 3 数据、整体排除） | — |

- **不过滤**：练习试次由 `Phase` 标记并保留；无效精度、被作者剔除者、幽灵全部保留。
- **分片**：整合后 Clean 预计 ~190 MB（Task1 ~604k 行 + Task2 ~523k 行）→ 按 SKILL「大文件拆分」以**被试边界**切分（**同一被试的 Session 2 + Session 3 全部行必须落在同一片**），预计 **4 片** `_Clean_part1..4.csv`，各片表头一致、`rbind` 可还原；Codebook/JSON/subj_info 各 1 份、不新增 Dataset_inf 行。
- **raw 文件**：预计 ~130–190 MB（GitHub 单文件硬上限 100 MB）→ 按被试边界分片 `_Exp1_raw_part1..4.csv`。**raw 分片规则已加入 SKILL**（§文件与文件夹规范「大文件拆分（单一 `*_Clean.csv` 或 `*_raw.csv` > 50 MB）」），`2_Code/split_clean_csv.py` 已扩展为同时接受 `*_raw.csv`；raw 不参与校验（两个校验器只匹配 `_Clean` 系列），各片共用同一 exp JSON、不新增 Dataset_inf 行。

### 步骤 3：重建 `Sun_2026_DataExp_Exp1_subj_info.csv`
- `Subject_ID` = `phase_XXX_subj_YY`（~~`phase_015_subj_ghost01`~~ **已被 §8 取代：幽灵无 Session 2 数据、按交集排除**）；行数与 Clean 一致（交集口径 **589 行**），消除 334 vs 506 的 KNOWN 豁免。
- `Gender` ← raw `Sex`（可得部分：平台导出覆盖者；38 名"作者独有"被试无 `Sex` → `/`）；其余人口学列 raw 无 → `/`；建议加一列标注幽灵（或在 JSON detail 写明）。

### 步骤 4：重生成 `Codebook_Sun_2026_DataExp_Exp1_Clean.xlsx`
- 4 列单 `Sheet1`，行数 == 新 Clean 列数、行序 == 新列序（`2_Code/make_codebooks.R`）。
- 枚举修正：`Session`（2;3）、`Task`（shape-matching;self-matching）、`Run`（1;2，仅 Task1 双跑被试有 2）、`Response` 补 `NA (no response)`、`ACC` 补 `NA (no response)`、`Matching` 仅二值、Identity 逐层列全、`CorrResponse` 注明 Task1/Task2 来源差异。

### 步骤 5：exp JSON v2 补全（单 `Exp1` 文件，两任务统一记入，来源分级）
| 字段 | 值 | 来源 |
|---|---|---|
| `Physical_Environment.Setting` | `Online`（受控词；Naodao 平台） | 全文 |
| `Equipment.Software` | `jsPsych 7.3.1`（psychophysics 插件） | 全文 + 程序 |
| `Location` / `Presenting` / `Monitor` / `Viewing_distance` | `/`（在线、被试自有设备） | — |
| `Experimental_Design.Conditions` | Task1（Session 2）：8 shapes × match/nonmatch；Task2（Session 3）：self/friend × moral/ability × positive/negative × matching/nonmatching | 数据 + 代码 |
| `Block_Structure.Block_number` | `16 per task (Task1: 2 sub-versions × 8 blocks; Task2: 2 sub-tasks × 8 blocks)` | `initJspsy*.js` |
| `Block_Structure.Trial_number` | `768 formal trials per task per subject (1536 for subjects completing both sessions)` | 数据实测 |
| `Block_Structure.Practice_trials` | `48 per practice block, adaptive repetition until accuracy >= 60% (observed 96-480)` | `SMT_1.js` / `SMT_2.js`（`acc=60`） |
| `Trial_Structure`（两任务相同） | Fixation `500 ms`；Stimulus `200 ms (1000-1200 ms)`；SOA `500 ms`；Response_deadline `2200 ms`（作答自 1000 ms）；Feedback `500 ms`；ITI 依注释核（约 100 ms） | `SMT_1.js` L312-388、`SMT_2.js` L1113-1195 |
| `Stimulus_Properties` | Modality `Visual`；Shape 190 px ≈3.8°×3.8°；Label 80 px 微软雅黑 ≈3.6°×1.6°；Colors 待核 CSS | 程序 |
| `detail` | 682/681/590/503 口径、87 人剔除明细、12 人保留、幽灵临时 ID、Task1 无身份→NonPerson、Task1 双跑个案与 `Run` 列、两源分歧（681 vs 644）、分片说明 | 本计划 |

### 步骤 6：Dataset_inf.csv 收口（字节保真：往返测试 → 写 → diff 仅目标单元格 → ID 行序保持）

> ⚠️ 下表为**并集口径**的目标值；**最终已按 §8 交集口径收口**：`Sample_Size=589`、`Male=294`、`Drop_Subj=86`（`Valid_Subj=503`、`Female=295` 不变），`Note` 改写为交集说明。其余字段（City/jsPsych/Journal/License/Repo_Link/numTrials 等）与下表一致。
| 列 | 现值 | 目标 |
|---|---|---|
| `Status` | 空 | `1`（重建后自洽） |
| `Sample_Size` / `Valid_Subj` / `Drop_Subj` | 空 | **682 / 503 / 179** |
| `Male` / `Female` | 空 | 填**可得部分**的计数（来自平台 raw `Sex`；作者 `SMT_1_raw.csv` 无 `Sex` 列 → 38 名"作者独有"被试不可得），并在 `Note` 注明覆盖范围 |
| `City` | `Nanjing` | **`NA`**（任务在脑岛平台线上完成；先例 Kirk/Perrykkad） |
| `numTrials` | 空 | `768 per task (Task1 SMT_1 + Task2 SMT_2; 1536 for subjects with both sessions)` |
| `numBlocks` | 空 | `16 per task (2 x 8 blocks x 48 trials)` |
| `Practice_Trial` / `Practice_Block` | 空 | `48 per block, adaptive to >=60% accuracy (96-480)` / `2-10` |
| `Environmental_Info` | 空 | `jsPsych 7.3.1` |
| `Design` | 含 stranger…（**与数据不符**） | **由用户亲自撰写**——执行时保留原值不动，收口时提醒用户提供文本 |
| `Self` / `Close` / `Others` | `Self` / `Friend` / 空 | `Self`（我）/ `Friend`（他/她，Close）/ **保持空白**（见 §6.1） |
| `Extra_Ind_Var` | 空 | `Session; Task; Domain; Valence (Task2 only)` |
| `Stim_Type` / `Stim_language` | geometric shape / Chinese | 保持 |
| `Repo_Link` | sciengine CSD 链接（疑非本数据集） | **`https://www.scidb.cn/s/NZjyA3`**（论文所述 SciDB；已定） |
| `License` | `No License`（**非三态**） | **`CC BY 4.0`**（项目自有数据；已定） |
| `PubType` / `Journal` / `DOI` | preprint / NA / 空 | **`Journal` / `Data Express` / 留空**（论文在 revision，DOI 待发表后补——已定，见 PROJ_STATE §4 决策 22，不再作为问题提出） |
| `ID` / 行序 | `Sun_2026_DataExp_Exp1_All` | 不变（单实验单行） |

### 步骤 7：校验与收尾
1. `Rscript 2_Code/validate_json_metadata.R` → EXIT=0。
2. `Rscript 2_Code/validate_clean_csv.R` → 0 ERROR；**删除 `known` 中的 Sun 条目**（E3 已修）。
3. 自检：Clean 表头逐列对齐模板 v2；Codebook 行数 == 列数；分片 `rbind` 可还原、各片被试不跨片；`(Subject, Session, Phase)` 键唯一（Task1/Task2 的 Phase 名不同，Session 区分）。
4. PROJ_STATE.md §3/§5 更新（Sun_2026_DataExp 由类别二迁类别一，数字改 682/113 行不变）；`For_COLLABORATORS.md` 相应更新。
5. exFAT 卫生（`._*`）后再提交（**提交需用户明确确认**）。

---

## 5. 验收标准

> 下列勾选项为**并集口径**执行结果；交集口径（§8）的验收结果为：**589 被试 / 1,040,880 行 / 20 列**、每人两会话齐备（1,178 对）、幽灵与 92 名仅-S2 被试均不在库内、两级校验 0 ERROR。

- [x] 五件套齐：`_Exp1_raw_part1..4` + `_Exp1_Clean_part1..4` + `subj_info`（682 行）+ Codebook + 双 JSON。
- [x] Clean 含两任务：`Session ∈ {2,3}`、`Task ∈ {shape-matching, self-matching}`；Task1 正式 768（680 人；`phase_017_subj_20` 为 1536，`Run=1/2`）/ Task2 正式 768（590 条记录）；练习均由 `Phase` 标记。
- [x] 幽灵以 `phase_015_subj_ghost01` 入库并在 JSON/Note 标注；同一被试两 session 同片（按 Subject 排序后分片）。
- [x] Task1 双跑按决策落地：`phase_003_subj_14` 仅 768 正式（重跑遍）；`phase_017_subj_20` 1536 且 `Run=1/2`；JSON `detail` 说明；差异清单已入 log §7。
- [x] 两级校验 0 ERROR 且无 Sun KNOWN 豁免（`known` 条目已删除）。
- [x] Dataset_inf / exp JSON 一致（N 口径、软件、设置、Identity；`PubType=Journal`、`Journal=Data Express`、`License=CC BY 4.0`、`Repo_Link=SciDB`、`City=NA`）。⚠️ paper JSON 的 `City` 仍为 `Nanjing`（本次未改动，属待用户裁决的一致性项，见执行汇报）。
- [x] `Design` 列保留原值未动，并已提请用户撰写（§7.2 第 9 项）。

---

## 6. 风险与注意

- 862 MB / 774 MB raw：**只流式读**；落盘先 `/tmp` 再 `mv`，写前 `ls -la`，不覆盖既有文件。
- **编码不同**：Day 2 平台导出 = GB18030 且含非法字节（`encoding="gb18030", errors="replace"`）；Day 3 平台导出 = UTF-8（无 BOM）。`clean.R` 必须分别显式指定，否则报 `UnicodeDecodeError`。
- 现 `_Clean_part1/2.csv`、`subj_info`：替换前备份至 `_trash_<日期>/`（或确认可由 clean.R 还原），**不得静默覆盖**。
- 作者分析口径（RT 200–1200 ms 修剪、ACC 缺失记为错、Task1 用于 QC 的 60% 门槛）属**分析层**，不写入 Clean，仅在 JSON `detail` 备注。
- 文件夹名 `Sun_2026_DataExp` = 全库关键 ID，不改；年份 2026 与 ChinaXiv 预印本一致。

### 6.1 第 7 项调查：Identity 是否"必须三类"——不需要（结论：`Others` 留空）

- `Self`/`Close`/`Others` 三列**不是三个必备类别**，而是 Std 6 类词表的分组简写（SKILL §数据标准化）。全库 113 行实测：**2 类 = 54 行（48%）、3 类 = 59 行、1 类 = 0 行**。
- 2 类的构成：`Self + Others`（Stranger/Other/Celebrity/NonPerson）= **46 行**（Atzeni、Constable 系列、Hu 系列、Vicovaro、Wozniak 等）；`Self + Close`（Friend）= **5 行**（Svensson_2022_PsychRes Exp1–3、Svensson_2023_QJEP、Sun 本行）；`Self + Friend + 字面 'none'` = 3 行（Wozniak_2022，legacy 非规范值）。
- 关键事实：**某组无成员时该列留空是主流做法**——46 行在无 close-other 时留空 `Close`；Sun 现状（`Others` 留空）与 Svensson 5 行一致，也符合 SKILL 条文"Close 列无 close-other 时留空"的同款逻辑。
- **结论**：`Others` **保持空白**（不用 `NA`）；无需改数据。附带项：Wozniak_2022 的 3 行字面 `none` 属非规范值，可另行统一（不在本任务范围）。

### 6.2 第 9 项调查：Task1 两名 1536 试次被试的逐段证据（来源 = 真 raw `day1_data.csv` 的 `time_elapsed`）

`phase_003_subj_14`（PID 20231101，形如日期，疑测试/演示号）——真 raw 只有**一遍**，作者文件多出**一遍**：

| 来源 | 段落 | 正确率 | 平均 RT | time_elapsed |
|---|---|---|---|---|
| 作者文件（SMT_1_raw，首遍） | prac_ALT1_1 144 → formal_ALT1_1 384 → prac_ALT1_2 48 → formal_ALT1_2 384 | 0.570 → **0.594** → 0.957 → 0.955 | 392 / 608 / 818 / 734 ms | 无时间戳 |
| 真 raw（= 作者文件的第二遍） | prac_ALT1_1 96 → formal_ALT1_1 384 → prac_ALT1_2 48 → formal_ALT1_2 384 | 0.677 → 0.893 → 0.833 → 0.896 | 518 / 607 / 570 / 572 ms | 2.07 → 35.35 min（连续一段） |

→ 首遍 `formal_ALT1_1` = 0.594 **低于 Day-2 QC 阈值 0.60**，第二遍 0.893 达标：**典型的"首跑未达标→重跑"**，平台的这份导出只保留重跑。

`phase_017_subj_20`（PID 85，与 `phase_017_subj_21`、`phase_018_subj_6` 共用 PID）——两条**独立 session 记录**（`time_elapsed` 从 45.00 min 重置到 4.42 min）：

| 记录 | 段落 | 正确率 | 平均 RT | time_elapsed |
|---|---|---|---|---|
| 第 1 条 | prac_ALT1_2 48 → formal_ALT1_2 384 → prac_ALT1_1 48 → formal_ALT1_1 384 | 0.833 / 0.917 / 0.854 / 0.930 | 723 / 723 / 713 / 683 ms | 8.65 → 45.00 min |
| 第 2 条 | prac_ALT1_2 48 → formal_ALT1_2 384 → prac_ALT1_1 48 → formal_ALT1_1 384 | 0.896 / 0.948 / 0.896 / 0.966 | 812 / 707 / 725 / 682 ms | 4.42 → 40.59 min |

→ 两遍均达 QC 标准，属**真实重复施测**（非中断丢失数据），且两遍内容不同（非复制）。

**全局计数与完整差异清单**（逐案证据已写入 `removed_subjects_log.md` §7.2/§7.3）：

| 类型 | 记录 | 作者文件 | 平台导出 | 处置（用户决策） |
|---|---|---|---|---|
| A 作者 2 遍 / 平台 1 遍 | `phase_003_subj_14` | 1536 正式（首遍 0.594 未过门槛） | 768（仅重跑遍，与作者第二遍完全一致） | **只保留重跑遍** |
| B 两边均 2 遍 | `phase_017_subj_20` | 1536 | 1536 | **两遍均保留** + `Run` 列 |
| C 平台 2 遍 / 作者 1 遍 | `phase_003_subj_2` | 768 | 1536（多出 run B） | **只采用作者文件的 1 遍**；平台 run B 不入库 |
| D 平台独有伪 ID | `NA`（PID 460） | 无 | 1872 行 / 1536 正式（含一遍 0.568 未达标） | **不入库**（作者文件无此记录） |
| E 覆盖差异 | **作者独有 38 个 ID**（`phase_002` ×13、`phase_003_subj_3`/`_10`、`phase_009` ×23） | 各 768 正式 | 该批在平台导出中完全缺失 | Task1 只能取作者文件 |

其他记录：`correct` 列在部分 run 上两源不一致（如 `phase_003_subj_2` formal_ALT1_2：0.950 vs 0.935，RT 逐段相同）；PID 与 ID 不可跨来源对齐（同 PID 可对应多个 ID）。

---

## 7. 决策清单（2026-10 汇总）

### 7.1 已定案（全部写入执行步骤，无需再议）

| # | 事项 | 决定 |
|---|---|---|
| 1 | Task1 的 `Task` 取值 | **`shape-matching`**（执行时同步在 SKILL 任务词表加该受控值） |
| 2 | ~~幽灵临时 ID~~ | ~~`phase_015_subj_ghost01`~~ **已被 §8 取代：幽灵按交集排除，不保留** |
| 3 | Task1 的 `Label` | **用中文呈现词**（由 `SMT_1.js` `words1` 恢复：三角/方形/菱形/梯形/圆形/五边/六边/椭圆）；`Shape` 保持英文形状键；raw 保留原键；Codebook 记映射 |
| 4 | `City` | **`NA`**（在线研究） |
| 5 | `PubType`/`Journal`/`DOI` | **`Journal` / `Data Express` / DOI 留空**（论文在 revision，发表后补；已记 PROJ_STATE §4 决策 22，不再作为问题提出） |
| 6 | `Repo_Link` | **`https://www.scidb.cn/s/NZjyA3`** |
| 7 | `License` | **`CC BY 4.0`**（项目自有数据） |
| 8 | `Male`/`Female` | 填**可得部分** + `Note` 注明覆盖范围（38 名作者独有被试无 `Sex`） |
| — | 两任务整合 | Task1 = SMT_1（Session 2）、Task2 = SMT_2（Session 3），同一 `_Exp1_*` CSV，可按被试边界分片 |
| — | ~~幽灵入库~~ | ~~Day-3 空 ID 记录赋临时 ID 入库~~ **已被 §8 取代（排除）** |
| — | Task1 双跑四类处置 | 作者 2 遍·平台 1 遍 → 只留与平台一致的 1 遍；两边均 2 遍 → 均保留；平台 2 遍·作者 1 遍 → 只留作者那遍；平台独有记录 → **不入库**（注：前两类当事人 `phase_003_subj_14`、`phase_017_subj_20` 均无 Session 3 数据，按 §8 交集口径**整体排除**，该处置仅存于 log 备查） |
| — | `Others` 列 | 保持空白（§6.1） |
| — | raw 分片规则 | 已写入 SKILL + `split_clean_csv.py`（§4 步骤 2） |

### 7.2 仍需您处理的两项

| # | 事项 | 状态 |
|---|---|---|
| 9 | `Design` 列文案 | **由您亲自撰写**（现值为错误的 generic 文本含 stranger）——执行时我不改动该单元格，收口时提醒 |
| 10 | **是否执行本计划（步骤 1–7）** | **等您决定**。执行会：新增 `_Exp1_raw(_part<N>)`、重写 `_Clean(_part<N>)` 与 `subj_info`、重生成 Codebook、更新 exp JSON 与 `Dataset_inf.csv`（旧文件先备份 `_trash_<日期>/` 再替换） |




---

## 8. 交集口径调整计划（2026-10-01 追加决策：以两任务交集保留数据）

> 用户 2026-10-01 指示：**按 Task1 与 Task2 的交集（而非并集）保留数据**，并把细节更新到 `removed_subjects_log.md` 与 `removed_subjects_590_to_503.csv`。
> §8.4 三项已由用户批复（A 幽灵不保留／B 删除 `Run` 列／C 不写入 SKILL，属本数据特例）；**本调整已于 2026-10-01 执行完毕**。
> **执行结果**：Clean/raw 重建为 **589 被试 / 1,040,880 行 / 20 列**（无 `Run`；Session 2 = 516,864、Session 3 = 524,016），各分 4 片（Clean ~38.8 MB/片、raw ~43.9 MB/片，逐字节可还原）；subj_info 589 行（Gender 全覆盖：Male 294 / Female 295）；Codebook 重生成 20 行；exp JSON `detail` 改写为交集口径；主索引 4 个单元格更新（Sample_Size 589、Male 294、Drop_Subj 86、Note）；`removed_subjects_590_to_503.csv` 追加 93 行（92 `no_Task2_session` + 1 `no_Task1_session`，原 87 行未动）、log 新增 §8（§7.4 标注为被取代）；paper JSON `City` 改为 `/`；两级校验 0 ERROR（W2 为 589 vs 503 口径类）；PROJ_STATE / For_COLLABORATORS 数字同步。

### 8.1 实测口径（来自当前交付文件）

| 集合 | 人数 | 行数 |
|---|---|---|
| 仅 Session 2（Task1 = SMT_1/Day 2） | **92** | 86,352 |
| 两会话都有（**交集 = 新库内口径**） | **589** | **1,040,880**（S2 516,864 + S3 524,016） |
| 仅 Session 3（Task2-only） | **1**（`phase_015_subj_ghost01`） | 864 |
| 现并集口径 | 682 | 1,128,096 |

### 8.2 交集口径的连带影响（需在计划中一并处理）

1. **`phase_003_subj_14`（此前"只保留重跑遍"的个案）→ 无 Session 3 数据，整个人被排除**；其"首遍/重跑遍"处置随之失效（仍在 log 中作为排除依据留存）。
2. **`phase_017_subj_20`（此前"两遍均保留 + `Run` 列"的个案）→ 无 Session 3 数据，整个人被排除**；因此 **`Run` 列在全表中将恒为 1**（唯一取值来源消失）。
3. `phase_003_subj_2`（平台 2 遍 / 作者 1 遍）**在交集内** → 仍按"只采用作者文件那 1 遍"处理，无变化。
4. **作者剔除的 86 人（590 − 503 − 幽灵）全部在交集内** → 仍按最小预处理原则保留（不变）。
5. **Gender 覆盖变为完整**：被排除的 92 人正是无 `Sex` 的那批 → 新 subj_info = **589 行，Gender 全覆盖**（Male 294 / Female 295，幽灵 Male 已随其排除）。
6. **文件体量**：Clean ≈ 158 MB、raw ≈ 175 MB → 仍按被试边界各分 **4 片**（≤ 50 MB/片）。
7. **主索引**：`Sample_Size` 682 → **589**；`Valid_Subj` 503 不变；`Drop_Subj` 179 → **86**；Male/Female 295/295 → **294/295**；`Note` 重写为交集口径。
8. **Codebook**：删除 `Run` 列（决策 B）→ 列数 21 → **20**，Codebook 行数同步 21 → 20，需重生成（`Session`/`Task` 枚举不变）。
9. **exp JSON `detail`**：改写口径段（589 = 590 条 Task2 记录里除幽灵外的 589 人，全部有 Task1 数据；92 名 Task1-only 与 1 条幽灵按交集规则排除），并保留双跑个案的排除记录。
10. **文档**：`removed_subjects_log.md` 新增交集口径节（含 92 人清单与幽灵）；`removed_subjects_590_to_503.csv` 追加 93 行（92 × `no_Task2_session` + 1 × `no_Task1_session`）；PROJ_STATE §3/§5、For_COLLABORATORS 的数字同步（682 → 589）。

### 8.3 执行步骤（确认后照此执行）

1. 修改 `1_Data/Sun_2026_DataExp/Sun_2026_DataExp_clean.R`：在合并两任务后按 `Subject` 取交集（`intersect(Task1 IDs, Task2 IDs)`），并对 Task1 侧同步剔除；守卫断言改为 589 被试 / 1,040,880 行。
2. 备份现有 4+4 分片与 subj_info 到 `_trash_2026-10-01/Sun_2026_DataExp_intersection/`，删除旧分片，重跑脚本 → 重新分片（Clean/raw 各 4 片）。
3. 重生成 Codebook（删除 `Run` 列 → 20 行；`2_Code/make_codebooks.R` 的 Sun job 指向合并副本）。
4. 改写 exp JSON `detail`。
5. 主索引字节保真更新（Sample_Size/Valid_Subj/Drop_Subj/Male/Female/Note）。
6. `removed_subjects_590_to_503.csv` 追加 93 行 + `removed_subjects_log.md` 新增 §8 节。
7. 两级校验（期望：JSON EXIT=0；Clean 0 ERROR，W2 为 589 vs 503 口径类 WARN）；PROJ_STATE / For_COLLABORATORS 同步。

### 8.4 已定案（2026-10-01 用户批复）

| # | 事项 | 决定 |
|---|---|---|
| A | 幽灵 `phase_015_subj_ghost01` 是否例外保留 | **不保留**——统一按交集原则（仅 Session 3、无 Session 2 → 排除） |
| B | `Run` 列是否删除 | **删除**（交集下全表恒为 1；Codebook 同步 21 → 20 行；exp JSON `detail` 说明该列原用于已排除的双跑个案） |
| C | 是否把"多任务整合可按交集口径"写入 SKILL | **不写入**——认定为本数据的**特例**，只在 `removed_subjects_log.md` 与本计划中留档，不作为通用规则 |

**口径定案结果**：Clean/raw = **589 被试 / 1,040,880 行**（Session 2 = 516,864 + Session 3 = 524,016），列数 **20**（无 `Run`）；排除 92 名仅-Session 2 被试 + 1 条仅-Session 3 幽灵（共 93 条记录，写入 `removed_subjects_590_to_503.csv` 与 log）。

**执行状态**：**待执行**（用户指示"更新计划，不执行"）。执行步骤见 §8.3。

---

## 9. 管线定义（2026-10-01 用户指示：clean.R 输入改为 raw 分片）

- **`1_Data/Sun_2026_DataExp/Sun_2026_DataExp_clean.R`（随研究文件夹，库内 26 个研究同款布局）现为 raw → Clean 的可复现路径**：
  - 输入 = `1_Data/Sun_2026_DataExp/Sun_2026_DataExp_Exp1_raw_part1..4.csv`（已入库、可跟踪的产物，**不再读输入区**）；
  - 输出 = `Sun_2026_DataExp_Exp1_Clean.csv`（再由 `2_Code/split_clean_csv.py` 切成 4 片）+ `Sun_2026_DataExp_Exp1_subj_info.csv`；
  - 因此在没有输入区（`Sun_2026_DataExp_Raw/`，被 gitignore）的 clone 中同样可重跑。
- **raw 的来源（一次性构建，已固化在分片本身）**：由输入区的作者任务级文件 `01_raw/SMT_1_raw.csv`（Task1）与平台导出 `questionnaires_day3_raw/day2_data.csv`（Task2）整合而成，构建规则（两任务整合、并集 → **交集**口径、双跑个案与空 ID 幽灵记录的处置）见 `removed_subjects_log.md` §7/§8 与本计划 §4/§8；exp JSON `detail` 亦记录数据来源。
- **验证**：重构后由 raw 分片重建的 Clean 与重构前产物**逐字节一致**（md5 `cd709abe12e30f5db07f71e5f2a1609f`，1,040,880 行 / 589 被试 / 20 列），subj_info 亦逐字节一致；分片后各片与旧片逐字节相同。
- **守卫生效范围**：脚本内含交集口径断言（589 / 1,040,880 / 1,178 对会话）、被排除记录不得出现（`phase_003_subj_14`、`phase_017_subj_20`、`phase_015_subj_ghost01`）、任务侧值域与 Identity 规则断言。
