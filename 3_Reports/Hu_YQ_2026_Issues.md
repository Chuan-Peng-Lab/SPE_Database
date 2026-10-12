# Hu_YQ_2026_ChinaSciData — 待处理问题清单（请合作者协助）

> **本文件用途**：记录 `1_Data/Hu_YQ_2026_ChinaSciData/`（数据来源：Science Data Bank，DOI `10.57760/sciencedb.08117`，"Data for Training Effect of Self Prioritization"）在核查中发现的问题与待确认口径，以及库内已完成的修复。需要原始数据收集方/合作者提供材料或确认事实的部分见 **§2**（可直接在表格「回复」列填写）。
>
> **当前状态（2026-10-12）**：**结构重构已完成**——北京 2015 的两个任务已合并为 `Exp1`（36 人 / 450,028 行 Clean），开封 2023 数据已编为 `Exp2`（26 人 / 79,592 行），主索引由 6 行改为 4 行（合计 62 人，不再重复计数）；两级校验 0 ERROR（`validate_json_metadata.R` EXIT=0、`validate_clean_csv.R` 0 ERROR / 28 WARN，均为已知口径或登记例外）。**仍缺输入区原始数据（H1）**，故清洗脚本尚不能在库内重跑。
>
> **关联文档**：`PROJ_STATE.md`（项目现状）、`For_COLLABORATORS.md`（合作者推进指南）、`.agents/skills/spe-database-curation/SKILL.md`（入库规范）。

---

## 0. 一句话结论

原先把**一个实验当成了两个实验**（北京 2015 被拆成 `Exp1`+`Exp2`、开封编为 `Exp3`，36 名北京被试被计两次、条目人数虚增为 98）——**该问题已于 2026-10-12 在库内修复**：现为 `Exp1` = 北京（两个任务合并）、`Exp2` = 开封，4 行索引、62 人。仍需合作者提供**原始导出（H1）**，并确认若干设计/口径细节（H5、H6、H8、H9、H14③）与新增事项（N1–N3）。

---

## 1. 库内现状（2026-10-12）

| | 现状 | 说明 |
|---|---|---|
| 实验数 | **2**（Exp1 / Exp2） | Exp1 = 北京 2015（Chuan-Peng Hu；Tsinghua University）；Exp2 = 开封 2023（Chenghao Zhou；Henan University） |
| Exp1 | 36 人；Clean **450,028 行**（分 2 片）、raw **450,029 行**（分 2 片） | 两任务合并：`association-type-matching`（self-other / happy-neutral / high-low reward）与 `self-matching`（self/friend/stranger × 情绪）；两任务在同一 6 次到访内完成（已由 raw 的日期核实） |
| Exp2 | 26 人（matching-first 14 / nonmatching-first 12）；Clean/raw 各 **79,592 行** | 9 个阶段（baseline、training1–7、formal）均为不同日期的到访（已由 raw 的 Date 核实） |
| 主索引 | **4 行**：`Exp1_control`（30 人）、`Exp1_depression`（6 人）、`Exp2_matching-first`（14 人）、`Exp2_nonmatching-first`（12 人） | 合计 62 人；组别在数据文件中不是列，可由 Exp1 subj_info 的 `BDI_Score` 推导（control：BDI<10；subclinical depression：BDI>20） |
| 标准文件 | 每实验 Clean / raw / subj_info / Codebook / exp JSON 齐备；study 级 paper JSON 1 份 | 分片共用 1 份 Codebook 与 1 份 exp JSON，不新增主索引行 |

**任务命名（2026-10-12 定案）**：`Task` 列现为 `shape-matching`（= 原 `matching`，即 association-type-matching 任务；联结类型与情绪由 extraIV 与身份列承载）与 `self-matching`。全库同时把 `monetaryValue-matching`、`facialExpression-matching` 并入 `shape-matching`，受控值表已更新（N4）。

---

## 2. 仍需合作者处理的事项

### 2.1 ⛔ 阻断项：原始数据与来源（没有这些无法重跑清洗脚本）

