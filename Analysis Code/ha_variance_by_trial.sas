/*******************************************************************************
* Program: Harvestable Area Variance Analysis by Trial
* Purpose: Compare how much variance HA explains in yield across trials
*          Calculate cumulative contribution of HA to yield
*******************************************************************************/

OPTIONS NODATE NONUMBER PS=60 LS=132;
TITLE "Harvestable Area Contribution to Yield Variance by Trial";

/*******************************************************************************
* STEP 1: Import Data
*******************************************************************************/
PROC IMPORT DATAFILE="D:\svrec HA data\Multitemporal VI data HA + yield + names.csv"
    OUT=vi_data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

DATA analysis_data;
    SET vi_data;
    WHERE DAS = 13;  /* Use first timepoint */
    
    Genotype = VarietyName;
    Yield = Yield;
    HA = 'HA Mean'n;
    PLT_COUNT = 'PLT COUNT'n;
    
    KEEP Trial Genotype Row Column Yield HA PLT_COUNT;
RUN;

/* Remove missing values */
DATA analysis_data;
    SET analysis_data;
    WHERE Yield IS NOT MISSING AND HA IS NOT MISSING AND HA > 0;
RUN;

/*******************************************************************************
* STEP 2: Trial-Level Descriptive Statistics
*******************************************************************************/

PROC SORT DATA=analysis_data;
    BY Trial;
RUN;

PROC MEANS DATA=analysis_data NOPRINT;
    BY Trial;
    VAR Yield HA;
    OUTPUT OUT=trial_summary
           N=N_obs N_HA
           MEAN=Mean_Yield Mean_HA
           STD=SD_Yield SD_HA
           MIN=Min_Yield Min_HA
           MAX=Max_Yield Max_HA
           CV=CV_Yield CV_HA;
RUN;

PROC PRINT DATA=trial_summary;
    TITLE2 "Trial-Level Summary Statistics";
    VAR Trial N_obs Mean_Yield SD_Yield CV_Yield Mean_HA SD_HA CV_HA;
    FORMAT Mean_Yield SD_Yield Mean_HA SD_HA 10.2 CV_Yield CV_HA 6.2;
RUN;

/*******************************************************************************
* STEP 3: Correlation Between Yield and HA by Trial
*******************************************************************************/

PROC CORR DATA=analysis_data NOPRINT OUTP=corr_by_trial;
    BY Trial;
    VAR Yield HA;
RUN;

DATA trial_correlations;
    SET corr_by_trial;
    WHERE _TYPE_ = 'CORR' AND _NAME_ = 'Yield';
    
    Correlation = HA;
    R_squared = Correlation**2;
    
    KEEP Trial Correlation R_squared;
RUN;

PROC PRINT DATA=trial_correlations;
    TITLE2 "Correlation Between Yield and HA by Trial";
    VAR Trial Correlation R_squared;
    FORMAT Correlation 6.4 R_squared PERCENT8.2;
RUN;

/*******************************************************************************
* STEP 4: Variance Decomposition by Trial
*******************************************************************************/

