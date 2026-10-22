# 🏥 Healthcare Analytics: What 170,000 Patient Records Revealed


> **Source Reference:** [LinkedIn Pulse Article: $13,000 Hospital Stay & 170,000 Patient Records Analysis][cite: 1]

> **Tech Stack:** SQL (MySQL), Relational Database Design, Advanced Analytics (CTEs, Window Functions)

---

## 🔍 Project Overview

Healthcare resource allocation, patient length of stay (LOS), and readmission rates are critical metrics that drive hospital efficiency and patient care quality. This repository contains an end-to-end SQL-driven exploratory data analysis of **170,000+ patient records**[cite: 1].

The primary objective is to uncover operational bottlenecks, evaluate procedure burdens across medical specialties, investigate demographic disparities in lab testing, and map out medication utilization patterns across different age groups.

---

## 🏗️ Database Schema & Architecture

The relational database (`patient`) is structured around two core tables linked via a unique patient identifier (`patient_nbr`):

* **`health` Table:** Tracks encounter-level metrics, including length of stay (`time_in_hospital`), procedure counts, lab procedures, medication counts, admission types, readmission status, and specific medication usages (`metformin`, `glipizide`, `insulin`).
* **`demographics` Table:** Contains patient background attributes, most notably `race` and `age`.

---

## 📊 Exploratory Data Analysis (EDA)

### 1. Hospital Length of Stay Distribution

To understand patient stay durations, encounters were bucketed into rounded intervals, supplemented by an ASCII-style visual distribution using string replication (`rpad`).

```sql
USE patient;

SELECT round(time_in_hospital, 1) as bucket, 
       count(*) as count,
       rpad('', count(*)/1000, '👤') as bar 
FROM health
GROUP BY bucket
ORDER BY bucket;

```

### 2. High-Burden Medical Specialties

Analyzing medical specialties with significant patient volume (>50 cases) and high procedural intensity (average procedures > 2.5) helps identify resource-heavy departments.

```sql
SELECT DISTINCT medical_specialty,
       round(AVG(num_procedures), 1) as avg_procedures, 
       count(*) as count
FROM health
GROUP BY medical_specialty
HAVING count > 50 
       AND avg_procedures > 2.5
ORDER BY avg_procedures DESC;

```

---

## 🔬 Clinical & Demographic Deep Dive

### Lab Procedures Across Demographics

Investigating whether diagnostic intensity varies by patient demographics (`race`).

```sql
SELECT d.race, 
       avg(h.num_lab_procedures) AS avg_lab_procedures
FROM health as h
JOIN demographics as d ON h.patient_nbr = d.patient_nbr
GROUP BY d.race
ORDER BY avg(h.num_lab_procedures);

```

### Procedure Frequency vs. Length of Stay

Categorizing lab procedure volumes into tiers (`Few`, `Average`, `Many`) to analyze their direct correlation with hospital stay duration.

```sql
SELECT ROUND(avg(time_in_hospital), 2) as avg_days_in_hospital,
       CASE 
           WHEN num_lab_procedures >= 0 AND num_lab_procedures < 25 THEN 'Few'
           WHEN num_lab_procedures >= 25 AND num_lab_procedures < 55 THEN 'Average'
           ELSE 'Many'
       END as procedure_frequency
FROM health
GROUP BY procedure_frequency
ORDER BY avg_days_in_hospital;

```

### Targeted Cohort Filtering

Isolating specific emergency admission types (`admission_type_id = 1`) whose length of stay falls below the hospital-wide average.

```sql
SELECT *
FROM patient.health
WHERE admission_type_id = 1
  AND time_in_hospital < (SELECT AVG(time_in_hospital) FROM patient.health);

```

---

## 🛠️ Data Wrangling & Transformation

Data hygiene is paramount in healthcare datasets. Initial datatype audits revealed fields stored as string/text types that required casting or modification for numerical aggregation.

```sql
-- Type Casting and Data Cleansing
ALTER TABLE health MODIFY COLUMN num_medications INT; 
ALTER TABLE health MODIFY COLUMN num_lab_procedures INT; 
ALTER TABLE health MODIFY COLUMN num_procedures INT; 

```

### Patient Summary Generation

Combining relational data across tables to generate natural-language-style structured summaries for high-medication patients.

```sql
SELECT CONCAT(
    'Patient ', health.patient_nbr, ' was ', demographics.race, ' and ',
    (CASE WHEN readmitted = 'NO' 
          THEN 'was not readmitted. They had ' 
          ELSE 'was readmitted. They had ' END),
    num_medications, ' medications and ', num_lab_procedures, ' lab procedures.'
) AS summary
FROM patient.health
INNER JOIN patient.demographics ON demographics.patient_nbr = health.patient_nbr
ORDER BY num_medications DESC, num_lab_procedures DESC 
LIMIT 50;

```

---

## 🚀 Advanced Analytics: CTEs & Window Functions

### Unpivoting Medication Usage

To analyze medication trends collectively rather than across isolated columns, a Common Table Expression (CTE) and `UNION ALL` were used to unpivot columns like `metformin`, `glipizide`, and `insulin`.

### Ranking Medication Popularity by Age Group

Applying window functions (`RANK()` partitioned by age) to determine the top prescribed medications across different age brackets.

```sql
WITH long_health_cte AS (
    SELECT patient_nbr, 'metformin' AS medication, metformin AS med_usage FROM patient.health
    UNION ALL
    SELECT patient_nbr, 'glipizide' AS medication, glipizide AS med_usage FROM patient.health
    UNION ALL
    SELECT patient_nbr, 'insulin' AS medication, insulin AS med_usage FROM patient.health
)
SELECT age,
       medication,
       COUNT(*) AS encounter_use_count,
       RANK() OVER (PARTITION BY age ORDER BY COUNT(*) DESC) AS medication_rank
FROM long_health_cte
JOIN patient.demographics ON long_health_cte.patient_nbr = demographics.patient_nbr
WHERE med_usage NOT IN ('No')
GROUP BY medication, age
ORDER BY age, medication_rank;

```

---

## 💡 Key Insights & Strategic Recommendations

* **Length of Stay Clustering:** Most inpatient stays cluster tightly within specific day ranges, highlighting predictable discharge windows that can be optimized using automated bed-turnover scheduling.
* **Procedural Load & Specialties:** High-intensity surgical and specialized departments show clear spikes in resource utilization, which can inform nurse-to-patient staffing ratios.
* **Medication Management:** Insulin and metformin dominate diabetic treatment protocols across nearly all age brackets, making glycemic management optimization a top target for reducing readmission rates.

---


## 📂 Repository Structure

```text
📦 healthcare_analytics_with_SQL
 ┣ 📜 SQL_analysis_healthcare_project.sql  # Main script containing comprehensive project queries and analysis
 ┣ 📜 demographics.sql                     # Initial demographics dataset given
 ┣ 📜 health.sql                           # Initial health dataset given
 ┗ 📜 README.md                            # Project overview, objectives, and documentation
