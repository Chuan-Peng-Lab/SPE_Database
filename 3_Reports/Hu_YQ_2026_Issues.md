# Hu_YQ_2026_ChinaSciData — 待处理问题清单（请合作者协助）

> **本文件用途**：记录 `1_Data/Hu_YQ_2026_ChinaSciData/`（数据来源：Science Data Bank，DOI `10.57760/sciencedb.08117`，"Data for Training Effect of Self Prioritization"）在 2026-09-25 核查中发现的**结构性问题与待确认字段**。其中多项只能由原始数据收集方/合作者提供材料或确认事实后才能修复——请按 **§2** 逐项回复（可直接在表格「回复」列填写）。
>
> **当前状态**：库内两级校验通过（`validate_json_metadata.R` EXIT=0；`validate_clean_csv.R` 0 ERROR / 7 WARN，均为预期口径或已登记项），但**实验层级与事实不符**（见 §1），在修复前不建议用于任何汇总/元分析统计。
>
> **关联文档**：`PROJ_STATE.md`（项目现状）、`For_COLLABORATORS.md`（合作者推进指南）、`.agents/skills/spe-database-curation/SKILL.md`（入库规范）。

---

## 0. 一句话结论

库内把**一个实验当成了两个实验**：北京 2015（Chuan-Peng 收集）的两个任务被拆成 `Exp1` 与 `Exp2`，开封（Zhou 2023）的数据被编为 `Exp3`；正确结构应为 **2 个实验**——`Exp1` = 北京（含 `self-emotion-association` 与 `association-type-matching` 两个任务），`Exp2` = 开封。
**直接后果**：北京同一批 36 名被试被计数两次（该条目被试数虚增为 98，实际应为 62），主索引由应为的 4 行膨胀为 6 行；并连带 `Task` 列语义、`extraIV` 命名、Codebook、实验 JSON、目录结构全部需要重建。

---

## 1. 库内现状 vs 应有结构

| | 库内现状（2026-09-25） | 应有结构（已确认） |
|---|---|---|
| 实验数 | **3**（Exp1 / Exp2 / Exp3） | **2** |
| Exp1 | 北京 2015，36 人；`Task` = self-matching / emotion / reward（**3 种"联结类型"被误当任务**）；Clean 130,716 行 | 北京 2015 合并文件（含两任务，450,029 行；约 88.8 MB，按库内大文件规则分 2 片） |
| Exp2 | 北京 2015 **同一批 36 人**；`Task` = self-matching；identity self/friend/stranger × 4 情绪；Clean 319,313 行 | 开封 Zhou 2023（26 人，matching-first 14 / nonmatching-first 12），Clean 79,592 行 |
| Exp3 | 开封 Zhou 2023（26 人） | —（并入 Exp2） |
| 主索引 | 6 行（Exp1×2 组 + Exp2×2 组 + Exp3×2 组），`Sample_Size` 合计 98 | **4 行**（Exp1_control、Exp1_depression、Exp2_matching-first、Exp2_nonmatching-first），合计 62 |

**任务命名与映射（待您确认，见 H3）**——库内按数据内容判定：

| 应有任务 | 内容 | 对应库内现有数据 |
|---|---|---|
| `self-emotion-association` | 将自我与不同情绪联结 | 现 `Exp2/`（12 张圆脸图片 × 情绪 control/neutral/happy/sad；标签 自己/朋友/生人） |
| `association-type-matching` | 自我、情绪、奖赏三种联结 | 现 `Exp1/`（联结类型 self-other / happy-sad / high-low reward；标签 你/生人/高兴/中性/￥1/￥16） |

---

## 2. 需要合作者处理的事项

### 2.1 ⛔ 阻断项：原始数据与来源（没有这些无法重建/复核）

