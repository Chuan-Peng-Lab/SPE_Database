# SPE数据库交互式自动化清理工具 - 使用指南

## 一、总结：Clean_Data_V3.Rmd 数据清理逻辑

### 1.1 变量选择模式（最常出现的清理后变量）

根据对 Clean_Data_V3.Rmd（5125行代码，137个数据集）的分析，标准清理后的变量包括：

| 变量名 | 描述 | 可能的原始列名 |
|--------|------|----------------|
| **Subject** | 参与者ID | Subject, V1, Pair Number, participant, Participant.Private.ID |
| **Shape** | 形状刺激 | Shape, V7, V8, V9, Stimulus |
| **Label** | 标签刺激 | Label, Label1, Label2, Label3, V10, V11, V12 |
| **Matching** | 匹配条件 | Matching, Condition, Match, V14 |
| **ACC** | 准确率 | ACC, acc, corr, Target.ACC, respond3.ACC, V15 |
| **RT_ms** | 反应时间（毫秒） | RT_ms, RT, rt, Target.RT, respond3.RT, V16, latency |
| **RT_sec** | 反应时间（秒） | 自动从RT_ms转换 |
| **Response** | 参与者反应 | Response, resp, V5 |
| **Shape_Origin_Identity** | 原始身份 | 直接从Shape提取 |
| **Shape_English_Identity** | 英语身份 | 多语言翻译 |
| **Shape_Standardized_Identity** | 标准化身份 | Self/Close/Acquaintance/Celebrity/Stranger/NonPerson |

### 1.2 Identity三级标准化

```
原始(Origin) → 英语(English) → 标准化(Standardized)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Self, you, 我, 自我, Sie → Self → Self
Friend, close, 朋友, Freund → Friend → Close  
Stranger, other, 陌生人, Fremder → Stranger → Stranger
Acquaintance, 熟人 → Acquaintance → Acquaintance
Celebrity, 名人 → Celebrity → Celebrity
NonPerson, none, object → NonPerson → NonPerson
```

### 1.3 Matching条件标准化

```
原始值 → 标准化
━━━━━━━━━━━━━━━━
1, match, Match, true → Matching
2, mismatch, Nonmatch, false → Nonmatching
Shape == Label → 自动推断
```

### 1.4 RT单位处理

- 如果中位数 < 10：假设是**秒**，转换为毫秒 (×1000)
- 如果中位数 >= 10：假设是**毫秒**，保持不变

### 1.5 ACC标准化

- 数值 > 0 → 1 (正确)
- 数值 <= 0 → 0 (错误)

---

## 二、自动化工具功能

### 2.1 文件结构

```
2_Code/
├── SPE_Interactive_Clean.R   # 交互式清理工具（推荐）
├── SPE_Batch_Clean.R         # 批量清理工具（简洁版）
└── SPE_Interactive_Clean.R   # 完整交互式工具（带变量审核）
```

### 2.2 功能对比

| 功能 | 交互式工具 | 批量工具 |
|------|-----------|---------|
| 用户输入路径 | ✅ 多种格式 | ❌ 自动扫描 |
| 变量审核修正 | ✅ 可修改 | ❌ 默认检测 |
| 批量处理 | ✅ 支持 | ✅ 支持 |
| 详细报告 | ✅ | ✅ |
| 新增数据处理 | ✅ 推荐 | ❌ |

---

## 三、使用方法

### 3.1 交互式处理（推荐新增数据使用）

```r
# 在RStudio中运行
source("SPE_Interactive_Clean.R")

# 选择菜单选项:
# [1] 处理单个文件 (交互式) - 推荐新增数据
# [2] 批量处理所有文件
```

**交互式处理流程：**

```
步骤1：输入数据路径
  ↓
  支持格式：
  - "D:/path/to/file.csv"
  - D:/path/to/file.csv
  - D:\path\to\file.csv
  - ../1_Data/...

步骤2：读取数据并检测变量
  ↓
  自动检测变量映射：
  - Subject → 检测到的列名
  - Shape → 检测到的列名
  - Label → 检测到的列名
  - ...

步骤3：用户审核变量
  ↓
  显示检测结果：
  Subject -> [detected]: 
  (直接回车确认，或输入正确列名修改)

步骤4：清理并保存
  ↓
  输出: *_Clean.csv
```

