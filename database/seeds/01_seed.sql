
-- SHA2 password values are demo-only and are not suitable for real authentication.

INSERT INTO company (company_id, sector, address, name, company_type) VALUES
(401, 'Software and IT Services', '1 Le Duan, District 1, Ho Chi Minh City', 'Lotus Digital', 'pro'),
(402, 'E-commerce', '12 Nguyen Hue, District 1, Ho Chi Minh City', 'Mekong Commerce', 'normal'),
(403, 'Banking and Finance', '88 Cach Mang Thang Tam, District 3, Ho Chi Minh City', 'Beacon Bank', 'pro'),
(404, 'Healthcare Technology', '20 Tran Hung Dao, Hoan Kiem, Hanoi', 'CareBridge Health', 'normal'),
(405, 'Education Technology', '5 Vo Nguyen Giap, Ngu Hanh Son, Da Nang', 'BrightPath Learning', 'normal');

INSERT INTO user_account
(account_id, first_name, last_name, gender, email_address, hashed_password, phone_number, registration_method, account_status, created_date)
VALUES
(101, 'An', 'Nguyen', 'female', 'an.nguyen@example.test', SHA2('demo-user-101-password', 256), '0901000101', 'email', 'active', '2026-01-05 09:00:00'),
(102, 'Binh', 'Tran', 'male', 'binh.tran@example.test', SHA2('demo-user-102-password', 256), '0901000102', 'email', 'active', '2026-01-10 10:30:00'),
(103, 'Chi', 'Le', 'female', 'chi.le@example.test', SHA2('demo-user-103-password', 256), '0901000103', 'email', 'active', '2026-02-14 08:15:00'),
(104, 'Duc', 'Pham', 'male', 'duc.pham@example.test', SHA2('demo-user-104-password', 256), '0901000104', 'email', 'active', '2026-03-01 11:45:00'),
(105, 'Ha', 'Vo', 'female', 'ha.vo@example.test', NULL, '0901000105', 'Google', 'active', '2026-03-22 14:20:00'),
(106, 'Khanh', 'Nguyen', 'male', 'khanh.nguyen@example.test', NULL, '0901000106', 'Facebook', 'unverified', '2026-04-10 09:00:00'),
(107, 'My', 'Tran', 'female', 'my.tran@example.test', NULL, '0901000107', 'LinkedIn', 'locked', '2026-04-12 10:00:00'),
(201, 'Minh', 'Do', 'male', 'minh.do@lotus.example.test', SHA2('demo-user-201-password', 256), '0902000201', 'email', 'active', '2025-11-02 09:00:00'),
(202, 'Lan', 'Bui', 'female', 'lan.bui@lotus.example.test', NULL, '0902000202', 'LinkedIn', 'active', '2025-11-03 09:00:00'),
(203, 'Tuan', 'Hoang', 'male', 'tuan.hoang@mekong.example.test', SHA2('demo-user-203-password', 256), '0902000203', 'email', 'active', '2025-11-04 09:00:00'),
(204, 'Mai', 'Phan', 'female', 'mai.phan@mekong.example.test', NULL, '0902000204', 'Google', 'active', '2025-11-05 09:00:00'),
(205, 'Khoa', 'Vu', 'male', 'khoa.vu@beacon.example.test', SHA2('demo-user-205-password', 256), '0902000205', 'email', 'active', '2025-11-06 09:00:00'),
(206, 'Thao', 'Dang', 'female', 'thao.dang@beacon.example.test', NULL, '0902000206', 'Facebook', 'active', '2025-11-07 09:00:00'),
(207, 'Long', 'Truong', 'male', 'long.truong@carebridge.example.test', SHA2('demo-user-207-password', 256), '0902000207', 'email', 'active', '2025-11-08 09:00:00'),
(208, 'Vy', 'Huynh', 'female', 'vy.huynh@carebridge.example.test', NULL, '0902000208', 'Google', 'active', '2025-11-09 09:00:00'),
(209, 'Nam', 'Ly', 'male', 'nam.ly@brightpath.example.test', SHA2('demo-user-209-password', 256), '0902000209', 'email', 'active', '2025-11-10 09:00:00'),
(210, 'Nhi', 'Mai', 'female', 'nhi.mai@brightpath.example.test', NULL, '0902000210', 'LinkedIn', 'active', '2025-11-11 09:00:00'),
(301, 'Quang', 'Nguyen', 'male', 'quang.admin@example.test', SHA2('demo-user-301-password', 256), '0903000301', 'email', 'active', '2025-01-05 08:00:00'),
(302, 'Thuy', 'Le', 'female', 'thuy.admin@example.test', SHA2('demo-user-302-password', 256), '0903000302', 'email', 'active', '2025-01-06 08:00:00'),
(303, 'Huy', 'Pham', 'male', 'huy.admin@example.test', NULL, '0903000303', 'Google', 'active', '2025-01-07 08:00:00'),
(304, 'Linh', 'Tran', 'female', 'linh.admin@example.test', SHA2('demo-user-304-password', 256), '0903000304', 'email', 'active', '2025-01-08 08:00:00'),
(305, 'Son', 'Vo', 'male', 'son.admin@example.test', NULL, '0903000305', 'LinkedIn', 'active', '2025-01-09 08:00:00');

