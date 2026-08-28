# Stage 3.1 四方交叉复核差异表（进行中）

对应 PROJ_STATE.md「阶段 3.1：无问题条目独立复核」。以 REF/ 全文 + paper/exp JSON + Clean 数据为权威来源，逐字段比对 Dataset_inf.csv 现值。

**方法**：每研究输出差异表（字段 | CSV | JSON | Clean | 全文 | 清洗代码 Rmd | 判定）。差异分级：可自动确定（数据侧错误）→ 待统一批量修改；需人工 → 登记待确认；口径/语义差异 → 登记。**复核阶段只读不改**，全部 21 研究完成后统一批量修改。

**状态**：样板 3 个（Amodeo / Constable_2019 / Liang）已完成并附清洗代码核查；剩余 18 个待推进（用户确认样板方法后）。

---

## 清洗代码核查结论（2_Code/Clean_Data.Rmd，2026-08）

对样板 3 研究逐一核查原始清洗代码，判定疑点归属：

1. **清洗代码解释的疑点（数据形态本身，非错误）**：
   - Amodeo `Bekende→Friend→Close` 三级映射为清洗代码明确映射（Rmd L3112-3123）；清洗**无被试过滤**，故 Clean 保留全部 67 人（含论文排除 1 人）——符合「清洗=最小预处理」原则。
   - Constable Exp3 `Label_Origin` 二分类（Self/Stranger）源于清洗代码 case_when（Rmd L1654-1659），与 Exp1/2 的 `Label_Origin_Identity = Label`（4 值）**清洗模式不一致**；且 Exp3 `Shape_Origin_Identity = Label`（Rmd L1624）疑为复制粘贴（raw 两列同值故结果相同，但语义应为 Shape 列）。
   - Constable Exp4 `Subject = Pair.Number`（Rmd L1691）——pair 粒度是清洗代码的明确选择；Person1/Person2 均→"Individual_Self"（Rmd L1709-1710），**Self vs Coactor 的区分在 Clean 侧丢失**（论文分析明确区分二者，L189）。
   - Liang 三个组文件由三个 chunk 按 `group` 过滤生成：Exp1.1=dlpfc(35)、Exp1.2=sham(36)、Exp1.3=psts(38)（Rmd L2616/L4723 段/L4793），35+36+38=109 ✓。
2. **清洗代码无法解释的疑点（元数据层错误/遗漏，需修改或人工）**：
   - CSV 数值错误：Constable Exp3 Female、Exp4 Female；Liang Drop_Subj/Valid_Subj（数据 109 人全在，无全文排除依据）。
   - CSV/JSON 元数据缺失或口径：numBlocks=0、Environmental_Info 空、Setting 违反受控词表、numTrials 口径不统一（per-block vs total）、Constable Exp4 Practice_Trial 口径（训练 50 vs 匹配 practice 21/41）。
   - 结构问题：Liang CSV 3 行 vs 3 组×2 阶段；Exp1_Clean 在 Rmd 无生成 chunk（历史遗留，与 Exp1.1 内容同）。

---

## 样板 A：Amodeo_2024_CABN（A 类单实验平铺，1 行）

| 字段 | CSV | JSON | Clean/raw | 全文 | 清洗代码 Rmd | 判定 |
|---|---|---|---|---|---|---|
| numBlocks | **0** | 6 blocks | Block 1–6 | L60 六块×60 | —（元数据） | **可改 CSV→6** |
| Environmental_Info | **空** | Software=E-prime 2.0.10.248 | — | L60 E-prime | — | **可改 CSV→补** |
| exp JSON Setting | — | **"Electrically shielded chamber"** | — | L70 chamber | — | **可改 JSON→Laboratory**（违规词表） |
| Repo_Link | **论文 DOI** | — | — | L156 仅 request | — | **需人工**：无数据仓库，填论文 DOI 语义错误 |
| Valid_Subj | 66 | — | 67 被试 | L46 行为样本 66 | 无被试过滤（67 全留） | **需人工**：Clean/subj_info 67 含 1 名论文排除的 ASD（低于机会）；subj_info Autism 37 vs 全文 36 |
| Sample_Size / Male / Female | 70 / 49 / 21 | Summary 32+27=59(EEG) | — | L44 入组 70(39ASD+31NT) | — | 一致（59=EEG 样本，摘要原话） |
| Identity 标签 | Self/Close-Others/Stranger | — | Bekende→Friend→Close | L58 论文称 **vriend** | L3114/L3121 明确 Bekende→Friend | **登记**：数据用词 Bekende vs 论文 vriend；映射为清洗代码明确选择，保留 |
| numTrials / Practice / 刺激参数 / License / Country / City / Matching / ACC | 360 / 24 / 同全文 / On request / Belgium / Ghent / 0,1 | 一致 | 每被试 360 行 | 一致 | 一致 | 一致 |

