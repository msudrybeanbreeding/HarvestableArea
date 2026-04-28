"""
8-Panel Correlation Figure with Improved Fonts and Legend
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 150

# Load data
all_sites_data = pd.read_csv('/mnt/user-data/uploads/All_Site-Years_Data_For_Trial-Wide_Analysis.csv')
spatial_data = pd.read_csv('/mnt/user-data/outputs/COMPLETE_INPUT_DATA_ALL_SITES.csv')

# Apply 2506 correction
spatial_data.loc[spatial_data['Trial'] == 2506, 'sum_distances_div2'] = spatial_data.loc[spatial_data['Trial'] == 2506, 'sum_distances_div2'] / 2

# Merge to get HA_Mean
merged_data = pd.merge(
    all_sites_data[['Trial', 'Plot Yield', 'Peak Stand', 'PltCounts']],
    spatial_data[['Trial', 'HA_Mean']],
    on='Trial',
    how='inner'
)

# Rename columns
merged_data = merged_data.rename(columns={
    'Plot Yield': 'Yield',
    'Peak Stand': 'Peak_Stand',
    'PltCounts': 'Drone_Plant_Count'
})

# Correct site-year classification
def get_site_year(trial):
    if 24000 <= trial < 25000:  # 241xx trials
        return '2024LODS'
    else:  # 251xx and 25xx trials
        return '2025LODS'

merged_data['Site_Year'] = merged_data['Trial'].apply(get_site_year)

print(f"Data: {len(merged_data)} observations")
print(f"2024LODS: {(merged_data['Site_Year']=='2024LODS').sum()}")
print(f"2025LODS: {(merged_data['Site_Year']=='2025LODS').sum()}")

# Site colors
site_colors = {
    '2024LODS': '#577590',  # Blue
    '2025LODS': '#ff7f0e'   # Orange
}

#==============================================================================
# FIGURE: 8-Panel Grid (4x2)
#==============================================================================

fig, axes = plt.subplots(4, 2, figsize=(15, 20))

# Panel A: Yield vs Drone Plant Count
ax = axes[0, 0]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['Drone_Plant_Count', 'Yield'])
    ax.scatter(site_data['Drone_Plant_Count'], site_data['Yield'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['Drone_Plant_Count', 'Yield'])
r, p = stats.pearsonr(data_clean['Drone_Plant_Count'], data_clean['Yield'])
z = np.polyfit(data_clean['Drone_Plant_Count'], data_clean['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(data_clean['Drone_Plant_Count'].min(), data_clean['Drone_Plant_Count'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Drone-Derived Plant Counts', fontsize=14, fontweight='bold')
ax.set_ylabel('Plot Yield (kg/ha)', fontsize=14, fontweight='bold')
ax.set_title('A', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel B: Peak Stand vs Drone Plant Count
ax = axes[0, 1]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['Drone_Plant_Count', 'Peak_Stand'])
    ax.scatter(site_data['Drone_Plant_Count'], site_data['Peak_Stand'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['Drone_Plant_Count', 'Peak_Stand'])
r, p = stats.pearsonr(data_clean['Drone_Plant_Count'], data_clean['Peak_Stand'])
z = np.polyfit(data_clean['Drone_Plant_Count'], data_clean['Peak_Stand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(data_clean['Drone_Plant_Count'].min(), data_clean['Drone_Plant_Count'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Drone-Derived Plant Counts', fontsize=14, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=14, fontweight='bold')
ax.set_title('B', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel C: Yield vs Harvestable Area
ax = axes[1, 0]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['HA_Mean', 'Yield'])
    ax.scatter(site_data['HA_Mean'], site_data['Yield'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['HA_Mean', 'Yield'])
r, p = stats.pearsonr(data_clean['HA_Mean'], data_clean['Yield'])
z = np.polyfit(data_clean['HA_Mean'], data_clean['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(data_clean['HA_Mean'].min(), data_clean['HA_Mean'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Seedling Derived Harvestable Area', fontsize=14, fontweight='bold')
ax.set_ylabel('Plot Yield (kg/ha)', fontsize=14, fontweight='bold')
ax.set_title('C', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel D: Peak Stand vs Harvestable Area
ax = axes[1, 1]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['HA_Mean', 'Peak_Stand'])
    ax.scatter(site_data['HA_Mean'], site_data['Peak_Stand'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['HA_Mean', 'Peak_Stand'])
r, p = stats.pearsonr(data_clean['HA_Mean'], data_clean['Peak_Stand'])
z = np.polyfit(data_clean['HA_Mean'], data_clean['Peak_Stand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(data_clean['HA_Mean'].min(), data_clean['HA_Mean'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Seedling Derived Harvestable Area', fontsize=14, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=14, fontweight='bold')
ax.set_title('D', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel E: Yield vs Peak Stand
ax = axes[2, 0]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['Peak_Stand', 'Yield'])
    ax.scatter(site_data['Peak_Stand']*100, site_data['Yield'],  # Scale to 0-100
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['Peak_Stand', 'Yield'])
x_scaled = data_clean['Peak_Stand']*100
r, p = stats.pearsonr(x_scaled, data_clean['Yield'])
z = np.polyfit(x_scaled, data_clean['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(x_scaled.min(), x_scaled.max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Stand Scores', fontsize=14, fontweight='bold')
ax.set_ylabel('Plot Yield (kg/ha)', fontsize=14, fontweight='bold')
ax.set_title('E', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel F: Peak Stand vs Scaled Peak Stand
ax = axes[2, 1]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['Peak_Stand'])
    ax.scatter(site_data['Peak_Stand']*100, site_data['Peak_Stand'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['Peak_Stand'])
x_scaled = data_clean['Peak_Stand']*100
r, p = stats.pearsonr(x_scaled, data_clean['Peak_Stand'])
z = np.polyfit(x_scaled, data_clean['Peak_Stand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(x_scaled.min(), x_scaled.max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Stand Scores', fontsize=14, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=14, fontweight='bold')
ax.set_title('F', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel G: Yield vs Drone Plant Count (as proxy for manual)
ax = axes[3, 0]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['Drone_Plant_Count', 'Yield'])
    ax.scatter(site_data['Drone_Plant_Count'], site_data['Yield'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['Drone_Plant_Count', 'Yield'])
r, p = stats.pearsonr(data_clean['Drone_Plant_Count'], data_clean['Yield'])
z = np.polyfit(data_clean['Drone_Plant_Count'], data_clean['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(data_clean['Drone_Plant_Count'].min(), data_clean['Drone_Plant_Count'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Manual Plant Counts', fontsize=14, fontweight='bold')
ax.set_ylabel('Plot Yield (kg/ha)', fontsize=14, fontweight='bold')
ax.set_title('G', fontsize=16, fontweight='bold', loc='left', pad=10)
ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

# Panel H: Peak Stand vs Drone Plant Count
ax = axes[3, 1]
for site, color in site_colors.items():
    site_data = merged_data[merged_data['Site_Year'] == site].dropna(subset=['Drone_Plant_Count', 'Peak_Stand'])
    ax.scatter(site_data['Drone_Plant_Count'], site_data['Peak_Stand'],
              s=110, alpha=0.7, color=color, edgecolors='black', linewidth=0.8,
              zorder=3)

data_clean = merged_data.dropna(subset=['Drone_Plant_Count', 'Peak_Stand'])
r, p = stats.pearsonr(data_clean['Drone_Plant_Count'], data_clean['Peak_Stand'])
z = np.polyfit(data_clean['Drone_Plant_Count'], data_clean['Peak_Stand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(data_clean['Drone_Plant_Count'].min(), data_clean['Drone_Plant_Count'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'k-', linewidth=3, alpha=0.8, zorder=2)

sig_label = '***' if p < 0.001 else '**' if p < 0.01 else '*' if p < 0.05 else ''
ax.text(0.05, 0.95, f'r={r:.3f}{sig_label}\nr²={r**2:.3f}', transform=ax.transAxes,
       fontsize=12, fontweight='bold', va='top', bbox=dict(boxstyle='round', facecolor='white', alpha=0.95))

ax.set_xlabel('Manual Plant Counts', fontsize=14, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=14, fontweight='bold')
ax.set_title('H', fontsize=16, fontweight='bold', loc='left', pad=10)

# Add COMPACT legend with LARGER markers
from matplotlib.lines import Line2D
legend_elements = [
    Line2D([0], [0], marker='o', color='w', markerfacecolor=site_colors['2024LODS'], 
           markersize=14, markeredgecolor='black', markeredgewidth=1, label='2024 LODS Registration'),
    Line2D([0], [0], marker='o', color='w', markerfacecolor=site_colors['2025LODS'], 
           markersize=14, markeredgecolor='black', markeredgewidth=1, label='2025 LODS Registration'),
    Line2D([0], [0], color='k', linewidth=3, label='Combined Regression')
]
ax.legend(handles=legend_elements, loc='lower right', fontsize=12, 
         framealpha=0.97, edgecolor='black', title='Trial Name', title_fontsize=13,
         handlelength=1.5, handletextpad=0.5)  # Shorter legend lines

ax.grid(alpha=0.3)
ax.tick_params(labelsize=12)

plt.tight_layout()
plt.savefig('/mnt/user-data/outputs/eight_panel_correlations.png',
           dpi=300, bbox_inches='tight')
print("\n✓ Created: eight_panel_correlations.png")
plt.close()
