# For_COLLABORATORS.md — 合作者指南：如何推进 SPE 数据库

> 本文面向**合作者（人类读者）**：说明拿到新数据后要做什么、把文件放到哪里、如何让 agent 完成后续的整理入库。
> 细则正文不在此重复，只放指针：入库流程细则见 `.opencode/skills/spe-database-curation/SKILL.md`；项目状态与未解决问题见 `PROJ_STATE.md`；仓库纪律见 `AGENTS.md`。

## 0. 背景与分工

- **现状**：主索引 `1_Data/Dataset_inf.csv` 现有 **49 研究 / 102 行**，其中 47 个研究已完成入库（五件套齐全）；仍有 **4 个条目等待原始数据/说明文件**（见 §2：Pan_2025_unpub、Sun_2026_DataExp 已入库但有缺口；Hu_YQ_2026_ChinaSciData、Scheller_2026_elife 为 deferred 未入库）。
- **分工**：合作者**只负责提供原始材料**（原始数据导出 + 论文全文 + 人口学/说明文件）；识别实验/被试结构、写清洗脚本、生成五件套、登记 CSV、两级校验、Table 1 渲染、四方核对等全部由 **agent** 完成。
- **如何调用 agent**：在仓库根目录启动支持 `AGENTS.md` 约定的 AI 编程 agent（本项目用 opencode），把 §2 / §3 的指令模板发给它即可。数据整理/入库类任务 agent 会自动加载 `spe-database-curation` 技能，无需手动指定。
- **联系维护者**：GitHub 用户名 **hcp4715**（仓库维护者）；涉及 REF/ 全文与版本同步、数据疑问、清理文件等，直接联系他。

## 1. 放数据的通用规则（先读这一节）

| 规则 | 说明 |
|---|---|
| **放哪里** | 一律放入该研究文件夹下的**输入区**：`1_Data/<Study>/<Study>_Raw/`（个别历史研究为 `_raw` 变体；§2 表格给出每个研究的精确路径）。输入区被 git 忽略（不上传 GitHub）、只读、无需提交；agent 不会改动输入区里的原始文件 |
| **放什么** | 尽量放**原始导出文件**：逐被试/逐会话文件（E-Prime `.edat2`/`.txt`、PsychoPy `.psydat`/`.csv`、MATLAB `.mat`、在线平台导出等），**保留作者原始命名与目录结构**，不要预先重命名、转格式、合并、删减或"整理" |
| **说明文件一并放** | 被试人口学表、问卷、实验程序说明、README、数据字典等（xlsx/csv/pdf 均可）与数据放同一输入区——它们常常正是库内缺口（如 Pan） |
| **只有聚合数据？** | 若只有汇总表（如 xlsx），也放进去并在给 agent 的指令中注明来源；agent 会判断能否使用 |
| **放好之后** | 不需要做任何清洗，把 §2 的指令模板发给 agent 即可 |

## 2. 待数据研究：补齐入库（4 个）

