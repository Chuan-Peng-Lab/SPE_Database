# Bootstrap Analysis - v4.4 Legend Optimized (Final Version)

## 定义

- **Strict approach** = 严格筛选（排除Primary=Stranger且Secondary=Self的试次）
- **Loose approach** = 宽松筛选（只保留Self和Stranger）

## 版本说明

| 版本 | Strict | Loose | 用途 |
|------|--------|-------|------|
| **v4.3** | Aligned (对齐) | Max (最大) | 比较Shape vs Label |
| **v4.4** | Max (最大) | Max (最大) | 比较Strict vs Loose |
- **Loose approach** = Max version（各自取最大样本量）

## 文件夹结构

```
v4_legend_optimized/
│
├── 📝 代码文件
│   ├── bootstrap_analysis_v4.3.ipynb   # ✅ 最新版本（推荐）
│   ├── bootstrap_analysis_v4.2.ipynb
│   ├── bootstrap_analysis_v4.1.ipynb
│   ├── bootstrap_analysis_v4.ipynb
│   └── bootstrap_analysis_v4.py
│
├── 📊 结果数据 (CSV)
│   ├── bootstrap_rt_strict_v4.3.csv
│   ├── bootstrap_acc_strict_v4.3.csv
│   ├── bootstrap_rt_loose_v4.3.csv
│   └── bootstrap_acc_loose_v4.3.csv
│
├── 📈 结果图表 (PNG, 300 dpi)
│   └── combined_figures_v4.3.png
│
└── 📖 文档
    └── README.md
```

## 运行方式

```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized
jupyter notebook bootstrap_analysis_v4.3.ipynb
```

然后点击 "Cell" → "Run All"

## 图表布局

```
┌─────────────────────────────────────────────────────────┐
│  A. SPE calculated by strict approach (RT)              │
│     ■ Shape  ■ Label                                    │
│                                                         │
│     B. SPE calculated by strict approach (ACC)          │
│        ■ Shape  ■ Label                                 │
├─────────────────────────────────────────────────────────┤
│  C. SPE calculated by loose approach (RT)               │
│     ■ Shape  ■ Label                                    │
│                                                         │
│     D. SPE calculated by loose approach (ACC)           │
│        ■ Shape  ■ Label                                 │
└─────────────────────────────────────────────────────────┘
```

## 预期结果

### Strict (Aligned) - 样本量对齐
| 指标 | Shape | Label |
|------|-------|-------|
| RT | N=610, d≈0.075, Sig: Yes | N=610, d≈0.277, Sig: Yes |
| ACC | N=590, d≈0.054, Sig: Yes | N=590, d≈0.013, Sig: No |

### Loose (Max) - 各自最大样本量
| 指标 | Shape | Label |
|------|-------|-------|
| RT | N=964, d≈0.005, Sig: No | N=813, d≈0.160, Sig: Yes |
| ACC | N=954, d≈0.007, Sig: No | N=800, d≈-0.015, Sig: No |

## 版本历史

| 版本 | 改进 |
|------|------|
| v4 | 两种图例样式（Style 1和Style 2） |
| v4.1 | 修复Loose Filtering输出缺失问题 |
| v4.2 | 修复X轴范围问题 |
| v4.3 | 最终版本：Strict=Aligned, Loose=Max |

## 联系方式

- 蔡振兴: czx@nnu.edu.cn
- 胡传鹏（通讯作者）: hcp4715@hotmail.com
