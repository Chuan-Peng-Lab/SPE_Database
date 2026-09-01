# 工具与脚本参考（附属参考文件 — 按需读取）

本文件是 `SKILL.md` 的附属参考：执行特定工具/脚本任务时按需读取。主文件「工具与脚本」节保留各工具的一句话定位，细节在此。

## 清洗工具三套并行实现（逻辑一致）

- `2_Code/Clean_Data.Rmd` — 逐论文手工管线（**历史权威/配方参考**）；按论文逐个清洗，含旧文件夹名注释（历史记录，不改）。**已降级**：agent 自动化入库不再以它为主路径，其逐研究段逐步提取为独立脚本/配置；仅作为独立清洗脚本的配方参考。
- `2_Code/SPE_Interactive_Clean_V3.R` — 控制台交互清洗（单个/批量 `*_raw.csv`，变量映射 + Identity 标准化）。人工备用。
- `2_Code/SPE_Shiny_App_V4.2.R` — Shiny 网页版（交互界面、批量处理、ZIP 下载）。人工备用。
- 三者产出相同的标准化列（`Subject/Shape/Label/Matching/ACC/RT_ms` + 三级 Identity）与 `*_ExpN_Clean.csv` 命名；**清洗 = 最小预处理，不过滤**（见主文件「数据标准化」）。

## 独立清洗脚本（`<Study>_clean.R` — 主路径）

从 Clean_Data.Rmd 提取独立清洗脚本的规范（2026-08 起先例：`Sui_2015_unpub_clean.R`）：

- 内嵌脚本依赖的辅助函数（如 read.mat），不依赖 Rmd 上下文；开头注释写明来源行号与相对原版的修改点。
- 路径用脚本所在目录的相对路径，并修正 Rmd 中的失效路径（旧文件夹名）；脚本内做工作目录自适应（Rscript 的 `--file=` 参数）。
- 输出 `*_Clean.csv` 带一致性守卫（如 stopifnot 行数/被试数）；行尾 CRLF/LF 差异直接无视，不做转换。
- 排除已确认的问题被试（如测试运行）时，在脚本注释中写明证据（内部编号/默认人口学/按键反转等）与依据条目（PROJ_STATE.md 已知问题）。
- 修改数据文件后同步更新同目录 subj_info、Dataset_inf.csv（字节保真）与 codebook；Clean_Data.Rmd 对应段如需同步修改，diff 应只含目标改动。

### Subject 编号与数据对齐规则（2026-08 阶段 3 沉淀，Vicovaro_2022_JEPHPP Exp2 教训）

1. **编号只承载唯一性，条件信息由数据列承载**：Subject 编号不编码 block/条件（Symmetry/Matching 等由 Clean 数据列表达）。raw participant_id 重复（多段/跨 block 共用同一 ID）时，统一按段号加后缀 `_1`/`_2`…，不引入条件后缀分支（如不写 `_selfS`/`_selfA`）；条件归属查数据列即可。
2. **重复 ID 判定看"该 ID 总段数 > 1"，而非当前段号**：凡 participant_id 名下段数 > 1 → **所有段**都加段号后缀（不能只给后段加，否则第一段不唯一）；守卫 `stopifnot(length(unique(Subject)) == 预期被试数)`。
3. **subj_info 与 Clean 的 Subject 对齐用键，不用行序**：构建期保留临时映射列（如 `Subject_raw = participant_id|block|seg_no`），subj_info 人口学按映射键对齐；**禁止依赖文件行序**（行序脆弱，键稳定）。写出 Clean 前删除临时列。
4. **构建期中间映射内嵌脚本，不落盘独立文件**：Subject↔原始 ID 映射由脚本内存对象生成，明细写入脚本注释；研究文件夹只允许标准产物（raw/Clean/subj_info/Codebook/JSON + `<Study>_clean.R`），不产生 subject_map 等中间 CSV。

### 通用函数与独立脚本同库

