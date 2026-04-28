/* ================================================================= */
/* Multitemporal Correlation Analysis - 2024 Dataset                */
/* Correlations between VIs, HA, Thresh, Plant Count vs Yield & Peak Stand */
/* ================================================================= */

/* Import the dataset */
proc import datafile="/mnt/user-data/uploads/ConsolidatedMultitemporal2024.csv"
    out=multitemp
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=max;
run;

/* Clean variable names and prepare data */
data multitemp_clean;
    set multitemp;
    
    /* Rename variables for easier handling */
    Yield = "Plot Yield"n;
    PlantCount = pntcounts;
    Thresh = Thresh_mean;
    HA = HAreamean;
    NDVI = NDVI_mean;
    SAVI = SAVI_mean;
    GNDVI = "613GNDVI_mean"n;
    NDRE = "613NDRE_mean"n;
    ExG = "613ExG_mean"n;
    ExR = "613ExR_mean"n;
    
    /* Keep only necessary variables */
    keep Trial DAS joined_PlotIDstring Yield PeakStand 
         PlantCount Thresh HA NDVI SAVI GNDVI NDRE ExG ExR;
    
    /* Remove missing values */
    if nmiss(of Yield PeakStand PlantCount Thresh HA NDVI SAVI GNDVI NDRE ExG ExR) = 0;
run;

/* Get unique timepoints */
proc sql noprint;
    select distinct DAS into :das_list separated by ' '
    from multitemp_clean
    order by DAS;
quit;

/* Macro to calculate correlations for each timepoint */
%macro corr_by_das;
    /* Create output dataset to store all results */
    data all_correlations;
        length DAS 8 Variable $20 Yield_r Yield_p PeakStand_r PeakStand_p 8;
        delete;
    run;
    
    %let i = 1;
    %let das = %scan(&das_list, &i);
    
    %do %while(&das ne );
        
        /* Filter data for current DAS */
        data temp_das;
            set multitemp_clean;
            where DAS = &das;
        run;
        
        /* Check if data exists */
        proc sql noprint;
            select count(*) into :nobs
            from temp_das;
        quit;
        
        %if &nobs > 0 %then %do;
            
            title "Correlation Analysis - DAS = &das";
            
            /* Calculate correlations with Yield */
            ods select none;
            proc corr data=temp_das nosimple;
                var PlantCount Thresh HA NDVI SAVI GNDVI NDRE ExG ExR;
                with Yield;
                ods output PearsonCorr=corr_yield_&das;
            run;
            ods select all;
            
            /* Calculate correlations with PeakStand */
            ods select none;
            proc corr data=temp_das nosimple;
                var PlantCount Thresh HA NDVI SAVI GNDVI NDRE ExG ExR;
                with PeakStand;
                ods output PearsonCorr=corr_peak_&das;
            run;
            ods select all;
            
            /* Process Yield correlations */
            data corr_yield_temp;
                set corr_yield_&das;
                DAS = &das;
                Variable = Variable;
                Yield_r = Yield;
                Yield_p = PYield;
                keep DAS Variable Yield_r Yield_p;
            run;
            
            /* Process PeakStand correlations */
            data corr_peak_temp;
                set corr_peak_&das;
                DAS = &das;
                Variable = Variable;
                PeakStand_r = PeakStand;
                PeakStand_p = PPeakStand;
                keep DAS Variable PeakStand_r PeakStand_p;
            run;
            
            /* Merge correlations for current DAS */
            proc sql;
                create table corr_current as
                select a.DAS, a.Variable, a.Yield_r, a.Yield_p, 
                       b.PeakStand_r, b.PeakStand_p
                from corr_yield_temp as a
                left join corr_peak_temp as b
                on a.Variable = b.Variable;
            quit;
            
            /* Append to master dataset */
            data all_correlations;
                set all_correlations corr_current;
            run;
            
        %end;
        
        %let i = %eval(&i + 1);
        %let das = %scan(&das_list, &i);
    %end;
    
    /* Clean up temporary datasets */
    proc datasets library=work nolist;
        delete temp_das corr_yield_temp corr_peak_temp corr_current
               corr_yield_: corr_peak_:;
    run;
    quit;
    
%mend corr_by_das;

/* Execute the macro */
%corr_by_das;

/* ================================================================= */
/* Format and display comprehensive results table                    */
/* ================================================================= */

title "Comprehensive Correlation Results by Timepoint";
proc print data=all_correlations noobs label;
    var DAS Variable Yield_r Yield_p PeakStand_r PeakStand_p;
    format Yield_r PeakStand_r 6.4 Yield_p PeakStand_p pvalue6.4;
    label DAS = "Days After Sowing"
          Variable = "Predictor Variable"
          Yield_r = "Correlation with Yield"
          Yield_p = "P-value (Yield)"
          PeakStand_r = "Correlation with Peak Stand"
          PeakStand_p = "P-value (Peak Stand)";
run;

