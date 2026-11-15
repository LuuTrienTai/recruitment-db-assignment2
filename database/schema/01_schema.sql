-- TODO: M2: schema Assignment 1 cuối cùng; chưa triển khai.
-- Đây là file giữ chỗ, chưa có SQL thực thi.
USE recruitment_db;

SET FOREIGN_KEY_CHECKS =0;
-- DELETE TABLE FOR RECREATE
DROP TABLE IF EXISTS cv;
DROP TABLE IF EXISTS candidate_save_job_posting;
DROP TABLE IF EXISTS job_alert;
DROP TABLE IF EXISTS application;
DROP TABLE IF EXISTS work_locations;
DROP TABLE IF EXISTS candidate_interest_job_category;
DROP TABLE IF EXISTS job_posting;
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
    accountID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    gender VARCHAR(25) NOT NULL,
    email_address VARCHAR(255) NOT NULL UNIQUE,
    hashed_password VARCHAR(255) NOT NULL,
    phone_number VARCHAR(25) NOT NULL,
    registeration_method VARCHAR(255) NOT NULL,
    account_status VARCHAR(10) NOT NULL,
    created_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    CONSTRAINT pk_user PRIMARY KEY (accountID),
    CONSTRAINT registeration_method_select CHECK (registeration_method IN ('email', 'Google', 'Facebook', 'LinkedIn')),
    CONSTRAINT chk_user_status CHECK (account_status IN ('unverified', 'active', 'locked'))
);

CREATE TABLE company(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    sector VARCHAR(255) NOT NULL,
    address TEXT NOT NULL,
    name VARCHAR(255),
    type VARCHAR(25),
    CONSTRAINT pk_company PRIMARY KEY (ID)
);

CREATE TABLE job_category(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    parent_job_categoryID INT UNSIGNED NULL,
    name TEXT NOT NULL,
    level VARCHAR(25) NOT NULL,
    CONSTRAINT pk_job_category PRIMARY KEY (ID),
    CONSTRAINT fk_job_category_parent FOREIGN KEY (parent_job_categoryID)
        REFERENCES job_category(ID)
        ON DELETE SET NULL
);

CREATE TABLE candidate(
    candidateID INT UNSIGNED NOT NULL,
    expected_salary DECIMAL(12,2) NOT NULL,
    experience_level VARCHAR(25) NOT NULL,
    work_at_other_place BOOLEAN NOT NULL DEFAULT FALSE,
    receive_suggestion BOOLEAN NOT NULL DEFAULT TRUE,
    receive_promotion BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_candidate PRIMARY KEY (candidateID),
    CONSTRAINT fk_candidate_account FOREIGN KEY (candidateID)
        REFERENCES user_account(accountID)
        ON DELETE CASCADE,
    CONSTRAINT chk_candidate_salary CHECK (expected_salary >= 0)

);

CREATE TABLE employer(
    employerID INT UNSIGNED NOT NULL,
    companyID INT UNSIGNED NOT NULL,
    job_title VARCHAR(50) NOT NULL,
    CONSTRAINT pk_employer PRIMARY KEY (employerID),
    CONSTRAINT fk_employer FOREIGN KEY (employerID)
        REFERENCES user_account(accountID)
        ON DELETE CASCADE,
    CONSTRAINT fk_employer_company FOREIGN KEY (companyID)
        REFERENCES company(ID)
        ON DELETE RESTRICT
);

CREATE TABLE administrator(
    adminID INT UNSIGNED NOT NULL,
    administrative_access_level INT UNSIGNED NOT NULL,
    CONSTRAINT pk_admin PRIMARY KEY (adminID),
    CONSTRAINT fk_admin FOREIGN KEY (adminID)
        REFERENCES user_account(accountID)
        ON DELETE CASCADE,
    CONSTRAINT chk_admin_level CHECK (administrative_access_level BETWEEN 1 AND 99)
);


