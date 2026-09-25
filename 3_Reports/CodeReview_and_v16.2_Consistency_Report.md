# 绘图代码审查 + 稿件 v16.2 一致性报告

> 日期：2026-09-24　|　范围：`3_Reports/1_Identity_Analysis`、`2_Mismatch_Analysis`、`3_Exploratory_Analysis` 三段分析代码 + 稿件 `SPE_数据库_v16.1.docx` → `v16.2.docx`
> 数据基线：`1_Data/` 49 个研究文件夹、89 个 `*_Clean.csv`、`Dataset_inf.csv` 108 行（107 行有数据文件夹）
> 可复现产物：`_v2` 代码与图（见 §4）、`Generate_Table1_v2.R`、`Output/Table1_v2.csv`、`_v162_work/`（全部审计脚本与中间产物）

---

## 1. 结论摘要

1. 三段绘图/分析代码**存在 3 个会改变结论的实现错误**（§2 的 B1/B2/B3），已全部在 `_v2` 版本中修复并重跑。
2. 稿件 v16.1 正文中**三个示例的全部统计数字**都与当前数据/代码不符，已按 `_v2` 结果整体改写（§5）。
3. `Generate_Table1.qmd` **当前无法运行**（依赖已删除的 `Paper_ID` 列），Table 1 已由新的 `Generate_Table1_v2.R` 从主索引重生成：94 行 → **107 行**，并修正 41 处单元格差异（§6）。
4. 参考文献中有 **1 篇被引但缺失**、**1 条作者张冠李戴**、**1 条重复**、3 条缺期刊/页码；已按 Crossref 逐条核验修正（§7）。
5. 交付：`Datasets/4_Writing/SPE_数据库_v16.2.docx`（Word 可正常打开，导出 PDF 45 页）。

---

## 2. 代码审查发现（按严重度）

### B1【严重】被试编号只在数据集内唯一，跨研究串号

89 个 Clean 文件中 `Subject` 只有 **1,441 个不同取值**，却有 **4,521 个「数据集×被试」组合**。
三段代码都直接按 `Subject` 分组：

- `Figure3_Ridges_Pairwise_*.Rmd`：`data[data$Subject == subj, ]` 与 `lmer(... + (1 | Subject) + ...)`
- `Figure_Bootstrap_Mismatch_*.Rmd`：`df[df$Subject == subj, ]`
- 后果：编号为 5 的被试在不同研究里被**合并成同一个「被试」**，其 Self 试次可能来自研究 A、Stranger 试次来自研究 B，算出的 Cohen's d 无意义；`(1|Subject)` 随机效应也把不相关的人合并。

**影响量化**（身份分析，`_v162_work/diag_identity_variants.R`）：

| 口径 | 有效被试数 | NonPerson | Stranger | Celebrity | Acquaintance | Close |
|---|---|---|---|---|---|---|
| 修复前（v1 代码原样） | 1,366 | **0.283** | 0.180 | **−0.195** | −0.163 | 0.088 |
| 修复后（v2） | 4,321 | 0.251 | 0.234 | **+0.240** | 0.167 | 0.163 |

修复后五个基线**全部为正**（符合 SPE 预期），修复前 Celebrity/Acquaintance 为负。

### B2【中】失配分析的 `Source` 标识退化为 `Exp1`/`Exp2`

`Figure_Bootstrap_Mismatch_v1.Rmd` 用 `basename(dirname(f))`：多实验研究的 Clean 文件位于 `<Study>/Exp1/` 下，于是 `Source` 变成 `"Exp1"`，不同研究的 Exp1 混为一谈（身份分析那份用的是文件全名，是对的）。虽然该变量在下游未被直接使用，但一旦用于分组即为错误。
**修复**：统一为 `tools::file_path_sans_ext(basename(f))`。

### B3【中】缺少 RT 合理性过滤 + ACC 取值未限定