INSERT INTO candidate
(candidate_id, expected_salary, experience_level, work_at_other_place, receive_suggestion, receive_promotion)
VALUES
(101, 32000000, '3_5_years', TRUE, TRUE, FALSE),
(102, 24000000, '1_3_years', FALSE, TRUE, TRUE),
(103, 18000000, 'under_1_year', TRUE, FALSE, TRUE),
(104, 40000000, 'over_5_years', FALSE, TRUE, FALSE),
(105, 15000000, 'no_experience', TRUE, TRUE, TRUE),
(106, 20000000, '1_3_years', FALSE, TRUE, FALSE),
(107, 28000000, '3_5_years', TRUE, FALSE, FALSE);

INSERT INTO employer (employer_id, company_id, job_title) VALUES
(201, 401, 'Talent Acquisition Lead'),
(202, 401, 'Senior Recruiter'),
(203, 402, 'Recruitment Manager'),
(204, 402, 'Technical Recruiter'),
(205, 403, 'People Operations Lead'),
(206, 403, 'Senior Talent Partner'),
(207, 404, 'HR Manager'),
(208, 404, 'Technology Recruiter'),
(209, 405, 'Recruitment Lead'),
(210, 405, 'People and Culture Specialist');

INSERT INTO administrator (admin_id, administrative_access_level) VALUES
(301, 'super_admin'),
(302, 'manager'),
(303, 'reviewer'),
(304, 'reviewer'),
(305, 'manager');