CREATE TABLE cv(
    candidateID INT UNSIGNED NOT NULL,
    cvNo INT UNSIGNED NOT NULL,
    name VARCHAR(255) NOT NULL,
    location VARCHAR(500) NOT NULL,
    format VARCHAR(10) NOT NULL,
    size INT UNSIGNED NOT NULL,
    uploaded_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_cv PRIMARY KEY (candidateID, cvNo),
    CONSTRAINT fk_cv_candidate FOREIGN KEY (candidateID)
        REFERENCES candidate(candidateID)
        ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT chk_cv_format CHECK (format IN ('pdf')),
    CONSTRAINT chk_cv_size CHECK (size > 0 AND size < 5242880)
);


CREATE TABLE job_alert(
    candidateID INT UNSIGNED NOT NULL,
    alert_no INT UNSIGNED NOT NULL,
    search_keyword VARCHAR(255) NOT NULL,
    province_city VARCHAR(50) NULL, 
    district VARCHAR(50) NULL,
    salary_level INT UNSIGNED NOT NULL,
    experience_level INT UNSIGNED NOT NULL,
    professional_role VARCHAR(50) NOT NULL,
    type_employment VARCHAR(50) NOT NULL,
    notification_frequency VARCHAR(25) NOT NULL,
    delivery_channel VARCHAR(50) NOT NULL,
    consent_confirmed BOOLEAN NOT NULL,
    confirmed_time DATETIME NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_job_alert PRIMARY KEY (candidateID, alert_no),
    CONSTRAINT fk_job_alert_candidate FOREIGN KEY (candidateID)
        REFERENCES candidate(candidateID)
        ON DELETE CASCADE,
    CONSTRAINT chk_job_notification_frequency CHECK (notification_frequency IN ('daily', 'weekly')),
    CONSTRAINT chk_job_alert_channel CHECK (delivery_channel IN ('email','app','both')),
    CONSTRAINT chk_job_alert_consent CHECK (consent_confirmed = FALSE OR confirmed_time IS NOT NULL)
    
);

CREATE TABLE candidate_desired_location(
    candidateID INT UNSIGNED NOT NULL,
    province_city VARCHAR(100) NOT NULL,
    CONSTRAINT pk_desired_location PRIMARY KEY (candidateID, province_city),
    CONSTRAINT fk_desired_location_candidate FOREIGN KEY (candidateID)
        REFERENCES candidate(candidateID)
        ON DELETE CASCADE
);

CREATE TABLE candidate_interest_job_category(
    candidateID INT UNSIGNED NOT NULL,
    job_categoryID INT UNSIGNED NOT NULL,
    CONSTRAINT pk_interest_category PRIMARY KEY (candidateID, job_categoryID),
    CONSTRAINT fk_interest_category_candidate FOREIGN KEY (candidateID)
        REFERENCES candidate(candidateID)
        ON DELETE CASCADE,
    CONSTRAINT fk_interest_category_job_category FOREIGN KEY (job_categoryID)
        REFERENCES job_category(ID)
        ON DELETE CASCADE
);

CREATE TABLE candidate_follow_company(
    candidateID INT UNSIGNED NOT NULL,
    companyID INT UNSIGNED NOT NULL,
    followed_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_follow_company PRIMARY KEY (candidateID, companyID),
    CONSTRAINT fk_follow_company_candidate FOREIGN KEY (candidateID)
        REFERENCES candidate(candidateID)
        ON DELETE CASCADE,
    CONSTRAINT fk_follow_company_company FOREIGN KEY (companyID)
        REFERENCES company(ID)
        ON DELETE CASCADE
);

CREATE TABLE recruitment_need(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    employerID INT UNSIGNED NOT NULL,
    companyID INT UNSIGNED NOT NULL,
    declare_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    professional_position VARCHAR(255) NOT NULL,
    job_level VARCHAR(25) NOT NULL,
    number_employee_required INT UNSIGNED NOT NULL,
    expected_completion_date DATE NULL,
    budget DECIMAL(15,2) NOT NULL,
    budget_source VARCHAR(255) NULL,
    consultation TEXT NULL,
    CONSTRAINT pk_recruitment_need PRIMARY KEY (ID),
    CONSTRAINT fk_need_employer FOREIGN KEY (employerID)
        REFERENCES employer(employerID)
        ON DELETE RESTRICT,
    CONSTRAINT fk_need_company FOREIGN KEY (companyID)
        REFERENCES company(ID)
        ON DELETE RESTRICT,
    CONSTRAINT chk_need_number CHECK (number_employee_required > 0),
    CONSTRAINT chk_need_budget CHECK (budget >= 0),
    CONSTRAINT chk_need_date CHECK (expected_completion_date IS NULL OR expected_completion_date >= declare_date)
);

