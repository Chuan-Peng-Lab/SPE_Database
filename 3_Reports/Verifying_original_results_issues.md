# Verifying original results issues — 作者原始结果验证问题记录

> **本文件用途**：统一记录「入库四方核对（论文 ↔ 作者代码/产物 ↔ 库内数据 ↔ 原始数据）中发现作者/OSF 原始产物与论文或数据不一致、或论文统计量无法复现」的问题。**后续遇到此类问题一律记录在此文件**（每个问题一个条目，含论文信息、问题描述、证据链、影响范围与处置），不再单独建文档。条目按发现时间顺序编号。

**通用处置原则**（与 SKILL.md §入库工作流·入库后四方核对一致）：
- 库内数据以原始数据为准重建并验证，作者产物问题**不影响库内数据**；
- 发现的问题按「可自动确定（有全文/数据证据）→ 修改；需人工 → 登记 PROJ_STATE 已知问题」处置；
- **是否联系作者由项目负责人决定**（超库范围不主动执行）；
- 核对脚本固化于 `2_Code/`（qjep_verify/、orellana2020_verify/ 等）。

---

# Issue 1 — Orellana-Corrales_2023_QJEP：作者 data_clean.csv 列错位（2026-08）

> **一句话结论**：OSF 官方仓库（osf.io/v8r2p）中作者的数据聚合文件 `data_clean.csv` 存在**列错位**（`in*` 与 `fm*` 两列互换），根源是作者脚本 `2-dataprep_mt.py` 的打印顺序与表头不一致；论文（QJEP 2023）匹配任务的全部统计量可**逐位精确复现自该错位文件**，导致论文两个主效应标签互换、两个中间格均值互换、非匹配试次 follow-up 方向反转、d′ 基于错位错误率计算。**本数据库（1_Data/Orellana-Corrales_2023_QJEP/）的数据自原始 PsychoPy 导出重建，正确无误，不受此问题影响。** SPE 定性结论在真实数据下依然成立。

- 论文：Orellana-Corrales, G., Matschke, C., Schäfer, S., & Wesslein, A.-K. (2023). Does an experimentally induced self-association elicit affective self-prioritisation? *Quarterly Journal of Experimental Psychology, 76*(9), 1379–1390. DOI: 10.1177/17470218221124928
- 数据仓库：OSF https://osf.io/v8r2p/（"Affective prioritization of self"）
- 核对时间：2026-08（阶段 5 入库后的全量四方交叉核对：论文 ↔ 作者代码 ↔ 库内数据 ↔ OSF 原始数据）
- 核对脚本：`2_Code/qjep_verify/`（part1_structure.py / part2_alignment.py / part3_stats.py / part3b_stats2.py / part4_dprime.py / part5_misc.py）

---

## 1. 背景

本研究为单一在线实验（Prolific 招募，native German speakers）：被试先学习几何形状与「self / furniture」的关联，再完成 IAT-RF（自我/家具 × 积极/消极）与匹配任务（Sui et al., 2012 范式）。匹配任务每被试 4 练习 + 140 实验试次，四条件（bed 编码）各 35 试次：`i_m`（自我-匹配）、`f_m`（家具-匹配）、`i_n`（自我-非匹配）、`f_n`（家具-非匹配）。

库内入库数据（`Orellana-Corrales_2023_QJEP_Exp1_raw/Clean.csv`，136 名 × 140 试次 = 19,040 行）由**每被试的 PsychoPy 原始导出**（`data_raw/v1~v8/*.csv`，136 个文件）重建，并经清洗脚本守卫与作者 `data_merged.tsv` **逐值全等**验证（subject 编号、bed、MT.corr、MT.rt）。作者的分析产物 `data_clean.csv` 仅用于核对，未入库。

---

## 2. 证据一：论文正文原文

### 2.1 方法部分 — 匹配任务设计与条件（论文 Methods, "Procedure" 段）

> "After the IAT-RF, participants conducted the matching task that had previously been used to demonstrate the cognitive SPE (e.g., Sui et al., 2012). … A geometric shape was presented with either the label "self" or "furniture" underneath and remained on the screen until the participant responded, or for a maximum of 1,500 ms. Participants were asked to press "D" if the presented combination was matching according to the instructions provided at the beginning of the experiment, and "K" if the combination was nonmatching. … An initial practice phase presented four trials, and was followed by 140 experimental trials to measure the SPE as established in the literature (Sui et al., 2012)."

（论文原文行 L95；匹配任务 = 形状-标签配对判断，四条件：self/furniture × matching/nonmatching，与 bed 编码 `i_m/f_m/i_n/f_n` 一一对应。）

### 2.2 结果部分 — 匹配任务统计量（论文 Results, "Matching task → Average RTs" 段）

> "A 2 (shape: self-associated vs. furniture-associated) × 2 (trial type: matching vs. nonmatching) within-participants ANOVA was carried out to analyse the RT data (see Figure 1). Both main effects of shape, *F*(1, 106) = **199.28**, *p* < .001, η²p = .65, and trial type, *F*(1, 106) = **77.08**, *p* < .001, η²p = .42, were statistically significant. The shape × trial type interaction, *F*(1, 106) = **111.13**, *p* < .001, η²p = .51, was significant as well."

> "The analysis on matching trials revealed a significant main effect, *F*(1, 106) = **255.76**, *p* < .001, η²p = .71, reflecting a significant SPE. In detail, RTs were faster when responding to matching self-associated shape–label pairs (*M* = **694**, *SD* = 91) than to matching furniture-associated shape–label pairs (*M* = **802**, *SD* = 103). The analysis on nonmatching trials also revealed a significant main effect, *F*(1, 106) = **5.90**, *p* = .017, η²p = .05. That is, RTs were faster when responding to nonmatching pairs of the self-associated shape and furniture-associated label (*M* = **779**, *SD* = 106) than to nonmatching pairs of the furniture-associated shape and self-associated label (*M* = **793**, *SD* = 100)."

（论文原文行 L125–L127；注意论文将 `199.28` 归为 shape 主效应、`77.08` 归为 trial type 主效应，并报告 matching 条件 furniture 均值 802 > self 694、nonmatching 条件 self 779 < furniture 793。）

### 2.3 结果部分 — d′ 敏感度分析（论文 Results, "Sensitivity measure d′" 段）

