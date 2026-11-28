-- Job-posting CRUD. The initial status is open; status transitions belong to M6.
USE recruitment_db;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_validate_job_posting$$
CREATE PROCEDURE sp_validate_job_posting(
    IN p_category_id INT UNSIGNED,
    IN p_company_id INT UNSIGNED,
    IN p_campaign_id INT UNSIGNED,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_working_hours VARCHAR(100),
    IN p_saturday_work_policy VARCHAR(50),
    IN p_job_level VARCHAR(50),
    IN p_required_experience VARCHAR(50),
    IN p_min_salary DECIMAL(12,2),
    IN p_max_salary DECIMAL(12,2),
    IN p_employment_type VARCHAR(25),
    IN p_posted_date DATE,
    IN p_application_deadline DATE,
    IN p_application_method VARCHAR(50),
    IN p_contact_detail VARCHAR(255),
    IN p_employee_responsibilities VARCHAR(255),
    IN p_requirements TEXT
)
BEGIN
    DECLARE v_record_count INT DEFAULT 0;
    DECLARE v_category_level VARCHAR(25);
    DECLARE v_campaign_company_id INT UNSIGNED;

    IF p_title IS NULL OR CHAR_LENGTH(TRIM(p_title)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job title is required.';
    END IF;
    IF p_description IS NULL OR CHAR_LENGTH(TRIM(p_description)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job description is required.';
    END IF;
    IF p_working_hours IS NULL OR CHAR_LENGTH(TRIM(p_working_hours)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Working hours are required.';
    END IF;
    IF p_saturday_work_policy IS NULL
       OR p_saturday_work_policy NOT IN ('working', 'off', 'not_specified') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Saturday-work policy must be working, off, or not_specified.';
    END IF;
    IF p_job_level IS NULL OR CHAR_LENGTH(TRIM(p_job_level)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job level is required.';
    END IF;
    IF p_required_experience IS NULL
       OR p_required_experience NOT IN ('no_experience', 'under_1_year', '1_3_years', '3_5_years', 'over_5_years') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Required experience must be a supported experience level.';
    END IF;
    IF p_employment_type IS NULL
       OR p_employment_type NOT IN ('full_time', 'part_time', 'contract', 'internship') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Employment type must be full_time, part_time, contract, or internship.';
    END IF;
    IF p_application_method IS NULL OR p_application_method NOT IN ('on_site', 'external') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Application method must be on_site or external.';
    END IF;
    IF p_employee_responsibilities IS NULL
       OR CHAR_LENGTH(TRIM(p_employee_responsibilities)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Employee responsibilities are required.';
    END IF;
    IF p_requirements IS NULL OR CHAR_LENGTH(TRIM(p_requirements)) = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job requirements are required.';
    END IF;
    IF p_posted_date IS NULL OR p_application_deadline IS NULL
       OR p_application_deadline <= p_posted_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Application deadline must be later than the posted date.';
    END IF;
    IF (p_min_salary IS NOT NULL AND p_min_salary <= 0)
       OR (p_max_salary IS NOT NULL AND p_max_salary <= 0) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Salary values must be positive.';
    END IF;
    IF p_min_salary IS NOT NULL AND p_max_salary IS NOT NULL
       AND p_min_salary > p_max_salary THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Minimum salary cannot exceed maximum salary.';
    END IF;
    IF p_application_method = 'external'
       AND (p_contact_detail IS NULL OR CHAR_LENGTH(TRIM(p_contact_detail)) = 0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Contact details are required for an external application.';
    END IF;

    SELECT COUNT(*), MAX(category_level)
    INTO v_record_count, v_category_level
    FROM job_category
    WHERE category_id = p_category_id;
    IF v_record_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The selected job category does not exist.';
    END IF;
    IF v_category_level <> 'specialisation' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A job posting must use a specialisation-level job category.';
    END IF;

    SELECT COUNT(*) INTO v_record_count
    FROM company
    WHERE company_id = p_company_id;
    IF v_record_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The selected company does not exist.';
    END IF;

    SELECT COUNT(*) INTO v_record_count
    FROM recruitment_campaign
    WHERE campaign_id = p_campaign_id;
    IF v_record_count = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The selected recruitment campaign does not exist.';
    END IF;
    SELECT e.company_id INTO v_campaign_company_id
    FROM recruitment_campaign AS rc
    JOIN employer AS e ON e.employer_id = rc.created_by_employer_id
    WHERE rc.campaign_id = p_campaign_id;
    IF v_campaign_company_id <> p_company_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Job posting company must match the company of the campaign creator.';
    END IF;
END$$

DROP PROCEDURE IF EXISTS sp_create_job_posting$$
CREATE PROCEDURE sp_create_job_posting(
    IN p_category_id INT UNSIGNED,
    IN p_company_id INT UNSIGNED,
    IN p_campaign_id INT UNSIGNED,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_working_hours VARCHAR(100),
    IN p_saturday_work_policy VARCHAR(50),
    IN p_job_level VARCHAR(50),
    IN p_required_experience VARCHAR(50),
    IN p_min_salary DECIMAL(12,2),
    IN p_max_salary DECIMAL(12,2),
    IN p_employment_type VARCHAR(25),
    IN p_posted_date DATE,
    IN p_application_deadline DATE,
    IN p_application_method VARCHAR(50),
    IN p_contact_detail VARCHAR(255),
    IN p_employee_responsibilities VARCHAR(255),
    IN p_requirements TEXT,
    OUT p_job_posting_id INT UNSIGNED
)
BEGIN
    IF p_posted_date IS NULL OR p_posted_date > CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Posted date must be today or earlier.';
    END IF;
    IF p_application_deadline IS NULL OR p_application_deadline < CURRENT_DATE() THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A new job posting must have a current or future application deadline.';
    END IF;

    CALL sp_validate_job_posting(
        p_category_id, p_company_id, p_campaign_id, p_title, p_description,
        p_working_hours, p_saturday_work_policy, p_job_level, p_required_experience,
        p_min_salary, p_max_salary, p_employment_type, p_posted_date,
        p_application_deadline, p_application_method, p_contact_detail,
        p_employee_responsibilities, p_requirements
    );

    INSERT INTO job_posting (
        category_id, company_id, campaign_id, title, description, working_hours,
        saturday_work_policy, job_level, required_experience, job_status,
        min_salary, max_salary, employment_type, posted_date,
        application_deadline, application_method, contact_detail,
        employee_responsibilities, requirements
    )
    VALUES (
        p_category_id, p_company_id, p_campaign_id, TRIM(p_title), p_description,
        TRIM(p_working_hours), p_saturday_work_policy, TRIM(p_job_level),
        p_required_experience, 'open', p_min_salary, p_max_salary,
        p_employment_type, p_posted_date, p_application_deadline,
        p_application_method, p_contact_detail, p_employee_responsibilities,
        p_requirements
    );

    SET p_job_posting_id = LAST_INSERT_ID();
END$$

DROP PROCEDURE IF EXISTS sp_get_job_posting$$
CREATE PROCEDURE sp_get_job_posting(IN p_job_posting_id INT UNSIGNED)
BEGIN
    IF p_job_posting_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job posting ID is required.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM job_posting WHERE job_posting_id = p_job_posting_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The job posting does not exist.';
    END IF;

    SELECT *
    FROM job_posting
    WHERE job_posting_id = p_job_posting_id;
END$$

DROP PROCEDURE IF EXISTS sp_list_job_postings$$
CREATE PROCEDURE sp_list_job_postings()
BEGIN
    SELECT *
    FROM job_posting
    ORDER BY posted_date DESC, job_posting_id DESC;
END$$

DROP PROCEDURE IF EXISTS sp_update_job_posting$$
CREATE PROCEDURE sp_update_job_posting(
    IN p_job_posting_id INT UNSIGNED,
    IN p_category_id INT UNSIGNED,
    IN p_company_id INT UNSIGNED,
    IN p_campaign_id INT UNSIGNED,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_working_hours VARCHAR(100),
    IN p_saturday_work_policy VARCHAR(50),
    IN p_job_level VARCHAR(50),
    IN p_required_experience VARCHAR(50),
    IN p_min_salary DECIMAL(12,2),
    IN p_max_salary DECIMAL(12,2),
    IN p_employment_type VARCHAR(25),
    IN p_posted_date DATE,
    IN p_application_deadline DATE,
    IN p_application_method VARCHAR(50),
    IN p_contact_detail VARCHAR(255),
    IN p_employee_responsibilities VARCHAR(255),
    IN p_requirements TEXT
)
BEGIN
    IF p_job_posting_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job posting ID is required.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM job_posting WHERE job_posting_id = p_job_posting_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The job posting to update does not exist.';
    END IF;

    CALL sp_validate_job_posting(
        p_category_id, p_company_id, p_campaign_id, p_title, p_description,
        p_working_hours, p_saturday_work_policy, p_job_level, p_required_experience,
        p_min_salary, p_max_salary, p_employment_type, p_posted_date,
        p_application_deadline, p_application_method, p_contact_detail,
        p_employee_responsibilities, p_requirements
    );

    UPDATE job_posting
    SET category_id = p_category_id,
        company_id = p_company_id,
        campaign_id = p_campaign_id,
        title = TRIM(p_title),
        description = p_description,
        working_hours = TRIM(p_working_hours),
        saturday_work_policy = p_saturday_work_policy,
        job_level = TRIM(p_job_level),
        required_experience = p_required_experience,
        min_salary = p_min_salary,
        max_salary = p_max_salary,
        employment_type = p_employment_type,
        posted_date = p_posted_date,
        application_deadline = p_application_deadline,
        application_method = p_application_method,
        contact_detail = p_contact_detail,
        employee_responsibilities = p_employee_responsibilities,
        requirements = p_requirements
    WHERE job_posting_id = p_job_posting_id;
END$$

DROP PROCEDURE IF EXISTS sp_delete_job_posting$$
CREATE PROCEDURE sp_delete_job_posting(IN p_job_posting_id INT UNSIGNED)
BEGIN
    IF p_job_posting_id IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job posting ID is required.';
    END IF;
    IF NOT EXISTS (
        SELECT 1 FROM job_posting WHERE job_posting_id = p_job_posting_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'The job posting to delete does not exist.';
    END IF;
    IF EXISTS (
        SELECT 1 FROM application WHERE job_posting_id = p_job_posting_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot delete a job posting with applications; close it instead to preserve recruitment history.';
    END IF;

    DELETE FROM job_posting
    WHERE job_posting_id = p_job_posting_id;
END$$

DELIMITER ;