- `Perrykkad_2022_BMCPsych_Exp1_Clean.csv` 有 **72 个 RT = 4,294,967,295 ms**（2³²−1 哨兵值），最大值 `Liu_2023_CogRes` 3.76×10⁶ ms，另有负值（Vicovaro −16、−14）。
- ACC 分析直接取原始 ACC，会把 `-2`（范围外按键）以及 `Sui_2015_unpub_Exp1` 中的 `3/4` 当成准确率参与 Cohen's d。
**修复**：RT 限定 `0 < RT_ms ≤ 10000`，ACC 仅保留 `{0, 1}`（均在 Methods 中写明）。
量化影响：身份分析 RT 的 d 变化 < 0.005（B1 才是主导因素），但去掉哨兵值对稳健性是必要的。

### B4【中】`Generate_Table1.qmd` 已无法运行

第 44 行 `stopifnot("Paper_ID" %in% names(inf))`：`Paper_ID` 列已从 `Dataset_inf.csv` 移除（现 37 列，主键为 `ID = Folder_Name_ExpN_subj_Group`），脚本必然中断。
**修复**：新增 `Generate_Table1_v2.R`（不依赖 quarto/pandoc），输出 `Output/Table1_v2.csv`。

### B5【中】探索性分析的数据源是 2026-09-01 的快照

`Figure_Exploratory_Moderators_v1.Rmd` 读 `Datasets/8_Exploratory_Analysis/Output/10`（2026-09-01 生成，55 个数据集），**不含 Lee_2026_BritJPsy 与 Zhao_2026_PsychonBullRev**。
**修复**：新增 `exploratory_workflow_v11.py` / `exploratory_visualization_workflow_v11.py`（**增量**，写入 `Output/11`、`Pic/11`，不覆盖旧产物），在全部 89 个 Clean 文件上重跑。

### B6【轻，未改】`Constable_2019_JEPHPP` 文件夹名期刊缩写有误

Crossref 显示该文发表于 **Memory & Cognition**（47, 1145–1157, doi:10.3758/s13421-019-00924-6），稿件参考文献也是这么写的；但库内关键 ID 用了 `JEPHPP`。因改 ID 会牵动全库引用，**留待你决定**，本次未动。

---

## 3. v2 结果（正文数字的唯一来源）

### 3.1 例 1：基线身份（`p_ridges_pairwise_combined_11_v2.png`）

修复 B1/B3 后重跑；RT 基于 4,321 名被试 × 身份的 6,708 个效应量，ACC 基于 4,307 名的 6,660 个。
数据集覆盖：NonPerson 8、Stranger 70、Celebrity 3、Acquaintance 2、Close 50。

| | NonPerson | Stranger | Celebrity | Acquaintance | Close |
|---|---|---|---|---|---|
| RT d [95% CI] | .251 [.203, .300] | .234 [.200, .269] | .241 [.176, .306] | .167 [.081, .253] | .163 [.128, .198] |
| ACC d [95% CI] | .207 [.176, .240] | .136 [.114, .159] | .153 [.111, .195] | .130 [.074, .187] | .085 [.062, .108] |

10 组成对比较：RT **3/10 显著**（NonPerson / Celebrity / Stranger 均 > Close，p < .01）；ACC **6/10 显著**（NonPerson > {Close, Acquaintance, Stranger, Celebrity}，Celebrity > Close，Stranger > Close）。
**结论变化**：旧稿「三档梯度、Celebrity 最强、8/10 显著」不成立；现在是「五个基线全为正，仅最强 vs 最弱可比」。

### 3.2 例 2：失配条件 bootstrap（`combined_figures_v6_v2.png`）

失配试次 1,068,081，89 个数据集，4,520 名被试。保守法：shape 38 个数据集 / 371,894 试次，label 27 个 / 276,010 试次。

| 方法 | 指标 | 维度 | N max | Cohen's d | 95% CI | CI 首次排除 0 的 N |
|---|---|---|---|---|---|---|
| 保守 | RT | Shape | 1,563 | 0.123 | [0.103, 0.144] | 40 |
| 保守 | RT | Label | 1,563 | 0.252 | [0.227, 0.275] | 20 |
| 保守 | ACC | Shape | 1,494 | 0.052 | [0.035, 0.070] | 170 |
| 保守 | ACC | Label | 1,494 | 0.049 | [0.030, 0.069] | 210 |
| 自由 | RT | Shape | 3,604 | 0.005 | [−0.008, 0.017] | 未达到 |
| 自由 | RT | Label | 3,192 | 0.125 | [0.112, 0.138] | 40 |
| 自由 | ACC | Shape | 3,524 | 0.009 | [−0.002, 0.020] | 未达到 |
| 自由 | ACC | Label | 3,114 | 0.009 | [−0.003, 0.021] | 未达到 |