独立清洗脚本与 `1_Data/utils.R`（`spe_root`/`write_clean_csv`/`read_dataset_inf`/`read_eprime_txt`/`parse_header`/`parse_matching_blocks`）同在 `1_Data/` 下，`source()` 同库引用，**不跨文件夹引用**（不要放 2_Code/ 再跨层 source）。

## 主索引读取（`2_Code/read_dataset_inf.py`）

- 统一封装 BOM/引号/列名定位：`from read_dataset_inf import read_dataset_inf, find_rows`；
  `find_rows(rows, Folder_Name, exp=...)` 按关键 ID 过滤。CLI：`python 2_Code/read_dataset_inf.py [--folder NAME] [--exp N]`
- R 侧：`source("1_Data/utils.R"); inf <- read_dataset_inf()`
- 完整读取模板见主文件「主索引 Dataset_inf.csv」§读取模板。

## 辅助工具（2026-08 新增，2_Code/）

### `repo_fetch.py` — 数据仓库下载辅助（OSF / PsychArchives）

子命令：`osf-list` / `osf-get`（按文件名子串匹配下载）/ `pa-search` / `pa-files` / `pa-get`。
用法见脚本 docstring。纪律：

- 先列文件清单再下载，目标已存在拒绝覆盖。
- P5 沉淀：先 `--list` 可发现仓库重复上传/缺失，避免白下载。
- **2026-08 端点修复**：OSF 下载一律用 `osf.io/{guid}/download`（文件 GUID 取自 API `attributes.guid`）；`api.osf.io/v2/files/{fid}/download` 已失效（404），`osf.io/{24hex-fid}/download` 会落到 SPA 页面——osf-get 已按此实现，勿回退。
- 已知缺陷（用户指示暂不修复）：osf-list/osf-get 存在 OSF API 分页缺陷（默认每页 10 条、未翻页，145 文件曾被误列为 11 个）——大批量仓库先确认文件数再下载。

### `scan_raw.py` — 原始数据快速扫描

列名/行数/每被试行数（整除判定）/列值分布/两列交叉表；大文件用 `--sample N`（行数与被试统计仍全量流式）。阶段 4 判定 raw 完整性（如 Smith 48 vs 59）与还原任务结构用。

### 其他工具

- `2_Code/make_codebooks.R` — Codebook 模板生成（单 Sheet1 4 列、枚举值取数据 unique 含特殊码），改 `jobs` 列表复用。
- `2_Code/analyze_csv_blanks.py` — 重扫 Dataset_inf.csv 空白基线。
- `2_Code/validate_json_metadata.R` / `validate_clean_csv.R` — 两级校验器（规则见主文件「校验与卫生」）。
- `2_Code/migrate_exp_json_to_v2.py` — v1 flat `table` → v2 hierarchical 一次性迁移；仅当旧文件重现时重跑。
- 各研究核对脚本目录（四方核对固化）：`2_Code/qjep_verify/`（Issue 1）、`2_Code/orellana2020_verify/`（Issue 2）、`2_Code/wozniak2020_verify/`（Issue 4）、`2_Code/hobbs_verify/`（Table 2 全量复现，最后一例）、`2_Code/mcivor_verify/`（d′ 描述性核对）。

## REF 全文转换管线（`REF/`）

- `REF/html2Json.py`（HTML→JSON，适配 Springer/Elsevier/Wiley/eLife/MDPI/Collabra/SAGE/PLOS 8 模板；`--force` 全量）+ `REF/json2md.py`（JSON→MD）+ `REF/pdf2md.py` 备用。
- 用法与验收清单见 `REF/README_html2md.md`（全文正文归属该文件，此处仅指针）。
- 转换优先自动管线；Wiley/SAGE 页面 meta 缺失 → Crossref 补 `METADATA_OVERRIDES`；BMC 参考文献是 `<ol>` 非 `<ul>`；PDF 双栏交错为源版式固有边界（DeepSeek `_DS` 版更优）；pdf2md 自动跳过已有 md 的 PDF。
