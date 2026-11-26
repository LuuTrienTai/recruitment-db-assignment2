USE recruitment_db;

SET FOREIGN_KEY_CHECKS = 0;
-- DELETE TABLE FOR RECREATE
DROP TABLE IF EXISTS cv;
DROP TABLE IF EXISTS candidate_save_job_posting;
DROP TABLE IF EXISTS job_alert;
DROP TABLE IF EXISTS application;
DROP TABLE IF EXISTS work_location;
DROP TABLE IF EXISTS candidate_interest_job_category;
DROP TABLE IF EXISTS job_posting;
DROP TABLE IF EXISTS declares_recruitment_need;
DROP TABLE IF EXISTS recruitment_need;
DROP TABLE IF EXISTS recruitment_campaign;
DROP TABLE IF EXISTS candidate_desired_location;
DROP TABLE IF EXISTS candidate;
DROP TABLE IF EXISTS candidate_follow_company;
DROP TABLE IF EXISTS job_category;
DROP TABLE IF EXISTS employer;
DROP TABLE IF EXISTS administrator;
DROP TABLE IF EXISTS company;
DROP TABLE IF EXISTS user_account;
DROP TABLE IF EXISTS verification_task;
DROP TABLE IF EXISTS interview;
SET FOREIGN_KEY_CHECKS = 1;

#######
CREATE TABLE user_account(
    account_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    gender VARCHAR(25) NOT NULL,
    email_address VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NULL,
    phone_number VARCHAR(25) NOT NULL,
    registration_method VARCHAR(255) NOT NULL,
    account_status VARCHAR(10) NOT NULL,
    created_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_user PRIMARY KEY (account_id),
    CONSTRAINT chk_user_registration_method CHECK (registration_method IN ('email', 'Google', 'Facebook', 'LinkedIn')),
    CONSTRAINT chk_user_status CHECK (account_status IN ('unverified', 'active', 'locked')),
    CONSTRAINT chk_user_email_password CHECK (
        registration_method <> 'email'
        OR (hashed_password IS NOT NULL AND CHAR_LENGTH(TRIM(hashed_password)) > 0)
    )
);

CREATE TABLE company(
    company_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    sector VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    name VARCHAR(255) NOT NULL,
    company_type VARCHAR(25) NOT NULL,
    CONSTRAINT pk_company PRIMARY KEY (company_id),
    CONSTRAINT chk_company_type CHECK (company_type IN ('normal', 'pro'))
);