**结论变化**：方向与旧稿一致（保守法下 label-RT 最强、自由法下只剩 label-RT），但数值全部更新；旧稿自由法下 shape-RT 显著（d = 0.023）现已不显著。

### 3.3 例 3：实施参数（`Figure_Exploratory_Moderators_Main_v2.png`，基于 `Output/11`）

| 面板 | n | Spearman ρ | p | bootstrap 95% CI | p_boot |
|---|---|---|---|---|---|
| A 时长·RT | 54 | −.311 | .022 | [−.539, −.052] | .018 |
| B 时长·ACC | 54 | −.335 | .013 | [−.548, −.095] | .010 |
| C 试次数·RT | 64 | .045 | .727 | [−.222, .302] | .748 |
| D 试次数·ACC | 65 | .174 | .165 | [−.098, .433] | .205 |

敏感性分析（剔除最大 3 个试次数的数据集）：RT ρ = .077, p = .560；ACC ρ = .195, p = .132。
**结论变化**：**时长 → SPE 的负相关保留**（区间全在 0 以下）；**试次数 → SPE 无可靠关联**，旧稿的正相关结论已删除。这与 `Datasets/8_Exploratory_Analysis/Exploratory_Effect_Size_Change_Audit.md` 的记载一致（该文件已判定旧结果建立在 n=40–44 的小样本 + 部分错误数据上）。

---

## 4. 交付产物

### 代码（`_v2`）
| 文件 | 说明 |
|---|---|
| `3_Reports/1_Identity_Analysis/Figure3_Ridges_Pairwise_v2.Rmd` (+`.R`) | 修复 B1/B3 |
| `3_Reports/2_Mismatch_Analysis/Figure_Bootstrap_Mismatch_v2.Rmd` (+`.R`) | 修复 B1/B2/B3 |
| `3_Reports/3_Exploratory_Analysis/Figure_Exploratory_Moderators_v2.Rmd` (+`.R`) | 改读 `Output/11` |
| `3_Reports/Generate_Table1_v2.R` | 修复 B4 |
| `Datasets/8_Exploratory_Analysis/exploratory_workflow_v11.py` | 上游增量重跑（→ `Output/11`） |
| `Datasets/8_Exploratory_Analysis/exploratory_visualization_workflow_v11.py` | 下游增量重跑（→ `Output/11`、`Pic/11`） |

### 图（`_v2`）
- `3_Reports/Output/Pic/p_ridges_pairwise_combined_11_v2.png`
- `3_Reports/Output/Pic/combined_figures_v6_v2.png`
- `3_Reports/Output/Pic/Figure_Exploratory_Moderators_Main_v2.png` + 4 张单面板 `*_v2.png`

### 数据/汇总
- `3_Reports/Output/Table1_v2.csv`（107 行）、`Table1_v2_summary_stats.csv`
- `3_Reports/Output/data/identity_baseline_summary_v2.csv`
- `3_Reports/Output/data/mismatch_bootstrap_summary_v2.csv`
- `3_Reports/Output/data/exploratory_figure_captions_v2.csv`、`exploratory_sensitivity_v2.csv`
- `3_Reports/Output/data/*_v2.csv`（ridge / pairwise / bootstrap 中间数据）

### 稿件
- `Datasets/4_Writing/SPE_数据库_v16.2.docx` —— **干净终稿**（无批注、无修订痕迹）
- `Datasets/4_Writing/SPE_数据库_v16.2_批注版_czx.docx` —— 终稿文字 + **32 条 czx 名下批注**（逐条说明改动与依据）
- `Datasets/4_Writing/SPE_数据库_v16.2_修订批注版_czx.docx` —— 同上，另把 v16.1→v16.2 的**全部改动显示为 czx 名下的修订痕迹**（764 处插入 / 464 处删除，可逐条接受或拒绝），51 页
- 预览：`3_Reports/_v162_work/v16.2_final.pdf`（干净版，45 页）