%MACRO trial_variance_decomp(trial_id=);
    
    TITLE2 "Trial &trial_id: Variance Decomposition";
    
    /* Get data for this trial */
    DATA trial_data;
        SET analysis_data;
        WHERE Trial = &trial_id;
    RUN;
    
    /* Check sample size */
    PROC SQL NOPRINT;
        SELECT COUNT(*) INTO :n_obs TRIMMED
        FROM trial_data;
        
        SELECT COUNT(DISTINCT Genotype) INTO :n_geno TRIMMED
        FROM trial_data;
    QUIT;
    
    %IF &n_geno < 3 OR &n_obs < 15 %THEN %DO;
        %PUT WARNING: Trial &trial_id has insufficient data (n_geno=&n_geno, n_obs=&n_obs);
        
        DATA variance_trial_&trial_id;
            LENGTH Trial 8 Model $20;
            Trial = &trial_id;
            Model = "INSUFFICIENT_DATA";
            N_obs = &n_obs;
            N_geno = &n_geno;
            Var_Genotype = .;
            Var_Residual = .;
            HA_Coefficient = .;
            HA_Pvalue = .;
            Variance_Explained = .;
            Pct_Var_Explained = .;
            OUTPUT;
        RUN;
    %END;
    %ELSE %DO;
        
        /* Model 0: Baseline (Genotype only) */
        PROC MIXED DATA=trial_data COVTEST METHOD=REML;
            CLASS Genotype;
            MODEL Yield = / SOLUTION;
            RANDOM Genotype;
            ODS OUTPUT CovParms=cov_model0_&trial_id;
        RUN;
        
        DATA variance_model0_&trial_id;
            SET cov_model0_&trial_id END=last;
            RETAIN var_g var_e;
            
            IF CovParm = 'Genotype' THEN var_g = Estimate;
            IF CovParm = 'Residual' THEN var_e = Estimate;
            
            IF last THEN DO;
                Trial = &trial_id;
                Model = "0_Baseline";
                N_obs = &n_obs;
                N_geno = &n_geno;
                Var_Genotype = var_g;
                Var_Residual = var_e;
                Var_Total = var_g + var_e;
                HA_Coefficient = .;
                HA_Pvalue = .;
                OUTPUT;
            END;
            
            KEEP Trial Model N_obs N_geno Var_Genotype Var_Residual Var_Total
                 HA_Coefficient HA_Pvalue;
        RUN;
        
        /* Model 1: Add HA */
        PROC MIXED DATA=trial_data COVTEST METHOD=REML;
            CLASS Genotype;
            MODEL Yield = HA / SOLUTION;
            RANDOM Genotype;
            ODS OUTPUT CovParms=cov_model1_&trial_id SolutionF=fixed_model1_&trial_id;
        RUN;
        
        /* Extract HA coefficient and p-value */
        DATA ha_effect_&trial_id;
            SET fixed_model1_&trial_id;
            WHERE Effect = 'HA';
            
            HA_Coefficient = Estimate;
            HA_Pvalue = Probt;
            
            KEEP HA_Coefficient HA_Pvalue;
        RUN;
        
        DATA variance_model1_&trial_id;
            SET cov_model1_&trial_id END=last;
            RETAIN var_g var_e;
            
            IF CovParm = 'Genotype' THEN var_g = Estimate;
            IF CovParm = 'Residual' THEN var_e = Estimate;
            
            IF last THEN DO;
                IF _N_ = 1 THEN SET ha_effect_&trial_id;
                
                Trial = &trial_id;
                Model = "1_HA";
                N_obs = &n_obs;
                N_geno = &n_geno;
                Var_Genotype = var_g;
                Var_Residual = var_e;
                Var_Total = var_g + var_e;
                OUTPUT;
            END;
            
            KEEP Trial Model N_obs N_geno Var_Genotype Var_Residual Var_Total
                 HA_Coefficient HA_Pvalue;
        RUN;
        
        /* Combine models and calculate variance explained */
        DATA variance_trial_&trial_id;
            SET variance_model0_&trial_id variance_model1_&trial_id;
            BY Trial Model;
            
            RETAIN baseline_residual;
            
            IF Model = "0_Baseline" THEN baseline_residual = Var_Residual;
            
            IF Model = "1_HA" THEN DO;
                Variance_Explained = baseline_residual - Var_Residual;
                Pct_Var_Explained = (Variance_Explained / baseline_residual) * 100;
            END;
            ELSE DO;
                Variance_Explained = 0;
                Pct_Var_Explained = 0;
            END;
        RUN;
        
        /* Cleanup */
        PROC DATASETS LIBRARY=WORK NOLIST;
            DELETE cov_model0_&trial_id cov_model1_&trial_id 
                   variance_model0_&trial_id variance_model1_&trial_id
                   fixed_model1_&trial_id ha_effect_&trial_id trial_data;
        QUIT;
        
    %END;
    
%MEND trial_variance_decomp;

