/*******************************************************************************
* Program: Multitemporal Vegetative Index Correlation Analysis (CORRECTED)
* Purpose: Calculate correlations between VIs, HA, Plant Count, Threshold 
*          and Yield at each DAS timepoint - wholistically and by trial
* Dataset: 2025_Multitemporal_VI_data___yield.csv
* 
* CORRECTION: Fixed variable renaming issue with HA_Mean and PLT_COUNT
*******************************************************************************/
ods graphics on;
 dm 'log; clear;';

/* Set options for output and display */
OPTIONS NODATE NONUMBER PS=60 LS=132;
TITLE "Multitemporal VI Correlation Analysis with Yield";

/*******************************************************************************
* STEP 1: Import the CSV dataset
*******************************************************************************/
PROC IMPORT DATAFILE="D:\svrec HA data\2025 Multitemporal VI data + yield.csv"
    OUT=vi_data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Display dataset structure and first few observations */
PROC CONTENTS DATA=vi_data; 
RUN;

PROC PRINT DATA=vi_data (OBS=10);
    TITLE2 "First 10 Observations of Dataset";
RUN;

/*******************************************************************************
* STEP 2: Create a list of unique DAS values for iteration
*******************************************************************************/
PROC SORT DATA=vi_data OUT=das_list NODUPKEY;
    BY DAS;
RUN;

/* Create macro variable with list of all unique DAS values */
PROC SQL NOPRINT;
    SELECT DISTINCT DAS INTO :das_list SEPARATED BY ' '
    FROM vi_data
    ORDER BY DAS;
    
    SELECT COUNT(DISTINCT DAS) INTO :n_das
    FROM vi_data;
QUIT;

%PUT NOTE: Number of DAS timepoints = &n_das;
%PUT NOTE: DAS values = &das_list;

/*******************************************************************************
* STEP 3: Create a list of unique Trial values
*******************************************************************************/
PROC SQL NOPRINT;
    SELECT DISTINCT Trial INTO :trial_list SEPARATED BY ' '
    FROM vi_data
    ORDER BY Trial;
    
    SELECT COUNT(DISTINCT Trial) INTO :n_trials
    FROM vi_data;
QUIT;

%PUT NOTE: Number of Trials = &n_trials;
%PUT NOTE: Trial values = &trial_list;

/*******************************************************************************
* STEP 4: Define macro for correlation analysis
* This macro calculates Pearson correlations between all VI variables and Yield
* 
* CORRECTED: Fixed the variable renaming and KEEP statement order
*******************************************************************************/
%MACRO corr_analysis(input_data=, das_value=, trial_value=, output_suffix=);
    
    /* Filter data for specific DAS and optionally Trial */
    DATA temp_data;
        SET &input_data;
        
        /* Filter by DAS */
        %IF &das_value NE %THEN %DO;
            WHERE DAS = &das_value
            %IF &trial_value NE %THEN %DO;
                AND Trial = &trial_value
            %END;
            ;
        %END;
        
        /* Keep only relevant variables - use ORIGINAL names with spaces */
        KEEP Trial DAS 
             ExG_Mean ExG_Var 
             ExR_Mean ExR_Var 
             NDVI_Mean NDVI_Var 
             gNDVI_Mean gNDVI_Var 
             NDRE_mean NDRE_Var 
             THRESH_mean THRESH_Var 
             'HA Mean'n
             'PLT COUNT'n
             Yield;
             
        /* Rename variables with spaces for easier processing */
        /* RENAME happens last, so reference original names above */
        RENAME 'HA Mean'n = HA_Mean
               'PLT COUNT'n = PLT_COUNT;
    RUN;
    
    /* Calculate Pearson correlations with Yield */
    %IF &trial_value NE %THEN %DO;
        TITLE2 "Correlations with Yield - Trial &trial_value, DAS &das_value";
    %END;
    %ELSE %DO;
        TITLE2 "Correlations with Yield - All Trials, DAS &das_value";
    %END;
    
    PROC CORR DATA=temp_data NOSIMPLE 
              PLOTS=MATRIX(HISTOGRAM NVAR=ALL);
        VAR ExG_Mean ExG_Var 
            ExR_Mean ExR_Var 
            NDVI_Mean NDVI_Var 
            gNDVI_Mean gNDVI_Var 
            NDRE_mean NDRE_Var 
            THRESH_mean THRESH_Var 
            HA_Mean 
            PLT_COUNT;
        WITH Yield;
        ODS OUTPUT PearsonCorr=corr_&output_suffix;
    RUN;
    
    /* Add identifying information to correlation output */
    DATA corr_&output_suffix;
        SET corr_&output_suffix;
        LENGTH Analysis_Type $20 Trial_ID 8 DAS_Value 8;
        %IF &trial_value NE %THEN %DO;
            Analysis_Type = "By Trial";
            Trial_ID = &trial_value;
        %END;
        %ELSE %DO;
            Analysis_Type = "Wholistic";
            Trial_ID = .;
        %END;
        DAS_Value = &das_value;
    RUN;
    
    /* Clean up temporary dataset */
    PROC DATASETS LIBRARY=WORK NOLIST;
        DELETE temp_data;
    QUIT;
    
