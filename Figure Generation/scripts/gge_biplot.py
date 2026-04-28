"""
GGE Biplot ONLY - Focused visualization with everything in frame
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.preprocessing import StandardScaler

# Set style
sns.set_style("whitegrid")
plt.rcParams['font.size'] = 11
plt.rcParams['figure.dpi'] = 150

# Load data
spatial_data = pd.read_csv('/mnt/user-data/outputs/COMPLETE_INPUT_DATA_ALL_SITES.csv')
all_sites_data = pd.read_csv('/mnt/user-data/uploads/All_Site-Years_Data_For_Trial-Wide_Analysis.csv')

# Apply 2506 correction
spatial_data.loc[spatial_data['Trial'] == 2506, 'sum_distances_div2'] = spatial_data.loc[spatial_data['Trial'] == 2506, 'sum_distances_div2'] / 2

# Get trial-level averages
trial_spatial = spatial_data.groupby('Trial').agg({
    'HA_Mean': 'mean',
    'variance_distance': 'mean',
    'sum_distances_div2': 'mean',
    'Site': 'first'
}).reset_index()

# Merge datasets
data = pd.merge(all_sites_data, trial_spatial, on='Trial', how='inner')

# Rename columns
data = data.rename(columns={
    'Peak Stand': 'Peak_Stand',
    'PltCounts': 'Plant_Count_Drone',
    'Thresh_mean': 'Drone_Stand_Threshold',
    'Plot Yield': 'Yield'
})

# Select traits
traits = {
    'HA_Mean': 'Harvestable Area',
    'variance_distance': 'Distance Variance',
    'sum_distances_div2': 'Plot Length',
    'Plant_Count_Drone': 'Plant Count',
    'Yield': 'Yield',
    'Drone_Stand_Threshold': 'Drone Peak Stand'
}

# Filter data
data_clean = data[list(traits.keys())].dropna()
X = data_clean.values
trait_names = list(traits.values())

print(f"Data: {X.shape[0]} observations × {X.shape[1]} traits")

# Standardize
scaler = StandardScaler()
X_scaled = scaler.fit_transform(X)

# SVD
U, s, Vt = np.linalg.svd(X_scaled, full_matrices=False)
var_explained = (s**2) / np.sum(s**2) * 100

print(f"PC1: {var_explained[0]:.1f}%, PC2: {var_explained[1]:.1f}%")
print(f"Total: {var_explained[0] + var_explained[1]:.1f}%")

# GGE coordinates
trait_pc1 = Vt[0, :] * np.sqrt(s[0])
trait_pc2 = Vt[1, :] * np.sqrt(s[1])

# Define categories
early_season_traits = ['Harvestable Area', 'Distance Variance', 'Plot Length', 'Plant Count']
target_traits = ['Yield', 'Drone Peak Stand']
mature_drone_traits = []  # Empty now

#==============================================================================
# FIGURE: GGE BIPLOT ONLY
#==============================================================================

fig, ax = plt.subplots(1, 1, figsize=(14, 14))

# Plot origin
ax.axhline(0, color='gray', linewidth=1, linestyle='--', alpha=0.5, zorder=1)
ax.axvline(0, color='gray', linewidth=1, linestyle='--', alpha=0.5, zorder=1)

# Plot trait vectors
for i, name in enumerate(trait_names):
    # Color by category
    if name in early_season_traits:
        color = '#ff6b6b'  # Red for early season
    elif name in target_traits:
        color = '#4ecdc4'  # Teal for target traits
    else:
        color = '#9b59b6'  # Purple (not used now but keeping for safety)
    
    # Draw arrow
    ax.arrow(0, 0, trait_pc1[i], trait_pc2[i],
            head_width=0.15, head_length=0.15, fc=color, ec=color,
            linewidth=3, alpha=0.8, zorder=5)
    
    # Calculate label position with extra offset
    offset_multiplier = 1.15
    label_x = trait_pc1[i] * offset_multiplier
    label_y = trait_pc2[i] * offset_multiplier
    
    # Add label
    ax.text(label_x, label_y, name, fontsize=12, fontweight='bold',
           ha='center', va='center',
           bbox=dict(boxstyle='round,pad=0.5', facecolor='white', 
                    edgecolor=color, alpha=0.95, linewidth=2.5),
           zorder=10)

# Add legend
from matplotlib.lines import Line2D
legend_elements = [
    Line2D([0], [0], color='#ff6b6b', linewidth=3, 
           label='Early Season Metrics'),
    Line2D([0], [0], color='#4ecdc4', linewidth=3, 
           label='Target Traits')
]
ax.legend(handles=legend_elements, loc='lower right', fontsize=13, 
         framealpha=0.97, edgecolor='black', fancybox=True)

# Axes labels and title
ax.set_xlabel(f'PC1 ({var_explained[0]:.1f}% of variance)', 
             fontsize=15, fontweight='bold')
ax.set_ylabel(f'PC2 ({var_explained[1]:.1f}% of variance)', 
             fontsize=15, fontweight='bold')
ax.set_title('Trait Relationships: Early Season Metrics vs Target Traits\n(GGE Biplot)', 
            fontsize=16, fontweight='bold', pad=20)

# Grid and aspect
ax.grid(alpha=0.3, linewidth=0.5)
ax.set_aspect('equal', adjustable='box')

# Set limits with generous padding
max_val = max(abs(trait_pc1).max(), abs(trait_pc2).max()) * 1.4
ax.set_xlim(-max_val, max_val)
ax.set_ylim(-max_val, max_val)

# Tick parameters
ax.tick_params(labelsize=11)

plt.tight_layout()
plt.savefig('/mnt/user-data/outputs/gge_biplot_traits.png', 
           dpi=300, bbox_inches='tight', pad_inches=0.2)
print("\n✓ Created: gge_biplot_traits.png")
print("✓ All labels within frame with adequate padding")
plt.close()
