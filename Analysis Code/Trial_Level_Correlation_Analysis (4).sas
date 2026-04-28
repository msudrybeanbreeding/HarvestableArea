/*==============================================================================
  SAS Code: Trial-Level Correlation Analysis
  Purpose: Correlate trial-level normalized yield with trial-level harvestable area
  Author: Mason
  Date: January 14, 2026
==============================================================================*/

/* Set library and options */
options validvarname=v7;

/* Import the CSV data */
proc import datafile="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\All Site-Years Data For Trial-Wide Analysis.csv"
    out=work.plot_data
    dbms=csv
    replace;
    guessingrows=max;
run;

/* Check the imported data */
proc print data=work.plot_data(obs=10);
    title "First 10 Observations of Plot-Level Data";
run;

proc contents data=work.plot_data;
    title "Contents of Plot-Level Data";
run;

/*==============================================================================
  Step 1: Aggregate to Trial Level
==============================================================================*/

/* Sort data before aggregating */
proc sort data=work.plot_data;
    by Year Location Siteyear Trial;
run;

/* Calculate trial-level means for normalized yield and harvestable area */
proc means data=work.plot_data noprint;
    by Year Location Siteyear Trial;
    var Normalized_Plot_Yield HAreamean;
    output out=work.trial_level
        mean=Trial_Normalized_Yield Trial_Harvestable_Area
        n=N_Plots
        std=SD_Normalized_Yield SD_Harvestable_Area;
run;

/* Display trial-level summary statistics */
proc print data=work.trial_level;
    title "Trial-Level Summary Statistics";
    var Year Location Siteyear Trial Trial_Normalized_Yield Trial_Harvestable_Area N_Plots;
    format Trial_Normalized_Yield Trial_Harvestable_Area 8.4;
run;

/*==============================================================================
  Step 2: Descriptive Statistics by Site-Year and Overall
==============================================================================*/

/* Descriptive statistics by site-year */
proc means data=work.trial_level n mean std min max;
    by Siteyear;
    var Trial_Normalized_Yield Trial_Harvestable_Area;
    title "Trial-Level Descriptive Statistics by Site-Year";
run;

/* Overall descriptive statistics */
proc means data=work.trial_level n mean std min max;
    var Trial_Normalized_Yield Trial_Harvestable_Area N_Plots;
    title "Overall Trial-Level Descriptive Statistics";
run;

/*==============================================================================
  Step 3: Correlation Analysis - Overall
==============================================================================*/

/* Pearson correlation with significance test */
proc corr data=work.trial_level pearson;
    var Trial_Normalized_Yield Trial_Harvestable_Area;
    title "Pearson Correlation: Trial-Level Normalized Yield vs Harvestable Area";
    title2 "All Site-Years Combined";
run;

/* Spearman correlation (non-parametric) */
proc corr data=work.trial_level spearman;
    var Trial_Normalized_Yield Trial_Harvestable_Area;
    title "Spearman Correlation: Trial-Level Normalized Yield vs Harvestable Area";
    title2 "All Site-Years Combined";
run;

/*==============================================================================
  Step 4: Correlation Analysis by Site-Year
==============================================================================*/

/* Pearson correlation by site-year */
proc sort data=work.trial_level;
    by Siteyear;
run;

proc corr data=work.trial_level pearson;
    by Siteyear;
    var Trial_Normalized_Yield Trial_Harvestable_Area;
    title "Pearson Correlation by Site-Year";
run;

/* Spearman correlation by site-year */
proc corr data=work.trial_level spearman;
    by Siteyear;
    var Trial_Normalized_Yield Trial_Harvestable_Area;
    title "Spearman Correlation by Site-Year";
run;

/*==============================================================================
  Step 5: Simple Linear Regression
==============================================================================*/

/* Overall regression model */
proc reg data=work.trial_level;
    model Trial_Normalized_Yield = Trial_Harvestable_Area / vif;
    title "Simple Linear Regression: Normalized Yield vs Harvestable Area";
    title2 "All Site-Years Combined";
    output out=work.reg_diagnostics predicted=Predicted residual=Residual;
