CREATE DATABASE hospital_analytics;
USE hospital_analytics;

SELECT COUNT(*) FROM patient_master_clean;
SELECT COUNT(*) FROM insurance_claims_clean;
SELECT COUNT(*) FROM hospital_operations_clean;
SELECT COUNT(*) FROM previous_admission_clean;
SELECT COUNT(*) FROM treatment_summary_clean;

CREATE VIEW previous_admission_count AS
SELECT 
    Patient_ID,
    COUNT(*) AS Previous_Admissions
FROM previous_admission_clean
GROUP BY Patient_ID;

CREATE VIEW patient_analytics_view AS
SELECT 
    p.Patient_ID,
    p.Age,
    p.Age_band,
    p.Gender_clean,
    p.Department,
    p.`Total Bill` AS Total_Bill,
    p.LOS,
    
    CASE 
        WHEN p.Readmitted_30_Days = 'Yes' THEN 1
        ELSE 0
    END AS Readmitted_30_Days,
    
    COALESCE(pa.Previous_Admissions,0) AS Previous_Admissions,
    
    CAST(t.Total_Treatment_Cost AS DECIMAL(10,2)) AS Total_Treatment_Cost

FROM patient_master_clean p
LEFT JOIN previous_admission_count pa 
    ON p.Patient_ID = pa.Patient_ID
LEFT JOIN treatment_summary_clean t 
    ON p.Patient_ID = t.Patient_ID;
    
    
    
    
    SELECT 
ROUND(
    SUM(Readmitted_30_Days) * 100.0 / COUNT(*),
2) AS Readmission_Rate_Percentage
FROM patient_analytics_view;

SELECT 
    Department,
    COUNT(*) AS Total_Patients,
    SUM(Readmitted_30_Days) AS Readmitted_Patients,
    ROUND(SUM(Readmitted_30_Days) * 100.0 / COUNT(*),2) AS Readmission_Rate_Percentage
FROM patient_analytics_view
GROUP BY Department
ORDER BY Readmission_Rate_Percentage DESC;

SELECT 
    Department,
    ROUND(AVG(LOS),2) AS Avg_Length_of_Stay
FROM patient_analytics_view
GROUP BY Department
ORDER BY Avg_Length_of_Stay DESC;

SELECT 
    Age_band,
    COUNT(*) AS Total_Patients,
    SUM(Readmitted_30_Days) AS Readmitted_Count,
    ROUND(SUM(Readmitted_30_Days) * 100.0 / COUNT(*),2) AS Readmission_Rate
FROM patient_analytics_view
GROUP BY Age_band
ORDER BY Readmission_Rate DESC;

SELECT 
    Department,
    ROUND(SUM(Total_Bill),2) AS Total_Revenue
FROM patient_analytics_view
GROUP BY Department
ORDER BY Total_Revenue DESC;

SELECT 
    ROUND(SUM(Claim_Amount),2) AS Revenue_Lost
FROM insurance_claims_clean
WHERE Claim_Status = 'Rejected';

SELECT 
ROUND(
    SUM(CASE WHEN Claim_Status = 'Approved' THEN 1 ELSE 0 END) 
    * 100.0 / COUNT(*),
2) AS Claim_Approval_Rate
FROM insurance_claims_clean;

SELECT 
    Claim_Status,
    COUNT(*) AS Claim_Count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM insurance_claims_clean),2) AS Percentage
FROM insurance_claims_clean
GROUP BY Claim_Status
ORDER BY Claim_Count DESC;

DESCRIBE insurance_claims_clean;

SELECT 
    Payer_Name,
    ROUND(AVG(
        DATEDIFF(
            STR_TO_DATE(Claim_Settled_Date, '%d-%m-%Y'),
            STR_TO_DATE(Claim_Submitted_Date, '%d-%m-%Y')
        )
    ),2) AS Avg_Settlement_Days
