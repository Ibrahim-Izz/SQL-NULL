-- ============================================
-- HEALTHCARE SYSTEM: All NULL Killers (ULTRA REALISTIC)
-- Patients, Admissions, Lab Results, Medications, Physicians
-- ============================================

-- Drop tables if they exist
DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS medical_procedures;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS physicians;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS departments;

DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS medical_procedures;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS physicians;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS medications;
DROP TABLE IF EXISTS lab_results;
DROP TABLE IF EXISTS medical_procedures;
DROP TABLE IF EXISTS admissions;
DROP TABLE IF EXISTS physicians;
DROP TABLE IF EXISTS patients;
DROP TABLE IF EXISTS departments;

CREATE TABLE departments (
    department_id INT PRIMARY KEY,
    department_name VARCHAR(100) NOT NULL,
    building VARCHAR(50),
    floor_number INT,
    annual_budget DECIMAL(12,2),
    head_physician_id INT
);

CREATE TABLE physicians (
    physician_id INT PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    specialty VARCHAR(100),
    license_number VARCHAR(50),
    department_id INT,
    hire_date DATE,
    annual_salary DECIMAL(10,2),
    FOREIGN KEY (department_id) REFERENCES departments(department_id)
);

CREATE TABLE patients (
    patient_id INT PRIMARY KEY,
    full_name VARCHAR(100),
    date_of_birth DATE,
    blood_type VARCHAR(5),
    primary_physician_id INT,
    insurance_provider VARCHAR(100),
    emergency_contact VARCHAR(100),
    FOREIGN KEY (primary_physician_id) REFERENCES physicians(physician_id)
);

CREATE TABLE admissions (
    admission_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    admission_date DATETIME NOT NULL,
    discharge_date DATETIME,
    admission_type VARCHAR(50),
    diagnosis VARCHAR(200),
    attending_physician_id INT,
    discharge_status VARCHAR(50),
    total_cost DECIMAL(10,2),
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (attending_physician_id) REFERENCES physicians(physician_id)
);

CREATE TABLE lab_results (
    result_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    test_name VARCHAR(100) NOT NULL,
    order_date DATETIME NOT NULL,
    result_date DATETIME,
    result_value VARCHAR(100),
    result_unit VARCHAR(20),
    normal_range VARCHAR(50),
    interpreting_physician_id INT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (interpreting_physician_id) REFERENCES physicians(physician_id)
);

CREATE TABLE medications (
    prescription_id INT PRIMARY KEY,
    patient_id INT NOT NULL,
    medication_name VARCHAR(100) NOT NULL,
    prescribing_physician_id INT,
    dosage VARCHAR(50),
    start_date DATE NOT NULL,
    end_date DATE,
    pharmacy_cost DECIMAL(8,2),
    refills_remaining INT,
    FOREIGN KEY (patient_id) REFERENCES patients(patient_id),
    FOREIGN KEY (prescribing_physician_id) REFERENCES physicians(physician_id)
);

CREATE TABLE medical_procedures (
    procedure_id INT PRIMARY KEY,
    admission_id INT NOT NULL,
    procedure_name VARCHAR(100) NOT NULL,
    scheduled_time DATETIME,
    actual_time DATETIME,
    performing_physician_id INT,
    procedure_cost DECIMAL(10,2),
    complications VARCHAR(200),
    FOREIGN KEY (admission_id) REFERENCES admissions(admission_id),
    FOREIGN KEY (performing_physician_id) REFERENCES physicians(physician_id)
);

INSERT INTO departments VALUES
(1, 'Emergency Medicine', 'Main Building', 1, 5000000.00, 101),
(2, 'Cardiology', 'Main Building', 3, 3000000.00, 102),
(3, 'Pediatrics', 'Children Wing', 2, 2500000.00, 103),
(4, 'Oncology', 'Research Building', NULL, 4000000.00, 104),
(5, 'Telemedicine', NULL, NULL, NULL, NULL);