### 3.2 批量处理（首次转换推荐）

```r
source("SPE_Batch_Clean.R")
```

自动处理 `1_Data` 目录下所有 `*_raw.csv` 文件。

### 3.3 命令行运行

```bash
# Windows
Rscript SPE_Batch_Clean.R

# 或双击 RUN_SPE_CLEAN.bat
```

---

## 四、输出说明

### 4.1 输出文件

- **命名**: `*_raw.csv` → `*_Clean.csv`
- **位置**: 与原始文件同目录

### 4.2 输出变量

| 变量 | 类型 | 描述 |
|------|------|------|
| Subject | numeric | 参与者ID |
| Shape | character | 形状刺激 |
| Label | character | 标签刺激 |
| Matching | factor | Matching/Nonmatching |
| ACC | numeric | 0或1 |
| RT_ms | numeric | 毫秒 |
| RT_sec | numeric | 秒 |
| Response | character | 参与者反应 |
| Shape_Origin_Identity | character | 原始身份 |
| Shape_English_Identity | character | 英语身份 |
| Shape_Standardized_Identity | factor | 标准化身份 |

### 4.3 标准化Identity类别

```
Self          - 自我
Close         - 亲密他人（朋友、家人）
Acquaintance  - 熟人
Celebrity     - 名人
Stranger      - 陌生人
NonPerson     - 非人物体
Unknown       - 未知
```

---

## 五、常见问题

### 5.1 文件读取失败

**问题**: 某些文件无法读取

**解决**: 
- 交互式工具会自动尝试多种编码
- 批量处理会跳过空文件并继续

### 5.2 变量检测错误

**问题**: 变量映射检测不正确

**解决**: 
- 交互式工具提供审核界面，可手动修改
- 显示所有可用列名供选择

### 5.3 Wozniak文件问题

**问题**: Wozniak_2022_PR_Exp1_raw.csv 只有4字节

**原因**: 原始数据为.dat格式，需从Wozniak_2022_PR_Raw文件夹处理

**解决**: 批量处理会自动跳过空文件

---

## 六、技术细节

### 6.1 支持的编码

- UTF-8-BOM (优先)
- UTF-8
- latin1
- GBK
- 默认

### 6.2 错误处理

- 每个文件独立处理，失败不影响其他
- 空文件(<100 bytes)自动跳过
- 详细的错误日志

### 6.3 性能

- 逐文件处理，避免内存溢出
- 实时进度显示
- 大文件支持（测试过100MB+文件）

---

## 七、示例

### 7.1 处理单个文件

```
> source("SPE_Interactive_Clean.R")

请选择操作模式:
  [1] 处理单个文件 (交互式)
  [2] 批量处理所有文件

请输入选择 (0-2): 1

请输入原始数据文件路径: D:\GitHub_programe\GitHub\SPE_Database\1_Data\Constable_2020_AP\Constable_2020_AP_Exp1_raw.csv

✓ 文件路径已识别

步骤2：读取数据并检测变量
✓ 成功读取数据: 1200 行 × 24 列
✓ 自动检测到 7 个变量映射

步骤3：变量审核
检测到的变量映射:
(如果正确直接回车跳过，有误则输入正确的列名)
------------------------------------------------------------
Subject -> [Subject]: 
(直接回车)
Shape -> [Shape]: 
(直接回车)
...

✓ 数据清理完成: 1200 行 × 11 列
✓ 已保存到: ...\Constable_2020_AP_Exp1_Clean.csv
```

### 7.2 批量处理

```
> source("SPE_Batch_Clean.R")

找到 65 个原始数据文件

[1/65] Constable_2020_AP_Exp1_raw.csv
  ✓ Constable_2020_AP_Exp1_Clean.csv (1200 行)

...

============================================================
处理完成!
============================================================
总计: 65 个文件
成功: 64 个
跳过: 1 个 (空文件)
失败: 0 个
============================================================
```

---

## 八、联系方式

如有问题，请联系：
- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng: hcp4715@hotmail.com

---

**版本**: v2.0  
**更新日期**: 2025-03-06