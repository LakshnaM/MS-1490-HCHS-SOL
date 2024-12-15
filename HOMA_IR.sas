libname mylib 'W:\MS_1490';

data work.homa_ir_categorized;
    set MYLIB.MS1490;

    /* Categorization based on HOMA_IR */
	if  diabetes4 = 1 then HOMA_IR_Category = 'No Diabetes';
    else if HOMA_IR <= 1.9 and diabetes4 = 2 then HOMA_IR_Category = 'pre IR ≤ 1.9';
    else if HOMA_IR > 1.9 and HOMA_IR <= 2.9 and diabetes4 = 2 then HOMA_IR_Category = 'pre IR 2.0 - 2.9';
    else if HOMA_IR > 2.9 and diabetes4 = 2 then HOMA_IR_Category = 'pre IR ≥ 3.0';
	else if HOMA_IR <= 1.9 and diabetes4 = 3 then HOMA_IR_Category = 'dia IR ≤ 1.9';
	else if HOMA_IR > 1.9 and HOMA_IR <= 2.9 and diabetes4 = 3 then HOMA_IR_Category = 'Dia IR 2.0 - 2.9';
	else if HOMA_IR > 2.9 and diabetes4 = 3 then HOMA_IR_Category = 'Dia IR ≥ 3.0';
    else HOMA_IR_Category = 'Unknown'; /* Handle missing or undefined values */

	/* Keep relevant variables */
    keep ID HEIGHT STRAT PSU_ID WEIGHT_FINAL_NORM_OVERALL WEIGHT_FINAL_EXPANDED MED_INSULIN MED_ANTIDIAB MED_METFORMIN
         ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM BMI DIABETES4 Combined_Category AGE HOMA_IR HOMA_IR_Category;
run;
proc freq data=work.homa_ir_categorized;
    tables HOMA_IR_Category;
    title 'Frequency Distribution of HOMA_IR Categories';
run;


/* Step 2: Merging the HOMA-IR categorized dataset with the cancer dataset */
data work.merged_data;
    merge mylib.ONCOSOL_20240313 (in=a) /* Assuming ONCOSOL_20240313 has a variable ID to match */
          work.homa_ir_categorized (in=b);
    by ID; 
    if a and b; /* Keep only records that appear in both datasets */
run;

/* Step 3: Perform Cox Proportional Hazards Analysis */
proc phreg data=work.merged_data;
    class HOMA_IR_Category(ref='No Diabetes') ALCOHOL_USE CIGARETTE_USE US_BORN GPAQ_PAG2008 GENDERNUM / param=ref;
    model ONCO_TIME*ONCO_CANCERINC(0) = HOMA_IR_Category ALCOHOL_USE CIGARETTE_USE AGE US_BORN BMI GPAQ_PAG2008 GENDERNUM / ties=EFRON;
    hazardratio HOMA_IR_Category / diff=ref;
  output out=work.cox_output;
run;


/* Step 4: Calculate total cancer events */
proc sql noprint;
    select sum(ONCO_CANCERINC) into :total_cancer_events
    from work.merged_data
    where ONCO_CANCERINC = 1;
quit;

/* Step 5: Calculate events and incidence rates by HOMA-IR category */
proc sql;
    create table work.events_summary as
    select HOMA_IR_Category,
           count(*) as Cancer_Events,
           sum(ONCO_TIME) as Person_Years,
           (count(*) / sum(ONCO_TIME)) * 1000 as IR_per_1000
    from work.merged_data
    where ONCO_CANCERINC = 1
    group by HOMA_IR_Category;
quit;

/* Step 6: Calculate incidence rates per 1000 person-years */
data work.incidence_rates;
    set work.events_summary;
    IR_per_1000_PY = (Cancer_Events / Person_Years) * 1000;
run;

/* Step 7: Display final summary */
proc print data=work.incidence_rates label;
    var HOMA_IR_Category Person_Years Cancer_Events IR_per_1000_PY;
    title 'Summary of Cancer Events by HOMA-IR Category';
run;



