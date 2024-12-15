/* Assigning library references to the datasets */
libname mylib 'W:\MS_1490';
/* Step 1: Correct Categorization of HbA1c and Diabetes_SELF */
data work.categorized_hba1c;
    set mylib.MS1490;

    /* Categorization using both DIABETES4 and HBA1C_SI */
if DIABETES4 = 1 then DSHBA_CAT = 'Non-diabetic';
else if HBA1C_SI < 39 and (Diabetes4=1 or DIABETES4 = 2 or DIABETES4 = 3) then DSHBA_CAT = '<5.9';
    else if HBA1C_SI >= 39 and HBA1C_SI < 48 and (Diabetes4=1 or DIABETES4 = 2 or DIABETES4 = 3) then DSHBA_CAT = '5.9-6.8';
    else if HBA1C_SI >= 48 and (Diabetes4=1 or DIABETES4 = 2 or DIABETES4 = 3) then DSHBA_CAT = '>6.9';
   
    
    /* Keep relevant variables */
    keep ID DIABETES4 DSHBA_CAT WEIGHT_FINAL_NORM_OVERALL AGE GENDERNUM BMI GPAQ_PAG2008 ALCOHOL_USE CIGARETTE_USE US_BORN;
run;
proc freq data=work.categorized_hba1c;
    tables DSHBA_CAT;
    title 'Frequency Distribution of Diabetes Duration Categories';
run;

/* Step 2: Merge the datasets */
data work.merged_data;
    merge mylib.ONCOSOL_20240313 (in=a) work.categorized_hba1c (in=b); 
    by ID; 
    if a and b; 
run;
proc phreg data=work.merged_data;
    class DSHBA_CAT(ref='Non-diabetic') ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM / param=ref;
    model ONCO_TIME*ONCO_CANCERINC(0) = DSHBA_CAT ALCOHOL_USE CIGARETTE_USE AGE US_BORN BMI GPAQ_PAG2008 GENDERNUM / ties=EFRON;
    hazardratio DSHBA_CAT / diff=ref;
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
    select DSHBA_CAT, 
           sum(ONCO_TIME) as Person_Years,
           sum(ONCO_CANCERINC) as Cancer_Events, /* Summing cancer incidence */
           (sum(ONCO_CANCERINC) / sum(ONCO_TIME) * 1000) as IR_per_1000_PY,
           (calculated Cancer_Events / sum(ONCO_CANCERINC) * 100) as Cancer_Event_Percent
    from work.merged_data
    group by DSHBA_CAT;
quit;
proc print data=work.final_summary label;
    var DSHBA_CAT Person_Years Cancer_Events Cancer_Event_Percent IR_per_1000_PY;
    title 'Summary of Cancer Events by Diabetes Category';
run;

