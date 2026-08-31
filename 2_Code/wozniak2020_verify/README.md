# wozniak2020_verify — Wozniak_2020_PLOS 四方核对脚本

2026-09 阶段 5 入库四方核对（论文 ↔ 作者脚本/xlsx ↔ 库内数据 ↔ .dat 原始
导出）。发现记录于 `3_Reports/Verifying_original_results_issues.md`（Issue 4）。

## 文件

- `verify_massive.py` — 复刻作者 MATLAB 聚合（`DATA/Massive_SelfBoost_
  Avg1subject_MAD_full.m` + `SelfBoost_Avg1subject_MAD_full.m`）并与其
  xlsx 聚合文件（"Raw data - SelfBoostExp.xlsx"）逐值对比。
  运行：`python3 2_Code/wozniak2020_verify/verify_massive.py`
  结果：**3312 单元格 0 差异**（72 被试 × 46 列，RT ±0.01 ms / 正确率
  ±0.001）。

## 作者口径（脚本实现）

- RT 过滤：仅正确试次且 200 < RT < 1500 ms（脚本 `highestRT = 1500`
  硬编码覆盖了论文文字所述的 2.5 MAD 口径）。
- xlsx 身份编号（关键）：cue 编号 = 内部码（1=You, 2=Neutral,
  3=AntiYou）；face 编号 = 槽号 σ(j) = 码 j 在 labelsREAL 排列中的位置：
  perm0 [2,1,3]、perm1 [1,2,3]、perm2 [2,3,1]、perm3 [3,1,2]。
  RT_ij = 组合 (label i, face σ(j))；RT_0i = face σ(i)；RT_M_i =
  (i, σ(i))；RT_NM1_i = label i & face≠σ(i)；RT_NM2_i = face σ(i) &
  label≠i。
- xlsx "ER_" 列 = 正确率（正确且 RT 有效 / 分母），非错误率。

## 描述性统计方向核对（论文口径，2026-09 实测）

按作者过滤口径（正确 & 200<RT<1500）聚合库内 Clean 数据：

| 实验 | 核对项 | 库内实测 | 论文报告 |
|---|---|---|---|
| Exp1 | cue You vs 陌生人 | 646.2 vs 682.6 ms（Self 快） | You cue 显著更快 ✓ |
| Exp1 | matching vs nonmatching | 640.1 vs 684.9 ms | 交互显著（匹配更快）✓ |
| Exp2 | cue 关联本人脸名字 vs 其他 | 624.7 vs 654.3 ms | 关联名字显著更快 ✓ |
| Exp2 | target 本人脸 vs 陌生脸 | 619.0 vs 657.4 ms | 本人脸显著更快 ✓ |
| Exp3 | cue 无效应 | 638.2 vs 633.5 ms（差 4.7） | F=0.19 无效应 ✓ |
| Exp3 | target 本人脸 vs 自关联脸 vs 陌生脸 | 620.0 / 650.8 / 638.8 ms | 本人脸最快 ✓ |
| ×3 | matching < nonmatching | 全部成立 | ✓ |

库内数据（`Wozniak_2020_PLOS_clean.R` 产物）身份映射按论文语义（Exp1:
You=Self；Exp2: 本人脸=Self；Exp3: You=自关联陌生脸=Self、本人脸=Self），
与 xlsx 的错位编号无关。