/* Get list of trials */
PROC SQL NOPRINT;
    SELECT DISTINCT Trial INTO :trial_list SEPARATED BY ' '
    FROM analysis_data
    ORDER BY Trial;
    
    SELECT COUNT(DISTINCT Trial) INTO :n_trials TRIMMED
    FROM analysis_data;
QUIT;

%PUT NOTE: Found &n_trials trials: &trial_list;

/* Run analysis for each trial */
%DO i = 1 %TO &n_trials;
    %LET trial_id = %SCAN(&trial_list, &i);
    %trial_variance_decomp(trial_id=&trial_id);
%END;

/* Combine all trial results */
DATA all_trial_variance;
    SET variance_trial_:;
RUN;

/* Cleanup individual trial datasets */
PROC DATASETS LIBRARY=WORK NOLIST;
    DELETE variance_trial_:;
QUIT;

/*******************************************************************************
* STEP 5: Summary Tables
*******************************************************************************/

/* Baseline variance by trial */
DATA baseline_variance;
    SET all_trial_variance;
    WHERE Model = "0_Baseline";
RUN;

PROC PRINT DATA=baseline_variance NOOBS;
    TITLE2 "Baseline Variance Components by Trial (No HA)";
    VAR Trial N_obs N_geno Var_Genotype Var_Residual Var_Total;
    FORMAT Var_Genotype Var_Residual Var_Total 12.2;
RUN;

/* HA model results by trial */
DATA ha_model_results;
    SET all_trial_variance;
    WHERE Model = "1_HA";
RUN;

PROC PRINT DATA=ha_model_results NOOBS;
    TITLE2 "HA Model Results by Trial";
    VAR Trial N_obs N_geno HA_Coefficient HA_Pvalue Var_Residual 
        Variance_Explained Pct_Var_Explained;
    FORMAT HA_Coefficient 10.2 HA_Pvalue PVALUE6.4 
           Var_Residual Variance_Explained 12.2
           Pct_Var_Explained 6.2;
RUN;

/* Merge with correlations */
DATA trial_comparison;
    MERGE ha_model_results (IN=a)
          trial_correlations (IN=b);
    BY Trial;
    IF a;
RUN;

PROC PRINT DATA=trial_comparison NOOBS;
    TITLE2 "Complete Comparison: HA Effect Across Trials";
    VAR Trial N_obs N_geno Correlation R_squared HA_Coefficient HA_Pvalue 
        Pct_Var_Explained;
    FORMAT Correlation 6.4 R_squared Pct_Var_Explained PERCENT8.2
           HA_Coefficient 10.2 HA_Pvalue PVALUE6.4;
RUN;

/*******************************************************************************
* STEP 6: Summary Statistics Across Trials
*******************************************************************************/

PROC MEANS DATA=ha_model_results N MEAN STD MIN MAX;
    TITLE2 "Summary of HA Contribution Across All Trials";
    VAR Pct_Var_Explained HA_Coefficient Variance_Explained;
    OUTPUT OUT=overall_summary
           N=N_trials
           MEAN=Mean_Pct Mean_Coef Mean_Var
           STD=SD_Pct SD_Coef SD_Var
           MIN=Min_Pct Min_Coef Min_Var
           MAX=Max_Pct Max_Coef Max_Var;
RUN;

PROC PRINT DATA=overall_summary NOOBS;
    TITLE2 "Overall Summary Statistics";
    VAR N_trials Mean_Pct SD_Pct Min_Pct Max_Pct;
    FORMAT Mean_Pct SD_Pct Min_Pct Max_Pct 6.2;
RUN;

/*******************************************************************************
* STEP 7: Cumulative Analysis - Yield --> HA Relationship
*******************************************************************************/

/* Calculate cumulative yield and HA by trial */
PROC SORT DATA=analysis_data;
    BY Trial Yield;
RUN;