> "We followingly calculated the measure of sensitivity *d′* and submitted it to a single-factor (shape: self-associated vs. furniture-associated) ANOVA. The analysis revealed a significant effect, *F*(1, 106) = **4.63**, *p* = .034, η²p = .04, indicating higher sensitivity towards self-associated shapes (*M* = **2.34**, *SD* = 1.04) than furniture-associated shapes (*M* = **2.19**, *SD* = 1.08)."

（论文原文行 L131；d′ 由四条件错误计数 ER 计算，而 ER 列同样受错位影响。）

---

## 3. 证据二：原作者代码脚本

### 3.1 `2-dataprep_mt.py`（OSF "data and analysis/analysis code/"）— 聚合值与打印顺序

脚本按 bed 条件聚合四格均值/正确数/错误数，**打印顺序为 `mi → mf → ni → nf`**（即 `i_m, f_m, i_n, f_n`）：

```python
# 2-dataprep_mt.py（作者原文件，节选）
if dataLine["bed"] == "i_m":                       # 自我-匹配
    mi.append(int(dataLine["mt.rt"]))              #   -> mi
    ...
if dataLine["bed"] == "f_m":                       # 家具-匹配
    mf.append(int(dataLine["mt.rt"]))              #   -> mf
    ...
if dataLine["bed"] == "i_n":                       # 自我-非匹配
    ni.append(int(dataLine["mt.rt"]))              #   -> ni
    ...
if dataLine["bed"] == "f_n":                       # 家具-非匹配
    nf.append(int(dataLine["mt.rt"]))              #   -> nf

print(miart, len(mi), sum(mi), file = outputfile, end = " " )   # 第 1 组值（i_m）
print(mfart, len(mf), sum(mf), file = outputfile, end = " " )   # 第 2 组值（f_m）
print(niart, len(ni), sum(ni), file = outputfile, end = " " )   # 第 3 组值（i_n）
print(nfart, len(nf), sum(nf), file = outputfile, end = " " )   # 第 4 组值（f_n）
```

即输出列值顺序为：`[i_m, f_m, i_n, f_n]`。

### 3.2 但 `data_clean.csv`（OSF "data and analysis/data/"）的表头顺序是 `im → in → fm → fn`

```text
subject,Tukey_MT,YoB,Sex,Handedness,
imRTmean,imACC,imRTsum,      # 第 1 组表头（应=i_m）
inRTmean,inACC,inRTsum,      # 第 2 组表头（应=i_n）
fmRTmean,fmACC,fmRTsum,      # 第 3 组表头（应=f_m）
fnRTmean,fnACC,fnRTsum,      # 第 4 组表头（应=f_n）
imER,inER,fmER,fnER
```

**脚本值顺序（i_m, f_m, i_n, f_n）与表头顺序（im, in, fm, fn）不一致**：数据文件若直接保存脚本输出，则第 2 组值（f_m）被冠以 `in*` 表头、第 3 组值（i_n）被冠以 `fm*` 表头——**`in*` 列实为家具-匹配（f_m）值，`fm*` 列实为自我-非匹配（i_n）值**（`im*`、`fn*` 两列正确）。

> 注：脚本内另有次要缺陷——`miart` 等变量在无合格试次时沿用上一被试的值（subject 2/73 无合格试次时 `imRTmean` 残留上一被试 729/628 的值；subject 73 不在排除名单，残留值进入分析）。

### 3.3 SPSS 分析脚本 `3-Syntax.sps` 使用错位列

```text
* matching trials follow-up:
GLM imRTmean fmRTmean ...        # fm 列实为 i_n（自我-非匹配）值
* nonmatching trials follow-up:
GLM inRTmean fnRTmean ...        # in 列实为 f_m（家具-匹配）值
```

分析脚本本身正确（`im/fm` 为匹配条件、`in/fn` 为非匹配条件），但因输入文件 `data_clean.csv` 列错位，**输入给 `fm` 位置的是自我-非匹配值、输入给 `in` 位置的是家具-匹配值**。

---

## 4. 证据三：agent 检查结果

### 4.1 错位实证（逐被试逐值）

按作者口径（正确试次、RT>200 ms、<每被试 Tukey 上限 q3+1.5×IQR，hinge 法）自原始 PsychoPy csv 重算真实四条件均值，与 `data_clean.csv` 列值对比（抽查 subject 1）：

| 条件（bed） | 真实均值（原始数据重算） | data_clean.csv 列 | data_clean.csv 显示值 | 判定 |
|---|---|---|---|---|
| i_m（自我-匹配） | 729 | imRTmean | 729 | 一致 ✓ |
| f_m（家具-匹配） | 948 | inRTmean | 948 | **错位**（in 列装 f_m） |
| i_n（自我-非匹配） | 816 | fmRTmean | 816 | **错位**（fm 列装 i_n） |
| f_n（家具-非匹配） | 850 | fnRTmean | 850 | 一致 ✓ |

全样本 136 名中 134–136 名存在同类错位（核对脚本 part2_alignment.py 逐值验证）。

### 4.2 论文统计量的可复现性

用 **错位文件原样**（`data_clean.csv` 列值按其表头语义使用）可逐位精确复现论文全部匹配任务统计量；用**真实数据**（原始 csv 重算，107 名分析样本 = 136 − 29 名 Tukey 排除）复算结果如下：

| 论文报告（错位数据） | 论文归属 | 真实数据复算 | 说明 |
|---|---|---|---|
| F(1,106) = 199.28 | shape 主效应 | **74.66**（真实 shape 主效应） | 标签互换：199.28 实为 trial type 效应 |
| F(1,106) = 77.08 | trial type 主效应 | **195.90**（真实 trial type 主效应） | 同上 |
| F(1,106) = 111.13 | 交互 | 111.13 | 交互项不受错位影响 |
| F(1,106) = 255.76 | matching 内 shape 效应 | **120.80** | 真实值（含两中间格互换） |
| F(1,106) = 5.90, p = .017 | nonmatching 内 shape 效应 | **4.80, p = .031** | 方向反转（见 4.3） |
| F(1,106) = 4.63, p = .034 | d′ ANOVA | 基于错位 ER；真实口径 ≈ 100.27 | d′ 均值 2.34/2.19 无法由真实数据再现（±0.09 无标准变体） |

