DELIMITER $$
DROP PROCEDURE IF EXISTS sp_search_job_postings$$
CREATE PROCEDURE sp_search_job_postings(
    IN p_keyword VARCHAR(255),
    IN p_company_id INT UNSIGNED,
    IN p_category_id INT UNSIGNED,
    IN p_job_status VARCHAR(25),
    IN p_sort_by VARCHAR(30)
)
BEGIN
    IF p_job_status IS NOT NULL AND p_job_status NOT IN ('open', 'closed') THEN SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Job status must be open or closed.';
    END IF;
    IF p_sort_by IS NOT NULL
        AND p_sort_by NOT IN ('title', 'posted_date', 'application_deadline', 'min_salary', 'max_salary') THEN SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Sort column must be title, posted_date, application_deadline, min_salary, or max_salary.';
    END IF;
    SELECT jp.job_posting_id AS job_posting_id, jp.title AS title, c.name AS company_name, jc.name AS category_name, jp.job_status AS job_status
    FROM job_posting jp
    JOIN company c ON c.company_id  = jp.company_id
    JOIN job_category jc ON jc.category_id = jp.category_id
    WHERE (p_keyword IS NULL OR title LIKE CONCAT('%', p_keyword, '%')) AND (p_company_id IS NULL OR jp.company_id = p_company_id)
    AND (p_category_id IS NULL OR jp.category_id = p_category_id) AND (p_job_status IS NULL OR job_status = p_job_status)

    ORDER BY 
        CASE WHEN p_sort_by = 'title' THEN jp.title END ASC,
        CASE WHEN p_sort_by = 'posted_date' THEN jp.posted_date END DESC,
        CASE WHEN p_sort_by = 'application_deadline' THEN jp.application_deadline END DESC,
        CASE WHEN p_sort_by = 'min_salary' THEN jp.min_salary END DESC,
        CASE WHEN p_sort_by = 'max_salary' THEN jp.max_salary END DESC,
        jp.posted_date DESC,
        jp.job_posting_id DESC;
END$$
DELIMITER ;

-- CALL sp_search_job_postings('dev', NULL, NULL, NULL, NULL);      
-- CALL sp_search_job_postings(NULL, NULL, NULL, 'open', NULL);    
-- CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'title');    
-- CALL sp_search_job_postings(NULL, NULL, NULL, 'abc', NULL);   
-- CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'xyz');    
