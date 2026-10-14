# 一致性核查：稿件 Table 1 vs Dataset_inf.csv vs 1_Data/ 文件夹

**日期**: 2026-08-10
**范围**: 比较三个来源中研究（study）与实验（experiment）的数量及标识符。
**核查方式**: 对 Table 1（docx）、`Dataset_inf.csv` 与 `1_Data/` 目录列表进行自动化比对。

> **状态（2026-10-14 复核）**: 本文为 **2026-08-10 快照**；`待处理问题` 8 项经按当前数据逐项核验后**已全部解决/消解**（见该节），不再保留开放条目。下文表格中的文件夹名、行数与 `Paper_ID` 口径均为当时状态，现由 `1_Data/Dataset_inf.csv` + `3_Reports/Output/Table1_v2.csv` 取代，仅作历史记录。

## 比较的数据来源

| # | 来源 | 路径 | 行数 |
|---|---|---|---|
| 1 | **Table 1**（稿件） | `3_Reports/SPE_database_manu_v16.docx` | 70 条数据集记录 |
| 2 | **Dataset_inf.csv**（总目录清单） | `1_Data/Dataset_inf.csv` | 73 条数据记录 |
| 3 | **1_Data/ 文件夹**（已整理的研究文件夹） | `1_Data/` | 34 个研究文件夹 |

## 汇总数量

| 指标 | Table 1（docx） | Dataset_inf.csv | 1_Data/ 文件夹 |
|---|---|---|---|
| 研究（论文）数量 | 38 个标签 → **34 个唯一文件夹**（其中 4 个为标签别名） | **43** 个 `Folder_Name` 条目（34 个存在 + 9 个缺失） | **34** 个文件夹 |
| 实验（数据集）数量 | **70** 行（70 个唯一 Paper_ID） | **73** 行（73 个唯一 Paper_ID） | 43 个 `*_Exp*.json` 文件；**59** 个 `*_Clean.csv` 文件 |
| 已知待收录研究（已记录在案） | — | 1（`Wozniak_2020_PLOS`） | — |

注意：README 声称"44 篇论文 / 70 个数据集 / 3603 名被试"——其中"44 篇论文"这一数字与任何单一来源均不吻合（唯一文件夹为 34 个 / CSV 条目为 43 个 / Table 1 标签为 38 个）。

## 各文件夹实验数量明细

| 文件夹 | CSV 行数 | Exp JSON 数 | Clean CSV 数 | 是否一致 |
|---|---|---|---|---|
| Amodeo_2024_CABN | 1 | 1 | 1 | ✅ |
| Constable_2019_EPHPP | 4 | 4 | 4 | ✅ |
| Constable_2020_AP | 1 | 1 | 1 | ✅ |
| Constable_2020_CE | 2 | 2 | 2 | ✅ |
| Dalmaso_2024_CC | 2 | 2 | 2 | ✅ |
| Feldborg_2021_ERPH | 1 | 1 | 1 | ✅ |
| Haciahmet_2023_Psy | 1 | 1 | 1 | ✅ |
| Hu_2020_CP | 1 | 1 | 1 | ✅ |
| Hu_2023 | 1 | 1 | 1 | ✅ |
| Kirk_2025_BJP | 2 | 0 ⚠️ | 2 | ❌ 缺少实验 JSON |
| Kolvoort_2020_HBM | 1 | 1 | 1 | ✅ |
| Lee_2023_Cognition | 2 | 0 ⚠️ | 2 | ❌ 缺少实验 JSON |
| Liang_2022_HBM | 3 | 1 | **4** | ❌ **CSV/JSON 数量不足** |
| Liu_2023_CP | 1 | 1 | 1 | ✅ |
| Martinez-Perez_2024_CC | 1 | 1 | 1 | ✅ |
| Navon_2021 | 4 | 4 | 4 | ✅ |
| Orellana-Corrales_2021_APP | 2 | 0 ⚠️ | 2 | ❌ 缺少实验 JSON |
| Pan_2025 | 1 | 0 ⚠️ | 1 | ❌ 缺少实验 JSON |
| Perrykkad_2022_BMC | 1 | 1 | 1 | ✅ |
| Qian_2020_QJEP | 2 | 2 | 2 | ✅ |
| Schaefer_2019_CP | 3 | 3 | 3 | ✅ |
| Smith_2024_Cortex | 1 | 0 ⚠️ | 1 | ❌ 缺少实验 JSON |
| Sui_2014 | 1 | 0 ⚠️ | 1 | ❌ 缺少实验 JSON |
| Sui_2014_APP | 4 | 4 | 4 | ✅ |
| Sui_2015 | 2 | 0 ⚠️ | 2 | ❌ 缺少实验 JSON |
| Sui_2023_CC | 1 | 1 | 1 | ✅ |
| Sun_2025 | 1 | 0 ⚠️ | 1 | ❌ 缺少实验 JSON |
| Svensson_2023_QJEP | 1 | 0 ⚠️ | 1 | ❌ 缺少实验 JSON |
| Vicovaro_2022_EPHPP | 2 | 2 | 2 | ✅ |
| Wang_2016_EPHPP | 1 | 1 | 1 | ✅ |
| Wozniak_2018_PLOS | 2 | 2 | 2 | ✅ |
| Wozniak_2022_PR | 3 | 3 | 3 | ✅ |
| Xu_2021_CP | 1 | 1 | 1 | ✅ |
| Zhang_2023_NI | 1 | 1 | 1 | ✅ |
| **合计（34 个文件夹）** | **58** | **43** | **59** | |