CREATE TABLE job_category(
    category_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    parent_category_id INT UNSIGNED NULL,
    name TEXT NOT NULL,
    category_level VARCHAR(25) NOT NULL,
    CONSTRAINT pk_job_category PRIMARY KEY (category_id),
    CONSTRAINT fk_job_category_parent FOREIGN KEY (parent_category_id)
        REFERENCES job_category(category_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_job_category_level CHECK (category_level IN ('group', 'profession', 'specialisation')),
    CONSTRAINT chk_job_category_parent_rule CHECK (
        (category_level = 'group' AND parent_category_id IS NULL)
        OR (category_level IN ('profession', 'specialisation') AND parent_category_id IS NOT NULL)
    ),
    CONSTRAINT chk_job_category_no_self_parent CHECK (
        parent_category_id IS NULL OR parent_category_id <> category_id
    )
);

CREATE TABLE candidate(
    candidate_id INT UNSIGNED NOT NULL,
    expected_salary DECIMAL(12,2) NOT NULL,
    experience_level VARCHAR(25) NOT NULL,
    work_at_other_place BOOLEAN NOT NULL DEFAULT FALSE,
    receive_suggestion BOOLEAN NOT NULL DEFAULT TRUE,
    receive_promotion BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_candidate PRIMARY KEY (candidate_id),
    CONSTRAINT fk_candidate_account FOREIGN KEY (candidate_id)
        REFERENCES user_account(account_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_candidate_salary CHECK (expected_salary > 0),
    CONSTRAINT chk_candidate_experience CHECK (
        experience_level IN ('no_experience', 'under_1_year', '1_3_years', '3_5_years', 'over_5_years')
    )
);

CREATE TABLE employer(
    employer_id INT UNSIGNED NOT NULL,
    company_id INT UNSIGNED NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    CONSTRAINT pk_employer PRIMARY KEY (employer_id),
    CONSTRAINT fk_employer FOREIGN KEY (employer_id)
        REFERENCES user_account(account_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_employer_company FOREIGN KEY (company_id)
        REFERENCES company(company_id)
        ON DELETE RESTRICT
);

CREATE TABLE administrator(
    admin_id INT UNSIGNED NOT NULL,
    administrative_access_level VARCHAR(50) NOT NULL,
    CONSTRAINT pk_admin PRIMARY KEY (admin_id),
    CONSTRAINT fk_admin FOREIGN KEY (admin_id)
        REFERENCES user_account(account_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_admin_level CHECK (administrative_access_level IN ('reviewer', 'manager', 'super_admin'))
);


CREATE TABLE cv(
    candidate_id INT UNSIGNED NOT NULL,
    cv_no INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(500) NOT NULL,
    file_format VARCHAR(10) NOT NULL,
    file_size_bytes INT UNSIGNED NOT NULL,
    uploaded_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_cv PRIMARY KEY (candidate_id, cv_no),
    CONSTRAINT fk_cv_candidate FOREIGN KEY (candidate_id)
        REFERENCES candidate(candidate_id)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cv_format CHECK (file_format IN ('pdf','doc','docx')),
    CONSTRAINT chk_cv_size CHECK (file_size_bytes > 0 AND file_size_bytes <= 5242880)
);


CREATE TABLE job_alert(
    candidate_id INT UNSIGNED NOT NULL,
    alert_no INT UNSIGNED NOT NULL,
    search_keyword VARCHAR(255) NOT NULL,
    province_city VARCHAR(50) NULL, 
    district VARCHAR(50) NULL,
    salary_level VARCHAR(50) NOT NULL,
    experience_level VARCHAR(25) NOT NULL,
    professional_role VARCHAR(50) NOT NULL,
    employment_type VARCHAR(50) NOT NULL,
    notification_frequency VARCHAR(25) NOT NULL,
    delivery_channel VARCHAR(50) NOT NULL,
    consent_confirmed BOOLEAN NOT NULL,
    consent_confirmed_at DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_job_alert PRIMARY KEY (candidate_id, alert_no),
    CONSTRAINT fk_job_alert_candidate FOREIGN KEY (candidate_id)
        REFERENCES candidate(candidate_id)
        ON DELETE CASCADE,
    CONSTRAINT chk_job_notification_frequency CHECK (notification_frequency IN ('daily', 'weekly')),
    CONSTRAINT chk_job_alert_channel CHECK (delivery_channel IN ('email','app','both')),
    CONSTRAINT chk_job_alert_consent CHECK (consent_confirmed = TRUE AND consent_confirmed_at IS NOT NULL),
    CONSTRAINT chk_job_alert_keyword CHECK (CHAR_LENGTH(TRIM(search_keyword)) > 0),
    CONSTRAINT chk_job_alert_location CHECK (district IS NULL OR province_city IS NOT NULL)
);

CREATE TABLE candidate_desired_location(
    candidate_id INT UNSIGNED NOT NULL,
    province_city VARCHAR(100) NOT NULL,
    CONSTRAINT pk_desired_location PRIMARY KEY (candidate_id, province_city),
    CONSTRAINT fk_desired_location_candidate FOREIGN KEY (candidate_id)
        REFERENCES candidate(candidate_id)
        ON DELETE CASCADE
);

CREATE TABLE candidate_interest_job_category(
    candidate_id INT UNSIGNED NOT NULL,
    category_id INT UNSIGNED NOT NULL,
    CONSTRAINT pk_interest_category PRIMARY KEY (candidate_id, category_id),
    CONSTRAINT fk_interest_category_candidate FOREIGN KEY (candidate_id)
        REFERENCES candidate(candidate_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_interest_category_job_category FOREIGN KEY (category_id)
        REFERENCES job_category(category_id)
        ON DELETE CASCADE
);

CREATE TABLE candidate_follow_company(
    candidate_id INT UNSIGNED NOT NULL,
    company_id INT UNSIGNED NOT NULL,
    followed_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_follow_company PRIMARY KEY (candidate_id, company_id),
    CONSTRAINT fk_follow_company_candidate FOREIGN KEY (candidate_id)
        REFERENCES candidate(candidate_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_follow_company_company FOREIGN KEY (company_id)
        REFERENCES company(company_id)
        ON DELETE CASCADE
);

CREATE TABLE recruitment_need(
    need_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    declared_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    professional_position VARCHAR(255) NOT NULL,
    job_level VARCHAR(25) NOT NULL,
    number_employee_required INT UNSIGNED NOT NULL,
    expected_completion_date DATE NULL,
    budget DECIMAL(15,2) NULL,
    budget_source VARCHAR(255) NULL,
    consultation TEXT NULL,
    CONSTRAINT pk_recruitment_need PRIMARY KEY (need_id),
    CONSTRAINT chk_need_number CHECK (number_employee_required > 0),
    CONSTRAINT chk_need_budget CHECK (budget IS NULL OR budget >= 0),
    CONSTRAINT chk_need_date CHECK (expected_completion_date IS NULL OR expected_completion_date > declared_date)
);

CREATE TABLE declares_recruitment_need(
    need_id INT UNSIGNED NOT NULL,
    employer_id INT UNSIGNED NOT NULL,
    company_id INT UNSIGNED NOT NULL,
    CONSTRAINT pk_declares PRIMARY KEY (need_id),
    CONSTRAINT fk_declares_need FOREIGN KEY (need_id)
        REFERENCES recruitment_need(need_id) ON DELETE CASCADE,
    CONSTRAINT fk_declares_employer FOREIGN KEY (employer_id)
        REFERENCES employer(employer_id) ON DELETE RESTRICT,
    CONSTRAINT fk_declares_company FOREIGN KEY (company_id)
        REFERENCES company(company_id) ON DELETE RESTRICT
);

CREATE TABLE verification_task(
    task_type VARCHAR(50) NOT NULL,
    employer_id INT UNSIGNED NOT NULL,
    admin_id INT UNSIGNED NULL,
    task_status VARCHAR(25) NOT NULL DEFAULT 'not_completed',
    submitted_document TEXT NULL,
    submitted_at DATE NULL DEFAULT (CURRENT_DATE),
    reviewed_at DATE NULL,
    CONSTRAINT pk_verification_task PRIMARY KEY (task_type, employer_id),
    CONSTRAINT fk_verification_employer FOREIGN KEY (employer_id)
        REFERENCES employer(employer_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_verification_admin FOREIGN KEY (admin_id)
        REFERENCES administrator(admin_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_task_type CHECK (task_type IN ('phone_verification','company_information','business_registration','personal_data_agreement')),
    CONSTRAINT chk_verification_status CHECK (task_status IN ('not_completed', 'submitted', 'approved', 'rejected')),
    CONSTRAINT chk_verification_date CHECK (reviewed_at IS NULL OR (submitted_at IS NOT NULL AND reviewed_at >= submitted_at)),
    CONSTRAINT chk_verification_auto_no_admin CHECK (
        task_type NOT IN ('phone_verification', 'personal_data_agreement') OR admin_id IS NULL
    ),
    CONSTRAINT chk_verification_manual_review CHECK (
        task_type NOT IN ('company_information', 'business_registration')
        OR task_status NOT IN ('approved', 'rejected')
        OR (admin_id IS NOT NULL AND reviewed_at IS NOT NULL)
    )
);

CREATE TABLE recruitment_campaign(
    campaign_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    created_by_employer_id INT UNSIGNED NOT NULL,
    managed_by_employer_id INT UNSIGNED NOT NULL,
    recruitment_need_id INT UNSIGNED NULL,
    name TEXT NOT NULL,
    creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    campaign_status VARCHAR(20) NOT NULL,
    CONSTRAINT pk_recruitment_campaign PRIMARY KEY (campaign_id),
    CONSTRAINT uq_campaign_need UNIQUE (recruitment_need_id),
    CONSTRAINT fk_campaign_created_employer FOREIGN KEY (created_by_employer_id)
        REFERENCES employer(employer_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_campaign_manage_employer FOREIGN KEY (managed_by_employer_id)
        REFERENCES employer(employer_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_campaign_need FOREIGN KEY (recruitment_need_id)
        REFERENCES recruitment_need(need_id)
        ON DELETE SET NULL,
    CONSTRAINT chk_campaign_status CHECK (campaign_status IN ('running', 'stopped'))
);

CREATE TABLE job_posting(
    job_posting_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    category_id INT UNSIGNED NOT NULL,
    company_id INT UNSIGNED NOT NULL,
    campaign_id INT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    working_hours VARCHAR(100) NOT NULL,
    saturday_work_policy VARCHAR(50) NOT NULL,
    job_level VARCHAR(50) NOT NULL,
    required_experience VARCHAR(50) NOT NULL,
    job_status VARCHAR(25) NOT NULL,
    min_salary DECIMAL(12,2) NULL,
    max_salary DECIMAL(12,2) NULL,
    employment_type VARCHAR(25) NOT NULL,
    posted_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    application_deadline DATE NOT NULL DEFAULT (CURRENT_DATE),
    application_method VARCHAR(50) NOT NULL,
    contact_detail VARCHAR(255) NULL,
    employee_responsibilities VARCHAR(255) NOT NULL,
    requirements TEXT NOT NULL,
    application_count INT UNSIGNED NOT NULL DEFAULT 0,
    CONSTRAINT pk_job_posting PRIMARY KEY (job_posting_id),
    CONSTRAINT fk_job_posting_category FOREIGN KEY (category_id)
        REFERENCES job_category(category_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_job_posting_company FOREIGN KEY (company_id)
        REFERENCES company(company_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_job_posting_campaign FOREIGN KEY (campaign_id)
        REFERENCES recruitment_campaign(campaign_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_job_posting_status CHECK (job_status IN ('open','closed')),
    CONSTRAINT chk_job_posting_min_salary CHECK (min_salary IS NULL OR min_salary > 0),
    CONSTRAINT chk_job_posting_max_salary CHECK (max_salary IS NULL OR max_salary > 0),
    CONSTRAINT chk_job_posting_salary CHECK (min_salary IS NULL OR max_salary IS NULL OR max_salary >= min_salary),
    CONSTRAINT chk_job_posting_deadline CHECK (application_deadline > posted_date),
    CONSTRAINT chk_job_posting_saturday_policy CHECK (saturday_work_policy IN ('working', 'off', 'not_specified')),
    CONSTRAINT chk_job_posting_experience CHECK (required_experience IN ('no_experience', 'under_1_year', '1_3_years', '3_5_years', 'over_5_years')),
    CONSTRAINT chk_job_posting_employment_type CHECK (employment_type IN ('full_time', 'part_time', 'contract', 'internship')),
    CONSTRAINT chk_job_posting_application_method CHECK (application_method IN ('on_site', 'external')),
    CONSTRAINT chk_job_posting_external_contact CHECK (
        application_method <> 'external'
        OR (contact_detail IS NOT NULL AND CHAR_LENGTH(TRIM(contact_detail)) > 0)
    )
);

CREATE TABLE candidate_save_job_posting(
    candidate_id INT UNSIGNED NOT NULL,
    job_posting_id INT UNSIGNED NOT NULL,
    saved_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_save_job PRIMARY KEY (candidate_id, job_posting_id),
    CONSTRAINT fk_save_job_candidate FOREIGN KEY (candidate_id)
        REFERENCES candidate(candidate_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_save_job_posting FOREIGN KEY (job_posting_id)
        REFERENCES job_posting(job_posting_id)
        ON DELETE CASCADE
);

CREATE TABLE work_location(
    job_posting_id INT UNSIGNED NOT NULL,
    province_city VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    CONSTRAINT pk_work_locations PRIMARY KEY (job_posting_id, province_city, address),
    CONSTRAINT fk_work_locations_job FOREIGN KEY (job_posting_id)
        REFERENCES job_posting(job_posting_id)
        ON DELETE CASCADE
);


CREATE TABLE application(
    application_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    candidate_id INT UNSIGNED NOT NULL,
    cv_no INT UNSIGNED NOT NULL,
    job_posting_id INT UNSIGNED NOT NULL,
    submission_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(255) NOT NULL,
    work_location VARCHAR(500) NOT NULL,
    ai_analyze_cv BOOLEAN NOT NULL DEFAULT FALSE,
    personal_data_usage_agreed BOOLEAN NOT NULL DEFAULT FALSE,
    application_status VARCHAR(25) NOT NULL,
    CONSTRAINT pk_application PRIMARY KEY (application_id),
    CONSTRAINT fk_application_cv FOREIGN KEY (candidate_id, cv_no)
        REFERENCES cv(candidate_id, cv_no)
        ON DELETE RESTRICT,
    CONSTRAINT fk_application_job FOREIGN KEY (job_posting_id)
        REFERENCES job_posting(job_posting_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_application_status CHECK (application_status IN ('submitted','viewed','interviewing','accepted','rejected')),
    CONSTRAINT chk_application_consent CHECK (personal_data_usage_agreed = TRUE),
    CONSTRAINT chk_application_contact CHECK (
        CHAR_LENGTH(TRIM(contact_name)) > 0
        AND CHAR_LENGTH(TRIM(email)) > 0
        AND CHAR_LENGTH(TRIM(phone_number)) > 0
        AND CHAR_LENGTH(TRIM(work_location)) > 0
    )
);

CREATE TABLE interview(
    interview_id INT UNSIGNED NOT NULL AUTO_INCREMENT,
    application_id INT UNSIGNED NOT NULL,
    conducting_employer_id INT UNSIGNED NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    interview_mode VARCHAR(25) NOT NULL,
    venue_or_meeting_link TEXT NULL,
    interview_status VARCHAR (25) NOT NULL,
    feedback TEXT NULL,
    round_type VARCHAR(25) NOT NULL,
    CONSTRAINT pk_interview PRIMARY KEY (interview_id),
    CONSTRAINT fk_interview_application FOREIGN KEY (application_id)
        REFERENCES application(application_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_interview_employer FOREIGN KEY (conducting_employer_id)
        REFERENCES employer(employer_id)
        ON DELETE RESTRICT,
    CONSTRAINT chk_interview_status CHECK (interview_status IN ('scheduled', 'completed', 'cancelled')),
    CONSTRAINT chk_interview_time CHECK (end_time > start_time),
    CONSTRAINT chk_interview_mode CHECK (interview_mode IN ('online','in_person')),
    CONSTRAINT chk_interview_feedback CHECK (feedback IS NULL OR interview_status = 'completed')
);