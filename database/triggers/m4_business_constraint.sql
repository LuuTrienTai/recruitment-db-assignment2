-- ============================================================
-- M4: Business Constraint Trigger
-- Constraint: SC15b
-- An Employer cannot conduct two scheduled Interviews whose
-- time intervals overlap.
--
-- Table: interview
-- MySQL: 8.4
-- ============================================================

USE recruitment_db;

DROP TRIGGER IF EXISTS trg_interview_no_overlap_before_insert;
DROP TRIGGER IF EXISTS trg_interview_no_overlap_before_update;

DELIMITER $$

-- ------------------------------------------------------------
-- 1. INSERT
-- Check whether the new scheduled interview overlaps with
-- another scheduled interview conducted by the same Employer.
-- ------------------------------------------------------------
CREATE TRIGGER trg_interview_no_overlap_before_insert
BEFORE INSERT ON interview
FOR EACH ROW
BEGIN
    DECLARE v_conflict_count INT DEFAULT 0;

    IF NEW.interview_status = 'scheduled' THEN
        SELECT COUNT(*)
          INTO v_conflict_count
          FROM interview AS i
         WHERE i.conducting_employer_id = NEW.conducting_employer_id
           AND i.interview_status = 'scheduled'
           AND NEW.start_time < i.end_time
           AND NEW.end_time > i.start_time;

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'SC15b violation: this Employer already has a scheduled Interview that overlaps with the requested time.';
        END IF;
    END IF;
END$$

-- ------------------------------------------------------------
-- 2. UPDATE
-- Apply the same rule when an Interview is updated.
-- Exclude the current row using interview_id so that a row
-- does not conflict with itself.
-- ------------------------------------------------------------
CREATE TRIGGER trg_interview_no_overlap_before_update
BEFORE UPDATE ON interview
FOR EACH ROW
BEGIN
    DECLARE v_conflict_count INT DEFAULT 0;

    IF NEW.interview_status = 'scheduled' THEN
        SELECT COUNT(*)
          INTO v_conflict_count
          FROM interview AS i
         WHERE i.conducting_employer_id = NEW.conducting_employer_id
           AND i.interview_status = 'scheduled'
           AND i.interview_id <> OLD.interview_id
           AND NEW.start_time < i.end_time
           AND NEW.end_time > i.start_time;

        IF v_conflict_count > 0 THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT =
                    'SC15b violation: this update would create an overlapping scheduled Interview for the same Employer.';
        END IF;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- DML operations that may violate SC15b:
--   INSERT interview
--   UPDATE interview (employer, start_time, end_time, status)
--
-- DELETE cannot create a scheduling overlap.
--
-- Notes:
--   * Only rows with interview_status = 'scheduled' are checked.
--   * Different Employers may have overlapping Interviews.
--   * Adjacent intervals are allowed because the overlap test
--     uses strict < and > comparisons.
-- ============================================================
