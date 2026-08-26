# SPE Database

This project was inspired by [the Confidence Database](https://doi.org/10.1038/s41562-019-0813-1). We aimed at curating a database that include trial-level data and other meta-data from as many empirical studies that used self-matching task from [Sui, He, &amp; Humphreys (2012)](http://www.ncbi.nlm.nih.gov/pubmed/22963229). `<!-- OSF, preprint, and publication links will be directly added to this paragraph -->`

Currently, the SPE database includes trial-level data from **43 studies** (**34 curated on disk + 9 pending entries**) / **73 experiment-level rows** per the master index `1_Data/Dataset_inf.csv`. Earlier published counts (44 papers / 70 datasets / 3603 participants) refer to the manuscript and have not been re-verified against the CSV. Each dataset includes information on reaction times (RTs), accuracy (ACC), and other information reported in papers. Participants in these included studies come from diverse cultural backgrounds, facilitating cross-study comparisons and meta-analytic investigations.

The SPE Database is continuously updated as new studies and datasets become available. We welcome contributions from researchers who wish to share their data and help expand this resource. If you are interested in contributing or collaborating, please feel free to reach out!

This project is in parallel with an on-going preregistered meta-analysis leading by Hu Chuan-Peng and Zheng Liu (see registry [here](https://osf.io/euqmf)).

## Data & metadata

- **Master index**: `1_Data/Dataset_inf.csv` (UTF-8 with BOM) — one row per experiment, keyed by `Folder_Name` (the project-wide ID for papers/preprints, == study folder) + `Exp`. Key columns: `FirstAuthor`, `Year` (official print year), `Journal`, `DOI` (paper DOI), `Country`/`City`, `Stim_Type`, `Stim_language`, `License`, `numTrials`, `Sample_Size`/`Male`/`Female`, `Repo_Link` (data repository link). Current inventory: **34 curated studies on disk + 9 pending entries** (authoritative counts live in the CSV).
- **Cleaned data**: `*_ExpN_Clean.csv` uses standardized columns `Subject`, `Shape`, `Label`, `Matching`, `ACC`, `RT_ms`, plus 3-level Identity columns (Origin → English → Standardized: NonPerson/Self/Close/Acquaintance/Celebrity/Stranger). Cleaning is minimal preprocessing — invalid values (e.g., `ACC = -1`) are kept and documented in the codebook; users preprocess per their own analysis goals.
- **Per-study metadata**: paper-level `<Study>.json` + experiment-level `<Study>_Exp<N>.json` (v2 schema) + `Codebook_<Study>_Exp<N>_Clean.xlsx`.
- **Contributing / adding data**: follow the curation conventions in `.opencode/skills/spe-database-curation/SKILL.md` (folder naming, JSON schemas, codebook rules, DOI/year verification workflow) — load it via `skill(name="spe-database-curation")` for any data-curation task.
- **For agents**: repository conventions and efficiency rules live in `AGENTS.md`; project state lives in `PROJ_STATE.md` (see also the Document map in AGENTS.md).

## Leading Team

- Zhenxin Cai (School of Psychology, Nanjing Normal University,email:[czx@nnu.edu.cn](czx@nnu.edu.cn))
- Wang Qihui(School of Psychology, Nanjing Normal University,email:QAQbigWang@163.com.)
- Xinru Sun (School of Psychology, Nanjing Normal University)
- Wanke Pan (School of Psychology, Nanjing Normal University)
- Mengzheng Hu (School of Psychology, Nanjing Normal University)
- Zheng Liu (Division of Applied Psychology, School of Humanities and Social Science, CUHK-Shenzhen)
- Jie Sui ([School of Psychology, University of Aberdeen](https://www.abdn.ac.uk/people/jie.sui))
- **Hu Chuan-Peng** (**Corresponding author**, School of Psychology, Nanjing Normal University, email: [hcp4715@hotmail.com](hcp4715@hotmail.com))

### Data contributors

Authors of original studies were invited and listed here, if permitted, as contributors. We will adhere to Sage's authorship criteria for authors in our future data descriptor paper. That is, authors of our data descriptor paper must have been responsible for at least one of the following [CRediT](https://us.sagepub.com/en-us/nam/credit) roles:

- Conceptualization
- Methodology
- Formal Analysis
- Investigation

AND at least one of the following:

- Writing - Original Draft Preparation
- Writing - Review & Editing

Contributors

- Marco Bertamini (Department of General Psychology, University of Padova)
- Mario Dalmaso (Department of Developmental and Social Psychology, University of Padova)
- Michele Vicovaro (Department of General Psychology, University of Padova)
- Merryn D. Constable (Department of Psychology, Northumbria University)
- Christian Frings (University of Trier)
- Céline Haciahmet (University of Trier)
- Sarah Schäfer (University of Trier)
- Bernhard Pastötter (University of Trier)
- Judith Goris (Department of Experimental Psychology, Ghent University)
- Letizia Amodeo (Department of Experimental Clinical and Health Psychology, Ghent University)
- Annabel D. Nijhof (Department of Experimental Clinical and Health Psychology, Ghent University)
- Jan R. Wiersema (Department of Experimental Clinical and Health Psychology, Ghent University)
- Lili Guan (School of Psychology, Northeast Normal University)
- Luis J. Fuentes (Departamento de Psicología Básica y Metodología, Facultad de Psicología y Logopedia, Universidad de Murcia)
- Lucía B. Palmero (Departamento de Psicología Básica y Metodología, Facultad de Psicología y Logopedia, Universidad de Murcia)
- Ivar Kolvoort (Department of Psychology, Programme Group Psychological Methods, University of Amsterdam)
- Tal Makovski (Department of Psychology, Tel-Hai Academic College)
- Víctor Martínez-Pérez (University of Castilla-La Mancha Albacete Campus, Faculty of Medicine (UCLM - Albacete))
- Mayan Navon (Department of Education and Psychology, the Open University of Israel)
- Georg Northoff (Institute of Mental Health Research, University of Ottawa)
- Xiangping Gao (Department of Psychology, Shanghai Normal University)
- Haoyue Qian (School of Physics and Shanghai Key Laboratory of Magnetic Resonance, East China Normal University; Department of Psychology, Shanghai Normal University)
- Kalai Hung (Tsinghua University)
- Michella Feldborg (University of Aberdeen)
- Fei Wang (Tsinghua University)
- Qiongdan Liang (Tsinghua University)
- Yongfa Zhang (Tsinghua University)
- Tuo Liu (Goethe University Frankfurt)
- Mateusz Wozniak (Social Cognition in Human-Robot Interaction Group, Italian Institute of Technology; Social Mind Center, Department of Cognitive Science, Central European University; Cognition and Philosophy Lab, Department of Philosophy, Monash University; Institute of Psychology, Jagiellonian University)

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

**Planned**

* **[Metadata in JSON Format]**: Transition metadata storage from .md to .json format for each article, providing a more structured and machine-readable format.

## Folder structure

```
root
│  .gitignore
│  README.md
├─1_Data 
│   └─ Dataset_inf.csv  # master index (UTF-8 with BOM); legacy Dataset_inf.xlsx pending removal
│   └─ <Author>_<Year>_<Suffix>   # Suffix = readable journal/database abbreviation (e.g. JEPHPP, ActaPsych, ConsciousCog, QJEP), full short journal name (Cognition, Cortex), psyarxiv/unpub tag, or data-repo abbreviation (SDB)
│       └─ <Author>_<Year>_<Suffix>_<Exp-id>_Clean.csv
│       └─ <Author>_<Year>_<Suffix>_<Exp-id>_subj_info.csv
│       └─ Codebook_<Author>_<Year>_<Suffix>_<Exp-id>_Clean.xlsx
│       └─ <Author>_<Year>_<Suffix>.json  # Including Meta data for each paper.
│       └─ <Author>_<Year>_<Suffix>_<Exp-id>.json  # Including methodological information for the specific experiment.
│       └─ <Author>_<Year>_<Suffix>_<Exp-id>_raw.csv
├─2_Code
│   └─ Clean_Data.Rproj
│   └─ Clean_Data.Rmd
│   └─ README.md
└─3_Reports
     │
     └─ README.md
```
