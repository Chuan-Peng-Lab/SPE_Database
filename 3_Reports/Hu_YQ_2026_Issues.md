# Hu_YQ_2026_ChinaSciData — 未解决问题清单（请合作者协助）

> **本文件只记录尚未解决的问题**：已解决事项与处置过程不在此保留（相关记录见 git 历史、`PROJ_STATE.md` §3/§6，以及两份 Codebook 与实验 JSON 的 `detail`）。
> **数据来源**：Science Data Bank，DOI `10.57760/sciencedb.08117`（"Data for Training Effect of Self Prioritization"）；库内路径 `1_Data/Hu_YQ_2026_ChinaSciData/`。
> **编号说明**：沿用首轮核查的编号（H1–H14、N1–N5），便于与既有回复逐条对应；**本文件未出现的编号表示已解决或已定案，无需回复**。
> **关联文档**：`PROJ_STATE.md`（项目现状）、`For_COLLABORATORS.md`（合作者推进指南）、`.agents/skills/spe-database-curation/SKILL.md`（入库规范）。

---

## 1. 库内现状（供回复时对照）

| | 现状 |
|---|---|
| Exp1 | 北京 2015（Chuan-Peng Hu；Tsinghua University）：36 人；Clean 450,028 行 / raw 450,029 行（各按被试边界分 2 片） |
| Exp2 | 开封 2023（Chenghao Zhou；Henan University）：26 人；Clean / raw 各 79,592 行 |
| 主索引 | 4 行、合计 62 人：`Exp1_control`（30）、`Exp1_depression`（6）、`Exp2_matching-first`（14）、`Exp2_nonmatching-first`（12） |
| `Task` 取值 | Exp1：`shape-matching`（联结类型任务，原 association-type-matching）与 `self-matching`；Exp2：`self-matching` |
| 组别 | Exp1 的组别不是数据文件的列，由 `Exp1_subj_info.csv` 的 `BDI_Score` 推导（control：BDI<10；subclinical depression：BDI>20） |

---

## 2. 未解决问题

### 2.1 ⛔ 阻断项：输入区原始数据缺失（H1）