**样板 A 小结**：可改 CSV 2 处 + JSON 1 处；需人工 2 处（Repo_Link、N 口径）；登记 1 处（Bekende/vriend）。

---

## 样板 B：Constable_2019_JEPHPP（B 类多实验子文件夹，4 行）

| 字段 | CSV | JSON | Clean/raw | 全文 | 清洗代码 Rmd | 判定 |
|---|---|---|---|---|---|---|
| Exp3 Female | **14** | — | subj_info 20F+8M | L143 仅报 8 male | —（subj_info 独立） | **可改 CSV→20** |
| Exp4 Female | **14** | — | subj_info 性别全 "/" | L173 "14 male and **26 female**" | — | **可改 CSV→26** |
| Exp4 Sample/Valid | **40/40** | — | **Clean 20 Subject=20 pairs** | L173 20 pairs (40 人) | L1691 `Subject=Pair.Number` | **需人工**：pair 粒度（40 人→20 pair），论文分析按 Match/Mismatch responder 分组 t(19) |
| Exp4 Self vs Coactor | — | — | Person1/Person2 均→Self | L189 区分 Self vs Coactor | L1709-1710 均→Individual_Self | **登记**：Clean 无法区分 Self 与 Coactor（清洗代码选择） |
| numTrials | **96/80 (per-block)** | 96/block (288 total) | 每被试 288/640 行 | L74/L181 3×96、8×80 | — | **需人工**：per-block vs total 口径库内不统一（Amodeo=360 total） |
| Exp4 Practice_Trial | **50** | "21 or 41" | — | L179 训练 50 + L181 practice 21/41 | — | **需人工**：CSV 填训练 50，匹配 practice 21/41 |
| Self/Close/Others | Self=Self **Close=We** Others=They/Alone | — | We→Group-Self→**Self** | L91/L95 Me+We=Self-referential | L1496-1507 We→Group-Self→Self | **需人工**：CSV Close=We 误填（we 是 group-self 非 close other）；Exp4 Close=Team 同理 |
| exp JSON Setting ×4 | — | **"/"** | — | CEU 实验室面测 | — | **可改 JSON×4→Laboratory** |
| exp JSON Location ×4 | — | **"/"** | — | L38 CEU Budapest | — | **可改 JSON×4→CEU** |
| Exp1-3 Environmental_Info | 空 | Software="/" | — | 论文未披露软件 | — | **需人工**：留空 or "/"？ |
| Exp3 Label 粒度 | — | — | Label_Origin 仅 Self/Stranger | L95 label 二分类 | L1654-1659 case_when 二分类 | **登记**：与 Exp1/2 4 值模式不一致（清洗代码编写差异）；raw 有细粒度 Label 列 |
| Exp4 Label 粒度 | — | — | Person1/P2/Team→Self | — | L1721-1727 case_when | **登记**：同上 |
| ACC=3 | — | — | 0/1/3 | too slow 提示存在 | — | **登记**：Codebook 未解释 3（E-Prime 惯例=no response） |
| License / Note | No License / Pair Number | — | — | L89 OSF 数据 | — | **登记**：License 待 OSF 确认；Note 语义不明 |
| 一致项 | N 28×3/40、Male 12/6/8/14、Drop=0、numBlocks 3/8、Practice 20、Design=2×2、Hungarian/English、刺激参数、Repo_Link=osf.io/sejw7/ | 一致 | 一致 | 一致 | — | 一致 |

**样板 B 小结**：可改 CSV 2 处 + JSON 8 处（4 Setting+4 Location）；需人工 5 处（pair 粒度、numTrials 口径、Practice_Trial、Self/Close/Others 语义、Environmental_Info）；登记 5 处。

---

## 样板 C：Liang_2022_HumBrainMap（C 类特殊平铺，3 行）