FROM insurance_claims_clean
WHERE Claim_Status = 'Approved'
AND Claim_Settled_Date IS NOT NULL
AND Payer_Name IS NOT NULL
AND Payer_Name <> ''
AND Payer_Name <> 'Self-Pay'
GROUP BY Payer_Name
ORDER BY Avg_Settlement_Days DESC;

SELECT 
    Department,
    ROUND(SUM(Total_Bill),2) AS Total_Revenue
FROM patient_analytics_view
GROUP BY Department
ORDER BY Total_Revenue DESC
LIMIT 5;

    SELECT 
    ROUND(AVG(Total_Treatment_Cost),2) AS Avg_Treatment_Cost
FROM patient_analytics_view;

SELECT 
    ROUND(AVG(Total_Bill),2) AS Avg_Total_Bill
FROM patient_analytics_view;

SELECT 
ROUND(
    (AVG(Total_Bill) - AVG(Total_Treatment_Cost)) 
    * 100.0 / AVG(Total_Bill)
,2) AS Profit_Margin_Percentage
FROM patient_analytics_view;

SELECT Admission_Date
FROM patient_master_clean
LIMIT 5;

SELECT 
STR_TO_DATE(Admission_Date, '%d-%m-%Y')
FROM patient_master_clean
LIMIT 5;

SELECT 
YEAR(STR_TO_DATE(Admission_Date, '%d-%m-%Y')) AS Year,
MONTH(STR_TO_DATE(Admission_Date, '%d-%m-%Y')) AS Month,
COUNT(*) AS Total_Patients,
SUM(CASE WHEN Readmitted_30_Days = 'Yes' THEN 1 ELSE 0 END) AS Readmitted_Count,
ROUND(
    SUM(CASE WHEN Readmitted_30_Days = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*)
,2) AS Readmission_Rate
FROM patient_master_clean
GROUP BY 
YEAR(STR_TO_DATE(Admission_Date, '%d-%m-%Y')),
MONTH(STR_TO_DATE(Admission_Date, '%d-%m-%Y'))
ORDER BY 
Year, Month;

SELECT 
YEAR(STR_TO_DATE(Admission_Date, '%d-%m-%Y')) AS Year,
MONTH(STR_TO_DATE(Admission_Date, '%d-%m-%Y')) AS Month,
ROUND(SUM(`Total Bill`),2) AS Monthly_Revenue
FROM patient_master_clean
GROUP BY 
YEAR(STR_TO_DATE(Admission_Date, '%d-%m-%Y')),
MONTH(STR_TO_DATE(Admission_Date, '%d-%m-%Y'))
ORDER BY 
Year, Month;

SELECT 
YEAR(STR_TO_DATE(Date, '%d-%m-%Y')) AS Year,
MONTH(STR_TO_DATE(Date, '%d-%m-%Y')) AS Month,
ROUND(AVG(Occupied_Beds * 100.0 / Available_Beds),2) AS Avg_Occupancy_Percentage
FROM hospital_operations_clean
GROUP BY 
YEAR(STR_TO_DATE(Date, '%d-%m-%Y')),
MONTH(STR_TO_DATE(Date, '%d-%m-%Y'))
ORDER BY 
Year, Month;

SELECT 
    Patient_ID,
    Age,
    Age_band,
    LOS,
    Previous_Admissions,
    Readmitted_30_Days
FROM patient_analytics_view
WHERE 
    Readmitted_30_Days = 1
    AND Previous_Admissions >= 2
    AND LOS > 10
ORDER BY Previous_Admissions DESC, LOS DESC
LIMIT 20;

SELECT DISTINCT
    Patient_ID,
    Age,
    Age_band,
    LOS,
    Previous_Admissions,
    Readmitted_30_Days
FROM patient_analytics_view
WHERE 
    Readmitted_30_Days = 1
    AND Previous_Admissions >= 2
    AND LOS > 10
ORDER BY Previous_Admissions DESC, LOS DESC
LIMIT 20;