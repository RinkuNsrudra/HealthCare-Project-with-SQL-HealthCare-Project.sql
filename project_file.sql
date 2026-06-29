CREATE DATABASE hospital_management;
use hospital_management;
select * from patients;

--  total number of registered patients

select count(*) as total_patients
from patients;

select *
from patients
limit 10;

-- Provide the second patient row
select *
from patients
limit 1 offset 1;

-- how many patients are recently registered(in last 30 days)

select *
from patients
where registration_date >= (select max(registration_date) - interval 30 day from patients)
order by registration_date desc;

select max(registration_date) - interval 30 day from patients;

-- insight >> only one patient registered
-- very low recent acquistion rate
-- reduced amrketing, bad reviews, if this pattern continues there will be no new patient in future
-- no efficient utilisation of resources


-- how many doctors are available in hospital
select count(*) from doctors;

-- workforce of the hospital is 10

select * from doctors;

-- what are distinct specialisation in the hospital
select distinct specialization from doctors;

select * from doctors;
-- sort the doctors based on experience and provide first and last name of doctor together

-- concat

select concat(first_name, ' ', last_name) as doctor_name,
specialization, years_experience
from doctors
order by years_experience desc;


select * from doctors;

-- find the doctors name ending with 'is' based on first name
select first_name
from doctors 
where first_name  like '%is';

select * from doctors;

-- phone number
select * from doctors_1;

-- count dictinct phone no
select distinct(`phone number`)
from doctors_1;


select * from appointments;

-- what is total no of rows 
select count(*) from appointments;

-- what is the appointment status distribution
select * from appointments;

select status, count(*)
from appointments
group by status;

-- provide me the status types whose count is more than 50
select status, count(*)
from appointments
group by status
having count(*) > 50; -- having is used with groupby and not where

-- find all the appointments in the last 7 days

select *
from appointments
where appointment_date >= (select max(appointment_date) - INTERVAL 7 day from appointments)
order by appointment_date desc;


-- find date wise count of status

select appointment_date, status, count(*)
from appointments
group by appointment_date, status
order by appointment_date desc;

select count(*)
from treatments;

select *
from treatments;

-- Most common treatment_type
select treatment_type, count(*) as treatment_count
from treatments
group by treatment_type
order by treatment_count desc;

-- find min cost, max cost, avg cost of the treatment

select min(cost) as min_cost, max(cost) as max_cost, round(avg(cost), 1) as avg_cost
from treatments;

select * from treatments;

-- cast, round is a temporaray change
-- if you want to make permanent then make a new columns and write back to database
-- update table 

-- update treatments set cost = cast (cost as int);
-- select cast(cost as int) from treatments;
-- alter treatments cost int


select cast(cost as SIGNED) FROM TREATMENTS;
#MY SQL, INT IS NOT DIRECTLY USED, YOU CAN USE SIGNED

select cast(10.389 as decimal(10, 2));


select *
from billing;

select count(*) from billing;

-- PAYMENT STATUS DISTRIBUTION
SELECT payment_status, COUNT(*) AS bill_count
FROM billing
GROUP BY payment_status;


-- patients and doctor >> segmentation

select * from patients;

-- how many patients are registered from each address?
select address, count(*) as patient_count
from patients
group by address
order by patient_count desc;

-- these resgions are residential area, localized demand, strongs referral network/residential clusters
-- targeted outreach

-- what is age distribution of patients?

select patient_id, first_name, gender,
TIMESTAMPDIFF(YEAR, date_of_birth, curdate()) as age
from patients;

-- Age group segmentation
-- 18-35
-- 36-55
-- 56+

-- age_group, patient_count

select 
case
	when timestampdiff(YEAR, date_of_birth, CURDATE()) < 18 THEN 'UNDER 18'
    when timestampdiff(YEAR, date_of_birth, CURDATE()) BETWEEN 18 and 35 THEN 'Adults'
    when timestampdiff(YEAR, date_of_birth, CURDATE()) BETWEEN 36 and 55 THEN 'Matured'
    ELSE 'SENIORS'
end as age_group,
count(*) as patient_count
from patients
group by age_group
order by patient_count desc;


select * from patients;

-- which email domains are most commonly used by patients
select substring_index(email, '@', -1) as email_domain,
count(*) as patient_count
from patients
group by email_domain;

-- which month had higher patient registeration

select year(registration_date) as year,
month(registration_date) as month,
count(*) as patient_count
from patients
group by year, month;

select * from patients;

-- Which medical specialisation are most in demand based on appointment volume?

select d.specialization,
count(a.appointment_id) as total_appointments
from appointments a
join doctors d
on a.doctor_id = d.doctor_id
group by d.specialization;

-- are critical specialization supported by senior experienced doctor or junior doctor?
-- > 15 years--senior

select specialization,
count(*) as total_doctors,
SUM(CASE WHEN years_experience >= 15 THEN 1 ELSE 0 END) AS senior_doctors,
SUM(CASE WHEN years_experience < 15 THEN 1 ELSE 0 END) AS junior_doctors
from doctors
group by specialization;

