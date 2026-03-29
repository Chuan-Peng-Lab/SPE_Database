# 运行指南 (v2)

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
   jupyter notebook bootstrap_analysis_v2.ipynb
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
   python bootstrap_analysis_v2.py
   ```

## 输出文件说明

### 图表文件（300 dpi）
- `bootstrap_rt_strict.png` - 严格筛选RT图
- `bootstrap_acc_strict.png` - 严格筛选ACC图
- `bootstrap_rt_loose.png` - 宽松筛选RT图
- `bootstrap_acc_loose.png` - 宽松筛选ACC图
- `combined_figures_300dpi.png` - 4张图合并为2x2网格

### 数据文件
- `bootstrap_rt_strict.csv` - RT严格筛选bootstrap结果
- `bootstrap_acc_strict.csv` - ACC严格筛选bootstrap结果
- `bootstrap_rt_loose.csv` - RT宽松筛选bootstrap结果
- `bootstrap_acc_loose.csv` - ACC宽松筛选bootstrap结果
- `cohens_d_by_participant.csv` - 每个被试的Cohen's d值

## 分析说明

### 数据筛选标准

**严格筛选**：
- 需要同时具有Shape和Label信息
- 每个被试至少需要3种不同的社会身份
- 排除Primary=Stranger且Secondary=Self的试次
- 这种方法控制了潜在的自我相关性混淆

**宽松筛选**：
- 只需要Primary为Self或Stranger
- 不基于Secondary进行筛选
- 标准更简单，包含更多数据

### Cohen's d计算
```
RT:   Cohen's d = (Mean_Stranger - Mean_Self) / Pooled_SD
ACC:  Cohen's d = (Mean_Self - Mean_Stranger) / Pooled_SD
```
其中：
- Pooled_SD = sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))
- RT正的d值表示Stranger RT > Self RT（自我优势效应）
- ACC正的d值表示Self ACC > Stranger ACC（自我优势效应）

### Bootstrap重采样
- 500次迭代/样本量
- 样本量：10, 20, 30, ..., n_participants
- **有放回抽样**（与R代码一致）
- 计算Cohen's d的均值和95%置信区间

## 图表解读

每个图表显示：
- **X轴**：样本量（被试数量）
- **Y轴**：Cohen's d均值
  - RT：Stranger - Self（正=Stranger更慢=自我优势）
  - ACC：Self - Stranger（正=Self更准确=自我优势）
- **蓝色线**：Shape分析
- **紫色线**：Label分析
- **阴影区域**：95%置信区间
- **灰色虚线**：无效应（d=0）

### 关键问题
1. 不匹配条件下是否存在自我优势效应？
2. 当前样本量是否足以检测到效应？
3. Shape和Label条件下的效应是否不同？
4. 严格与宽松筛选标准是否影响结论？

## 与R代码的对应关系

本Python代码严格对应R代码"bootstrap 2.0"的逻辑：

| R代码 | Python代码 |
|-------|-----------|
| `process_data(data, "Shape")` | `process_data_strict(df, 'Shape')` |
| `calculate_cohens_d(data, "Shape", "RT")` | `calculate_cohens_d_per_subject(df, 'RT')` |
| `bootstrap_analysis_simple(cohens_d_result, "Shape")` | `bootstrap_analysis(cohens_d_values)` |
| `sample(all_cohens_d, size = n, replace = TRUE)` | `np.random.choice(cohens_d_values, size=n, replace=True)` |

## 故障排除

### 问题1：找不到数据文件
**错误**：`FileNotFoundError`
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
- RT_ms
- ACC

### 问题3：Label_Standardized_Identity不存在
**警告**：`Label_Standardized_Identity not found`
**解决**：代码会自动使用Shape_Standardized_Identity作为替代

### 问题4：内存不足
**错误**：`MemoryError`
**解决**：
- 减少bootstrap迭代次数（从500改为200）
- 增加样本量步长（从10改为20）

### 问题5：图表显示问题
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
- [ ] 所有数据集加载成功
- [ ] 只保留Nonmatching试次
- [ ] Cohen's d值范围在-2到2之间
- [ ] Bootstrap结果显示CI宽度随n增加而减小
- [ ] 4张图表都正确生成（300 dpi）
- [ ] 合并图表清晰可读
- [ ] Shape和Label线条都显示在图中

### 预期结果
- **严格筛选**：参与者数量较少
- **宽松筛选**：参与者数量较多
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
