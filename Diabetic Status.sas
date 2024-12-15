
libname mydata 'W:\MS_1490\';
data work.combined_categorized_data;
    set MYLIB.MS1490; /* Adjust the dataset reference as needed */
  
/* Categorize based only on DIABETES4 */
if DIABETES4 = 1 then HBA1C_Category = 'Non-diabetic';
else if DIABETES4 = 2 then HBA1C_Category = 'Pre-diabetic';
else if DIABETES4 = 3 then HBA1C_Category = 'Diabetic';

keep ID AGE HEIGHT STRAT PSU_ID WEIGHT_FINAL_NORM_OVERALL HBA1C_Category SITE_BKGRD ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM BMI;
run;

data merged_data;
    merge mylib.oncosol_20240313(in=a) /* Cancer incidence dataset from mylib */
          work.combined_categorized_data(in=b); /* Diabetes dataset from work directory */
    by ID; /* Common identifier */
    if a and b; /* Keep only records that appear in both datasets */
run;

/* Step 2: Perform the Cox proportional hazards analysis */
proc phreg data=work.merged_data;
    class HBA1C_Category (ref='Non-diabetic') ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM / param=ref;
	hazardratio HBA1C_Category / diff=ref; /* Hazard ratios for diabetes categories */
    model ONCO_TIME*ONCO_CANCERINC(0) = HBA1C_Category ALCOHOL_USE CIGARETTE_USE AGE US_BORN BMI GPAQ_PAG2008 GENDERNUM / ties=EFRON;
    hazardratio HBA1C_Category / diff=ref;
	 weight WEIGHT_FINAL_NORM_OVERALL;
    output out=work.cox_output;
run;
proc sql noprint;
    select sum(ONCO_CANCERINC) into :total_cancer_events
    from work.merged_data
    where ONCO_CANCERINC = 1;
quit;

proc sql;
    create table work.final_summary as
    select HBA1C_Category, 
           sum(ONCO_TIME) as Person_Years,
           sum(ONCO_CANCERINC) as Cancer_Events, /* Summing cancer incidence */
           (sum(ONCO_CANCERINC) / sum(ONCO_TIME) * 1000) as IR_per_1000_PY,
           (calculated Cancer_Events / sum(ONCO_CANCERINC) * 100) as Cancer_Event_Percent
    from work.merged_data
    group by HBA1C_Category;
quit;
proc print data=work.final_summary label;
    var HBA1C_Category Person_Years Cancer_Events Cancer_Event_Percent IR_per_1000_PY;
    title 'Summary of Cancer Events by Diabetes Category';
run;