-- make a table/master data>> appointments with patient details and doctor specialzation

select 
a.appointment_id,
CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
d.specialization,
a.appointment_date,
a.appointment_time,
a.reason_for_visit,
a.status
from appointments a
join patients p
on a.patient_id=p.patient_id
join doctors d
on a.doctor_id = d.doctor_id
ORDER BY a.appointment_date DESC limit 5;

-- which doctors are overloaded and which have available capacity based on appointment volume

SELECT
  CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
  d.specialization,
  COUNT(a.appointment_id) AS total_appointments
from doctors d
left join appointments a
on d.doctor_id = a.doctor_id
group by d.doctor_id, doctor_name, d.specialization
order by total_appointments;

-- build a big master data where we can see the entire journey of a patient >> from appointment>treatment>billing


SELECT
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  a.appointment_id,
  a.appointment_date,
  a.status AS appointment_status,
  t.treatment_id,
  t.treatment_type,
  t.cost AS treatment_cost,
  b.bill_id,
  b.amount AS billed_amount,
  b.payment_status
FROM patients p
JOIN appointments a
  ON p.patient_id = a.patient_id
LEFT JOIN treatments t
  ON a.appointment_id = t.appointment_id
LEFT JOIN billing b
  ON t.treatment_id = b.treatment_id
ORDER BY p.patient_id, a.appointment_date;

-- finances
-- what is total revenue generated by company
select sum(amount) as total_revenue
from billing
where payment_status = 'Paid';

-- Which patients contribute the most revenue

SELECT
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  SUM(b.amount) AS total_spent
from patients p
join billing b
on p.patient_id = b.patient_id
where b.payment_status = 'Paid'
GROUP BY p.patient_id, patient_name
ORDER BY total_spent DESC;

-- RFM Segmentation 
-- Recency, Frequency and Monetary
-- Create RFM metrcis per patient using: last_visit, total_visit, paid_spend
-- label "champions", "Loyal high value", "risk"

WITH rfm AS (
  SELECT
    p.patient_id,
    CONCAT(p.first_name,' ',p.last_name) AS patient_name,
    MAX(a.appointment_date) AS last_visit,
    COUNT(DISTINCT a.appointment_id) AS frequency,
    COALESCE(SUM(CASE WHEN b.payment_status='Paid' THEN b.amount END),0) AS monetary
  FROM patients p
  LEFT JOIN appointments a ON a.patient_id = p.patient_id
  LEFT JOIN billing b ON b.patient_id = p.patient_id
  GROUP BY p.patient_id, patient_name
),
scored AS (
  SELECT
    *,
    DATEDIFF(CURDATE(), last_visit) AS recency_days,
    NTILE(4) OVER (ORDER BY DATEDIFF(CURDATE(), last_visit) ASC) AS r_score, -- lower recency better
    NTILE(4) OVER (ORDER BY frequency DESC) AS f_score,
    NTILE(4) OVER (ORDER BY monetary DESC) AS m_score
  FROM rfm
)
SELECT
  patient_id, patient_name,
  recency_days, frequency, monetary,
  r_score, f_score, m_score,
  CONCAT(r_score,f_score,m_score) AS rfm_code,
  CASE
    WHEN r_score >=3 AND f_score >=3 AND m_score >=3 THEN 'Champions'
    WHEN f_score >=3 AND m_score >=3 THEN 'Loyal High Value'
    WHEN r_score <=2 AND f_score <=2 THEN 'At Risk / Inactive'
    WHEN f_score >=3 THEN 'Frequent Visitors'
    WHEN m_score >=3 THEN 'High Spenders'
    ELSE 'Regular'
  END AS segment
FROM scored
ORDER BY monetary DESC, frequency DESC;

-- outlier detection
-- are there treatments with unusually high cost that require review

select treatment_id,
treatment_type,
cost
from treatments
where cost > (select avg(cost) + 2 *stddev(cost) from treatments);

-- Rank doctors by total appointment
SELECT
  CONCAT(d.first_name, ' ', d.last_name) AS doctor_name,
  d.specialization,
  COUNT(a.appointment_id) AS total_appointments
FROM doctors d
JOIN appointments a
  ON d.doctor_id = a.doctor_id
GROUP BY d.doctor_id, doctor_name, d.specialization
ORDER BY total_appointments DESC LIMIT 5;

-- Rank patients by total spending (VIP patients)

SELECT
  p.patient_id,
  CONCAT(p.first_name, ' ', p.last_name) AS patient_name,
  SUM(b.amount) AS total_spent,
RANK() OVER(ORDER BY SUM(b.amount) DESC) as spending_rank
from patients p
join billing b
on p.patient_id = b.patient_id
where b.payment_status = 'Paid'
Group by p.patient_id, patient_name;

-- select treatement by frequency
SELECT
  treatment_type,
  COUNT(*) AS treatment_count,
  RANK() OVER (ORDER BY COUNT(*) DESC) AS frequency_rank
FROM treatments
GROUP BY treatment_type;


