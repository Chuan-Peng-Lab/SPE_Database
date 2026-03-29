#!/usr/bin/env python3
"""
Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions (v3)

Updates in v3:
1. Figure titles: "SPE calculated by strict/loose approach"
2. APA style: no grid lines, fixed axes
3. Two versions: 
   - Version 1: Sample Size as is
   - Version 2: Sample Size limited to min(Shape, Label) for each filtering

Usage:
    python bootstrap_analysis_v3.py
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from scipy import stats
import warnings
warnings.filterwarnings('ignore')

# Set APA style
plt.rcParams['font.family'] = 'Times New Roman'
plt.rcParams['font.size'] = 12


def cohens_d(group1, group2):
    """Calculate Cohen's d between two groups."""
    n1, n2 = len(group1), len(group2)
    if n1 < 2 or n2 < 2:
        return np.nan
    
    mean1, mean2 = np.mean(group1), np.mean(group2)
    var1, var2 = np.var(group1, ddof=1), np.var(group2, ddof=1)
    pooled_sd = np.sqrt(((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2))
    
    if pooled_sd == 0:
        return np.nan
    
    return (mean1 - mean2) / pooled_sd


def filter_valid_subjects(df, identity_column):
    """Filter subjects with Self, Stranger, and at least 3 identities."""
    valid_subjects = []
    
    for subject, subj_df in df.groupby('Subject'):
        identities = set(subj_df[identity_column].dropna().unique())
        has_self = 'Self' in identities
        has_stranger = 'Stranger' in identities
        identity_count = len(identities)
        
        if has_self and has_stranger and identity_count >= 3:
            valid_subjects.append(subject)
    
    return valid_subjects


def process_data_strict(df, analysis_type='Shape'):
    """Process data with STRICT filtering."""
    if analysis_type == 'Shape':
        identity_column = 'Shape_Standardized_Identity'
        secondary_column = 'Label_Standardized_Identity'
    else:
        identity_column = 'Label_Standardized_Identity'
        secondary_column = 'Shape_Standardized_Identity'
    
    valid_subjects = filter_valid_subjects(df, identity_column)
    df_filtered = df[df['Subject'].isin(valid_subjects)].copy()
    
    df_filtered['Primary'] = df_filtered[identity_column].apply(
        lambda x: x if x in ['Self', 'Stranger'] else 'Other'
    )
    df_filtered['Secondary'] = df_filtered[secondary_column].apply(
        lambda x: x if x in ['Self', 'Stranger'] else 'Other'
    )
    
    mask = (
        (df_filtered['Primary'] == 'Self') |
        ((df_filtered['Primary'] == 'Stranger') & (df_filtered['Secondary'] != 'Self')) |
        (df_filtered['Primary'] == 'Other')
    )
    
    return df_filtered[mask].copy()


def process_data_loose(df, analysis_type='Shape'):
    """Process data with LOOSE filtering."""
    if analysis_type == 'Shape':
        identity_column = 'Shape_Standardized_Identity'
    else:
        identity_column = 'Label_Standardized_Identity'
    
    df_filtered = df.copy()
    df_filtered['Primary'] = df_filtered[identity_column].apply(
        lambda x: x if x in ['Self', 'Stranger'] else 'Other'
    )
    
    return df_filtered[df_filtered['Primary'].isin(['Self', 'Stranger'])].copy()


def calculate_cohens_d_per_subject(df, measure='RT', min_trials=2):
    """Calculate Cohen's d for each participant."""
    results = []
    
    for subject, subj_df in df.groupby('Subject'):
        self_data = subj_df[subj_df['Primary'] == 'Self']
        stranger_data = subj_df[subj_df['Primary'] == 'Stranger']
        
        if measure == 'RT':
            self_values = self_data[self_data['ACC'] == 1]['RT_ms'].dropna().values
            stranger_values = stranger_data[stranger_data['ACC'] == 1]['RT_ms'].dropna().values
        else:
            self_values = self_data['ACC'].dropna().values
            stranger_values = stranger_data['ACC'].dropna().values
        
        if len(self_values) < min_trials or len(stranger_values) < min_trials:
            continue
        
        if measure == 'RT':
            d = cohens_d(stranger_values, self_values)
        else:
            d = cohens_d(self_values, stranger_values)
        
        if not np.isnan(d):
            results.append({
                'Subject': subject,
                'Cohens_d': d,
                'n_self': len(self_values),
                'n_stranger': len(stranger_values)
            })
    
    return pd.DataFrame(results)


def bootstrap_analysis(cohens_d_values, n_bootstrap=500, min_n=10, step=10, max_n=None):
    """Perform bootstrap resampling WITH REPLACEMENT."""
    total_n = len(cohens_d_values)
    if total_n < min_n:
        return pd.DataFrame()
    
    if max_n is None:
        max_n = total_n
    else:
        max_n = min(max_n, total_n)
    
    sample_sizes = list(range(min_n, max_n + 1, step))
    if max_n % step != 0 and max_n not in sample_sizes:
        sample_sizes.append(max_n)
    sample_sizes = sorted(set(sample_sizes))
    
    results = []
    
    for n in sample_sizes:
        if n > total_n:
            continue
        
        bootstrap_means = []
        for _ in range(n_bootstrap):
            sampled = np.random.choice(cohens_d_values, size=n, replace=True)
            bootstrap_means.append(np.mean(sampled))
        
        bootstrap_means = np.array(bootstrap_means)
        
        results.append({
            'SampleSize': n,
            'Mean_d': np.mean(bootstrap_means),
            'SE': np.std(bootstrap_means),
            'CI_lower': np.percentile(bootstrap_means, 2.5),
            'CI_upper': np.percentile(bootstrap_means, 97.5)
        })
    
    return pd.DataFrame(results)


def run_analysis(data_filtered, filtering_type='Strict', n_bootstrap=500):
    """Run complete analysis for RT and ACC with Shape and Label."""
    results = {}
    
    # RT Analysis
    print(f"\n=== RT Analysis ({filtering_type} filtering) ===")
    
    data_rt = data_filtered[data_filtered['Matching'] == 'Nonmatching'].copy()
    
    if filtering_type == 'Strict':
        rt_shape_data = process_data_strict(data_rt, 'Shape')
        rt_label_data = process_data_strict(data_rt, 'Label')
    else:
        rt_shape_data = process_data_loose(data_rt, 'Shape')
        rt_label_data = process_data_loose(data_rt, 'Label')
    
    rt_shape_cohens = calculate_cohens_d_per_subject(rt_shape_data, 'RT')
    rt_label_cohens = calculate_cohens_d_per_subject(rt_label_data, 'RT')
    
    print(f"  Shape: {len(rt_shape_cohens)} participants")
    print(f"  Label: {len(rt_label_cohens)} participants")
    
    # Get max_n for alignment
    rt_max_n = min(len(rt_shape_cohens), len(rt_label_cohens))
    
    if len(rt_shape_cohens) > 0:
        rt_shape_bootstrap = bootstrap_analysis(rt_shape_cohens['Cohens_d'].values, n_bootstrap)
        rt_shape_bootstrap['Identity'] = 'Shape'
        rt_shape_bootstrap_aligned = bootstrap_analysis(rt_shape_cohens['Cohens_d'].values, n_bootstrap, max_n=rt_max_n)
        rt_shape_bootstrap_aligned['Identity'] = 'Shape'
    else:
        rt_shape_bootstrap = pd.DataFrame()
        rt_shape_bootstrap_aligned = pd.DataFrame()
    
    if len(rt_label_cohens) > 0:
        rt_label_bootstrap = bootstrap_analysis(rt_label_cohens['Cohens_d'].values, n_bootstrap)
        rt_label_bootstrap['Identity'] = 'Label'
        rt_label_bootstrap_aligned = bootstrap_analysis(rt_label_cohens['Cohens_d'].values, n_bootstrap, max_n=rt_max_n)
        rt_label_bootstrap_aligned['Identity'] = 'Label'
    else:
        rt_label_bootstrap = pd.DataFrame()
        rt_label_bootstrap_aligned = pd.DataFrame()
    
    rt_bootstrap_combined = pd.concat([rt_shape_bootstrap, rt_label_bootstrap], ignore_index=True)
    rt_bootstrap_aligned = pd.concat([rt_shape_bootstrap_aligned, rt_label_bootstrap_aligned], ignore_index=True)
    
    results['rt_bootstrap'] = rt_bootstrap_combined
    results['rt_bootstrap_aligned'] = rt_bootstrap_aligned
    results['rt_shape_cohens'] = rt_shape_cohens
    results['rt_label_cohens'] = rt_label_cohens
    
    # ACC Analysis
    print(f"\n=== ACC Analysis ({filtering_type} filtering) ===")
    
    if filtering_type == 'Strict':
        acc_shape_data = process_data_strict(data_filtered, 'Shape')
        acc_label_data = process_data_strict(data_filtered, 'Label')
    else:
        acc_shape_data = process_data_loose(data_filtered, 'Shape')
        acc_label_data = process_data_loose(data_filtered, 'Label')
    
    acc_shape_cohens = calculate_cohens_d_per_subject(acc_shape_data, 'ACC')
    acc_label_cohens = calculate_cohens_d_per_subject(acc_label_data, 'ACC')
    
    print(f"  Shape: {len(acc_shape_cohens)} participants")
    print(f"  Label: {len(acc_label_cohens)} participants")
    
    # Get max_n for alignment
    acc_max_n = min(len(acc_shape_cohens), len(acc_label_cohens))
    
    if len(acc_shape_cohens) > 0:
        acc_shape_bootstrap = bootstrap_analysis(acc_shape_cohens['Cohens_d'].values, n_bootstrap)
        acc_shape_bootstrap['Identity'] = 'Shape'
        acc_shape_bootstrap_aligned = bootstrap_analysis(acc_shape_cohens['Cohens_d'].values, n_bootstrap, max_n=acc_max_n)
        acc_shape_bootstrap_aligned['Identity'] = 'Shape'
    else:
        acc_shape_bootstrap = pd.DataFrame()
        acc_shape_bootstrap_aligned = pd.DataFrame()
    
    if len(acc_label_cohens) > 0:
        acc_label_bootstrap = bootstrap_analysis(acc_label_cohens['Cohens_d'].values, n_bootstrap)
        acc_label_bootstrap['Identity'] = 'Label'
        acc_label_bootstrap_aligned = bootstrap_analysis(acc_label_cohens['Cohens_d'].values, n_bootstrap, max_n=acc_max_n)
        acc_label_bootstrap_aligned['Identity'] = 'Label'
    else:
        acc_label_bootstrap = pd.DataFrame()
        acc_label_bootstrap_aligned = pd.DataFrame()
    
    acc_bootstrap_combined = pd.concat([acc_shape_bootstrap, acc_label_bootstrap], ignore_index=True)
    acc_bootstrap_aligned = pd.concat([acc_shape_bootstrap_aligned, acc_label_bootstrap_aligned], ignore_index=True)
    
    results['acc_bootstrap'] = acc_bootstrap_combined
    results['acc_bootstrap_aligned'] = acc_bootstrap_aligned
    results['acc_shape_cohens'] = acc_shape_cohens
    results['acc_label_cohens'] = acc_label_cohens
    
    return results


def create_apa_figure(strict_rt, strict_acc, loose_rt, loose_acc, 
                      version='original', output_path=None):
    """
    Create APA-style figure with fixed axes.
    
    version: 'original' or 'aligned'
    """
    # Colors
    identity_colors = {'Shape': '#2E86AB', 'Label': '#A23B72'}
    
    # Fixed axis limits (for consistency across figures)
    x_min, x_max = 0, 500
    y_min, y_max = -0.4, 0.4
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    plot_configs = [
        (axes[0, 0], strict_rt, 'RT', 'SPE calculated by strict approach'),
        (axes[0, 1], strict_acc, 'ACC', 'SPE calculated by strict approach'),
        (axes[1, 0], loose_rt, 'RT', 'SPE calculated by loose approach'),
        (axes[1, 1], loose_acc, 'ACC', 'SPE calculated by loose approach'),
    ]
    
    for ax, data, measure, title in plot_configs:
        # APA style: white background, no grid
        ax.set_facecolor('white')
        ax.grid(False)
        
        if data.empty:
            ax.text(0.5, 0.5, 'No Data', ha='center', va='center', 
                   transform=ax.transAxes, fontsize=14)
            continue
        
        for identity in ['Shape', 'Label']:
            subset = data[data['Identity'] == identity]
            if subset.empty:
                continue
            
            color = identity_colors[identity]
            ax.plot(subset['SampleSize'], subset['Mean_d'], 
                   color=color, linewidth=2, label=identity)
            ax.fill_between(subset['SampleSize'], 
                           subset['CI_lower'], 
                           subset['CI_upper'], 
                           color=color, alpha=0.2)
            ax.scatter(subset['SampleSize'], subset['Mean_d'], 
                      color=color, s=20, zorder=5)
        
        # Zero line
        ax.axhline(y=0, color='black', linestyle='--', linewidth=0.8, alpha=0.5)
        
        # APA style axes
        ax.set_xlim(x_min, x_max)
        ax.set_ylim(y_min, y_max)
        
        # Labels
        if measure == 'RT':
            y_label = "Cohen's d (Stranger - Self)"
            subplot_label = 'A' if 'strict' in title.lower() else 'C'
        else:
            y_label = "Cohen's d (Self - Stranger)"
            subplot_label = 'B' if 'strict' in title.lower() else 'D'
        
        ax.set_xlabel('Sample Size', fontsize=12, fontweight='bold')
        ax.set_ylabel(y_label, fontsize=12, fontweight='bold')
        
        # Title with measure
        full_title = f"{title}\n({measure})"
        ax.set_title(full_title, fontsize=13, fontweight='bold', family='Times New Roman')
        
        # Subplot label
        ax.text(-0.1, 1.1, subplot_label, transform=ax.transAxes, 
               fontsize=16, fontweight='bold', va='top', ha='right')
        
        # Legend
        ax.legend(title='Identity', fontsize=10, title_fontsize=11, 
                 loc='upper right', framealpha=0.9)
        
        # APA style: remove top and right spines
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_linewidth(1)
        ax.spines['bottom'].set_linewidth(1)
        
        # Tick marks
        ax.tick_params(axis='both', which='major', labelsize=10)
    
    plt.tight_layout()
    
    if output_path:
        filename = f'combined_figures_apa_{version}.png'
        plt.savefig(output_path / filename, dpi=300, bbox_inches='tight', 
                   facecolor='white', edgecolor='none')
        print(f"\nSaved: {filename}")
    
    return fig


def main():
    """Main analysis function."""
    
    print("=" * 80)
    print("Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions")
    print("Version 3.0 - APA Style with Fixed Axes")
    print("=" * 80)
    
    # Define paths
    data_path = Path("D:/GitHub_programe/GitHub/SPE_Database/1_Data")
    output_path = Path("D:/GitHub_programe/GitHub/SPE_Database/3_Reports/Bootstrap")
    output_path.mkdir(exist_ok=True)
    
    # Find all Clean.csv files
    clean_files = list(data_path.rglob("*_Clean.csv"))
    print(f"\nFound {len(clean_files)} Clean.csv files")
    
    # Load and merge all Clean.csv files
    print("\nLoading data...")
    all_data = []
    
    for file_path in clean_files:
        try:
            df = pd.read_csv(file_path)
            df['Source'] = file_path.stem
            all_data.append(df)
        except Exception as e:
            print(f"  Error loading {file_path.name}: {e}")
    
    merged_df = pd.concat(all_data, ignore_index=True)
    print(f"Total merged data: {len(merged_df)} rows")
    
    # Check required columns
    required_cols = ['Subject', 'Matching', 'Shape_Standardized_Identity', 'RT_ms', 'ACC']
    missing_cols = [col for col in required_cols if col not in merged_df.columns]
    if missing_cols:
        print(f"ERROR: Missing columns: {missing_cols}")
        return
    
    has_label = 'Label_Standardized_Identity' in merged_df.columns
    print(f"Has Label_Standardized_Identity: {has_label}")
    
    if not has_label:
        print("WARNING: Label_Standardized_Identity not found. Using Shape for both.")
        merged_df['Label_Standardized_Identity'] = merged_df['Shape_Standardized_Identity']
    
    # Filter for Nonmatching trials
    mismatch_df = merged_df[merged_df['Matching'] == 'Nonmatching'].copy()
    print(f"Mismatch trials: {len(mismatch_df)} rows")
    print(f"Unique participants: {mismatch_df['Subject'].nunique()}")
    
    # Run analyses
    print("\n" + "=" * 80)
    print("STRICT FILTERING ANALYSIS")
    print("=" * 80)
    strict_results = run_analysis(mismatch_df, 'Strict', n_bootstrap=500)
    
    print("\n" + "=" * 80)
    print("LOOSE FILTERING ANALYSIS")
    print("=" * 80)
    loose_results = run_analysis(mismatch_df, 'Loose', n_bootstrap=500)
    
    # Generate figures
    print("\n" + "=" * 80)
    print("GENERATING APA-STYLE FIGURES")
    print("=" * 80)
    
    # Version 1: Original sample sizes
    create_apa_figure(
        strict_results['rt_bootstrap'],
        strict_results['acc_bootstrap'],
        loose_results['rt_bootstrap'],
        loose_results['acc_bootstrap'],
        version='original',
        output_path=output_path
    )
    
    # Version 2: Aligned sample sizes (min of Shape and Label)
    create_apa_figure(
        strict_results['rt_bootstrap_aligned'],
        strict_results['acc_bootstrap_aligned'],
        loose_results['rt_bootstrap_aligned'],
        loose_results['acc_bootstrap_aligned'],
        version='aligned',
        output_path=output_path
    )
    
    # Save all results
    print("\n" + "=" * 80)
    print("SAVING RESULTS")
    print("=" * 80)
    
    # Save bootstrap results
    strict_results['rt_bootstrap'].to_csv(output_path / 'bootstrap_rt_strict_original.csv', index=False)
    strict_results['acc_bootstrap'].to_csv(output_path / 'bootstrap_acc_strict_original.csv', index=False)
    loose_results['rt_bootstrap'].to_csv(output_path / 'bootstrap_rt_loose_original.csv', index=False)
    loose_results['acc_bootstrap'].to_csv(output_path / 'bootstrap_acc_loose_original.csv', index=False)
    
    strict_results['rt_bootstrap_aligned'].to_csv(output_path / 'bootstrap_rt_strict_aligned.csv', index=False)
    strict_results['acc_bootstrap_aligned'].to_csv(output_path / 'bootstrap_acc_strict_aligned.csv', index=False)
    loose_results['rt_bootstrap_aligned'].to_csv(output_path / 'bootstrap_rt_loose_aligned.csv', index=False)
    loose_results['acc_bootstrap_aligned'].to_csv(output_path / 'bootstrap_acc_loose_aligned.csv', index=False)
    
    # Save Cohen's d by participant
    all_cohens_d = []
    for results, filtering in [(strict_results, 'Strict'), (loose_results, 'Loose')]:
        for measure in ['rt', 'acc']:
            for identity in ['shape', 'label']:
                key = f'{measure}_{identity}_cohens'
                if key in results and not results[key].empty:
                    df = results[key].copy()
                    df['Filtering'] = filtering
                    df['Measure'] = measure.upper()
                    df['Identity'] = identity.capitalize()
                    all_cohens_d.append(df)
    
    if all_cohens_d:
        pd.concat(all_cohens_d, ignore_index=True).to_csv(
            output_path / 'cohens_d_by_participant.csv', index=False
        )
    
    # Print summary
    print("\n" + "=" * 80)
    print("ANALYSIS SUMMARY")
    print("=" * 80)
    
    for filtering, results in [('Strict', strict_results), ('Loose', loose_results)]:
        print(f"\n{filtering} Filtering:")
        for measure in ['RT', 'ACC']:
            bootstrap_key = f'{measure.lower()}_bootstrap'
            if not results[bootstrap_key].empty:
                final = results[bootstrap_key].groupby('Identity').last()
                print(f"  {measure}:")
                for identity in ['Shape', 'Label']:
                    if identity in final.index:
                        row = final.loc[identity]
                        sig = "Yes" if (row['CI_lower'] > 0 or row['CI_upper'] < 0) else "No"
                        print(f"    {identity}: Mean d = {row['Mean_d']:.3f}, "
                              f"95% CI [{row['CI_lower']:.3f}, {row['CI_upper']:.3f}], "
                              f"Significant: {sig}")
    
    print("\n" + "=" * 80)
    print("OUTPUT FILES:")
    print("=" * 80)
    print("\nFigures (300 dpi):")
    print("  - combined_figures_apa_original.png (Version 1: original sample sizes)")
    print("  - combined_figures_apa_aligned.png (Version 2: aligned sample sizes)")
    print("\nData files:")
    print("  - bootstrap_*_original.csv (Version 1 results)")
    print("  - bootstrap_*_aligned.csv (Version 2 results)")
    print("  - cohens_d_by_participant.csv (Individual Cohen's d values)")
    
    print("\n" + "=" * 80)
    print("ANALYSIS COMPLETE!")
    print("=" * 80)


if __name__ == "__main__":
    main()
