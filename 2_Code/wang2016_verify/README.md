# wang2016_verify — Wang, Humphreys & Sui (2016, JEPHPP) 核对脚本

2026-09-01 txt 转换后核对（结果与背景见 `3_Reports/Verifying_original_results_issues.md` Issue 3，原 `Wang_2016_JEPHPP_Stage4_Notes.md` 已并入删除）。

## 文件用途

| 脚本 | 用途 | 口径 |
|---|---|---|
| `verify_merge_vs_csv.py` | 6 份 E-Merge txt ↔ 4 份作者聚合 CSV 逐值核对 + 规则 B 验证 + 结构核对 | txt 为扁平宽表（第 4 行列名）；Label 中文/小写英文→英文映射；Identity None/stranger→Stranger；Exp2 练习行用 Target1.*；Block=TRxBlockList.Sample（变体 x 从 Procedure[Block] 提取）；规则 B：Matching == (CorrectAnswer == yeskey)，yeskey 每被试由 practice 行 YesNoResp 推断。运行：`python3 verify_merge_vs_csv.py`，退出码 0 = 全部一致（2026-09-01：TOTAL PROBLEMS: 0） |
| `verify_stats.R` | 论文统计量复现（match/mismatch 错误率与 RT 的 RM-ANOVA） | 数据源 `/tmp/wang_trials.csv`（由 verify_merge_vs_csv.py 的解析函数导出的全 trial 表）；正式试次、规则 B match 集、正确试次 RT 均值、错误率=ACC==0（无反应计错）；aov 实现。主结论见 Issue 3 |
| `scan_subsets.R` | Exp2 全部 C(25,20)=53130 个 20 人子集扫描（数据源 /tmp/wang_trials.csv） | 直接 SS 分解公式（aov 太慢）；结论：RT F 最接近 17.3499（论文 17.35）、错误率 3.9300（论文 3.93）——论文 20 人样本与数据相容但排除名单不可唯一反推（RT 命中 731 子集、err 命中 2087 子集） |

## 关键结论（2026-09-01）

1. 聚合 CSV 无导出损失（除 practice 行：Exp2 breaking 9 行/被试、两实验 association 6 行/被试被作者导出丢弃，txt 均有）——库内数据已从 txt 重建（`Wang_2016_JEPHPP_clean.R` v2）。
2. association 任务实为 3AFC（键 b/n/m=标签位置），Label 由 T1-T3+CorrectAnswer 确定性恢复。
3. 规则 B 全量 0 违例；8 blocks×81、9 条件×72 结构全对。
4. 统计：Exp1 match-RT F=43.02（论文 43.29，近似）；Exp2 20 人子集可精确复现论文 F（不可唯一反推）。
5. AssoMatc_Self（RawData_Baseline 31 人）≠ 论文 control（结构 6×60 vs 8×81、人口学、采集时间三重不符）——不入库，保留存档。
