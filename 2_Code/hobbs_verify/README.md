# hobbs_verify — Hobbs_2023_PsychMed 入库四方核对脚本（2026-08-30）

Hobbs, Sui, Munafò, Kessler & Button (2023), Psychological Medicine,
DOI 10.1017/s0033291721003597，Associative Learning Task 入库时的核对工具。

## 脚本

- `verify_trial.py` — 库内 `Hobbs_2023_PsychMed_Exp1_raw.csv`（51840 行）与作者
  `associative_df_trial_anon.csv` 逐行对比（Task/ShapeCode/Matching/RT_ms/
  ACC），并**用库内数据按作者 collapsed 口径重算聚合**（排除 rt<200 ms 与
  无响应后按 subject×Task×stimuli 求 prop_acc/mean_rt）与作者
  `associative_long_matching_collapsed_anon.csv`（1296 组合）逐值对比。
  用法：`python3 verify_trial.py`（项目根目录下执行）。
- `verify_stats.R` — 复现论文 Table 2 全部 48 个 b 系数（3 任务 × ACC/RT ×
  PHQ-9/BDI-II × 4 系数；lm + 标准化重拟合），容差 ±0.011（论文两位小数）。
  用法：`Rscript verify_stats.R`。

## 2026-08-30 核对结果

- trial 级：51840/51840 行一致（Task、ShapeCode、Matching、RT_ms（|diff|<1
  ms）、ACC（作者 acc=1 必为 1；acc=0 可为 0/NA/RT<200 ms 的正确行 1））。
  197 行 ACC 显示差异 = RT<200 ms 的**正确**试次：库内保留 ACC=1（最小预处
  理），作者分析前改为 0（Associative_cleaning.R 的 acc 改值口径）。
- 聚合级：1296/1296 组合全等（prop_acc 差 <1e-6；mean_rt 差 <1 ms）。
  round 边界：1 个组合（subject 79ccef…, Valence, Happy）存在 RT=199.666 ms
  的边界行（作者按精确值 <200 排除、库内 round 为 200 保留），验证脚本按
  作者精确值判定边界后一致——round 显示差异（<0.5 ms），非数据差异。
- 论文统计量：Table 2 全部 48 个 b 系数与论文一致（±0.011）；库内重算聚合
  与作者 collapsed 全等（故直接以作者 collapsed + qs session 2 问卷分复现，
  问卷数据不在库内范围）。

## 数据源说明

- 输入区权威文件：`Hobbs_2023_PsychMed_raw/Raw Anonymised Data/Data/
  Associative Learning/raw_associative_anon.xlsx`（作者清洗脚本
  Associative_cleaning.R 亦用 xlsx；同名 csv 存在表示层差异——NA 编码、
  形状分配列值，勿用）。
- 作者聚合文件：`Hobbs_2023_PsychMed_raw/Aggregated Data for Analysis/
  Data/Associative Learning/`（associative_df_trial_anon.csv /
  associative_long_matching_collapsed_anon.csv）。
- 论文全文：`REF/Hobbs_2023_PsychMed_DS.md`（DeepSeek 转换版）。