INSERT INTO verification_task
(task_type, employer_id, admin_id, task_status, submitted_document, submitted_at, reviewed_at)
VALUES
('phone_verification', 201, NULL, 'approved', NULL, '2025-11-02 09:10:00', NULL),
('company_information', 201, 301, 'approved', 'lotus-company-profile.pdf', '2025-11-02 10:00:00', '2025-11-03 09:00:00'),
('business_registration', 201, 302, 'approved', 'lotus-business-registration.pdf', '2025-11-02 10:30:00', '2025-11-03 10:00:00'),
('personal_data_agreement', 201, NULL, 'approved', NULL, '2025-11-02 11:00:00', NULL),
('phone_verification', 202, NULL, 'approved', NULL, '2025-11-03 09:10:00', NULL),
('company_information', 202, 303, 'approved', 'lotus-recruiter-profile.pdf', '2025-11-03 10:00:00', '2025-11-04 09:00:00'),
('business_registration', 202, 303, 'approved', 'lotus-registration-copy.pdf', '2025-11-03 10:30:00', '2025-11-04 09:30:00'),
('personal_data_agreement', 202, NULL, 'approved', NULL, '2025-11-03 11:00:00', NULL),
('phone_verification', 203, NULL, 'approved', NULL, '2025-11-04 09:10:00', NULL),
('company_information', 203, 304, 'approved', 'mekong-company-profile.pdf', '2025-11-04 10:00:00', '2025-11-05 09:00:00'),
('business_registration', 203, 304, 'approved', 'mekong-registration.pdf', '2025-11-04 10:30:00', '2025-11-05 09:30:00'),
('personal_data_agreement', 203, NULL, 'approved', NULL, '2025-11-04 11:00:00', NULL),
('phone_verification', 204, NULL, 'approved', NULL, '2025-11-05 09:10:00', NULL),
('company_information', 204, NULL, 'submitted', 'mekong-updated-profile.pdf', '2025-11-05 10:00:00', NULL),
('business_registration', 204, 305, 'rejected', 'mekong-registration-blurry.pdf', '2025-11-05 10:30:00', '2025-11-06 09:30:00'),
('personal_data_agreement', 204, NULL, 'approved', NULL, '2025-11-05 11:00:00', NULL),
('phone_verification', 205, NULL, 'approved', NULL, '2025-11-06 09:10:00', NULL),
('company_information', 205, 301, 'approved', 'beacon-company-profile.pdf', '2025-11-06 10:00:00', '2025-11-07 09:00:00'),
('business_registration', 205, 302, 'approved', 'beacon-registration.pdf', '2025-11-06 10:30:00', '2025-11-07 09:30:00'),
('personal_data_agreement', 205, NULL, 'approved', NULL, '2025-11-06 11:00:00', NULL),
('phone_verification', 206, NULL, 'approved', NULL, '2025-11-07 09:10:00', NULL),
('company_information', 206, 303, 'approved', 'beacon-recruiter-profile.pdf', '2025-11-07 10:00:00', '2025-11-08 09:00:00'),
('business_registration', 206, NULL, 'not_completed', NULL, NULL, NULL),
('personal_data_agreement', 206, NULL, 'approved', NULL, '2025-11-07 11:00:00', NULL),
('phone_verification', 207, NULL, 'approved', NULL, '2025-11-08 09:10:00', NULL),
('company_information', 207, 304, 'approved', 'carebridge-company-profile.pdf', '2025-11-08 10:00:00', '2025-11-09 09:00:00'),
('business_registration', 207, 305, 'approved', 'carebridge-registration.pdf', '2025-11-08 10:30:00', '2025-11-09 09:30:00'),
('personal_data_agreement', 207, NULL, 'approved', NULL, '2025-11-08 11:00:00', NULL),
('phone_verification', 208, NULL, 'approved', NULL, '2025-11-09 09:10:00', NULL),
('company_information', 208, 305, 'approved', 'carebridge-recruiter-profile.pdf', '2025-11-09 10:00:00', '2025-11-10 09:00:00'),
('business_registration', 208, 305, 'approved', 'carebridge-registration.pdf', '2025-11-09 10:30:00', '2025-11-10 09:30:00'),
('personal_data_agreement', 208, NULL, 'approved', NULL, '2025-11-09 11:00:00', NULL),
('phone_verification', 209, NULL, 'approved', NULL, '2025-11-10 09:10:00', NULL),
('company_information', 209, 301, 'approved', 'brightpath-company-profile.pdf', '2025-11-10 10:00:00', '2025-11-11 09:00:00'),
('business_registration', 209, 302, 'approved', 'brightpath-registration.pdf', '2025-11-10 10:30:00', '2025-11-11 09:30:00'),
('personal_data_agreement', 209, NULL, 'approved', NULL, '2025-11-10 11:00:00', NULL),
('phone_verification', 210, NULL, 'approved', NULL, '2025-11-11 09:10:00', NULL),
('company_information', 210, 303, 'approved', 'brightpath-updated-profile.pdf', '2025-11-11 10:00:00', '2025-11-12 09:00:00'),
('business_registration', 210, 304, 'approved', 'brightpath-registration.pdf', '2025-11-11 10:30:00', '2025-11-12 09:30:00'),
('personal_data_agreement', 210, NULL, 'approved', NULL, '2025-11-11 11:00:00', NULL);

INSERT INTO job_category (category_id, parent_category_id, name, category_level) VALUES
(1, NULL, 'Information Technology', 'group'),
(6, NULL, 'Finance', 'group'),
(11, NULL, 'Healthcare', 'group');

INSERT INTO job_category (category_id, parent_category_id, name, category_level) VALUES
(2, 1, 'Software Engineering', 'profession'),
(3, 1, 'Data and Artificial Intelligence', 'profession'),
(7, 6, 'Banking', 'profession'),
(8, 6, 'Financial Analysis', 'profession'),
(12, 11, 'Health Informatics', 'profession'),
(13, 11, 'Healthcare Operations', 'profession');

