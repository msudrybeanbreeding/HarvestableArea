"""
Python Script: Trial-Level Yield vs Harvestable Area Scatter Plot
Purpose: Visualize the relationship between normalized trial yield and harvestable area
Author: Mason
Date: January 14, 2026
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import numpy as np
from scipy import stats

# Set style for publication-quality plots
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 300
plt.rcParams['font.size'] = 11
plt.rcParams['font.family'] = 'sans-serif'

# ==============================================================================
# 1. Load and Aggregate Data
# ==============================================================================

# Load the plot-level data
file_path = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\All Site-Years Data For Trial-Wide Analysis.csv"
df = pd.read_csv(file_path)

print("Dataset loaded successfully!")
print(f"Shape: {df.shape}")
print(f"\nColumns: {df.columns.tolist()}")
print(f"\nFirst few rows:")
print(df.head())

# Aggregate to trial level
trial_level = df.groupby(['Year', 'Location', 'Siteyear', 'Trial']).agg({
    'Normalized Plot Yield': 'mean',
    'Plot Yield': 'mean',
    'HAreamean': 'mean'
}).reset_index()

# Rename columns for clarity
trial_level.columns = ['Year', 'Location', 'Siteyear', 'Trial', 
                        'Trial_Normalized_Yield', 'Trial_Uncorrected_Yield', 
                        'Trial_Harvestable_Area']

print(f"\nTrial-level data shape: {trial_level.shape}")
print(f"\nSite-years in dataset: {trial_level['Siteyear'].unique()}")
print(f"Number of trials: {len(trial_level)}")

# ==============================================================================
# 2. Calculate Correlations
# ==============================================================================

# Overall correlation - Normalized Yield
overall_corr_norm, overall_pval_norm = stats.pearsonr(
    trial_level['Trial_Harvestable_Area'], 
    trial_level['Trial_Normalized_Yield']
)

# Overall correlation - Uncorrected Yield
overall_corr_uncorr, overall_pval_uncorr = stats.pearsonr(
    trial_level['Trial_Harvestable_Area'], 
    trial_level['Trial_Uncorrected_Yield']
)

print(f"\n{'='*60}")
print(f"NORMALIZED YIELD")
print(f"Overall Pearson Correlation: r = {overall_corr_norm:.4f}, p = {overall_pval_norm:.4f}")
print(f"\nUNCORRECTED YIELD")
print(f"Overall Pearson Correlation: r = {overall_corr_uncorr:.4f}, p = {overall_pval_uncorr:.4f}")
print(f"{'='*60}")

# Correlation by site-year - Normalized Yield
print("\nNormalized Yield - Correlations by Site-Year:")
for siteyear in sorted(trial_level['Siteyear'].unique()):
    subset = trial_level[trial_level['Siteyear'] == siteyear]
    if len(subset) > 2:
        r, p = stats.pearsonr(subset['Trial_Harvestable_Area'], 
                              subset['Trial_Normalized_Yield'])
        print(f"{siteyear}: r = {r:.4f}, p = {p:.4f}, n = {len(subset)}")

# Correlation by site-year - Uncorrected Yield
print("\nUncorrected Yield - Correlations by Site-Year:")
for siteyear in sorted(trial_level['Siteyear'].unique()):
    subset = trial_level[trial_level['Siteyear'] == siteyear]
    if len(subset) > 2:
        r, p = stats.pearsonr(subset['Trial_Harvestable_Area'], 
                              subset['Trial_Uncorrected_Yield'])
        print(f"{siteyear}: r = {r:.4f}, p = {p:.4f}, n = {len(subset)}")

# ==============================================================================
# 3. Create Scatter Plot - NORMALIZED YIELD
# ==============================================================================

# Define colors for each site-year
colors = ['#E41A1C', '#377EB8', '#4DAF4A']  # Red, Blue, Green
siteyears = sorted(trial_level['Siteyear'].unique())
color_map = dict(zip(siteyears, colors[:len(siteyears)]))

# Create figure
fig, ax = plt.subplots(figsize=(10, 7))

# Plot each site-year separately (points only, no individual trend lines)
for siteyear in siteyears:
    subset = trial_level[trial_level['Siteyear'] == siteyear]
    ax.scatter(subset['Trial_Harvestable_Area'], 
               subset['Trial_Normalized_Yield'],
               c=color_map[siteyear],
               s=100,
               alpha=0.7,
               edgecolors='black',
               linewidth=0.5,
               label=siteyear)

# Overall regression line (all data) - ONLY THIS ONE
x_all = trial_level['Trial_Harvestable_Area']
y_all = trial_level['Trial_Normalized_Yield']
slope, intercept, r_value, p_value, std_err = stats.linregress(x_all, y_all)
line_x = np.linspace(x_all.min(), x_all.max(), 100)
line_y = slope * line_x + intercept
ax.plot(line_x, line_y, 
        color='black', 
        linestyle='-', 
        linewidth=2.5,
        alpha=0.8,
        label=f'Overall Trend (r={overall_corr_norm:.3f}, p={overall_pval_norm:.3f})')

# Formatting
ax.set_xlabel('Trial-Level Harvestable Area', fontsize=13, fontweight='bold')
ax.set_ylabel('Trial-Level Normalized Yield', fontsize=13, fontweight='bold')
ax.set_title('Trial-Level Normalized Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', pad=20)

# Legend
ax.legend(loc='best', frameon=True, fancybox=True, shadow=True, fontsize=10)

# Grid
ax.grid(True, alpha=0.3, linestyle='--', linewidth=0.5)

# Tight layout
plt.tight_layout()

# Save figure
output_path = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Trial_Yield_vs_Harvestable_Area_Scatter.png"
plt.savefig(output_path, dpi=300, bbox_inches='tight')
print(f"\nFigure saved to: {output_path}")

plt.show()

# ==============================================================================
# 3b. Create Scatter Plot for UNCORRECTED YIELD
# ==============================================================================

# Create figure for uncorrected yield
fig, ax = plt.subplots(figsize=(10, 7))

# Plot each site-year separately (points only, no individual trend lines)
for siteyear in siteyears:
    subset = trial_level[trial_level['Siteyear'] == siteyear]
    ax.scatter(subset['Trial_Harvestable_Area'], 
               subset['Trial_Uncorrected_Yield'],
               c=color_map[siteyear],
               s=100,
               alpha=0.7,
               edgecolors='black',
               linewidth=0.5,
               label=siteyear)

# Overall regression line (all data) - ONLY THIS ONE
x_all = trial_level['Trial_Harvestable_Area']
y_all = trial_level['Trial_Uncorrected_Yield']
slope, intercept, r_value, p_value, std_err = stats.linregress(x_all, y_all)
line_x = np.linspace(x_all.min(), x_all.max(), 100)
line_y = slope * line_x + intercept
ax.plot(line_x, line_y, 
        color='black', 
        linestyle='-', 
        linewidth=2.5,
        alpha=0.8,
        label=f'Overall Trend (r={overall_corr_uncorr:.3f}, p={overall_pval_uncorr:.3f})')

# Formatting
ax.set_xlabel('Trial-Level Harvestable Area', fontsize=13, fontweight='bold')
ax.set_ylabel('Trial-Level Uncorrected Yield', fontsize=13, fontweight='bold')
ax.set_title('Trial-Level Uncorrected Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', pad=20)

# Legend
ax.legend(loc='best', frameon=True, fancybox=True, shadow=True, fontsize=10)

# Grid
ax.grid(True, alpha=0.3, linestyle='--', linewidth=0.5)

# Tight layout
plt.tight_layout()

# Save figure
output_path_uncorr = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Trial_Uncorrected_Yield_vs_Harvestable_Area_Scatter.png"
plt.savefig(output_path_uncorr, dpi=300, bbox_inches='tight')
print(f"Uncorrected yield figure saved to: {output_path_uncorr}")

plt.show()

# ==============================================================================
# 4. Create Additional Plots
# ==============================================================================

# Create a figure with subplots for each site-year
fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)

for idx, siteyear in enumerate(siteyears):
    subset = trial_level[trial_level['Siteyear'] == siteyear]
    
    # Scatter plot
    axes[idx].scatter(subset['Trial_Harvestable_Area'], 
                      subset['Trial_Normalized_Yield'],
                      c=color_map[siteyear],
                      s=120,
                      alpha=0.7,
                      edgecolors='black',
                      linewidth=0.5)
    
    # Regression line
    if len(subset) > 2:
        x = subset['Trial_Harvestable_Area']
        y = subset['Trial_Normalized_Yield']
        slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
        line_x = np.linspace(x.min(), x.max(), 100)
        line_y = slope * line_x + intercept
        axes[idx].plot(line_x, line_y, 
                       color=color_map[siteyear], 
                       linestyle='-', 
                       linewidth=2)
        
        # Add statistics to plot
        axes[idx].text(0.05, 0.95, 
                       f'r = {r_value:.3f}\np = {p_value:.3f}\nn = {len(subset)}',
                       transform=axes[idx].transAxes,
                       verticalalignment='top',
                       bbox=dict(boxstyle='round', facecolor='white', alpha=0.8),
                       fontsize=10)
    
    # Formatting
    axes[idx].set_xlabel('Trial Harvestable Area', fontsize=11, fontweight='bold')
    axes[idx].set_title(siteyear, fontsize=12, fontweight='bold')
    axes[idx].grid(True, alpha=0.3)

# Y-label only on first subplot
axes[0].set_ylabel('Trial Normalized Yield', fontsize=11, fontweight='bold')

# Overall title
fig.suptitle('Trial-Level Normalized Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', y=1.02)

plt.tight_layout()

# Save panel figure
output_path_panel = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Trial_Yield_vs_Harvestable_Area_Panel.png"
plt.savefig(output_path_panel, dpi=300, bbox_inches='tight')
print(f"Panel figure saved to: {output_path_panel}")

plt.show()

# ==============================================================================
# 4b. Create Panel Plots for UNCORRECTED YIELD
# ==============================================================================

# Create a figure with subplots for each site-year - Uncorrected Yield
fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)

for idx, siteyear in enumerate(siteyears):
    subset = trial_level[trial_level['Siteyear'] == siteyear]
    
    # Scatter plot
    axes[idx].scatter(subset['Trial_Harvestable_Area'], 
                      subset['Trial_Uncorrected_Yield'],
                      c=color_map[siteyear],
                      s=120,
                      alpha=0.7,
                      edgecolors='black',
                      linewidth=0.5)
    
    # Regression line
    if len(subset) > 2:
        x = subset['Trial_Harvestable_Area']
        y = subset['Trial_Uncorrected_Yield']
        slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
        line_x = np.linspace(x.min(), x.max(), 100)
        line_y = slope * line_x + intercept
        axes[idx].plot(line_x, line_y, 
                       color=color_map[siteyear], 
                       linestyle='-', 
                       linewidth=2)
        
        # Add statistics to plot
        axes[idx].text(0.05, 0.95, 
                       f'r = {r_value:.3f}\np = {p_value:.3f}\nn = {len(subset)}',
                       transform=axes[idx].transAxes,
                       verticalalignment='top',
                       bbox=dict(boxstyle='round', facecolor='white', alpha=0.8),
                       fontsize=10)
    
    # Formatting
    axes[idx].set_xlabel('Trial Harvestable Area', fontsize=11, fontweight='bold')
    axes[idx].set_title(siteyear, fontsize=12, fontweight='bold')
    axes[idx].grid(True, alpha=0.3)

# Y-label only on first subplot
axes[0].set_ylabel('Trial Uncorrected Yield', fontsize=11, fontweight='bold')

# Overall title
fig.suptitle('Trial-Level Uncorrected Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', y=1.02)

plt.tight_layout()

# Save panel figure for uncorrected yield
output_path_panel_uncorr = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Trial_Uncorrected_Yield_vs_Harvestable_Area_Panel.png"
plt.savefig(output_path_panel_uncorr, dpi=300, bbox_inches='tight')
print(f"Uncorrected yield panel figure saved to: {output_path_panel_uncorr}")

plt.show()

# ==============================================================================
# 5. Summary Statistics Table
# ==============================================================================

print("\n" + "="*80)
print("SUMMARY STATISTICS BY SITE-YEAR")
print("="*80)

summary_stats = trial_level.groupby('Siteyear').agg({
    'Trial_Normalized_Yield': ['mean', 'std', 'min', 'max'],
    'Trial_Uncorrected_Yield': ['mean', 'std', 'min', 'max'],
    'Trial_Harvestable_Area': ['mean', 'std', 'min', 'max'],
    'Trial': 'count'
}).round(4)

summary_stats.columns = ['_'.join(col).strip() for col in summary_stats.columns.values]
summary_stats = summary_stats.rename(columns={'Trial_count': 'N_Trials'})

print(summary_stats)

# Export summary statistics
output_csv = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Trial_Level_Summary_Stats.csv"
summary_stats.to_csv(output_csv)
print(f"\nSummary statistics saved to: {output_csv}")

print("\nScript completed successfully!")