| 字段 | CSV | JSON | Clean/raw | 全文 | 清洗代码 Rmd | 判定 |
|---|---|---|---|---|---|---|
| 行结构 | **3 行 Exp1/2/3 各 Sample_Size=109** | exp JSON 仅 1 个 | 4 文件=3 组（Exp1=dlpfc?、Exp1.1=dlpfc、Exp1.2=sham、Exp1.3=psts） | L51 3 组×2 阶段 | 3 chunk 按 group 过滤 | **需人工**：实际=1 研究 3 组×pre/post，CSV 3 行结构无法对应 |
| Exp1_Clean 文件 | — | — | 与 Exp1.1 内容同（多 Session 列） | — | **Rmd 无生成 chunk** | **需人工**：历史遗留重复文件，待确认删除 |
| Drop_Subj / Valid_Subj | **1 / 108** | — | 109 人全在（35+36+38） | L51 109 招募，**无排除记录** | filter 仅按 group | **需人工**：108/1 无数据与全文依据 |
| Setting | — | "Laboratory setting" | — | — | — | **可改 JSON→Laboratory**（词表） |
| License / Repo_Link | CC BY-NC-ND / osf.io/u9ty6 **view_only** | — | — | L51 未提数据可用性 | — | **需人工**：数据许可/公开性待 OSF 确认（Human #4/#8） |
| 一致项 | N=109、Male 50/Female 59、numBlocks 6、numTrials 360、Practice 达标式 NA、Environmental_Info=E-prime2.0、Design=3×2×3、English、Friend→Close | 刺激参数一致 | 一致 | 一致 | 一致 | 一致 |

**样板 C 小结**：可改 JSON 1 处；需人工 4 处（行结构、Exp1_Clean 冗余文件、Drop/Valid、License/Repo）；登记 1 处（exp JSON 未分 3 组）。

---

## 系统性发现（跨样板，供统一判定）

1. **numTrials 口径库内不统一**：Amodeo 360（total）vs Constable 96/80（per-block）vs Sui_2014 60（per-block?）——需定统一口径或每行注明。
2. **Setting 词表普遍违规**：Amodeo "chamber"、Constable "/"、Liang "Laboratory setting"——统一改 "Laboratory"。
3. **性别数错误**（Constable Exp3/Exp4）——CSV 人工填写错。
4. **Label 侧身份粒度不统一**（Constable Exp3/Exp4 二分类 vs Exp1/2 细粒度）——清洗代码不一致所致，是否统一需判定。
5. **数据粒度**（Constable Exp4 pair vs individual）——清洗代码明确选择，是否接受需判定。
6. **Environmental_Info/Software 多处未填**——论文未披露的留空 or "/" 需定惯例。

---

# 剩余 18 研究复核结果（2026-08 批次）

**方法**：机械比对（2_Code/stage31_crosscheck.py，复用 read_dataset_inf）+ REF 全文人工核对。全部 18 研究均发现差异（无一完全一致）。差异分级：**可自动改**（数据侧错误/缺失，有全文或 JSON 依据）/ **需人工**（N 口径、采集地、pair 粒度、License 等）/ **登记**（口径、映射选择）。

## A 类（单实验平铺 ×10）

### A1. Constable_2020_ActaPsych
- 可改 JSON：DOI 带 `https://doi.org/` 前缀→裸格式；City `'/'`→Newcastle
- 需人工：N 口径 CSV 92（人，全文 L44 "46 pairs, 92 participants" ✓）vs Clean/subj_info **46（pair 粒度）**，subj_info 为 Pair_ID 结构；numTrials=240 为 per-phase（JSON 480 total，Clean 480 行/pair）；Practice=24（=2 phase×12）；**subj_Group 漏判**：全文 L56/L72 Switch Identity 为 between-subjects（24 pairs vs 22 pairs）→ 应填组名非 All
- 登记：Clean 无 Shape/Label Standardized 列（Shape_Std=['']）；软件未披露（JSON '/'、CSV 空，一致）