CREATE TABLE verification_task(
    type VARCHAR(50) NOT NULL,
    employerID INT UNSIGNED NOT NULL,
    adminID INT UNSIGNED NULL,
    status VARCHAR(25) NOT NULL DEFAULT 'not completed',
    submitted_document TEXT NOT NULL,
    submited_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    review_date DATE NULL,
    CONSTRAINT pk_verification_task PRIMARY KEY (type, employerID),
    CONSTRAINT fk_verification_employer FOREIGN KEY (employerID)
        REFERENCES employer(employerID)
        ON DELETE CASCADE,
    CONSTRAINT fk_verification_admin FOREIGN KEY (adminID)
        REFERENCES administrator(adminID)
        ON DELETE SET NULL,
    CONSTRAINT chk_task_type CHECK (type IN ('phone-number verification', 'company-information update', 'business-registration-document submission', 'agreement to personal-data processing')),
    CONSTRAINT chk_verification_status CHECK (status IN ('not completed', 'submitted', 'approved', 'rejected')),
    CONSTRAINT chk_verification_date CHECK (review_date IS NULL OR review_date >= submited_date)
);

CREATE TABLE recruitment_campaign(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    created_employerID INT UNSIGNED NOT NULL,
    manage_employerID INT UNSIGNED NOT NULL,
    recruitment_needID INT UNSIGNED NULL,
    name TEXT NOT NULL,
    creation_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL,
    CONSTRAINT pk_recruitment_campaign PRIMARY KEY (ID),
    CONSTRAINT uq_campaign_need UNIQUE (recruitment_needID),
    CONSTRAINT fk_campaign_created_employer FOREIGN KEY (created_employerID)
        REFERENCES employer(employerID)
        ON DELETE RESTRICT,
    CONSTRAINT fk_campaign_manage_employer FOREIGN KEY (manage_employerID)
        REFERENCES employer(employerID)
        ON DELETE RESTRICT,
    CONSTRAINT fk_campaign_need FOREIGN KEY (recruitment_needID)
        REFERENCES recruitment_need(ID)
        ON DELETE SET NULL,
    CONSTRAINT chk_campaign_status CHECK (status IN ('running', 'stopped'))
);

CREATE TABLE job_posting(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    classified_job_categoryID INT UNSIGNED NOT NULL,
    companyID INT UNSIGNED NOT NULL,
    recruitment_campaignID INT UNSIGNED NOT NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    working_hours INT UNSIGNED NOT NULL,
    saturday_work_policy VARCHAR(50) NOT NULL,
    job_level VARCHAR(50) NOT NULL,
    required_exp VARCHAR(50) NOT NULL,
    status VARCHAR(25) NOT NULL,
    min_salary DECIMAL(12,2) NULL,
    max_salary DECIMAL(12,2) NULL,
    employment_type VARCHAR(25) NOT NULL,
    posted_date DATE NOT NULL DEFAULT (CURRENT_DATE),
    apply_deadline DATE NOT NULL DEFAULT (CURRENT_DATE),
    apply_method VARCHAR(50) NOT NULL,
    contact_detail VARCHAR(50) NOT NULL,
    employeeResponsibilities VARCHAR(255) NOT NULL,
    requirements TEXT NOT NULL,
    CONSTRAINT pk_job_posting PRIMARY KEY (ID),
    CONSTRAINT fk_job_posting_category FOREIGN KEY (classified_job_categoryID)
        REFERENCES job_category(ID)
        ON DELETE RESTRICT,
    CONSTRAINT fk_job_posting_company FOREIGN KEY (companyID)
        REFERENCES company(ID)
        ON DELETE RESTRICT,
    CONSTRAINT fk_job_posting_campaign FOREIGN KEY (recruitment_campaignID)
        REFERENCES recruitment_campaign(ID)
        ON DELETE RESTRICT,
    CONSTRAINT chk_job_posting_status CHECK (status IN ('open','closed')),
    CONSTRAINT chk_job_posting_min_salary CHECK (min_salary IS NULL OR min_salary >= 0),
    CONSTRAINT chk_job_posting_salary CHECK (max_salary >= min_salary),
    CONSTRAINT chk_job_posting_deadline CHECK (apply_deadline >= posted_date)

);

