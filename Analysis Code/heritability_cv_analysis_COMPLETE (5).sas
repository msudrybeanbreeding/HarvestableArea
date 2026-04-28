/*******************************************************************************
* Program: Heritability and CV Analysis - COMPLETE VERSION
* Purpose: Calculate heritability with proper comparison tables
*
* KEY FIX: Includes full comparison section that was missing
*******************************************************************************/

OPTIONS NODATE NONUMBER PS=60 LS=132;
TITLE "Heritability and CV Analysis for Yield Traits";

/*******************************************************************************
* STEP 1: Import Data
*******************************************************************************/
PROC IMPORT DATAFILE="D:\svrec HA data\Multitemporal VI data HA + yield + names - 13DAS for Heritabiliy.csv"
    OUT=vi_data
    DBMS=CSV
    REPLACE;
    GETNAMES=YES;
RUN;

/*******************************************************************************
* STEP 2: Data Preparation - Use ONE DAS per plot
*******************************************************************************/
DATA yield_data;
    SET vi_data;
    WHERE DAS = 13;  /* Use first timepoint - yield is constant across DAS */
    
    Genotype = VarietyName;
    Yield_Raw = Yield;
    Yield_HA100 = HACorrectedYield;
    Yield_HA85 = HACorrected85Yield;
    Yield_PerPlant = Perplantyield;
    
    RENAME 'HA Mean'n = HA_Mean
           'PLT COUNT'n = PLT_COUNT;
    
    KEEP Trial Row Column Genotype
         Yield_Raw Yield_HA100 Yield_HA85 Yield_PerPlant
         'HA Mean'n 'PLT COUNT'n;
RUN;

/* Data summary */
PROC SQL;
    TITLE2 "Data Summary (Using DAS=13)";
    SELECT 
        COUNT(*) AS Total_Observations,
        COUNT(DISTINCT Trial) AS N_Trials,
        COUNT(DISTINCT Genotype) AS N_Genotypes
    FROM yield_data;
QUIT;

/*******************************************************************************
* STEP 3: Descriptive Statistics
*******************************************************************************/
PROC MEANS DATA=yield_data N MEAN STD MIN MAX CV;
    TITLE2 "Overall Descriptive Statistics";
    VAR Yield_Raw Yield_HA100 Yield_HA85 Yield_PerPlant;
    OUTPUT OUT=overall_stats
           N=N_Raw N_HA100 N_HA85 N_PerPlant
           MEAN=Mean_Raw Mean_HA100 Mean_HA85 Mean_PerPlant
           STD=Std_Raw Std_HA100 Std_HA85 Std_PerPlant
           CV=CV_Raw CV_HA100 CV_HA85 CV_PerPlant;
RUN;

PROC SORT DATA=yield_data;
    BY Trial;
RUN;

PROC MEANS DATA=yield_data N MEAN STD MIN MAX CV NOPRINT;
    BY Trial;
    VAR Yield_Raw Yield_HA100 Yield_HA85 Yield_PerPlant;
    OUTPUT OUT=trial_stats
           N=N_Raw N_HA100 N_HA85 N_PerPlant
           MEAN=Mean_Raw Mean_HA100 Mean_HA85 Mean_PerPlant
           STD=Std_Raw Std_HA100 Std_HA85 Std_PerPlant
           CV=CV_Raw CV_HA100 CV_HA85 CV_PerPlant;
RUN;

/*******************************************************************************
* STEP 4: OVERALL HERITABILITY ANALYSIS
*******************************************************************************/

