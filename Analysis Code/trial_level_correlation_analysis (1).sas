/*******************************************************************************
* Program: Trial-Level Mean and Variance Analysis with Correlations
* Purpose: 
*   1. Calculate mean and variance for each VI, HA, PLT COUNT, and THRESH by Trial
*   2. Run correlations using trial-level means as treatments (n=13 trials)
*   3. Analyze relationships between trial-averaged VIs and trial-averaged Yield
* 
* Dataset: 2025_Multitemporal_VI_data___yield.csv
* 
* Approach: Treat each trial as a single experimental unit with averaged values
*******************************************************************************/

/* Set options for output and display */
OPTIONS NODATE NONUMBER PS=60 LS=132;
TITLE "Trial-Level Analysis: Means, Variances, and Correlations";

/*******************************************************************************
* STEP 1: Import the CSV dataset
*******************************************************************************/
PROC IMPORT DATAFILE="D:\svrec HA data\2025 Multitemporal VI data + yield.csv"
    OUT=vi_data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Display dataset structure */
PROC CONTENTS DATA=vi_data; 
    TITLE2 "Dataset Structure";
RUN;

/*******************************************************************************
* STEP 2: Calculate Trial-Level Means and Variances for ALL Variables
* This creates one observation per trial with mean and variance for each VI
*******************************************************************************/

PROC SQL;
    CREATE TABLE trial_means_vars AS
    SELECT 
        Trial,
        
        /* Count of observations per trial */
        COUNT(*) AS N_Obs,
        
        /* ExG statistics */
        MEAN(ExG_Mean) AS ExG_Mean_Avg,
        VAR(ExG_Mean) AS ExG_Mean_Var,
        MEAN(ExG_Var) AS ExG_Var_Avg,
        VAR(ExG_Var) AS ExG_Var_Var,
        
        /* ExR statistics */
        MEAN(ExR_Mean) AS ExR_Mean_Avg,
        VAR(ExR_Mean) AS ExR_Mean_Var,
        MEAN(ExR_Var) AS ExR_Var_Avg,
        VAR(ExR_Var) AS ExR_Var_Var,
        
        /* NDVI statistics */
        MEAN(NDVI_Mean) AS NDVI_Mean_Avg,
        VAR(NDVI_Mean) AS NDVI_Mean_Var,
        MEAN(NDVI_Var) AS NDVI_Var_Avg,
        VAR(NDVI_Var) AS NDVI_Var_Var,
        
        /* gNDVI statistics */
        MEAN(gNDVI_Mean) AS gNDVI_Mean_Avg,
        VAR(gNDVI_Mean) AS gNDVI_Mean_Var,
        MEAN(gNDVI_Var) AS gNDVI_Var_Avg,
        VAR(gNDVI_Var) AS gNDVI_Var_Var,
        
        /* NDRE statistics */
        MEAN(NDRE_mean) AS NDRE_Mean_Avg,
        VAR(NDRE_mean) AS NDRE_Mean_Var,
        MEAN(NDRE_Var) AS NDRE_Var_Avg,
        VAR(NDRE_Var) AS NDRE_Var_Var,
        
        /* THRESH statistics */
        MEAN(THRESH_mean) AS THRESH_Mean_Avg,
        VAR(THRESH_mean) AS THRESH_Mean_Var,
        MEAN(THRESH_Var) AS THRESH_Var_Avg,
        VAR(THRESH_Var) AS THRESH_Var_Var,
        
        /* HA Mean statistics */
        MEAN("HA Mean"n) AS HA_Mean_Avg,
        VAR("HA Mean"n) AS HA_Mean_Var,
        
        /* PLT COUNT statistics */
        MEAN("PLT COUNT"n) AS PLT_COUNT_Avg,
        VAR("PLT COUNT"n) AS PLT_COUNT_Var,
        
        /* Yield statistics */
        MEAN(Yield) AS Yield_Avg,
        VAR(Yield) AS Yield_Var
        
    FROM vi_data
    GROUP BY Trial
    ORDER BY Trial;
QUIT;

/* Display the trial-level summary */
PROC PRINT DATA=trial_means_vars;
    TITLE2 "Trial-Level Means and Variances - Summary Table";
    FORMAT ExG_Mean_Avg ExR_Mean_Avg NDVI_Mean_Avg gNDVI_Mean_Avg 
           NDRE_Mean_Avg THRESH_Mean_Avg HA_Mean_Avg PLT_COUNT_Avg 
           Yield_Avg 10.4
           ExG_Mean_Var ExR_Mean_Var NDVI_Mean_Var gNDVI_Mean_Var 
           NDRE_Mean_Var THRESH_Mean_Var HA_Mean_Var PLT_COUNT_Var 
           Yield_Var 12.4;
