# 1_Data — 数据与元数据使用说明（给数据使用者）

本目录是 SPE Database 的数据层：每个研究一个文件夹，文件夹内是本库统一后的**标准文件**，元数据以 JSON 记录。
本库把各研究的原始导出统一成三层规范：**① 文件夹结构**、**② 试次级数据**、**③ 实验实施元数据**。
规则正文（唯一权威）在 [`.agents/skills/spe-database-curation/SKILL.md`](../.agents/skills/spe-database-curation/SKILL.md)；
本文件面向使用者，说明这三层各统一了什么、以及使用时的注意事项。

---

## ⚠️ 先读这一条：`Task` 列不等于实验条件

2026-10-12 全库统一 `Task` 命名后，`Task` 只回答**一个问题**：该试次的**联结对象是否含自参照身份**。受控值只有三个：

| `Task` | 含义 |
|---|---|
| `self-matching` | 形状↔自我/他人等**自参照身份**联结的匹配判断（数据库核心任务） |
| `shape-matching` | **不含自参照身份**的形状-标签匹配（形状名、情绪面孔、货币金额，以及同一任务内混合联结类型的匹配） |
| `choice-task` | 二择一知觉辨别（判断刺激的感觉特征本身，无匹配判断） |

**同一研究内不同条件可能共用同一个 `Task` 值**，因此**不能只按 `Task` 分组**。条件/操纵要从下面这些位置读取：

1. **刺激列原值** `Shape` / `Label`——例如伪词任务的标签是伪词（`Nenu`/`Miru`/`Waru`），标准任务的身份词是 `You`/`none`/朋友名；
2. **三级身份列** `Shape_*_Identity` / `Label_*_Identity`——例如 `£9`/`£3`/`£1` = 奖赏条件、`happy`/`neutral`/`sad` = 情绪条件、`Self`/`Close`/`Stranger` = 身份条件；
3. **`extraIV1` / `extraIV2`**——任务内的额外操纵自变量（各研究的语义写在 Codebook 与 exp JSON `detail` 中，同名列在不同研究含义不同）；
4. **`Session` / `Phase` / `Block` / `Trial`**——多阶段（训练/基线）、多块设计；
5. **该研究的 exp JSON `detail` 与 Codebook**——每个研究都写明了本研究的条件信息承载在哪些列。

已登记的两个示例（完整清单见 SKILL §数据标准化「任务与附加自变量命名」）：

| 研究 | 共用的 `Task` 值 | 条件如何区分 |
|---|---|---|
| `Hobbs_2023_PsychMed_Exp1` | `shape-matching`（情绪任务与金钱任务） | 身份列：`Self`=Self/Close/Stranger；`Valence`=happy/neutral/sad；`Reward`=£9/£3/£1 |
| `Wozniak_2022_PsychRes_Exp1–3` | `self-matching`（标准自我任务与伪词任务） | `Label` 列原刺激：伪词任务=`Nenu`/`Miru`/`Waru`；标准任务=`You`/`none`/朋友名 |

> 使用建议：**先读该研究的 Codebook 与 exp JSON `detail`，再决定用哪些列切条件。**

---

## 一、文件夹结构标准化

| 层级 | 约定 |
|---|---|
| 主索引 | `1_Data/Dataset_inf.csv`（UTF-8 带 BOM）。**一行 = 一个 `Folder_Name` + `Exp` + `subj_Group` 三元组**（被试分组研究按组拆多行）。旧版 `Dataset_inf.xlsx` 已废弃，勿用。 |
| 研究文件夹 | `1_Data/<Folder_Name>/`，`<Folder_Name>` = `<FirstAuthor>_<Year>_<Suffix>`，全库唯一的研究 ID；`Year` = 正式印刷年/数据条目年，文件名纯 ASCII（如 `Hu_YQ_2026_ChinaSciData`、`Lee_2023_Cognition`）。 |
| 单实验研究 | 文件平铺在研究文件夹内（paper JSON、exp JSON、raw、Clean、subj_info、Codebook 同目录）。 |
| 多实验研究 | 每个实验一个 `Exp<N>/` 子文件夹，其内放该实验的全部标准文件；**paper JSON 固定放在研究文件夹根**。 |
| 输入区 | `1_Data/<Folder_Name>/<Folder_Name>_Raw/`（历史小写 `_raw/` 变体亦合法）= 下载到的原始导出，**只读**、不参与校验、不算标准产物；可含 `Source/` 子目录。 |
| 大文件分片 | 单个 `*_Clean.csv` 或 `*_raw.csv` > 50 MB 时按**整被试边界**拆为 `_Clean_part<N>.csv` / `_raw_part<N>.csv`：各片表头逐字节相同、`rbind` 可还原、**仍视为 1 个数据集**（不新增主索引行，共享 1 份 Codebook 与 1 份 exp JSON）。 |

**每个研究应交付的标准文件（5 类规范产物）**

