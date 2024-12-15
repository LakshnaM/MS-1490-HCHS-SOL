/* Assigning library references to the datasets */
libname mylib 'W:\MS_1490';

/* Step 1: Categorization based on DIABETES4 and medication variables */
data work.categorized_diabetes;
    set mylib.MS1490;

    /* Categorization using DIABETES4 and medication usage */
    if DIABETES4 = 1 then Combined_Category = 'No Diabetes';
    else if DIABETES4 = 2 and MED_METFORMIN = 0 and MED_INSULIN = 0 and MED_ANTIDIAB = 0 then Combined_Category = 'P No Med';
    else if DIABETES4 = 3 and MED_INSULIN > 0 then Combined_Category = 'D Insulin'; /* Prioritize insulin first */
    else if DIABETES4 = 3 and (MED_METFORMIN > 0 or MED_ANTIDIAB > 0) then Combined_Category = 'D Oral medication';
    else if DIABETES4 = 3 and MED_METFORMIN = 0 and MED_INSULIN = 0 and MED_ANTIDIAB = 0 then Combined_Category = 'D No Med';
    else Combined_Category = 'Unknown'; /* To handle missing or unclassified values */
    
    /* Keep relevant variables */
    keep ID HEIGHT STRAT PSU_ID WEIGHT_FINAL_NORM_OVERALL WEIGHT_FINAL_EXPANDED MED_INSULIN MED_ANTIDIAB MED_METFORMIN
         ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM BMI DIABETES4 Combined_Category AGE;
run;

/* Step 2: Merging the datasets */
data work.merged_data;
    merge mylib.ONCOSOL_20240313 (in=a) /* Assuming ONCOSOL_20240313 has a variable ID to match */
          work.categorized_diabetes (in=b);
    by ID; 
    if a and b; /* Keep only records that appear in both datasets */
run;

/* Step 3: Perform Cox proportional hazards analysis */
proc phreg data=work.merged_data;
    class Combined_Category(ref='No Diabetes') ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM / param=ref;
    model ONCO_TIME*ONCO_CANCERINC(0) = Combined_Category ALCOHOL_USE CIGARETTE_USE AGE US_BORN BMI GPAQ_PAG2008 GENDERNUM / ties=EFRON;
    hazardratio Combined_Category / diff=ref;
	 weight WEIGHT_FINAL_NORM_OVERALL;
    output out=work.cox_output;
run;

/* Step 4: Calculate the total cancer events */
proc sql noprint;
    select sum(ONCO_CANCERINC) into :total_cancer_events
    from work.merged_data
    where ONCO_CANCERINC = 1;
quit;

/* Step 5: Calculate cancer events and person-years by diabetes category */
proc sql;
    create table work.events_summary as
    select Combined_Category,
           count(*) as Cancer_Events,
           sum(ONCO_TIME) as Person_Years
    from work.merged_data
    where ONCO_CANCERINC = 1
    group by Combined_Category;
quit;

/* Step 6: Print final summary of cancer events and person-years */
proc print data=work.events_summary label;
    var Combined_Category Person_Years Cancer_Events;
    title 'Summary of Cancer Events by Diabetes Category';
run;