### 4.3 两中间格均值互换与 follow-up 方向反转

107 名分析样本的真实四条件均值（作者口径复算，本次复核：i_m=695 / f_m=779 / i_n=803 / f_n=795；核对 agent 报告 694/778/801/792，±3 ms 内一致）：

| 论文报告（错位数据） | 论文声称 | 真实数据 | 差异 |
|---|---|---|---|
| matching self = 694 | 自我-匹配 | 694 ✓ | 一致 |
| matching furniture = 802 | 家具-匹配 | **779**（真实家具-匹配） | 论文 802 实为自我-非匹配值 |
| nonmatching self = 779 | 自我-非匹配 | **803**（真实自我-非匹配） | 论文 779 实为家具-匹配值 |
| nonmatching furniture = 793 | 家具-非匹配 | 795 ✓ | 一致（±2 ms） |

**后果**：论文声称 nonmatching 条件下自我-非匹配（779）快于家具-非匹配（793）且显著（F=5.90, p=.017）——**方向反转**：真实数据中自我-非匹配（803）**慢于**家具-非匹配（795），且该非匹配 follow-up 效应接近显著但方向相反（F=4.80, p=.031，自我更慢）。

### 4.4 真实数据下 SPE 定性结论

真实数据下核心 SPE 仍成立：matching 条件 self（695）< furniture（779），差异显著（F=120.80）；交互显著。即论文的**定性结论**（自我关联刺激获得优先化）不受影响，但**具体统计量与中间格方向描述需要修正**。

---

## 5. 影响范围与处置

| 对象 | 影响 | 处置 |
|---|---|---|
| 本数据库 `1_Data/Orellana-Corrales_2023_QJEP/`（raw/Clean/subj_info/JSON/CSV 行） | **无影响**：数据自原始 PsychoPy 导出重建并逐值验证，正确 | 无需改动；本说明归档于 `3_Reports/`，并在 `Orellana-Corrales_2023_QJEP_Exp1.json` 的 `detail` 字段记录摘要 |
| 论文正文统计量（F 值、两中间格均值、nonmatching follow-up 方向、d′） | **受影响**：基于作者错位的 `data_clean.csv` | 建议联系作者核对并考虑勘误（2026-08 已向项目负责人报告；是否通知作者由项目负责人决定） |
| OSF 产物 `data_clean.csv` / `2-dataprep_mt.py` | 错误源头 | 建议作者修正脚本打印顺序并重跑；`2_Code/qjep_verify/part3b_stats2.py` 提供可复现的核查脚本 |

## 6. 核对脚本与文件索引

- 核对脚本：`2_Code/qjep_verify/`（part1_structure.py 结构扫描；part2_alignment.py 列对齐逐值验证；part3_stats.py / part3b_stats2.py 统计复现；part4_dprime.py d′ 排查；part5_misc.py Codebook/JSON 检查）
- 论文全文：`REF/Orellana-Corrales_2023_QJEP.md`
- 作者脚本：输入区 `Orellana-Corrales_2023_QJEP_raw/v8r2p-osfstorage-data-archive/`（data_clean.csv、data_merged.tsv、codebook .csv、data_raw/）；分析代码于 OSF "data and analysis/analysis code/"（1-mergeAndSubset.R、2-dataprep_mt.py、2-dataprep_iat.py、3-Syntax.sps、util.py）
- 库内数据：`1_Data/Orellana-Corrales_2023_QJEP/Orellana-Corrales_2023_QJEP_Exp1_{raw,Clean,subj_info}.csv`、`Orellana-Corrales_2023_QJEP_clean.R`


---

# Issue 2 — Orellana-Corrales_2020_ExpPsych：作者产物问题多项（2026-08-30）

 — 作者产物问题说明（2026-08-30 入库核对发现）

论文：Orellana-Corrales, Matschke & Wesslein (2020), *Experimental Psychology* 67(6), DOI 10.1027/1618-3169/a000502（dot-probe 提示效应 + IOR 研究，匹配任务为 manipulation check；本库只收录匹配任务 trial 级数据，dot-probe 不入库）。

库内数据（`1_Data/Orellana-Corrales_2020_ExpPsych/Exp{1,2,3}/`）经三重验证：① 每被试 128 试次守卫；② identity 自洽（匹配试次 shape 身份 == label 身份、非匹配相反，三实验一致率 1.0）；③ 与作者 LST 聚合逐值核对 0 差异（exp1_MT.lst 38 行、exp2_MT.lst 32 行、mt_data.lst 16 行可比部分）。**库内数据正确，本文件所述均为作者/OSF 侧问题。**

## 1. 作者编号录入错误（已按作者脚本修正）

E-Prime 的 Subject 号被误填为 Session 号（Study 3 = umv5p 存档）。作者自己的修正脚本 `participantSession.txt`（R 代码注释 *"Correct subject numbers entered as session numbers"*）：真实被试号 = Subject + Session − 1。36 个 session 文件 → 真实被试 1–36（dplocation_IOR-01-1 → 被试 1；dplocation_IOR-1-2..1-21 → 被试 2..21；dplocation_IOR-15-1 等 → 15、22–36），与论文 "36 participants completed Study 3" 吻合。Study 1/2（3ke4f 存档）文件名内 Subject 已唯一，无需修正。

## 2. OSF 上传的 mt_data.lst 是未修正编号的中间产物

`umv5p-osfstorage-archive/mt_data.lst` 仅 17 行（Subject = 1, 15, 22–36），其中 **Subject 1 行 = 未修正编号下 20 个 session 的合并聚合**（imACC=560 = 20×28、imRTsum=358371 等）。正确聚合应为 36 行。该文件与 `analysisSyntax.sps`（SPSS 分析读 mt_data.sav）不匹配：若按 17 行版分析，N=16（FILTER 排除 Subject 33），df=15，与论文 F(1,33) 不符——**作者实际分析用的 sav 版本未上传**（见 §5）。

## 3. 三份 LST 的 Tukey RT 上限口径不一致