INSERT INTO physicians VALUES
(101, 'Dr. Sarah Mitchell', 'Emergency Medicine', 'MD-12345', 1, '2015-06-01', 280000.00),
(102, 'Dr. James Rodriguez', 'Cardiology', 'MD-23456', 2, '2010-03-15', 350000.00),
(103, 'Dr. Lisa Chen', 'Pediatrics', 'MD-34567', 3, '2018-09-01', 250000.00),
(104, 'Dr. Michael Brown', 'Oncology', 'MD-45678', 4, '2012-07-20', 400000.00),
(105, 'Dr. Emily White', NULL, 'MD-56789', 1, '2020-01-10', 200000.00),
(106, 'Dr. David Kim', 'Internal Medicine', NULL, 2, '2023-07-01', 65000.00),
(107, 'Dr. Maria Garcia', 'Anesthesiology', 'MD-67890', NULL, NULL, NULL),
(108, 'Dr. Robert Taylor', 'Surgery', 'MD-78901', NULL, NULL, NULL);

INSERT INTO patients VALUES
(1, 'Jennifer Wilson', '1985-03-15', 'O+', 101, 'Blue Cross Blue Shield', '555-0101 (Husband: Mark)'),
(2, 'Thomas Anderson', '1978-11-22', 'A+', 102, 'United Healthcare', '555-0102 (Wife: Sarah)'),
(3, 'Emma Davis', '2015-08-10', 'B+', 103, 'Medicaid', '555-0103 (Mother: Rachel)'),
(4, NULL, NULL, NULL, NULL, NULL, NULL),
(5, 'Mike Stevens', NULL, 'A-', 105, NULL, NULL),
(6, 'Jane Doe', NULL, NULL, 101, NULL, NULL),
(7, 'Carlos Rodriguez', '1990-05-20', NULL, NULL, NULL, '555-0107 (Hotel: Grand Plaza)'),
(8, 'Protected Minor', NULL, 'AB+', 103, 'State Medicaid', '[REDACTED BY COURT ORDER]'),
(9, 'Robert Martinez', '1965-12-01', 'O-', 104, NULL, '[PATIENT DECLINED]'),
(10, 'Susan Taylor', '1992-07-18', NULL, NULL, 'Aetna', '555-0110 (Sister: Mary)'),
(11, 'Baby Boy Smith', '2024-11-08', NULL, 103, 'Parents Insurance', '555-0111 (Mother: Amy Smith)'),
(12, 'William Johnson', '1945-06-12', 'B-', NULL, 'Medicare', NULL);

INSERT INTO admissions VALUES
(1001, 1, '2024-10-01 08:30:00', '2024-10-05 14:00:00', 'Elective Surgery', 'Appendicitis', 101, 'Discharged - Recovered', 18500.00),
(1002, 2, '2024-11-05 14:20:00', NULL, 'Cardiac Emergency', 'Myocardial Infarction', 102, NULL, NULL),
(1003, 4, '2024-11-07 22:45:00', NULL, NULL, NULL, 101, NULL, NULL),
(1004, 5, '2024-11-06 03:15:00', NULL, 'Emergency', NULL, 105, NULL, NULL),
(1005, 3, '2024-11-01 10:00:00', '2024-11-03 16:30:00', 'Pediatric Emergency', 'Pneumonia', 103, 'Transferred to Children\'s Hospital', NULL),
(1006, 6, '2024-11-04 19:00:00', '2024-11-05 02:30:00', 'Psychiatric Hold', NULL, 101, 'Left AMA', 0.00),
(1007, 7, '2024-11-03 11:00:00', '2024-11-05 09:00:00', 'Observation', 'Dehydration', 105, 'Discharged - Recovered', NULL),
(1008, 8, '2024-11-02 08:00:00', NULL, 'Court Ordered Observation', 'Suspected Abuse', 103, NULL, NULL),
(1009, 9, '2024-10-15 09:00:00', NULL, 'Oncology Treatment', 'Lymphoma - Stage 2', 104, NULL, NULL),
(1010, 10, '2024-11-08 15:30:00', '2024-11-08 17:00:00', 'Walk-in Clinic', 'Minor Laceration', 105, 'Discharged - Recovered', 450.00),
(1011, 11, '2024-11-08 03:45:00', NULL, 'NICU', NULL, 103, NULL, NULL),
(1012, 12, '2024-10-28 01:00:00', '2024-10-30 23:45:00', 'Emergency', 'Cardiac Arrest', 101, 'Deceased', NULL);