| 编号 | 事项 | 为什么阻塞 | 需要提供 / 回复 | 回复 |
|---|---|---|---|---|
| **H1** | 条目下**没有输入区** `Hu_YQ_2026_ChinaSciData_Raw/`；清洗脚本 `Hu_YQ_2026_ChinaSciData_clean.R` 以输入区为唯一数据源，三处 `stop()` 分别依赖 `Data_for_Exp1.csv`/`Data_for_Exp2.csv`、`Info_participants.xlsx`、`Exp2/` | 无输入区 → 清洗脚本不能在库内重跑，标准文件无法回溯复核（库内规则：原始数据留档于只读输入区） | 按下列结构放入 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/`（**保留原始文件名与目录结构，不必预先清洗或合并**）：① `Data_for_Exp1.csv`、`Data_for_Exp2.csv`（作者合并导出，GB18030）；② 北京逐被试 E-Prime 导出（`.txt`，UTF-16）→ `Task1_rawdata/`（联结类型任务）、`Task2_rawdata/`（self-matching）；③ 人口学表 `Info_participants.xlsx`；④ 开封逐被试逐阶段导出 → `Exp2/sub-<ID>/<phase>/`，`<phase>` = `baseline`、`training1`–`training7`、`formal`，文件 `<ID>.xlsx`（正式段）与 `<ID>练习.xlsx`（练习段）；⑤ 数据条目所附两份 Codebook；⑥ 实验程序文件（E-Prime `.es`/`.ebs2` 或 PsychoPy 脚本） | |

### 2.2 需要材料或公开信息

| 编号 | 事项 | 库内现状 | 需要提供 / 回复 | 回复 |
|---|---|---|---|---|
| **H2** | **开封数据的公开归属**：DOI 记录（DataCite，version V1，2023-05-08 注册）的摘要只描述 2015 年北京的两个 experiment，文件清单也只列 `Data_for_Exp1.csv`/`Data_for_Exp2.csv` + 2 份 Codebook | 开封（Zhou 2023）数据无法从 DOI 记录核实其公开版本与授权 | ① 开封数据是否随**新版（V2）数据页**发布？如有请给链接/版本号；② 若尚未公开，是否计划公开、以何许可？ | |
| **N1** | **开封被试性别未交付** | 程序把被试编号首位写进了 `Gender` 列（1→male / 2→female），该列不含性别信息；库内 `subj_info` 的 `Gender` 记为 `NA`、主索引 `Male`/`Female` 记为 `missing`（口径：原研究有该信息、库内未获得） | 是否有独立的性别记录（人口学表原件）？如有请提供 | |
| **N2** | **北京被试年龄**：6009 与 6031 的取值未定 | raw 的 Age 列跨 session 不一致（6009 为 20/26/33；6031 为 20，而作者确认值 19 不在 raw 取值中）；现 `Exp1_subj_info.csv` 中 6009 记为 `/`（不确定）、6031 用作者确认值 19 | 6009、6031 的正确年龄 | |
| **N5** | **开封交付缺漏与异常导出**（2026-10-12 登记；来源 = `Hu_YQ_2026_ChinaSciData_Exp2.json` 的 `detail`） | 26 人 × 9 阶段 = 234 个应有阶段中缺 18 个（跨 15 人）：13 个正式与练习文件全缺（`11001-training4`、`11005-training4`、`11007-training4`、`11009-training5`、`11011-training4`、`11011-training7`、`12001-baseline`、`12003-training4`、`12004-training4`、`12008-training6`、`12009-training3`、`21003-training2`、`21003-training4`），5 个仅有练习文件（`11002-training2`、`12002-training7`、`12007-training3`、`12007-training6`、`22001-training4`；`training4` 缺失最多，8 个）。另有 4 处导出异常：11001 的 baseline 文件内被试编号误写为 11003；12001 的 baseline 目录存的是 12002 的 baseline；12010 的 `training3` 与 `training4` 为同一次；`training3`/11006 第 2 块与 `training1`/22002 的正确按键反向（后者已在清洗中按作者 `fit_error.m` 更正） | ① 上述缺失阶段是否还能从原始记录补齐，或可确认为未采集？② 编号误写、目录覆盖、阶段重复是否有对应的原始文件可替换？**若重新上传输入区（H1），请一并包含这些阶段的可用文件** | |

### 2.3 需要确认的设计与口径

| 编号 | 事项 | 库内/数据现状 | 需要确认 | 回复 |
|---|---|---|---|---|
| **H3** | **任务↔文件映射**（已按数据内容落地，请确认） | `Data_for_Exp1.csv` → `shape-matching`（self-other / happy-neutral / high-low reward）；`Data_for_Exp2.csv` → `self-matching`（self/friend/stranger × 情绪） | 该映射是否正确？（映射错则 `Task` 赋值与主索引 `Design`/`Extra_Ind_Var` 全错） | |
| **H5** | **开封练习段试次数** | 数据中练习段每被试 336–576 试次；exp JSON 现记「48（320 试次版：2×24）/ 120（240 试次版：4×30）」 | 该设计值是否正确？若练习段结构与程序版本无关而实际为其他值，请指出 | |
| **H6** | **开封 block 与 Design 口径** | 开封导出无块号/试次号；exp JSON 记「正式 2 块（每块 160 或 120 试次）」，主索引 `numBlocks = 2` | 官方口径：每次参加的 block 数与命名 | |
| **H8** | **北京练习试次数** | 联结类型任务每被试 84–416（中位 154）、self-matching 144–720（中位 192）；主索引按中位数记录，JSON 注明「设计值待原作者确认」 | 练习段设计上的固定试次数（或「依条件而变」的说明） | |
| **H9** | **被试级试次差异来源** | 联结类型任务每被试主试次 2880/3456/4032 三档；self-matching 7793/8640/10080；开封 2160–2880 | 差异来源（到访次数不同？中断？）以便在 Note 中写清口径 | |
| **H14③** | **刺激类型细节** | 主索引 `Stim_Type` 两实验均写 `geometric shape`；self-matching 任务的形状层是「圆 / 横椭圆 / 竖椭圆 + 情绪表情」 | 该任务的 `Stim_Type` 是否另设值（如同时标注情绪面孔）？ | |
| **N3** | **开封块/试次编号** | 源导出无块号/试次号，Clean 因此无 `Block`/`Trial` 列（试次顺序仅由行序保留） | 源程序中是否有可导出的块/试次编号？ | |

---

## 3. 回复方式与文件放置

1. **直接回复**：在 §2 各表的「回复」列填写（或另附邮件/文档，注明编号 H1–H3、H5/H6/H8/H9/H14③、N1–N3、N5）。
2. **提供文件**：放入 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/`（只读输入区，不参与校验、不会改动）；建议保留原始文件名与目录结构，并在文件夹内附一份 `Source/README.txt` 说明每个文件对应哪个实验/任务、被试编号体系。
3. **优先顺序建议**：**H1（原始数据）> N5（开封缺漏阶段）> H3（任务映射确认）> H2（开封公开版本）> H5/H6/H8/H9/H14③、N1–N3（口径确认）**；H1 到位后其余修复可一次性完成，并重跑清洗脚本复核。

