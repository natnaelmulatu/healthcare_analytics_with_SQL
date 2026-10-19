USE patient;

SELECT round(time_in_hospital, 1) as bucket, 
count(*) as count,
rpad('', count(*)/1000, '👤') as bar 
FROM health
GROUP BY bucket
ORDER BY bucket;

----------------------------------
--- Looking at top procedures
----------------------------------
SELECT DISTINCT medical_specialty,
round(AVG(num_procedures), 1) as avg_procedures, 
count(*) as count
FROM health
GROUP BY medical_specialty
HAVING count > 50
and avg_procedures > 2.5
ORDER BY avg_procedures DESC;


SELECT 
	d.race, 
    avg(h.num_lab_procedures)
FROM health as h
JOIN demographics as d on h.patient_nbr = d.patient_nbr
group by d.race
order by avg(h.num_lab_procedures);


SELECT 
ROUND(avg(time_in_hospital), 2) as avg_days_in_hospital,
CASE WHEN num_lab_procedures >= 0
	AND num_lab_procedures < 25
    THEN 'Few'
    
    WHEN num_lab_procedures >= 25
	AND num_lab_procedures < 55
    THEN 'Average'

ELSE 'Many'
END as procedure_frequency

FROM health
GROUP BY procedure_frequency
ORDER BY avg_days_in_hospital;  

SELECT *
FROM patient.health

WHERE admission_type_id = 1
AND time_in_hospital < (SELECT AVG(time_in_hospital) FROM patient.health);


SELECT CONCAT('Patient ', health.patient_nbr, ' was ', demographics.race, '   and ',
(CASE WHEN readmitted = 'NO'
THEN ' was not readmitted. They   had '
ELSE ' was readmitted. They had ' END),
num_medications, '   medications and ',num_lab_procedures, ' lab procedures.' ) AS summary
FROM   patient.health
INNER JOIN patient.demographics 
ON   demographics.patient_nbr = health.patient_nbr
ORDER BY num_medications   
DESC, num_lab_procedures
DESC LIMIT 50;

SELECT AVG(num_medications)
FROM health;
SELECT AVG(CAST(num_medications as float))
FROM health; 


ALTER TABLE health
MODIFY COLUMN num_medications INT; 

ALTER TABLE health
MODIFY COLUMN num_lab_procedures INT; 

ALTER TABLE health
MODIFY COLUMN num_procedures INT; 

SELECT *
FROM patient.health;

SELECT patient_nbr, 'metformin' AS medication, metformin AS med_usage FROM patient.health
UNION ALL
SELECT patient_nbr, 'glipizide' AS medication, glipizide AS med_usage FROM patient.health
UNION ALL
SELECT patient_nbr, 'insulin' AS medication, insulin AS med_usage 
FROM patient.health;


WITH long_health_cte AS (
SELECT patient_nbr, 'metformin' AS medication, metformin AS med_usage FROM patient.health
UNION ALL
SELECT patient_nbr, 'glipizide' AS medication, glipizide AS med_usage FROM patient.health
UNION ALL
SELECT patient_nbr, 'insulin' AS medication, insulin AS med_usage FROM patient.health
)

SELECT
age,
medication,
COUNT(*) AS encounter_use_count,
RANK() OVER (PARTITION BY age ORDER BY COUNT(*) DESC) AS medication_rank
FROM long_health_cte
JOIN patient.demographics ON long_health_cte.patient_nbr = demographics.patient_nbr
WHERE med_usage NOT IN ('No')
GROUP BY medication, age
ORDER BY age, medication_rank;