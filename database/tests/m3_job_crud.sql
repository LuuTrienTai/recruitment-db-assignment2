-- Run against the seeded database after installing m3_job_crud.sql.
-- The transaction rolls the demonstration insert, update, and delete back.
USE recruitment_db;

START TRANSACTION;

CALL sp_create_job_posting(
    4, 401, 601,
    'M3 CRUD Demo Engineer',
    'Temporary posting used to demonstrate the M3 CRUD procedures.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    20000000,
    30000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Build and maintain application features.',
    'Experience with SQL and a programming language.',
    @created_job_posting_id
);

SELECT IF(
    (SELECT COUNT(*) FROM job_posting
     WHERE job_posting_id = @created_job_posting_id
       AND title = 'M3 CRUD Demo Engineer'
       AND job_status = 'open'
       AND min_salary = 20000000
       AND max_salary = 30000000) = 1,
    'PASS', 'FAIL'
) AS create_persisted_correctly;

CALL sp_get_job_posting(@created_job_posting_id);
CALL sp_list_job_postings();

CALL sp_update_job_posting(
    @created_job_posting_id,
    4, 401, 601,
    'M3 CRUD Demo Engineer - Updated',
    'Updated temporary posting used to demonstrate the M3 CRUD procedures.',
    'Monday-Friday, 09:00-18:00',
    'not_specified',
    'Mid-level',
    '1_3_years',
    22000000,
    32000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Build, test, and maintain application features.',
    'Experience with SQL and a programming language.'
);

SELECT IF(
    (SELECT COUNT(*) FROM job_posting
     WHERE job_posting_id = @created_job_posting_id
       AND title = 'M3 CRUD Demo Engineer - Updated'
       AND job_status = 'open'
       AND min_salary = 22000000
       AND max_salary = 32000000) = 1,
    'PASS', 'FAIL'
) AS update_persisted_correctly;

INSERT INTO candidate_save_job_posting (candidate_id, job_posting_id)
VALUES (101, @created_job_posting_id);
INSERT INTO work_location (job_posting_id, province_city, address)
VALUES (@created_job_posting_id, 'Ho Chi Minh City', 'Temporary CRUD test location');

CALL sp_delete_job_posting(@created_job_posting_id);

SELECT IF(
    (SELECT COUNT(*) FROM job_posting WHERE job_posting_id = @created_job_posting_id) = 0
    AND (SELECT COUNT(*) FROM candidate_save_job_posting
         WHERE job_posting_id = @created_job_posting_id) = 0
    AND (SELECT COUNT(*) FROM work_location
         WHERE job_posting_id = @created_job_posting_id) = 0,
    'PASS', 'FAIL'
) AS delete_removed_posting_and_dependent_rows;

ROLLBACK;