INSERT INTO job_category (category_id, parent_category_id, name, category_level) VALUES
(4, 2, 'Backend Developer', 'specialisation'),
(5, 2, 'Frontend Developer', 'specialisation'),
(9, 3, 'Data Analyst', 'specialisation'),
(10, 3, 'Machine Learning Engineer', 'specialisation'),
(14, 12, 'Health Data Analyst', 'specialisation'),
(15, 13, 'Clinical Operations Coordinator', 'specialisation');

INSERT INTO candidate_interest_job_category (candidate_id, category_id) VALUES
(101, 4), (101, 10),
(102, 5), (102, 9),
(103, 4), (103, 5),
(104, 9), (104, 10),
(105, 14), (105, 15),
(106, 4),
(107, 14);

INSERT INTO candidate_desired_location (candidate_id, province_city) VALUES
(101, 'Ho Chi Minh City'), (101, 'Da Nang'),
(102, 'Ho Chi Minh City'),
(103, 'Hanoi'), (103, 'Ho Chi Minh City'),
(104, 'Da Nang'),
(105, 'Hanoi'), (105, 'Da Nang'),
(106, 'Ho Chi Minh City'),
(107, 'Hanoi');

INSERT INTO cv (candidate_id, cv_no, name, location, file_format, file_size_bytes, uploaded_date) VALUES
(101, 1, 'An_Nguyen_Backend_2026.pdf', '/demo/cv/101/an-backend.pdf', 'pdf', 458752, '2026-04-02 10:00:00'),
(101, 2, 'An_Nguyen_Platform_2026.docx', '/demo/cv/101/an-platform.docx', 'docx', 720896, '2026-06-18 15:30:00'),
(102, 1, 'Binh_Tran_Frontend_2026.pdf', '/demo/cv/102/binh-frontend.pdf', 'pdf', 512000, '2026-05-04 09:20:00'),
(102, 2, 'Binh_Tran_Data_2026.doc', '/demo/cv/102/binh-data.doc', 'doc', 663552, '2026-07-12 11:10:00'),
(103, 1, 'Chi_Le_Junior_Developer.pdf', '/demo/cv/103/chi-junior.pdf', 'pdf', 389120, '2026-06-03 13:15:00'),
(103, 2, 'Chi_Le_Web_Projects.docx', '/demo/cv/103/chi-web.docx', 'docx', 819200, '2026-08-01 17:05:00'),
(104, 1, 'Duc_Pham_Data_Lead.pdf', '/demo/cv/104/duc-data.pdf', 'pdf', 901120, '2026-02-21 08:30:00'),
(104, 2, 'Duc_Pham_ML_Projects.pdf', '/demo/cv/104/duc-ml.pdf', 'pdf', 1048576, '2026-09-11 16:45:00'),
(105, 1, 'Ha_Vo_Health_Analytics.pdf', '/demo/cv/105/ha-health.pdf', 'pdf', 430080, '2026-07-20 12:00:00'),
(105, 2, 'Ha_Vo_Clinical_Operations.docx', '/demo/cv/105/ha-clinical.docx', 'docx', 573440, '2026-09-19 14:25:00'),
(107, 1, 'My_Tran_Health_Data.pdf', '/demo/cv/107/my-health-data.pdf', 'pdf', 5242880, '2026-04-13 11:30:00');

INSERT INTO job_alert
(candidate_id, alert_no, search_keyword, province_city, district, salary_level, experience_level, professional_role, employment_type, notification_frequency, delivery_channel, consent_confirmed, consent_confirmed_at)
VALUES
(101, 1, 'Backend engineer', 'Ho Chi Minh City', 'District 1', '25-40 million VND', '3_5_years', 'Backend Developer', 'full_time', 'daily', 'both', TRUE, '2026-04-03 10:00:00'),
(102, 1, 'Frontend developer', 'Ho Chi Minh City', 'District 7', '18-28 million VND', '1_3_years', 'Frontend Developer', 'full_time', 'weekly', 'email', TRUE, '2026-05-05 09:00:00'),
(103, 1, 'Junior software engineer', 'Hanoi', 'Cau Giay', '12-20 million VND', 'under_1_year', 'Software Engineering', 'full_time', 'daily', 'app', TRUE, '2026-06-04 13:00:00'),
(104, 1, 'Machine learning', NULL, NULL, '35-55 million VND', 'over_5_years', 'Machine Learning Engineer', 'full_time', 'weekly', 'both', TRUE, '2026-02-22 08:00:00'),
(105, 1, 'Health data analyst', 'Da Nang', 'Hai Chau', '12-20 million VND', 'no_experience', 'Health Data Analyst', 'internship', 'weekly', 'app', TRUE, '2026-07-21 12:00:00');