%MEND corr_analysis;

/*******************************************************************************
* STEP 5: Run Wholistic Correlations (All Trials Combined) for Each DAS
*******************************************************************************/
%PUT NOTE: Starting Wholistic Correlation Analysis;

/* Loop through each DAS value */
%MACRO run_wholistic;
    %LOCAL i das_val;
    
    %DO i = 1 %TO &n_das;
        %LET das_val = %SCAN(&das_list, &i);
        
        %PUT NOTE: Processing Wholistic Analysis for DAS=&das_val;
        
        /* Run correlation analysis for this DAS across all trials */
        %corr_analysis(input_data=vi_data, 
                      das_value=&das_val, 
                      trial_value=,
                      output_suffix=wholistic_das&das_val);
    %END;
%MEND run_wholistic;

%run_wholistic;

/*******************************************************************************
* STEP 6: Run Trial-Specific Correlations for Each DAS
*******************************************************************************/
%PUT NOTE: Starting Trial-Specific Correlation Analysis;

/* Nested loop through each Trial and DAS combination */
%MACRO run_by_trial;
    %LOCAL i j trial_val das_val;
    
    %DO i = 1 %TO &n_trials;
        %LET trial_val = %SCAN(&trial_list, &i);
        
        %DO j = 1 %TO &n_das;
            %LET das_val = %SCAN(&das_list, &j);
            
            %PUT NOTE: Processing Trial=&trial_val, DAS=&das_val;
            
            /* Run correlation analysis for this Trial-DAS combination */
            %corr_analysis(input_data=vi_data, 
                          das_value=&das_val, 
                          trial_value=&trial_val,
                          output_suffix=trial&trial_val._das&das_val);
        %END;
    %END;
%MEND run_by_trial;

%run_by_trial;

/*******************************************************************************
* STEP 7: Combine All Correlation Results into Summary Tables
*******************************************************************************/

/* Combine all wholistic correlations */
DATA all_wholistic_corr;
    SET corr_wholistic_das:;
RUN;

/* Combine all trial-specific correlations */
DATA all_trial_corr;
    SET corr_trial:;
RUN;

/* Combine everything into one master table */
DATA all_correlations;
    SET all_wholistic_corr all_trial_corr;
RUN;

/* Sort and display summary */
PROC SORT DATA=all_correlations;
    BY DAS_Value Analysis_Type Trial_ID Variable;
RUN;

PROC PRINT DATA=all_correlations;
    TITLE2 "Complete Correlation Summary - All DAS Timepoints";
    VAR Analysis_Type Trial_ID DAS_Value Variable Yield PYield;
    FORMAT PYield PVALUE6.4;
RUN;

/*******************************************************************************
* STEP 8: Create Summary Reports by DAS
*******************************************************************************/

/* Wholistic correlation summary across all DAS */
PROC PRINT DATA=all_wholistic_corr;
    TITLE2 "Wholistic Correlations Across All Trials by DAS";
    BY DAS_Value;
    VAR Variable Yield PYield nYield;
    FORMAT PYield PVALUE6.4;
RUN;

/* Trial-specific correlation summary */
PROC PRINT DATA=all_trial_corr;
    TITLE2 "Trial-Specific Correlations by DAS";
    BY DAS_Value Trial_ID;
    VAR Variable Yield PYield nYield;
    FORMAT PYield PVALUE6.4;
RUN;

/*******************************************************************************
* STEP 9: Identify Strongest Correlations at Each Timepoint
*******************************************************************************/

/* Find top correlations for wholistic analysis */
PROC SORT DATA=all_wholistic_corr;
    BY DAS_Value DESCENDING Yield;
RUN;

DATA top_wholistic_corr;
    SET all_wholistic_corr;
    BY DAS_Value;
    
    /* Keep only top 5 correlations per DAS */
    IF FIRST.DAS_Value THEN rank = 0;
    rank + 1;
    
    IF rank <= 5;
    
    /* Create absolute correlation for ranking */
    abs_corr = ABS(Yield);
RUN;

PROC PRINT DATA=top_wholistic_corr;
    TITLE2 "Top 5 Correlations with Yield by DAS (Wholistic)";
    BY DAS_Value;
    VAR Variable Yield PYield nYield abs_corr;
    FORMAT PYield PVALUE6.4 Yield abs_corr 8.4;
RUN;