#### 批注版实现说明（技术限制）
- 批注与修订的作者统一为 **czx**（改写 OOXML 的 `w:author` / `w:initials`；Word 读回确认为 `{'czx': 32}`）。
- 批注锚点采用**段落级定位**（Word `Paragraphs(i).Range`）。先试过 `Content.Find` 与字符偏移两种方式，前者 31/37 正确、6 条文献类锚点被折叠，后者受 Zotero 域代码干扰全部错位。
- **参考文献部分无法逐条挂批注**：文献表是单个 Zotero 书目域，Word 会把域内的任何批注锚点折叠为整个域，故 6 条文献修正合并为 1 条批注，挂在 `Reference` 标题段上（见该批注第 1–6 条）。
- `批注版` 保留文档原有的 9 处修订及其原作者（蔡振辛 / Hu Chuan-Peng）不改动；`修订批注版` 因整篇由 Word 比较生成，全部修订统一记为 czx。

---

## 5. 稿件文字改动清单（v16.1 → v16.2）

| 位置 | 改动 |
|---|---|
| 摘要 | 44 studies / 70 experiments / 3,603 participants / 1.55 M trials → **49 studies / 89 datasets / 4,875 participants / 2.1 M trials**；末段"三个示例全部都只能靠大数据检出"改为与结果相符的表述 |
| 引言 | 同上规模数字 |
| 文件夹结构 | `Dataset_inf.csv` 行语义：由"每行 = 1 study，主键 `Paper_Id`"改为"每行 = 实验×被试组，主键 = `Folder_Name`+`Exp`+`subj_Group`（`ID` 列）" |
| 文件夹结构 | paper JSON 内容描述改为与实际 11 字段 schema 相符（原称含招募策略/纳入排除标准，实无） |
| 文件夹结构 | 五件套命名示例改为现行语法（`_subj_info.csv`、`Codebook_*_Clean.xlsx`） |
| 五组件 | `Ratchliff et al., 2016` → `Ratcliff et al., 2016` |
| 数据概览 | 规模数字按当前主索引重算并标注口径 |
| Table 1 注 | 重写（说明 N / Trials / Exp_Implement 口径） |
| 数据说明 | "five categories" → **six categories**（Self/Close/Acquaintance/Celebrity/Stranger/NonPerson） |
| 例 1 方法 | 补充 RT 窗口、ACC 取值、被试嵌套口径 |
| 例 1 结果 | 全部数字与结论重写（§3.1） |
| 例 2 方法 | 72 experiments/853,015 trials/1,676 participants → **89/1,068,081/4,520**；63 experiments/303,331/199,271 → **38 与 27 个数据集 / 371,894 / 276,010** |
| 例 2 结果 | 全部数字重写（§3.2）；表题由"Summary of Liberal Approach Results"改为"Bootstrap Estimates of the Self-Prioritization Effect Under Nonmatching Conditions" |
| 例 3 方法 | 补充排除规则；明确 Cohen's dz 以 Stranger 为基线 |
| 例 3 结果 | 时长区间 100–1,500 ms/n=40 → **100–3,000 ms/n=54**；试次数正相关结论**删除**（改为无可靠关联） |
| 讨论 | 三句总结改为与 §3 一致 |
| 图表编号 | 统一为 Figure 1–6 + Table 1–2；修正正文中 "Figure 3/3C/3D"、"Figure 4A–D"、"Figures 5A–5D"、"Figure 6C and 7D"、"table 3" 等错引 |

---

## 6. Table 1 差异（94 行 → 107 行）

**结构差异**（`_v162_work/table1_diff.txt`）：
- 新增：`Hu_2023_psyarxiv` Exp3a/3b/4a/6b（4 行）、`Lee_2026_BritJPsy` Exp1a/1b/2（3 行）、`Zhao_2026_PsychonBullRev` Exp1/2/3（4 行）
- 移除：`Hu_2023_psyarxiv` Exp1（已拆分为 4 个数据集）、`Sui_2015_unpub` Exp2（主索引无此条目）
- 行数变化：`Bukowski_2021_ActaPsych` Exp1 由 1 行 → 4 行（按被试组拆行）

