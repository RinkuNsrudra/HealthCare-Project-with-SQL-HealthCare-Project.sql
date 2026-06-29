CREATE DATABASE hospital_management;
USE hospital_management;
select * from patients;

-- Count total number of patient

Select count(*) as Total_patients from patients;

select *
from patients
limit 10;

-- provide the second patients row

select *
from patients
limit 1 offset 1;

-- how many patients recently registered (in last 30 days)

select *
from patients
where registration_date >= (select max(registration_date) - interval 30 day from patients)
order by registration_date desc;

-- insight >> only one patient registerd
-- very low recent aquisation rate
-- reduced marketing, bad rewiews, if this pattern continue theier will be  no new patient in future
-- no efficient utilization of resources

-- how many doctors are available in hospital

select count(*) from doctors;

-- workforce of the hospital is 10

select * from doctors;

-- what are the distinct specialization in the hospital

select distinct specialization from doctors;

-- sort the doctor based on  experience and provide  first and last name of doctors together

select concat(first_name,' ', last_name) as doctors_name,
specialization, years_experience
from doctors
order by years_experience desc;

select * from doctors;
-- Find the doctors name end with "is" based on first name

select *
from doctors
where first_name like '%is';

-- count phone numbers
select distinct(`phone_number`)
from doctors;

select * from appointments;

-- what is total numbers of rows

select count(*) from appointments;

-- what is appointments status distribution

select status, count(*)
from appointments
group by status;

-- provide me the status types whose count is more than 50

select status, count(*)
from appointments
group by status
having count(*) > 50; -- having is used with group by not where

-- find all the appointments in last 7 days
select *
from appointments
where appointment_date >= (select max(appointment_date) - interval 7 day from appointments)
order by appointment_date desc;

-- find datewise count status
select appointment_date,status, count(*)
from appointments
group by appointment_date,status
order by appointment_date desc;

select * from treatments;
select count(*) from treatments;

-- most common treatment type
 select treatment_type,count(*) as treatment
 from treatments
 group by treatment_type
 order by treatment_type desc;
 
 -- fint min cost , max cost , avg cost of the treatment

select min(cost)as min_cost , max(cost) as max_cost , round(avg(cost),1) as avg_cost
from treatments;


-- update treatments set cost = cast(cost as int);
-- select  cast(cost as int ) from treatments;

select cast(cost as signed) from treatments;
# MYSQL , INT is not directly used , you have to use SIGNED

select cast(10.389 as decimal(10,2));


select * from billing;
select count(*) from billing;

-- payment Status Distribution
 select payment_status, count(*) as bill_count
 from billing
 group by payment_status;

-- patients & doctors Table >> segmentation

select * from patients;

-- how many patients are registered from each address
select address, count(*) as Patients_count
from patients
group by address
order by Patients_count desc;

-- these regions are residential area, localized demand, strongs referral network/residential clusters
-- targeted outreach

-- what is age distribution of patients?

select patient_id, first_name, gender,
timestampdiff(year,date_of_birth, curdate()) as age
from patients;

-- age group  segmentation
-- 18-35
-- 36-55
-- 56+
-- age_group, patient_count

SELECT 
    CASE 
        WHEN TIMESTAMPDIFF(YEAR, Date_of_Birth, CURDATE()) BETWEEN 18 AND 35 THEN '18-35'
        WHEN TIMESTAMPDIFF(YEAR, Date_of_Birth, CURDATE()) BETWEEN 36 AND 55 THEN '36-55'
        WHEN TIMESTAMPDIFF(YEAR, Date_of_Birth, CURDATE()) >= 56 THEN '56+'
        ELSE 'Below 18'
    END AS age_group,
    
    COUNT(*) AS patient_count

FROM Patients
GROUP BY age_group
ORDER BY age_group;


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

-- which email domain are most  commonly used  by patients
select * from patients;

SELECT 
    SUBSTRING_INDEX(email, '@', -1) AS email_domain,
    COUNT(*) AS patient_count
FROM Patients
GROUP BY email_domain;

-- which month had higher patients registration
 select 
 year(registration_date) as year,
 month(registration_date) as month,
 count(*)  as patient_count
 from patients
 group by year, month;
 
 -- which medical specialization in more in demand based on appointment volume?

SELECT
    d.specialization,
    COUNT(*) AS appointment_count
FROM appointments a
JOIN doctors d
    ON a.doctor_id = d.doctor_id
GROUP BY d.specialization
ORDER BY appointment_count DESC;


SELECT specialization,
COUNT(appointment_id) as total_appointments
from appointments a
join doctors d
on a.doctor_id = d.doctor_id
group by d.specialization;

-- are critical specialization supported by senior experience doctor or junior doctors
 select * from doctors;


select specialization,
count(*) as total_doctors,
sum(case when years_experience >= 15 then 1 else 0 end) as Senior_docs,
sum(case when years_experience < 15 then 1 else 0 end) as Junior_docs
from doctors
group by specialization;

-- make talbe\master data >> appointments with patients details and doctors specialization
select * from patients;
select * from doctors;
WITH doctor_volume AS (
    SELECT 
        d.doctor_id,
        d.doctor_name,
        d.specialization,
        COUNT(a.appointment_id) AS appointment_volume
    FROM Doctors d
    LEFT JOIN Appointments a
        ON d.doctor_id = a.doctor_id
    GROUP BY d.doctor_id, d.doctor_name, d.specialization
)

SELECT *,
       CASE 
           WHEN appointment_volume > 
                (SELECT AVG(appointment_volume) FROM doctor_volume)
           THEN 'Overloaded'
           ELSE 'Available'
       END AS workload_status
FROM doctor_volume
ORDER BY appointment_volume DESC;
   
    
    
    
-- which doctors are  overloaded and which have available based on appointments volume
 select 
	concat(d.first_name, ' ', d.last_name) as doctor_name,
	d.specialization,
	count(a.appointment_id) as total_appointments
 from doctors d
 left join appointments a
 on d.doctor_id = a.doctor_id
 group by d.doctor_id, doctor_name, d.specialization
 order by total_appointment;
 
 -- built a biger data where  we can see the entire journeyof a patients >> from appointments >> treatements >> billings
  
-- select *from patients p
 -- joins appointments a 
 -- on p.patient_id = a.patient_id
 -- left join treatments

 
 -- finance
 -- what are total revenue generated by company
 select sum(amount) as total_revenue
  from billing
  where payment_status = 'Paid';
  
  -- calculate total spent by patients
  select 
  p.patient_id,
	concat(p.first_name,' ',p.last_name) as patient_name,
	sum(b.amount) as total_spent
  from patients p
  join billing b
  on p.patient_id = b.patient_id
  where b.payment_status = "Paid"
  group by p.patient_id ,patient_name
  order by total_spent desc;
  
  -- RFM segmentation 
  -- Recency  Frequency and Monetary
  -- Create RFM matrics per patients  using last_visit , total_visit, paid_spend 
  -- label 'Champion', 'loyal high value','risk'


-- Outlier detection
-- Are their treatments with unusually high cost that require reviews
select * from treatments;

SELECT 
    treatment_id,
    treatment_type,
    cost
FROM treatments
WHERE cost > (select avg(cost) + 2 *stddev(cost) from treatments);

-- ranks doctors by total appointments

-- rank patients by total spent (VIP Patients)

-- select treatments by frequency