| 编号 | 事项 | 为什么需要 | 需要您提供 / 回复 | 回复 |
|---|---|---|---|---|
| **H1** | **原始导出缺失**：条目下**没有输入区** `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/`；清洗脚本 `Hu_YQ_2026_ChinaSciData_clean.R` 的数据源写死为仓库内 `clean/Hu_2015_unpub/…` 与 `clean/Zhou_2023_unpub_Exp1/cleaned/…`，该目录**在仓库与本地均已不存在** → 脚本不可重跑、数据无法回溯复核 | 库内规则要求原始数据留档（输入区只读、不参与校验）；无源数据时任何重建都无法验证 | ① 北京 2015 每被试 E-Prime 导出（或已合并的 `Data_for_Exp1.csv` / `Data_for_Exp2.csv`）；② 开封 2023 每被试导出；③ 两份 Codebook（`Codebook_Data_for_Exp1.xlsx` 等）；④ 实验程序文件（`.es`/`.ebs2` 或 Python 脚本）。**放到 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/` 即可**，其余由我们处理 | |
| **H2** | **开封数据的公开归属**：DOI 记录（DataCite，version **V1**，2023-05-08 注册，2026-03-26 有元数据更新）的摘要**只描述 2015 年北京的两个 experiment**，文件清单也只列 `Data_for_Exp1.csv`/`Data_for_Exp2.csv` + 2 个 Codebook（记录为 5 files / 41 MB） | 开封（Zhou 2023）数据目前无法从 DOI 记录核实其公开版本与授权 | ① 开封数据是否随**新版（V2）数据页**发布？如有，请给链接/版本号；② 若尚未公开，是否计划公开、以何许可？ | |
| **H3** | **任务↔文件映射确认**（见 §1 表；库内按数据内容判定，需您确认） | 映射错则合并后的 `Task` 赋值全错 | 确认：`self-emotion-association` = 现 `Exp2/`（self/friend/stranger × 情绪圆脸）；`association-type-matching` = 现 `Exp1/`（self-other / happy-sad / high-low reward）？ | |

### 2.2 需要确认的事实（只需回复）

| 编号 | 事项 | 库内/数据现状 | 需要确认 | 回复 |
|---|---|---|---|---|
| **H4** | **Session 语义** | 北京两份数据都是 `Session 1–6` 各 36 人，另有 `Session 7` **仅被试 6031 一人**（6031 正是被排除被试）；实验 JSON 现写「7 sessions」（任务②）/「6 sessions」（任务①）；DOI 摘要写「× 6 (sessions: 6)」 | ① 这 6 个 session 是**6 次到访**，还是同一次参加内的 6 个重复 run？② 6031 的 Session 7 是补测还是数据误差（是否保留）？ | |
| **H5** | **开封练习段试次数** | 数据 `00_practice` 阶段每被试 **336–576 试次（中位 456）**；而库内元数据写「4 blocks × 10 trials = **40**」 | 40 指什么？练习段实际结构（块数 × 每块试次）为何？ | |
| **H6** | **Block 与 Design 口径** | 任务② 数据 `Block`∈{1,2} 且**在每个联结类型内重新计数**（3 联结 × 2 = 每次 6 段）；任务① 数据 `Block` 1–6；库内 CSV 写 `×2(block)`/`numBlocks=2`，实验 JSON 写 `×6(block)`/「6 formal blocks」 | 官方口径：每次参加的 block 数与命名（是否把"3 联结 × 2"算作 6 个 block） | |
| **H7** | **6015 的空行** | 北京任务② 有 1 行全为 `NA`（`Subject 6015 / Session 6 / practice`），触发校验器 W5（Matching 非规范取值） | 该行是文件残留还是确有记录？保留（并标注）还是删除？ | |
| **H8** | **练习试次数（北京）** | 任务② 每被试 84–416（中位 154）、任务① 144–720（中位 192）；库内按中位数填 154/192 且未注明口径（JSON 仅写 "Present"） | 练习段设计上的固定试次数（或"依条件而变"的说明） | |
| **H9** | **被试级试次差异** | 任务② 每被试主试次 2880 / 3456 / 4032 三档；任务① 7793 / 8640 / 10080；开封 2160–2880 | 差异来源（参加次数不同？中断？）以便 Note 中写清口径 | |

### 2.3 需要确认的元数据（与外部权威记录冲突）

| 编号 | 字段 | 库内现值 | 外部记录 / 事实 | 需要确认 | 回复 |
|---|---|---|---|---|---|
| **H10** | `License`（数据许可） | `CC BY 4.0`（6 行） | DataCite 记录：**CC BY-NC 4.0** | 以哪个为准？若新版数据页已改为 CC BY，请给依据 | |
| **H11** | `Year` | **2026**（文件夹名、CSV、JSON 一致） | DataCite：`publicationYear` **2023**、version V1；数据采集年为 2015（北京）/ 2023（开封） | 2026 是否指新版数据页发布年？请确认口径 | |
| **H12** | `DOI` 列与 `PubType` | `DOI` 填**数据集 DOI**（与 `Repo_Link` 相同）；`PubType` = `unpublished data` | 库内规范：`DOI` 列应填**论文 DOI**，数据链接归 `Repo_Link`；未发表条目先例（Sui_2014/2015_unpub、Pan_2025_unpub）`DOI` = `NA` | 是否有配套论文/预印本？如无，`DOI` 是否置 `NA`、`PubType` 是否维持 | |
| **H13** | `Corresponding_author` / `Email` | 现为 `Hu` / 空白 | 数据页应含通讯作者邮箱；库内空白 = "不确定" | 请提供通讯作者与邮箱（或确认留空） | |
| **H14** | 身份列与刺激类型细节 | CSV `Others` 列仅填 `Stranger`，但标准化身份还含 `Happy/Neutral/Low_reward/High_reward`（任务②）与 `Filler`（开封，伪词 白栽/地入）；英文层用 `Other`、标准化层用 `Stranger`；`Stim_Type` 两任务均写 `geometric shape` | — | ① 非人身份/`Filler` 是否计入 `Others` 简写列？② 英文层是否统一为 `Stranger`？③ 任务① 的形状是带表情的圆脸图片，`Stim_Type` 是否另设值？ | |

---

## 3. 库内将自行修复（无需合作者动作，列出供知情）

1. **实验层级重构**：北京两任务合并为 1 个实验的单一 Clean（450,029 行；列取并集、按库内模板 v2 列序），开封数据编号由 `Exp3` 改为 `Exp2`；删除重复的 Exp 行。
2. **`Task` / `extraIV` 规范**：`Task` 改为 `self-emotion-association` / `association-type-matching`；任务内操纵（联结类型、情绪）降为 `extraIV1`（或 `extraIV1/extraIV2`）。
3. **主索引 `Dataset_inf.csv`**：6 行 → 4 行（删除北京重复计数的 2 行、`Exp 3→2`、重写 Exp1 两行的 `Design`/`Extra_Ind_Var`/`numTrials`/`numBlocks`/`Practice_*`/`Self-Close-Others`），按 ID 字母序重排（字节保真校验）。
4. **元数据重建**：合并后的实验 JSON ×2（含大文件分片记录、`Trial_number` = 行数÷被试数、Session 实况），Codebook 重建（行序 = Clean 列序），`subj_info` 保持 1 份/实验。
5. **大文件分片**：合并后的北京 Clean（约 88.8 MB）按库内新规则在被试边界拆为 `_Clean_part1/part2.csv`（见 SKILL.md §文件与文件夹规范「大文件拆分」）；分片共用 1 份 Codebook 与 1 份 JSON，不新增主索引行。
6. **文档同步**：`PROJ_STATE.md`、`README.md`、`SKILL.md` 中的计数与过期描述（如 SKILL 仍写本条目 "deferred — 无文件夹"）。

---

## 4. 已核实无误（不必重复检查）

- **分组与样本**：depression 6 人 = 数据页 BDI 名单 `6005/6006/6010/6022/6025/6036` 完全一致；被排除 3 人 `6008/6015/6031` 保留在库并在 Note 说明；开封 26 人（14 / 12）与 JSON 一致。
- **N 口径**：`Sample_Size` = Clean 被试数；`Valid_Subj` = 作者分析样本（北京 control 27 / depression 6；开封 14 / 12）；`Drop_Subj` = 差值。
- **数据标准化**：ACC 统一为 `1`（正确）/`0`（错误）/`NA`（无反应）；`Matching` 严格 `Matching`/`Nonmatching`（仅 H7 的 1 行例外）；列序符合库内模板 v2；Codebook 为单 Sheet1、4 列、行数 = Clean 列数且行序一致。
- **校验基线**：`validate_json_metadata.R` EXIT=0（142 JSON / 51 文件夹）；`validate_clean_csv.R` 0 ERROR（7 条 WARN：6 条为组间拆行的 Sample/Valid 口径差异（预期），1 条为 H7 的空行）。

---

## 5. 回复方式与文件放置

1. **直接回复**：在 §2 各表的「回复」列填写（或另附邮件/文档，注明编号 H1–H14）。
2. **提供文件**：放入 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/`（只读输入区，不参与校验、不会改动）；建议保留原始文件名，并在文件夹内附一份 `Source/README.txt` 说明每个文件对应哪个实验/任务、被试编号体系。
3. **优先顺序建议**：**H1（原始数据）> H3（任务映射）> H2/H10/H11（来源与许可）> H4–H9、H12–H14（口径确认）**；H1、H3 到位后其余修复可一次性完成。