| 文件 | 内容 |
|---|---|
| `*_raw.csv` | 标准化**试次级原始值**（源导出 + 为可追溯补齐的字段；保留作者原始编码） |
| `*_Exp<N>_Clean.csv` | **最小预处理（标准化）产物**，下游分析的主入口 |
| `*_Exp<N>_subj_info.csv` | 被试级人口学（`Subject_ID`/`Exp_id`/`Age`/`Gender`/…） |
| `Codebook_*_Exp<N>_Clean.xlsx` | 数据字典：单 `Sheet1`、4 列（`Variable_name`/`Variable_description`/`Variable_value`/`Variable_category`），**一行 = Clean 的一列**，行序与 Clean 列序一致 |
| `<Folder_Name>.json` + `<Folder_Name>_Exp<N>.json` | 论文级 + 实验级元数据 |

---

## 二、数据标准化（`*_Exp<N>_Clean.csv`）

**最小预处理 ≠ 过滤。** Clean 只是重命名/重排/统一编码：**不删试次、不删被试、不改数值**；练习试次若保留则用 `Phase` 标注而非删除；极端 RT、无反应等特殊值按统一编码保留，由使用者按自己的分析目标预处理。

- **列序（模板 v2）**：`Subject → [Group] → [Session] → Task → [Phase] → [Condition] → Block → Trial → [Practice] → Matching → Shape → [ShapeLoc] → [Shape_Subtype] → Shape-Identity×3 → Label → Label-Identity×3 → [extraIV1] → [extraIV2] → [CorrResponse] → [Response] → RT_ms → RT_sec → ACC → [研究特有保留列]`（`[ ]` = 该研究没有则跳过）。
- **`Shape` / `Label` = 实际呈现的刺激**：形状层可能是几何形状、面孔图片、说话者、联结类型等；标签层是呈现的标签词/图片。**不再用数字编码**，原始编码保留在 raw 与研究特有的 `*Code` 列。
- **身份三级**（每个承载身份的刺激列各一套）：`*_Origin_Identity`（原文，保留原语言）→ `*_English_Identity`（英文对译）→ `*_Standardized_Identity`（规范词表：`Self`/`Close`/`Stranger`/`Celebrity`/`Acquaintance`/`NonPerson`）。分析请使用 **Standardized** 层。词表外的**已登记例外**：货币（`£1`/`£3`/`£9`、`￥1`/`￥16`）、情绪（`happy`/`neutral`）、`ingroup`、无身份伪词试次（`Filler`）、被试提供名字的占位值（`subj_name`）。
- **`Matching`**：`Matching`（呈现的形状-标签对与所学联结一致）/ `Nonmatching`（不一致），严格二值（极少数研究登记例外，见各研究 Codebook 与 SKILL）。
- **`ACC` 统一编码**：`1` 正确 / `0` 错误 / `NA` 无反应（**一律写字面量 `NA`，不是空字段**）/ `-2` 范围外按键 / `-3` 提前按键 / `-4` 超时按键；后三者仅在原数据有明确证据时使用。
- **缺失三态**：`missing`（明确无法获得）/ 空白（不确定）/ `NA`（明确没有或不适用）——三者含义不同，请勿一律当缺失处理。JSON 中的未知值写作 `/`。
- **`subj_info` 口径**：`Gender` 统一为 `Female`/`Male`（作者原始的非二元类别按原值保留）；人口学缺失写 `/`。
- **raw 与 Clean 的关系**：Clean 可由同研究的 `*_raw.csv` 复现（分片先按序 `rbind` 还原）。

---

## 三、实验实施元数据（JSON）

### 3.1 论文级 `<Folder_Name>.json`（11 个字段）

`Paper_name`、`Summary`、`Year`、`Author`、`Journal`、`Country`、`City`、`Extra_Var`、`Email`、`DOI`、`Conclusion`。使用时注意：

- `Year` = 正式印刷年/数据条目年（**不是**数据采集年；采集时间见 exp JSON 的 `Collected_date`）；
- `Country` / `City` = **数据采集地**（不是作者单位）；
- `DOI` = **论文 DOI**（数据链接在 `Dataset_inf.csv` 的 `Repo_Link` 列；未发表条目为 `/` 或 `NA`）；
- `Email` 以 `Dataset_inf.csv` 现值为准。

### 3.2 实验级 `<Folder_Name>_Exp<N>.json`（v2 schema：五个字段组）

| 字段组 | 记录内容 | 使用注意 |
|---|---|---|
| `Physical_Environment` | `Location`、`Setting`、`Equipment`（呈现软件/显示器）、`Viewing_distance` | `Setting` 为受控值：`Laboratory` / `Online` / 组合值；**`Setting` = 施测环境**，不是软件 |
| `Experimental_Design` | `Conditions`：该实验操纵/比较了哪些条件 | 完整因子设计另见主索引 `Design` 列 |
| `Block_Structure` | `Block_number`、`Trial_number`、`Practice_trials` | `Trial_number` 为每被试总试次（多 session 研究为合计），含口径说明 |
| `Trial_Structure` | `Fixation_duration`、`Stimulus_duration`、`SOA`、`ISI`、`Stimulus_order`、`Response_deadline`、`ITI`、`Feedback_duration` | **`SOA` = 前一刺激 onset → 后一刺激 onset；`ISI` = 前一刺激 offset → 后一刺激 onset**；同时呈现记 `0 ms (simultaneous)`；`Stimulus_order` 取 `Simultaneous`/`Sequential` |
| `Stimulus_Properties` | `Modality`、`Fixation`、`Shape`、`Label`、`Colors` | **`Modality` = 感觉通道**（`Visual`/`Auditory`/`Audiovisual`）；EEG/fMRI 是记录技术、不是 modality；刺激类别（几何形状/面孔/声音/词）写 CSV 的 `Stim_Type` |