%MACRO heritability_overall(yvar=, outname=);
    
    TITLE2 "Heritability Analysis: &yvar (Overall)";
    
    PROC SQL NOPRINT;
        SELECT COUNT(*) INTO :n_obs
        FROM yield_data
        WHERE &yvar IS NOT MISSING;
        
        SELECT COUNT(DISTINCT Genotype) INTO :n_geno
        FROM yield_data
        WHERE &yvar IS NOT MISSING;
    QUIT;
    
    %PUT NOTE: &yvar has &n_obs observations and &n_geno genotypes;
    
    %IF &n_geno < 3 OR &n_obs < 50 %THEN %DO;
        DATA herit_&outname;
            LENGTH Trait $20;
            Trait = "&yvar";
            Var_G_num = .;
            Var_T_num = .;
            Var_GT_num = .;
            Var_E_num = .;
            Var_Phenotypic = .;
            H2_broad = .;
            H2_mean = .;
            Mean_trait = .;
            CV_phenotypic = .;
            CV_genotypic = .;
            CV_environmental = .;
            N_obs = &n_obs;
            N_geno = &n_geno;
            OUTPUT;
        RUN;
    %END;
    %ELSE %DO;
        PROC MIXED DATA=yield_data COVTEST METHOD=REML;
            WHERE &yvar IS NOT MISSING;
            CLASS Genotype Trial;
            MODEL &yvar = / SOLUTION DDFM=KR;
            RANDOM Genotype Trial Genotype*Trial;
            ODS OUTPUT CovParms=covparms_&outname;
        RUN;
        
        DATA herit_&outname;
            SET covparms_&outname END=last;
            
            IF CovParm = 'Genotype' THEN CALL SYMPUTX('var_g', Estimate);
            IF CovParm = 'Trial' THEN CALL SYMPUTX('var_t', Estimate);
            IF CovParm = 'Genotype*Trial' THEN CALL SYMPUTX('var_gt', Estimate);
            IF CovParm = 'Residual' THEN CALL SYMPUTX('var_e', Estimate);
            
            IF last THEN DO;
                Trait = "&yvar";
                Var_G_num = INPUT(SYMGET('var_g'), BEST.);
                Var_T_num = INPUT(SYMGET('var_t'), BEST.);
                Var_GT_num = INPUT(SYMGET('var_gt'), BEST.);
                Var_E_num = INPUT(SYMGET('var_e'), BEST.);
                
                Var_Phenotypic = Var_G_num + Var_T_num + Var_GT_num + Var_E_num;
                H2_broad = Var_G_num / Var_Phenotypic;
                
                n_trials = 13;
                n_rep = 1;
                H2_mean = Var_G_num / (Var_G_num + Var_GT_num/n_trials + Var_E_num/(n_trials*n_rep));
                
                IF _N_ = 1 THEN SET overall_stats;
                
                %IF &yvar = Yield_Raw %THEN %DO;
                    Mean_trait = Mean_Raw;
                    CV_phenotypic = CV_Raw;
                    N_obs = N_Raw;
                %END;
                %ELSE %IF &yvar = Yield_HA100 %THEN %DO;
                    Mean_trait = Mean_HA100;
                    CV_phenotypic = CV_HA100;
                    N_obs = N_HA100;
                %END;
                %ELSE %IF &yvar = Yield_HA85 %THEN %DO;
                    Mean_trait = Mean_HA85;
                    CV_phenotypic = CV_HA85;
                    N_obs = N_HA85;
                %END;
                %ELSE %IF &yvar = Yield_PerPlant %THEN %DO;
                    Mean_trait = Mean_PerPlant;
                    CV_phenotypic = CV_PerPlant;
                    N_obs = N_PerPlant;
                %END;
                
                CV_genotypic = (SQRT(Var_G_num) / Mean_trait) * 100;
                CV_environmental = (SQRT(Var_E_num) / Mean_trait) * 100;
                N_geno = &n_geno;
                
                OUTPUT;
            END;
            
            KEEP Trait Var_G_num Var_T_num Var_GT_num Var_E_num Var_Phenotypic
                 H2_broad H2_mean Mean_trait CV_phenotypic CV_genotypic CV_environmental
                 N_obs N_geno;
        RUN;
    %END;
    
    PROC PRINT DATA=herit_&outname NOOBS;
        TITLE3 "Heritability Estimates for &yvar";
        VAR Trait N_obs N_geno Mean_trait CV_phenotypic H2_broad H2_mean 
            CV_genotypic CV_environmental;
        FORMAT H2_broad H2_mean 6.4
               Mean_trait 10.2
               CV_phenotypic CV_genotypic CV_environmental 6.2;
    RUN;
    
%MEND heritability_overall;

/* Run overall analyses */
%heritability_overall(yvar=Yield_Raw, outname=raw);
%heritability_overall(yvar=Yield_HA100, outname=ha100);
%heritability_overall(yvar=Yield_HA85, outname=ha85);
%heritability_overall(yvar=Yield_PerPlant, outname=perplant);

