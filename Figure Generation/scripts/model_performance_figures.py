"""
Model Performance Figures - Simplified Export
Generates CV improvement and heritability comparison figures with large fonts
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns

sns.set_style("whitegrid")
plt.rcParams['figure.dpi'] = 150

#==============================================================================
# LOAD DATA
#==============================================================================

cv_data = pd.read_csv('/mnt/user-data/outputs/ALL_COVARIATES_WITH_ACTUAL_NN_VARIANCE.csv')

site_colors = {'2025SVREC': '#90be6d', '2025LODS': '#ff7f0e', '2024LODS': '#577590'}

models = [
    'Drone-Derived\nHarvestable\nArea',
    'Seedling-Derived\nPlot Length',
    'Seedling\nDistance\nVariance',
    'HA + Plot Length',
    'HA + Distance\nVariance',
    'Plot Length +\nDistance Variance',
    'All Three\nCovariates'
]

#==============================================================================
# FIGURE 1: CV IMPROVEMENT BAR CHART
#==============================================================================

print("Creating CV improvement figure...")

fig, ax = plt.subplots(figsize=(20, 14))

x = np.arange(len(models))
width = 0.25

for i, (site, color) in enumerate(site_colors.items()):
    site_data = cv_data[cv_data['SiteYear'] == site]
    
    cv_improvements = []
    cv_errors = []
    
    for model in models:
        model_key = model.replace('\n', ' ')
        baseline_cv = site_data['Baseline_CV'].values[0]
        model_cv = site_data[f'CV_{model_key}'].values[0]
        cv_se = site_data[f'CV_SE_{model_key}'].values[0]
        
        improvement = ((baseline_cv - model_cv) / baseline_cv) * 100
        improvement_se = (cv_se / baseline_cv) * 100
        
        cv_improvements.append(improvement)
        cv_errors.append(improvement_se)
    
    offset = width * (i - 1)
    bars = ax.bar(x + offset, cv_improvements, width, label=site, 
                   color=color, alpha=0.8, edgecolor='black', linewidth=1.5)
    
    ax.errorbar(x + offset, cv_improvements, yerr=cv_errors, 
                fmt='none', ecolor='black', capsize=6, capthick=2.5, linewidth=2.5)

ax.axhline(y=0, color='black', linestyle='-', linewidth=2)
ax.text(0.02, 0.02, 'Error bars: ±SE', transform=ax.transAxes, 
        fontsize=20, va='bottom', ha='left',
        bbox=dict(boxstyle='round', facecolor='white', alpha=0.9))

ax.set_xlabel('Spatial Covariate Model', fontsize=26, fontweight='bold')
ax.set_ylabel('CV Improvement (%)', fontsize=26, fontweight='bold')
ax.set_title('Coefficient of Variation Improvement by Spatial Covariate Model', 
             fontsize=30, fontweight='bold', pad=20)
ax.set_xticks(x)
ax.set_xticklabels(models, fontsize=20, ha='center')
ax.tick_params(axis='y', labelsize=20)
ax.legend(fontsize=22, loc='upper left', ncol=4, framealpha=0.95, 
          edgecolor='black', columnspacing=1.5)
ax.grid(alpha=0.3, axis='y')

plt.subplots_adjust(bottom=0.25, left=0.08, right=0.99, top=0.96)
plt.savefig('/mnt/user-data/outputs/cv_improvement_large_fonts.png', dpi=300, bbox_inches='tight')
print("✓ Created: cv_improvement_large_fonts.png")
plt.close()

#==============================================================================
# FIGURE 2: CV AND HERITABILITY COMPARISON (2x2)
#==============================================================================

print("Creating CV/H² comparison figure...")

fig, axes = plt.subplots(2, 2, figsize=(20, 20))

site_shapes = {'2025SVREC': 'o', '2025LODS': 's', '2024LODS': '^'}

# Panel A: CV - HA alone
ax = axes[0, 0]
for site, color in site_colors.items():
    site_data = cv_data[cv_data['SiteYear'] == site]
    ax.scatter(site_data['Baseline_CV'], site_data['CV_Drone-Derived Harvestable Area'],
              s=150, marker=site_shapes[site], color=color, alpha=0.7, 
              edgecolors='black', linewidth=1.5, label=site)

min_val = cv_data['CV_Drone-Derived Harvestable Area'].min() * 0.95
max_val = cv_data['Baseline_CV'].max() * 1.05
ax.plot([min_val, max_val], [min_val, max_val], 'k--', linewidth=2, alpha=0.5, label='1:1 line')

z = np.polyfit(cv_data['Baseline_CV'], cv_data['CV_Drone-Derived Harvestable Area'], 1)
p = np.poly1d(z)
x_line = np.linspace(min_val, max_val, 100)
ax.plot(x_line, p(x_line), 'r-', linewidth=2.5, alpha=0.8, label='Regression')

ax.fill_between([min_val, max_val], [min_val, max_val], max_val, 
                 alpha=0.1, color='green', label='Improvement zone')

ax.set_xlabel('Baseline CV', fontsize=22, fontweight='bold')
ax.set_ylabel('CV with Harvestable Area', fontsize=22, fontweight='bold')
ax.set_title('A) CV: Harvestable Area Only', fontsize=24, fontweight='bold', pad=10)
ax.tick_params(labelsize=20)
ax.legend(fontsize=16, loc='lower right', framealpha=0.95)
ax.grid(alpha=0.3)

# Panel B: CV - All 3 covariates
ax = axes[0, 1]
for site, color in site_colors.items():
    site_data = cv_data[cv_data['SiteYear'] == site]
    ax.scatter(site_data['Baseline_CV'], 
              site_data['CV_Harvestable Area, Seedling-Derived Plot Length and Seedling Distance Variance'],
              s=150, marker=site_shapes[site], color=color, alpha=0.7, 
              edgecolors='black', linewidth=1.5, label=site)

min_val = cv_data['CV_Harvestable Area, Seedling-Derived Plot Length and Seedling Distance Variance'].min() * 0.95
max_val = cv_data['Baseline_CV'].max() * 1.05
ax.plot([min_val, max_val], [min_val, max_val], 'k--', linewidth=2, alpha=0.5, label='1:1 line')

z = np.polyfit(cv_data['Baseline_CV'], 
               cv_data['CV_Harvestable Area, Seedling-Derived Plot Length and Seedling Distance Variance'], 1)
p = np.poly1d(z)
x_line = np.linspace(min_val, max_val, 100)
ax.plot(x_line, p(x_line), 'r-', linewidth=2.5, alpha=0.8, label='Regression')

ax.fill_between([min_val, max_val], [min_val, max_val], max_val, 
                 alpha=0.1, color='green', label='Improvement zone')

ax.set_xlabel('Baseline CV', fontsize=22, fontweight='bold')
ax.set_ylabel('CV with All Three Covariates', fontsize=22, fontweight='bold')
ax.set_title('B) CV: Harvestable Area, Seedling-Derived\nPlot Length and Seedling Distance Variance', 
             fontsize=24, fontweight='bold', pad=10)
ax.tick_params(labelsize=20)
ax.legend(fontsize=16, loc='lower right', framealpha=0.95)
ax.grid(alpha=0.3)

# Panel C: Heritability - HA alone
ax = axes[1, 0]
for site, color in site_colors.items():
    site_data = cv_data[cv_data['SiteYear'] == site]
    ax.scatter(site_data['Baseline_H2'], site_data['H2_Drone-Derived Harvestable Area'],
              s=150, marker=site_shapes[site], color=color, alpha=0.7, 
              edgecolors='black', linewidth=1.5, label=site)

min_val = cv_data['Baseline_H2'].min() * 0.95
max_val = cv_data['H2_Drone-Derived Harvestable Area'].max() * 1.05
ax.plot([min_val, max_val], [min_val, max_val], 'k--', linewidth=2, alpha=0.5, label='1:1 line')

z = np.polyfit(cv_data['Baseline_H2'], cv_data['H2_Drone-Derived Harvestable Area'], 1)
p = np.poly1d(z)
x_line = np.linspace(min_val, max_val, 100)
ax.plot(x_line, p(x_line), 'r-', linewidth=2.5, alpha=0.8, label='Regression')

ax.fill_between([min_val, max_val], min_val, [min_val, max_val], 
                 alpha=0.1, color='green', label='Improvement zone')

ax.set_xlabel('Baseline Heritability', fontsize=22, fontweight='bold')
ax.set_ylabel('Heritability with Harvestable Area', fontsize=22, fontweight='bold')
ax.set_title('C) Heritability: Harvestable Area Only', fontsize=24, fontweight='bold', pad=10)
ax.tick_params(labelsize=20)
ax.legend(fontsize=16, loc='upper left', framealpha=0.95)
ax.grid(alpha=0.3)

# Panel D: Heritability - All 3 covariates
ax = axes[1, 1]
for site, color in site_colors.items():
    site_data = cv_data[cv_data['SiteYear'] == site]
    ax.scatter(site_data['Baseline_H2'], 
              site_data['H2_Harvestable Area, Seedling-Derived Plot Length and Seedling Distance Variance'],
              s=150, marker=site_shapes[site], color=color, alpha=0.7, 
              edgecolors='black', linewidth=1.5, label=site)

min_val = cv_data['Baseline_H2'].min() * 0.95
max_val = cv_data['H2_Harvestable Area, Seedling-Derived Plot Length and Seedling Distance Variance'].max() * 1.05
ax.plot([min_val, max_val], [min_val, max_val], 'k--', linewidth=2, alpha=0.5, label='1:1 line')

z = np.polyfit(cv_data['Baseline_H2'], 
               cv_data['H2_Harvestable Area, Seedling-Derived Plot Length and Seedling Distance Variance'], 1)
p = np.poly1d(z)
x_line = np.linspace(min_val, max_val, 100)
ax.plot(x_line, p(x_line), 'r-', linewidth=2.5, alpha=0.8, label='Regression')

ax.fill_between([min_val, max_val], min_val, [min_val, max_val], 
                 alpha=0.1, color='green', label='Improvement zone')

ax.set_xlabel('Baseline Heritability', fontsize=22, fontweight='bold')
ax.set_ylabel('Heritability with All Three Covariates', fontsize=22, fontweight='bold')
ax.set_title('D) Heritability: Harvestable Area, Seedling-Derived\nPlot Length and Seedling Distance Variance', 
             fontsize=24, fontweight='bold', pad=10)
ax.tick_params(labelsize=20)
ax.legend(fontsize=16, loc='upper left', framealpha=0.95)
ax.grid(alpha=0.3)

plt.subplots_adjust(left=0.08, right=0.99, top=0.97, bottom=0.05, hspace=0.25, wspace=0.20)
plt.savefig('/mnt/user-data/outputs/cv_h2_comparison_large_fonts.png', dpi=300, bbox_inches='tight')
print("✓ Created: cv_h2_comparison_large_fonts.png")
plt.close()

print("\n" + "="*70)
print("✓ Model performance figures created successfully!")
print("="*70)