作者 `util.py` 的 `tukey_all` 提供 q3+1.5×IQR 与 q3+3×IQR 两个上限；逐值核对实证：**exp1/exp2_MT.lst 用 1.5×IQR**（与论文 Methods "one and a half interquartile ranges" 一致），**mt_data.lst 用 3×IQR**（与上传脚本 `data_preparation_mt.py` 激活的 `grenze_type="grenze3_oben"` 一致）。三份产物口径不统一；论文 Methods 文本（1.5）与 Study 3 代码（3）亦不一致。库内核对按各产物实际口径进行（Exp1/2 用 1.5、Exp3 用 3），均 0 差异。

## 4. Study 2 排除名单未公开（已由 agent 枚举确定）

论文 Study 2 "33 completed, 2 excluded (dot-probe RT outliers) → N=31"，未公开编号；OSF 亦无 Study 2 的 SPSS 语法（3ke4f 仅有 exp1_analysis.sps）。agent 以 exp2_MT.lst 33 人聚合暴力枚举 33 选 2 排除组合（528 种），按论文三个统计量（matching F=29.72、nonmatching F=2.67、d' F=13.95）总差最小确定：**被排除者 = Subject 24 与 30**（总差 0.008，且 2×2 主效应 40.58/6.02/6.42 精确复现）。该结论已写入库内 Note。

## 5. Study 3 匹配任务统计量无法复现（作者分析数据版本不可考）

论文 Study 3 匹配任务报告 F(1,33)：shape 22.97、trial type 4.819、交互 28.88；matching 单因素 F=49.59（680.79 vs 830.94）；nonmatching F=0.54；d' F=5.99。**上述值无法从任何可得数据版本复现**：

- 按上传 mt_data.lst（17 行未修正版）FILTER 后 16 行分析：F = 18.4 / 3.26 / 32.84（df=15），matching 27.88、d' 3.37 —— 与论文不符；
- 按库内修正编号 36 人数据（作者口径 k=3、RT>200、ACC==1、round 均值）排除 6/33 后：**Subject 7、9、14 存在某格 0 个正确试次**（低表现被试：如 Subject 7 的 Ich-nonmatching 32 试次仅 4 个正确；任何过滤口径（含仅 ACC==1、无 RT 过滤）下均缺格），使 34 人无缺格分析不可能；枚举排除集（+7/9/14 子集）与过滤口径（k=1.5/3 × RT 下界 0/100/200）共 96 组合，均不匹配论文 F；
- 作者 SPSS 分析文件 `mt_data.sav`（analysisSyntax.sps 引用）**未上传**，其聚合口径（含缺格处理）不可考。

**结论**：论文 Study 3 匹配任务统计量基于一个未公开的数据版本；库内数据自洽且与作者上传聚合（16 行可比部分）逐值一致，**不受影响**。是否联系作者核实（如索要 mt_data.sav / 修正后的 36 行 LST）**由项目负责人决定**（与 QJEP 2023 列错位发现的处置模式一致）。

## 6. Study 2 Subject 34 原始导出缺失（edat2 only）

`exp2_rawData.zip` 含 32 名被试的 txt/edat2/XML 三件套 + Subject 34 的 **edat2 仅一份**（无 txt/XML）。edat2 为 E-Prime 二进制格式，无现成解析工具（pyedat2 不可安装），库内无法重建其 trial 级数据 → Exp2 raw/Clean/subj_info 均为 32 人（1–13、15–33）；作者 exp2_MT.lst 含 Subject 34 聚合（33 行）但缺其原始导出。已写入 CSV Note。

## 复现证据摘要（Exp1/2 全部精确，库内数据 = 论文统计量）

| 研究 | 统计量 | 论文值 | 复现值 |
|---|---|---|---|
| Exp1 (N=34) | shape / trial / int | 52.48 / 15.00 / 18.99 | 52.48 / 15.00 / 18.99 |
| Exp1 | matching F (686 vs 874) | 50.73 | 50.73 (685.82 vs 874.00) |
| Exp1 | nonmatching F (806.88 vs 858.12) | 7.68 | 7.68 |
| Exp1 | d' F | 28.95 | 28.95 |
| Exp2 (N=31, excl 24/30) | shape / trial / int | 40.58 / 6.02 / 6.42 | 40.58 / 6.02 / 6.42 |
| Exp2 | matching F (765.45 vs 934.10) | 29.72 | 29.72 |
| Exp2 | nonmatching F | 2.67 | 2.67 |
| Exp2 | d' F | 13.95 | 13.95 |
| Exp3 (N=34) | shape / trial / int | 22.97 / 4.819 / 28.88 | 无法复现（§5） |

核对脚本：`2_Code/orellana2020_verify/`（README 说明各文件用途与口径）。

---

# Issue 3 — Wang_2016_JEPHPP：作者聚合导出与论文统计量近似吻合但未精确复现；论文 df 与报告 N 不符（2026-08，2026-09-01 txt 核对后更新）

> **一句话结论**：论文（JEPHPP 2016）两个实验的匹配任务统计量可**方向性复现**；txt 核对后（2026-09-01）复现度大幅提升——**Exp1 match-RT F=43.02（论文 43.29，全 21 人即近似命中，相对差 0.6%）、Exp2 存在大量 20 人子集精确复现论文 F=17.35/3.93（排除名单不可唯一反推）**；论文全部统计 df(2,38) 隐含分析 N=20，与论文报告 N=21（Exp1）/N=20（Exp2）不符（Exp2 数据实为 25 人）。**库内数据按 txt 重建并经聚合 CSV 逐值验证（0 差异），Matching 判定与论文设计一致（规则 B 逐试次验证 0 违例）；残余统计差异疑为作者未披露的试次/被试排除细节，不改变 SPE 定性结论。**

- 论文：Wang, H., Humphreys, G., & Sui, J. (2016). Expanding and retracting from the self: Gains and costs in switching self-associations. *JEP: HPP, 42*(2), 247–256. DOI: 10.1037/xhp0000125
- 数据来源：作者 E-Merge 聚合导出 + 6 份 E-Merge txt（edat2 转换，`1_Data/Wang_2016_JEPHPP_Raw/` 输入区；**聚合 CSV ↔ txt 逐值核对 0 差异**，`2_Code/wang2016_verify/verify_merge_vs_csv.py`）
- 核对时间：2026-08（阶段 4 重建后核对）；2026-09-01（txt 转换后复核，统计口径：正式试次、规则 B match 集、正确试次 RT 均值、RM-ANOVA，`2_Code/wang2016_verify/verify_stats.R`）
- 背景：库内原 Exp1 五件套数据源错误（AssoMatc_Self 任务数据误作 Exp1，已归档 `*_Raw/AssoMatc_Self_archive/`），2026-08 由聚合导出重建 Exp1（21 人，编号 3-24 缺 23）与 Exp2（25 人，编号 1-25）

