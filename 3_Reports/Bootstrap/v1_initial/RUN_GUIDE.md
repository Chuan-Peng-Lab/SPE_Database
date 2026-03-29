# 运行指南

## 快速开始

### 前置要求
确保已安装以下Python库：
```bash
pip install pandas numpy matplotlib seaborn scipy jupyter
```

### 方式一：Jupyter Notebook（推荐）

1. 打开终端/命令提示符
2. 导航到Bootstrap目录：
   ```bash
   cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
   ```
3. 启动Jupyter Notebook：
   ```bash
   jupyter notebook bootstrap_analysis.ipynb
   ```
4. 在Notebook中，从顶部运行所有单元格（Cell → Run All）

### 方式二：Python脚本

1. 打开终端/命令提示符
2. 导航到Bootstrap目录：
   ```bash
   cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
   ```
3. 运行脚本：
   ```bash
   python bootstrap_analysis.py
   ```

## 输出文件说明

### 数据文件
- `cohens_d_by_participant.csv` - 每个被试的Cohen's d值
- `bootstrap_results.csv` - 每个样本量的bootstrap结果

### 图表文件
- `figure1_shape_strict.png` - 严格筛选，Shape基准（300 dpi）
- `figure2_label_strict.png` - 严格筛选，Label基准（300 dpi）
- `figure3_shape_loose.png` - 宽松筛选，Shape基准（300 dpi）
- `figure4_label_loose.png` - 宽松筛选，Label基准（300 dpi）
- `combined_figures_300dpi.png` - 4张图合并为2x2网格（300 dpi）

## 分析说明

### 数据筛选标准

**严格筛选（图1-2）**：
- 需要同时具有Shape和Label标准化身份列
- 每个被试至少需要3种不同的社会身份
- 排除Shape=Stranger且Label=Self的试次（Shape基准）
- 排除Label=Stranger且Shape=Self的试次（Label基准）
- 这种方法控制了潜在的自我相关性混淆

**宽松筛选（图3-4）**：
- 只需要Shape为Self或Stranger
- 不需要Label筛选
- 标准更简单，包含更多数据

### Cohen's d计算
```
Cohen's d = (Mean_RT_Stranger - Mean_RT_Self) / Pooled_SD
```
其中：
- Pooled_SD = sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))
- 正的d值表示Stranger RT > Self RT（自我优势效应）

### Bootstrap重采样
- 每个样本量进行1000次迭代
- 样本量：10, 20, 30, ..., n_participants
- 有放回抽样
- 计算Cohen's d的均值和95%置信区间

## 图表解读

每个图表显示：
- **X轴**：样本量（被试数量）
- **Y轴**：Cohen's d均值（Stranger - Self）
- **蓝色/绿色线**：bootstrap迭代的效应量均值
- **阴影区域**：95%置信区间
- **红色虚线**：无效应（d=0）

### 关键问题
1. 不匹配条件下是否存在自我优势效应？
2. 效应量是否太小而无法在单个数据集中检测到？
3. 效应量如何随样本量增加而稳定？
4. 严格与宽松筛选标准是否影响结论？

## 故障排除

### 问题1：找不到数据文件
**错误**：`FileNotFoundError: [Errno 2] No such file or directory`
**解决**：检查数据路径是否正确：
```python
data_path = Path("D:/GitHub_programe/GitHub/SPE_Database/1_Data")
```

### 问题2：缺少必要的列
**错误**：`KeyError: 'Shape_Standardized_Identity'`
**解决**：检查数据文件是否包含必要的列：
- Subject
- Matching
- Shape_Standardized_Identity
- Label_Standardized_Identity（严格筛选需要）
- RT_ms
- ACC

### 问题3：内存不足
**错误**：`MemoryError`
**解决**：
- 减少bootstrap迭代次数（从1000改为500）
- 增加样本量步长（从10改为20）

### 问题4：图表显示问题
**错误**：图表不显示或显示异常
**解决**：
- 确保安装了matplotlib后端：
  ```bash
  pip install matplotlib --upgrade
  ```
- 在Jupyter Notebook中添加：
  ```python
  %matplotlib inline
  ```

## 验证结果

### 检查清单
- [ ] 所有52个数据集加载成功
- [ ] 只保留Nonmatching试次
- [ ] Cohen's d值范围在-2到2之间
- [ ] Bootstrap结果显示CI宽度随n增加而减小
- [ ] 4张图表都正确生成（300 dpi）
- [ ] 合并图表清晰可读

### 预期结果
- **严格筛选**：参与者数量较少（通常100-200人）
- **宽松筛选**：参与者数量较多（通常300-500人）
- **效应量**：通常在-0.5到0.5之间
- **置信区间**：随样本量增加而变窄

## 引用

如果您使用此分析，请引用：
1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.
2. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.
3. Efron, B., & Tibshirani, R. J. (1993). *An Introduction to the Bootstrap*. Chapman & Hall.

## 联系方式

如有问题，请联系：
- 蔡振兴：czx@nnu.edu.cn
- 胡传鹏（通讯作者）：hcp4715@hotmail.com