| 研究 | 现状缺口 | 数据放到哪里 | 放好后发给 agent 的指令（可复制） |
|---|---|---|---|
| **Pan_2025_unpub**（未发表手稿，Pan Wanke） | trial 数据已在库（40 被试 / 28,037 行）；缺**人口学与说明性文件**：subj_info 的 Gender/Handedness/Ethnicity/Country/First_Language 等全为 `/`（Age 由出生年推导），paper/exp JSON 方法字段缺，License 未声明 | `1_Data/Pan_2025_unpub/Pan_2025_unpub_Exp1_Raw/`（输入区已存在，直接放入新文件） | 「请补齐 Pan_2025_unpub 的缺口：人口学与说明文件已放入 `1_Data/Pan_2025_unpub/Pan_2025_unpub_Exp1_Raw/`，请加载 spe-database-curation 技能，补填 subj_info/JSON/CSV 相应字段，并跑两级校验（validate_json_metadata.R + validate_clean_csv.R）。」 |
| **Sun_2026_DataExp**（数据论文） | 无原始 trial 导出：库内只有 62 MB Clean + subj_info，无 `*_raw.csv` | 新建 `1_Data/Sun_2026_DataExp/Sun_2026_DataExp_Raw/` 放入原始导出 | 「Sun_2026_DataExp 原始数据已放入 `1_Data/Sun_2026_DataExp/Sun_2026_DataExp_Raw/`，请生成 `*_raw.csv`，与 Clean 做逐值核对，并跑两级校验后汇报。」 |
| **Hu_YQ_2026_ChinaSciData**（中国科学数据 数据论文；原 Hu_2023_SDB；整研究未入库，CSV 行已预留） | 无任何数据/文件夹 | 新建 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/` 放入从数据论文仓库下载的原始数据；数据论文全文放 `REF/`（第 3 步；版本同步找 hcp4715） | 「请将 Hu_YQ_2026_ChinaSciData 入库：原始数据已放入 `1_Data/Hu_YQ_2026_ChinaSciData/Hu_YQ_2026_ChinaSciData_Raw/`，全文在 `REF/`。CSV 行已预留，请走完整入库流程（五件套 → CSV 收口 → 两级校验 → Table 1 重渲染）并做四方核对。」 |
| **Scheller_2026_elife**（eLife；DOI 10.7554/eLife.100932） | OSF 只有 TOJ 任务 trial 数据；**shape-label 匹配任务**的逐被试 trial 数据从未上传（论文分析所用 Raw Data/*.csv）。CSV 行已移除、输入区保留 | `1_Data/Scheller_2026_elife/Scheller_2026_elife_raw/`（已存在，内含 OSF 的 "Data and Analysis Scripts"；匹配数据建议放单独子文件夹如 `Matching_task_data/`，勿动已有 TOJ 内容） | 「Scheller_2026_elife 匹配任务数据已放入 `1_Data/Scheller_2026_elife/Scheller_2026_elife_raw/`，请重入本条目：先在 Dataset_inf.csv 登记两行（移除 known_unlisted 豁免），再走入库流程 + 四方核对 + 两级校验 + Table 1 重渲染。」 |

## 3. 未来新研究入库（4 步，其余交给 agent）

**第 1 步 · 新建研究文件夹**：在 `1_Data/` 下新建 `<Author>_<Year>_<Suffix>/`（Suffix = 期刊缩写 / psyarxiv / unpub，示例：`Zhang_2026_JNeurosci`）。命名规范见 AGENTS.md；拿不准就先按 `作者_年份` 建，agent 入库时会按规范收口校正。

**第 2 步 · 论文全文放 REF/**：将论文全文（出版社 PDF，或 HTML）存为 `REF/<Folder_Name>.pdf`（或 `.html`）。

> ⚠️ **REF/ 不上传 GitHub**：整个 `REF/` 目录被 `.gitignore` 忽略，全文文件与版本**不随仓库同步**。因此：
> - 需要库内已有全文、历史版本，或需要按 html→md 管线转换（见 `REF/README_html2md.md`）时，请**联系 hcp4715（GitHub 用户名）**获取/同步；
> - 合作者新增的全文也请**同步一份给 hcp4715**，保证 REF 版本一致；
> - 若暂无全文，agent 会先按 OA 渠道自动查找并落盘 REF/，找不到再向你要。

**第 3 步 · 原始数据放输入区**：按 §1 通用规则，放入 `1_Data/<Study>/<Study>_Raw/`（含人口学/说明文件）。

**第 4 步 · 调用 agent**，发送指令：

> 「请将 `<Author_Year_Suffix>` 入库：原始数据在 `1_Data/<Study>/<Study>_Raw/`，论文全文在 `REF/<Folder_Name>.pdf`。」

agent 将自动执行：扫描输入区识别实验/被试/会话 → 生成独立清洗脚本 `<Study>_clean.R` → 产出五件套（`*_raw.csv` / `*_ExpN_Clean.csv` / `*_subj_info.csv` / `Codebook_*_Clean.xlsx` / paper + 实验 JSON）→ `Dataset_inf.csv` 登记新行 → 两级校验（结构级 `validate_json_metadata.R` EXIT=0；内容级 `validate_clean_csv.R` 0 ERROR）→ `Generate_Table1.qmd` 重渲染 → **四方核对**（论文-代码-数据-原始数据 + 描述性统计）。

**完成标准**（可直接让 agent 汇报确认）：五件套齐全、命名合规、两级校验通过、CSV 行已登记、Table 1 渲染 EXIT=0。

## 4. 红线与提醒

- 输入区（`*_Raw/`、`*_raw/`）只读且被 git 忽略：不需要也不应该提交；agent 不会修改输入区里的原始文件。
- **不要覆盖或删除库内已有文件**（含 REF/ 与各研究文件夹）；如需清理，先与 hcp4715 确认（历史上曾发生过不可恢复的误删）。
- 主索引 = `1_Data/Dataset_inf.csv`（UTF-8 带 BOM；`Dataset_inf.xlsx` 为旧版，待合作者确认后删除）——由 agent 维护，合作者无需直接编辑。
- 数据放好后，整个整理入库由 agent 完成；完成后请 agent 汇报校验结果，有任何疑问联系 hcp4715。
- 细则正文归属：入库 10 步流程与命名/JSON/Codebook 规范 → `SKILL.md`；项目状态与未解决问题清单 → `PROJ_STATE.md`；agent 仓库纪律与教训 → `AGENTS.md`。
