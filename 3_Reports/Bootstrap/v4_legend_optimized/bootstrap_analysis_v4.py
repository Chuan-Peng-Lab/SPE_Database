#!/usr/bin/env python3
"""
Bootstrap Analysis for Self-Prioritization Effect in Mismatch Conditions (v4)

Updates in v4:
1. Legend placed after title to avoid blocking the plot
2. More compact legend design
3. Cleaner APA-style presentation

Usage:
    python bootstrap_analysis_v4.py
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from pathlib import Path
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
    return (mean1 - mean2) / pooled_sd if pooled_sd != 0 else np.nan


def filter_valid_subjects(df, identity_column):
    """Filter subjects with Self, Stranger, and at least 3 identities."""
    valid_subjects = []
    for subject, subj_df in df.groupby('Subject'):
        identities = set(subj_df[identity_column].dropna().unique())
        if 'Self' in identities and 'Stranger' in identities and len(identities) >= 3:
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
    identity_column = 'Shape_Standardized_Identity' if analysis_type == 'Shape' else 'Label_Standardized_Identity'
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
        
        d = cohens_d(stranger_values, self_values) if measure == 'RT' else cohens_d(self_values, stranger_values)
        
        if not np.isnan(d):
            results.append({'Subject': subject, 'Cohens_d': d, 'n_self': len(self_values), 'n_stranger': len(stranger_values)})
    return pd.DataFrame(results)


def bootstrap_analysis(cohens_d_values, n_bootstrap=500, min_n=10, step=10, max_n=None):
    """Perform bootstrap resampling WITH REPLACEMENT."""
    total_n = len(cohens_d_values)
    if total_n < min_n:
        return pd.DataFrame()
    
    max_n = min(max_n, total_n) if max_n else total_n
    sample_sizes = list(range(min_n, max_n + 1, step))
    if max_n % step != 0 and max_n not in sample_sizes:
        sample_sizes.append(max_n)
    sample_sizes = sorted(set(sample_sizes))
    
    results = []
    for n in sample_sizes:
        if n > total_n:
            continue
        bootstrap_means = [np.mean(np.random.choice(cohens_d_values, size=n, replace=True)) for _ in range(n_bootstrap)]
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
    print(f"  Shape: {len(rt_shape_cohens)} participants, Label: {len(rt_label_cohens)} participants")
    
    rt_max_n = min(len(rt_shape_cohens), len(rt_label_cohens))
    
    rt_shape_boot = bootstrap_analysis(rt_shape_cohens['Cohens_d'].values, n_bootstrap) if len(rt_shape_cohens) > 0 else pd.DataFrame()
    rt_label_boot = bootstrap_analysis(rt_label_cohens['Cohens_d'].values, n_bootstrap) if len(rt_label_cohens) > 0 else pd.DataFrame()
    rt_shape_boot_aligned = bootstrap_analysis(rt_shape_cohens['Cohens_d'].values, n_bootstrap, max_n=rt_max_n) if len(rt_shape_cohens) > 0 else pd.DataFrame()
    rt_label_boot_aligned = bootstrap_analysis(rt_label_cohens['Cohens_d'].values, n_bootstrap, max_n=rt_max_n) if len(rt_label_cohens) > 0 else pd.DataFrame()
    
    for df in [rt_shape_boot, rt_label_boot, rt_shape_boot_aligned, rt_label_boot_aligned]:
        if not df.empty:
            df['Identity'] = 'Shape' if df is rt_shape_boot or df is rt_shape_boot_aligned else 'Label'
    
    results['rt_bootstrap'] = pd.concat([rt_shape_boot, rt_label_boot], ignore_index=True)
    results['rt_bootstrap_aligned'] = pd.concat([rt_shape_boot_aligned, rt_label_boot_aligned], ignore_index=True)
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
    print(f"  Shape: {len(acc_shape_cohens)} participants, Label: {len(acc_label_cohens)} participants")
    
    acc_max_n = min(len(acc_shape_cohens), len(acc_label_cohens))
    
    acc_shape_boot = bootstrap_analysis(acc_shape_cohens['Cohens_d'].values, n_bootstrap) if len(acc_shape_cohens) > 0 else pd.DataFrame()
    acc_label_boot = bootstrap_analysis(acc_label_cohens['Cohens_d'].values, n_bootstrap) if len(acc_label_cohens) > 0 else pd.DataFrame()
    acc_shape_boot_aligned = bootstrap_analysis(acc_shape_cohens['Cohens_d'].values, n_bootstrap, max_n=acc_max_n) if len(acc_shape_cohens) > 0 else pd.DataFrame()
    acc_label_boot_aligned = bootstrap_analysis(acc_label_cohens['Cohens_d'].values, n_bootstrap, max_n=acc_max_n) if len(acc_label_cohens) > 0 else pd.DataFrame()
    
    for df in [acc_shape_boot, acc_label_boot, acc_shape_boot_aligned, acc_label_boot_aligned]:
        if not df.empty:
            df['Identity'] = 'Shape' if df is acc_shape_boot or df is acc_shape_boot_aligned else 'Label'
    
    results['acc_bootstrap'] = pd.concat([acc_shape_boot, acc_label_boot], ignore_index=True)
    results['acc_bootstrap_aligned'] = pd.concat([acc_shape_boot_aligned, acc_label_boot_aligned], ignore_index=True)
    results['acc_shape_cohens'] = acc_shape_cohens
    results['acc_label_cohens'] = acc_label_cohens
    
    return results


def create_apa_figure_v4(strict_rt, strict_acc, loose_rt, loose_acc, 
                          version='original', output_path=None):
    """
    Create APA-style figure with legend integrated into title.
    
    Legend is placed after the title text to avoid blocking the plot.
    """
    # Colors
    shape_color = '#2E86AB'
    label_color = '#A23B72'
    
    # Fixed axis limits
    x_min, x_max = 0, 500
    y_min, y_max = -0.4, 0.4
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    # Create legend patches
    shape_patch = mpatches.Patch(color=shape_color, label='Shape')
    label_patch = mpatches.Patch(color=label_color, label='Label')
    
    plot_configs = [
        (axes[0, 0], strict_rt, 'RT', 'Strict'),
        (axes[0, 1], strict_acc, 'ACC', 'Strict'),
        (axes[1, 0], loose_rt, 'RT', 'Loose'),
        (axes[1, 1], loose_acc, 'ACC', 'Loose'),
    ]
    
    for ax, data, measure, filtering in plot_configs:
        # APA style: white background, no grid
        ax.set_facecolor('white')
        ax.grid(False)
        
        if data.empty:
            ax.text(0.5, 0.5, 'No Data', ha='center', va='center', 
                   transform=ax.transAxes, fontsize=14)
            continue
        
        # Plot data
        for identity in ['Shape', 'Label']:
            subset = data[data['Identity'] == identity]
            if subset.empty:
                continue
            
            color = shape_color if identity == 'Shape' else label_color
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
        
        # Fixed axes
        ax.set_xlim(x_min, x_max)
        ax.set_ylim(y_min, y_max)
        
        # Labels
        y_label = "Cohen's d (Stranger - Self)" if measure == 'RT' else "Cohen's d (Self - Stranger)"
        subplot_label = ('A' if filtering == 'Strict' else 'C') if measure == 'RT' else ('B' if filtering == 'Strict' else 'D')
        
        ax.set_xlabel('Sample Size', fontsize=12, fontweight='bold')
        ax.set_ylabel(y_label, fontsize=12, fontweight='bold')
        
        # Title with legend integrated
        # Format: "SPE calculated by [filtering] approach ([measure])  ■ Shape  ■ Label"
        title_text = f"SPE calculated by {filtering.lower()} approach ({measure})"
        ax.set_title(title_text, fontsize=12, fontweight='bold', family='Times New Roman', loc='left')
        
        # Add colored squares as legend after title
        # Position them at the right side of the title area
        title_obj = ax.title
        title_bbox = title_obj.get_window_extent(fig.canvas.get_renderer())
        
        # Add legend as text with colored markers
        # Using transform=ax.transAxes for positioning
        ax.text(0.98, 1.02, '■ Shape', transform=ax.transAxes, 
               fontsize=10, color=shape_color, fontweight='bold',
               ha='right', va='bottom')
        ax.text(0.98, 1.02, '     ■ Label', transform=ax.transAxes,
               fontsize=10, color=label_color, fontweight='bold',
               ha='right', va='bottom')
        
        # Subplot label
        ax.text(-0.08, 1.15, subplot_label, transform=ax.transAxes, 
               fontsize=16, fontweight='bold', va='top', ha='right')
        
        # APA style: remove top and right spines
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_linewidth(1)
        ax.spines['bottom'].set_linewidth(1)
        ax.tick_params(axis='both', which='major', labelsize=10)
    
    plt.tight_layout()
    
    if output_path:
        filename = f'combined_figures_apa_v4_{version}.png'
        plt.savefig(output_path / filename, dpi=300, bbox_inches='tight', 
                   facecolor='white', edgecolor='none')
        print(f"\nSaved: {filename}")
    
    return fig


def create_apa_figure_v4_alternative(strict_rt, strict_acc, loose_rt, loose_acc, 
                                      version='original', output_path=None):
    """
    Alternative version: Legend below title as subtitle.
    """
    # Colors
    shape_color = '#2E86AB'
    label_color = '#A23B72'
    
    # Fixed axis limits
    x_min, x_max = 0, 500
    y_min, y_max = -0.4, 0.4
    
    fig, axes = plt.subplots(2, 2, figsize=(14, 10))
    
    plot_configs = [
        (axes[0, 0], strict_rt, 'RT', 'Strict'),
        (axes[0, 1], strict_acc, 'ACC', 'Strict'),
        (axes[1, 0], loose_rt, 'RT', 'Loose'),
        (axes[1, 1], loose_acc, 'ACC', 'Loose'),
    ]
    
    for ax, data, measure, filtering in plot_configs:
        # APA style
        ax.set_facecolor('white')
        ax.grid(False)
        
        if data.empty:
            ax.text(0.5, 0.5, 'No Data', ha='center', va='center', 
                   transform=ax.transAxes, fontsize=14)
            continue
        
        # Plot data
        for identity in ['Shape', 'Label']:
            subset = data[data['Identity'] == identity]
            if subset.empty:
                continue
            
            color = shape_color if identity == 'Shape' else label_color
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
        
        # Fixed axes
        ax.set_xlim(x_min, x_max)
        ax.set_ylim(y_min, y_max)
        
        # Labels
        y_label = "Cohen's d (Stranger - Self)" if measure == 'RT' else "Cohen's d (Self - Stranger)"
        subplot_label = ('A' if filtering == 'Strict' else 'C') if measure == 'RT' else ('B' if filtering == 'Strict' else 'D')
        
        ax.set_xlabel('Sample Size', fontsize=12, fontweight='bold')
        ax.set_ylabel(y_label, fontsize=12, fontweight='bold')
        
        # Title
        title_text = f"SPE calculated by {filtering.lower()} approach"
        ax.set_title(title_text, fontsize=13, fontweight='bold', 
                    family='Times New Roman', pad=25)
        
        # Add measure and legend as subtitle below title
        subtitle_text = f"({measure})    ■ Shape    ■ Label"
        ax.text(0.5, 1.02, subtitle_text, transform=ax.transAxes,
               fontsize=10, ha='center', va='bottom',
               color='black')
        
        # Color the squares in subtitle
        # This is a workaround - we'll use separate text objects
        ax.text(0.5, 1.02, f"({measure})    ", transform=ax.transAxes,
               fontsize=10, ha='right', va='bottom', color='black')
        ax.text(0.5, 1.02, "■", transform=ax.transAxes,
               fontsize=10, ha='left', va='bottom', color=shape_color)
        ax.text(0.53, 1.02, " Shape    ", transform=ax.transAxes,
               fontsize=10, ha='right', va='bottom', color='black')
        ax.text(0.53, 1.02, "■", transform=ax.transAxes,
               fontsize=10, ha='left', va='bottom', color=label_color)
        ax.text(0.56, 1.02, " Label", transform=ax.transAxes,
               fontsize=10, ha='left', va='bottom', color='black')
        
        # Subplot label
        ax.text(-0.08, 1.15, subplot_label, transform=ax.transAxes, 
               fontsize=16, fontweight='bold', va='top', ha='right')
        
        # APA style
        ax.spines['top'].set_visible(False)
        ax.spines['right'].set_visible(False)
        ax.spines['left'].set_linewidth(1)
        ax.spines['bottom'].set_linewidth(1)
        ax.tick_params(axis='both', which='major', labelsize=10)
    
    plt.tight_layout()
    
    if output_path:
        filename = f'combined_figures_apa_v4_alt_{version}.png'
        plt.savefig(output_path / filename, dpi=300, bbox_inches='tight', 
                   facecolor='white', edgecolor='none')
        print(f"Saved: {filename}")
    
    return fig


def main():
    """Main analysis function."""
    
    print("=" * 80)
    print("Bootstrap Analysis for Self-Prioritization Effect (v4)")
    print("Legend integrated into title to avoid blocking plot")
    print("=" * 80)
    
    # Define paths
    data_path = Path("D:/GitHub_programe/GitHub/SPE_Database/1_Data")
    output_path = Path("D:/GitHub_programe/GitHub/SPE_Database/3_Reports/Bootstrap")
    output_path.mkdir(exist_ok=True)
    
    # Load data
    clean_files = list(data_path.rglob("*_Clean.csv"))
    print(f"\nFound {len(clean_files)} Clean.csv files")
    
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
    
    # Check columns
    has_label = 'Label_Standardized_Identity' in merged_df.columns
    if not has_label:
        merged_df['Label_Standardized_Identity'] = merged_df['Shape_Standardized_Identity']
    
    # Filter for Nonmatching
    mismatch_df = merged_df[merged_df['Matching'] == 'Nonmatching'].copy()
    print(f"Mismatch trials: {len(mismatch_df)} rows")
    
    # Run analyses
    print("\n" + "=" * 80)
    print("STRICT FILTERING")
    print("=" * 80)
    strict_results = run_analysis(mismatch_df, 'Strict', n_bootstrap=500)
    
    print("\n" + "=" * 80)
    print("LOOSE FILTERING")
    print("=" * 80)
    loose_results = run_analysis(mismatch_df, 'Loose', n_bootstrap=500)
    
    # Generate figures
    print("\n" + "=" * 80)
    print("GENERATING FIGURES (v4)")
    print("=" * 80)
    
    # Version 1: Legend as colored squares after title
    create_apa_figure_v4(
        strict_results['rt_bootstrap'],
        strict_results['acc_bootstrap'],
        loose_results['rt_bootstrap'],
        loose_results['acc_bootstrap'],
        version='original',
        output_path=output_path
    )
    
    create_apa_figure_v4(
        strict_results['rt_bootstrap_aligned'],
        strict_results['acc_bootstrap_aligned'],
        loose_results['rt_bootstrap_aligned'],
        loose_results['acc_bootstrap_aligned'],
        version='aligned',
        output_path=output_path
    )
    
    # Version 2: Alternative with subtitle
    create_apa_figure_v4_alternative(
        strict_results['rt_bootstrap'],
        strict_results['acc_bootstrap'],
        loose_results['rt_bootstrap'],
        loose_results['acc_bootstrap'],
        version='original',
        output_path=output_path
    )
    
    create_apa_figure_v4_alternative(
        strict_results['rt_bootstrap_aligned'],
        strict_results['acc_bootstrap_aligned'],
        loose_results['rt_bootstrap_aligned'],
        loose_results['acc_bootstrap_aligned'],
        version='aligned',
        output_path=output_path
    )
    
    # Save results
    print("\n" + "=" * 80)
    print("SAVING RESULTS")
    print("=" * 80)
    
    strict_results['rt_bootstrap'].to_csv(output_path / 'bootstrap_rt_strict_v4_original.csv', index=False)
    strict_results['acc_bootstrap'].to_csv(output_path / 'bootstrap_acc_strict_v4_original.csv', index=False)
    loose_results['rt_bootstrap'].to_csv(output_path / 'bootstrap_rt_loose_v4_original.csv', index=False)
    loose_results['acc_bootstrap'].to_csv(output_path / 'bootstrap_acc_loose_v4_original.csv', index=False)
    
    strict_results['rt_bootstrap_aligned'].to_csv(output_path / 'bootstrap_rt_strict_v4_aligned.csv', index=False)
    strict_results['acc_bootstrap_aligned'].to_csv(output_path / 'bootstrap_acc_strict_v4_aligned.csv', index=False)
    loose_results['rt_bootstrap_aligned'].to_csv(output_path / 'bootstrap_rt_loose_v4_aligned.csv', index=False)
    loose_results['acc_bootstrap_aligned'].to_csv(output_path / 'bootstrap_acc_loose_v4_aligned.csv', index=False)
    
    print("\n" + "=" * 80)
    print("OUTPUT FILES:")
    print("=" * 80)
    print("\nFigures (300 dpi):")
    print("  - combined_figures_apa_v4_original.png")
    print("  - combined_figures_apa_v4_aligned.png")
    print("  - combined_figures_apa_v4_alt_original.png (alternative style)")
    print("  - combined_figures_apa_v4_alt_aligned.png (alternative style)")
    
    print("\n" + "=" * 80)
    print("ANALYSIS COMPLETE!")
    print("=" * 80)


if __name__ == "__main__":
    main()