RUN;

/* Export trial-level means and variances */
PROC EXPORT DATA=trial_means_vars
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\trial_level_means_variances.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 3: Calculate Trial-Level Statistics by DAS
* This creates separate summaries for each DAS timepoint
*******************************************************************************/

PROC SQL;
    CREATE TABLE trial_means_by_das AS
    SELECT 
        Trial,
        DAS,
        
        /* Count of observations per trial-DAS combination */
        COUNT(*) AS N_Obs,
        
        /* VI Means - averaged across plots within trial-DAS */
        MEAN(ExG_Mean) AS ExG_Mean_Avg,
        MEAN(ExR_Mean) AS ExR_Mean_Avg,
        MEAN(NDVI_Mean) AS NDVI_Mean_Avg,
        MEAN(gNDVI_Mean) AS gNDVI_Mean_Avg,
        MEAN(NDRE_mean) AS NDRE_Mean_Avg,
        MEAN(THRESH_mean) AS THRESH_Mean_Avg,
        MEAN("HA Mean"n) AS HA_Mean_Avg,
        MEAN("PLT COUNT"n) AS PLT_COUNT_Avg,
        MEAN(Yield) AS Yield_Avg,
        
        /* VI Variances */
        VAR(ExG_Mean) AS ExG_Mean_Var,
        VAR(ExR_Mean) AS ExR_Mean_Var,
        VAR(NDVI_Mean) AS NDVI_Mean_Var,
        VAR(gNDVI_Mean) AS gNDVI_Mean_Var,
        VAR(NDRE_mean) AS NDRE_Mean_Var,
        VAR(THRESH_mean) AS THRESH_Mean_Var,
        VAR("HA Mean"n) AS HA_Mean_Var,
        VAR("PLT COUNT"n) AS PLT_COUNT_Var,
        VAR(Yield) AS Yield_Var
        
    FROM vi_data
    GROUP BY Trial, DAS
    ORDER BY Trial, DAS;
QUIT;

/* Display trial-level statistics by DAS */
PROC PRINT DATA=trial_means_by_das (OBS=50);
    TITLE2 "Trial-Level Means and Variances by DAS (First 50 rows)";
    VAR Trial DAS N_Obs ExG_Mean_Avg NDVI_Mean_Avg gNDVI_Mean_Avg 
        NDRE_Mean_Avg HA_Mean_Avg PLT_COUNT_Avg Yield_Avg;
    FORMAT ExG_Mean_Avg NDVI_Mean_Avg gNDVI_Mean_Avg NDRE_Mean_Avg 
           HA_Mean_Avg PLT_COUNT_Avg Yield_Avg 10.4;
RUN;

/* Export trial-level means by DAS */
PROC EXPORT DATA=trial_means_by_das
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\trial_means_by_das.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 4: Trial-as-Treatment Correlations (Overall - Across All DAS)
* Using trial means as single observations (n=13 trials)
*******************************************************************************/

TITLE2 "TRIAL-AS-TREATMENT CORRELATION ANALYSIS";
TITLE3 "Using Trial-Level Means Across All Timepoints (n=13)";

PROC CORR DATA=trial_means_vars PLOTS=MATRIX(HISTOGRAM);
    VAR ExG_Mean_Avg ExG_Var_Avg
        ExR_Mean_Avg ExR_Var_Avg
        NDVI_Mean_Avg NDVI_Var_Avg
        gNDVI_Mean_Avg gNDVI_Var_Avg
        NDRE_Mean_Avg NDRE_Var_Avg
        THRESH_Mean_Avg THRESH_Var_Avg
        HA_Mean_Avg
        PLT_COUNT_Avg;
    WITH Yield_Avg;
    ODS OUTPUT PearsonCorr=trial_corr_overall;
RUN;

/* Display correlation results */
PROC PRINT DATA=trial_corr_overall;
    TITLE2 "Trial-Level Correlations with Yield (Overall)";
    VAR Variable Yield_Avg PYield_Avg;
    FORMAT PYield_Avg PVALUE6.4 Yield_Avg 8.4;
RUN;

/* Export overall trial correlations */
PROC EXPORT DATA=trial_corr_overall
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\trial_level_correlations_overall.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 5: Trial-as-Treatment Correlations BY DAS
* Separate correlation analysis for each DAS timepoint (n=13 trials per DAS)
*******************************************************************************/