（另有 9 个 CSV `Folder_Name` 条目完全没有对应文件夹——见问题 1。上表合计仅覆盖已存在的文件夹。）

---

## 待处理问题（Open Issues）

**2026-10-14 复核：原 8 项已全部解决/消解，逐项移出**（按当前数据核验，非依原标记）：
① 9 个「缺文件夹」条目已全部落位（多为改名：`Bukowski_2021_AP`→`Bukowski_2021_ActaPsych`、`Golubickis_2021_AP`→`Golubickis_2021_ActaPsych`、`Hobbs_2023_PM`→`Hobbs_2023_PsychMed`、`Hu_2023_SDB`→`Hu_YQ_2026_ChinaSciData`、`Mcivor_2020_EJN`→`Mcivor_2021_EJN`、`Orellana-Corrales_2021_EP`→`Orellana-Corrales_2020_ExpPsych`/`_2021_APP`/`_2023_QJEP`、`Svensson_2021_PR`→`Svensson_2022_PsychRes`/`_2023_QJEP`、`Scheller_2024_elife`→`Scheller_2026_elife`〔deferred〕；`Wozniak_2020_PLOS` 亦已收录）；
② `Paper_ID` 键已废弃（主索引现为 `Folder_Name_Exp<N>_<subj_Group>` 复合键，`ID` 列）；
③⑤ 系稿件 Table 1 的复制粘贴/归属错误（稿件 v16 已废弃；可解性登记见 `Table1_Issues_Solvability.md`）；
④ 空 `Exp` 值已全部回填（现 114 行、0 空值）；
⑥ 复核确认**并非错误**（标签粒度问题），已关闭；
⑦ `Liang_2022_HumBrainMap` 冗余 `Exp1_Clean.csv` 已删、Exp JSON 已补（现 1 Clean + 1 Exp JSON + 3 行按 `subj_Group` 拆组）；
⑧ 9 个文件夹的实验 JSON 已全部补齐（全库 93 份 exp JSON，结构级校验 EXIT=0）。

---

## 方法说明
- 使用 Paper_ID 作为 Table 1（`ID` 列）与 Dataset_inf.csv（`Paper_ID` 列）之间的关联键。
- 文件夹→实验数量通过 `*_Exp*.json` 和 `*_Clean.csv` 文件列表统计（已排除 AppleDouble `._*` 文件）。
- Exp 归一化：比较前去除 "Exp" 前缀。