## 1. 问题描述

1. **论文 df 与报告 N 不符**：论文 Exp1 报告 21 名被试，但全部匹配任务统计 df 均为 (2,38)（隐含 n=20）；Exp2 报告 20 人、df(2,38) 一致——Exp1 的 21 人中疑有 1 人未纳入分析（论文未披露）。Exp2 数据 25 人 > 论文 20 人（排除名单未公开）。
2. **统计量复现（2026-09 txt 口径，正式试次）**：
   - **Exp1（21 人全样本）**：match-RT F=43.02（论文 43.29，近似命中）；match 错误 F=6.66（论文 7.65）；association 错误 F=3.23（论文 3.35）；mismatch 错误 F=0.14（论文 1.66，差异大，原因不明——疑试次级排除）；留一 20 人子集无法精确命中（RT 最接近 43.16=剔除 21 号，err 最接近 7.63=剔除 6 号）。
   - **Exp2（25 人全样本）**：match-RT F=22.57（论文 17.35）；match 错误 F=4.75（论文 3.93）；association 错误 F=0.045（论文 0.02）；mismatch 错误 F=3.66（论文 3.96，接近）。**全 53130 个 20 人子集扫描：存在大量子集精确复现论文 F（RT=17.35：731 个命中，最接近 17.3499，如排除 {4,7,9,23,25}；err=3.93：2087 个命中，最接近 3.9300，如排除 {1,4,7,14,24}）——论文 20 人分析样本与数据相容，但排除名单不可由数据唯一反推，且 RT/错误两分析的排除集不必相同**。
3. **Exp2 人口学不符**：数据 25 人 10 男/15 女（M=23.52）vs 论文 20 人 12 男——上传数据无法与论文分析样本对齐（20 人子集男数 ≤10 <12）。
4. **Exp1 前 9 行 practice 判定**：成立（9 条件各 1）；**Exp2 practice 行真实存在（9/被试，txt 验证），作者聚合 CSV 导出时丢弃**——库内 v2 数据已从 txt 补回（论文方法称两实验相同，与数据一致）。

## 2. txt 核对后的新发现（2026-09-01，均不影响库内数据正确性）

- **association 任务实现为 3AFC 选择**：形状 + 三个标签同屏（T1-T3 位置），键 b/n/m = 位置 1/2/3，CorrectAnswer = 正确标签（=形状初始指派身份）所在位置键；论文文字描述为 match/mismatch 判断（"choose which of the three labels matched the shape"——方法文字实为 3AFC，结果部分按 match/mismatch 表述）；Clean 的 association Label 由此逐试次恢复（全被试恒定映射 {Self:你, Friend:朋友, Stranger:生人}，0 违例），Matching 全为 Matching（3AFC 无失配试次）。
- **breaking 实际按键为 n/m**（论文写 Z/M 键；n/m 为相邻键，疑因中文键盘布局 Z 为输入法切换键）；match 键（Yes）每被试 counterbalance（n 或 m），YesNoResp 列记录。
- **Exp1 breaking 两程序版本**：breaking（TR4*，被试 3-10,24）与 breaking_mn（TR5*，被试 11-22），结构/列语义一致（Block=TRxBlockList.Sample、SubTrial=1-81）。
- **AssoMatc_Self ≠ 论文 control**：RawData_Baseline 31 人（2013-07~08 采集）任务结构 6 blocks×60+18 practice、匹配 50/50、每条件 40 试次 ≠ 论文 control（"与 Part 2 相同"：8 blocks×81、72/条件、1/3 匹配）；人口学 14 男/M=22.90/19-29 ≠ 论文 22 人 13 男/M=23.78/19-32。非论文 control，不入库（维持 2026-08 决策；背景详见下文 §4）。

## 3. 处置

- 库内 raw/Clean/subj_info 自 6 份 txt 重建（`Wang_2016_JEPHPP_clean.R` v2，聚合 CSV 逐值验证 0 差异），Matching = 规则 B（新指令映射：Exp1 self→stranger/friend→self/stranger→friend；Exp2 self→friend/friend→stranger/stranger→self），与论文设计一致，并用 txt 的 CorrectAnswer/YesNoResp 逐试次验证 0 违例；
- 统计差异已记录（本 Issue）；N 口径按数据（Exp1 21、Exp2 25）并记论文口径于 CSV Note；Exp2 分析样本不可唯一反推（见上）；
- **是否联系作者（排除名单/分析口径）由项目负责人决定**。

## 4. 背景与数据布局（原 `Wang_2016_JEPHPP_Stage4_Notes.md` 核心内容，2026-09-01 并入后该文件已删除）

> 2026-09-01 并入（原 `Wang_2016_JEPHPP_Stage4_Notes.md` 删除）：仅保留当前最重要的背景事实（任务设计、输入区布局、N 口径决策）；历史试错过程不记录。

### 4.1 论文与任务设计

- 论文：Wang, H., Humphreys, G., & Sui, J. (2016). Expanding and retracting from the self. *JEP: HPP, 42*(2), 247–256. DOI: 10.1037/xhp0000125
- 两实验 + 一个 control；每实验两阶段：
  - **Part 1 Association（学习）**：形状（S.bmp/C.bmp/T.bmp，counterbalanced 绑定）与身份标签配对学习；实现为 3AFC 选择任务（见 §2），学习到 6 连对/形状标准。
  - **Part 2 Breaking（切换匹配）**：按**新指派**判断 shape-label 对是否匹配；切换映射 Exp1：self→stranger、friend→self、stranger→friend；Exp2：self→friend、friend→stranger、stranger→self。**8 blocks × 81 = 648 正式试次（9 条件 × 72）+ 9 practice**；实际按键 n/m（论文写 Z/M，中文键盘布局原因）。
  - **Control（baseline，仅 Exp1 有）**：独立被试只接受 Part 2 指令后直接匹配判断；论文 N=22（13 男，19-32 岁，M=23.78）。
