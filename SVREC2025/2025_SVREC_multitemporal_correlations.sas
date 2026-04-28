/* ================================================================= */
/* 2025 SVREC Multitemporal Correlation Analysis                     */
/* Correlations between VIs, HA, Thresh, Plant Count vs Yield & Peak Stand */
/* ================================================================= */

/* Import the dataset */
proc import datafile="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\SVREC2025\2025 Multitemporal VI data + yield.csv"
    out=multitemp_2025
    dbms=csv
    replace;
    getnames=yes;
    guessingrows=max;
run;

/* Clean variable names and prepare data */
data multitemp_clean;
    set multitemp_2025;
    
    /* Use simpler variable names */
    PlotID = id;
    PlantCount = "PLT COUNT"n;
    Thresh = THRESH_mean;
    HA = "HA Mean"n;
    NDVI = NDVI_Mean;
    GNDVI = gNDVI_Mean;
    NDRE = NDRE_mean;
    ExG = ExG_Mean;
    ExR = ExR_Mean;
    
    /* Keep only necessary variables */
    keep Trial DAS PlotID Yield PeakStand 
         PlantCount Thresh HA NDVI GNDVI NDRE ExG ExR;
    
    /* Remove rows where Yield or PeakStand are missing */
    if nmiss(Yield, PeakStand) = 0;
run;

/* Macro to calculate correlations for each trial and timepoint */
%macro corr_by_trial_das;
    /* Create output dataset to store all results */
    data all_correlations;
        length Trial 8 DAS 8 Variable $20 Yield_r Yield_p PeakStand_r PeakStand_p 8;
        delete;
    run;
    
    /* Get unique trials */
    proc sql noprint;
        select distinct Trial into :trial_list separated by ' '
        from multitemp_clean
        order by Trial;
    quit;
    
    /* Loop through each trial */
    %let t = 1;
    %let trial = %scan(&trial_list, &t);
    
    %do %while(&trial ne );
        
        /* Get DAS values for this trial */
        proc sql noprint;
            select distinct DAS into :das_list separated by ' '
            from multitemp_clean
            where Trial = &trial
            order by DAS;
        quit;
        
        /* Loop through each DAS within trial */
        %let i = 1;
        %let das = %scan(&das_list, &i);
        
        %do %while(&das ne );
            
            /* Filter data for current trial and DAS */
            data temp_trial_das;
                set multitemp_clean;
                where Trial = &trial and DAS = &das;
            run;
            
            /* Check if data exists */
            proc sql noprint;
                select count(*) into :nobs
                from temp_trial_das;
            quit;
            
            %if &nobs > 0 %then %do;
                
                title "Correlation Analysis - Trial &trial, DAS = &das";
                
                /* Calculate correlations with Yield and PeakStand */
                ods select none;
                proc corr data=temp_trial_das nosimple;
                    var Yield PeakStand;
                    with PlantCount Thresh HA NDVI GNDVI NDRE ExG ExR;
                    ods output PearsonCorr=corr_&trial._&das;
                run;
                ods select all;
                
                /* Process correlations - transpose to get predictors as rows */
                data corr_temp;
                    set corr_&trial._&das;
                    length Variable $20;
                    Trial = &trial;
                    DAS = &das;
                    
                    /* Extract correlations for each predictor */
                    if _N_ = 1 then Variable = "PlantCount";
                    else if _N_ = 2 then Variable = "Thresh";
                    else if _N_ = 3 then Variable = "HA";
                    else if _N_ = 4 then Variable = "NDVI";
                    else if _N_ = 5 then Variable = "GNDVI";
                    else if _N_ = 6 then Variable = "NDRE";
                    else if _N_ = 7 then Variable = "ExG";
                    else if _N_ = 8 then Variable = "ExR";
                    
                    Yield_r = Yield;
                    Yield_p = PYield;
                    PeakStand_r = PeakStand;
                    PeakStand_p = PPeakStand;
                    
                    keep Trial DAS Variable Yield_r Yield_p PeakStand_r PeakStand_p;
                run;
                
                /* Append to master dataset */
                data all_correlations;
                    set all_correlations corr_temp;
                run;
                
            %end;
            
            %let i = %eval(&i + 1);
            %let das = %scan(&das_list, &i);
        %end;
        
        %let t = %eval(&t + 1);
        %let trial = %scan(&trial_list, &t);
    %end;
    
    /* Clean up temporary datasets */
    proc datasets library=work nolist;
        delete temp_trial_das corr_temp corr_:;
    run;
    quit;
    
%mend corr_by_trial_das;

/* Execute the macro */
%corr_by_trial_das;

/* ================================================================= */
/* Format and display comprehensive results table by trial          */
/* ================================================================= */

title "2025 SVREC - Comprehensive Correlation Results by Trial and Timepoint";
proc print data=all_correlations noobs label;
    var Trial DAS Variable Yield_r Yield_p PeakStand_r PeakStand_p;
    format Yield_r PeakStand_r 6.4 Yield_p PeakStand_p pvalue6.4;
    label Trial = "Trial"
          DAS = "Days After Sowing"
          Variable = "Predictor Variable"
          Yield_r = "Correlation with Yield"
          Yield_p = "P-value (Yield)"
          PeakStand_r = "Correlation with Peak Stand"
          PeakStand_p = "P-value (Peak Stand)";
