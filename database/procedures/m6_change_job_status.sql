DELIMITER $$

DROP PROCEDURE IF EXISTS sp_change_job_status$$
CREATE PROCEDURE sp_change_job_status(
    IN p_job_posting_id INT UNSIGNED,
    IN p_new_status TEXT
)
BEGIN
    DECLARE v_today DATE DEFAULT CURRENT_DATE();
    DECLARE v_current_status VARCHAR(25);
    DECLARE v_deadline DATE;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_current_status = NULL;

    IF p_job_posting_id IS NULL OR p_job_posting_id = 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job posting ID must be a positive integer.';
    END IF;

    IF p_new_status IS NULL OR CAST(p_new_status AS BINARY) NOT IN ('open', 'closed') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job status must be open or closed.';
    END IF;

    -- Check the deadline in the UPDATE so a concurrent edit cannot invalidate
    -- an earlier deadline check. A DATE deadline includes the entire day.
    UPDATE job_posting
    SET job_status = p_new_status
    WHERE job_posting_id = p_job_posting_id
      AND (p_new_status = 'closed' OR application_deadline >= v_today);

    IF ROW_COUNT() = 0 THEN
        -- Zero rows can mean a missing job, an expired job, or an unchanged row.
        SELECT job_status, application_deadline INTO v_current_status, v_deadline
        FROM job_posting
        WHERE job_posting_id = p_job_posting_id
        FOR UPDATE;

        IF v_current_status IS NULL THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job posting does not exist.';
        END IF;

        IF p_new_status = 'open' AND v_deadline < v_today THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Cannot open a job posting after its application deadline.';
        END IF;

        IF CAST(v_current_status AS BINARY) <> CAST(p_new_status AS BINARY) THEN
            SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Job posting changed concurrently. Retry the status update.';
        END IF;
    END IF;

    SELECT p_job_posting_id AS job_posting_id, p_new_status AS job_status;
END$$

DELIMITER ;
