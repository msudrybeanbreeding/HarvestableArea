"""
Partial Variance Partitioning: Unique and Shared Components
With LARGE FONTS for visibility
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

# Set style
sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 150

# Load data
data = pd.read_csv('/mnt/user-data/outputs/variance_partitioning_partial_results.csv')

print("Creating variance partitioning figure with LARGE FONTS...")
print(f"Data: {len(data)} trials")

# Site colors
site_colors = {
    'SVREC_2025': '#90EE90',  # Light green
    'LODS_2025': '#FFB6C1',   # Light pink/salmon
    'LODS_2024': '#ADD8E6'    # Light blue
}

#==============================================================================
# FIGURE: Stacked Bar Chart
#==============================================================================

fig, ax = plt.subplots(figsize=(20, 12))  # Taller for larger fonts

# Group by site and order by total variance explained within each site
sites = ['SVREC_2025', 'LODS_2025', 'LODS_2024']
x_positions = []
x_labels = []
current_x = 0

for site in sites:
    site_data = data[data['Site'] == site].sort_values('total_cov_pct', ascending=False)  # Order by variance explained
    
    for idx, row in site_data.iterrows():
        trial_id = row['Trial']
        
        # Stack bars
        bottom = 0
        
        # HA Unique - Teal/cyan
        ax.bar(current_x, row['unique_ha_pct'], width=0.8, 
              bottom=bottom, color='#7FCDCD', edgecolor='black', linewidth=0.5,
              label='HA (Unique)' if current_x == 0 else '')
        bottom += row['unique_ha_pct']
        
        # Plot Length Unique - Yellow
        ax.bar(current_x, row['unique_nnsum_pct'], width=0.8,
              bottom=bottom, color='#F4E76E', edgecolor='black', linewidth=0.5,
              label='Plot Length (Unique)' if current_x == 0 else '')
        bottom += row['unique_nnsum_pct']
        
        # Seedling Var Unique - Light purple/lavender
        ax.bar(current_x, row['unique_nnvar_pct'], width=0.8,
              bottom=bottom, color='#B8A9C9', edgecolor='black', linewidth=0.5,
              label='Seedling Var (Unique)' if current_x == 0 else '')
        bottom += row['unique_nnvar_pct']
        
        # Shared - Salmon/coral pink
        ax.bar(current_x, row['shared_pct'], width=0.8,
              bottom=bottom, color='#F28B82', edgecolor='black', linewidth=0.5,
              label='Shared' if current_x == 0 else '')
        
        x_positions.append(current_x)
        x_labels.append(str(trial_id))
        current_x += 1
    
    # Add spacing between sites
    current_x += 0.5

# Add site background shading
site_ranges = {
    'SVREC_2025': (0, len(data[data['Site'] == 'SVREC_2025'])),
    'LODS_2025': (len(data[data['Site'] == 'SVREC_2025']) + 0.5, 
                 len(data[data['Site'] == 'SVREC_2025']) + len(data[data['Site'] == 'LODS_2025']) + 0.5),
    'LODS_2024': (len(data[data['Site'] == 'SVREC_2025']) + len(data[data['Site'] == 'LODS_2025']) + 1,
                 len(data) + 0.5)  # Extended to end
}

for site, (start, end) in site_ranges.items():
    ax.axvspan(start - 0.5, end, alpha=0.15, color=site_colors[site], zorder=0)
    
    # Add site label in middle - SMALLER
    mid_x = (start + end - 0.5) / 2
    ax.text(mid_x, ax.get_ylim()[1] * 0.6, site.replace('_', ' '), 
           ha='center', va='center', fontsize=22, fontweight='bold',
           color='black', alpha=0.6)

# Formatting with LARGE FONTS - INCREASED AXIS FONTS
ax.set_xlabel('Trial (grouped by site)', fontsize=30, fontweight='bold')
ax.set_ylabel('% of Total Variance Explained', fontsize=30, fontweight='bold')
ax.set_title('Partial Variance Partitioning: Unique and Shared Components', 
            fontsize=32, fontweight='bold', pad=20)

ax.set_xticks(x_positions)
ax.set_xticklabels(x_labels, rotation=45, ha='right', fontsize=20)  # Increased x-axis
ax.tick_params(axis='y', labelsize=26)  # Increased y-axis ticks

# Legend with larger font
ax.legend(loc='upper right', fontsize=20, framealpha=0.95, edgecolor='black',
         fancybox=True)

ax.grid(axis='y', alpha=0.3, linewidth=0.8)
ax.set_ylim(0, ax.get_ylim()[1])

plt.tight_layout()
plt.savefig('/mnt/user-data/outputs/variance_partitioning_partial_bars_large_fonts.png',
           dpi=300, bbox_inches='tight')
print("\n✓ Created: variance_partitioning_partial_bars_large_fonts.png")
plt.close()

print("\n✓ Variance partitioning figure with LARGE FONTS created successfully!")
