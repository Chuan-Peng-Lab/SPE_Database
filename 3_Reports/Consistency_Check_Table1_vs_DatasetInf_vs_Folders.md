# 一致性核查：稿件 Table 1 vs Dataset_inf.csv vs 1_Data/ 文件夹

**日期**: 2026-08-10
**范围**: 比较三个来源中研究（study）与实验（experiment）的数量及标识符。
**核查方式**: 对 Table 1（docx）、`Dataset_inf.csv` 与 `1_Data/` 目录列表进行自动化比对。

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

### 问题 1 — CSV 中列出的 9 个研究在 `1_Data/` 中没有对应文件夹
- **来源**: Dataset_inf.csv
- **涉及**: `Bukowski_2021_AP`、`Golubickis_2021_AP`、`Hobbs_2023_PM`、`Hu_2023_SDB`、`Mcivor_2020_EJN`、`Orellana-Corrales_2021_EP`、`Scheller_2024_elife`、`Svensson_2021_PR`、`Wozniak_2020_PLOS`
- **状态**: `Wozniak_2020_PLOS` 在 AGENTS.md 中已记录为"待收录"（数据尚未整理）。其余 8 个**未记录在案**——要么是待整理，要么是 CSV 中的过期条目。
- **建议处理**: 对这 8 个条目逐一处理：(a) 整理数据文件夹；(b) 加入已记录在案的待收录列表；(c) 若已过时则从 CSV 中删除。校验脚本（`validate_json_metadata.R`）已能标记这些问题。

### 问题 2 — 3 个 CSV Paper_ID 在 Table 1 中缺失
- **来源**: Table 1 ↔ Dataset_inf.csv
- **涉及**: `Pt5E1`（Hu_2023_SDB）、`Pu7E1`（Wozniak_2020_PLOS）、空 Paper_ID（Scheller_2024_elife）
- **状态**: Table 1 中的 70 个 ID 均存在于 CSV；这 3 个是 CSV 独有。`Scheller_2024_elife` 行存在**空 Paper_ID**。
- **建议处理**: 如果这些数据集需要报告，则在 Table 1 中补充相应行；否则在稿件中标记为排除/待收录。

### 问题 3 — Table 1 中 Exp 列存在复制粘贴错误
- **来源**: Table 1（docx）
- **涉及**: `P5E1`–`P5E4` **全部被标记为"Exp4"**；而 CSV 与文件夹子目录（`Constable_2019_EPHPP/Exp1..Exp4`）显示为 Exp1–Exp4。另有 `P46E1`（Table 1 为"Exp2"，CSV 为"1"）和 `P46E2`（Table 1 为"Exp4"，CSV 为"2"）。
- **状态**: 已确认为 Table 1 的向下填充/复制粘贴错误。
- **建议处理**: 更正 Table 1 中的 Exp 值：`P5E1`→Exp1、`P5E2`→Exp2、`P5E3`→Exp3、`P5E4`→Exp4；并根据文件夹结构核对 `P46E1`/`P46E2`。

### 问题 4 — Dataset_inf.csv 中存在空的 Exp 值
- **来源**: Dataset_inf.csv
- **涉及**: 8 行：`P54E2`、`P54E3`、`Pu5E1`、`Pu5E2`、`Pu6E1`、`Pu9E1`、`Pu9E2`、`Pu10E1`（另有问题 2 中的 3 个 CSV 独有 ID）
- **状态**: Exp 列为空；Table 1 中这些记录均有对应值（Exp1–Exp3）。
- **建议处理**: 根据 Table 1 / 文件夹文件名回填 Exp 值。

