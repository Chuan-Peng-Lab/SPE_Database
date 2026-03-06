# SPE数据库自动化数据清理工具

## 概述

这是一个全自动化的SPE数据库数据清理工具，能够批量处理 `1_Data`目录下所有 `*_raw.csv`文件，自动识别变量并清理，输出对应的 `*_Clean.csv`文件。

## 核心功能

1. **自动变量识别**：自动检测Subject、Shape、Label、Matching、ACC、RT等关键变量
2. **多语言支持**：支持英语、德语、中文等多种语言的Identity标准化
3. **单位自动检测**：自动检测RT单位为秒或毫秒，并进行转换
4. **批量处理**：一键处理所有原始数据文件
5. **交互式界面**：提供简单的命令行交互界面

## 文件结构

```
2_Code/
├── SPE_Auto_Clean.R          # 主清理脚本（完整功能）
├── Test_Auto_Clean.R         # 测试脚本（简化版）
└── README_Auto_Clean.md      # 使用说明
```

## 使用方法

### 方法1：使用完整脚本（推荐）

在RStudio中运行：

```r
# 打开RStudio，设置工作目录
setwd("D:/GitHub_programe/GitHub/SPE_Database/2_Code")

# 加载脚本
source("SPE_Auto_Clean.R")

# 运行主函数
main()
```

### 方法2：使用测试脚本

```r
# 在RStudio中运行测试
source("Test_Auto_Clean.R")
```

### 方法3：命令行运行

```bash
# 在命令行中运行（需要Rscript）
Rscript SPE_Auto_Clean.R
```

## 交互式界面

运行 `main()`函数后，会出现以下选项：

```
SPE数据库交互式数据清理工具
==================================================

请选择操作模式:
1. 处理单个文件
2. 批量处理所有文件
3. 处理指定目录
```

### 选项1：处理单个文件

- 输入原始数据文件的完整路径
- 系统自动检测变量并清理
- 生成 `*_Clean.csv`文件

### 选项2：批量处理所有文件

- 自动扫描 `1_Data`目录下所有 `*_raw.csv`文件
- 批量处理所有文件
- 生成详细处理报告

### 选项3：处理指定目录

- 输入自定义目录路径
- 处理该目录下所有 `*_raw.csv`文件

## 输出格式

清理后的数据包含以下标准变量：

| 变量名                      | 描述             | 示例                         |
| --------------------------- | ---------------- | ---------------------------- |
| Subject                     | 参与者ID         | 1, 2, 3...                   |
| Shape                       | 形状刺激         | "Self", "Friend", "Stranger" |
| Label                       | 标签刺激         | "Self", "Friend", "Stranger" |
| Matching                    | 匹配条件         | "Matching", "Nonmatching"    |
| ACC                         | 准确率           | 0, 1                         |
| RT_ms                       | 反应时间（毫秒） | 456.7                        |
| RT_sec                      | 反应时间（秒）   | 0.4567                       |
| Response                    | 参与者反应       | "w", "o", "m", "n"           |
| Shape_Origin_Identity       | 原始身份         | "自我", "Sie", "Self"        |
| Shape_English_Identity      | 英语身份         | "Self", "Friend", "Stranger" |
| Shape_Standardized_Identity | 标准化身份       | "Self", "Close", "Stranger"  |

## 标准化身份类别

清理工具会将所有Identity标准化为以下6个类别：

1. **Self** - 自我
2. **Close** - 亲密他人（朋友、家人）
3. **Acquaintance** - 熟人
4. **Celebrity** - 名人
5. **Stranger** - 陌生人
6. **NonPerson** - 非人物体

## 支持的变量命名格式

### Subject变量

- `Subject`, `subject`, `Participant`, `participant`
- `Pair.Number`, `Pair Number`, `V1`, `V2`
- `subj_idx`, `Participant.Private.ID`

### RT变量

- `rt`, `RT`, `latency`, `reaction.time`
- `Target.RT`, `respond3.RT`, `V16`
- `iti.rt`, `RT_ms`, `RT_sec`

### ACC变量

- `acc`, `ACC`, `corr`, `correct`
- `accuracy`, `Target.ACC`, `respond3.ACC`
- `iti.acc`, `V15`

### Matching变量

- `match`, `Match`, `matching`, `Matching`
- `condition`, `Condition`, `type`, `V14`

## 处理流程

1. **读取原始数据**：使用 `read.csv()`读取 `*_raw.csv`文件
2. **变量检测**：基于关键词模式匹配检测变量
3. **数据清理**：
   - 标准化Matching条件
   - 标准化ACC为0/1
   - 检测并转换RT单位
   - 创建三级Identity变量
4. **数据转换**：
   - 数值类型转换
   - 因子水平设置
5. **保存输出**：保存为 `*_Clean.csv`

## 错误处理

- 文件不存在时显示错误信息
- 变量检测失败时使用默认值
- 数据类型转换错误时保留原始值
- 生成详细的处理报告

## 测试数据

已针对以下典型数据文件进行测试：

1. **Constable_2020_AP_Exp1_raw.csv** - 标准格式

   - 变量: `Shape`, `Label`, `Condition`, `rt`, `corr`
   - 特点: 标准SPE任务格式
2. **Qian_2019_QJEP_Exp1_raw.csv** - 复合字段

   - 变量: `condition`, `respond3.ACC`, `respond3.RT`
   - 特点: 复合condition字段 (`Self-shape_Matched`)
3. **Hu_2020_CP_Exp1_raw.csv** - 道德属性

   - 变量: `Shape`, `Label`, `Match`, `ACC`, `RT`
   - 特点: 包含道德属性 (`immoralSelf`, `moralOther`)

## 常见问题

### Q1: 如果变量检测失败怎么办？

A: 系统会使用默认值（如使用行号作为Subject），并在报告中显示警告。

### Q2: 如何处理特殊格式的数据？

A: 工具支持多种格式，如果遇到无法处理的情况，请参考 `Clean_Data_V3.Rmd`中的手动清理代码。

### Q3: 输出文件保存在哪里？

A: 输出文件保存在原始数据文件相同的目录，文件名从 `*_raw.csv`改为 `*_Clean.csv`。

### Q4: 如何验证清理结果？

A: 检查生成的 `*_Clean.csv`文件，确保：

1. 所有必要变量都存在
2. ACC值为0或1
3. RT单位正确
4. Identity标准化正确

## 扩展开发

如果需要处理新的数据格式，可以：

1. 在 `detect_variables()`函数中添加新的变量模式
2. 在 `standardize_to_english()`函数中添加新的语言映射
3. 在 `standardize_identity()`函数中添加新的标准化规则

## 联系信息

如有问题或建议，请联系：

- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng: hcp4715@hotmail.com

## 版本历史

- v1.0 (2025-03-05): 初始版本，支持基本自动化清理
- 基于 `Clean_Data_V3.Rmd` (5125行代码) 的清理逻辑

---

**注意**: 首次运行时可能需要安装 `dplyr`、`tidyr`、`readr`等R包。