CREATE TABLE candidate_save_job_posting(
    candidateID INT UNSIGNED NOT NULL,
    job_postingID INT UNSIGNED NOT NULL,
    saved_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_save_job PRIMARY KEY (candidateID, job_postingID),
    CONSTRAINT fk_save_job_candidate FOREIGN KEY (candidateID)
        REFERENCES candidate(candidateID)
        ON DELETE CASCADE,
    CONSTRAINT fk_save_job_posting FOREIGN KEY (job_postingID)
        REFERENCES job_posting(ID)
        ON DELETE CASCADE
);

CREATE TABLE work_locations(
    job_postingID INT UNSIGNED NOT NULL,
    province_city VARCHAR(100) NOT NULL,
    address VARCHAR(255) NOT NULL,
    CONSTRAINT pk_work_locations PRIMARY KEY (job_postingID, province_city, address),
    CONSTRAINT fk_work_locations_job FOREIGN KEY (job_postingID)
        REFERENCES job_posting(ID)
        ON DELETE CASCADE
);


CREATE TABLE application(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    candidateID INT UNSIGNED NOT NULL,
    cvNo INT UNSIGNED NOT NULL,
    job_postingID INT UNSIGNED NOT NULL,
    submission_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    contact_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    phone_number VARCHAR(255) NOT NULL,
    work_location VARCHAR(500) NOT NULL,
    AI_analyze_CV BOOLEAN NOT NULL DEFAULT FALSE,
    personal_data_usage BOOLEAN NOT NULL DEFAULT FALSE,
    status VARCHAR(25) NOT NULL,
    CONSTRAINT pk_application PRIMARY KEY (ID),
    CONSTRAINT fk_application_cv FOREIGN KEY (candidateID, cvNo)
        REFERENCES cv(candidateID, cvNo)
        ON DELETE RESTRICT,
    CONSTRAINT fk_application_job FOREIGN KEY (job_postingID)
        REFERENCES job_posting(ID)
        ON DELETE RESTRICT,
    CONSTRAINT chk_application_status CHECK (status IN ('submitted','viewed','interviewing','accepted','rejected'))
);

CREATE TABLE interview(
    ID INT UNSIGNED NOT NULL AUTO_INCREMENT,
    applicationID INT UNSIGNED NOT NULL,
    conduct_employerID INT UNSIGNED NOT NULL,
    start_time DATETIME NOT NULL,
    end_time DATETIME NOT NULL,
    mode VARCHAR(25) NOT NULL,
    venue_meeting_link TEXT NULL,
    status VARCHAR (25) NOT NULL,
    feedback TEXT NULL,
    round_type VARCHAR(25) NOT NULL,
    CONSTRAINT pk_interview PRIMARY KEY (ID),
    CONSTRAINT fk_interview_application FOREIGN KEY (applicationID)
        REFERENCES application(ID)
        ON DELETE CASCADE,
    CONSTRAINT fk_interview_employer FOREIGN KEY (conduct_employerID)
        REFERENCES employer(employerID)
        ON DELETE RESTRICT,
    CONSTRAINT chk_interview_status CHECK (status IN ('scheduled', 'completed', 'cancelled')),
    CONSTRAINT chk_interview_time CHECK (end_time > start_time),
    CONSTRAINT chk_interview_mode CHECK (mode IN ('online','in person'))
);

