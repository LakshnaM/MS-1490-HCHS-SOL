libname mylib 'W:\MS_1490';

/* Step 1: Calculating Duration of Diabetes */
data work.duration_diabetes;
    set MYLIB.MS1490;

    /* Calculate duration of diabetes */
    if not missing(MHEA16A) then Diabetes_Duration = AGE - MHEA16A;
    else Diabetes_Duration = .; /* Handle missing values */

 if DIABETES4 = 1 then Combined_Category = 'No Diabetes';
else if Diabetes_Duration <= 10 and DIABETES4 = 2 then Combined_Category = 'P ≤ 10 years';
else if Diabetes_Duration > 10 and DIABETES4 = 2 then Combined_Category = 'P ≥ 10 years';
else if Diabetes_Duration <= 10 and DIABETES4 = 3 then Combined_Category = 'D ≤ 10 years';    
else if Diabetes_Duration > 10 and DIABETES4 = 3 then Combined_Category = 'D ≥ 10 years';     
    /* Keep relevant variables */
    keep ID AGE MHEA16A Diabetes_Duration DIABETES3 Combined_Category ID HEIGHT STRAT PSU_ID WEIGHT_FINAL_NORM_OVERALL WEIGHT_FINAL_EXPANDED MED_INSULIN MED_ANTIDIAB MED_METFORMIN
         ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM BMI DIABETES4 Combined_Category AGE;
run;

proc freq data=work.duration_diabetes;
    tables Combined_Category;
    title 'Frequency Distribution of Diabetes Duration Categories';
run;


/* Step 2: Merging the datasets with the cancer dataset */
data work.merged_data;
    merge mylib.ONCOSOL_20240313 (in=a) /* Assuming ONCOSOL_20240313 has a variable ID to match */
          work.duration_diabetes (in=b);
    by ID; 
    if a and b; /* Keep only records that appear in both datasets */
run;

/* Step 3: Perform Cox Proportional Hazards Analysis */
proc phreg data=work.merged_data;
    class Combined_Category(ref='No Diabetes') ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM / param=ref;
    model ONCO_TIME*ONCO_CANCERINC(0) = Combined_Category ALCOHOL_USE CIGARETTE_USE AGE US_BORN BMI GPAQ_PAG2008 GENDERNUM / ties=EFRON;
    hazardratio Combined_Category / diff=ref;
    weight WEIGHT_FINAL_NORM_OVERALL;
    output out=work.cox_output;
run;

/* Step 4: Calculate total cancer events */
proc sql noprint;
    select sum(ONCO_CANCERINC) into :total_cancer_events
    from work.merged_data
    where ONCO_CANCERINC = 1;
quit;

/* Step 5: Calculate events and incidence rates by Combined_Category */
proc sql;
    create table work.events_summary as
    select Combined_Category,
           count(*) as Cancer_Events,
           sum(ONCO_TIME) as Person_Years,
           (count(*) / sum(ONCO_TIME)) * 1000 as IR_per_1000
    from work.merged_data
    where ONCO_CANCERINC = 1
    group by Combined_Category;
quit;

/* Step 6: Calculate incidence rates per 1000 person-years */
data work.incidence_rates;
    set work.events_summary;
    IR_per_1000_PY = (Cancer_Events / Person_Years) * 1000;
run;

/* Step 7: Display final summary */
proc print data=work.incidence_rates label;
    var Combined_Category Person_Years Cancer_Events IR_per_1000_PY;
    title 'Summary of Cancer Events by Diabetes Category';
run;