/* Create macro to loop through each DAS */
%MACRO trial_corr_by_das;
    %LOCAL i das_val;
    
    %DO i = 1 %TO 7;
        %LET das_val = %SCAN(13 21 25 32 40 47 55, &i);
        
        %PUT NOTE: Processing Trial-Level Correlations for DAS=&das_val;
        
        /* Filter data for specific DAS */
        DATA temp_das_&das_val;
            SET trial_means_by_das;
            WHERE DAS = &das_val;
        RUN;
        
        /* Run correlation analysis */
        TITLE3 "Trial-Level Correlations at DAS=&das_val (n=13 trials)";
        
        PROC CORR DATA=temp_das_&das_val NOSIMPLE;
            VAR ExG_Mean_Avg ExR_Mean_Avg
                NDVI_Mean_Avg gNDVI_Mean_Avg
                NDRE_Mean_Avg THRESH_Mean_Avg
                HA_Mean_Avg PLT_COUNT_Avg;
            WITH Yield_Avg;
            ODS OUTPUT PearsonCorr=trial_corr_das&das_val;
        RUN;
        
        /* Add DAS identifier to output */
        DATA trial_corr_das&das_val;
            SET trial_corr_das&das_val;
            DAS = &das_val;
        RUN;
        
        /* Clean up */
        PROC DATASETS LIBRARY=WORK NOLIST;
            DELETE temp_das_&das_val;
        QUIT;
    %END;
%MEND trial_corr_by_das;

%trial_corr_by_das;

/* Combine all DAS-specific trial correlations */
DATA all_trial_corr_by_das;
    SET trial_corr_das13 trial_corr_das21 trial_corr_das25 
        trial_corr_das32 trial_corr_das40 trial_corr_das47 
        trial_corr_das55;
RUN;

/* Display combined results */
PROC SORT DATA=all_trial_corr_by_das;
    BY DAS Variable;
RUN;

PROC PRINT DATA=all_trial_corr_by_das;
    TITLE2 "Trial-Level Correlations with Yield by DAS";
    BY DAS;
    VAR Variable Yield_Avg PYield_Avg nYield_Avg;
    FORMAT PYield_Avg PVALUE6.4 Yield_Avg 8.4;
RUN;

/* Export DAS-specific trial correlations */
PROC EXPORT DATA=all_trial_corr_by_das
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\trial_level_correlations_by_das.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 6: Visualization - Trial-Level Correlation Trends
*******************************************************************************/

/* Create heatmap of trial-level correlations across DAS */
PROC SGPLOT DATA=all_trial_corr_by_das;
    TITLE2 "Trial-Level Correlation Trends Across DAS Timepoints";
    HEATMAP X=DAS Y=Variable / COLORRESPONSE=Yield_Avg
            COLORMODEL=(red white blue)
            X2AXIS;
    XAXIS LABEL="Days After Sowing (DAS)";
    YAXIS LABEL="Variable (Trial-Level Means)";
    GRADLEGEND / TITLE="Correlation with Yield";
RUN;

/* Line plot showing correlation strength over time for key variables */
PROC SGPLOT DATA=all_trial_corr_by_das;
    TITLE2 "Trial-Level Correlation Strength Over Time";
    WHERE Variable IN ('NDVI_Mean_Avg' 'gNDVI_Mean_Avg' 'NDRE_Mean_Avg' 
                       'HA_Mean_Avg' 'PLT_COUNT_Avg');
    SERIES X=DAS Y=Yield_Avg / GROUP=Variable MARKERS;
    XAXIS LABEL="Days After Sowing (DAS)";
    YAXIS LABEL="Correlation with Yield (Trial-Level)";
    REFLINE 0 / AXIS=Y LINEATTRS=(PATTERN=2 COLOR=gray);
RUN;

/*******************************************************************************
* STEP 7: Compare Trial-Level vs Plot-Level Correlations
* Summary table showing strongest correlations at trial level
*******************************************************************************/

/* Identify strongest correlations at trial level (overall) */
PROC SORT DATA=trial_corr_overall;
    BY DESCENDING Yield_Avg;
RUN;

DATA top_trial_correlations;
    SET trial_corr_overall;
    abs_corr = ABS(Yield_Avg);
    rank = _N_;
    IF rank <= 10;  /* Top 10 correlations */
RUN;

PROC PRINT DATA=top_trial_correlations;
    TITLE2 "Top 10 Trial-Level Correlations with Yield (Overall)";
    VAR rank Variable Yield_Avg PYield_Avg nYield_Avg abs_corr;
    FORMAT PYield_Avg PVALUE6.4 Yield_Avg abs_corr 8.4;
