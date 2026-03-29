#!/usr/bin/env python3
"""
Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions

Objective: Compute self-prioritization effect (Self vs. Stranger) in mismatch 
conditions with bootstrap resampling and sequential sample size augmentation.

Usage:
    python bootstrap_analysis.py

Output:
    - cohens_d_by_participant.csv
    - bootstrap_results.csv
    - figure1_shape_strict.png
    - figure2_label_strict.png
    - figure3_shape_loose.png
    - figure4_label_loose.png
    - combined_figures_300dpi.png
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


def calculate_strict_cohens_d(df, baseline='Shape'):
    """
    Calculate Cohen's d with strict filtering.
    - Requires both Shape and Label standardized identity columns
    - Excludes cases where Shape=Stranger and Label=Self (controlling for self-relevance)
    - Requires at least 3 different identities per participant
    """
    results = []
    
    # Group by participant
    for (source, subject), subj_df in df.groupby(['Source', 'Subject']):
        
        # Check if we have both Shape and Label columns
        if 'Shape_Standardized_Identity' not in subj_df.columns:
            continue
        if 'Label_Standardized_Identity' not in subj_df.columns:
            continue
        
        # Get unique identities
        shape_identities = set(subj_df['Shape_Standardized_Identity'].dropna().unique())
        label_identities = set(subj_df['Label_Standardized_Identity'].dropna().unique())
        
        # Require at least 3 different identities
        if len(shape_identities) < 3 or len(label_identities) < 3:
            continue
        
        # Filter based on baseline
        if baseline == 'Shape':
            # Exclude trials where Shape=Stranger and Label=Self
            filtered = subj_df[
                ~((subj_df['Shape_Standardized_Identity'] == 'Stranger') & 
                  (subj_df['Label_Standardized_Identity'] == 'Self'))
            ]
            identity_col = 'Shape_Standardized_Identity'
        else:  # Label baseline
            # Exclude trials where Label=Stranger and Shape=Self
            filtered = subj_df[
                ~((subj_df['Label_Standardized_Identity'] == 'Stranger') & 
                  (subj_df['Shape_Standardized_Identity'] == 'Self'))
            ]
            identity_col = 'Label_Standardized_Identity'
        
        # Get RT for Self and Stranger
        self_rt = filtered[filtered[identity_col] == 'Self']['RT_ms'].values
        stranger_rt = filtered[filtered[identity_col] == 'Stranger']['RT_ms'].values
        
        # Calculate Cohen's d
        d = cohens_d(stranger_rt, self_rt)
        
        if not np.isnan(d):
            results.append({
                'Source': source,
                'Subject': subject,
                'Baseline': baseline,
                'Filtering': 'Strict',
                'Cohens_d': d,
                'n_Self': len(self_rt),
                'n_Stranger': len(stranger_rt)
            })
    
    return pd.DataFrame(results)


def calculate_loose_cohens_d(df, baseline='Shape'):
    """
    Calculate Cohen's d with loose filtering.
    - Only requires Shape to be Self or Stranger
    - No need to control for Label=Self when Shape=Stranger
    """
    results = []
    
    # Group by participant
    for (source, subject), subj_df in df.groupby(['Source', 'Subject']):
        
        # Check if we have Shape column
        if 'Shape_Standardized_Identity' not in subj_df.columns:
            continue
        
        # Filter based on baseline
        if baseline == 'Shape':
            identity_col = 'Shape_Standardized_Identity'
        else:  # Label baseline
            if 'Label_Standardized_Identity' not in subj_df.columns:
                continue
            identity_col = 'Label_Standardized_Identity'
        
        # Get RT for Self and Stranger
        self_rt = subj_df[subj_df[identity_col] == 'Self']['RT_ms'].values
        stranger_rt = subj_df[subj_df[identity_col] == 'Stranger']['RT_ms'].values
        
        # Calculate Cohen's d
        d = cohens_d(stranger_rt, self_rt)
        
        if not np.isnan(d):
            results.append({
                'Source': source,
                'Subject': subject,
                'Baseline': baseline,
                'Filtering': 'Loose',
                'Cohens_d': d,
                'n_Self': len(self_rt),
                'n_Stranger': len(stranger_rt)
            })
    
    return pd.DataFrame(results)


def bootstrap_sequential_sample_size(cohens_d_values, n_iterations=1000, 
                                     min_n=10, max_n=None, step=10):
    """
    Perform bootstrap resampling with sequential sample size augmentation.
    
    Parameters:
    - cohens_d_values: Array of Cohen's d values for all participants
    - n_iterations: Number of bootstrap iterations per sample size
    - min_n: Starting sample size
    - max_n: Maximum sample size (default: total participants)
    - step: Increment in sample size
    
    Returns:
    - DataFrame with bootstrap results for each sample size
    """
    if max_n is None:
        max_n = len(cohens_d_values)
    
    results = []
    
    for n in range(min_n, max_n + 1, step):
        bootstrap_means = []
        
        for _ in range(n_iterations):
            # Resample with replacement
            sample = np.random.choice(cohens_d_values, size=n, replace=True)
            bootstrap_means.append(np.mean(sample))
        
        bootstrap_means = np.array(bootstrap_means)
        
        results.append({
            'Sample_Size': n,
            'Mean_Cohens_d': np.mean(bootstrap_means),
            'SD_Cohens_d': np.std(bootstrap_means),
            'CI_lower': np.percentile(bootstrap_means, 2.5),
            'CI_upper': np.percentile(bootstrap_means, 97.5),
            'n_bootstrap': n_iterations
        })
    
    return pd.DataFrame(results)


def generate_figures(bootstrap_df, output_path):
    """Generate all 4 figures and combined figure."""
    
    # Figure 1: Strict filtering - Shape baseline
    fig, ax = plt.subplots(figsize=(10, 6))
    data = bootstrap_df[(bootstrap_df['Filtering'] == 'Strict') & 
                        (bootstrap_df['Baseline'] == 'Shape')]
    ax.plot(data['Sample_Size'], data['Mean_Cohens_d'], 'b-', linewidth=2, label='Mean Cohen\'s d')
    ax.fill_between(data['Sample_Size'], data['CI_lower'], data['CI_upper'], alpha=0.3, label='95% CI')
    ax.axhline(y=0, color='r', linestyle='--', linewidth=1, label='No effect')
    ax.set_xlabel('Sample Size', fontsize=12)
    ax.set_ylabel('Cohen\'s d (Stranger - Self)', fontsize=12)
    ax.set_title('Figure 1: Strict Filtering - Shape Baseline\n(Self-Prioritization Effect in Mismatch Conditions)', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='best')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path / 'figure1_shape_strict.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Figure 2: Strict filtering - Label baseline
    fig, ax = plt.subplots(figsize=(10, 6))
    data = bootstrap_df[(bootstrap_df['Filtering'] == 'Strict') & 
                        (bootstrap_df['Baseline'] == 'Label')]
    ax.plot(data['Sample_Size'], data['Mean_Cohens_d'], 'g-', linewidth=2, label='Mean Cohen\'s d')
    ax.fill_between(data['Sample_Size'], data['CI_lower'], data['CI_upper'], alpha=0.3, label='95% CI')
    ax.axhline(y=0, color='r', linestyle='--', linewidth=1, label='No effect')
    ax.set_xlabel('Sample Size', fontsize=12)
    ax.set_ylabel('Cohen\'s d (Stranger - Self)', fontsize=12)
    ax.set_title('Figure 2: Strict Filtering - Label Baseline\n(Self-Prioritization Effect in Mismatch Conditions)', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='best')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path / 'figure2_label_strict.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Figure 3: Loose filtering - Shape baseline
    fig, ax = plt.subplots(figsize=(10, 6))
    data = bootstrap_df[(bootstrap_df['Filtering'] == 'Loose') & 
                        (bootstrap_df['Baseline'] == 'Shape')]
    ax.plot(data['Sample_Size'], data['Mean_Cohens_d'], 'b-', linewidth=2, label='Mean Cohen\'s d')
    ax.fill_between(data['Sample_Size'], data['CI_lower'], data['CI_upper'], alpha=0.3, label='95% CI')
    ax.axhline(y=0, color='r', linestyle='--', linewidth=1, label='No effect')
    ax.set_xlabel('Sample Size', fontsize=12)
    ax.set_ylabel('Cohen\'s d (Stranger - Self)', fontsize=12)
    ax.set_title('Figure 3: Loose Filtering - Shape Baseline\n(Self-Prioritization Effect in Mismatch Conditions)', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='best')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path / 'figure3_shape_loose.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Figure 4: Loose filtering - Label baseline
    fig, ax = plt.subplots(figsize=(10, 6))
    data = bootstrap_df[(bootstrap_df['Filtering'] == 'Loose') & 
                        (bootstrap_df['Baseline'] == 'Label')]
    ax.plot(data['Sample_Size'], data['Mean_Cohens_d'], 'g-', linewidth=2, label='Mean Cohen\'s d')
    ax.fill_between(data['Sample_Size'], data['CI_lower'], data['CI_upper'], alpha=0.3, label='95% CI')
    ax.axhline(y=0, color='r', linestyle='--', linewidth=1, label='No effect')
    ax.set_xlabel('Sample Size', fontsize=12)
    ax.set_ylabel('Cohen\'s d (Stranger - Self)', fontsize=12)
    ax.set_title('Figure 4: Loose Filtering - Label Baseline\n(Self-Prioritization Effect in Mismatch Conditions)', 
                 fontsize=14, fontweight='bold')
    ax.legend(loc='best')
    ax.grid(True, alpha=0.3)
    plt.tight_layout()
    plt.savefig(output_path / 'figure4_label_loose.png', dpi=300, bbox_inches='tight')
    plt.close()
    
    # Combined figure
    fig, axes = plt.subplots(2, 2, figsize=(16, 12))
    
    # Figure 1: Strict - Shape
    ax1 = axes[0, 0]
    data1 = bootstrap_df[(bootstrap_df['Filtering'] == 'Strict') & 
                         (bootstrap_df['Baseline'] == 'Shape')]
    ax1.plot(data1['Sample_Size'], data1['Mean_Cohens_d'], 'b-', linewidth=2)
    ax1.fill_between(data1['Sample_Size'], data1['CI_lower'], data1['CI_upper'], alpha=0.3)
    ax1.axhline(y=0, color='r', linestyle='--', linewidth=1)
    ax1.set_xlabel('Sample Size', fontsize=10)
    ax1.set_ylabel('Cohen\'s d', fontsize=10)
    ax1.set_title('A. Strict Filtering - Shape Baseline', fontsize=12, fontweight='bold')
    ax1.grid(True, alpha=0.3)
    
    # Figure 2: Strict - Label
    ax2 = axes[0, 1]
    data2 = bootstrap_df[(bootstrap_df['Filtering'] == 'Strict') & 
                         (bootstrap_df['Baseline'] == 'Label')]
    ax2.plot(data2['Sample_Size'], data2['Mean_Cohens_d'], 'g-', linewidth=2)
    ax2.fill_between(data2['Sample_Size'], data2['CI_lower'], data2['CI_upper'], alpha=0.3)
    ax2.axhline(y=0, color='r', linestyle='--', linewidth=1)
    ax2.set_xlabel('Sample Size', fontsize=10)
    ax2.set_ylabel('Cohen\'s d', fontsize=10)
    ax2.set_title('B. Strict Filtering - Label Baseline', fontsize=12, fontweight='bold')
    ax2.grid(True, alpha=0.3)
    
    # Figure 3: Loose - Shape
    ax3 = axes[1, 0]
    data3 = bootstrap_df[(bootstrap_df['Filtering'] == 'Loose') & 
                         (bootstrap_df['Baseline'] == 'Shape')]
    ax3.plot(data3['Sample_Size'], data3['Mean_Cohens_d'], 'b-', linewidth=2)
    ax3.fill_between(data3['Sample_Size'], data3['CI_lower'], data3['CI_upper'], alpha=0.3)
    ax3.axhline(y=0, color='r', linestyle='--', linewidth=1)
    ax3.set_xlabel('Sample Size', fontsize=10)
    ax3.set_ylabel('Cohen\'s d', fontsize=10)
    ax3.set_title('C. Loose Filtering - Shape Baseline', fontsize=12, fontweight='bold')
    ax3.grid(True, alpha=0.3)
    
    # Figure 4: Loose - Label
    ax4 = axes[1, 1]
    data4 = bootstrap_df[(bootstrap_df['Filtering'] == 'Loose') & 
                         (bootstrap_df['Baseline'] == 'Label')]
    ax4.plot(data4['Sample_Size'], data4['Mean_Cohens_d'], 'g-', linewidth=2)
    ax4.fill_between(data4['Sample_Size'], data4['CI_lower'], data4['CI_upper'], alpha=0.3)
    ax4.axhline(y=0, color='r', linestyle='--', linewidth=1)
    ax4.set_xlabel('Sample Size', fontsize=10)
    ax4.set_ylabel('Cohen\'s d', fontsize=10)
    ax4.set_title('D. Loose Filtering - Label Baseline', fontsize=12, fontweight='bold')
    ax4.grid(True, alpha=0.3)
    
    # Add overall title
    fig.suptitle('Self-Prioritization Effect in Mismatch Conditions\n(Bootstrap Resampling with Sequential Sample Size Augmentation)', 
                 fontsize=16, fontweight='bold', y=1.02)
    
    plt.tight_layout()
    plt.savefig(output_path / 'combined_figures_300dpi.png', dpi=300, bbox_inches='tight')
    plt.close()


def main():
    """Main analysis function."""
    
    print("=" * 80)
    print("Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions")
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
            print(f"  Loaded: {file_path.name} - {len(df)} rows")
        except Exception as e:
            print(f"  Error loading {file_path.name}: {e}")
    
    # Merge all dataframes
    merged_df = pd.concat(all_data, ignore_index=True)
    print(f"\nTotal merged data: {len(merged_df)} rows")
    
    # Filter for Nonmatching trials only
    mismatch_df = merged_df[merged_df['Matching'] == 'Nonmatching'].copy()
    print(f"Mismatch trials: {len(mismatch_df)} rows")
    print(f"Unique participants: {mismatch_df['Subject'].nunique()}")
    
    # Calculate Cohen's d for all conditions
    print("\nCalculating Cohen's d...")
    strict_shape = calculate_strict_cohens_d(mismatch_df, baseline='Shape')
    strict_label = calculate_strict_cohens_d(mismatch_df, baseline='Label')
    loose_shape = calculate_loose_cohens_d(mismatch_df, baseline='Shape')
    loose_label = calculate_loose_cohens_d(mismatch_df, baseline='Label')
    
    print(f"Strict filtering - Shape: {len(strict_shape)} participants")
    print(f"Strict filtering - Label: {len(strict_label)} participants")
    print(f"Loose filtering - Shape: {len(loose_shape)} participants")
    print(f"Loose filtering - Label: {len(loose_label)} participants")
    
    # Combine all Cohen's d results
    all_cohens_d = pd.concat([strict_shape, strict_label, loose_shape, loose_label], 
                             ignore_index=True)
    
    # Save to CSV
    all_cohens_d.to_csv(output_path / 'cohens_d_by_participant.csv', index=False)
    print(f"\nSaved: cohens_d_by_participant.csv")
    
    # Perform bootstrap for each condition
    print("\nPerforming bootstrap resampling...")
    bootstrap_results = []
    
    for filtering in ['Strict', 'Loose']:
        for baseline in ['Shape', 'Label']:
            subset = all_cohens_d[(all_cohens_d['Filtering'] == filtering) & 
                                 (all_cohens_d['Baseline'] == baseline)]
            
            if len(subset) > 0:
                print(f"  Processing {filtering} - {baseline}: {len(subset)} participants")
                
                # Perform bootstrap
                boot_result = bootstrap_sequential_sample_size(
                    subset['Cohens_d'].values,
                    n_iterations=1000,
                    min_n=10,
                    step=10
                )
                
                boot_result['Filtering'] = filtering
                boot_result['Baseline'] = baseline
                bootstrap_results.append(boot_result)
    
    # Combine bootstrap results
    bootstrap_df = pd.concat(bootstrap_results, ignore_index=True)
    
    # Save to CSV
    bootstrap_df.to_csv(output_path / 'bootstrap_results.csv', index=False)
    print(f"Saved: bootstrap_results.csv")
    
    # Generate figures
    print("\nGenerating figures...")
    generate_figures(bootstrap_df, output_path)
    print("  Generated: figure1_shape_strict.png")
    print("  Generated: figure2_label_strict.png")
    print("  Generated: figure3_shape_loose.png")
    print("  Generated: figure4_label_loose.png")
    print("  Generated: combined_figures_300dpi.png")
    
    # Print summary
    print("\n" + "=" * 80)
    print("ANALYSIS SUMMARY")
    print("=" * 80)
    
    print("\n1. DATA OVERVIEW:")
    print(f"   Total datasets loaded: {len(clean_files)}")
    print(f"   Total mismatch trials: {len(mismatch_df)}")
    print(f"   Unique participants: {mismatch_df['Subject'].nunique()}")
    
    print("\n2. COHEN'S d CALCULATION:")
    for filtering in ['Strict', 'Loose']:
        for baseline in ['Shape', 'Label']:
            subset = all_cohens_d[(all_cohens_d['Filtering'] == filtering) & 
                                 (all_cohens_d['Baseline'] == baseline)]
            if len(subset) > 0:
                print(f"   {filtering} - {baseline}:")
                print(f"     Participants: {len(subset)}")
                print(f"     Mean Cohen's d: {subset['Cohens_d'].mean():.3f}")
                print(f"     SD: {subset['Cohens_d'].std():.3f}")
                print(f"     Range: [{subset['Cohens_d'].min():.3f}, {subset['Cohens_d'].max():.3f}]")
    
    print("\n3. BOOTSTRAP RESULTS (Final Sample Size):")
    for filtering in ['Strict', 'Loose']:
        for baseline in ['Shape', 'Label']:
            subset = bootstrap_df[(bootstrap_df['Filtering'] == filtering) & 
                                 (bootstrap_df['Baseline'] == baseline)]
            if len(subset) > 0:
                final = subset.iloc[-1]
                print(f"   {filtering} - {baseline}:")
                print(f"     Final sample size: {final['Sample_Size']}")
                print(f"     Mean Cohen's d: {final['Mean_Cohens_d']:.3f}")
                print(f"     95% CI: [{final['CI_lower']:.3f}, {final['CI_upper']:.3f}]")
                print(f"     Significant: {'Yes' if final['CI_lower'] > 0 or final['CI_upper'] < 0 else 'No'}")
    
    print("\n4. OUTPUT FILES:")
    print(f"   - cohens_d_by_participant.csv")
    print(f"   - bootstrap_results.csv")
    print(f"   - figure1_shape_strict.png")
    print(f"   - figure2_label_strict.png")
    print(f"   - figure3_shape_loose.png")
    print(f"   - figure4_label_loose.png")
    print(f"   - combined_figures_300dpi.png")
    
    print("\n" + "=" * 80)
    print("ANALYSIS COMPLETE!")
    print("=" * 80)


if __name__ == "__main__":
    main()
