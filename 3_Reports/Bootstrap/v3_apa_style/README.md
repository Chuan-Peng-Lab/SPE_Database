# Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions (v3)

## Overview

This analysis computes the self-prioritization effect (Self vs. Stranger) in mismatch conditions using bootstrap resampling. Version 3 includes APA-style formatting and two versions of sample size alignment.

## Key Features (v3)

### 1. Figure Titles (Following Advisor's Feedback)
- **Row 1**: "SPE calculated by strict approach"
- **Row 2**: "SPE calculated by loose approach"
- Each row uses the same filtering approach for both RT and ACC

### 2. APA Style Formatting
- **No grid lines** - Clean, publication-ready appearance
- **White background** - Professional look
- **Fixed axes** - Easy comparison across figures
  - X-axis: [0, 500]
  - Y-axis: [-0.4, 0.4]
- **Times New Roman font** - APA standard
- **Subplot labels** (A, B, C, D) - Clear identification

### 3. Two Versions of Sample Size

**Version 1: Original**
- Sample sizes as calculated
- Shape and Label may have different maximum sample sizes
- Shows full range of data

**Version 2: Aligned**
- Sample sizes limited to min(Shape, Label) for each filtering
- Both Shape and Label lines end at the same sample size
- Easier comparison between conditions
- More conservative estimate

## Output Files

### Figures (300 dpi)
- `combined_figures_apa_original.png` - Version 1 (original sample sizes)
- `combined_figures_apa_aligned.png` - Version 2 (aligned sample sizes)

### Data Files
- `bootstrap_rt_strict_original.csv` - RT strict filtering (original)
- `bootstrap_acc_strict_original.csv` - ACC strict filtering (original)
- `bootstrap_rt_loose_original.csv` - RT loose filtering (original)
- `bootstrap_acc_loose_original.csv` - ACC loose filtering (original)
- `bootstrap_rt_strict_aligned.csv` - RT strict filtering (aligned)
- `bootstrap_acc_strict_aligned.csv` - ACC strict filtering (aligned)
- `bootstrap_rt_loose_aligned.csv` - RT loose filtering (aligned)
- `bootstrap_acc_loose_aligned.csv` - ACC loose filtering (aligned)
- `cohens_d_by_participant.csv` - Individual Cohen's d values

## Figure Layout

```
┌─────────────────────────────────────────────────────────┐
│  A. SPE calculated by strict approach (RT)              │
│     B. SPE calculated by strict approach (ACC)          │
├─────────────────────────────────────────────────────────┤
│  C. SPE calculated by loose approach (RT)               │
│     D. SPE calculated by loose approach (ACC)           │
└─────────────────────────────────────────────────────────┘
```

Each subplot shows:
- **Blue line**: Shape analysis
- **Purple line**: Label analysis
- **Shaded area**: 95% confidence interval
- **Gray dashed line**: No effect (d=0)

## How to Run

### Option 1: Jupyter Notebook (Recommended)
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
jupyter notebook bootstrap_analysis_v3.ipynb
```
Then run all cells from top to bottom.

### Option 2: Python Script
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
python bootstrap_analysis_v3.py
```

## Interpretation

### Cohen's d Values
- **RT**: d = (Mean_Stranger - Mean_Self) / Pooled_SD
  - Positive = Stranger slower = Self-prioritization effect
- **ACC**: d = (Mean_Self - Mean_Stranger) / Pooled_SD
  - Positive = Self more accurate = Self-prioritization effect

### Statistical Significance
- If 95% CI does not include 0 → Significant effect
- If 95% CI includes 0 → Non-significant effect

### Version Comparison
- **Original**: Shows full range of data, but Shape and Label may have different endpoints
- **Aligned**: Shows only up to the smaller sample size, allows direct comparison

## APA Style Guidelines Applied

1. **Font**: Times New Roman throughout
2. **Background**: White, no grid lines
3. **Axes**: 
   - Fixed ranges for comparison
   - Top and right spines removed
   - Left and bottom spines with 1pt width
4. **Labels**: Bold, clear hierarchy
5. **Legend**: Compact, upper right placement
6. **Subplot labels**: A, B, C, D in bold

## Methodology

### Data Filtering (Strict)
```
Keep trial IF:
  Primary == "Self" OR
  (Primary == "Stranger" AND Secondary != "Self") OR
  Primary == "Other"
```

### Bootstrap Procedure
1. Sample n participants with replacement
2. Calculate mean Cohen's d
3. Repeat 500 times
4. Calculate 95% CI
5. Increment n by 10
6. Repeat until max sample size

### Sample Size Alignment (Version 2)
```python
max_n = min(len(shape_participants), len(label_participants))
bootstrap_analysis(values, max_n=max_n)
```

## References

1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.

2. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

3. Efron, B., & Tibshirani, R. J. (1993). *An Introduction to the Bootstrap*. Chapman & Hall.

## Contact

For questions about this analysis:
- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng (Corresponding): hcp4715@hotmail.com
