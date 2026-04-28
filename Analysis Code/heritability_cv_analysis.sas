/*******************************************************************************
* Program: Heritability and CV Analysis for Yield Traits
* Purpose: 
*   1. Calculate broad-sense heritability (H²) for all yield types
*   2. Calculate Coefficient of Variation (CV) - phenotypic and genotypic
*   3. Provide estimates both OVERALL and PER-TRIAL
*   4. Analyze: Yield, HACorrectedYield, HACorrected85Yield, Perplantyield
*
* Dataset: 2025_Multitemporal_VI_data___yield.csv
*
* Methods:
*   - PROC MIXED for variance component estimation
*   - Heritability = σ²g / (σ²g + σ²e)
*   - CV_phenotypic = (√σ²p / mean) × 100
*   - CV_genotypic = (√σ²g / mean) × 100
*******************************************************************************/

/* Set options for output and display */
OPTIONS NODATE NONUMBER PS=60 LS=132;
TITLE "Heritability and CV Analysis for Yield Traits";

/*******************************************************************************
* STEP 1: Import the CSV dataset
*******************************************************************************/
PROC IMPORT DATAFILE="D:\svrec HA data\2025 Multitemporal VI data + yield.csv"
    OUT=vi_data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/* Check for genotype/variety information */
PROC CONTENTS DATA=vi_data;
    TITLE2 "Dataset Structure";
RUN;

PROC PRINT DATA=vi_data (OBS=10);
    TITLE2 "First 10 Observations";
RUN;

/*******************************************************************************
* STEP 2: Data Preparation
* Identify genotype/variety column and create factors
*******************************************************************************/

/* Check unique values in key columns */
PROC SQL;
    SELECT COUNT(DISTINCT Trial) AS N_Trials,
           COUNT(DISTINCT Row) AS N_Rows,
           COUNT(DISTINCT Column) AS N_Columns,
           COUNT(DISTINCT Combocode) AS N_Combocodes,
           COUNT(*) AS Total_Obs
    FROM vi_data;
QUIT;

/* Create a working dataset with cleaner variable names */
DATA yield_data;
    SET vi_data;
    
    /* Rename yield variables for easier handling */
    Yield_Raw = Yield;
    Yield_HA100 = HACorrectedYield;
    Yield_HA85 = HACorrected85Yield;
    Yield_PerPlant = Perplantyield;
    
    /* Create genotype identifier from Combocode or MasonPlot */
    Genotype = Combocode;  /* Adjust this if you have variety info */
    
    /* Rename spatial variables */
    RENAME 'HA Mean'n = HA_Mean
           'PLT COUNT'n = PLT_COUNT;
    
    /* Keep relevant variables */
    KEEP Trial Row Column Genotype DAS
         Yield_Raw Yield_HA100 Yield_HA85 Yield_PerPlant
         'HA Mean'n 'PLT COUNT'n;
RUN;

/* Summary of data structure */
PROC FREQ DATA=yield_data;
    TABLES Trial DAS / NOCUM;
    TITLE2 "Distribution of Trials and DAS";
RUN;

/*******************************************************************************
* STEP 3: Overall Descriptive Statistics for All Yield Types
*******************************************************************************/

PROC MEANS DATA=yield_data N MEAN STD MIN MAX CV;
    TITLE2 "Overall Descriptive Statistics for Yield Traits";
    VAR Yield_Raw Yield_HA100 Yield_HA85 Yield_PerPlant;
    OUTPUT OUT=overall_stats
           N=N_Raw N_HA100 N_HA85 N_PerPlant
           MEAN=Mean_Raw Mean_HA100 Mean_HA85 Mean_PerPlant
           STD=Std_Raw Std_HA100 Std_HA85 Std_PerPlant
           CV=CV_Raw CV_HA100 CV_HA85 CV_PerPlant;
RUN;

/* Descriptive statistics by trial */
PROC MEANS DATA=yield_data N MEAN STD MIN MAX CV NOPRINT;
    BY Trial;
    VAR Yield_Raw Yield_HA100 Yield_HA85 Yield_PerPlant;
    OUTPUT OUT=trial_stats
           N=N_Raw N_HA100 N_HA85 N_PerPlant
           MEAN=Mean_Raw Mean_HA100 Mean_HA85 Mean_PerPlant
           STD=Std_Raw Std_HA100 Std_HA85 Std_PerPlant
           CV=CV_Raw CV_HA100 CV_HA85 CV_PerPlant;
