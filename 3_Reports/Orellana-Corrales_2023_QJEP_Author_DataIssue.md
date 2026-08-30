# Orellana-Corrales_2023_QJEP — 原作者数据分析产物错误详细说明

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