/* ================================================================= */
/* Export results to CSV                                             */
/* ================================================================= */

proc export data=all_correlations
    outfile="/home/claude/multitemporal_correlations_results.csv"
    dbms=csv
    replace;
run;

/* ================================================================= */
/* Create summary statistics by DAS                                  */
/* ================================================================= */

proc means data=multitemp_clean n mean std min max;
    class DAS;
    var Yield PeakStand PlantCount Thresh HA NDVI SAVI GNDVI NDRE ExG ExR;
    title "Descriptive Statistics by Timepoint";
run;

/* ================================================================= */
/* Correlation heatmap visualization data preparation                */
/* ================================================================= */

/* Prepare data for heatmap - Yield correlations */
proc transpose data=all_correlations out=yield_heatmap prefix=DAS_;
    by Variable;
    id DAS;
    var Yield_r;
run;

title "Correlation Matrix: Variables vs Yield by DAS";
proc print data=yield_heatmap noobs;
run;

/* Prepare data for heatmap - PeakStand correlations */
proc transpose data=all_correlations out=peak_heatmap prefix=DAS_;
    by Variable;
    id DAS;
    var PeakStand_r;
run;

title "Correlation Matrix: Variables vs Peak Stand by DAS";
proc print data=peak_heatmap noobs;
run;

/* ================================================================= */
/* Statistical significance summary                                  */
/* ================================================================= */

data significance_summary;
    set all_correlations;
    
    /* Categorize significance levels */
    if Yield_p < 0.001 then Yield_sig = "***";
    else if Yield_p < 0.01 then Yield_sig = "**";
    else if Yield_p < 0.05 then Yield_sig = "*";
    else Yield_sig = "ns";
    
    if PeakStand_p < 0.001 then Peak_sig = "***";
    else if PeakStand_p < 0.01 then Peak_sig = "**";
    else if PeakStand_p < 0.05 then Peak_sig = "*";
    else Peak_sig = "ns";
run;

title "Correlation Results with Significance Indicators";
title2 "*** p<0.001, ** p<0.01, * p<0.05, ns = not significant";
proc print data=significance_summary noobs;
    var DAS Variable Yield_r Yield_sig PeakStand_r Peak_sig;
    format Yield_r PeakStand_r 6.4;
run;

/* ================================================================= */
/* Identify strongest correlations at each timepoint                */
/* ================================================================= */

proc sort data=all_correlations;
    by DAS descending Yield_r;
run;

title "Strongest Positive Correlations with Yield by Timepoint";
proc print data=all_correlations (obs=3);
    by DAS;
    var Variable Yield_r Yield_p;
    format Yield_r 6.4 Yield_p pvalue6.4;
run;

proc sort data=all_correlations;
    by DAS descending PeakStand_r;
run;

title "Strongest Positive Correlations with Peak Stand by Timepoint";
proc print data=all_correlations (obs=3);
    by DAS;
    var Variable PeakStand_r PeakStand_p;
    format PeakStand_r 6.4 PeakStand_p pvalue6.4;
run;

/* ================================================================= */
/* Trial-specific correlations (optional deeper analysis)            */
/* ================================================================= */

title "Correlations within Each Trial at Each Timepoint";

%macro trial_corr;
    %let trials = 24110 24111 24112;
    
    data trial_correlations;
        length Trial DAS 8 Variable $20 Yield_r 8;
        delete;
    run;
    
    %do t = 1 %to 3;
        %let trial = %scan(&trials, &t);
        
        %let i = 1;
        %let das = %scan(&das_list, &i);
        
        %do %while(&das ne );
            
            data temp_trial;
                set multitemp_clean;
                where Trial = &trial and DAS = &das;
            run;
            
            proc sql noprint;
                select count(*) into :nobs
                from temp_trial;
            quit;
            
            %if &nobs > 5 %then %do;
                
                ods select none;
                proc corr data=temp_trial nosimple;
                    var PlantCount Thresh HA NDVI SAVI GNDVI NDRE ExG ExR;
                    with Yield;
                    ods output PearsonCorr=corr_t&trial._&das;
                run;
                ods select all;
                
                data corr_temp;
                    set corr_t&trial._&das;
                    Trial = &trial;
                    DAS = &das;
                    Variable = Variable;
                    Yield_r = Yield;
                    keep Trial DAS Variable Yield_r;
                run;
                
                data trial_correlations;
                    set trial_correlations corr_temp;
                run;
                
            %end;
            
            %let i = %eval(&i + 1);
            %let das = %scan(&das_list, &i);
        %end;
    %end;
    
    proc datasets library=work nolist;
        delete temp_trial corr_temp corr_t:;
    run;
    quit;
    
%mend trial_corr;

%trial_corr;

proc print data=trial_correlations;
    var Trial DAS Variable Yield_r;
    format Yield_r 6.4;
run;

proc export data=trial_correlations
    outfile="/home/claude/trial_specific_correlations.csv"
    dbms=csv
    replace;
run;

title;