RUN;

PROC PRINT DATA=trial_stats;
    TITLE2 "Descriptive Statistics by Trial";
    VAR Trial Mean_Raw CV_Raw Mean_HA100 CV_HA100 Mean_HA85 CV_HA85 
        Mean_PerPlant CV_PerPlant;
    FORMAT Mean_Raw Mean_HA100 Mean_HA85 Mean_PerPlant 10.2
           CV_Raw CV_HA100 CV_HA85 CV_PerPlant 6.2;
RUN;

/*******************************************************************************
* STEP 4: OVERALL HERITABILITY ANALYSIS
* Using PROC MIXED to estimate variance components
* Model: Yield = μ + Genotype + Trial + Genotype×Trial + Error
*******************************************************************************/

%MACRO heritability_overall(yvar=, outname=);
    
    TITLE2 "Heritability Analysis: &yvar (Overall - All Trials)";
    
    /* Mixed model with genotype and trial as random effects */
    PROC MIXED DATA=yield_data COVTEST METHOD=REML;
        CLASS Genotype Trial;
        MODEL &yvar = / SOLUTION DDFM=KR;
        RANDOM Genotype Trial Genotype*Trial;
        ODS OUTPUT CovParms=covparms_&outname;
    RUN;
    
    /* Extract variance components and calculate heritability */
    DATA herit_&outname;
        SET covparms_&outname END=last;
        
        /* Store variance components */
        IF CovParm = 'Genotype' THEN CALL SYMPUTX('var_g', Estimate);
        IF CovParm = 'Trial' THEN CALL SYMPUTX('var_t', Estimate);
        IF CovParm = 'Genotype*Trial' THEN CALL SYMPUTX('var_gt', Estimate);
        IF CovParm = 'Residual' THEN CALL SYMPUTX('var_e', Estimate);
        
        /* Calculate heritability on last observation */
        IF last THEN DO;
            Trait = "&yvar";
            Var_Genotype = SYMGET('var_g');
            Var_Trial = SYMGET('var_t');
            Var_GxT = SYMGET('var_gt');
            Var_Error = SYMGET('var_e');
            
            /* Convert to numeric */
            Var_G_num = INPUT(Var_Genotype, BEST.);
            Var_T_num = INPUT(Var_Trial, BEST.);
            Var_GT_num = INPUT(Var_GxT, BEST.);
            Var_E_num = INPUT(Var_Error, BEST.);
            
            /* Calculate total phenotypic variance */
            Var_Phenotypic = Var_G_num + Var_T_num + Var_GT_num + Var_E_num;
            
            /* Broad-sense heritability */
            H2_broad = Var_G_num / Var_Phenotypic;
            
            /* Heritability (on plot-mean basis) */
            /* Assuming equal replication, adjust n_rep if different */
            n_trials = 13;
            n_rep = 1;  /* Adjust based on your design */
            
            H2_mean = Var_G_num / (Var_G_num + Var_GT_num/n_trials + Var_E_num/(n_trials*n_rep));
            
            /* Calculate CVs from overall_stats */
            MERGE overall_stats;
            
            %IF &yvar = Yield_Raw %THEN %DO;
                Mean_trait = Mean_Raw;
                CV_phenotypic = CV_Raw;
            %END;
            %ELSE %IF &yvar = Yield_HA100 %THEN %DO;
                Mean_trait = Mean_HA100;
                CV_phenotypic = CV_HA100;
            %END;
            %ELSE %IF &yvar = Yield_HA85 %THEN %DO;
                Mean_trait = Mean_HA85;
                CV_phenotypic = CV_HA85;
            %END;
            %ELSE %IF &yvar = Yield_PerPlant %THEN %DO;
                Mean_trait = Mean_PerPlant;
                CV_phenotypic = CV_PerPlant;
            %END;
            
            /* Genotypic CV */
            CV_genotypic = (SQRT(Var_G_num) / Mean_trait) * 100;
            
            /* Environmental CV */
            CV_environmental = (SQRT(Var_E_num) / Mean_trait) * 100;
            
            OUTPUT;
        END;
        
        KEEP Trait Var_G_num Var_T_num Var_GT_num Var_E_num Var_Phenotypic
             H2_broad H2_mean Mean_trait CV_phenotypic CV_genotypic CV_environmental;
    RUN;
    
    PROC PRINT DATA=herit_&outname NOOBS;
        TITLE3 "Heritability and CV Estimates for &yvar";
        VAR Trait Var_G_num Var_T_num Var_GT_num Var_E_num Var_Phenotypic
            H2_broad H2_mean Mean_trait CV_phenotypic CV_genotypic CV_environmental;
        FORMAT Var_G_num Var_T_num Var_GT_num Var_E_num Var_Phenotypic 12.2
               H2_broad H2_mean 6.4
               Mean_trait 10.2
               CV_phenotypic CV_genotypic CV_environmental 6.2;
    RUN;
    