run;

/* Print results by trial for easier viewing */
proc sort data=all_correlations;
    by Trial DAS Variable;
run;

title "2025 SVREC - Correlation Results by Trial";
proc print data=all_correlations noobs;
    by Trial;
    var DAS Variable Yield_r Yield_p PeakStand_r PeakStand_p;
    format Yield_r PeakStand_r 6.4 Yield_p PeakStand_p pvalue6.4;
run;

/* ================================================================= */
/* Export results to CSV                                             */
/* ================================================================= */

proc export data=all_correlations
    outfile="C:\Users\mason\OneDrive\Desktop\MSc\Harvestable Area Paper\2025 HA data analysis\SVREC2025\2025_SVREC_correlations_by_trial_and_timepoint.csv"
    dbms=csv
    replace;
run;

/* ================================================================= */
/* Create summary statistics by Trial and DAS                        */
/* ================================================================= */

proc means data=multitemp_clean n mean std min max;
    class Trial DAS;
    var Yield PeakStand PlantCount Thresh HA NDVI GNDVI NDRE ExG ExR;
    title "2025 SVREC - Descriptive Statistics by Trial and Timepoint";
run;

/* ================================================================= */
/* Correlation heatmap visualization data preparation by trial      */
/* ================================================================= */

/* Create separate datasets for each trial */
%macro create_trial_heatmaps;
    
    /* Get list of trials dynamically */
    proc sql noprint;
        select distinct Trial into :trial_list separated by ' '
        from all_correlations
        order by Trial;
    quit;
    
    %let num_trials = %sysfunc(countw(&trial_list));
    
    %do t = 1 %to &num_trials;
        %let trial = %scan(&trial_list, &t);
        
        /* Yield correlations for this trial */
        data trial_&trial._data;
            set all_correlations;
            where Trial = &trial;
        run;
        
        proc transpose data=trial_&trial._data out=yield_heatmap_&trial prefix=DAS_;
            by Variable;
            id DAS;
            var Yield_r;
        run;
        
        title "2025 SVREC - Correlation Matrix: Variables vs Yield by DAS - Trial &trial";
        proc print data=yield_heatmap_&trial noobs;
        run;
        
        /* PeakStand correlations for this trial */
        proc transpose data=trial_&trial._data out=peak_heatmap_&trial prefix=DAS_;
            by Variable;
            id DAS;
            var PeakStand_r;
        run;
        
        title "2025 SVREC - Correlation Matrix: Variables vs Peak Stand by DAS - Trial &trial";
        proc print data=peak_heatmap_&trial noobs;
        run;
    %end;
    
    /* Clean up */
    proc datasets library=work nolist;
        delete trial:_data;
    run;
    quit;
    
%mend create_trial_heatmaps;

%create_trial_heatmaps;

/* ================================================================= */
/* Statistical significance summary by trial                         */
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

title "2025 SVREC - Correlation Results with Significance Indicators";
title2 "*** p<0.001, ** p<0.01, * p<0.05, ns = not significant";
proc print data=significance_summary noobs;
    by Trial;
    var DAS Variable Yield_r Yield_sig PeakStand_r Peak_sig;
    format Yield_r PeakStand_r 6.4;
run;

/* ================================================================= */
/* Identify strongest correlations at each trial and timepoint      */
/* ================================================================= */

proc sort data=all_correlations;
    by Trial DAS descending Yield_r;
run;

title "2025 SVREC - Strongest Positive Correlations with Yield by Trial and Timepoint";
proc print data=all_correlations;
    by Trial DAS;
    var Variable Yield_r Yield_p;
    format Yield_r 6.4 Yield_p pvalue6.4;
    where Yield_r > 0;
    id Variable;
run;

proc sort data=all_correlations;
    by Trial DAS descending PeakStand_r;
run;

title "2025 SVREC - Strongest Positive Correlations with Peak Stand by Trial and Timepoint";
proc print data=all_correlations;
    by Trial DAS;
    var Variable PeakStand_r PeakStand_p;
    format PeakStand_r 6.4 PeakStand_p pvalue6.4;
    where PeakStand_r > 0;
    id Variable;
run;

/* ================================================================= */
/* Summary: Count of significant correlations by trial              */
/* ================================================================= */

proc sql;
    create table sig_count as
    select Trial, DAS,
           sum(case when Yield_p < 0.05 then 1 else 0 end) as Sig_Yield_Count,
           sum(case when PeakStand_p < 0.05 then 1 else 0 end) as Sig_Peak_Count
    from significance_summary
    group by Trial, DAS
    order by Trial, DAS;
quit;

title "2025 SVREC - Count of Significant Correlations (p<0.05) by Trial and Timepoint";
proc print data=sig_count noobs;
    var Trial DAS Sig_Yield_Count Sig_Peak_Count;
run;

title;