/*******************************************************************************
* STEP 10: Export Results to CSV Files
*******************************************************************************/

/* Export wholistic correlations */
PROC EXPORT DATA=all_wholistic_corr
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\alltrials.csv"
    DBMS=CSV
    REPLACE;
RUN;

/* Export trial-specific correlations */
PROC EXPORT DATA=all_trial_corr
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\bytrialcorrelations.csv"
    DBMS=CSV
    REPLACE;
RUN;

/* Export combined results */
PROC EXPORT DATA=all_correlations
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\wholistictrialcorrelations.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 11: Create Visualization - Correlation Heatmap by DAS
*******************************************************************************/

/* Prepare data for heatmap visualization */
PROC SORT DATA=all_wholistic_corr;
    BY Variable DAS_Value;
RUN;

/* Create heatmap showing correlation trends across time */
PROC SGPLOT DATA=all_wholistic_corr;
    TITLE2 "Correlation Trends with Yield Across DAS Timepoints (Wholistic)";
    HEATMAP X=DAS_Value Y=Variable / COLORRESPONSE=Yield
            COLORMODEL=(red white blue)
            X2AXIS;
    XAXIS LABEL="Days After Sowing (DAS)";
    YAXIS LABEL="Variable";
    GRADLEGEND / TITLE="Correlation with Yield";
RUN;

/* Create line plot showing how key correlations change over time */
PROC SGPLOT DATA=all_wholistic_corr;
    TITLE2 "Correlation Strength Over Time (Wholistic Analysis)";
    WHERE Variable IN ('NDVI_Mean' 'gNDVI_Mean' 'NDRE_mean' 'HA_Mean' 'PLT_COUNT');
    SERIES X=DAS_Value Y=Yield / GROUP=Variable MARKERS;
    XAXIS LABEL="Days After Sowing (DAS)";
    YAXIS LABEL="Correlation with Yield";
    REFLINE 0 / AXIS=Y LINEATTRS=(PATTERN=2 COLOR=gray);
RUN;

/*******************************************************************************
* STEP 12: Statistical Summary by Trial
*******************************************************************************/

/* Calculate mean correlations by trial across all DAS */
PROC MEANS DATA=all_trial_corr N MEAN STD MIN MAX;
    TITLE2 "Summary Statistics of Correlations by Trial";
    CLASS Trial_ID Variable;
    VAR Yield;
    OUTPUT OUT=trial_summary MEAN=Mean_Corr STD=Std_Corr;
RUN;

PROC PRINT DATA=trial_summary;
    TITLE2 "Mean Correlation with Yield by Trial and Variable";
    WHERE _TYPE_ = 3;  /* Both Trial and Variable specified */
    VAR Trial_ID Variable Mean_Corr Std_Corr _FREQ_;
RUN;

/*******************************************************************************
* STEP 13: Clean up temporary datasets
*******************************************************************************/
PROC DATASETS LIBRARY=WORK NOLIST;
    DELETE corr_: das_list;
QUIT;

/* End of Program */
TITLE;
FOOTNOTE;

/*******************************************************************************
* NOTES FOR USERS:
* 
* CORRECTION APPLIED:
* - Fixed variable renaming issue where HA_Mean and PLT_COUNT were causing errors
* - The KEEP statement now uses original variable names ('HA Mean'n, 'PLT COUNT'n)
* - RENAME statement executes last, converting them to HA_Mean and PLT_COUNT
* 
* FILE PATHS CONFIGURED:
* - Input: D:\svrec HA data\2025 Multitemporal VI data + yield.csv
* - Output directory: C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\
*   
* VARIABLES ANALYZED:
* - Vegetation Indices: ExG (Mean/Var), ExR (Mean/Var), NDVI (Mean/Var),
*                       gNDVI (Mean/Var), NDRE (Mean/Var)
* - Threshold: THRESH (Mean/Var)
* - Area: HA_Mean (from 'HA Mean')
* - Plant Count: PLT_COUNT (from 'PLT COUNT')
* - Response: Yield
*
* OUTPUTS GENERATED:
* - alltrials.csv: Wholistic correlations (all trials combined) by DAS
* - bytrialcorrelations.csv: Trial-specific correlations by DAS
* - wholistictrialcorrelations.csv: Combined results (wholistic + by trial)
* - Correlation tables by DAS (wholistic and by trial)
* - Summary statistics
* - Visualization plots (heatmap and line charts)
*
* DATASET STRUCTURE:
* - 7 DAS timepoints: 13, 21, 25, 32, 40, 47, 55
* - 13 Trials: 2501-2514 (excluding 2505)
* - 9912 total observations
*
* TO RUN:
* - Ensure file paths are accessible
* - Submit entire program or run sections sequentially
* - Check log for any warnings or errors
*******************************************************************************/
