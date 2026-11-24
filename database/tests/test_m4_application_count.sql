-- ============================================================
-- Test M4 - DA01: job_posting.application_count
--
-- Run after m4_application_count.sql has been executed successfully.
-- Run the whole file in DBeaver with Execute SQL Script (Alt + X).
-- The test uses a transaction and ends with ROLLBACK, so test data
-- is not retained. The AUTO_INCREMENT value may still advance.
-- ============================================================

USE recruitment_db;

-- 0. Check that the three triggers are installed.
SELECT
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    ACTION_TIMING
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND EVENT_OBJECT_TABLE = 'application'
ORDER BY TRIGGER_NAME;

-- 1. Baseline: every stored count should equal the actual row count.
SELECT
    jp.job_posting_id,
    jp.application_count AS stored_count,
    COUNT(a.application_id) AS actual_count,
    CASE
        WHEN jp.application_count = COUNT(a.application_id) THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM job_posting AS jp
LEFT JOIN application AS a
       ON a.job_posting_id = jp.job_posting_id
GROUP BY jp.job_posting_id, jp.application_count
ORDER BY jp.job_posting_id;

-- 2. Test INSERT, UPDATE (move to another posting), UPDATE of an
--    unrelated attribute, and DELETE. All changes are rolled back.
START TRANSACTION;

-- A. AFTER INSERT: posting 706 should gain one application.
INSERT INTO application
    (candidate_id, cv_no, job_posting_id, submission_time,
     contact_name, email, phone_number, work_location,
     ai_analyze_cv, personal_data_usage_agreed, application_status)
VALUES
    (101, 1, 706, NOW(),
     'M4 Trigger Test', 'm4-trigger-test@example.test', '0900000000',
     'Test location', FALSE, TRUE, 'submitted');

SET @m4_test_application_id = LAST_INSERT_ID();

SELECT
    'A1 - AFTER INSERT' AS test_step,
    job_posting_id,
    application_count AS stored_count,
    (SELECT COUNT(*) FROM application
      WHERE job_posting_id = 706) AS actual_count,
    CASE WHEN application_count = (SELECT COUNT(*) FROM application
                                    WHERE job_posting_id = 706)
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM job_posting
WHERE job_posting_id = 706;

-- B. AFTER UPDATE: move the test Application from 706 to 707.
--    Posting 706 should decrease by one; posting 707 should increase by one.
UPDATE application
SET job_posting_id = 707
WHERE application_id = @m4_test_application_id;

SELECT
    'B1 - AFTER UPDATE: old posting' AS test_step,
    job_posting_id,
    application_count AS stored_count,
    (SELECT COUNT(*) FROM application
      WHERE job_posting_id = 706) AS actual_count,
    CASE WHEN application_count = (SELECT COUNT(*) FROM application
                                    WHERE job_posting_id = 706)
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM job_posting
WHERE job_posting_id = 706;

SELECT
    'B2 - AFTER UPDATE: new posting' AS test_step,
    job_posting_id,
    application_count AS stored_count,
    (SELECT COUNT(*) FROM application
      WHERE job_posting_id = 707) AS actual_count,
    CASE WHEN application_count = (SELECT COUNT(*) FROM application
                                    WHERE job_posting_id = 707)
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM job_posting
WHERE job_posting_id = 707;

-- C. AFTER UPDATE should not change counts when job_posting_id is unchanged.
UPDATE application
SET application_status = 'viewed'
WHERE application_id = @m4_test_application_id;

SELECT
    'C - UPDATE unrelated attribute' AS test_step,
    job_posting_id,
    application_count AS stored_count,
    (SELECT COUNT(*) FROM application
      WHERE job_posting_id = 707) AS actual_count,
    CASE WHEN application_count = (SELECT COUNT(*) FROM application
                                    WHERE job_posting_id = 707)
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM job_posting
WHERE job_posting_id = 707;

-- D. AFTER DELETE: posting 707 should lose the test Application.
DELETE FROM application
WHERE application_id = @m4_test_application_id;

SELECT
    'D - AFTER DELETE' AS test_step,
    job_posting_id,
    application_count AS stored_count,
    (SELECT COUNT(*) FROM application
      WHERE job_posting_id = 707) AS actual_count,
    CASE WHEN application_count = (SELECT COUNT(*) FROM application
                                    WHERE job_posting_id = 707)
         THEN 'PASS' ELSE 'FAIL' END AS test_result
FROM job_posting
WHERE job_posting_id = 707;

-- E. Undo the temporary test changes.
ROLLBACK;

-- 3. Final check after rollback: all stored counts must still match.
SELECT
    jp.job_posting_id,
    jp.application_count AS stored_count,
    COUNT(a.application_id) AS actual_count,
    CASE
        WHEN jp.application_count = COUNT(a.application_id) THEN 'PASS'
        ELSE 'FAIL'
    END AS test_result
FROM job_posting AS jp
LEFT JOIN application AS a
       ON a.job_posting_id = jp.job_posting_id
GROUP BY jp.job_posting_id, jp.application_count
ORDER BY jp.job_posting_id;

SELECT COUNT(*) AS remaining_test_applications
FROM application
WHERE email = 'm4-trigger-test@example.test';
-- Expected remaining_test_applications: 0
