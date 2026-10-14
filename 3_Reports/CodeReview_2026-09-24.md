# 绘图代码审查报告（v2 修复版，2026-09-24）

> 日期：2026-09-24（历史报告；2026-10-14 精简，见「状态」节）　|　范围：`3_Reports/1_Identity_Analysis`、`2_Mismatch_Analysis`、`3_Exploratory_Analysis` 三段分析代码
> 数据基线（审计时点 2026-09-24；当前计数以 `PROJ_STATE` §5 为准）：`1_Data/` 49 个研究文件夹、89 个 `*_Clean.csv`、`Dataset_inf.csv` 108 行（107 行有数据文件夹）
> 可复现产物：`_v2` 代码与图（见 §4）、`Generate_Table1_v2.R`、`Output/Table1_v2.csv`

---

## 状态（2026-10-14）

原 §1 摘要、§2 代码审查发现（B1–B6）、§5 稿件文字改动清单、§6 Table 1 差异、§7 参考文献审计、§8 稿件 docx 复核**已删除**——各条目均已解决，或属旧稿件相关（稿件已更新，不再作为比对基线，见 `PROJ_STATE` §4 决策 17）不再维护；删前全文见 git 历史，归档登记见 `PROJ_STATE` §7。

- **B1–B5 已修复并重跑**：B1 被试编号仅在数据集内唯一（跨研究串号）→ 按「数据集×被试」重编号后分组；B2 失配分析 `Source` 退化为 `Exp1`/`Exp2` → 改用文件全名；B3 缺 RT 合理性过滤且 ACC 取值未限定 → RT 限定 `0 < RT_ms ≤ 10000`、ACC 限 `{0, 1}`；B4 `Generate_Table1.qmd` 因 `Paper_ID` 列移除而失效 → 新增 `Generate_Table1_v2.R`；B5 探索性分析读 2026-09-01 旧快照 → 增量重跑至 `Output/11`。修复产物即 §4 所列 `_v2` 代码/图，**§3 的数字为修复后结果**。
- **B6 为误报，已关闭**：`Constable_2019_JEPHPP` 文件夹名**正确**——该文发表于 *Journal of Experimental Psychology: Human Perception and Performance*（45, 1549–1561, doi `10.1037/xhp0000691`）；原报告将其误记为 *Memory & Cognition*。库内 ID 无需改动，**勿据原报告改名**。

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