DATA cumulative_by_trial;
    SET analysis_data;
    BY Trial;
    
    RETAIN cum_yield cum_ha n_cumulative;
    
    IF FIRST.Trial THEN DO;
        cum_yield = 0;
        cum_ha = 0;
        n_cumulative = 0;
    END;
    
    n_cumulative + 1;
    cum_yield + Yield;
    cum_ha + HA;
    
    mean_yield_cumulative = cum_yield / n_cumulative;
    mean_ha_cumulative = cum_ha / n_cumulative;
    
    /* Calculate difference between yield rank and HA rank */
    yield_rank = n_cumulative;
RUN;

/* For each trial, calculate the difference between sorted yield and sorted HA */
PROC SORT DATA=analysis_data OUT=sorted_by_yield;
    BY Trial Yield;
RUN;

DATA sorted_by_yield;
    SET sorted_by_yield;
    BY Trial;
    
    RETAIN yield_rank;
    
    IF FIRST.Trial THEN yield_rank = 0;
    yield_rank + 1;
RUN;

PROC SORT DATA=analysis_data OUT=sorted_by_ha;
    BY Trial HA;
RUN;

DATA sorted_by_ha;
    SET sorted_by_ha;
    BY Trial;
    
    RETAIN ha_rank;
    
    IF FIRST.Trial THEN ha_rank = 0;
    ha_rank + 1;
RUN;

/* Merge to get both ranks */
PROC SQL;
    CREATE TABLE rank_comparison AS
    SELECT 
        a.Trial,
        a.Genotype,
        a.Row,
        a.Column,
        a.Yield,
        a.HA,
        y.yield_rank,
        h.ha_rank,
        ABS(y.yield_rank - h.ha_rank) AS rank_difference
    FROM analysis_data AS a
    LEFT JOIN sorted_by_yield AS y
        ON a.Trial = y.Trial 
        AND a.Genotype = y.Genotype
        AND a.Row = y.Row
        AND a.Column = y.Column
    LEFT JOIN sorted_by_ha AS h
        ON a.Trial = h.Trial 
        AND a.Genotype = h.Genotype
        AND a.Row = h.Row
        AND a.Column = h.Column;
QUIT;

/* Summarize rank differences by trial */
PROC MEANS DATA=rank_comparison NOPRINT;
    BY Trial;
    VAR rank_difference;
    OUTPUT OUT=rank_diff_summary
           MEAN=Mean_Rank_Diff
           STD=SD_Rank_Diff
           MAX=Max_Rank_Diff;
RUN;

PROC PRINT DATA=rank_diff_summary;
    TITLE2 "Cumulative Rank Difference: Yield vs HA by Trial";
    TITLE3 "Average absolute difference in ranking position";
    VAR Trial Mean_Rank_Diff SD_Rank_Diff Max_Rank_Diff;
    FORMAT Mean_Rank_Diff SD_Rank_Diff Max_Rank_Diff 8.2;
RUN;

/*******************************************************************************
* STEP 8: Visualizations
*******************************************************************************/

/* Variance explained by trial */
PROC SGPLOT DATA=ha_model_results;
    TITLE2 "Percentage of Variance Explained by HA Across Trials";
    VBAR Trial / RESPONSE=Pct_Var_Explained FILLATTRS=(COLOR=blue);
    YAXIS LABEL="% Residual Variance Explained" MIN=0 MAX=100;
    XAXIS LABEL="Trial";
    REFLINE 50 / AXIS=Y LINEATTRS=(PATTERN=2 COLOR=red) LABEL="50%";
RUN;

/* HA coefficient by trial */
PROC SGPLOT DATA=ha_model_results;
    TITLE2 "HA Coefficient (Effect Size) by Trial";
    VBAR Trial / RESPONSE=HA_Coefficient FILLATTRS=(COLOR=green);
    YAXIS LABEL="HA Coefficient (kg/HA unit)";
    XAXIS LABEL="Trial";
    REFLINE 0 / AXIS=Y LINEATTRS=(PATTERN=1 COLOR=black);
RUN;