%MEND heritability_overall;

/* Run heritability analysis for all yield types */
%heritability_overall(yvar=Yield_Raw, outname=raw);
%heritability_overall(yvar=Yield_HA100, outname=ha100);
%heritability_overall(yvar=Yield_HA85, outname=ha85);
%heritability_overall(yvar=Yield_PerPlant, outname=perplant);

/* Combine all heritability results */
DATA all_heritability_overall;
    SET herit_raw herit_ha100 herit_ha85 herit_perplant;
RUN;

PROC PRINT DATA=all_heritability_overall NOOBS;
    TITLE2 "Summary: Heritability and CV for All Yield Traits (Overall)";
    VAR Trait H2_broad H2_mean CV_phenotypic CV_genotypic CV_environmental;
    FORMAT H2_broad H2_mean 6.4 CV_phenotypic CV_genotypic CV_environmental 6.2;
RUN;

/* Export overall heritability results */
PROC EXPORT DATA=all_heritability_overall
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\heritability_cv_overall.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 5: PER-TRIAL HERITABILITY ANALYSIS
* Calculate heritability and CV separately for each trial
*******************************************************************************/

%MACRO heritability_by_trial(yvar=, outname=);
    
    TITLE2 "Per-Trial Heritability Analysis: &yvar";
    
    /* Get list of trials */
    PROC SQL NOPRINT;
        SELECT DISTINCT Trial INTO :trial_list SEPARATED BY ' '
        FROM yield_data
        ORDER BY Trial;
        
        SELECT COUNT(DISTINCT Trial) INTO :n_trials
        FROM yield_data;
    QUIT;
    
    /* Loop through each trial */
    %DO i = 1 %TO &n_trials;
        %LET trial_id = %SCAN(&trial_list, &i);
        
        %PUT NOTE: Processing Trial &trial_id for &yvar;
        
        /* Filter data for specific trial */
        DATA trial_&trial_id._data;
            SET yield_data;
            WHERE Trial = &trial_id;
        RUN;
        
        /* Check if sufficient data exists */
        PROC SQL NOPRINT;
            SELECT COUNT(DISTINCT Genotype) INTO :n_geno
            FROM trial_&trial_id._data;
            
            SELECT COUNT(*) INTO :n_obs
            FROM trial_&trial_id._data
            WHERE &yvar IS NOT MISSING;
        QUIT;
        
        %PUT NOTE: Trial &trial_id has &n_geno genotypes and &n_obs observations;
        
        /* Only run if sufficient genotypes exist */
        %IF &n_geno > 1 AND &n_obs > 10 %THEN %DO;
            
            /* Mixed model for single trial */
            PROC MIXED DATA=trial_&trial_id._data COVTEST METHOD=REML;
                CLASS Genotype Row Column;
                MODEL &yvar = / SOLUTION;
                RANDOM Genotype;  /* Only genotype is random in single trial */
                ODS OUTPUT CovParms=covparms_&outname._&trial_id;
            RUN;
            
            /* Calculate heritability for this trial */
            DATA herit_&outname._&trial_id;
                SET covparms_&outname._&trial_id END=last;
                
                IF CovParm = 'Genotype' THEN CALL SYMPUTX('var_g', Estimate);
                IF CovParm = 'Residual' THEN CALL SYMPUTX('var_e', Estimate);
                
                IF last THEN DO;
                    Trial_ID = &trial_id;
                    Trait = "&yvar";
                    Var_Genotype = INPUT(SYMGET('var_g'), BEST.);
                    Var_Error = INPUT(SYMGET('var_e'), BEST.);
                    Var_Phenotypic = Var_Genotype + Var_Error;
                    
                    /* Broad-sense heritability for this trial */
                    H2_broad = Var_Genotype / Var_Phenotypic;
                    
                    /* Get mean and CV for this trial */
                    MERGE trial_stats (WHERE=(Trial=&trial_id));
                    BY Trial;
                    
                    %IF &yvar = Yield_Raw %THEN %DO;
                        Mean_trait = Mean_Raw;
                        CV_phenotypic = CV_Raw;
                    %END;
                    %ELSE %IF &yvar = Yield_HA100 %THEN %DO;
                        Mean_trait = Mean_HA100;
                        CV_phenotypic = CV_HA100;
                    %END;
                    %ELSE %IF &yvar = Yield_HA85 %THEN %DO;
                        Mean_trait = Mean_HA85;
                        CV_phenotypic = CV_HA85;
                    %END;
                    %ELSE %IF &yvar = Yield_PerPlant %THEN %DO;
                        Mean_trait = Mean_PerPlant;
                        CV_phenotypic = CV_PerPlant;
                    %END;
                    
                    /* Genotypic CV */
                    CV_genotypic = (SQRT(Var_Genotype) / Mean_trait) * 100;
                    
                    /* Environmental CV */
                    CV_environmental = (SQRT(Var_Error) / Mean_trait) * 100;
                    
                    OUTPUT;
                END;
                
                KEEP Trial_ID Trait Var_Genotype Var_Error Var_Phenotypic
                     H2_broad Mean_trait CV_phenotypic CV_genotypic CV_environmental;
            RUN;
            
        %END;
        %ELSE %DO;
            %PUT WARNING: Insufficient data for Trial &trial_id - skipping;
        %END;
        
        /* Clean up */
        PROC DATASETS LIBRARY=WORK NOLIST;
            DELETE trial_&trial_id._data covparms_&outname._&trial_id;
        QUIT;
        
    %END;
    
    /* Combine all trial-specific results */
    DATA herit_by_trial_&outname;
        SET herit_&outname._:;
    RUN;
    
    PROC PRINT DATA=herit_by_trial_&outname;
        TITLE3 "Heritability and CV by Trial for &yvar";
        VAR Trial_ID Trait H2_broad Mean_trait CV_phenotypic CV_genotypic CV_environmental;
        FORMAT H2_broad 6.4 Mean_trait 10.2 CV_phenotypic CV_genotypic CV_environmental 6.2;
    RUN;
    
    /* Clean up individual trial datasets */
    PROC DATASETS LIBRARY=WORK NOLIST;
        DELETE herit_&outname._25:;
    QUIT;
    
