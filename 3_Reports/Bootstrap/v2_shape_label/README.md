# Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions (v2)

## Overview

This analysis computes the self-prioritization effect (Self vs. Stranger) in mismatch conditions using bootstrap resampling. The analysis generates 4 figures showing how effect size (Cohen's d) changes with increasing sample size.

## Key Features (v2)

### 1. Separate Shape and Label Analysis
- **Shape Analysis**: Primary = Shape_Standardized_Identity, Secondary = Label_Standardized_Identity
- **Label Analysis**: Primary = Label_Standardized_Identity, Secondary = Shape_Standardized_Identity

### 2. RT and ACC as Dependent Variables
- **RT**: Cohen's d = (Mean_Stranger - Mean_Self) / Pooled_SD (positive = self-prioritization)
- **ACC**: Cohen's d = (Mean_Self - Mean_Stranger) / Pooled_SD (positive = self-prioritization)

### 3. Bootstrap with Replacement
- 500 iterations per sample size (matching R code)
- Sample sizes: 10, 20, 30, ..., n_participants
- With replacement sampling

### 4. Strict and Loose Filtering Criteria

**Strict Filtering**:
- Requires both Shape and Label information
- Requires at least 3 different identities per participant
- Excludes trials where Primary=Stranger and Secondary=Self
- Controls for self-relevance confounds

**Loose Filtering**:
- Only requires Primary to be Self or Stranger
- No filtering based on Secondary
- Includes more data

## Output Files

### Figures (300 dpi)
- `bootstrap_rt_strict.png` - RT with strict filtering
- `bootstrap_acc_strict.png` - ACC with strict filtering
- `bootstrap_rt_loose.png` - RT with loose filtering
- `bootstrap_acc_loose.png` - ACC with loose filtering
- `combined_figures_300dpi.png` - All 4 figures in 2x2 grid

### Data Files
- `bootstrap_rt_strict.csv` - Bootstrap results for RT (strict)
- `bootstrap_acc_strict.csv` - Bootstrap results for ACC (strict)
- `bootstrap_rt_loose.csv` - Bootstrap results for RT (loose)
- `bootstrap_acc_loose.csv` - Bootstrap results for ACC (loose)
- `cohens_d_by_participant.csv` - Cohen's d values for each participant

## How to Run

### Option 1: Jupyter Notebook (Recommended)
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
jupyter notebook bootstrap_analysis_v2.ipynb
```
Then run all cells from top to bottom.

### Option 2: Python Script
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
python bootstrap_analysis_v2.py
```

## Interpretation of Figures

Each figure shows:
- **X-axis**: Sample size (number of participants)
- **Y-axis**: Mean Cohen's d
  - RT: Stranger - Self (positive = stranger slower = self-prioritization)
  - ACC: Self - Stranger (positive = self more accurate = self-prioritization)
- **Blue line**: Shape analysis
- **Purple line**: Label analysis
- **Shaded area**: 95% confidence interval
- **Gray dashed line**: No effect (d=0)

### Key Questions Addressed
1. Does the self-prioritization effect exist in mismatch conditions?
2. Is the effect detectable with current sample sizes?
3. Does the effect differ between Shape and Label conditions?
4. Do strict vs. loose filtering criteria affect the conclusions?

## Data Requirements

The analysis requires the following columns in the data files:
- `Subject` - Participant ID
- `Matching` - Matching condition (should include "Nonmatching")
- `Shape_Standardized_Identity` - Shape identity (Self, Stranger, Close, etc.)
- `Label_Standardized_Identity` - Label identity (optional, will use Shape if not present)
- `RT_ms` - Reaction time in milliseconds
- `ACC` - Accuracy (0 or 1)

## Methodology

### Cohen's d Calculation
```
For RT:   d = (Mean_Stranger - Mean_Self) / Pooled_SD
For ACC:  d = (Mean_Self - Mean_Stranger) / Pooled_SD
```

Where:
- Pooled_SD = sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))

### Bootstrap Procedure
1. Start with n=10 participants
2. Sample n participants with replacement
3. Calculate mean Cohen's d for the sample
4. Repeat 500 times
5. Calculate 95% CI from bootstrap distribution
6. Increment n by 10
7. Repeat until all participants included

### Data Filtering (Strict)
```
Keep trial IF:
  Primary == "Self" OR
  (Primary == "Stranger" AND Secondary != "Self") OR
  Primary == "Other"
```

This excludes trials where Shape=Stranger and Label=Self, which could confound the self-prioritization effect.

## References

1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance: Evidence from perceptual matching. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.

2. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

3. Efron, B., & Tibshirani, R. J. (1993). *An Introduction to the Bootstrap*. Chapman & Hall.

## Contact

For questions about this analysis:
- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng (Corresponding): hcp4715@hotmail.com