RUN;

/* Summary statistics for trial-level correlations by DAS */
PROC MEANS DATA=all_trial_corr_by_das N MEAN STD MIN MAX;
    TITLE2 "Summary of Trial-Level Correlation Strength by Variable";
    CLASS Variable;
    VAR Yield_Avg;
    OUTPUT OUT=trial_corr_summary 
           MEAN=Mean_Corr 
           STD=Std_Corr 
           MIN=Min_Corr 
           MAX=Max_Corr;
RUN;

PROC PRINT DATA=trial_corr_summary;
    TITLE2 "Trial-Level Correlation Summary Across All DAS";
    WHERE _TYPE_ = 1;  /* Variable level only */
    VAR Variable Mean_Corr Std_Corr Min_Corr Max_Corr _FREQ_;
    FORMAT Mean_Corr Std_Corr Min_Corr Max_Corr 8.4;
RUN;

/*******************************************************************************
* STEP 8: Statistical Comparison - Trial Means vs Variances
* Which is more predictive: mean VI values or variability within trial?
*******************************************************************************/

TITLE2 "Comparing Predictive Power: Trial Means vs Trial Variances";

/* Correlations for MEANS */
PROC CORR DATA=trial_means_vars NOSIMPLE NOPRINT;
    VAR ExG_Mean_Avg ExR_Mean_Avg NDVI_Mean_Avg gNDVI_Mean_Avg 
        NDRE_Mean_Avg THRESH_Mean_Avg HA_Mean_Avg PLT_COUNT_Avg;
    WITH Yield_Avg;
    ODS OUTPUT PearsonCorr=means_corr;
RUN;

/* Correlations for VARIANCES */
PROC CORR DATA=trial_means_vars NOSIMPLE NOPRINT;
    VAR ExG_Mean_Var ExR_Mean_Var NDVI_Mean_Var gNDVI_Mean_Var 
        NDRE_Mean_Var THRESH_Mean_Var HA_Mean_Var PLT_COUNT_Var;
    WITH Yield_Avg;
    ODS OUTPUT PearsonCorr=vars_corr;
RUN;

/* Combine and compare */
DATA means_corr;
    SET means_corr;
    Type = "Mean";
    abs_corr = ABS(Yield_Avg);
RUN;

DATA vars_corr;
    SET vars_corr;
    Type = "Variance";
    abs_corr = ABS(Yield_Avg);
RUN;

DATA means_vs_vars;
    SET means_corr vars_corr;
RUN;

PROC SORT DATA=means_vs_vars;
    BY DESCENDING abs_corr;
RUN;

PROC PRINT DATA=means_vs_vars;
    TITLE3 "Means vs Variances: Which Predicts Yield Better at Trial Level?";
    VAR Type Variable Yield_Avg PYield_Avg abs_corr;
    FORMAT PYield_Avg PVALUE6.4 Yield_Avg abs_corr 8.4;
RUN;

/* Export comparison */
PROC EXPORT DATA=means_vs_vars
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\trial_means_vs_variances_comparison.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 9: Clean up temporary datasets
*******************************************************************************/
PROC DATASETS LIBRARY=WORK NOLIST;
    DELETE trial_corr_das: temp_das_: means_corr vars_corr;
QUIT;

/* End of Program */
TITLE;
FOOTNOTE;

/*******************************************************************************
* SUMMARY OF OUTPUTS:
*
* CSV FILES CREATED:
* 1. trial_level_means_variances.csv - Overall trial means/vars (n=13)
* 2. trial_means_by_das.csv - Trial means/vars by DAS (n=13 x 7 = 91)
* 3. trial_level_correlations_overall.csv - Correlations using overall means
* 4. trial_level_correlations_by_das.csv - Correlations at each DAS
* 5. trial_means_vs_variances_comparison.csv - Means vs variances comparison
*
* KEY ANALYSES:
* - Trial-level summary statistics (13 trials as experimental units)
* - Correlations treating each trial as single observation (n=13)
* - Separate correlations for each DAS timepoint (n=13 per DAS)
* - Comparison of means vs variances as predictors
* - Visualization of correlation trends over time
*
* INTERPRETATION:
* - This analysis treats each trial as a treatment/experimental unit
* - Each correlation uses n=13 data points (one per trial)
* - More appropriate for trial-level effects and comparisons
* - Lower sample size but removes within-trial variation
*
* NOTE: This complements the plot-level analysis in the main code
*******************************************************************************/