/* Combine overall results */
DATA all_heritability_overall;
    SET herit_raw herit_ha100 herit_ha85 herit_perplant;
RUN;

PROC PRINT DATA=all_heritability_overall NOOBS;
    TITLE2 "Summary: Overall Heritability for All Yield Traits";
    VAR Trait N_obs N_geno H2_broad H2_mean CV_phenotypic CV_genotypic CV_environmental;
    FORMAT H2_broad H2_mean 6.4 CV_phenotypic CV_genotypic CV_environmental 6.2;
RUN;

PROC EXPORT DATA=all_heritability_overall
    OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\heritability_cv_overall.csv"
    DBMS=CSV
    REPLACE;
RUN;

/*******************************************************************************
* STEP 5: PER-TRIAL HERITABILITY ANALYSIS
*******************************************************************************/

%MACRO heritability_by_trial(yvar=, outname=);
    
    TITLE2 "Per-Trial Heritability: &yvar";
    
    PROC SQL NOPRINT;
        SELECT DISTINCT Trial INTO :trial_list SEPARATED BY ' '
        FROM yield_data
        WHERE &yvar IS NOT MISSING
        ORDER BY Trial;
        
        SELECT COUNT(DISTINCT Trial) INTO :n_trials
        FROM yield_data
        WHERE &yvar IS NOT MISSING;
    QUIT;
    
    %DO i = 1 %TO &n_trials;
        %LET trial_id = %SCAN(&trial_list, &i);
        
        DATA trial_&trial_id._data;
            SET yield_data;
            WHERE Trial = &trial_id AND &yvar IS NOT MISSING;
        RUN;
        
        PROC SQL NOPRINT;
            SELECT COUNT(DISTINCT Genotype) INTO :n_geno
            FROM trial_&trial_id._data;
            
            SELECT COUNT(*) INTO :n_obs
            FROM trial_&trial_id._data;
        QUIT;
        
        %IF &n_geno > 3 AND &n_obs > 15 %THEN %DO;
            
            PROC MIXED DATA=trial_&trial_id._data COVTEST METHOD=REML;
                CLASS Genotype;
                MODEL &yvar = / SOLUTION;
                RANDOM Genotype;
                ODS OUTPUT CovParms=covparms_&outname._&trial_id;
            RUN;
            
            DATA herit_&outname._&trial_id;
                /* First, read trial stats for this trial */
                IF _N_ = 1 THEN DO;
                    SET trial_stats (WHERE=(Trial=&trial_id));
                    
                    %IF &yvar = Yield_Raw %THEN %DO;
                        CALL SYMPUTX('trial_mean', Mean_Raw);
                        CALL SYMPUTX('trial_cv', CV_Raw);
                        CALL SYMPUTX('trial_n', N_Raw);
                    %END;
                    %ELSE %IF &yvar = Yield_HA100 %THEN %DO;
                        CALL SYMPUTX('trial_mean', Mean_HA100);
                        CALL SYMPUTX('trial_cv', CV_HA100);
                        CALL SYMPUTX('trial_n', N_HA100);
                    %END;
                    %ELSE %IF &yvar = Yield_HA85 %THEN %DO;
                        CALL SYMPUTX('trial_mean', Mean_HA85);
                        CALL SYMPUTX('trial_cv', CV_HA85);
                        CALL SYMPUTX('trial_n', N_HA85);
                    %END;
                    %ELSE %IF &yvar = Yield_PerPlant %THEN %DO;
                        CALL SYMPUTX('trial_mean', Mean_PerPlant);
                        CALL SYMPUTX('trial_cv', CV_PerPlant);
                        CALL SYMPUTX('trial_n', N_PerPlant);
                    %END;
                END;
                
                SET covparms_&outname._&trial_id END=last;
                
                IF CovParm = 'Genotype' THEN CALL SYMPUTX('var_g', Estimate);
                IF CovParm = 'Residual' THEN CALL SYMPUTX('var_e', Estimate);
                
                IF last THEN DO;
                    Trial_ID = &trial_id;
                    Trait = "&yvar";
                    Var_Genotype = INPUT(SYMGET('var_g'), BEST.);
                    Var_Error = INPUT(SYMGET('var_e'), BEST.);
                    Var_Phenotypic = Var_Genotype + Var_Error;
                    H2_broad = Var_Genotype / Var_Phenotypic;
                    
                    /* Get trial-level stats from macro variables */
                    Mean_trait = INPUT(SYMGET('trial_mean'), BEST.);
                    CV_phenotypic = INPUT(SYMGET('trial_cv'), BEST.);
                    N_obs = INPUT(SYMGET('trial_n'), BEST.);
                    
                    /* Calculate CVs */
                    CV_genotypic = (SQRT(Var_Genotype) / Mean_trait) * 100;
                    CV_environmental = (SQRT(Var_Error) / Mean_trait) * 100;
                    N_geno = &n_geno;
                    
                    OUTPUT;
                END;
                
                KEEP Trial_ID Trait Var_Genotype Var_Error Var_Phenotypic
                     H2_broad Mean_trait CV_phenotypic CV_genotypic CV_environmental
                     N_obs N_geno;
            RUN;
            
        %END;
        
        /* Clean up temporary data only (keep herit_* datasets for combining later) */
        PROC DATASETS LIBRARY=WORK NOLIST;
            DELETE trial_&trial_id._data;
        QUIT;
        
    %END;
    
    /* Try to combine trial results - use a safer approach */
    %PUT NOTE: Looking for datasets matching HERIT_&outname._*;
    
    /* First, check if ANY herit datasets exist for this trait */
    PROC SQL NOPRINT;
        SELECT COUNT(*) INTO :n_herit_datasets TRIMMED
        FROM sashelp.vmember
        WHERE libname='WORK' 
              AND memtype='DATA'
              AND UPCASE(memname) LIKE "HERIT_%";
    QUIT;
    
    %PUT NOTE: Found &n_herit_datasets total herit datasets in WORK library;
    
    /* Now try to combine them */
    %LET dsid = %SYSFUNC(OPEN(WORK.herit_&outname._2501));
    %IF &dsid NE 0 %THEN %DO;
        %LET rc = %SYSFUNC(CLOSE(&dsid));
        
        /* At least one dataset exists, combine them all */
        DATA herit_by_trial_&outname;
            SET herit_&outname._:;
        RUN;
        
        %PUT NOTE: Successfully combined herit_&outname datasets;
        
        /* Clean up individual trial herit and covparms datasets */
        PROC DATASETS LIBRARY=WORK NOLIST;
            DELETE herit_&outname._25: covparms_&outname._:;
        QUIT;
    %END;
    %ELSE %DO;
        %PUT WARNING: No herit_&outname datasets found to combine;
        
        /* Create empty dataset */
        DATA herit_by_trial_&outname;
            LENGTH Trial_ID 8 Trait $20;
            STOP;
        RUN;
    %END;
    
