# Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions

## Overview

This analysis computes the self-prioritization effect (Self vs. Stranger) in mismatch conditions using bootstrap resampling with sequential sample size augmentation. The analysis generates 4 figures showing how effect size (Cohen's d) changes with increasing sample size.

## Objective

Prior research has produced mixed findings regarding the existence of self-prioritization effect in mismatch conditions (Sui, 2013). While some studies have documented self-prioritization effect under mismatch conditions, the majority have not reported such effects. It remains ambiguous whether the self-prioritization effect size in mismatch conditions is too small for detection in individual datasets or whether Self-Prioritization Effect is genuinely absent.

## Method

### Data Source
- All `*_Clean.csv` files from `1_Data` directory (52 datasets)
- Key columns: `Subject`, `Matching`, `Shape_Standardized_Identity`, `Label_Standardized_Identity`, `RT_ms`, `ACC`

### Data Filtering

**Strict Filtering (Figures 1-2)**:
- Requires both Shape and Label standardized identity columns
- Requires at least 3 different social identities per participant
- Excludes trials where Shape=Stranger & Label=Self (for Shape baseline)
- Excludes trials where Label=Stranger & Shape=Self (for Label baseline)
- This controls for potential self-relevance confounds

**Loose Filtering (Figures 3-4)**:
- Only requires Shape to be Self or Stranger
- No Label filtering required
- Simpler criterion, includes more data

### Effect Size Calculation
Cohen's d = (Mean_RT_Stranger - Mean_RT_Self) / Pooled_SD

Where:
- Pooled_SD = sqrt(((n1-1)*var1 + (n2-1)*var2) / (n1+n2-2))
- Positive d indicates Stranger RT > Self RT (self-prioritization effect)

### Bootstrap Resampling
- 1000 iterations per sample size
- Sample sizes: 10, 20, 30, ..., n_participants
- Resampling with replacement
- Calculates mean Cohen's d and 95% confidence interval

## Output Files

### Data Files
- `cohens_d_by_participant.csv` - Cohen's d values for each participant
- `bootstrap_results.csv` - Bootstrap results for each sample size

### Figures
- `figure1_shape_strict.png` - Strict filtering, Shape baseline (300 dpi)
- `figure2_label_strict.png` - Strict filtering, Label baseline (300 dpi)
- `figure3_shape_loose.png` - Loose filtering, Shape baseline (300 dpi)
- `figure4_label_loose.png` - Loose filtering, Label baseline (300 dpi)
- `combined_figures_300dpi.png` - All 4 figures in 2x2 grid (300 dpi)

### Configuration
- `TASK_TREE.json` - Task decomposition and KPIs

## How to Run

### Prerequisites
```bash
pip install pandas numpy matplotlib seaborn scipy jupyter
```

### Option 1: Jupyter Notebook (Recommended)
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
jupyter notebook bootstrap_analysis.ipynb
```
Then run all cells from top to bottom.

### Option 2: Python Script
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap
python bootstrap_analysis.py
```

## Interpretation of Figures

Each figure shows:
- **X-axis**: Sample size (number of participants)
- **Y-axis**: Mean Cohen's d (Stranger - Self)
- **Blue/Green line**: Mean effect size across bootstrap iterations
- **Shaded area**: 95% confidence interval
- **Red dashed line**: No effect (d=0)

### Key Questions Addressed
1. Does the self-prioritization effect exist in mismatch conditions?
2. Is the effect too small to detect in individual datasets?
3. How does the effect size stabilize with increasing sample size?
4. Do strict vs. loose filtering criteria affect the conclusions?

## Agent Structure

### Planner
- **Role**: Task decomposition and coordination
- **Responsibilities**: Break down analysis into atomic tasks, define KPIs, monitor progress

### Executor
- **Role**: Code execution and data processing
- **Responsibilities**: Load data, calculate Cohen's d, execute bootstrap, generate figures
- **Tools**: Python, pandas, numpy, scipy, matplotlib, seaborn

### Researcher
- **Role**: Literature review and methodology validation
- **Responsibilities**: Verify statistical methods, provide references

### Reviewer
- **Role**: Quality assurance and validation
- **Responsibilities**: Verify calculation accuracy, check figure quality, validate assumptions

## KPIs

### Phase 1: Data Preparation
- ✓ All 52 datasets loaded successfully
- ✓ Only mismatch trials retained
- ✓ Both strict and loose subsets created

### Phase 2: Effect Size Calculation
- ✓ Cohen's d calculated for each participant
- ✓ Values range typically -2 to 2
- ✓ Manual spot checks pass

### Phase 3: Bootstrap Resampling
- ✓ 1000 iterations per sample size
- ✓ CI width decreases with larger n
- ✓ All statistics mathematically consistent

### Phase 4: Visualization
- ✓ 4 individual figures generated (300 dpi)
- ✓ Combined figure in 2x2 grid (300 dpi)
- ✓ All figures clearly labeled

### Phase 5: Documentation
- ✓ Analysis report generated
- ✓ All findings documented with sources
- ✓ Quality review completed

## References

1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance: Evidence from perceptual matching. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.

2. Sui, J., & Humphreys, G. W. (2013). Self-referential processing is distinct from semantic elaboration: evidence from long-term memory effects in a patient with amnesia and semantic impairments. *Neuropsychologia*, 51(13), 2663–2673.

3. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

4. Efron, B., & Tibshirani, R. J. (1993). *An Introduction to the Bootstrap*. Chapman & Hall.

## Contact

For questions about this analysis:
- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng (Corresponding): hcp4715@hotmail.com