INSERT INTO candidate_follow_company (candidate_id, company_id, followed_date) VALUES
(101, 401, '2026-04-05 10:00:00'),
(102, 402, '2026-05-06 11:00:00'),
(103, 401, '2026-06-05 12:00:00'),
(104, 403, '2026-02-23 13:00:00'),
(105, 404, '2026-07-22 14:00:00'),
(105, 405, '2026-08-02 15:00:00');

INSERT INTO recruitment_need
(need_id, declared_date, professional_position, job_level, number_employee_required, expected_completion_date, budget, budget_source, consultation)
VALUES
(501, '2026-01-10', 'Backend Platform Engineer', 'Senior', 3, '2026-12-20', 900000000, 'Engineering department', TRUE),
(502, '2026-02-12', 'Frontend Product Engineer', 'Mid-level', 2, '2026-12-25', 480000000, 'Product department', FALSE),
(503, '2026-03-15', 'Data Analyst', 'Mid-level', 2, NULL, 360000000, 'Risk analytics team', TRUE),
(504, '2026-04-18', 'Health Data Analyst', 'Junior', 1, '2027-01-31', 240000000, 'Digital health program', FALSE),
(505, '2026-05-20', 'Clinical Operations Coordinator', 'Entry-level', 4, NULL, NULL, 'Annual operating budget', TRUE),
(506, '2026-06-22', 'Software Engineering Intern', 'Intern', 2, NULL, 0, 'Early-career program', FALSE);

INSERT INTO declares_recruitment_need (need_id, employer_id, company_id) VALUES
(501, 201, 401),
(502, 203, 402),
(503, 205, 403),
(504, 207, 404),
(505, 209, 405),
(506, 210, 405);

INSERT INTO recruitment_campaign
(campaign_id, created_by_employer_id, managed_by_employer_id, recruitment_need_id, name, creation_date, campaign_status)
VALUES
(601, 201, 202, 501, 'Platform Modernisation - H2 2026', '2026-01-15', 'running'),
(602, 203, 203, 502, 'Commerce Product Engineering - 2026', '2026-02-18', 'running'),
(603, 205, 205, 503, 'Risk Analytics Talent Pipeline', '2026-03-20', 'stopped'),
(604, 207, 208, 504, 'Digital Health Data Initiative', '2026-04-22', 'running'),
(605, 209, 210, 505, 'Clinical Operations Expansion', '2026-05-25', 'running'),
(606, 201, 202, NULL, 'Always-on Backend Talent Pool', '2026-06-01', 'running');