INSERT INTO lab_results VALUES
(2001, 1, 'Complete Blood Count', '2024-10-01 09:00:00', '2024-10-01 14:30:00', '7.5', 'K/uL', '4.5-11.0', 101),
(2002, 4, 'Toxicology Screen - Comprehensive', '2024-11-07 23:00:00', NULL, NULL, NULL, NULL, NULL),
(2003, 5, 'Chest X-Ray', '2024-11-06 04:00:00', '2024-11-06 06:30:00', 'Infiltrate right lower lobe', NULL, NULL, NULL),
(2004, 3, 'COVID-19 PCR Test', '2024-11-01 10:30:00', '2024-11-01 18:00:00', 'Negative', NULL, NULL, 103),
(2005, 7, 'Lipid Panel', '2024-11-03 12:00:00', '2024-11-04 08:00:00', NULL, NULL, NULL, NULL),
(2006, 6, 'Blood Alcohol Level', '2024-11-04 19:30:00', NULL, NULL, NULL, NULL, NULL),
(2007, 10, 'MRI - Brain', '2024-11-08 16:00:00', NULL, NULL, NULL, NULL, NULL),
(2008, 2, 'Cardiac Enzyme Panel', '2024-11-05 14:45:00', NULL, NULL, NULL, NULL, NULL),
(2009, 9, 'PET Scan', '2024-10-15 10:00:00', '2024-10-15 14:00:00', 'Multiple areas of uptake', NULL, NULL, 104),
(2010, 11, 'Newborn Blood Spot Screen', '2024-11-08 06:00:00', NULL, NULL, NULL, NULL, NULL),
(2011, 5, 'Blood Culture', '2024-11-06 03:30:00', NULL, NULL, NULL, NULL, NULL);

INSERT INTO medications VALUES
(3001, 1, 'Amoxicillin 500mg', 101, '500mg twice daily', '2024-10-01', '2024-10-10', 28.00, 0),
(3002, 4, 'Pain Management Protocol', NULL, NULL, '2024-11-07', NULL, NULL, NULL),
(3003, 2, 'Insulin Glargine', 102, '20 units at bedtime', '2024-11-05', NULL, 125.00, NULL),
(3004, 3, 'Albuterol Inhaler', 103, '2 puffs every 4 hours as needed', '2024-11-01', '2024-12-01', NULL, 5),
(3005, 7, 'IV Fluids - Normal Saline', 105, '1 liter over 4 hours', '2024-11-03', '2024-11-05', NULL, 0),
(3006, 9, 'Rituximab Infusion', 104, '375mg/m² IV', '2024-10-15', NULL, NULL, NULL),
(3007, 5, 'Antibiotic - Ceftriaxone', 105, '1g IV daily', '2024-11-06', '2024-11-13', NULL, 0),
(3008, 6, 'Lorazepam', 101, '1mg as needed for agitation', '2024-11-04', NULL, 15.00, NULL),
(3009, 11, 'Vitamin K Injection', 103, NULL, '2024-11-08', '2024-11-08', NULL, 0),
(3010, 12, 'Morphine Drip', 101, '2mg/hour continuous', '2024-10-28', '2024-10-30', NULL, 0);

INSERT INTO medical_procedures VALUES
(4001, 1001, 'Laparoscopic Appendectomy', '2024-10-01 10:00:00', '2024-10-01 11:30:00', 101, 12500.00, NULL),
(4002, 1003, 'Emergency Intubation', NULL, '2024-11-07 22:50:00', 101, NULL, NULL),
(4003, 1002, 'Cardiac Catheterization', '2024-11-05 15:00:00', '2024-11-05 16:45:00', NULL, 25000.00, NULL),
(4004, 1010, 'Suture Removal', '2024-11-15 14:00:00', NULL, 105, 150.00, NULL),
(4005, 1004, 'Wound Debridement', '2024-11-06 08:00:00', '2024-11-06 09:00:00', 105, NULL, 'Minor infection at site'),
(4006, 1012, 'CPR - Resuscitation Attempt', NULL, '2024-10-30 23:00:00', 101, NULL, 'Unsuccessful - Patient expired'),
(4007, 1006, 'Psychiatric Evaluation', '2024-11-05 09:00:00', NULL, NULL, 0.00, NULL),
(4008, 1007, 'CT Scan - Abdomen', '2024-11-03 13:00:00', '2024-11-03 13:30:00', 107, NULL, NULL),
(4009, 1009, 'Chemotherapy - Cycle 3', '2024-11-01 09:00:00', '2024-11-01 14:00:00', 104, NULL, 'Mild nausea'),
(4010, 1011, 'Phototherapy for Jaundice', NULL, '2024-11-08 08:00:00', 103, NULL, NULL);
