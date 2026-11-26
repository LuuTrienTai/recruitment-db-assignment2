-- =============================================================================
-- M5 — Assignment 2, mục 2.3: procedure thống kê hồ sơ ứng tuyển theo tin
-- =============================================================================
-- sp_report_job_applications(p_from_date, p_to_date, p_company_id, p_min_applications)
--
-- Câu hỏi nghiệp vụ: "Trong khoảng thời gian [from, to], mỗi tin tuyển dụng nhận
-- được bao nhiêu hồ sơ, phân bố theo trạng thái ra sao?"
--
-- Quyết định thiết kế (docs/decisions.md, D-M5-04..08):
--   * Lọc thời gian theo application.submission_time (thời điểm nộp hồ sơ),
--     không theo job_posting.posted_date — tránh trùng với sp_search_job_postings.
--   * LEFT JOIN application, điều kiện thời gian đặt trong ON: tin không có hồ sơ
--     trong kỳ vẫn xuất hiện với số đếm 0 (khi p_min_applications = 0).
--     Đặt điều kiện application trong WHERE sẽ biến LEFT JOIN thành INNER JOIN.
--   * Đếm bằng COUNT(a.application_id) từ bảng application; KHÔNG đọc cột dẫn xuất
--     job_posting.application_count (do trigger M4 duy trì).
--   * submission_time là DATETIME, tham số là DATE ⇒ cận dưới
--     submission_time >= from_date (00:00:00), cận trên DATE(submission_time) <= to_date
--     để lấy trọn ngày cuối. Không dùng submission_time < to_date + 1 ngày vì
--     DATE_ADD('9999-12-31', INTERVAL 1 DAY) trả NULL và làm mất mọi hồ sơ.
--
-- Tham số:
--   p_from_date        DATE    NULL = không giới hạn ngày bắt đầu
--   p_to_date          DATE    NULL = không giới hạn ngày kết thúc
--   p_company_id       BIGINT  NULL = mọi công ty; BIGINT có dấu để số âm nhận
--                              thông báo "không tồn tại" thay vì lỗi tràn kiểu
--   p_min_applications INT     bắt buộc, >= 0 (điều kiện HAVING)
--
-- Lỗi (SQLSTATE 45000):
--   - p_min_applications NULL hoặc âm
--   - p_from_date > p_to_date (khi cả hai khác NULL)
--   - p_company_id không tồn tại (kể cả 0 và số âm)
-- =============================================================================

USE recruitment_db;
-- File chứa tiếng Việt (thông báo lỗi, dữ liệu): đặt bảng mã cho kết nối để client
-- nào cũng lưu đúng, kể cả client mặc định latin1 (vd. mysql trong container).
SET NAMES utf8mb4;

DROP PROCEDURE IF EXISTS sp_report_job_applications;

DELIMITER $$

CREATE PROCEDURE sp_report_job_applications(
    IN p_from_date        DATE,
    IN p_to_date          DATE,
    IN p_company_id       BIGINT,
    IN p_min_applications INT
)
BEGIN
    -- ---------------------------------------------------------------- validate
    IF p_min_applications IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số hồ sơ tối thiểu (p_min_applications) là bắt buộc; nhập 0 để hiển thị cả tin chưa có hồ sơ.';
    END IF;

    IF p_min_applications < 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Số hồ sơ tối thiểu (p_min_applications) không được âm.';
    END IF;

    IF p_from_date IS NOT NULL AND p_to_date IS NOT NULL AND p_from_date > p_to_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).';
    END IF;

    IF p_company_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM company WHERE company_id = p_company_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Công ty (p_company_id) không tồn tại.';
    END IF;

    -- ------------------------------------------------------------------ report
    SELECT
        jp.job_posting_id,
        jp.title,
        c.company_id,
        c.name                                   AS company_name,
        jp.job_status,
        jp.posted_date,
        jp.application_deadline,
        COUNT(a.application_id)                  AS total_applications,
        COUNT(CASE WHEN a.application_status = 'submitted' THEN 1 END) AS submitted_count,
        COUNT(CASE WHEN a.application_status = 'viewed' THEN 1 END) AS viewed_count,
        COUNT(CASE WHEN a.application_status = 'interviewing' THEN 1 END) AS interviewing_count,
        COUNT(CASE WHEN a.application_status = 'accepted' THEN 1 END) AS accepted_count,
        COUNT(CASE WHEN a.application_status = 'rejected' THEN 1 END) AS rejected_count,
        MIN(a.submission_time)                   AS first_submission,
        MAX(a.submission_time)                   AS last_submission
    FROM job_posting AS jp
    INNER JOIN company AS c
        ON c.company_id = jp.company_id
    LEFT JOIN application AS a
        ON  a.job_posting_id = jp.job_posting_id
        AND (p_from_date IS NULL OR a.submission_time >= p_from_date)
        AND (p_to_date   IS NULL OR DATE(a.submission_time) <= p_to_date)
    WHERE (p_company_id IS NULL OR jp.company_id = p_company_id)
    GROUP BY
        jp.job_posting_id,
        jp.title,
        c.company_id,
        c.name,
        jp.job_status,
        jp.posted_date,
        jp.application_deadline
    HAVING COUNT(a.application_id) >= p_min_applications
    ORDER BY total_applications DESC, jp.job_posting_id ASC;
END$$

DELIMITER ;
