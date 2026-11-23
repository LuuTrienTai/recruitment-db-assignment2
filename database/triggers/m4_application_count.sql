-- ============================================================
-- M4 - DA01: Maintain job_posting.application_count
-- Database: recruitment_db
-- MySQL: 8.4+
--
-- Definition:
-- application_count stores the total number of rows in application
-- belonging to each job posting. All application statuses are counted.
--
-- Trigger events:
--   AFTER INSERT: increase the destination Job Posting counter.
--   AFTER DELETE: decrease the source Job Posting counter.
--   AFTER UPDATE: when job_posting_id changes, decrease the old
--                 Job Posting counter and increase the new one.
--
-- Run this file in DBeaver with Execute SQL Script (Alt + X),
-- using the recruitment_app connection to recruitment_db.
-- ============================================================

USE recruitment_db;

-- Drop existing versions so the script can be re-run safely.
DROP TRIGGER IF EXISTS trg_application_count_after_insert;
DROP TRIGGER IF EXISTS trg_application_count_after_delete;
DROP TRIGGER IF EXISTS trg_application_count_after_update;

DELIMITER $$

-- 1. A new Application increases the count of its Job Posting.
CREATE TRIGGER trg_application_count_after_insert
AFTER INSERT ON application
FOR EACH ROW
BEGIN
    UPDATE job_posting
       SET application_count = application_count + 1
     WHERE job_posting_id = NEW.job_posting_id;
END$$

-- 2. Deleting an Application decreases the count of its old Job Posting.
CREATE TRIGGER trg_application_count_after_delete
AFTER DELETE ON application
FOR EACH ROW
BEGIN
    UPDATE job_posting
       SET application_count = application_count - 1
     WHERE job_posting_id = OLD.job_posting_id;
END$$

-- 3. Moving an Application between Job Postings updates both counters.
--    Updates to other Application attributes do not change the count.
CREATE TRIGGER trg_application_count_after_update
AFTER UPDATE ON application
FOR EACH ROW
BEGIN
    IF OLD.job_posting_id <> NEW.job_posting_id THEN
        UPDATE job_posting
           SET application_count = application_count - 1
         WHERE job_posting_id = OLD.job_posting_id;

        UPDATE job_posting
           SET application_count = application_count + 1
         WHERE job_posting_id = NEW.job_posting_id;
    END IF;
END$$

DELIMITER ;

-- Reconcile existing stored values with the current Application rows.
-- This is safe to run again and makes the initial counter values correct
-- even when the trigger file is installed after the seed data.
UPDATE job_posting AS jp
SET application_count = (
    SELECT COUNT(*)
    FROM application AS a
    WHERE a.job_posting_id = jp.job_posting_id
);

-- Verify that the stored derived attribute matches the real row count.
SELECT
    jp.job_posting_id,
    jp.title,
    jp.application_count AS stored_application_count,
    COUNT(a.application_id) AS actual_application_count,
    CASE
        WHEN jp.application_count = COUNT(a.application_id) THEN 'OK'
        ELSE 'MISMATCH'
    END AS consistency_status
FROM job_posting AS jp
LEFT JOIN application AS a
       ON a.job_posting_id = jp.job_posting_id
GROUP BY jp.job_posting_id, jp.title, jp.application_count
ORDER BY jp.job_posting_id;

-- Verify that all three triggers exist.
SELECT
    TRIGGER_NAME,
    EVENT_MANIPULATION,
    ACTION_TIMING,
    EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA = DATABASE()
  AND EVENT_OBJECT_TABLE = 'application'
ORDER BY TRIGGER_NAME;