### A2. Feldborg_2021_IJERPH
- 可改 CSV：Practice_Trial NA→**22**（全文 L70: 8+8+6）；Environmental_Info 空→**Inquisit**（L58）
- 需人工：**Clean nSubj=102 vs 全文 84**（L54 "Eighty-four students"、CSV 84 ✓）——subj_info 102 行含 group 列，多出 18 人来源待查；subj_Group 填 "non-anxious;anxious" ✓，但 L54 另有 between 维度（friend/stranger label 42/42）是否并入待判定
- 一致：Setting=Online ✓ 词表、N 84 ✓

### A3. Haciahmet_2023_Psychophysiol
- 可改 CSV：Practice_Trial 空→24（L64）
- 可改 JSON：Setting "Laboratory/Controlled environment"→Laboratory
- 需人工：Valid_Subj=37 vs Clean 40（全文 L48 "Forty students included"、43 测试 3 排除）——CSV 37 来源不明
- 登记：Clean Block 出现 5（L64 practice 24 + 实验 4×60=240 = 264 行/人 ✓，Block 5 疑为 practice）
- 一致：N 40、numBlocks 4、numTrials 240、E-prime2.0 ✓

### A4. Hu_2020_CollabraPsy
- 可改 JSON：DOI 前缀→裸格式；Country `'/'`→China；City `'/'`→Nanjing；Setting "Individual testing in a quiet room"→Laboratory
- 需人工：**N 口径**——全文 L68 study1 招募 35/分析 29（6 排除），CSV Sample_Size=46、Clean 44——多研究（摘要 "both studies"）数据混杂待厘清；numBlocks=14/numTrials=312 口径（matching 2×120 + interleaved 5×48 + categorization 6×144 多任务）
- 登记：ACC 含 -1/2（Codebook 应说明）；身份 good-self/bad-self/good-other/bad-other 四类（Clean 仅 Self/Stranger 二分类）
- 一致：软件 Matlab+PTB ✓

### A5. Kolvoort_2020_HumBrainMap
- **可改 CSV：Country Netherlands→Canada、City Amsterdam→Ottawa**（全文 L66 "University of Ottawa / Royal Ottawa"）；numBlocks NA→4（L76）
- 可改 JSON：Setting "Laboratory setting"→Laboratory
- 需人工：numTrials=100 为 per-block（JSON "100 per block"、4 blocks=400/人）；**缺 subj_info 文件**
- 登记：Clean 11051/31 不整除（400×31 应 12400）

### A6. Liu_2023_CogRes
- **可改 JSON：Country Germany→UK、City Oldenburg→`/`**（数据为 Prolific UK 在线，L47；CSV 正确）；Practice "not specified"→"1 trial"（L59 "a practice trial"）；Setting "Online (participants' own devices)"→Online
- 需人工：City CSV 值 "In United Kingdom"（非城市名，规范化？）；多任务（matching 64 + emotion recognition）
- 一致：N 302/299 ✓、numTrials=64 ✓、Gorilla ✓、Setting 词表语义（在线）✓

### A7. Perrykkad_2022_BMCPsych
- **可改 CSV：Environmental_Info 'Matlab + PTB'→'Inquisit Web'**（全文 L89 明确 Inquisit Web；JSON 正确）
- 可改 JSON：Setting "Online/Remote"→Online
- 需人工：**N 口径**——全文 L65 328 招募/40 排除/288 有效 vs **Clean nSubj=334**（超招募数）；**缺 subj_info**；Country/City=Australia/Clayton（MTurk 在线数据，是否保留需判定）
- 登记：无 practice 证据（JSON '/'、CSV NA）
- 一致：numBlocks 3、numTrials 360 ✓

### A8. Sui_2023_ConsciousCog
- 可改 JSON：DOI 前缀→裸格式；City `'/'`→Aberdeen；Setting "Laboratory, individual testing sessions"→Laboratory
- 登记：Clean 17974/20 不整除（960×20 应 19200）；Label_Std 空
- 一致：N 20/20/20 ✓、16 blocks/960/12 ✓、软件未披露一致 ✓

### A9. Svensson_2023_QJEP
- 可改 CSV：numBlocks 空→1、numTrials 空→120、Practice_Trial 空→12（全文 L51）；Stim_Type 空→geometric shape；Environmental_Info 空→（软件未披露，留空 or `/` 待定）
- 需人工：Sample_Size=65 vs 全文 L45 招募 70/L59 5 排除→65（Sample_Size 语义=分析样本？）
- 登记：Clean 7370/65 不整除（120×65 应 7800）；Label_Std 空；多任务（matching + ANT）；Prolific 在线被试国籍
- 一致：Setting=Online ✓、N 65 ✓