| 编号 | 事项 | 为什么需要 | 需要您提供 / 回复 | 回复 |
|---|---|---|---|---|
| **H1** | **原始导出缺失**：条目下**没有输入区** `Hu_YQ_2026_ChinaSciData_Raw/`；清洗脚本 `Hu_YQ_2026_ChinaSciData_clean.R` 的数据源指向该输入区（`Data_for_Exp1.csv`、`Data_for_Exp2.csv`、`Info_participants.xlsx`、`Task1_rawdata/`、`Task2_rawdata/`、`Exp2/sub-<ID>/<phase>/`），目前均不存在 → 脚本不可重跑、数据无法回溯复核 | 库内规则要求原始数据留档（输入区只读、不参与校验）；无源数据时任何重建都无法验证 | ① 北京 2015 每被试 E-Prime 导出（或已合并的 `Data_for_Exp1.csv` / `Data_for_Exp2.csv`）+ 人口学表 `Info_participants.xlsx`；② 开封 2023 每被试每阶段导出（`sub-<ID>/<phase>/`）；③ 两份 Codebook；④ 实验程序文件（`.es`/`.ebs2` 或 PsychoPy 脚本）。**按上述目录结构放入 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/` 即可**，其余由我们处理 | |
| **H2** | **开封数据的公开归属**：DOI 记录（DataCite，version **V1**，2023-05-08 注册）的摘要只描述 2015 年北京的两个 experiment，文件清单也只列 `Data_for_Exp1.csv`/`Data_for_Exp2.csv` + 2 个 Codebook | 开封（Zhou 2023）数据目前无法从 DOI 记录核实其公开版本与授权 | ① 开封数据是否随**新版（V2）数据页**发布？如有请给链接/版本号；② 若尚未公开，是否计划公开、以何许可？ | |
| **H3** | **任务↔文件映射**（已按数据内容落地，请确认） | 映射错则 `Task` 赋值全错 | 确认：`association-type-matching` = `Data_for_Exp1.csv`（self-other / happy-neutral / high-low reward）；`self-matching` = `Data_for_Exp2.csv`（self/friend/stranger × 情绪）？ | |

### 2.2 需要确认的事实（只需回复）

| 编号 | 事项 | 库内/数据现状 | 需要确认 | 回复 |
|---|---|---|---|---|
| **H4** | **Session 语义** | 北京：`Session 1–6`（另有 Session 7 仅被试 6031 一人）；开封：9 个阶段 | **已由数据核实**：北京 6 个 session = 6 个不同到访日（两任务同日完成）；开封 9 个阶段亦各为不同日期。若与您的记录不符请指出 | |
| **H5** | **开封练习段试次数** | 数据中练习段每被试 336–576 试次；库内 JSON 现记「48（320 试次版：2×24）/ 120（240 试次版：4×30）」 | 该口径是否正确？若练习段结构与程序版本无关而实际为其他值，请指出 | |
| **H6** | **Block 与 Design 口径** | 开封导出无块/试次编号；库内 JSON 记「正式 2 块（每块 160 或 120 试次）」 | 官方口径：每次参加的 block 数与命名 | |
| **H7** | **6015 的空行** | 源导出含 1 行全空记录（被试 6015 / Session 6 / 关联任务）。**2026-10-12 处置**：raw 保留该行，Clean 删除（用户决定） | 该行是文件残留还是确有记录？（若为真实记录请说明应如何编码，我们可恢复） | |
| **H8** | **练习试次数（北京）** | 关联任务每被试 84–416（中位 154）、self-matching 144–720（中位 192）；库内主索引按中位数记录，JSON 注明「设计值待原作者确认」 | 练习段设计上的固定试次数（或「依条件而变」的说明） | |
| **H9** | **被试级试次差异** | 关联任务每被试主试次 2880/3456/4032 三档；self-matching 7793/8640/10080；开封 2160–2880 | 差异来源（到访次数不同？中断？）以便 Note 中写清口径 | |
| **H14③** | **刺激类型细节** | 主索引 `Stim_Type` 两实验均写 `geometric shape`；self-matching 任务的形状层是「圆 / 横椭圆 / 竖椭圆 + 情绪表情」 | 该任务的 `Stim_Type` 是否另设值（如同时标注情绪面孔）？ | |
| **N1** | **开封被试性别** | 程序把被试编号首位写进了 `Gender` 列（1→male / 2→female），因此该列不含性别信息；旧版 subj_info 的 male/female 即由此列派生 | 库内已把 subj_info 的 `Gender` 记为 `NA`、主索引 `Male`/`Female` 记为 `missing`（按 2026-10-12 定案口径：原研究有该信息、库内未获得）。**是否有独立的性别记录**（人口学表）？如有请提供 | |
| **N2** | **北京被试年龄** | raw 的 Age 列有 4 名被试跨 session 不一致（6009 为 20/26/33；6031 为 20 而作者确认值为 19）；现 subj_info 用作者确认值，6009 记为 `/`（不确定） | 6009、6031 的正确年龄 | |
| **N3** | **开封块/试次编号** | 源导出无块号/试次号，Clean 因此无 `Block`/`Trial` 列（试次顺序仅由行序保留） | 源程序中是否有可导出的块/试次编号？ | |

### 2.3 已确认的元数据（2026-10-12 定案，供核对）

| 编号 | 字段 | 现取值 | 说明 |
|---|---|---|---|
| **H10** | `License`（数据许可） | `CC BY-NC 4.0` | 按 DataCite 记录（原 `CC BY 4.0` 系误填） |
| **H11** | `Year` | `2026`（文件夹名、主索引、paper JSON 一致） | `Year` = 数据条目年；数据收集年记在 exp JSON 的 `Collected_date`（北京 2015-10-21~12-05；开封 2023-09-25~12-19） |
| **H12** | `DOI` 列与 `PubType` | `DOI = NA`（数据集链接保留在 `Repo_Link`）；`PubType = unpublished data` | 库内规范：`DOI` 列填论文 DOI；本研究无配套论文 → `NA`（未发表先例同） |
| **H13** | `Corresponding_author` / `Email` | `Hu` / `hcp4715@hotmail.com` | 由项目负责人提供 |
| **H14①** | 非身份刺激与身份列 | `happy`/`neutral`、`￥1`/`￥16`（Exp1）与 `Filler`（Exp2）在 `*_Standardized_Identity` 中**原样保留** | 与 `Lee_2023_Cognition`（`£9`/`£1`）同款处理，属登记例外（Exp2 的 `Matching = filler` 亦已在内容级校验中登记豁免） |
| **H14②** | 英文层用词 | Exp2 标签侧英文层 `Other`、标准化层 `Stranger` | 符合库内约定（English 层 = 原文的英文对译；Standardized 层 = 6 类词表） |

---

## 3. 库内已于 2026-10-12 完成的修复（无需合作者动作）

1. **实验层级重构**：北京两任务合并为 `Exp1`（Clean 450,028 行 / raw 450,029 行）；开封改编号为 `Exp2`；删除重复的 Exp 行。
2. **主索引**：6 行 → 4 行，合计 62 人；Exp1 行重写 `Design` / `Extra_Ind_Var` / `Practice_Trial` / `numBlocks` / `numTrials` / `Self`-`Close`-`Others` / `Note`；开封行改 `Exp` 编号、`Environmental_Info` 由 `E-Prime` 改为 `PsychoPy`、练习与块口径同步 JSON。
3. **Label 侧身份列缺陷修正（34,253 行）**：关联任务的非匹配试次原先由「形状的联结」映射英文/标准化身份（导致同一行 Origin 与 English/Standardized 指向不同刺激），已改为按**实际呈现的标签词**映射；修后 `Matching` 可由身份列独立复核（`Matching ⟺ Shape_Std == Label_Std`，450,028 行全通过）。
4. **raw 表补全**：把日志恢复出的原作者字段（`Stimulus`、`TrialListS.Sample`、`TrialListE.Sample`、`TrialList.Sample`）写入 raw，使 Clean 的 `Shape`/`Block`/`Trial` 可由 raw 复现（对齐经逐行核验，0 冲突）。
5. **大文件分片**：Clean（52.0 MB）与 raw（73.2 MB）各按被试边界拆为 2 片（6001–6019 / 6020–6036），逐字节可还原；共用 1 份 Codebook 与 1 份 exp JSON。
6. **元数据**：exp JSON 的 `Modality`/`Stimulus_order`/`SOA` 改为受控值（`Visual`/`Simultaneous`/`0 ms (simultaneous)`），结构级校验的 KNOWN 豁免已删除；`Trial_number`/`Practice_trials` 改为每被试总量口径；补齐 raw 来源与分片记录、已登记例外与未决事项。
7. **Codebook 重建**：Label 侧语义、raw 补列、Group 由 BDI 推导、Exp2 的 filler 例外、开封无块/试次编号等全部写入两份 Codebook（行序 = Clean 列序）。
8. **清洗脚本**：修正 Label 侧映射、输入路径改为标准输入区、Age 用作者确认值、raw 补列与自动分片、新增一致性检查（行数/被试数/ACC 与按键/身份映射为函数等）。
9. **下游分析配置**：`3_Reports/analysis_config.R` 升为 v4——删除「Exp1+Exp2 合并」规则（重构后会把北京与开封合成一个数据集）、开封基线筛选由 `Phase == "01_baseline"` 改为 `Session == "baseline"`。分析脚本本轮只改代码、未重跑。
10. **文档同步**：`PROJ_STATE.md`、`README.md`、`For_COLLABORATORS.md` 与本文件的计数与过期描述。

---

## 4. 已核实无误（不必重复检查）

- **分组与样本**：depression 6 人 = `6005/6006/6010/6022/6025/6036`（BDI>20），control 30 人（BDI<10），与主索引一致；被排除 3 人 `6008/6015/6031` 保留在库并在 Note 说明；开封 26 人（14/12）与 JSON 一致。
- **N 口径**：`Sample_Size` = Clean 被试数；`Valid_Subj` = 作者分析样本（北京 control 27 / depression 6；开封 14/12）；`Drop_Subj` = 差值。
- **数据标准化**：ACC 统一为 `1`/`0`/`NA`（无空字段）；`Matching` 严格 `Matching`/`Nonmatching`（Exp2 的 `filler` 已登记豁免）；Clean 列序符合模板 v2；Codebook 单 Sheet1、4 列、行数 = Clean 列数且行序一致。
- **raw↔Clean 一致性**：逐值核对 0 差异（差异仅为「空串 → 字面量 `NA`」）；`ACC` vs `Response == CorrResponse` 0 违例（Exp1 435,751 行 / Exp2 77,810 行）；身份绑定逐被试以 raw 的 `Selfpic`/`Stranger` 交叉验证，36 人 0 冲突（旧版「整被试反向」问题已消解）；开封形状-身份奇偶平衡 0 违例。
- **校验基线**：`validate_json_metadata.R` EXIT=0（144 JSON / 52 文件夹）；`validate_clean_csv.R` 0 ERROR / 28 WARN（W1 缺标准列 27 + W5 1；另打印组间拆行的 W2 口径差异，不计数）。

---

## 5. 回复方式与文件放置

1. **直接回复**：在 §2 各表的「回复」列填写（或另附邮件/文档，注明编号 H1–H14、N1–N3）。
2. **提供文件**：放入 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/`（只读输入区，不参与校验、不会改动）；建议保留原始文件名，并在文件夹内附一份 `Source/README.txt` 说明每个文件对应哪个实验/任务、被试编号体系。
3. **优先顺序建议**：**H1（原始数据）> H3（任务映射确认）> H2（开封公开版本）> H5/H6/H8/H9/H14③、N1–N3（口径确认）**；H1 到位后其余修复可一次性完成并重跑清洗脚本复核。