/* Scatter: R² vs Variance Explained */
PROC SGPLOT DATA=trial_comparison;
    TITLE2 "Relationship: R² vs % Variance Explained";
    SCATTER X=R_squared Y=Pct_Var_Explained / MARKERATTRS=(SIZE=12 SYMBOL=circlefilled);
    XAXIS LABEL="R² (Correlation Squared)" VALUES=(0 TO 1 BY 0.1) VALUEFORMAT=PERCENT8.0;
    YAXIS LABEL="% Variance Explained by HA" MIN=0 MAX=100;
    REFLINE 50 / AXIS=Y LINEATTRS=(PATTERN=2 COLOR=red);
RUN;

/* Distribution of variance explained */
PROC SGPLOT DATA=ha_model_results;
    TITLE2 "Distribution of Variance Explained Across Trials";
    HISTOGRAM Pct_Var_Explained / BINWIDTH=5;
    DENSITY Pct_Var_Explained;
    XAXIS LABEL="% Variance Explained by HA" MIN=0 MAX=100;
    YAXIS LABEL="Frequency";
RUN;

/* Yield vs HA scatter by trial (faceted) */
PROC SGPANEL DATA=analysis_data;
    TITLE2 "Yield vs HA Relationship by Trial";
    PANELBY Trial / ROWS=4 COLS=4;
    SCATTER X=HA Y=Yield / MARKERATTRS=(SIZE=5);
    REG X=HA Y=Yield / LINEATTRS=(COLOR=red THICKNESS=2);
    ROWAXIS LABEL="Yield (kg/ha)";
    COLAXIS LABEL="Harvestable Area";
RUN;

/*******************************************************************************
* STEP 9: Export Results
*******************************************************************************/

PROC EXPORT DATA=trial_comparison
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\ha_variance_by_trial.csv"
    DBMS=CSV
    REPLACE;
RUN;

PROC EXPORT DATA=rank_diff_summary
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\ha_yield_rank_differences.csv"
    DBMS=CSV
    REPLACE;
RUN;

PROC EXPORT DATA=all_trial_variance
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\variance_components_all_trials.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* INTERPRETATION GUIDE:
*
* KEY OUTPUTS:
*
* 1. VARIANCE EXPLAINED (Pct_Var_Explained):
*    - Shows how much of the residual variance in yield is explained by HA
*    - High values (>50%): Yield is largely determined by harvestable area
*    - Low values (<30%): Other factors (genetics, environment) dominate
*    - Interpretation: "In Trial X, HA accounts for Y% of yield variation"
*
* 2. HA COEFFICIENT:
*    - Effect size: How many kg of yield per unit increase in HA
*    - Positive values expected (more area → more yield)
*    - Magnitude varies by trial (environmental effects)
*    - Interpretation: "Each 0.1 increase in HA produces X kg more yield"
*
* 3. CORRELATION vs R²:
*    - Correlation: Linear association strength (-1 to 1)
*    - R²: Proportion of variance explained (0 to 1)
*    - R² ≈ Pct_Var_Explained (should be very similar)
*    - Differences indicate non-linearity or model complexity
*
* 4. RANK DIFFERENCES:
*    - Mean_Rank_Diff: Average mismatch between yield rank and HA rank
*    - Low values (<10): Yield and HA rankings are nearly identical
*    - High values (>30): Substantial yield differences independent of HA
*    - Interpretation: "Plots ranked very differently by yield vs HA"
*
* 5. VARIANCE COMPONENTS:
*    - Var_Genotype: Genetic differences in yield (after accounting for HA)
*    - Var_Residual: Unexplained variation (measurement error + other factors)
*    - Compare Model 0 vs Model 1 to see HA impact
*
* CROSS-TRIAL COMPARISON:
* - Consistent high % explained → HA is universally important
* - Variable % explained → HA importance depends on environment
* - Trials with low % explained → Look for other limiting factors
*
* CUMULATIVE INTERPRETATION:
* - If high-yield plots also have high HA → Yield IS area
* - If high-yield plots have low HA → Yield per unit area matters more
*******************************************************************************/

TITLE;
FOOTNOTE;