### A10. Xu_2022_CurrPsych
- **subj_Group 漏判：All→4 组**（全文 L54: acceptance/rejection × high/low facial attractiveness 组间随机分配）
- 可改 JSON：DOI 前缀→裸格式；City 'ChangChun'→'Changchun'（拼写统一）；Setting "Laboratory setting"→Laboratory
- 登记：ACC 含 'NA'（Codebook 说明）
- 一致：N 105 ✓、3 blocks/360/12 ✓、E-prime2.0 ✓

## B 类（多实验子文件夹 ×8）

### B1. Constable_2021_CogEmo
- Exp1 可改 CSV：numTrials 192→**384**（全文 L68 "4 blocks totalling 384"）；Practice_Trial 8→**4**（L66 training 4 trials；JSON "4 trials"）
- Exp2 可改 CSV：numBlocks 空→4、numTrials 空→192（L131）、Practice_Trial 空→8（L131）；**Valid_Subj 20→50**（全文 L141 "n = 50"）
- 可改 JSON：Setting Exp1 "Laboratory setting"→Laboratory、Exp2 "Laboratory (inferred)"→Laboratory
- 需人工：Clean Exp1 768 行/人（384×2? 训练+实验?）；City 'Newcastle' vs JSON 'Newcastle upon Tyne'（拼写统一）
- 一致：N 56 招募 ✓（Exp1 53 有效 L88 ✓、Exp2 50 L141）；4 blocks ✓；身份 Self/Stranger ✓

### B2. Dalmaso_2024_ConsciousCog
- 可改 CSV：numBlocks 空→2、numTrials 空→360、Practice_Trial 空→40（全文 L53/L59: 2 blocks、360 trials、40 practice）
- 可改 JSON：Setting "Laboratory setting"→Laboratory
- 需人工：**Country 采集地**——E1=Japanese（Waseda 日本）、E2=White Italian（意大利），CSV 两行均 Japan；paper JSON Italy/Padova 为作者单位；subj_Group（跨文化，每实验单组 All 可接受？）
- 登记：Exp2 Label_Std 空；ACC 含 2（Codebook 说明）
- 一致：N 40/40/40 ✓

### B3. Lee_2023_Cognition
- 可改 CSV：numBlocks 空→3、numTrials 空→**96**（匹配任务 2 runs×48，全文 L70/JSON）、Practice_Trial 空→24（3 practice blocks×8）
- 需人工：Sample_Size 57/65（招募，L56/L?）vs Valid 47/51 ✓（Clean 匹配 ✓）；Environmental_Info 空（软件 Testable 已披露 → 应补）
- 登记：**Label_Std 用 'Friend'（不在 6 类词表，应为 Close）**；NonPerson/NA 身份（happy/neutral、£9/£1→NonPerson/NA）；subj_info 有 None 列；多任务（matching 96 + classification 360）
- 一致：N 口径 ✓、Testable ✓、Setting=Online ✓

### B4. Navon_2021_psyarxiv
- 可改 JSON：DOI 前缀→裸格式；Country `'/'`→Israel、City `'/'`→Ra'anana（L51 希伯来语被试、Open University of Israel）；Setting "Laboratory setting (implied)"→Laboratory
- 需人工：**Exp3 Clean 28 vs 论文 27**（L142）；**Exp4 Sample 26/Valid 25 vs 论文 27 完成/1 排除→26 分析**（L170，Clean 27）
- 登记：Exp2/Exp3 Label_Std 空；Exp2 身份 father/close-relative/stranger（Shape_Std 无 Self 合理）；Exp4 身份顺序变（friend 先学）
- 一致：Exp1 N 13 ✓、Exp2 N 27 ✓、3 blocks/360/12 ✓、E-prime ✓

### B5. Qian_2020_QJEP
- **可改 CSV：Exp1 Practice_Trial 10→20**（全文 L60 "20 practice trials"）
- 可改 JSON：Setting "Laboratory setting"→Laboratory（×2）
- 需人工：Exp2 numTrials=100（per-block，2 blocks=200 total；JSON 200）；Exp1 numBlocks=NA（多 session 无块结构）
- 登记：Label_Std 空（Celebrity 身份在 Shape 侧 ✓）；4 session 设计
- 一致：N 26/24 ✓、144 trials ✓、E-Prime ✓