---

## 4. English summary (open items only)

1. **H1 (blocking)** — the input zone `Hu_YQ_2026_ChinaSciData_Raw/` is missing, so `Hu_YQ_2026_ChinaSciData_clean.R` cannot be re-run and the standard files cannot be re-verified. Please deposit: `Data_for_Exp1.csv` / `Data_for_Exp2.csv`; the per-participant E-Prime `.txt` logs (`Task1_rawdata/`, `Task2_rawdata/`); `Info_participants.xlsx`; the Kaifeng per-participant per-phase exports (`Exp2/sub-<ID>/<phase>/`, phases `baseline`, `training1`–`training7`, `formal`; files `<ID>.xlsx` and `<ID>练习.xlsx`); both codebooks; and the experiment programs.
2. **H2** — has the Kaifeng data been released in a new version (V2) of the deposit, and under which licence?
3. **N1** — the Kaifeng gender record (the program wrote the ID first digit into its gender column; the delivered data therefore carries no gender).
4. **N2** — the correct ages of Beijing participants 6009 and 6031 (raw Age is inconsistent across sessions).
5. **N5** — 18 of the 234 Kaifeng participant-sessions are missing (13 with no main or practice file, 5 with the practice file only), plus four anomalous exports (mislabeled ID, a baseline folder holding another participant's data, a duplicated session, and reversed response keys). Can these be supplied or confirmed as not collected?
6. **H3** — confirmation that `Data_for_Exp1.csv` = association-type-matching (`shape-matching`) and `Data_for_Exp2.csv` = self-matching.
7. **H5 / H6 / N3** — Kaifeng practice-trial counts (data show 336–576 per participant; JSON records 48 or 120), the official block count/names per visit (exports carry no block or trial numbers), and whether block/trial numbers can be exported.
8. **H8 / H9** — the designed practice-trial counts for the Beijing tasks (data show 84–416 and 144–720 per participant) and the source of the per-participant differences in main-trial counts (2880/3456/4032 and 7793/8640/10080).
9. **H14③** — whether the emotion–shape self-matching task needs a `Stim_Type` value other than `geometric shape`.

---

*问题状态变化时在本文件内更新对应编号行，不另建文档；已解决的行直接删除（记录留在 git 历史与 `PROJ_STATE.md`）。*