INSERT INTO job_posting
(job_posting_id, category_id, company_id, campaign_id, title, description, working_hours, saturday_work_policy, job_level, required_experience, job_status, min_salary, max_salary, employment_type, posted_date, application_deadline, application_method, contact_detail, employee_responsibilities, requirements)
VALUES
(701, 4, 401, 601, 'Senior Backend Engineer', 'Build reliable services for a high-traffic regional platform.', 'Monday-Friday, 09:00-18:00', 'off', 'Senior', '3_5_years', 'open', 30000000, 45000000, 'full_time', '2026-10-20', '2026-12-15', 'on_site', NULL, 'Design APIs, improve service reliability, and mentor engineers.', 'At least three years of backend development and experience with relational databases.'),
(702, 5, 402, 602, 'Frontend Engineer - Product Experience', 'Develop accessible customer-facing commerce experiences.', 'Monday-Friday, 08:30-17:30', 'not_specified', 'Mid-level', '1_3_years', 'open', 20000000, 32000000, 'full_time', '2026-10-25', '2026-12-20', 'on_site', NULL, 'Build reusable UI components and collaborate with product designers.', 'Experience with modern JavaScript, responsive design, and API integration.'),
(703, 9, 403, 603, 'Risk Data Analyst', 'Analyze operational data and support evidence-based risk decisions.', 'Monday-Friday, 08:00-17:00', 'working', 'Mid-level', '1_3_years',  'closed', 22000000, 35000000, 'full_time', '2026-09-01', '2026-10-31', 'external', 'recruitment@beacon.example.test', 'Prepare analytical reports and monitor data quality.', 'SQL proficiency, analytical thinking, and clear written communication.'),
(704, 14, 404, 604, 'Junior Health Data Analyst', 'Support data quality and reporting for digital health services.', 'Monday-Friday, 09:00-18:00', 'off', 'Junior', 'under_1_year', 'open', NULL, NULL, 'full_time', '2026-11-01', '2026-12-25', 'on_site', NULL, 'Validate health datasets and prepare recurring reports.', 'Attention to detail and interest in healthcare data, salary negotiable.'),
(705, 15, 405, 605, 'Clinical Operations Coordinator', 'Coordinate training operations for a growing learning network.', 'Monday-Saturday, 08:30-17:30', 'working', 'Entry-level', 'no_experience', 'open', 12000000, 18000000, 'internship', '2026-11-05', '2027-12-30', 'on_site', NULL, 'Coordinate schedules, maintain records, and support instructors.', 'Strong organisation and communication skills; no prior experience required.'),
(706, 4, 401, 606, 'Part-time Backend Developer', 'Support API maintenance for the ongoing platform talent pool.', 'Flexible, approximately 20 hours per week', 'not_specified', 'Mid-level', '1_3_years', 'open', 18000000, NULL, 'part_time', '2026-11-10', '2027-12-15', 'on_site', NULL, 'Fix service issues and add small API features.', 'Backend experience and availability for part-time work.'),
(707, 10, 401, 606, 'Contract Machine Learning Engineer', 'Deliver a fixed-term model evaluation and deployment project.', 'Monday-Friday, 09:00-18:00', 'off', 'Senior', 'over_5_years', 'open', NULL, 50000000, 'contract', '2026-11-12', '2027-12-20', 'on_site', NULL, 'Evaluate models and implement reliable inference pipelines.', 'Production machine-learning experience and strong Python skills.');

INSERT INTO work_location (job_posting_id, province_city, address) VALUES
(701, 'Ho Chi Minh City', '1 Le Duan, District 1'),
(701, 'Da Nang', '50 Bach Dang, Hai Chau'),
(702, 'Ho Chi Minh City', '12 Nguyen Hue, District 1'),
(702, 'Hanoi', '35 Duy Tan, Cau Giay'),
(703, 'Ho Chi Minh City', '88 Cach Mang Thang Tam, District 3'),
(704, 'Hanoi', '20 Tran Hung Dao, Hoan Kiem'),
(704, 'Da Nang', '22 Bach Dang, Hai Chau'),
(705, 'Da Nang', '5 Vo Nguyen Giap, Ngu Hanh Son'),
(706, 'Ho Chi Minh City', '1 Le Duan, District 1'),
(707, 'Ho Chi Minh City', '1 Le Duan, District 1');

INSERT INTO candidate_save_job_posting (candidate_id, job_posting_id, saved_date) VALUES
(101, 701, '2026-10-21 08:00:00'),
(102, 702, '2026-10-26 09:00:00'),
(103, 701, '2026-10-27 10:00:00'),
(104, 703, '2026-10-01 11:00:00'),
(105, 704, '2026-11-03 12:00:00'),
(105, 705, '2026-11-06 13:00:00'),
(101, 706, '2026-11-13 14:00:00'),
(102, 707, '2026-11-14 15:00:00');