- 论文 N：Exp1 = 21（3 男，19-27，M=22）；Exp2 = 20（12 男，18-30，M=23.70）。

### 4.2 输入区布局（`1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_Raw/`）

| 路径 | 内容 | 备注 |
|---|---|---|
| `RawData_Exp1/` | SelfAssociate/breaking（TR4 版，被试 3-10,24）/breaking_mn（TR5 版，被试 11-22）edat2 + 3 份合并 txt（SelfAssociate/breaking/breaking_mn_merge_20260831.txt） | 论文 Exp1 原始导出；txt 为用户 2026-08-31 从 edat2 转换 |
| `RawData_Exp2/` | SelfAssociate + breaking edat2 + 2 份合并 txt | 论文 Exp2 原始导出 |
| `RawData_Baseline/` | AssoMatc_Self-{1-21,101-110} 31 个 edat2 + baseline_merge_20260831.txt | **非论文 control**（见 §2 新发现） |
| `Merge Data_Exp1 & Exp 2 & Baseline/` | 4 个二进制合并文件 + Baseline Merge Data/（Counter1-6.emrg2 等） | E-Merge 合并产物 |
| 4 份聚合 CSV | `Wang_2016_JEPHPP_Exp{1,2}_{Association,Switch}.csv` | 作者 E-Merge 导出；2026-08 重建原数据源，现作逐值验证基准（与 txt 0 差异） |
| `AssoMatc_Self_archive/` | 原库内错误 Exp1 五件套（AssoMatc_Self 数据） | 归档，勿删除 |

要点：聚合 CSV 的 Identity 列 = 形状的 Part 1 身份（与 association 数据一致，逐被试固定）；Exp1 Label 大写（Self/Friend/Stranger）、Exp2 小写（self/friend/stranger）；聚合 CSV 无 Block/Trial 序号列、无 CorrectAnswer；Exp1 Switch 每被试前 9 行为 practice、Exp2 Switch 的 practice 行被导出丢弃（txt 有，9/被试）。

### 4.3 原 Exp1 五件套数据源错误（已更正）

原 `Wang_2016_JEPHPP_Exp1_raw.csv`（→ Clean → subj_info）曾误用 **AssoMatc_Self 任务**数据（31 人，编号 1-21+101-110，2013-07~08 采集，含 person+reward 刺激参数，与论文三实验均不符）——已归档至 `*_Raw/AssoMatc_Self_archive/` 并重建（2026-08）。**AssoMatc_Self 数据真实归属未确认**（可能是作者另一研究/未发表数据），保留输入区存档，不作任何实验数据（2026-09-01 txt 核对后仍无法判定）。

### 4.4 N 口径与决策记录（用户 2026-08 确认；2026-09-01 复核维持）

| 实验 | 数据口径（库内） | 论文口径 | 决策 |
|---|---|---|---|
| Exp1 | 21（3 男/18 女） | 21（3 男/18 女）一致 ✓ | 无冲突 |
| Exp2 | 25（10 男/15 女） | 20（12 男）分析，无排除名单 | **数据口径 25**，Note 记 Paper_N: 20 |
| control | 不入库（2026-09-01 复核：AssoMatc_Self 31 人非论文 control，结构/人口学/时间三重不符） | 22 | **整行不入库**；31 人保留输入区存档 |
| AssoMatc_Self | 非论文数据 | — | 保留输入区存档，不作任何实验数据 |

- CSV 行：Exp1 = ID 58（numTrials=648、Practice_Trial=9、numBlocks=8、Note 说明重建）；Exp2 = ID 89（新增行，Status=1，Paper_ID 留空——deprecated 列勿新建值）。
- 重建脚本：`1_Data/Wang_2016_JEPHPP/Wang_2016_JEPHPP_clean.R`（v2，2026-09-01 起从 6 份 txt 重建；守卫：行数/被试数/Matching 1:3/practice 行数/8 blocks×81/9 条件×72/规则 B 逐试次/人口学）；验证脚本 `2_Code/wang2016_verify/`（README 说明用途与口径）。
- 校验：validate_json_metadata（127 JSON）EXIT=0；validate_clean_csv 82 文件 0 ERROR/29 WARN。

---

# Issue 4 — Wozniak_2020_PLOS：作者 xlsx 聚合文件 face 身份编号错位；ER 列实为正确率；3 个 .dat 文件名与行内编号不一致（2026-08-31）

> **一句话结论**：OSF（osf.io/2q9w7）作者聚合文件 "Raw data - SelfBoostExp.xlsx" 的**身份编号体系不对称**——cue（标签）编号用固定内部码（1=You, 2=Neutral, 3=AntiYou），**face 编号却用槽号**（每被试 permutation 决定，σ(j)=「码 j 在 labelsREAL 排列中的槽号」），导致 perm≠1 的 32 名被试（perm0×20、perm2×8、perm3×4）其 9 组合 RT/ER、face 主效应（RT_0i）与派生区（RT_M/NM1/NM2）的**身份标签错位**；仅 perm1（40 人）正确。另：xlsx 的 "ER_" 列实际是**正确率**（非错误率，命名误导）；3 个 .dat 文件（1010/2008/2011）行内 SubNum 与文件名不一致（行内=1110/2004/2010，作者整理时重命名，xlsx 与文件名口径一致）。**库内数据自 .dat 重建、真实身份映射正确，不受影响**；论文描述的定性结论（方向核对）全部成立。

- 论文：Woźniak, M., & Hohwy, J. (2020). Stranger to my face: Top-down and bottom-up effects underlying prioritization of images of one's face. *PLOS ONE, 15*(7), e0235627. DOI: 10.1371/journal.pone.0235627
- 数据仓库：OSF https://osf.io/2q9w7（"Raw data - SelfBoostExp.xlsx" + DATA/SelfBoostExp_*.dat ×72 + MATLAB 聚合脚本）
- 核对时间：2026-08-31（阶段 5 入库后的四方核对：论文 ↔ 作者 MATLAB 脚本/xlsx ↔ 库内数据 ↔ .dat 原始导出）
- 核对脚本：`2_Code/wozniak2020_verify/`（verify_massive.py：复刻作者聚合并与 xlsx 逐值对比，3312 单元格 0 差异；方向核对见脚本 README）

