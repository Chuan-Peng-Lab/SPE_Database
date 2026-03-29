#!/usr/bin/env python3
"""
Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions (v2)

This version correctly implements:
1. Separate Shape and Label analysis
2. RT and ACC as dependent variables
3. Bootstrap with replacement (as in R code)
4. Strict and Loose filtering criteria

Based on the R code from "use example_12.14.R" (bootstrap 2.0)

Usage:
    python bootstrap_analysis_v2.py
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
from scipy import stats
import warnings
import sys

warnings.filterwarnings('ignore')

# Set style for plots
plt.style.use('seaborn-v0_8-whitegrid')
sns.set_palette("husl")


def cohens_d(group1, group2):
    """
    Calculate Cohen's d between two groups.
    d = (mean1 - mean2) / pooled_sd
    """
    n1, n2 = len(group1), len(group2)
    if n1 < 2 or n2 < 2:
        return np.nan
    
    mean1, mean2 = np.mean(group1), np.mean(group2)
    var1, var2 = np.var(group1, ddof=1), np.var(group2, ddof=1)
    
    # Pooled standard deviation
    pooled_sd = np.sqrt(((n1 - 1) * var1 + (n2 - 1) * var2) / (n1 + n2 - 2))
    
    if pooled_sd == 0:
        return np.nan
    
    return (mean1 - mean2) / pooled_sd


def filter_valid_subjects(df, identity_column):
    """
    Filter subjects that have:
    - Self and Stranger identities
    - At least 3 different identities total
    """
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
    """
    Process data with STRICT filtering (matching R code logic).
    
    For Shape analysis:
    - Primary = Shape_Standardized_Identity
    - Secondary = Label_Standardized_Identity
    - Filter: Keep Primary=Self OR (Primary=Stranger AND Secondary!=Self) OR Primary=Other
    
    For Label analysis:
    - Primary = Label_Standardized_Identity
    - Secondary = Shape_Standardized_Identity
    - Filter: Keep Primary=Self OR (Primary=Stranger AND Secondary!=Self) OR Primary=Other
    """
    if analysis_type == 'Shape':
        identity_column = 'Shape_Standardized_Identity'
        secondary_column = 'Label_Standardized_Identity'
    else:  # Label
        identity_column = 'Label_Standardized_Identity'
        secondary_column = 'Shape_Standardized_Identity'
    
    # Filter valid subjects
    valid_subjects = filter_valid_subjects(df, identity_column)
    df_filtered = df[df['Subject'].isin(valid_subjects)].copy()
    
    # Create Primary and Secondary columns
    df_filtered['Primary'] = df_filtered[identity_column].apply(
        lambda x: x if x in ['Self', 'Stranger'] else 'Other'
    )
    df_filtered['Secondary'] = df_filtered[secondary_column].apply(
        lambda x: x if x in ['Self', 'Stranger'] else 'Other'
    )
    
    # Apply strict filtering
    mask = (
        (df_filtered['Primary'] == 'Self') |
        ((df_filtered['Primary'] == 'Stranger') & (df_filtered['Secondary'] != 'Self')) |
        (df_filtered['Primary'] == 'Other')
    )
    
    df_processed = df_filtered[mask].copy()
    
    return df_processed


def process_data_loose(df, analysis_type='Shape'):
    """
    Process data with LOOSE filtering.
    
    Only requires Primary to be Self or Stranger.
    No filtering based on Secondary.
    """
    if analysis_type == 'Shape':
        identity_column = 'Shape_Standardized_Identity'
    else:  # Label
        identity_column = 'Label_Standardized_Identity'
    
    # Create Primary column
    df_filtered = df.copy()
    df_filtered['Primary'] = df_filtered[identity_column].apply(
        lambda x: x if x in ['Self', 'Stranger'] else 'Other'
    )
    
    # Only keep Self and Stranger
    df_processed = df_filtered[df_filtered['Primary'].isin(['Self', 'Stranger'])].copy()
    
    return df_processed


def calculate_cohens_d_per_subject(df, measure='RT', min_trials=2):
    """
    Calculate Cohen's d for each participant.
    
    For RT: Cohen's d = (Mean_Stranger - Mean_Self) / Pooled_SD
    For ACC: Cohen's d = (Mean_Self - Mean_Stranger) / Pooled_SD
    """
    results = []
    
    for subject, subj_df in df.groupby('Subject'):
        self_data = subj_df[subj_df['Primary'] == 'Self']
        stranger_data = subj_df[subj_df['Primary'] == 'Stranger']
        
        if measure == 'RT':
            # For RT, use only correct trials (ACC == 1)
            self_values = self_data[self_data['ACC'] == 1]['RT_ms'].dropna().values
            stranger_values = stranger_data[stranger_data['ACC'] == 1]['RT_ms'].dropna().values
        else:  # ACC
            self_values = self_data['ACC'].dropna().values
            stranger_values = stranger_data['ACC'].dropna().values
        
        # Check minimum trials
        if len(self_values) < min_trials or len(stranger_values) < min_trials:
            continue
        
        # Calculate Cohen's d
        if measure == 'RT':
            d = cohens_d(stranger_values, self_values)  # Stranger - Self
        else:  # ACC
            d = cohens_d(self_values, stranger_values)  # Self - Stranger
        
        if not np.isnan(d):
            results.append({
                'Subject': subject,
                'Cohens_d': d,
                'n_self': len(self_values),
                'n_stranger': len(stranger_values),
                'mean_self': np.mean(self_values),
                'mean_stranger': np.mean(stranger_values)
            })
    
    return pd.DataFrame(results)


def bootstrap_analysis(cohens_d_values, n_bootstrap=500, min_n=10, step=10):
    """
    Perform bootstrap resampling WITH REPLACEMENT (matching R code).
    
    Parameters:
    - cohens_d_values: Array of Cohen's d values for all participants
    - n_bootstrap: Number of bootstrap iterations per sample size
    - min_n: Starting sample size
    - step: Increment in sample size
    
    Returns:
    - DataFrame with bootstrap results for each sample size
    """
    max_n = len(cohens_d_values)
    if max_n < min_n:
        return pd.DataFrame()
    
    # Generate sample sizes: from min_n to max_n, step by step
    sample_sizes = list(range(min_n, max_n + 1, step))
    if max_n % step != 0 and max_n not in sample_sizes:
        sample_sizes.append(max_n)
    sample_sizes = sorted(set(sample_sizes))
    
    results = []
    
    for n in sample_sizes:
        if n > len(cohens_d_values):
            continue
        
        # Bootstrap with replacement
        bootstrap_means = []
        for _ in range(n_bootstrap):
            # Sample with replacement
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
    """
    Run complete analysis for RT and ACC with Shape and Label.
    """
    results = {}
    
    # RT Analysis
    print(f"\n=== RT Analysis ({filtering_type} filtering) ===")
    
    # Process data for RT (use only mismatch trials)
    data_rt = data_filtered[data_filtered['Matching'] == 'Nonmatching'].copy()
    
    if filtering_type == 'Strict':
        rt_shape_data = process_data_strict(data_rt, 'Shape')
        rt_label_data = process_data_strict(data_rt, 'Label')
    else:
        rt_shape_data = process_data_loose(data_rt, 'Shape')
        rt_label_data = process_data_loose(data_rt, 'Label')
    
    # Calculate Cohen's d for RT
    rt_shape_cohens = calculate_cohens_d_per_subject(rt_shape_data, 'RT')
    rt_label_cohens = calculate_cohens_d_per_subject(rt_label_data, 'RT')
    
    print(f"  Shape: {len(rt_shape_cohens)} participants")
    print(f"  Label: {len(rt_label_cohens)} participants")
    
    # Bootstrap for RT
    if len(rt_shape_cohens) > 0:
        rt_shape_bootstrap = bootstrap_analysis(rt_shape_cohens['Cohens_d'].values, n_bootstrap)
        rt_shape_bootstrap['Identity'] = 'Shape'
    else:
        rt_shape_bootstrap = pd.DataFrame()
    
    if len(rt_label_cohens) > 0:
        rt_label_bootstrap = bootstrap_analysis(rt_label_cohens['Cohens_d'].values, n_bootstrap)
        rt_label_bootstrap['Identity'] = 'Label'
    else:
        rt_label_bootstrap = pd.DataFrame()
    
    rt_bootstrap_combined = pd.concat([rt_shape_bootstrap, rt_label_bootstrap], ignore_index=True)
    results['rt_bootstrap'] = rt_bootstrap_combined
    results['rt_shape_cohens'] = rt_shape_cohens
    results['rt_label_cohens'] = rt_label_cohens
    
    # ACC Analysis
    print(f"\n=== ACC Analysis ({filtering_type} filtering) ===")
    
    # Process data for ACC (use all mismatch trials)
    if filtering_type == 'Strict':
        acc_shape_data = process_data_strict(data_filtered, 'Shape')
        acc_label_data = process_data_strict(data_filtered, 'Label')
    else:
        acc_shape_data = process_data_loose(data_filtered, 'Shape')
        acc_label_data = process_data_loose(data_filtered, 'Label')
    
    # Calculate Cohen's d for ACC
    acc_shape_cohens = calculate_cohens_d_per_subject(acc_shape_data, 'ACC')
    acc_label_cohens = calculate_cohens_d_per_subject(acc_label_data, 'ACC')
    
    print(f"  Shape: {len(acc_shape_cohens)} participants")
    print(f"  Label: {len(acc_label_cohens)} participants")
    
    # Bootstrap for ACC
    if len(acc_shape_cohens) > 0:
        acc_shape_bootstrap = bootstrap_analysis(acc_shape_cohens['Cohens_d'].values, n_bootstrap)
        acc_shape_bootstrap['Identity'] = 'Shape'
    else:
        acc_shape_bootstrap = pd.DataFrame()
    
    if len(acc_label_cohens) > 0:
        acc_label_bootstrap = bootstrap_analysis(acc_label_cohens['Cohens_d'].values, n_bootstrap)
        acc_label_bootstrap['Identity'] = 'Label'
    else:
        acc_label_bootstrap = pd.DataFrame()
    
    acc_bootstrap_combined = pd.concat([acc_shape_bootstrap, acc_label_bootstrap], ignore_index=True)
    results['acc_bootstrap'] = acc_bootstrap_combined
    results['acc_shape_cohens'] = acc_shape_cohens
    results['acc_label_cohens'] = acc_label_cohens
    
    return results


def create_bootstrap_plot(bootstrap_results, measure='RT', filtering_type='Strict', output_path=None):
    """
    Create bootstrap plot showing Shape and Label in the same figure.
    """
    if bootstrap_results.empty:
        print(f"  No data for {measure} {filtering_type}")
        return None
    
    # Colors matching R code
    identity_colors = {'Shape': '#2E86AB', 'Label': '#A23B72'}
    
    fig, ax = plt.subplots(figsize=(12, 8))
    
    for identity in ['Shape', 'Label']:
        data = bootstrap_results[bootstrap_results['Identity'] == identity]
        if data.empty:
            continue
        
        color = identity_colors[identity]
        
        # Plot line and confidence interval
        ax.plot(data['SampleSize'], data['Mean_d'], 
                color=color, linewidth=2, label=identity)
        ax.fill_between(data['SampleSize'], 
                       data['CI_lower'], 
                       data['CI_upper'], 
                       color=color, alpha=0.2)
        ax.scatter(data['SampleSize'], data['Mean_d'], 
                  color=color, s=30, zorder=5)
    
    # Zero line
    ax.axhline(y=0, color='gray', linestyle='--', linewidth=1, alpha=0.7)
    
    # Labels
    if measure == 'RT':
        y_label = "Cohen's d (Stranger - Self)"
        title = f"Bootstrap Power Analysis of Reaction Time ({filtering_type} Filtering)"
    else:
        y_label = "Cohen's d (Self - Stranger)"
        title = f"Bootstrap Power Analysis of Accuracy ({filtering_type} Filtering)"
    
    ax.set_xlabel('Sample Size (Number of Participants)', fontsize=14, fontweight='bold')
    ax.set_ylabel(y_label, fontsize=14, fontweight='bold')
    ax.set_title(title, fontsize=16, fontweight='bold', family='Times New Roman')
    
    # Legend
    ax.legend(title='Social Identity Category', 
             title_fontsize=12, fontsize=11,
             loc='best', framealpha=0.9)
    
    # Style
    ax.spines['top'].set_visible(False)
    ax.spines['right'].set_visible(False)
    ax.spines['left'].set_linewidth(0.8)
    ax.spines['bottom'].set_linewidth(0.8)
    ax.tick_params(axis='both', labelsize=11)
    
    plt.tight_layout()
    
    if output_path:
        filename = f"bootstrap_{measure.lower()}_{filtering_type.lower()}.png"
        plt.savefig(output_path / filename, dpi=300, bbox_inches='tight')
        print(f"  Saved: {filename}")
    
    return fig


def create_combined_figure(strict_rt, strict_acc, loose_rt, loose_acc, output_path):
    """
    Create a 2x2 combined figure with all 4 plots.
    """
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    identity_colors = {'Shape': '#2E86AB', 'Label': '#A23B72'}
    
    plot_configs = [
        (axes[0, 0], strict_rt, 'RT', 'Strict'),
        (axes[0, 1], strict_acc, 'ACC', 'Strict'),
        (axes[1, 0], loose_rt, 'RT', 'Loose'),
        (axes[1, 1], loose_acc, 'ACC', 'Loose'),
    ]
    
    for ax, data, measure, filtering in plot_configs:
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
        
        ax.axhline(y=0, color='gray', linestyle='--', linewidth=1, alpha=0.7)
        
        if measure == 'RT':
            y_label = "Cohen's d (Stranger - Self)"
        else:
            y_label = "Cohen's d (Self - Stranger)"
        
        ax.set_xlabel('Sample Size', fontsize=11)
        ax.set_ylabel(y_label, fontsize=11)
        ax.set_title(f'{filtering} Filtering - {measure}', 
                    fontsize=13, fontweight='bold', family='Times New Roman')
        ax.legend(title='Identity', fontsize=9, title_fontsize=10)
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
    
    fig.suptitle('Self-Prioritization Effect in Mismatch Conditions\n(Bootstrap with Replacement, 500 iterations)', 
                fontsize=16, fontweight='bold', y=1.02)
    
    plt.tight_layout()
    plt.savefig(output_path / 'combined_figures_300dpi.png', dpi=300, bbox_inches='tight')
    print("\nSaved: combined_figures_300dpi.png")


def main():
    """Main analysis function."""
    
    print("=" * 80)
    print("Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions")
    print("Version 2.0 - Matching R code logic")
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
    
    # Merge all dataframes
    merged_df = pd.concat(all_data, ignore_index=True)
    print(f"Total merged data: {len(merged_df)} rows")
    
    # Check required columns
    required_cols = ['Subject', 'Matching', 'Shape_Standardized_Identity', 'RT_ms', 'ACC']
    missing_cols = [col for col in required_cols if col not in merged_df.columns]
    if missing_cols:
        print(f"ERROR: Missing columns: {missing_cols}")
        return
    
    # Check if Label_Standardized_Identity exists
    has_label = 'Label_Standardized_Identity' in merged_df.columns
    print(f"Has Label_Standardized_Identity: {has_label}")
    
    if not has_label:
        print("WARNING: Label_Standardized_Identity not found. Will use Shape for both analyses.")
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
    
    # Generate individual figures
    print("\n" + "=" * 80)
    print("GENERATING FIGURES")
    print("=" * 80)
    
    create_bootstrap_plot(strict_results['rt_bootstrap'], 'RT', 'Strict', output_path)
    create_bootstrap_plot(strict_results['acc_bootstrap'], 'ACC', 'Strict', output_path)
    create_bootstrap_plot(loose_results['rt_bootstrap'], 'RT', 'Loose', output_path)
    create_bootstrap_plot(loose_results['acc_bootstrap'], 'ACC', 'Loose', output_path)
    
    # Create combined figure
    create_combined_figure(
        strict_results['rt_bootstrap'],
        strict_results['acc_bootstrap'],
        loose_results['rt_bootstrap'],
        loose_results['acc_bootstrap'],
        output_path
    )
    
    # Save all results
    print("\n" + "=" * 80)
    print("SAVING RESULTS")
    print("=" * 80)
    
    # Save bootstrap results
    strict_results['rt_bootstrap'].to_csv(output_path / 'bootstrap_rt_strict.csv', index=False)
    strict_results['acc_bootstrap'].to_csv(output_path / 'bootstrap_acc_strict.csv', index=False)
    loose_results['rt_bootstrap'].to_csv(output_path / 'bootstrap_rt_loose.csv', index=False)
    loose_results['acc_bootstrap'].to_csv(output_path / 'bootstrap_acc_loose.csv', index=False)
    
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
    print("ANALYSIS COMPLETE!")
    print("=" * 80)


if __name__ == "__main__":
    main()
