"""
Correlation Figures - Corrected Version with Large Fonts
Generates:
1. 6-panel Spatial Metrics correlations (HA, Yield, Peak Stand vs Plot Length & Distance Variance)
2. 2-panel HA correlations (HA vs Yield & Peak Stand)

All with enlarged fonts for presentations and thesis defense.
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from scipy import stats

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 150

#==============================================================================
# LOAD AND PREPARE DATA
#==============================================================================

print("Loading data...")

# Load datasets
complete = pd.read_csv('/mnt/user-data/outputs/COMPLETE_INPUT_DATA_ALL_SITES.csv')
yield_stand = pd.read_csv('/mnt/user-data/uploads/all_siteyears_yield_stand_data__1_.csv')
lods_2024 = pd.read_csv('/mnt/user-data/uploads/2024Lods_for_HA2.csv')

# Apply 2506 correction for plot length
complete.loc[complete['Trial'] == 2506, 'sum_distances_div2'] = complete.loc[complete['Trial'] == 2506, 'sum_distances_div2'] / 2

# Prepare LODS 2024 data
lods_2024_prep = lods_2024[['Trial', 'Plot Yield', 'HAreamean', 'PeakStand']].copy()
lods_2024_prep.columns = ['Trial', 'Yield', 'HA', 'PeakStand']
lods_2024_prep['SiteYear'] = '2024LODS'

# Combine yield_stand with LODS 2024
yield_stand_combined = pd.concat([yield_stand, lods_2024_prep], ignore_index=True)

# Create matching keys using Trial + HA
complete['match_key'] = (complete['Trial'].astype(str) + '_' + 
                         complete['HA_Mean'].round(6).astype(str))

yield_stand_combined['match_key'] = (yield_stand_combined['Trial'].astype(str) + '_' +
                                     yield_stand_combined['HA'].round(6).astype(str))

# Drop duplicates - keep first occurrence
yield_stand_unique = yield_stand_combined.drop_duplicates(subset='match_key', keep='first')

# Merge to get ONE peak stand per plot
data = complete.merge(
    yield_stand_unique[['match_key', 'PeakStand']],
    on='match_key',
    how='left'
)

# Drop plots without PeakStand
data = data[data['PeakStand'].notna()].copy()

print(f"Total plots: {len(data)}")
print("By site:")
print(data.groupby('Site').size())

# Site colors - matching original figures
site_colors = {
    'SVREC_2025': '#2ca02c',  # Green
    'LODS_2025': '#ff7f0e',   # Orange
    'LODS_2024': '#1f77b4'    # Blue
}

site_labels = {
    'SVREC_2025': 'SVREC 2025',
    'LODS_2025': 'LODS 2025',
    'LODS_2024': 'LODS 2024'
}

#==============================================================================
# FIGURE 1: 6-PANEL SPATIAL METRICS (3x2 grid)
#==============================================================================

print("\nCreating 6-panel spatial metrics figure...")

fig, axes = plt.subplots(3, 2, figsize=(20, 26))

# Row 1: HA vs Plot Length and Distance Variance
# Panel 1: HA vs Plot Length
ax = axes[0, 0]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['sum_distances_div2'], site_data['HA_Mean'],
              s=60, alpha=0.6, color=color, edgecolors='none', label=site_labels[site])

clean_data = data[['sum_distances_div2', 'HA_Mean']].dropna()
r, p = stats.pearsonr(clean_data['sum_distances_div2'], clean_data['HA_Mean'])
z = np.polyfit(clean_data['sum_distances_div2'], clean_data['HA_Mean'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['sum_distances_div2'].min(), clean_data['sum_distances_div2'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=2.5, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Drone-Derived Plot Length', fontsize=22, fontweight='bold')
ax.set_ylabel('Harvestable Area (HA)', fontsize=22, fontweight='bold')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)
ax.legend(loc='lower right', fontsize=18, framealpha=0.95)

# Panel 2: HA vs Distance Variance
ax = axes[0, 1]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['variance_distance'], site_data['HA_Mean'],
              s=60, alpha=0.6, color=color, edgecolors='none')

clean_data = data[['variance_distance', 'HA_Mean']].dropna()
r, p = stats.pearsonr(clean_data['variance_distance'], clean_data['HA_Mean'])
z = np.polyfit(clean_data['variance_distance'], clean_data['HA_Mean'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['variance_distance'].min(), clean_data['variance_distance'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=2.5, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Seedling Distance Variance', fontsize=22, fontweight='bold')
ax.set_ylabel('Harvestable Area (HA)', fontsize=22, fontweight='bold')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)

# Row 2: Yield vs Plot Length and Distance Variance
# Panel 3: Yield vs Plot Length
ax = axes[1, 0]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['sum_distances_div2'], site_data['Yield'],
              s=60, alpha=0.6, color=color, edgecolors='none')

clean_data = data[['sum_distances_div2', 'Yield']].dropna()
r, p = stats.pearsonr(clean_data['sum_distances_div2'], clean_data['Yield'])
z = np.polyfit(clean_data['sum_distances_div2'], clean_data['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['sum_distances_div2'].min(), clean_data['sum_distances_div2'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=2.5, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Drone-Derived Plot Length', fontsize=22, fontweight='bold')
ax.set_ylabel('Yield (kg/ha)', fontsize=22, fontweight='bold')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)

# Panel 4: Yield vs Distance Variance
ax = axes[1, 1]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['variance_distance'], site_data['Yield'],
              s=60, alpha=0.6, color=color, edgecolors='none')

clean_data = data[['variance_distance', 'Yield']].dropna()
r, p = stats.pearsonr(clean_data['variance_distance'], clean_data['Yield'])
z = np.polyfit(clean_data['variance_distance'], clean_data['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['variance_distance'].min(), clean_data['variance_distance'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=2.5, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Seedling Distance Variance', fontsize=22, fontweight='bold')
ax.set_ylabel('Yield (kg/ha)', fontsize=22, fontweight='bold')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)

# Row 3: Peak Stand vs Plot Length and Distance Variance
# Panel 5: Peak Stand vs Plot Length
ax = axes[2, 0]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['sum_distances_div2'], site_data['PeakStand'],
              s=60, alpha=0.6, color=color, edgecolors='none')

clean_data = data[['sum_distances_div2', 'PeakStand']].dropna()
r, p = stats.pearsonr(clean_data['sum_distances_div2'], clean_data['PeakStand'])
z = np.polyfit(clean_data['sum_distances_div2'], clean_data['PeakStand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['sum_distances_div2'].min(), clean_data['sum_distances_div2'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=2.5, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Drone-Derived Plot Length', fontsize=22, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=22, fontweight='bold')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)

# Panel 6: Peak Stand vs Distance Variance  
ax = axes[2, 1]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['variance_distance'], site_data['PeakStand'],
              s=60, alpha=0.6, color=color, edgecolors='none')

clean_data = data[['variance_distance', 'PeakStand']].dropna()
r, p = stats.pearsonr(clean_data['variance_distance'], clean_data['PeakStand'])
z = np.polyfit(clean_data['variance_distance'], clean_data['PeakStand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['variance_distance'].min(), clean_data['variance_distance'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=2.5, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Seedling Distance Variance', fontsize=22, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=22, fontweight='bold')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)

# Overall title
fig.suptitle('Seedling Spatial Metrics: Correlations with Harvestable Area, Yield, and Peak Stand',
            fontsize=26, fontweight='bold', y=0.995)

plt.tight_layout(rect=[0, 0, 1, 0.99])
plt.savefig('/mnt/user-data/outputs/spatial_metrics_final_large_fonts.png',
           dpi=300, bbox_inches='tight')
print("✓ Created: spatial_metrics_final_large_fonts.png")
plt.close()

#==============================================================================
# FIGURE 2: 2-PANEL HA CORRELATIONS (1x2 grid)
#==============================================================================

print("\nCreating 2-panel HA correlations figure...")

fig, axes = plt.subplots(1, 2, figsize=(24, 10))

# Panel A: HA vs Yield
ax = axes[0]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['HA_Mean'], site_data['Yield'],
              s=70, alpha=0.6, color=color, edgecolors='none', label=site_labels[site])

clean_data = data[['HA_Mean', 'Yield']].dropna()
r, p = stats.pearsonr(clean_data['HA_Mean'], clean_data['Yield'])
z = np.polyfit(clean_data['HA_Mean'], clean_data['Yield'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['HA_Mean'].min(), clean_data['HA_Mean'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=3, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.95, edgecolor='black'))

ax.set_xlabel('Harvestable Area (HA)', fontsize=24, fontweight='bold')
ax.set_ylabel('Plot Yield (kg/ha)', fontsize=24, fontweight='bold')
ax.set_title('A) Harvestable Area vs Yield', fontsize=26, fontweight='bold', pad=15, loc='left')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)
ax.legend(loc='upper right', fontsize=16, framealpha=0.95, edgecolor='black')

# Panel B: HA vs Peak Stand
ax = axes[1]
for site, color in site_colors.items():
    site_data = data[data['Site'] == site]
    ax.scatter(site_data['HA_Mean'], site_data['PeakStand'],
              s=70, alpha=0.6, color=color, edgecolors='none', label=site_labels[site])

clean_data = data[['HA_Mean', 'PeakStand']].dropna()
r, p = stats.pearsonr(clean_data['HA_Mean'], clean_data['PeakStand'])
z = np.polyfit(clean_data['HA_Mean'], clean_data['PeakStand'], 1)
p_fit = np.poly1d(z)
x_line = np.linspace(clean_data['HA_Mean'].min(), clean_data['HA_Mean'].max(), 100)
ax.plot(x_line, p_fit(x_line), 'r--', linewidth=3, alpha=0.8)

ax.text(0.05, 0.95, f'r = {r:.3f}\np < 0.0001\nn = {len(clean_data)}',
       transform=ax.transAxes, fontsize=18, va='top',
       bbox=dict(boxstyle='round', facecolor='white', alpha=0.95, edgecolor='black'))

ax.set_xlabel('Harvestable Area (HA)', fontsize=24, fontweight='bold')
ax.set_ylabel('Peak Stand', fontsize=24, fontweight='bold')
ax.set_title('B) Harvestable Area vs Peak Stand', fontsize=26, fontweight='bold', pad=15, loc='left')
ax.tick_params(labelsize=20)
ax.grid(alpha=0.3)
ax.legend(loc='upper right', fontsize=16, framealpha=0.95, edgecolor='black')

plt.tight_layout()
plt.savefig('/mnt/user-data/outputs/ha_correlations_final_large_fonts.png',
           dpi=300, bbox_inches='tight')
print("✓ Created: ha_correlations_final_large_fonts.png")
plt.close()

print("\n" + "="*70)
print("✓ Both correlation figures created successfully!")
print("="*70)
