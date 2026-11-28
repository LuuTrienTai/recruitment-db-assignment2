USE recruitment_db;
DELIMITER $$

-- MySQL CHECK constraints cannot reference an AUTO_INCREMENT column.
DROP TRIGGER IF EXISTS trg_job_category_no_self_parent_after_insert$$
CREATE TRIGGER trg_job_category_no_self_parent_after_insert
AFTER INSERT ON job_category
FOR EACH ROW
BEGIN
    IF NEW.parent_category_id = NEW.category_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A job category cannot be its own parent.';
    END IF;
END$$

DROP TRIGGER IF EXISTS trg_job_category_no_self_parent_before_update$$
CREATE TRIGGER trg_job_category_no_self_parent_before_update
BEFORE UPDATE ON job_category
FOR EACH ROW
BEGIN
    IF NEW.parent_category_id = NEW.category_id THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'A job category cannot be its own parent.';
    END IF;
END$$

DELIMITER ;