### B6. Schaefer_2019_JCogPsych
- 可改 CSV：Exp2/Exp3 numBlocks 空→3、numTrials 空→144、Practice_Trial 空→48（全文 L73）
- 可改 JSON：Setting "Sound-proofed rooms"→Laboratory（×3，L73 明确实验室）
- 需人工：**Exp2 Clean 数据异常**——无 Shape/Label/Matching 列（Shape_Std=['']、Matching=['']，仅 ACC/Subject 等）需深查
- 登记：Exp1 身份含 NonPerson（Bekannter/Nichts 标签）；103 人分 3 实验（32+36+35 ✓ L59）
- 一致：N 32/36/35 ✓、E-Prime ✓

### B7. Vicovaro_2022_JEPHPP
- **subj_Group 漏判：Exp2 All→self-symmetry;self-asymmetry**（全文 L56 "between participants (Experiment 2, online)"）
- 可改 JSON：Setting Exp1 "Dimly lit room"→Laboratory、Exp2 "Online experiment"→Online
- 需人工：Exp2 Environmental_Info 'PsychoPy3' vs JSON Software 'Pavlovia'（Pavlovia=PsychoPy 在线平台，口径）；numTrials=240 per-block（Exp1 2 blocks=480/人 ✓ vs Exp2 240 total/人——between 设计每被试 1 条件）
- 登记：Label_Std 空；ACC 含 'NA'
- 一致：N Exp1 30 ✓、Exp2 104 ✓、2 blocks ✓、PsychoPy3 ✓

### B8. Wozniak_2018_PLOS
- 可改 JSON：DOI 前缀→裸格式；Journal 'PloS one'→'PLOS ONE'（拼写统一）；Setting `'/'`→Laboratory（L62 实验室 E-Prime）
- 需人工：Country/City 多国采集地（paper JSON "Australia, Poland, Hungary" vs CSV 仅 Australia/Melbourne——CEU 伦理 L54，采集地判定）；Exp2 N=20/18 全文确认；numTrials=672（=2 性别×336，L66，口径需注明）
- 登记：Clean 11676/18 不整除；时序任务（face→label vs label→face）
- 一致：Exp1 N 19/18 ✓、4 blocks ✓、E-Prime ✓、身份 Self/Close/Stranger ✓

---

## 系统性发现（18 研究批次补充）

1. **subj_Group 漏判 3 处**（新增列时 Design 列无 between 标记但全文有组间设计）：Constable_2020（Switch Identity）、Xu_2022（4 组）、Vicovaro Exp2（self-symmetry/asymmetry）——**Design 列不是组间判定的充分依据，需全文核对**
2. **paper JSON DOI 普遍带 `https://doi.org/` 前缀**（Constable_2020/Hu_2020/Sui_2023/Xu_2022/Navon/Wozniak_2018 共 6 研究）——违反 SKILL 裸格式约定，统一去前缀
3. **paper JSON Country/City 多处与采集地不符**（Kolvoort CSV 错 / Liu JSON 错 / Dalmaso 跨文化 / Navon JSON 空 / Hu_2020 JSON 空）——采集地判定需全文依据
4. **CSV 试次字段空值批量存在**（Dalmaso/Svensson_2023/Lee/Schaefer Exp2/3/Constable_2021 Exp2 的 numBlocks/numTrials/Practice_Trial 空）——早期人工填写遗漏
5. **N 口径冲突 6 处**（Feldborg 102vs84、Perrykkad 334vs288、Hu_2020 44vs29、Navon Exp3/4、Constable_2021 Exp2 20vs50、Haciahmet 37vs40）
6. **Label 侧 Standardized 缺失/违规**（多个研究 Label_Std 空；Lee 用 'Friend' 非 'Close'）
7. **Clean 行数不整除**（Sui_2023/Kolvoort/Svensson_2023/Wozniak_2018）——需查数据完整性

---

## 待办

- [ ] 用户审查样板差异表与清洗代码核查结论
- [ ] 确认后推进剩余 18 研究（脚本核数值类 + 人工核语义类）
- [ ] 全部 21 研究完成后统一批量修改（可自动确定项）+ 人工判定（需人工项）
