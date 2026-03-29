# Bootstrap Analysis - 文件夹整理完成

## 📁 最终文件夹结构

```
D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\
│
├── README.md                          # 主说明文档
│
├── v1_initial/                        # 版本1：初始实现
│   ├── bootstrap_analysis.ipynb       # Jupyter Notebook
│   ├── bootstrap_analysis.py          # Python脚本
│   ├── README.md                      # 说明文档
│   ├── RUN_GUIDE.md                   # 运行指南
│   └── TASK_TREE.json                 # 任务分解
│
├── v2_shape_label/                    # 版本2：区分Shape和Label
│   ├── bootstrap_analysis_v2.ipynb
│   ├── bootstrap_analysis_v2.py
│   ├── README.md
│   └── RUN_GUIDE.md
│
├── v3_apa_style/                      # 版本3：APA格式
│   ├── bootstrap_analysis_v3.ipynb
│   ├── bootstrap_analysis_v3.py
│   ├── README.md
│   └── RUN_GUIDE.md
│
├── v4_legend_optimized/               # 版本4：图例优化（最新）
│   ├── bootstrap_analysis_v4.ipynb
│   ├── bootstrap_analysis_v4.py
│   └── README.md
│
├── results_data/                      # 所有结果数据
│   ├── bootstrap_rt_strict_original.csv
│   ├── bootstrap_rt_strict_aligned.csv
│   ├── bootstrap_rt_loose_original.csv
│   ├── bootstrap_rt_loose_aligned.csv
│   ├── bootstrap_acc_strict_original.csv
│   ├── bootstrap_acc_strict_aligned.csv
│   ├── bootstrap_acc_loose_original.csv
│   ├── bootstrap_acc_loose_aligned.csv
│   ├── bootstrap_results.csv
│   ├── bootstrap_rt_strict.csv
│   ├── bootstrap_rt_loose.csv
│   ├── bootstrap_acc_strict.csv
│   ├── bootstrap_acc_loose.csv
│   └── cohens_d_by_participant.csv
│
└── results_figures/                   # 所有生成的图表
    ├── v1_initial/
    │   ├── figure1_shape_strict.png
    │   ├── figure2_label_strict.png
    │   ├── figure3_shape_loose.png
    │   ├── figure4_label_loose.png
    │   └── combined_figures_300dpi.png
    │
    ├── v2_shape_label/
    │   ├── bootstrap_rt_strict.png
    │   ├── bootstrap_acc_strict.png
    │   ├── bootstrap_rt_loose.png
    │   └── bootstrap_acc_loose.png
    │
    ├── v3_apa_style/
    │   ├── combined_figures_apa_original.png
    │   └── combined_figures_apa_aligned.png
    │
    └── v4_legend_optimized/
        ├── combined_figures_style1_original.png
        ├── combined_figures_style1_aligned.png
        ├── combined_figures_style2_original.png
        └── combined_figures_style2_aligned.png
```

## 📊 版本演进

| 版本 | 主要改进 | 推荐用途 |
|------|---------|---------|
| **v1** | 基础bootstrap实现 | 学习参考 |
| **v2** | 区分Shape和Label，RT和ACC | 功能完整 |
| **v3** | APA格式，固定坐标轴 | 学术发表 |
| **v4** | 图例位置优化 | **推荐使用** |

## 🎯 推荐使用

### 用于导师审阅/发表
```
results_figures/v4_legend_optimized/combined_figures_style1_aligned.png
```

### 用于演示
```
results_figures/v4_legend_optimized/combined_figures_style2_aligned.png
```

### 运行最新代码
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized
jupyter notebook bootstrap_analysis_v4.ipynb
```

## ✅ 整理完成清单

- [x] 创建版本文件夹（v1-v4）
- [x] 移动代码文件到对应版本文件夹
- [x] 移动文档文件到对应版本文件夹
- [x] 创建results_data文件夹存放所有CSV数据
- [x] 创建results_figures文件夹存放所有图表
- [x] 按版本分类图表文件
- [x] 创建主README说明文档

## 📝 文件说明

### 代码文件
- `.ipynb` - Jupyter Notebook，交互式运行
- `.py` - Python脚本，命令行运行

### 文档文件
- `README.md` - 项目说明
- `RUN_GUIDE.md` - 运行指南
- `TASK_TREE.json` - 任务分解（仅v1）

### 数据文件
- `*_original.csv` - 原始样本量结果
- `*_aligned.csv` - 对齐样本量结果
- `cohens_d_by_participant.csv` - 个体Cohen's d值

### 图表文件
- `*_original.png` - 原始样本量图表
- `*_aligned.png` - 对齐样本量图表
- `style1` - 图例在标题右侧
- `style2` - 图例在标题下方

## 🚀 快速开始

```bash
# 进入最新版本文件夹
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized

# 运行Jupyter Notebook
jupyter notebook bootstrap_analysis_v4.ipynb

# 或运行Python脚本
python bootstrap_analysis_v4.py
```

---

**整理完成时间**: 2026-03-29
**最新版本**: v4_legend_optimized
