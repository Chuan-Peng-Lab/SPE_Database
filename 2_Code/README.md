# SPE 数据清理工具 - Shiny 版本

## 功能概述

本工具提供交互式网页界面用于清理和标准化 SPE (Self-Prioritization Effect) 数据库数据。支持单文件处理和批量处理两种模式。

## 主要功能

### 1. 双处理模式
- **单文件处理**：处理单个 `_raw.csv` 文件，提供完整的交互式数据清理流程
- **批量处理**：自动处理目录下所有 `*_raw.csv` 文件，结果打包为 ZIP 下载

### 2. 智能变量检测
- 自动识别关键变量：Subject, Shape, Label, Matching, ACC, RT, Response
- 支持可选变量：Block, Trial, Trial_Type, Session, Age, Sex, Handedness
- 允许添加自定义额外变量

### 3. Identity 标准化
- 自动检测 Shape 和 Label 值
- 提供标准化 Identity 映射选项：Self, Close, Acquaintance, Celebrity, Stranger, NonPerson, Unknown
- 支持手动输入自定义 Identity
- 三级标准化：Origin → English → Standardized

### 4. 数据验证
- Matching 条件验证（确保包含 Matching 和 Nonmatching）
- 数据预览：原始数据和清理后数据对比
- 统计信息：行数、列数、被试数量

### 5. 灵活的文件路径输入
- 支持多种格式：`D:/path/file.csv` 或 `"D:/path/file.csv"`
- 自动处理正斜杠和反斜杠
- 自动补全相对路径

## 使用方法

### 单文件处理模式
1. 选择 "单文件处理" 模式
2. 输入原始数据文件路径（支持 `_raw.csv` 文件）
3. 点击 "加载数据"
4. 点击 "自动检测变量" 或手动确认变量映射
5. 点击 "预览Shape/Label值" 查看唯一值并进行 Identity 映射
6. 点击 "开始清理" 处理数据
7. 查看清理结果和统计信息
8. 点击 "下载清理后的数据" 获取 `_Clean.csv` 文件

### 批量处理模式
1. 选择 "批量处理" 模式
2. 输入包含 `*_raw.csv` 文件的目录路径
3. 点击 "加载数据" 扫描文件
4. 按照单文件处理的步骤 4-6 完成变量映射和 Identity 设置
5. 点击 "开始清理" 开始批量处理
6. 实时查看处理进度和结果
7. 处理完成后点击 "下载清理后的数据" 获取包含所有结果的 ZIP 文件

## 输出变量

清理后的数据包含以下标准变量：
- Subject: 被试编号
- Shape: 形状刺激（保留原始值）
- Label: 标签刺激
- Matching: 匹配条件（Matching/Nonmatching）
- ACC: 准确性（0/1）
- RT_ms: 反应时间（毫秒）
- RT_sec: 反应时间（秒）
- Response: 参与者响应
- Block: 实验块（如果可用）
- Trial: 试次号（如果可用）
- Trial_Type: 试次类型（Practice/Formal）
- Session: 实验阶段（如果可用）
- Age: 年龄（如果可用）
- Sex: 性别（如果可用）
- Handedness: 利手性（如果可用）
- Shape_Origin_Identity: Shape 原始身份
- Shape_English_Identity: Shape 英文身份
- Shape_Standardized_Identity: Shape 标准化身份
- Label_Origin_Identity: Label 原始身份
- Label_English_Identity: Label 英文身份
- Label_Standardized_Identity: Label 标准化身份
- [额外变量...]

## 注意事项

1. 大文件处理可能需要较长时间，请耐心等待
2. 批处理时，空文件或小于10行的文件将被自动跳过
3. Identity 标准化基于预定义规则，未匹配的值将标记为 "Unknown"
4. 建议在处理前先预览数据以确认变量映射正确
5. 处理过程中请不要关闭浏览器或刷新页面

## 技术要求

- R 版本 >= 4.0
- 必要 R 包：shiny, dplyr
- 现代网页浏览器（Chrome, Firefox, Safari, Edge）

## 数据安全

所有数据处理均在本地进行，不会上传到任何服务器。处理结果仅在用户会话中可用，浏览器关闭后数据将被清除。