## 1. 问题描述

1. **xlsx face 编号 = 槽号（permutation 决定），cue 编号 = 内部码**：作者聚合脚本（Massive_SelfBoost_Avg1subject_MAD_full.m）将标签编号为 You=1/Neutral=2/AntiYou=3（固定），而 xlsx 的 face 列编号为「码 j 在 labelsREAL 排列中的槽号」σ(j)（perm0: [2,1,3]、perm1: [1,2,3]、perm2: [2,3,1]、perm3: [3,1,2]）。因此 xlsx 的 RT_ij = 真实组合 (label 码 i, face 码 σ(j))；RT_0i = face 码 σ(i)；派生区 RT_M_i = 组合 (i, σ(i))（对 perm≠1 不是真实匹配组合）、RT_NM1_i = label 码 i & face 码≠σ(i)、RT_NM2_i = face 码 σ(i) & label 码≠i。证据：72 名被试全部 3312 个 xlsx 单元格按此规则逐值复现（±0.01 ms / ±0.001），按任何其他映射均有数百处不符。
2. **xlsx ER 列为正确率**（作者命名 ER 误导）：如 ERR_TOTAL=0.9815 = 265/270 正确；且 ER 区按「正确且 RT 有效（200<RT<1500 ms）」计数（作者脚本 data(:,11)==1 过滤）。
3. **作者脚本 RT 过滤 = 硬编码 1500 ms**，与论文文字「2.5 median absolute deviations (MAD) over the median」**不一致**（脚本中 highestRT 计算后立即被覆盖为 1500）；xlsx 聚合基于 1500 ms 口径。
4. **3 个 .dat 文件名与行内 SubNum 不一致**：SelfBoostExp_1010.dat（行内 1110）、2008.dat（行内 2004）、2011.dat（行内 2010）——作者整理时重命名以区分重复编号；xlsx 被试列表与**文件名**口径一致（1010 与 1110 并存）。库内以文件名为被试 ID，行内值保留于 raw（SubNum 列）。
5. **影响**：论文 Table 1（图片）与 Fig 2–4 的 target 均值可能基于错位标签（无法直接核对——论文描述统计为图片）；论文 target 主效应 ANOVA 对 perm≠1 被试标签错位敏感（32/72）。论文正文全部**方向性结论**已按真实身份核对成立（见 §3）。

## 2. 处置

- 库内 raw/Clean/subj_info 自 72 个 .dat 重建（`Wozniak_2020_PLOS_clean.R`），身份映射按论文语义（Exp1: You=Self, 其余 Stranger；Exp2: AntiYou=本人脸=Self；Exp3: You=自关联陌生脸=Self、AntiYou=本人脸=Self），不受 xlsx 错位影响；
- 作者聚合逐值复现（3312 单元格 0 差异）证明解析正确；描述性统计方向核对（论文口径 200<RT<1500）全部通过；
- **是否联系作者（xlsx 错位是否进入论文统计/表格）由项目负责人决定**。

---

# Issue 5 — Zhang_2023_NeuroImage：OSF 共享 subject 级文件与论文分析样本口径不一致；trial 级数据未共享（2026-08-31）

> **一句话结论**：OSF 仓库（osf.io/hbrus）全量存档**无 trial 级数据、聚合文件（348 行）无被试 ID**；从 git 历史恢复的原始 subject 级文件（347 人，与库内 subj_info 逐值一致）与论文分析样本（348 人，182F/166M，18–34 岁）在 **N 与人口学上不一致**（数据 174F/172M/1 空、Age 0–36 含 0/36 异常值）——作者共享的 subject 文件 ≠ 论文分析样本组成（推断：论文 348 含约 8 名未共享 trial 数据的被试；库内 7 名无有效数据者属论文排除者）。库内 Clean 的 SPE 复算（stranger-match − self-match RT，正确试次）与 OSF SPE_score 分布吻合（mean 98.7 vs 95.0，sd 71.9 vs 70.7），证明库内 trial 数据与论文聚合 SPE 同源，**库内数据不受影响**。

- 论文：Zhang, Y., Wang, F., & Sui, J. (2023). Decoding individual differences in self-prioritization from the resting-state functional connectome. *NeuroImage*, 120205. DOI: 10.1016/j.neuroimage.2023.120205
- 数据仓库：OSF https://osf.io/hbrus/（全量存档 2026-08-31 下载：data/ 聚合行为+FC 矩阵、data/external_dataset/ 老年外部验证样本聚合、codes/、output/）
- 核对时间：2026-08-31（全量 OSF 存档复核 + git 历史源文件恢复 + SPE 公式复算）
- 核对脚本：本会话 Python 比对（SPE 复算逻辑见 PROJ_STATE 对应条目；无固化脚本）

## 1. 问题描述

1. **OSF 存档无 trial 级数据、聚合文件无被试 ID**：`all_behavioural_data.xlsx`（348 行：SPE_score/age/gender/FD_Jenkinson/independent_self/interdependent_self）与 `SPE_score.npy`/`covariate_*.npy` 无任何 ID 列，无法按被试对位；全库无匹配任务 trial 导出（与阶段 4 豁免结论一致）。
2. **共享 subject 级文件与论文样本不一致**：git 历史恢复的 `Zhang_2023_NeuroImage_Exp1_raw_Subject.csv`（347 人）与库内 subj_info **逐值一致（0 差异）**，但人口学与论文不符——性别 174F/172M/1 空 vs 论文 182F/166M；年龄 0–36（389 号 Age=0、90 号 Age=36）vs 论文 18–34。N 差 1（348 vs 347）。
3. **库内数据结构**：Clean 346 = 源 347 − Subject 101（有人口学、无 trial 行）；340 人有可用数据（142/211/385/413 全无反应 RT=0、402 仅 11/112 正确、62 为 1 行全 NA 占位）→ 论文 348 分析样本应含约 8 名未共享 trial 数据的被试。
4. **SPE 公式复现（分布吻合，无法逐值对齐）**：OSF SPE_score（n=348，mean 94.98，sd 70.72，range −170.8–311.4）≈ Clean 复算 stranger-match − self-match（正确试次，mean 98.74，sd 71.85，range −182.7–317.5）；~4 ms 差来自作者预处理脚本的 RT 过滤（脚本未上传 OSF），故 2 位小数逐值对位仅 17/340 命中，无法由此识别缺失被试。

