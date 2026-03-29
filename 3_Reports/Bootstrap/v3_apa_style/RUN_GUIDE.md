# 运行指南 (v3)

## 快速开始

### 前置要求
```bash
pip install pandas numpy matplotlib seaborn scipy jupyter
```

### 运行方式

**方式一：Jupyter Notebook（推荐）**
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
jupyter notebook bootstrap_analysis_v3.ipynb
```
然后点击 "Cell" → "Run All"

**方式二：Python脚本**
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
python bootstrap_analysis_v3.py
```

## v3版本更新

### 1. 图表标题（根据导师反馈）
- 第一行：**"SPE calculated by strict approach"**
- 第二行：**"SPE calculated by loose approach"**
- 每行使用相同的筛选方法

### 2. APA学术格式
- ✅ **去除网格线** - 干净的白色背景
- ✅ **固定坐标轴** - 方便比较
  - X轴：[0, 500]
  - Y轴：[-0.4, 0.4]
- ✅ **Times New Roman字体** - APA标准
- ✅ **子图标签** (A, B, C, D) - 清晰标识

### 3. 两个版本

**版本1：原始样本量（Original）**
- 样本量按实际计算
- Shape和Label可能有不同的最大样本量
- 显示完整数据范围

**版本2：对齐样本量（Aligned）**
- 样本量限制为Shape和Label的最小值
- 两条线在同一位置结束
- 更容易比较Shape和Label
- 更保守的估计

## 输出文件

### 📊 图表文件（300 dpi）
- `combined_figures_apa_original.png` - 版本1（原始样本量）
- `combined_figures_apa_aligned.png` - 版本2（对齐样本量）

### 📄 数据文件

**版本1：原始**
- `bootstrap_rt_strict_original.csv`
- `bootstrap_acc_strict_original.csv`
- `bootstrap_rt_loose_original.csv`
- `bootstrap_acc_loose_original.csv`

**版本2：对齐**
- `bootstrap_rt_strict_aligned.csv`
- `bootstrap_acc_strict_aligned.csv`
- `bootstrap_rt_loose_aligned.csv`
- `bootstrap_acc_loose_aligned.csv`

**其他**
- `cohens_d_by_participant.csv` - 每个被试的Cohen's d值

## 图表布局

```
┌─────────────────────────────────────────────────────────┐
│  A. SPE calculated by strict approach (RT)              │
│     B. SPE calculated by strict approach (ACC)          │
├─────────────────────────────────────────────────────────┤
│  C. SPE calculated by loose approach (RT)               │
│     D. SPE calculated by loose approach (ACC)           │
└─────────────────────────────────────────────────────────┘
```

每个子图显示：
- **蓝色线条**：Shape分析
- **紫色线条**：Label分析
- **阴影区域**：95%置信区间
- **灰色虚线**：无效应（d=0）

## APA格式说明

### 应用的APA标准
1. **字体**：全文使用Times New Roman
2. **背景**：白色，无网格线
3. **坐标轴**：
   - 固定范围便于比较
   - 去除顶部和右侧边框
   - 左侧和底部边框1pt宽度
4. **标签**：粗体，层次清晰
5. **图例**：紧凑，右上角放置
6. **子图标签**：A、B、C、D粗体

## 结果解读

### Cohen's d值
- **RT**：d = (Mean_Stranger - Mean_Self) / Pooled_SD
  - 正值 = Stranger更慢 = 自我优势效应
- **ACC**：d = (Mean_Self - Mean_Stranger) / Pooled_SD
  - 正值 = Self更准确 = 自我优势效应

### 统计显著性
- 95% CI不包含0 → 显著效应
- 95% CI包含0 → 不显著效应

### 版本选择建议
- **使用版本1**：需要展示完整数据范围时
- **使用版本2**：需要直接比较Shape和Label时（推荐用于发表）

## 常见问题

### Q1：应该使用哪个版本？
A：建议使用版本2（对齐样本量）进行发表，因为它允许更公平的比较。

### Q2：为什么要去除网格线？
A：APA格式要求简洁的图表，网格线会分散注意力。

### Q3：为什么固定坐标轴？
A：固定坐标轴使得不同图表之间可以直接比较效应大小。

### Q4：Shape和Label的区别是什么？
A：
- **Shape**：以Shape为基准，Label为辅助
- **Label**：以Label为基准，Shape为辅助
- 两者都计算Self vs. Stranger的效应

## 引用

如果您使用此分析，请引用：
1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.
2. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

## 联系方式

如有问题，请联系：
- 蔡振兴：czx@nnu.edu.cn
- 胡传鹏（通讯作者）：hcp4715@hotmail.com
