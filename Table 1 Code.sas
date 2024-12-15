libname MYDATA 'W:\MS_1490\';
proc contents data=MYDATA.dataset_name;
run;

data work.combined_categorized_data;
    set MYDATA.MS1490; /* Adjust the dataset reference as needed */
    
    /* Categorization of Diabetes based on Diabetes3 variable */
    if Diabetes3 = 1 then Diabetes_Formatted = 'No';
    else if Diabetes3 = 2 then Diabetes_Formatted = 'Pre-diabetes';
    else if Diabetes3 = 3 then Diabetes_Formatted = 'Diabetes';
    else Diabetes_Formatted = 'Missing'; /* Handles missing values */

    /* Categorization of US Born Status */
    if US_BORN = 1 then US_Born_Status = 'US Born';
    else if US_BORN = 0 then US_Born_Status = 'Not US Born';
    else US_Born_Status = 'Unknown'; /* For missing/undefined values */

    /* Categorization of BMI according to WHO standards */
    /* Categorization of BMI */
if BMI <= 25.0 then BMI_Category = '≤25.0';
else if BMI <= 30.0 then BMI_Category = '25.1-30';
else BMI_Category = '≥30';

    /* Categorization of Heritage Group (Bkgrd1) */
    if Bkgrd1 = 0 then Heritage_Group = 'Dominican';
    else if Bkgrd1 = 1 then Heritage_Group = 'Central American';
    else if Bkgrd1 = 2 then Heritage_Group = 'Cuban';
    else if Bkgrd1 = 3 then Heritage_Group = 'Mexican';
    else if Bkgrd1 = 4 then Heritage_Group = 'Puerto Rican';
    else if Bkgrd1 = 5 then Heritage_Group = 'South American';
    else if Bkgrd1 = 6 then Heritage_Group = 'More than one heritage';
    else if Bkgrd1 = 7 then Heritage_Group = 'Other';
    else Heritage_Group = 'Unknown'; /* For missing/undefined values */

    /* Categorization of Education Level */
    if EDUCATION_C4 = 1 then Education_Level = 'No high school';
    else if EDUCATION_C4 = 2 then Education_Level = 'at High school dip/GED';
    else if EDUCATION_C4 = 3 then Education_Level = 'High school';
    else if EDUCATION_C4 = 4 then Education_Level = 'College Graduate or Higher';
    else Education_Level = 'Unknown'; /* For missing/undefined values */

    /* Categorization of Physical Activity */
    if GPAQ_PAG2008 = 1 then Physical_Activity = 'Inactive';
    else if GPAQ_PAG2008 = 2 then Physical_Activity = 'Low Activity';
    else if GPAQ_PAG2008 = 3 then Physical_Activity = 'Moderate Activity';
    else if GPAQ_PAG2008 = 4 then Physical_Activity = 'High Activity';
    else Physical_Activity = 'Unknown'; /* For missing/undefined values */

    /* Categorization of Age */
    if AGE < 45 then Age_Category = 'Below 45';
    else if AGE <= 64 then Age_Category = '46 to 64';
    else Age_Category = '65 and above';

    /* Categorization of Sex */
    if GENDERNUM = 0 then Sex = 'Female';
    else if GENDERNUM = 1 then Sex = 'Male';
    else Sex = 'Unknown'; /* For missing or undefined values */

    /* Categorization for Cigarette Use */
    if CIGARETTE_USE = 1 then Cigarette_Use_Formatted = 'Never';
    else if CIGARETTE_USE = 2 then Cigarette_Use_Formatted = 'Former';
    else if CIGARETTE_USE = 3 then Cigarette_Use_Formatted = 'Current';
    else Cigarette_Use_Formatted = 'Missing'; /* Handles missing values */

    /* Categorization for Alcohol Use */
    if ALCOHOL_USE = 1 then Alcohol_Use_Formatted = 'Never';
    else if ALCOHOL_USE = 2 then Alcohol_Use_Formatted = 'Former';
    else if ALCOHOL_USE = 3 then Alcohol_Use_Formatted = 'Current';
    else Alcohol_Use_Formatted = 'Missing'; /* Handles missing values */

    /* Categorization of HBA1C_SI based on ADA standards */
    if HBA1C_SI < 39 then HBA1C_Category = 'Normal'; 
    else if HBA1C_SI >= 39 and HBA1C_SI < 48 then HBA1C_Category = 'Pre-diabetes';
    else if HBA1C_SI >= 48 then HBA1C_Category = 'Diabetes';
    else HBA1C_Category = 'Missing'; /* Include this line if there could be missing values */

    /* Categorization of Diabetic Medication */
    if (MED_ANTIDIAB = 0 or missing(MED_ANTIDIAB)) and 
       (MED_INSULIN = 0 or missing(MED_INSULIN)) and 
       (MED_METFORMIN = 0 or missing(MED_METFORMIN)) 
       then Medication_Category = 'No Medication';
    else if MED_INSULIN > 0 
       then Medication_Category = 'Insulin Only';
    else if MED_METFORMIN > 0 or MED_ANTIDIAB > 0
       then Medication_Category = 'Oral Medication Only';

    /* Categorize HOMA_IR */
    if HOMA_IR >= 1.0 and HOMA_IR < 1.9 then HOMA_IR_Category = 'Normal';
    else if HOMA_IR >= 1.9 and HOMA_IR < 2.9 then HOMA_IR_Category = 'Elevated or Early Insulin Resistance';
    else if HOMA_IR >= 2.9 then HOMA_IR_Category = 'Significant Insulin Resistance';
    else HOMA_IR_Category = 'Not Classified'; /* Use this line to handle values below 1.0 or missing */

    /* Apply formats for readability */
    format BMI_Category $15. Medication_Category $20. HBA1C_Category $15. Age_Category $15.
           Sex $7. Physical_Activity $20. Heritage_Group $30. Education_Level $30. Cigarette_Use Alcohol_Use;


    /* Keep only necessary variables */
keep ID HEIGHT STRAT PSU_ID WEIGHT_FINAL_NORM_OVERALL WEIGHT_FINAL_EXPANDED 
Diabetes_Formatted US_Born_Status BMI_Category Education_Level 
Physical_Activity Age_Category Sex HBA1C_Category Medication_Category 
Heritage_Group Cigarette_Use_Formatted Alcohol_Use_Formatted HOMA_IR HOMA_IR_Category;
run; 

proc contents data=work.combined_categorized_data; 
run; 

/* Weighted frequency analysis using PROC SURVEYFREQ */
proc surveyfreq data=work.combined_categorized_data;
    table Sex*Diabetes_Formatted 
          US_Born_Status*Diabetes_Formatted
          Education_Level*Diabetes_Formatted
          Physical_Activity*Diabetes_Formatted 
          Cigarette_Use_Formatted*Diabetes_Formatted
          Alcohol_Use_Formatted*Diabetes_Formatted 
          Medication_Category*Diabetes_Formatted
          HBA1C_Category*Diabetes_Formatted
          BMI_Category*Diabetes_Formatted 
          Heritage_Group*Diabetes_Formatted 
          age_category*Diabetes_Formatted 
          HOMA_IR_Category*Diabetes_Formatted;
    weight WEIGHT_FINAL_NORM_OVERALL; /* Use the correct weight variable */
    strata STRAT; /* Adjust if your stratification variable is named differently */
    cluster PSU_ID; /* Adjust if your PSU variable is named differently */
    title "Weighted Frequency Tables by Formatted Diabetes Status Including HbA1c Categories";
run;