---

## 6. English summary for co-authors

**What is wrong.** The database currently treats the 2015 Beijing collection as **two** experiments (`Exp1`, `Exp2`) and the 2023 Kaifeng collection as `Exp3`. According to the confirmed project facts, this entry should contain **two experiments**: `Exp1` = Beijing 2015 (Chuan-Peng Hu; Tsinghua University) comprising **two association tasks** — `self-emotion-association` and `association-type-matching` — and `Exp2` = Kaifeng 2023 (Zhou; Henan University). As a result the same 36 Beijing participants are counted twice (98 instead of 62 participants; 6 index rows instead of 4), and the `Task` column currently encodes association type instead of task identity.

**What we need from you.**
1. **H1** The original per-participant exports (Beijing 2015 and Kaifeng 2023) and the experiment programs — the input folder `Hu_YQ_2026_ChinaSciData_Raw/` is currently missing, so the cleaning script cannot be re-run.
2. **H3** Confirmation of the task-to-data mapping (self-emotion-association = current `Exp2/`; association-type-matching = current `Exp1/`).
3. **H2** Whether the Kaifeng data has been released in a new version of the deposit (the DOI record, V1/2023, only describes the two 2015 experiments).
4. **H10–H11** Data licence (our index says `CC BY 4.0`; DataCite records `CC BY-NC 4.0`) and year (index uses 2026; DataCite records 2023).
5. **H4–H9, H12–H14** Several design details to confirm: session semantics, practice-trial counts (Kaifeng: 40 declared vs ~456 in the data), block/design definition, one all-NA row (subject 6015), per-participant trial-count differences, DOI/PubType/Email, and identity-column conventions.

**What we will fix ourselves.** Merging the two Beijing tasks into one experiment, renumbering Kaifeng as `Exp2`, rebuilding the index rows (6 → 4), the `Task`/`extraIV` columns, codebooks and experiment JSONs, and splitting any file > 50 MB at whole-subject boundaries.

---

*Created: 2026-09-25（核查与文档：SPE Database curation agent）。问题状态变化时请在本文件内更新对应编号行，不另建文档。*