%MEND heritability_by_trial;

/* Run per-trial heritability analysis for all yield types */
%heritability_by_trial(yvar=Yield_Raw, outname=raw);
%heritability_by_trial(yvar=Yield_HA100, outname=ha100);
%heritability_by_trial(yvar=Yield_HA85, outname=ha85);
%heritability_by_trial(yvar=Yield_PerPlant, outname=perplant);

/* Combine all per-trial results */
DATA all_heritability_by_trial;
    SET herit_by_trial_raw herit_by_trial_ha100 
        herit_by_trial_ha85 herit_by_trial_perplant;
RUN;

PROC SORT DATA=all_heritability_by_trial;
    BY Trial_ID Trait;
RUN;

PROC PRINT DATA=all_heritability_by_trial;
    TITLE2 "Summary: Heritability and CV by Trial for All Yield Traits";
    BY Trial_ID;
    VAR Trait H2_broad CV_phenotypic CV_genotypic CV_environmental;
    FORMAT H2_broad 6.4 CV_phenotypic CV_genotypic CV_environmental 6.2;
RUN;

/* Export per-trial heritability results */
PROC EXPORT DATA=all_heritability_by_trial
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\heritability_cv_by_trial.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 6: Summary Statistics and Comparisons
*******************************************************************************/

/* Summary of heritability across trials */
PROC MEANS DATA=all_heritability_by_trial N MEAN STD MIN MAX;
    TITLE2 "Summary of Heritability Estimates Across Trials";
    CLASS Trait;
    VAR H2_broad CV_genotypic CV_environmental;
RUN;

/* Comparison table */
DATA heritability_comparison;
    LENGTH Source $20 Trait $20;
    SET all_heritability_overall (IN=a)
        all_heritability_by_trial (IN=b);
    
    IF a THEN Source = "Overall";
    ELSE IF b THEN Source = "Trial " || PUT(Trial_ID, 4.);
RUN;

PROC SORT DATA=heritability_comparison;
    BY Trait Source;
RUN;