%MEND heritability_by_trial;

/* Run per-trial analyses */
%heritability_by_trial(yvar=Yield_Raw, outname=raw);
%heritability_by_trial(yvar=Yield_HA100, outname=ha100);
%heritability_by_trial(yvar=Yield_HA85, outname=ha85);
%heritability_by_trial(yvar=Yield_PerPlant, outname=perplant);

/* Combine all per-trial results */
DATA all_heritability_by_trial;
    SET herit_by_trial_raw herit_by_trial_ha100 
        herit_by_trial_ha85 herit_by_trial_perplant;
RUN;

/* Check if we have trial-level data */
PROC SQL NOPRINT;
    SELECT COUNT(*) INTO :n_trial_obs
    FROM all_heritability_by_trial;
QUIT;

%PUT NOTE: Found &n_trial_obs trial-level observations;

/*******************************************************************************
* STEP 6: CREATE COMPARISON TABLE (THIS WAS MISSING!)
*******************************************************************************/

%IF &n_trial_obs > 0 %THEN %DO;
    
    /* Sort trial data */
    PROC SORT DATA=all_heritability_by_trial;
        BY Trial_ID Trait;
    RUN;
    
    /* Print trial results */
    PROC PRINT DATA=all_heritability_by_trial;
        TITLE2 "Per-Trial Heritability Results";
        BY Trial_ID;
        VAR Trait N_obs N_geno H2_broad CV_phenotypic CV_genotypic CV_environmental;
        FORMAT H2_broad 6.4 CV_phenotypic CV_genotypic CV_environmental 6.2;
    RUN;
    
    /* Export trial results */
    PROC EXPORT DATA=all_heritability_by_trial
        OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\heritability_cv_by_trial.csv"
        DBMS=CSV
        REPLACE;
    RUN;
    
    /***************************************************************************
    * CREATE COMPARISON TABLE - Combines Overall and Per-Trial Results
    ***************************************************************************/
    
    DATA heritability_comparison;
        LENGTH Source $30 Trait $20;
        
        /* Add overall results */
        SET all_heritability_overall (IN=overall_flag)
            all_heritability_by_trial (IN=trial_flag);
        
        IF overall_flag THEN Source = "Overall";
        ELSE IF trial_flag THEN Source = "Trial " || PUT(Trial_ID, 4.);
        
        /* Standardize variable names */
        IF overall_flag THEN Trial_ID = .;
    RUN;
    
    /* Sort for nice output */
    PROC SORT DATA=heritability_comparison;
        BY Trait Source;
    RUN;
    
    /* Print comparison */
    PROC PRINT DATA=heritability_comparison NOOBS;
        TITLE2 "Heritability Comparison: Overall vs Individual Trials";
        BY Trait;
        VAR Source H2_broad H2_mean CV_phenotypic CV_genotypic CV_environmental;
        FORMAT H2_broad H2_mean 6.4 CV_phenotypic CV_genotypic CV_environmental 6.2;
    RUN;
    
    /* Export comparison */
    PROC EXPORT DATA=heritability_comparison
        OUTFILE="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\heritability_comparison.csv"
        DBMS=CSV
        REPLACE;
    RUN;
    
    /***************************************************************************
    * Summary Statistics Across Trials
    ***************************************************************************/
    
    PROC MEANS DATA=all_heritability_by_trial N MEAN STD MIN MAX;
        TITLE2 "Summary of Heritability Estimates Across Trials";
        CLASS Trait;
        VAR H2_broad CV_genotypic CV_environmental;
    RUN;
    
    /***************************************************************************
    * Visualizations
    ***************************************************************************/
    
    /* Heritability by trial */
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
    
    /* H2 vs CV relationship */
    PROC SGPLOT DATA=all_heritability_by_trial;
        TITLE2 "Relationship Between Heritability and Genotypic CV";
        SCATTER X=H2_broad Y=CV_genotypic / GROUP=Trait MARKERATTRS=(SIZE=10);
        XAXIS LABEL="Broad-Sense Heritability (H²)";
        YAXIS LABEL="Genotypic CV (%)";
        REFLINE 0.5 / AXIS=X LINEATTRS=(PATTERN=2);
    RUN;
    
    /* Summary table */
    PROC TABULATE DATA=heritability_comparison FORMAT=8.3;
        TITLE2 "Summary Table: Heritability and CV Estimates";
        CLASS Trait Source;
        VAR H2_broad CV_phenotypic CV_genotypic;
        TABLE Trait,
              Source * (H2_broad CV_phenotypic CV_genotypic) * MEAN;
    RUN;
    
%END;
%ELSE %DO;
    %PUT WARNING: No trial-level heritability results available;
    %PUT WARNING: Comparison table cannot be created;
%END;

/* Cleanup */
PROC DATASETS LIBRARY=WORK NOLIST;
    DELETE herit_by_trial_: covparms_:;
QUIT;

TITLE;
FOOTNOTE;

/*******************************************************************************
* SUMMARY OF OUTPUTS:
*
* CSV FILES CREATED:
* 1. heritability_cv_overall.csv - Overall heritability (4 traits)
* 2. heritability_cv_by_trial.csv - Per-trial heritability (13 trials × 4 traits)
* 3. heritability_comparison.csv - Combined comparison table
*
* KEY FEATURES IN THIS VERSION:
* - Uses DAS=13 (first timepoint) - one observation per plot
* - Added complete comparison section (Step 6)
* - Properly combines overall and trial-level results
* - Creates publication-ready comparison table
* - Includes visualizations and summary statistics
*******************************************************************************/