INSERT INTO application
(application_id, candidate_id, cv_no, job_posting_id, submission_time, contact_name, email, phone_number, work_location, ai_analyze_cv, personal_data_usage_agreed, application_status)
VALUES
(801, 101, 1, 701, '2026-10-22 09:00:00', 'An Nguyen', 'an.nguyen@example.test', '0901000101', 'Ho Chi Minh City', TRUE, TRUE, 'viewed'),
(802, 101, 2, 701, '2026-10-30 09:15:00', 'An Nguyen', 'an.nguyen@example.test', '0901000101', 'Da Nang', FALSE, TRUE, 'interviewing'),
(803, 102, 1, 702, '2026-10-27 10:30:00', 'Binh Tran', 'binh.tran@example.test', '0901000102', 'Ho Chi Minh City', TRUE, TRUE, 'viewed'),
(804, 103, 1, 704, '2026-11-04 11:45:00', 'Chi Le', 'chi.le@example.test', '0901000103', 'Hanoi', FALSE, TRUE, 'rejected'),
(805, 104, 2, 705, '2026-11-08 14:00:00', 'Duc Pham', 'duc.pham@example.test', '0901000104', 'Da Nang', TRUE, TRUE, 'submitted'),
(806, 105, 1, 704, '2026-11-06 09:20:00', 'Ha Vo', 'ha.vo@example.test', '0901000105', 'Hanoi', TRUE, TRUE, 'accepted');

INSERT INTO interview
(interview_id, application_id, conducting_employer_id, start_time, end_time, interview_mode, venue_or_meeting_link, interview_status, feedback, round_type)
VALUES
(901, 802, 202, '2026-11-12 09:00:00', '2026-11-12 10:00:00', 'online', 'https://meet.example.test/round-1', 'completed', 'Strong system-design fundamentals, proceed to technical round.', 'screening'),
(902, 802, 201, '2026-11-20 14:00:00', '2026-11-20 15:30:00', 'online', 'https://meet.example.test/round-2', 'scheduled', NULL, 'technical'),
(903, 803, 203, '2026-11-19 10:00:00', '2026-11-19 11:00:00', 'in_person', '12 Nguyen Hue, District 1', 'scheduled', NULL, 'screening'),
(904, 803, 204, '2026-11-21 13:30:00', '2026-11-21 14:30:00', 'online', 'https://meet.example.test/commerce-tech', 'scheduled', NULL, 'technical'),
(905, 805, 210, '2026-11-23 09:30:00', '2026-11-23 10:15:00', 'in_person', '5 Vo Nguyen Giap, Ngu Hanh Son', 'scheduled', NULL, 'screening'),
(906, 805, 209, '2026-11-25 09:00:00', '2026-11-25 09:45:00', 'online', 'https://meet.example.test/cancelled-final', 'cancelled', NULL, 'final');

UPDATE job_posting AS jp
SET application_count = (
    SELECT COUNT(*)
    FROM application AS a
    WHERE a.job_posting_id = jp.job_posting_id
);

SELECT 'user_account' AS table_name, COUNT(*) AS row_count FROM user_account
UNION ALL SELECT 'company', COUNT(*) FROM company
UNION ALL SELECT 'candidate', COUNT(*) FROM candidate
UNION ALL SELECT 'employer', COUNT(*) FROM employer
UNION ALL SELECT 'administrator', COUNT(*) FROM administrator
UNION ALL SELECT 'job_category', COUNT(*) FROM job_category
UNION ALL SELECT 'candidate_interest_job_category', COUNT(*) FROM candidate_interest_job_category
UNION ALL SELECT 'candidate_desired_location', COUNT(*) FROM candidate_desired_location
UNION ALL SELECT 'cv', COUNT(*) FROM cv
UNION ALL SELECT 'job_alert', COUNT(*) FROM job_alert
UNION ALL SELECT 'candidate_save_job_posting', COUNT(*) FROM candidate_save_job_posting
UNION ALL SELECT 'candidate_follow_company', COUNT(*) FROM candidate_follow_company
UNION ALL SELECT 'verification_task', COUNT(*) FROM verification_task
UNION ALL SELECT 'recruitment_need', COUNT(*) FROM recruitment_need
UNION ALL SELECT 'declares_recruitment_need', COUNT(*) FROM declares_recruitment_need
UNION ALL SELECT 'recruitment_campaign', COUNT(*) FROM recruitment_campaign
UNION ALL SELECT 'job_posting', COUNT(*) FROM job_posting
UNION ALL SELECT 'work_location', COUNT(*) FROM work_location
UNION ALL SELECT 'application', COUNT(*) FROM application
UNION ALL SELECT 'interview', COUNT(*) FROM interview;