PROC PRINT DATA=heritability_comparison;
    TITLE2 "Heritability Comparison: Overall vs By Trial";
    BY Trait;
    VAR Source H2_broad CV_phenotypic CV_genotypic CV_environmental;
    FORMAT H2_broad 6.4 CV_phenotypic CV_genotypic CV_environmental 6.2;
RUN;

/*******************************************************************************
* STEP 7: Visualization of Results
*******************************************************************************/

/* Heritability by trial - bar chart */
PROC SGPLOT DATA=all_heritability_by_trial;
    TITLE2 "Broad-Sense Heritability by Trial and Yield Type";
    VBAR Trial_ID / RESPONSE=H2_broad GROUP=Trait GROUPDISPLAY=CLUSTER;
    YAXIS LABEL="Heritability (H²)" MIN=0 MAX=1;
    XAXIS LABEL="Trial";
    REFLINE 0.5 / AXIS=Y LINEATTRS=(PATTERN=2 COLOR=red) LABEL="H² = 0.5";
RUN;

/* CV comparison */
PROC SGPLOT DATA=all_heritability_by_trial;
    TITLE2 "Coefficient of Variation by Trial and Yield Type";
    VBAR Trial_ID / RESPONSE=CV_genotypic GROUP=Trait GROUPDISPLAY=CLUSTER;
    YAXIS LABEL="Genotypic CV (%)";
    XAXIS LABEL="Trial";
RUN;

/* Scatter plot: H2 vs CV */
PROC SGPLOT DATA=all_heritability_by_trial;
    TITLE2 "Relationship Between Heritability and Genotypic CV";
    SCATTER X=H2_broad Y=CV_genotypic / GROUP=Trait MARKERATTRS=(SIZE=10);
    XAXIS LABEL="Broad-Sense Heritability (H²)";
    YAXIS LABEL="Genotypic CV (%)";
    REFLINE 0.5 / AXIS=X LINEATTRS=(PATTERN=2);
RUN;

/*******************************************************************************
* STEP 8: Export Final Summary Table
*******************************************************************************/

/* Create publication-ready summary table */
PROC TABULATE DATA=heritability_comparison FORMAT=8.3;
    TITLE2 "Summary Table: Heritability and CV Estimates";
    CLASS Trait Source;
    VAR H2_broad CV_phenotypic CV_genotypic;
    TABLE Trait,
          Source * (H2_broad CV_phenotypic CV_genotypic) * MEAN;
RUN;

/* Export comparison table */
PROC EXPORT DATA=heritability_comparison
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\heritability_comparison.csv"
    DBMS=CSV
    REPLACE;
RUN;

/* Clean up */
PROC DATASETS LIBRARY=WORK NOLIST;
    DELETE herit_by_trial_: covparms_:;
QUIT;

/* End of Program */
TITLE;
FOOTNOTE;

/*******************************************************************************
* SUMMARY OF OUTPUTS:
*
* CSV FILES CREATED:
* 1. heritability_cv_overall.csv - Overall heritability estimates (n=4 traits)
* 2. heritability_cv_by_trial.csv - Per-trial estimates (n=13 trials × 4 traits)
* 3. heritability_comparison.csv - Combined comparison table
*
* KEY METRICS CALCULATED:
* 
* HERITABILITY (H²):
* - Broad-sense heritability = σ²g / σ²p
* - Plot-mean heritability = σ²g / (σ²g + σ²gt/t + σ²e/tr)
* - Range: 0 (no genetic variation) to 1 (all variation is genetic)
*
* COEFFICIENT OF VARIATION:
* - CV_phenotypic = (√σ²p / μ) × 100 (total variation)
* - CV_genotypic = (√σ²g / μ) × 100 (genetic variation)
* - CV_environmental = (√σ²e / μ) × 100 (environmental variation)
*
* VARIANCE COMPONENTS:
* - σ²g = Genotypic variance
* - σ²t = Trial variance (overall analysis only)
* - σ²gt = Genotype × Trial interaction (overall analysis only)
* - σ²e = Residual/error variance
*
* INTERPRETATION:
* - High H² (>0.6) = traits are highly heritable, selection will be effective
* - Moderate H² (0.3-0.6) = moderate genetic control
* - Low H² (<0.3) = environment has large effect, selection less effective
* - High CV_genotypic = large genetic variation available for selection
* - CV_genotypic/CV_phenotypic ratio indicates reliability of selection
*
* NOTE: Adjust "Genotype" variable if you have variety/line information
*******************************************************************************/
