# Bootstrap Analysis for Self-Prioritization Effect (v4.1)

## Overview

Version 4.1 focuses on:
1. **Unified legend style**: All figures use Style 2 (legend below title as subtitle)
2. **Three sample size versions**: Max, Original, and Aligned

## Files in This Folder

### Code Files
- `bootstrap_analysis_v4.ipynb` - Version 4 (two legend styles)
- `bootstrap_analysis_v4.1.ipynb` - **Version 4.1 (recommended)**
- `bootstrap_analysis_v4.py` - Python script for v4

### Documentation
- `README.md` - This file

## Version 4.1 Features

### Legend Style
All figures use **Style 2**: Legend below title as subtitle

```
SPE calculated by strict approach
(RT)  ■ Shape  ■ Label
```

This format:
- Keeps the plot area clean
- Provides clear legend identification
- Follows APA style guidelines

### Sample Size Versions

#### 1. Max Version (`combined_figures_style2_max.png`)
- **No sample size limit**
- Each condition uses its maximum available sample size
- Shape and Label may have different endpoints
- Shows full range of available data
- Best for exploratory analysis

#### 2. Aligned Version (`combined_figures_style2_aligned.png`)
- **Limited to min(Shape, Label) sample size**
- Both Shape and Label lines end at the same point
- Allows fair comparison between conditions
- More conservative estimate
- **Best for publication**

## How to Run

### Option 1: Jupyter Notebook (Recommended)
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized
jupyter notebook bootstrap_analysis_v4.1.ipynb
```
Then run all cells from top to bottom.

### Option 2: Python Script
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized
python bootstrap_analysis_v4.py
```

## Output Files

### Figures (300 dpi)
- `combined_figures_style2_max.png` - No sample size limit
- `combined_figures_style2_aligned.png` - Aligned to min of Shape/Label

### Data Files
- `bootstrap_rt_strict_max.csv`
- `bootstrap_acc_strict_max.csv`
- `bootstrap_rt_loose_max.csv`
- `bootstrap_acc_loose_max.csv`
- `bootstrap_rt_strict_aligned.csv`
- `bootstrap_acc_strict_aligned.csv`
- `bootstrap_rt_loose_aligned.csv`
- `bootstrap_acc_loose_aligned.csv`

## Figure Layout

Each figure contains 4 subplots in a 2x2 grid:

```
┌─────────────────────────────────────────────────────────┐
│  A. SPE calculated by strict approach                   │
│     (RT)  ■ Shape  ■ Label                              │
│                                                         │
│     B. SPE calculated by strict approach                │
│        (ACC)  ■ Shape  ■ Label                          │
├─────────────────────────────────────────────────────────┤
│  C. SPE calculated by loose approach                    │
│     (RT)  ■ Shape  ■ Label                              │
│                                                         │
│     D. SPE calculated by loose approach                 │
│        (ACC)  ■ Shape  ■ Label                          │
└─────────────────────────────────────────────────────────┘
```

## Interpretation

### Cohen's d Values
- **RT**: Cohen's d = (Mean_Stranger - Mean_Self) / Pooled_SD
  - Positive = Stranger slower = Self-prioritization effect
- **ACC**: Cohen's d = (Mean_Self - Mean_Stranger) / Pooled_SD
  - Positive = Self more accurate = Self-prioritization effect

### Statistical Significance
- If 95% CI does not include 0 → Significant effect
- If 95% CI includes 0 → Non-significant effect

## Recommendations

### For Publication
Use `combined_figures_style2_aligned.png`:
- ✅ Fair comparison between Shape and Label
- ✅ APA style formatting
- ✅ Clean legend placement
- ✅ Fixed axes for consistency

### For Exploratory Analysis
Use `combined_figures_style2_max.png`:
- ✅ Shows full range of data
- ✅ Each condition at its maximum power
- ✅ Reveals potential differences in data availability

### For Presentations
Use `combined_figures_style2_aligned.png`:
- ✅ Easy to compare Shape vs Label
- ✅ Clear legend
- ✅ Professional appearance

## Data Requirements

The analysis requires the following columns in *_Clean.csv files:
- `Subject` - Participant ID
- `Matching` - Matching condition (should include "Nonmatching")
- `Shape_Standardized_Identity` - Shape identity (Self, Stranger, Close, etc.)
- `Label_Standardized_Identity` - Label identity (optional, will use Shape if not present)
- `RT_ms` - Reaction time in milliseconds
- `ACC` - Accuracy (0 or 1)

## Methodology

### Data Filtering

**Strict Filtering**:
- Requires both Shape and Label information
- Requires at least 3 different identities per participant
- Excludes trials where Primary=Stranger and Secondary=Self

**Loose Filtering**:
- Only requires Primary to be Self or Stranger
- No filtering based on Secondary

### Bootstrap Resampling
- 500 iterations per sample size
- Sample sizes: 10, 20, 30, ..., n_participants
- With replacement (matching R code)
- Calculates mean Cohen's d and 95% confidence interval

## References

1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.

2. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

## Contact

- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng (Corresponding): hcp4715@hotmail.com
