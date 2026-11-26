-- =============================================================================
-- M2 — Kiểm thử / demo sp_search_job_postings
-- =============================================================================
-- Điều kiện: đã chạy schema, seed, và procedures/m2_search_jobs.sql.
-- Phần A chạy trên dữ liệu seed (chỉ SELECT, không thay đổi dữ liệu).
-- Phần B (case lỗi) chạy từng câu một.
-- =============================================================================

USE recruitment_db;

-- =============================================================== PHẦN A
-- A1. Không lọc gì (mặc định sắp xếp posted_date DESC, job_posting_id DESC)
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, NULL);

-- A2. Tìm kiếm theo từ khóa trong tiêu đề ('Engineer')
CALL sp_search_job_postings('Engineer', NULL, NULL, NULL, NULL);

-- A3. Lọc theo công ty 401 (Lotus Digital)
CALL sp_search_job_postings(NULL, 401, NULL, NULL, NULL);

-- A4. Lọc theo chuyên môn 4 (Backend Developer) và trạng thái 'open'
CALL sp_search_job_postings(NULL, NULL, 4, 'open', NULL);

-- A5. Lọc tin đã đóng ('closed') -> kỳ vọng chỉ có tin 703
CALL sp_search_job_postings(NULL, NULL, NULL, 'closed', NULL);

-- A6. Sắp xếp theo tiêu đề tăng dần ('title')
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'title');

-- A7. Sắp xếp theo ngày đăng giảm dần ('posted_date')
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'posted_date');

-- A8. Sắp xếp theo hạn nộp giảm dần ('application_deadline')
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'application_deadline');

-- A9. Sắp xếp theo lương tối thiểu giảm dần ('min_salary')
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'min_salary');

-- A10. Sắp xếp theo lương tối đa giảm dần ('max_salary')
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'max_salary');

-- =============================================================== PHẦN B
-- Mỗi câu dưới đây PHẢI báo lỗi SQLSTATE '45000'. Chạy từng câu một.

-- B1. Expected: "Job status must be open or closed."
CALL sp_search_job_postings(NULL, NULL, NULL, 'abc', NULL);

-- B2. Expected: "Sort column must be title, posted_date, application_deadline, min_salary, or max_salary."
CALL sp_search_job_postings(NULL, NULL, NULL, NULL, 'xyz');
