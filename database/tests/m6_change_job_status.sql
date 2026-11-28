-- Run on the seeded database after installing m6_change_job_status.sql.
-- Fixture changes are rolled back. The final result should report PASS.
USE recruitment_db;

DELIMITER $$

DROP PROCEDURE IF EXISTS test_m6_expect_error$$
CREATE PROCEDURE test_m6_expect_error(
    IN p_job_posting_id INT UNSIGNED,
    IN p_new_status TEXT,
    IN p_expected_message VARCHAR(128)
)
BEGIN
    DECLARE v_message VARCHAR(128);
    BEGIN
        DECLARE CONTINUE HANDLER FOR SQLSTATE '45000'
            GET STACKED DIAGNOSTICS CONDITION 1 v_message = MESSAGE_TEXT;

        CALL sp_change_job_status(p_job_posting_id, p_new_status);
    END;

    IF NOT (v_message <=> p_expected_message) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'M6 test failed: unexpected error or missing validation.';
    END IF;
END$$

DROP PROCEDURE IF EXISTS test_m6_change_job_status$$
CREATE PROCEDURE test_m6_change_job_status()
BEGIN
    DECLARE v_today DATE DEFAULT CURRENT_DATE();
    DECLARE v_application_count INT UNSIGNED;
    DECLARE v_title VARCHAR(255);
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM job_posting WHERE job_posting_id = 701) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'M6 test requires seed job posting 701.';
    END IF;

    SELECT application_count, title INTO v_application_count, v_title
    FROM job_posting WHERE job_posting_id = 701;

    UPDATE job_posting
    SET posted_date = v_today - INTERVAL 2 DAY,
        application_deadline = v_today, job_status = 'open'
    WHERE job_posting_id = 701;

    CALL sp_change_job_status(701, 'closed');
    CALL sp_change_job_status(701, 'closed');

    IF (SELECT job_status FROM job_posting WHERE job_posting_id = 701) <> 'closed' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'M6 test failed: closing was not persisted.';
    END IF;

    CALL sp_change_job_status(701, 'open');
    CALL sp_change_job_status(701, 'open');

    IF (SELECT job_status FROM job_posting WHERE job_posting_id = 701) <> 'open' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'M6 test failed: the deadline day must allow reopening.';
    END IF;

    UPDATE job_posting SET application_deadline = v_today - INTERVAL 1 DAY
    WHERE job_posting_id = 701;

    CALL test_m6_expect_error(701, 'open', 'Cannot open a job posting after its application deadline.');
    CALL sp_change_job_status(701, 'closed');
    CALL test_m6_expect_error(701, 'open', 'Cannot open a job posting after its application deadline.');
    CALL test_m6_expect_error(701, 'draft', 'Job status must be open or closed.');
    CALL test_m6_expect_error(701, 'OPEN', 'Job status must be open or closed.');
    CALL test_m6_expect_error(701, 'open ', 'Job status must be open or closed.');
    CALL test_m6_expect_error(701, NULL, 'Job status must be open or closed.');
    CALL test_m6_expect_error(NULL, 'closed', 'Job posting ID must be a positive integer.');
    CALL test_m6_expect_error(0, 'closed', 'Job posting ID must be a positive integer.');
    CALL test_m6_expect_error(4294967295, 'closed', 'Job posting does not exist.');

    IF NOT EXISTS (
        SELECT 1 FROM job_posting
        WHERE job_posting_id = 701 AND job_status = 'closed'
          AND application_deadline = v_today - INTERVAL 1 DAY
          AND application_count = v_application_count AND title = v_title
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'M6 test failed: final job fields are incorrect.';
    END IF;

    ROLLBACK;
    SELECT 'PASS: M6 status changes, deadline validation and input errors' AS result;
END$$

CALL test_m6_change_job_status()$$
DROP PROCEDURE test_m6_change_job_status$$
DROP PROCEDURE test_m6_expect_error$$

DELIMITER ;