### 问题 5 — Table 1 中研究标签的归属错误
- **来源**: Table 1（docx）
- **涉及**:
  - `P46E2`: 标记为"Constable et al. (2019)"，但 CSV 中年份为 2020，文件夹为 `Constable_2020_CE` → 应归属 2020 年 CE 论文
  - `Pu2E1`: 标记为"Martínez-Pérez et al. (2024)"，但 CSV `FirstAuthor` 为"Mario Dalmaso et al."，文件夹为 `Dalmaso_2024_CC` → 标记错误
  - `Pt9E1`: 标记为"Woźniak et al. (2020)"，但 CSV 文件夹为 `Wozniak_2022_PR`（与 `Pt9E2`/`Pt9E3` 相同）
  - `P95E2`: 标记为"Wozniak_2018_PLOS"（文件夹命名风格），而 `P95E1` 为"Woźniak et al. (2018)"——同一论文但风格不一致
- **状态**: 已确认存在归属错误/标签风格不一致。
- **建议处理**: 更正 Table 1 中的研究标签，使其与 CSV `Folder_Name` / `FirstAuthor` 一致。

### 问题 6 — Table 1 中部分研究标签横跨多个文件夹（粒度问题）
- **来源**: Table 1 ↔ 文件夹
- **涉及**: 6 个标签对应多个文件夹：Constable et al. (2019) → `Constable_2019_EPHPP` + `Constable_2020_CE`；Constable et al. (2020) → `Constable_2020_AP` + `Constable_2020_CE`；Orellana-Corrales et al. (2020) → `Orellana-Corrales_2021_APP` + `_EP`；Martínez-Pérez et al. (2024) → `Martinez-Perez_2024_CC` + `Dalmaso_2024_CC`；Sui et al. (2014) → 3 个文件夹；Svensson et al. (2022) → `Svensson_2021_PR` + `Svensson_2023_QJEP`。
- **状态**: 并非错误——CSV 与文件夹一致；影响的是如何从 Table 1 推导"研究数量"。
- **建议处理**: 考虑按文件夹（`Paper` 列）对 Table 1 行分组以统计数量，或增加论文↔文件夹的明确映射。

### 问题 7 — Liang_2022_HBM：文件夹中的实验多于 CSV/Table 1 记录
- **来源**: 三个来源均涉及
- **涉及**: `Liang_2022_HBM` 文件夹包含 4 个 Clean CSV（`Exp1`、`Exp1.1`、`Exp1.2`、`Exp1.3`），但 CSV 仅列出 3 行（全部为"Exp 1"），且只有 1 个 Exp JSON 存在。
- **状态**: 存在数据遗漏风险——磁盘上有实验数据但未登记入目录。
- **建议处理**: 在 CSV 中补充 `Exp1.1`/`Exp1.2`/`Exp1.3` 行（若需报告也加入 Table 1），并创建缺失的 Exp JSON。

### 问题 8 — 多个文件夹缺少实验 JSON 元数据
- **来源**: 文件夹
- **涉及**: `Kirk_2025_BJP`（2 个实验，0 个 JSON）、`Lee_2023_Cognition`（2，0）、`Orellana-Corrales_2021_APP`（2，0）、`Pan_2025`（1，0）、`Smith_2024_Cortex`（1，0）、`Sui_2014`（1，0）、`Sui_2015`（2，0）、`Sun_2025`（1，0）、`Svensson_2023_QJEP`（1，0）——实验数据以 Clean CSV 形式存在，但没有对应的 `<Study>_Exp<N>.json` 元数据。
- **状态**: 元数据完整性缺口；JSON 校验脚本对缺失的实验 JSON 不会报错（仅对格式错误的文件报错）。
- **建议处理**: 为这些文件夹生成 `_Exp<N>.json`（v2 模式）。

---

## 方法说明
- 使用 Paper_ID 作为 Table 1（`ID` 列）与 Dataset_inf.csv（`Paper_ID` 列）之间的关联键。
- 文件夹→实验数量通过 `*_Exp*.json` 和 `*_Clean.csv` 文件列表统计（已排除 AppleDouble `._*` 文件）。
- Exp 归一化：比较前去除 "Exp" 前缀。