另有 `schema_version`、`Collected_date`（采集时间）、**`detail`**。

> **`detail` 是每个实验的实施细节与已知问题记录处**：试次结构、编码映射、合并/分片说明、登记例外、口径与未决事项都写在这里。**使用任何一项数据前请先读 `detail`。**

---

## 四、建议的使用路径

1. 在 `Dataset_inf.csv` 里按 `Folder_Name`（研究 ID）+ `Exp` + `subj_Group` 定位研究行，取得样本量、设计、任务、试次数、数据链接与许可；
2. 进入 `1_Data/<Folder_Name>/`，依次读 **paper JSON → exp JSON（尤其 `detail`）→ Codebook**；
3. 使用 `*_Exp<N>_Clean.csv`（分片先 `rbind` 还原）；需要作者原始编码时对照 `*_raw.csv`；
4. 按自己的分析目标做完整预处理（练习试次、无反应、离群值、极端 RT 等本库均**不预先剔除**）。

| 相关文件 | 作用 |
|---|---|
| `1_Data/Dataset_inf.csv` | 主索引（研究级/实验级/分组级信息、数据链接、许可） |
| `1_Data/<Folder_Name>/Codebook_*.xlsx` | 该数据集的变量字典（含全部取值与特殊码） |
| `1_Data/<Folder_Name>/*.json` | 论文级与实验级元数据（`detail` 含口径与例外） |
| `.agents/skills/spe-database-curation/SKILL.md` | **规则正文**：文件夹/命名、JSON schema、Identity 三级、ACC 编码、Codebook、主索引字段语义 |
| `PROJ_STATE.md` | 项目现状（收录规模、已知问题、暂缓条目） |
| `3_Reports/` | 分析代码与产出（不含原始数据） |

---

## English summary (for data users)

- **What this folder is.** One folder per study under `1_Data/`; every study ships five standard products: `*_raw.csv` (standardized trial-level source values), `*_Exp<N>_Clean.csv` (minimal-preprocessing product, the analysis entry point), `*_Exp<N>_subj_info.csv` (participant level), `Codebook_*_Clean.xlsx` (data dictionary), and paper + experiment JSON metadata. `1_Data/Dataset_inf.csv` is the master index (one row per `Folder_Name` + `Exp` + `subj_Group`); `Dataset_inf.xlsx` is obsolete.
- **⚠️ `Task` is not the condition variable.** Since the database-wide unification (2026-10-12) `Task` only tells whether the shape-label association involves a self-referential identity: `self-matching`, `shape-matching`, or `choice-task`. Different conditions **can share the same `Task` value**; read the condition from the stimulus columns (`Shape`/`Label`), the three-level identity columns, `extraIV1`/`extraIV2`, `Session`/`Phase`/`Block`/`Trial`, and always from the study's Codebook and experiment JSON `detail`. Registered examples: `Hobbs_2023_PsychMed_Exp1` (emotion and reward tasks both `shape-matching`, separated by identity columns) and `Wozniak_2022_PsychRes_Exp1–3` (standard and pseudo-word tasks both `self-matching`, separated by the `Label` column).
- **Data standardization.** Fixed column order (template v2), readable stimulus values in `Shape`/`Label`, three-level identity columns per identity-bearing stimulus (Origin → English → Standardized, six-category vocabulary plus registered exceptions such as currencies, emotions, `ingroup`, `Filler`, `subj_name`), `Matching` strictly `Matching`/`Nonmatching`, ACC coded `1`/`0`/`NA`/`-2`/`-3`/`-4` (no response always the literal `NA`), and the three-state missing convention (`missing` / blank / `NA`). Nothing is filtered out: practice trials, outliers and special codes are retained and documented — preprocess according to your own analysis plan.
- **Experiment metadata.** The experiment JSON (v2) records five field groups — `Physical_Environment` (with the controlled `Setting`), `Experimental_Design`, `Block_Structure`, `Trial_Structure` (`SOA` = onset-to-onset, `ISI` = offset-to-onset, `Stimulus_order`), `Stimulus_Properties` (`Modality` = sensory channel, not recording technique) — plus `Collected_date` and a free-text **`detail`** field that documents trial structure, coding mappings, merging/splitting, registered exceptions and open items. **Read `detail` before using a dataset.**
- **Large files** (> 50 MB) are split at whole-participant boundaries into `_Clean_part<N>.csv` / `_raw_part<N>.csv` with identical headers; reassemble with `rbind`; the parts share one Codebook and one experiment JSON and add no index row.
- **Authoritative rules** live in `.agents/skills/spe-database-curation/SKILL.md`; project status in `PROJ_STATE.md`.