## 2. 处置

- 库内数据正确：subj_info = 原始 subject 源文件逐值一致；Clean 为最小预处理（无过滤）；SPE 分布可复现 → 数据管道无错误；
- CSV 行（ID 53）N 口径已按数据口径收口：346/346/0（Paper_N 记 Note）；原始 subject 源文件已恢复至输入区存档；
- trial 级 raw 豁免维持（OSF 无 trial 数据；原 trial 级 raw 从未入 git，不可恢复）；
- 遗留：OSF 聚合无 ID，论文 348 与数据 347 的差 1 无法精确对位；**是否联系作者（subject 文件与论文样本组成差异、trial 数据可否共享）由项目负责人决定**。

---

# Issue 6 — Qi_2025_SciData：论文文字 "square" vs 数据文件 rectangle.png（2026-08-31）

> **一句话结论**：论文 Methods 描述 SLM 任务三形状为 "circle, square, and triangle"，而逐被试 PsychoPy 导出的 `shape` 列实际为 `circle.png` / `triangle.png` / `rectangle.png`（三值严格等量：各 16080 次 / 48,240 正式试次）。形状-身份绑定为逐被试 counterbalance（12 组），数据内部自洽（清洗守卫全过）。库内 Shape 列以数据文件名为准（circle/triangle/rectangle）；该差异仅刺激命名不一致，不影响任何统计量。

- 论文：Qi, Y., Zou, F., Chau, X. Y., Zhou, M., Wang, F., & Sui, J. (2025). A Comprehensive Dataset for Investigating the Structure of Self-Bias. *Scientific Data, 12*(1). DOI: 10.1038/s41597-025-06035-z
- 数据仓库：OSF https://osf.io/3h95f（DOI 10.17605/OSF.IO/3H95F；数据 CC BY 4.0）
- 核对时间：2026-08-31（阶段 5 入库核对）
- 核对脚本：`1_Data/Qi_2025_SciData/Qi_2025_SciData_clean.R`（内嵌守卫）

## 1. 问题描述

论文 Methods（SLM 段）："participants learned to associate three geometric shapes (circle, square, and triangle) with three named identities"。134 个逐被试导出（各 381 行 = 2 元数据行 + 练习 + 360 正式试次）的 `shape` 列取值仅三值且严格等量：`circle.png` 16080、`triangle.png` 16080、`rectangle.png` 16080（全部 48,240 正式试次）。即论文文字 "square" 对应数据文件 "rectangle.png"。

## 2. 处置

- 库内数据以数据文件为准：Clean Shape 列 = circle / triangle / rectangle（去扩展名）；身份映射按 `shape_identity` 码（1/2/3），与形状名无关；
- 差异已记录于 exp JSON detail（`Qi_2025_SciData_Exp1.json`）与 Dataset_inf.csv Note 列；
- 无统计量受影响（形状名仅为刺激标签；匹配关系由 label_identity/shape_identity 码承载）；
- **是否联系作者说明由项目负责人决定**（当前不主动联系）。

---

# Issue 7 — Golubickis_2021_ActaPsych：论文 Appendix B 单个 RT SD 单元格无法复现（2026-08-31）

> **一句话结论**：论文（Acta Psychologica 218:103350）Appendix B 的 Exp1「self / mixed / nonmatching」单元格 RT SD 报告为 112 ms，库内数据复算（被试均值 SD）为 122.5 ms；该单元格 RT 均值（737 vs 736.6）与正确率（80 (17.8) vs 80 (17)）完全一致，且论文 Appendix B/C 其余 **23/24 个单元格（RT 均值/SD、正确率均值/SD）全部逐位复现**（±1 ms / ±1 pp 内）。单一 SD 单元格差异无统计影响，库内数据管道无误。

- 论文：Golubickis, M., & Macrae, C. N. (2021). Judging me and you: Task design modulates self-prioritization. *Acta Psychologica, 218*, 103350. DOI: 10.1016/j.actpsy.2021.103350
- 数据仓库：OSF https://osf.io/8bktn/（MoD_full_E1.csv / MoD_full_E2.csv / Analysis.R；项目未设置数据许可）
- 核对时间：2026-08-31（阶段 5 入库核对）
- 核对脚本：`1_Data/Golubickis_2021_ActaPsych/Golubickis_2021_ActaPsych_clean.R`（内嵌 Appendix 复现守卫，该单元格 SD 容差放宽至 15 并注释原因）

## 1. 问题描述

Appendix B（Exp1）报告 12 个单元格的 RT 均值 (SD) 与正确率 (SD)，均为被试均值口径（mean of per-subject cell means）。从 MoD_full_E1.csv 复算：

| 单元格 | 论文 RT 均值 (SD) | 复算 RT 均值 (SD) | 差异 |
|---|---|---|---|
| self / mixed / nonmatching | 737 (112) | 736.6 (122.5) | 均值 −0.4 ms；SD +10.5 |
| 其余 11 个单元格（Exp1） | — | — | 均值 ±0.5 ms 内、SD ±0.6 内 |
| 全部 12 个单元格（Exp2, Appendix C） | — | — | 均值 ±0.8 ms 内、SD ±0.6 内 |

SD 差异排查：无单个被试剔除可使 SD 变为 112（剔除最极端被试仅至 108.7/110.0）；「正确试次 ≥10/≥20」等排除规则亦无法同时保住均值 737 与 SD 112（如 n_correct≥10 时 SD=110.4 但均值升至 746.0）；总体 SD（population）为 120.4 亦非 112。该值疑为作者制表笔误或基于略异的数据版本，无法由任何简单规则复现。

## 2. 处置

- 库内数据以原始文件为准（附录其余全部单元格复现，证明文件即分析数据）；唯一 SD 差异不涉及任何结论（论文相关统计量方向全部验证通过：mixed > blocked、self 最快最准、SPE RT mixed 63/55 ms、blocked 26/11 ms 均复现）；
- 差异已记录于 exp JSON detail（`Golubickis_2021_ActaPsych_Exp1.json`）；
- **是否联系作者说明由项目负责人决定**（当前不主动联系）。