---

## 6. English summary for co-authors

**What has been fixed (2026-10-12).** The structural problem reported earlier is resolved. Experiment 1 now holds the 2015 Beijing collection with its two association tasks merged (36 participants; 450,028 Clean rows / 450,029 raw rows; both tables split into two whole-participant parts), and Experiment 2 holds the 2023 Kaifeng training study (26 participants; 79,592 rows). The master index has 4 rows and 62 participants instead of 6 rows and 98. In addition, the label-side identity columns of 34,253 mismatching trials were corrected so that the original-language, English and standardized identity always describe the presented label word (the same defect had been fixed for Hobbs_2023_PsychMed on 2026-10-08), the raw table now carries the trial fields recovered from the E-Prime logs so that the Clean columns are reproducible from it, the experiment JSONs use the controlled vocabularies (`Visual`, `Simultaneous`, `0 ms (simultaneous)`), and the codebooks, the cleaning script and the analysis assembly layer were updated accordingly. Both validators pass (structural EXIT=0; content 0 ERROR).

**What we still need from you.**
1. **H1** the original per-participant exports and the experiment programs — the input folder `Hu_YQ_2026_ChinaSciData_Raw/` is still missing, so the cleaning script cannot be re-run inside the repository.
2. **H3** confirmation of the task-to-file mapping (association-type-matching = `Data_for_Exp1.csv`; self-matching = `Data_for_Exp2.csv`).
3. **H2** whether the Kaifeng data has been released in a new version of the deposit.
4. **H5/H6/H8/H9/H14③, N1–N3** open design and caliber details: practice-trial counts, block definition, per-participant trial-count differences, the stimulus type of the emotion-shape task, the Kaifeng participant gender (the program wrote the ID first digit into the gender column), the ages of participants 6009 and 6031, and whether the Kaifeng program can export block/trial numbers.
5. **N4** the database-wide `Task` vocabulary review (currently `matching` is the only value in the database outside the controlled list; survey results in the project state file).

**Already decided and recorded.** Data licence `CC BY-NC 4.0`; `Year` 2026 = record year with the data-collection periods in `Collected_date`; `DOI` column `NA` (dataset link stays in `Repo_Link`); corresponding e-mail `hcp4715@hotmail.com`; non-identity values (`happy`/`neutral`, `￥1`/`￥16`, `Filler`) are kept as-is in the identity columns as registered exceptions; the all-blank source record (participant 6015, session 6) is kept in the raw table and removed from the Clean table.

---

*Created: 2026-09-25；主体重构完成并于 2026-10-12 更新。问题状态变化时请在本文件内更新对应编号行，不另建文档。*