**单元格差异 41 处**（按列：N 20、Trials 11、License 7、Stimulus 2、Language 1），其中值得注意的实质性修正：
- `Constable_2021_CogEmo` Exp1 刺激类型 `grey scale squares` → **face**（实验 JSON 明确为面部表情刺激）
- `Feldborg_2021_IJERPH` 两个被试组 N 48/54 → **53/49**（2026-09 按 Label 列重新分组）
- `Bukowski_2021_ActaPsych` Exp1 语言 English → **German**
- `Sui_2015_unpub`、`Sui_2014_unpub`、`Smith_2024_Cortex` 等的 Trials 口径由旧稿数值改为主索引 `numTrials`
- `License` 空缺由 `/` 统一为 `NA`

---

## 7. 参考文献审计（已按 Crossref 核验）

| 问题 | 处理 |
|---|---|
| **Bogacz et al. (2006) 正文引用但参考文献缺失** | 新增：Psychological Review, 113(4), 700–765, doi:10.1037/0033-295X.113.4.700 |
| **"Rose, H. (1991)" 作者张冠李戴** | 实为 Markus, H. R., & Kitayama, S. (1991), Psychological Review, 98(2), 224–253；正文 `(Rose, 1991)` 同步改为 `(Markus & Kitayama, 1991)` |
| Aron et al. (1992) 缺期刊、页码"1–17"错误 | 补为 JPSP, 63(4), 596–612 |
| Ghai (2024) 缺期刊页码、DOI 双前缀 | 补为 Nature Human Behaviour, 8(6), 1053–1056；作者补全为 Ghai, Forscher, & Hu；正文引用改 `Ghai et al., 2024` |
| Lin et al. (2023) 缺期刊页码 | 补为 Psychological Bulletin, 149(7–8), 487–505, doi:10.1037/bul0000399 |
| **Sun et al. (2023) 重复两条**（同一 DOI） | 合并为一条：`Sun, S., Wang, N., Wen, J., & Hu, C.-P. (2023). A dataset of cognitive ontology … China Scientific Data, 8(3), 175–189` |
| `Ratchliff et al., 2016` 拼写 | 正文改为 `Ratcliff et al., 2016` |

参考文献总数 39 → **39**（删 1 重复、加 1 缺失）。

**未处理、留待你决定**：`Sun et al. (2023)` 的页码 175–189 在 Crossref 无页码字段（无法独立验证，沿用原稿）；`Constable_2019_JEPHPP` 文件夹名（见 B6）。

---

## 8. 一致的复核结果

- 交付 docx 用 Word 实际打开：**无报错**，45 页；导出 PDF 成功。
- 表 1（107 行）与 `Output/Table1_v2.csv` 逐格一致；表 2 与 `mismatch_bootstrap_summary_v2.csv` 数值一致。
- 正文 6 处图题、2 处表题编号连续、无重复；正文所有跨引用（Figure 4A/4C/4D、5A–5D、6A–6D、Table 2）均指向存在对象。
- 旧数字全量扫描（visible text，含 Word 域/修订内容）：无残留（仅剩的两处 `0.126`/`0.061` 是新结果的置信区间端点）。

## 9. 如何复跑

```powershell
# 1) 探索性上游（可选，约 20–30 分钟；增量写入 Output/11，不覆盖旧产物）
cd Datasets\8_Exploratory_Analysis
python exploratory_workflow_v11.py
python exploratory_visualization_workflow_v11.py

# 2) 三段分析（purl 后 Rscript 运行，脚本自行定位 3_Reports/ 为工作目录）
cd ..\..\3_Reports
& "D:\R\R-4.4.3\bin\Rscript.exe" 1_Identity_Analysis\Figure3_Ridges_Pairwise_v2.R
& "D:\R\R-4.4.3\bin\Rscript.exe" 2_Mismatch_Analysis\Figure_Bootstrap_Mismatch_v2.R
& "D:\R\R-4.4.3\bin\Rscript.exe" 3_Exploratory_Analysis\Figure_Exploratory_Moderators_v2.R

# 3) Table 1
& "D:\R\R-4.4.3\bin\Rscript.exe" Generate_Table1_v2.R
```

> 注：`_v162_work/` 内含全部审计脚本（诊断、Table 1 差异、参考文献核验、docx 构建与验证）与中间产物，可复现本报告每一条结论。
