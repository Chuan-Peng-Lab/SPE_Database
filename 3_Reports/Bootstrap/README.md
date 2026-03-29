# Bootstrap Analysis - Project Structure

This folder contains the bootstrap analysis for Self-Prioritization Effect (SPE) in mismatch conditions.

## Folder Structure

```
Bootstrap/
├── v1_initial/              # Version 1: Initial implementation
├── v2_shape_label/          # Version 2: Separate Shape and Label analysis
├── v3_apa_style/            # Version 3: APA style formatting
├── v4_legend_optimized/     # Version 4: Legend placement optimized
├── results_data/            # All CSV result files
├── results_figures/         # All generated figures
│   ├── v1_initial/
│   ├── v2_shape_label/
│   ├── v3_apa_style/
│   └── v4_legend_optimized/
└── README.md               # This file
```

## Version History

### v1_initial
- Basic bootstrap implementation
- Single figure with 4 subplots
- No distinction between Shape and Label

### v2_shape_label
- Separate Shape and Label analysis
- RT and ACC as dependent variables
- Bootstrap with replacement (matching R code)
- Strict and Loose filtering criteria

### v3_apa_style
- APA style formatting
- No grid lines
- Fixed axes for comparison
- Two versions: original and aligned sample sizes

### v4_legend_optimized (Latest)
- Legend integrated into title area
- Two legend styles:
  - Style 1: Colored squares after title (recommended for publication)
  - Style 2: Subtitle below main title (recommended for presentations)
- No plot obstruction

## Quick Start

### Run Latest Version (v4)
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized
jupyter notebook bootstrap_analysis_v4.ipynb
```

### Run Python Script
```bash
cd D:\GitHub_programe\GitHub\SPE_Database\3_Reports\Bootstrap\v4_legend_optimized
python bootstrap_analysis_v4.py
```

## Output Files

### Results Data (results_data/)
- `bootstrap_*_strict_*.csv` - Strict filtering results
- `bootstrap_*_loose_*.csv` - Loose filtering results
- `*_original.csv` - Original sample sizes
- `*_aligned.csv` - Aligned sample sizes (min of Shape and Label)
- `cohens_d_by_participant.csv` - Individual Cohen's d values

### Figures (results_figures/)

**v4_legend_optimized (Recommended)**
- `combined_figures_style1_aligned.png` - Best for publication
- `combined_figures_style1_original.png`
- `combined_figures_style2_aligned.png` - Best for presentations
- `combined_figures_style2_original.png`

## Key Features

### Data Filtering

**Strict Filtering**:
- Requires both Shape and Label information
- Requires at least 3 different identities per participant
- Excludes trials where Primary=Stranger and Secondary=Self

**Loose Filtering**:
- Only requires Primary to be Self or Stranger
- No filtering based on Secondary

### Cohen's d Calculation
- **RT**: Cohen's d = (Mean_Stranger - Mean_Self) / Pooled_SD
- **ACC**: Cohen's d = (Mean_Self - Mean_Stranger) / Pooled_SD

### Bootstrap Resampling
- 500 iterations per sample size
- Sample sizes: 10, 20, 30, ..., n_participants
- With replacement (matching R code)

## Recommendations

### For Publication
Use `results_figures/v4_legend_optimized/combined_figures_style1_aligned.png`
- Style 1 has cleaner appearance
- Aligned version allows fair comparison between Shape and Label

### For Presentations
Use `results_figures/v4_legend_optimized/combined_figures_style2_aligned.png`
- Style 2 has more explicit legend
- Easier to read in slides

## References

1. Sui, J., He, X., & Humphreys, G. W. (2012). Perceptual effects of self-relevance. *Journal of Experimental Psychology: Human Perception and Performance*, 38(5), 1105-1117.

2. Cohen, J. (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates.

## Contact

- Zhenxin Cai: czx@nnu.edu.cn
- Hu Chuan-Peng (Corresponding): hcp4715@hotmail.com