run;
quit;

/* Regression by site-year */
proc sort data=work.trial_level;
    by Siteyear;
run;

proc reg data=work.trial_level;
    by Siteyear;
    model Trial_Normalized_Yield = Trial_Harvestable_Area;
    title "Simple Linear Regression by Site-Year";
run;
quit;

/*==============================================================================
  Step 6: Visualization - Scatter Plot with Regression Line
==============================================================================*/

/* Overall scatter plot */
proc sgplot data=work.trial_level;
    scatter x=Trial_Harvestable_Area y=Trial_Normalized_Yield / 
        markerattrs=(symbol=circlefilled size=10);
    reg x=Trial_Harvestable_Area y=Trial_Normalized_Yield / 
        lineattrs=(color=blue thickness=2) clm;
    xaxis label="Trial-Level Harvestable Area" grid;
    yaxis label="Trial-Level Normalized Yield" grid;
    title "Trial-Level Normalized Yield vs Harvestable Area";
    title2 "All Site-Years Combined with 95% Confidence Limits";
run;

/* Scatter plot by site-year */
proc sgplot data=work.trial_level;
    scatter x=Trial_Harvestable_Area y=Trial_Normalized_Yield / 
        group=Siteyear markerattrs=(size=10);
    reg x=Trial_Harvestable_Area y=Trial_Normalized_Yield / 
        group=Siteyear lineattrs=(thickness=2);
    xaxis label="Trial-Level Harvestable Area" grid;
    yaxis label="Trial-Level Normalized Yield" grid;
    title "Trial-Level Normalized Yield vs Harvestable Area by Site-Year";
run;

/* Panel plot by site-year */
proc sgpanel data=work.trial_level;
    panelby Siteyear / columns=3 rows=1;
    scatter x=Trial_Harvestable_Area y=Trial_Normalized_Yield / 
        markerattrs=(symbol=circlefilled);
    reg x=Trial_Harvestable_Area y=Trial_Normalized_Yield / 
        lineattrs=(color=blue);
    rowaxis label="Trial-Level Normalized Yield" grid;
    colaxis label="Trial-Level Harvestable Area" grid;
    title "Trial-Level Normalized Yield vs Harvestable Area";
    title2 "Separated by Site-Year";
run;

/*==============================================================================
  Step 7: Additional Analysis - Mixed Model Approach
==============================================================================*/

/* Account for site-year as random effect */
proc mixed data=work.trial_level;
    class Siteyear;
    model Trial_Normalized_Yield = Trial_Harvestable_Area / solution;
    random intercept / subject=Siteyear;
    title "Mixed Model: Harvestable Area Effect on Normalized Yield";
    title2 "Site-Year as Random Effect";
run;

/*==============================================================================
  Step 8: Export Results
==============================================================================*/

/* Export trial-level data with correlation results */
proc export data=work.trial_level
    outfile="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\All Site-Year Trial-Wide Analysis\Trial_Level_Summary.csv"
    dbms=csv
    replace;
run;

/* Create a summary table of correlations by site-year */
proc corr data=work.trial_level pearson noprint 
    outp=work.corr_results;
    by Siteyear;
    var Trial_Normalized_Yield Trial_Harvestable_Area;
run;

/* Filter and format correlation results */
data work.corr_summary;
    set work.corr_results;
    where _TYPE_ = 'CORR' and _NAME_ = 'Trial_Normalized_Yield';
    Correlation = Trial_Harvestable_Area;
    keep Siteyear Correlation;
run;

proc print data=work.corr_summary;
    title "Summary of Pearson Correlations by Site-Year";
    format Correlation 8.4;
run;

/*==============================================================================
  End of Code
==============================================================================*/

/* Clean up intermediate datasets if desired */
/* 
proc datasets library=work nolist;
    delete plot_data reg_diagnostics corr_results;
quit;
*/
