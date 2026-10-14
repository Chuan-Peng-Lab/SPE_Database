# SPE Database

This project was inspired by [the Confidence Database](https://doi.org/10.1038/s41562-019-0813-1). We aimed at curating a database that include trial-level data and other meta-data from as many empirical studies that used the self-matching task (also referred to as the shape–label matching task or the perceptual matching task) from [Sui, He, &amp; Humphreys (2012)](http://www.ncbi.nlm.nih.gov/pubmed/22963229), which measures the self-prioritization effect (SPE). `<!-- OSF, preprint, and publication links will be directly added to this paragraph -->`

Currently, the SPE database includes trial-level data from **52 studies** (**51 curated on disk + 1 deferred entry**) / **114 rows** per the master index `1_Data/Dataset_inf.csv` (see `PROJ_STATE.md`). <!-- Earlier published counts (44 papers / 70 datasets / 3603 participants) refer to the manuscript and have not been re-verified against the CSV -->. Each dataset includes information on reaction times (RTs), accuracy (ACC), and other information reported in papers. Participants in these included studies come from diverse cultural backgrounds and age range, facilitating cross-study comparisons and meta-analytic investigations.

The SPE Database is continuously updated as new studies and datasets become available. We welcome contributions from researchers who wish to share their data and help expand this resource. If you are interested in contributing or collaborating, please feel free to reach out!

This project is in parallel with an on-going preregistered meta-analysis leading by Hu Chuan-Peng and Zheng Liu (see registry [here](https://osf.io/euqmf)).

## Data & metadata

- **Master index**: `1_Data/Dataset_inf.csv` (UTF-8 with BOM) — one row per experiment-sample, keyed by `Folder_Name` (the project-wide **study ID** = the study folder name) + `Exp` + `subj_Group`. Key columns: `FirstAuthor`, `Year` (official print year), `Journal`, `DOI` (paper DOI), `Country`/`City`, `Stim_Type`, `Stim_language`, `License`, `numTrials`, `Sample_Size`/`Male`/`Female`, `Repo_Link` (data repository link). Current inventory: **51 curated studies on disk + 1 deferred (Scheller_2026_elife)** (authoritative counts live in the CSV); `Hu_YQ_2026_ChinaSciData` currently holds two experiments (4 index rows, 62 participants) — its input data zone is still pending; the open items (input data, Kaifeng release, design calibers) are listed in `3_Reports/Hu_YQ_2026_Issues.md`.
- **Data-user guide**: `1_Data/README.md` summarises the three standardization layers (folder structure, trial-level data, experiment metadata) for downstream users. **Note that `Task` is not the condition variable**: after the database-wide unification (2026-10-12) it only has three values (`self-matching` / `shape-matching` / `choice-task`), and different conditions can share one value — read the condition from the stimulus columns, the three-level identity columns, `extraIV1`/`extraIV2`, `Session`/`Phase`/`Block`, and the study's Codebook and experiment JSON `detail`.
- **Data readability** (since 2026-08-30): `Shape`/`Label` columns hold actual stimulus values (shape names / label words); original numeric codes are kept in the raw `ShapeCode`/`LabelCode` columns and the Clean `*_Origin_Identity` columns.
- **Cleaned data**: `*_ExpN_Clean.csv` uses standardized columns `Subject`, `Shape`, `Label`, `Matching`, `ACC`, `RT_ms`, plus 3-level Identity columns (Origin → English → Standardized: NonPerson/Self/Close/Acquaintance/Celebrity/Stranger). Cleaning is minimal preprocessing (harmonization) — special values are kept under the database-wide ACC coding (e.g., no response = `NA`, out-of-range key = `-2`) and documented in the codebook; users preprocess per their own analysis goals. Clean and raw files larger than 50 MB are split at whole-subject boundaries into `_Clean_part<N>.csv` / `_raw_part<N>.csv` (identical header; one shared codebook and experiment JSON; reassemble with `rbind`; rule in SKILL.md §文件与文件夹规范「大文件拆分」).
- **Per-study metadata**: paper-level `<Folder_Name>.json` + experiment-level `<Folder_Name>_Exp<N>.json` (v2 schema) + `Codebook_<Folder_Name>_Exp<N>_Clean.xlsx`.
- **Contributing / adding data**: follow the curation conventions in `.agents/skills/spe-database-curation/SKILL.md` (folder naming, JSON schemas, codebook rules, DOI/year verification workflow) — load it via `skill(name="spe-database-curation")` for any data-curation task.
- **For agents**: repository conventions and efficiency rules live in `AGENTS.md`; project state lives in `PROJ_STATE.md` (see also the Document map in AGENTS.md).
- **For collaborators (合作者)**: You only need to provide raw data and full texts, then let the AI agent finish the rest — see `For_COLLABORATORS.md` (中文).

## Leading Team

- Cai, Zhenxin (School of Psychology, Nanjing Normal University, email:[czx@nnu.edu.cn](czx@nnu.edu.cn))
- Wang, Fei (Department of Psychological and Cognitive Sciences, Tsinghua University, email: wf3126@mail.tsinghua.edu.cn)
- Sui, Jie ([School of Psychology, University of Aberdeen](https://www.abdn.ac.uk/people/jie.sui))
- **Hu Chuan-Peng** (**Corresponding author**, School of Psychology, Nanjing Normal University, email: [hcp4715@hotmail.com](hcp4715@hotmail.com))

### Data contributors

Authors of original studies were invited and listed here, if accepted, as contributors of the future manuscript. We will adhere to general authorship criteria for authors in our future data descriptor paper. That is, authors of our data descriptor paper must have been responsible for at least one of the following [see CRediT](https://us.sagepub.com/en-us/nam/credit) roles:

- Conceptualization
- Methodology
- Formal Analysis
- Investigation

AND at least one of the following:

- Writing - Original Draft Preparation
- Writing - Review & Editing

Confirmed contributors

- Amodeo, Letizia (Department of Experimental Clinical and Health Psychology, Ghent University)
- Bertamini, Marco (Department of General Psychology, University of Padova)
- Constable, Merryn D. (Department of Psychology, Northumbria University)
- Dalmaso, Mario (Department of Developmental and Social Psychology, University of Padova)
- Feldborg, Michella (University of Aberdeen)
- Frings, Christian (University of Trier)
- Fuentes, Luis J. (Departamento de Psicología Básica y Metodología, Facultad de Psicología y Logopedia, Universidad de Murcia)
- Gao, Xiangping (Department of Psychology, Shanghai Normal University)
- Goris, Judith (Department of Experimental Psychology, Ghent University)
- Guan, Lili (School of Psychology, Northeast Normal University)
- Haciahmet, Céline (University of Trier)
- Hung, Kalai (Department of Psychological and Cognitive Sciences, Tsinghua University)
- Kolvoort, Ivar (Department of Psychology, Programme Group Psychological Methods, University of Amsterdam)
- Liang, Qiongdan (Department of Psychological and Cognitive Sciences, Tsinghua University)
- Liu, Tuo (Department of Educational Psychology, Goethe University Frankfurt)
- Makovski, Tal (Department of Psychology, Tel-Hai Academic College)
- Martínez-Pérez, Víctor (University of Castilla-La Mancha Albacete Campus, Faculty of Medicine (UCLM - Albacete))
- Navon, Mayan (Department of Education and Psychology, the Open University of Israel)
- Nijhof, Annabel D. (Department of Experimental Clinical and Health Psychology, Ghent University)
- Northoff, Georg (Institute of Mental Health Research, University of Ottawa)
- Palmero, Lucía B. (Departamento de Psicología Básica y Metodología, Facultad de Psicología y Logopedia, Universidad de Murcia)
- Pastötter, Bernhard (University of Trier)
- Qian, Haoyue (School of Physics and Shanghai Key Laboratory of Magnetic Resonance, East China Normal University; Department of Psychology, Shanghai Normal University)
- Schäfer, Sarah (University of Trier)
- Vicovaro, Michele (Department of General Psychology, University of Padova)
- Wiersema, Jan R. (Department of Experimental Clinical and Health Psychology, Ghent University)
- Wozniak, Mateusz (Social Cognition in Human-Robot Interaction Group, Italian Institute of Technology; Social Mind Center, Department of Cognitive Science, Central European University; Cognition and Philosophy Lab, Department of Philosophy, Monash University; Institute of Psychology, Jagiellonian University)
- Zhang, Yongfa (Department of Psychological and Cognitive Sciences, Tsinghua University)
- Zhao, Yue (Department of Psychological and Cognitive Sciences, Tsinghua University)
- Wanke Pan (School of Psychology, Nanjing Normal University)
- Xinru Sun (School of Psychology, Nanjing Normal University)
- Siyu Wu (School of Psychology, Nanjing Normal University)
- Mengzheng Hu (School of Psychology, Nanjing Normal University)
- Zheng Liu (Division of Applied Psychology, School of Humanities and Social Science, CUHK-Shenzhen)

## Data Version

### Version v0.1.5 — 2026-06-28

**New features/changes**

* **[Reproducible Analyses]**: Added three self-contained R Markdown analyses — Identity-level SPE with mixed-model bootstrap (`1_Identity_Analysis`), bootstrap estimation of SPE under mismatch conditions (`2_Mismatch_Analysis`), and exploratory Spearman bootstrap moderator analysis (`3_Exploratory_Analysis`).
* **[Updated Data Fold Structure]**: Updated the data folder structure for better organization and clarity.It helps to organize the data and analyses in a more structured and logical manner, making it easier to navigate and understand the contents of the repository.
*  **[Updated Metadata in JSON Format]**: Updated the JSON file to include more detailed information about the data, such as the number of participants, the number of trials, and the number of variables. This makes it easier to understand the structure and content of the data.

### Version 0.1.4 — 2026-04-13

**New features/changes**

* **[Visualization Tool]**: Added Shiny-based interactive data cleaning tool with batch processing capabilities
* **[Batch Processing]**: Support for processing multiple `*_raw.csv` files in a directory automatically
* **[Interactive Interface]**: Web-based UI for variable mapping, Identity standardization, and data preview
* **[Flexible Input]**: Support for various path formats (with/without quotes, forward/backward slashes)
* **[Identity Mapping]**: Manual Shape and Label Identity mapping with auto-detection suggestions
* **[Batch Download]**: Results packaged as ZIP archive for easy distribution
* **[Progress Tracking]**: Real-time batch processing progress and detailed results summary

### Version 0.1.3 — 2025-10-20

**New features/changes**

* **[Data Filtering]**: Using R, retaining behavioral variables required for calculating the Self-Prioritization Effect (SPE), including Matching, Shape/Face/Voice, Label, Identity (Shape_Origin_Identity,Shape_English_Identity,Shape_Standardized_Identity,Label_Origin_Identity,Label_English_Identity,Label_Standardized_Identity standardized as: NonPerson, Self, Close, Acquaintance, Celebrity, Stranger), RT_ms, and ACC. Demographic variables (e.g., gender, age, handedness) were also retained when available.
* **[Floder Structure]**: The database is bifurcated into two primary folders: "Clean_Data" and "Raw_Data." The "Clean_Data" folder encompasses micpreprocessed data files, whereas the "Raw_Data" folder houses the original data files sourced from the articles. Within the Clean_Data folder, a JSON file has been added to document the paper's infromation, and a codebook has been included to provide a detailed account of the dataset's contents. Additionally, a codebook is present to meticulously log the data descriptions of the dataset.

### Version 0.1.2 — 2025-06-16

**New features/changes**

* **[Data Filtering]**: Performed initial data filtering using R, retaining behavioral variables required for calculating the Self-Prioritization Effect (SPE), including Matching, Shape/Face/Voice, Label, Identity (Shape_Identity standardized as: NonPerson, Self, Close, Acquaintance, Celebrity, Stranger), RT_ms, and ACC. Demographic variables (e.g., gender, age, handedness) were also retained when available.
* **[SPE Analysis]**: Conducted exploratory analysis of SPE using Clean_Data, calculating sequential dependency effects and analyzing the impact of different Identity categories on RT and ACC.
* **[Visualization]**: Visualized the distribution of SPE for each participant, providing a clear view of SPE performance across different Identity categories.

**Bugs/glitches discovered after the release**

* **[Insufficient Preprocessing]**: Data filtering was performed rather than full preprocessing, which may lead to invalid values during data exploration (e.g., ACC values may include -1 for no response, 2 for incorrect key press). Users must perform their own preprocessing based on their analysis goals. Details of each article's Clean_Data are available in the Codebook within the Clean_Data folder.

---

### Version 0.1.0 — 2025-05-16

**New features/changes**

* **[Data Structure Setup]**: Established the initial data structure of the SPE database, including behavioral and demographic data.
* **[Data Integration]**: Integrated raw data from multiple published articles, including behavioral variables (e.g., RT, ACC) and demographic variables.
* **[README File]**: Provided a basic README file explaining the database structure and usage guidelines.

**Bugs/glitches discovered after the release**

* **[Inconsistent Variable Names]**: Some raw data files contained inconsistent variable names, causing issues during data integration.
* **[Missing Demographic Variables]**: Certain articles lacked demographic variables, resulting in incomplete metadata.

---

### Unreleased

**Added**

* **[New studies]**: Also ingested `Hu_YQ_2026_ChinaSciData` (2 experiments / 4 index rows; input zone still pending — open items in `3_Reports/Hu_YQ_2026_Issues.md`), `Sun_2026_DataExp`, `Lee_2026_BritJPsy`, and `Zhao_2026_PsychonBullRev` (3 experiments; standard files rebuilt from the author's raw PsychoPy logs).
* **[New study: Wu_2026_Chinaxiv]**: Two preregistered experiments on self-prioritization in perceptual decision-making (random-dot kinematogram; matching task followed by a choice task), 141 participants (motion/colour groups) + 60 participants, 3 rows in the master index; full standard files, codebooks and JSON metadata (2026-10-06).
* **[Standardized Task column]**: `Task` unified to three values — `self-matching` / `shape-matching` / `choice-task` (2026-10-12); conditions are no longer encoded in `Task` alone (see `1_Data/README.md`).
* **[Data readability]**: `Shape`/`Label` columns hold actual stimulus values; original numeric codes are kept in the raw `ShapeCode`/`LabelCode` columns and the Clean `*_Origin_Identity` columns (since 2026-08-30).

**Changed**

* **[Column order]**: All `*_Clean.csv` files reordered to the v2 template; Codebooks and clean scripts synchronized (2026-10-08).
* **[Master index]**: `Dataset_inf.csv` is the single index (UTF-8 with BOM, 37 columns); the legacy `Dataset_inf.xlsx` was removed.

**Planned**

* **[Metadata in JSON Format]**: Transition metadata storage from .md to .json format for each article, providing a more structured and machine-readable format.

## Folder structure

```
root
│  .gitignore
│  README.md
│  AGENTS.md            # agent conventions and efficiency rules
│  PROJ_STATE.md        # project status and open items
│  For_COLLABORATORS.md # contributor guide (中文)
├─.agents
│   └─ skills/spe-database-curation/  # authoritative curation rules (SKILL.md)
├─1_Data
│   └─ Dataset_inf.csv  # master index (UTF-8 with BOM)
│   └─ <Folder_Name>   # = the study (folder name = project-wide study ID); <Folder_Name> = <Author>_<Year>_<Suffix>, Suffix = readable journal/database abbreviation (e.g. JEPHPP, ActaPsych, ConsciousCog, QJEP), full short journal name (Cognition, Cortex), psyarxiv/unpub tag, or data-repo abbreviation (SDB)
│       └─ <Folder_Name>_<Exp-id>_Clean.csv
│       └─ <Folder_Name>_<Exp-id>_Clean_part<N>.csv  # 分片：单一 Clean > 50 MB 时按被试边界拆分（规则见 SKILL.md §文件与文件夹规范「大文件拆分」）
│       └─ <Folder_Name>_<Exp-id>_raw.csv
│       └─ <Folder_Name>_<Exp-id>_raw_part<N>.csv  # 分片：单一 raw > 50 MB 时同理
│       └─ <Folder_Name>_<Exp-id>_subj_info.csv
│       └─ Codebook_<Folder_Name>_<Exp-id>_Clean.xlsx
│       └─ <Folder_Name>.json  # Including Meta data for each paper.
│       └─ <Folder_Name>_<Exp-id>.json  # Including methodological information for the specific experiment.
├─2_Code
│   └─ Clean_Data.Rproj
│   └─ Clean_Data.Rmd
│   └─ README.md
└─3_Reports
      └─ Generate_Table1_v2.R  # current Table 1 generator
      └─ Output/               # generated tables and reports
```
