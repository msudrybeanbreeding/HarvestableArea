"""
Python Script: Plot-Level Yield vs Harvestable Area Analysis
Purpose: Correlate and visualize plot-level normalized and uncorrected yield with harvestable area
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
# 1. Load Plot-Level Data
# ==============================================================================

# Load the plot-level data
file_path = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\All Site-Years Data For Trial-Wide Analysis.csv"
df = pd.read_csv(file_path)

print("Dataset loaded successfully!")
print(f"Shape: {df.shape}")
print(f"\nColumns: {df.columns.tolist()}")
print(f"\nFirst few rows:")
print(df.head())

# Check for missing values
print(f"\nMissing values:")
print(df[['Normalized Plot Yield', 'Plot Yield', 'HAreamean']].isnull().sum())

# Remove any rows with missing values in key columns
df_clean = df.dropna(subset=['Normalized Plot Yield', 'Plot Yield', 'HAreamean'])
print(f"\nClean dataset shape: {df_clean.shape}")
print(f"Site-years in dataset: {df_clean['Siteyear'].unique()}")
print(f"Number of plots: {len(df_clean)}")

# ==============================================================================
# 2. Calculate Correlations - Plot Level
# ==============================================================================

# Overall correlation - Normalized Yield
overall_corr_norm, overall_pval_norm = stats.pearsonr(
    df_clean['HAreamean'], 
    df_clean['Normalized Plot Yield']
)

# Overall correlation - Uncorrected Yield
overall_corr_uncorr, overall_pval_uncorr = stats.pearsonr(
    df_clean['HAreamean'], 
    df_clean['Plot Yield']
)

print(f"\n{'='*70}")
print(f"PLOT-LEVEL CORRELATIONS - OVERALL")
print(f"{'='*70}")
print(f"NORMALIZED YIELD:")
print(f"  Pearson Correlation: r = {overall_corr_norm:.4f}, p = {overall_pval_norm:.6f}")
print(f"\nUNCORRECTED YIELD:")
print(f"  Pearson Correlation: r = {overall_corr_uncorr:.4f}, p = {overall_pval_uncorr:.6f}")
print(f"{'='*70}")

# Correlation by site-year - Normalized Yield
print(f"\n{'='*70}")
print(f"NORMALIZED YIELD - CORRELATIONS BY SITE-YEAR")
print(f"{'='*70}")
for siteyear in sorted(df_clean['Siteyear'].unique()):
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    r, p = stats.pearsonr(subset['HAreamean'], subset['Normalized Plot Yield'])
    print(f"{siteyear}: r = {r:.4f}, p = {p:.6f}, n = {len(subset)}")

# Correlation by site-year - Uncorrected Yield
print(f"\n{'='*70}")
print(f"UNCORRECTED YIELD - CORRELATIONS BY SITE-YEAR")
print(f"{'='*70}")
for siteyear in sorted(df_clean['Siteyear'].unique()):
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    r, p = stats.pearsonr(subset['HAreamean'], subset['Plot Yield'])
    print(f"{siteyear}: r = {r:.4f}, p = {p:.6f}, n = {len(subset)}")

# ==============================================================================
# 3. Create Scatter Plot - NORMALIZED YIELD (Plot-Level)
# ==============================================================================

# Define colors for each site-year
colors = ['#E41A1C', '#377EB8', '#4DAF4A']  # Red, Blue, Green
siteyears = sorted(df_clean['Siteyear'].unique())
color_map = dict(zip(siteyears, colors[:len(siteyears)]))

# Create figure
fig, ax = plt.subplots(figsize=(10, 7))

# Plot each site-year separately (points only)
for siteyear in siteyears:
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    ax.scatter(subset['HAreamean'], 
               subset['Normalized Plot Yield'],
               c=color_map[siteyear],
               s=30,
               alpha=0.5,
               edgecolors='none',
               label=siteyear)

# Overall regression line (all data)
x_all = df_clean['HAreamean']
y_all = df_clean['Normalized Plot Yield']
slope, intercept, r_value, p_value, std_err = stats.linregress(x_all, y_all)
line_x = np.linspace(x_all.min(), x_all.max(), 100)
line_y = slope * line_x + intercept
ax.plot(line_x, line_y, 
        color='black', 
        linestyle='-', 
        linewidth=2.5,
        alpha=0.8,
        label=f'Overall Trend (r={overall_corr_norm:.3f}, p<0.001)' if overall_pval_norm < 0.001 
              else f'Overall Trend (r={overall_corr_norm:.3f}, p={overall_pval_norm:.3f})')

# Formatting
ax.set_xlabel('Plot-Level Harvestable Area', fontsize=13, fontweight='bold')
ax.set_ylabel('Plot-Level Normalized Yield', fontsize=13, fontweight='bold')
ax.set_title('Plot-Level Normalized Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', pad=20)

# Legend
ax.legend(loc='best', frameon=True, fancybox=True, shadow=True, fontsize=10)

# Grid
ax.grid(True, alpha=0.3, linestyle='--', linewidth=0.5)

# Tight layout
plt.tight_layout()

# Save figure
output_path_norm = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Plot_Level_Normalized_Yield_vs_HA_Scatter.png"
plt.savefig(output_path_norm, dpi=300, bbox_inches='tight')
print(f"\nNormalized yield plot saved to: {output_path_norm}")

plt.show()

# ==============================================================================
# 4. Create Scatter Plot - UNCORRECTED YIELD (Plot-Level)
# ==============================================================================

# Create figure for uncorrected yield
fig, ax = plt.subplots(figsize=(10, 7))

# Plot each site-year separately (points only)
for siteyear in siteyears:
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    ax.scatter(subset['HAreamean'], 
               subset['Plot Yield'],
               c=color_map[siteyear],
               s=30,
               alpha=0.5,
               edgecolors='none',
               label=siteyear)

# Overall regression line (all data)
x_all = df_clean['HAreamean']
y_all = df_clean['Plot Yield']
slope, intercept, r_value, p_value, std_err = stats.linregress(x_all, y_all)
line_x = np.linspace(x_all.min(), x_all.max(), 100)
line_y = slope * line_x + intercept
ax.plot(line_x, line_y, 
        color='black', 
        linestyle='-', 
        linewidth=2.5,
        alpha=0.8,
        label=f'Overall Trend (r={overall_corr_uncorr:.3f}, p<0.001)' if overall_pval_uncorr < 0.001 
              else f'Overall Trend (r={overall_corr_uncorr:.3f}, p={overall_pval_uncorr:.3f})')

# Formatting
ax.set_xlabel('Plot-Level Harvestable Area', fontsize=13, fontweight='bold')
ax.set_ylabel('Plot-Level Uncorrected Yield', fontsize=13, fontweight='bold')
ax.set_title('Plot-Level Uncorrected Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', pad=20)

# Legend
ax.legend(loc='best', frameon=True, fancybox=True, shadow=True, fontsize=10)

# Grid
ax.grid(True, alpha=0.3, linestyle='--', linewidth=0.5)

# Tight layout
plt.tight_layout()

# Save figure
output_path_uncorr = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Plot_Level_Uncorrected_Yield_vs_HA_Scatter.png"
plt.savefig(output_path_uncorr, dpi=300, bbox_inches='tight')
print(f"Uncorrected yield plot saved to: {output_path_uncorr}")

plt.show()

# ==============================================================================
# 5. Create Panel Plots by Site-Year - NORMALIZED YIELD
# ==============================================================================

fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)

for idx, siteyear in enumerate(siteyears):
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    
    # Scatter plot
    axes[idx].scatter(subset['HAreamean'], 
                      subset['Normalized Plot Yield'],
                      c=color_map[siteyear],
                      s=30,
                      alpha=0.5,
                      edgecolors='none')
    
    # Regression line
    x = subset['HAreamean']
    y = subset['Normalized Plot Yield']
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    line_x = np.linspace(x.min(), x.max(), 100)
    line_y = slope * line_x + intercept
    axes[idx].plot(line_x, line_y, 
                   color=color_map[siteyear], 
                   linestyle='-', 
                   linewidth=2)
    
    # Add statistics to plot
    p_text = f'p < 0.001' if p_value < 0.001 else f'p = {p_value:.3f}'
    axes[idx].text(0.05, 0.95, 
                   f'r = {r_value:.3f}\n{p_text}\nn = {len(subset)}',
                   transform=axes[idx].transAxes,
                   verticalalignment='top',
                   bbox=dict(boxstyle='round', facecolor='white', alpha=0.8),
                   fontsize=10)
    
    # Formatting
    axes[idx].set_xlabel('Plot Harvestable Area', fontsize=11, fontweight='bold')
    axes[idx].set_title(siteyear, fontsize=12, fontweight='bold')
    axes[idx].grid(True, alpha=0.3)

# Y-label only on first subplot
axes[0].set_ylabel('Plot Normalized Yield', fontsize=11, fontweight='bold')

# Overall title
fig.suptitle('Plot-Level Normalized Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', y=1.02)

plt.tight_layout()

# Save panel figure
output_path_panel_norm = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Plot_Level_Normalized_Yield_vs_HA_Panel.png"
plt.savefig(output_path_panel_norm, dpi=300, bbox_inches='tight')
print(f"Normalized yield panel plot saved to: {output_path_panel_norm}")

plt.show()

# ==============================================================================
# 6. Create Panel Plots by Site-Year - UNCORRECTED YIELD
# ==============================================================================

fig, axes = plt.subplots(1, 3, figsize=(15, 5), sharey=True)

for idx, siteyear in enumerate(siteyears):
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    
    # Scatter plot
    axes[idx].scatter(subset['HAreamean'], 
                      subset['Plot Yield'],
                      c=color_map[siteyear],
                      s=30,
                      alpha=0.5,
                      edgecolors='none')
    
    # Regression line
    x = subset['HAreamean']
    y = subset['Plot Yield']
    slope, intercept, r_value, p_value, std_err = stats.linregress(x, y)
    line_x = np.linspace(x.min(), x.max(), 100)
    line_y = slope * line_x + intercept
    axes[idx].plot(line_x, line_y, 
                   color=color_map[siteyear], 
                   linestyle='-', 
                   linewidth=2)
    
    # Add statistics to plot
    p_text = f'p < 0.001' if p_value < 0.001 else f'p = {p_value:.3f}'
    axes[idx].text(0.05, 0.95, 
                   f'r = {r_value:.3f}\n{p_text}\nn = {len(subset)}',
                   transform=axes[idx].transAxes,
                   verticalalignment='top',
                   bbox=dict(boxstyle='round', facecolor='white', alpha=0.8),
                   fontsize=10)
    
    # Formatting
    axes[idx].set_xlabel('Plot Harvestable Area', fontsize=11, fontweight='bold')
    axes[idx].set_title(siteyear, fontsize=12, fontweight='bold')
    axes[idx].grid(True, alpha=0.3)

# Y-label only on first subplot
axes[0].set_ylabel('Plot Uncorrected Yield', fontsize=11, fontweight='bold')

# Overall title
fig.suptitle('Plot-Level Uncorrected Yield vs Harvestable Area by Site-Year', 
             fontsize=14, fontweight='bold', y=1.02)

plt.tight_layout()

# Save panel figure
output_path_panel_uncorr = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Plot_Level_Uncorrected_Yield_vs_HA_Panel.png"
plt.savefig(output_path_panel_uncorr, dpi=300, bbox_inches='tight')
print(f"Uncorrected yield panel plot saved to: {output_path_panel_uncorr}")

plt.show()

# ==============================================================================
# 7. Summary Statistics and Correlation Table
# ==============================================================================

print("\n" + "="*80)
print("SUMMARY STATISTICS BY SITE-YEAR - PLOT LEVEL")
print("="*80)

summary_stats = df_clean.groupby('Siteyear').agg({
    'Normalized Plot Yield': ['mean', 'std', 'min', 'max'],
    'Plot Yield': ['mean', 'std', 'min', 'max'],
    'HAreamean': ['mean', 'std', 'min', 'max'],
    'Trial': 'nunique'
}).round(4)

summary_stats.columns = ['_'.join(col).strip() for col in summary_stats.columns.values]
summary_stats = summary_stats.rename(columns={'Trial_nunique': 'N_Trials'})

# Add plot counts
plot_counts = df_clean.groupby('Siteyear').size()
summary_stats['N_Plots'] = plot_counts

print(summary_stats)

# Create correlation summary table
corr_summary = []
for siteyear in sorted(df_clean['Siteyear'].unique()):
    subset = df_clean[df_clean['Siteyear'] == siteyear]
    
    # Normalized yield
    r_norm, p_norm = stats.pearsonr(subset['HAreamean'], subset['Normalized Plot Yield'])
    
    # Uncorrected yield
    r_uncorr, p_uncorr = stats.pearsonr(subset['HAreamean'], subset['Plot Yield'])
    
    corr_summary.append({
        'Siteyear': siteyear,
        'N_Plots': len(subset),
        'Normalized_Yield_r': r_norm,
        'Normalized_Yield_p': p_norm,
        'Uncorrected_Yield_r': r_uncorr,
        'Uncorrected_Yield_p': p_uncorr
    })

# Add overall row
r_norm_overall, p_norm_overall = stats.pearsonr(df_clean['HAreamean'], df_clean['Normalized Plot Yield'])
r_uncorr_overall, p_uncorr_overall = stats.pearsonr(df_clean['HAreamean'], df_clean['Plot Yield'])

corr_summary.append({
    'Siteyear': 'OVERALL',
    'N_Plots': len(df_clean),
    'Normalized_Yield_r': r_norm_overall,
    'Normalized_Yield_p': p_norm_overall,
    'Uncorrected_Yield_r': r_uncorr_overall,
    'Uncorrected_Yield_p': p_uncorr_overall
})

corr_df = pd.DataFrame(corr_summary)

print("\n" + "="*80)
print("CORRELATION SUMMARY TABLE - PLOT LEVEL")
print("="*80)
print(corr_df.to_string(index=False))

# Export summary statistics and correlations
output_stats = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Plot_Level_Summary_Stats.csv"
summary_stats.to_csv(output_stats)
print(f"\nSummary statistics saved to: {output_stats}")

output_corr = r"C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Plot_Level_Correlation_Summary.csv"
corr_df.to_csv(output_corr, index=False)
print(f"Correlation summary saved to: {output_corr}")

print("\n" + "="*80)
print("SCRIPT COMPLETED SUCCESSFULLY!")
print("="*80)
print("\nGenerated files:")
print("  1. Plot_Level_Normalized_Yield_vs_HA_Scatter.png")
print("  2. Plot_Level_Uncorrected_Yield_vs_HA_Scatter.png")
print("  3. Plot_Level_Normalized_Yield_vs_HA_Panel.png")
print("  4. Plot_Level_Uncorrected_Yield_vs_HA_Panel.png")
print("  5. Plot_Level_Summary_Stats.csv")
print("  6. Plot_Level_Correlation_Summary.csv")
