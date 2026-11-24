-- =============================================================================
-- M1 — Assignment 2, mục 2.4: Function 1 — tỷ lệ hồ sơ được chấp nhận (accepted)
-- =============================================================================
-- fn_candidate_acceptance_rate(p_candidate_id, p_from_date, p_to_date)
--
-- Ý nghĩa: tính tỷ lệ phần trăm (%) hồ sơ có trạng thái 'accepted' trên tổng số
-- hồ sơ ứng tuyển (application) mà ứng viên đã nộp trong khoảng thời gian lọc
-- theo application.submission_time. (docs/decisions.md, D-M1-01..04)
--
-- Quy tắc tính & xử lý NULL:
--   - Mẫu số: tổng số hồ sơ của candidate có submission_time thuộc kỳ lọc
--     (gồm cả 'submitted', 'viewed', 'interviewing', 'accepted', 'rejected').
--   - Tử số: số hồ sơ trong mẫu số có application_status = 'accepted'.
--   - Không có hồ sơ nào trong kỳ (mẫu số = 0) -> trả về NULL (chưa có dữ liệu
--     ứng tuyển để tính tỷ lệ; phân biệt với 0.00% khi có nộp nhưng chưa đậu).
--   - Có ít nhất 1 hồ sơ -> ROUND((accepted_count * 100) / total_count, 2),
--     kiểu DECIMAL(5,2) trong đoạn [0.00, 100.00].
--
-- Tham số:
--   p_candidate_id  INT UNSIGNED  bắt buộc, phải tồn tại trong bảng candidate
--   p_from_date     DATE          NULL = không giới hạn ngày bắt đầu
--                                 khác NULL: submission_time >= p_from_date 00:00:00
--   p_to_date       DATE          NULL = không giới hạn ngày kết thúc
--                                 khác NULL: submission_time < (p_to_date + 1 ngày)
--
-- Lỗi nghiệp vụ (SQLSTATE '45000'):
--   - p_candidate_id IS NULL
--   - p_candidate_id không tồn tại trong bảng candidate
--   - p_from_date > p_to_date (khi cả hai khác NULL)
--
-- Kỹ thuật theo yêu cầu 2.4: sử dụng CURSOR + LOOP + IF để duyệt từng hồ sơ của
-- ứng viên trong kỳ, đếm tổng số hồ sơ và số hồ sơ có trạng thái 'accepted'.
-- =============================================================================

USE recruitment_db;

DROP FUNCTION IF EXISTS fn_candidate_acceptance_rate;

DELIMITER $$

CREATE FUNCTION fn_candidate_acceptance_rate(
    p_candidate_id INT UNSIGNED,
    p_from_date    DATE,
    p_to_date      DATE
)
RETURNS DECIMAL(5,2)
READS SQL DATA
BEGIN
    DECLARE v_status         VARCHAR(25);
    DECLARE v_done           BOOLEAN DEFAULT FALSE;
    DECLARE v_total_count    INT     DEFAULT 0;
    DECLARE v_accepted_count INT     DEFAULT 0;

    DECLARE cur_application CURSOR FOR
        SELECT a.application_status
        FROM application AS a
        WHERE a.candidate_id = p_candidate_id
          AND (p_from_date IS NULL OR a.submission_time >= TIMESTAMP(p_from_date))
          AND (p_to_date   IS NULL OR a.submission_time <  TIMESTAMP(DATE_ADD(p_to_date, INTERVAL 1 DAY)));

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- -------------------------------------------------------- 1. Validate input
    IF p_candidate_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Mã ứng viên (p_candidate_id) là bắt buộc.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM candidate
        WHERE candidate_id = p_candidate_id
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ứng viên (p_candidate_id) không tồn tại.';
    END IF;

    IF p_from_date IS NOT NULL
       AND p_to_date IS NOT NULL
       AND p_from_date > p_to_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).';
    END IF;

    -- ----------------------------------------------- 2. Iterate with CURSOR+LOOP
    SET v_done = FALSE;
    OPEN cur_application;

    read_loop: LOOP
        FETCH cur_application INTO v_status;
        IF v_done THEN
            LEAVE read_loop;
        END IF;

        SET v_total_count = v_total_count + 1;

        IF v_status = 'accepted' THEN
            SET v_accepted_count = v_accepted_count + 1;
        END IF;
    END LOOP read_loop;

    CLOSE cur_application;

    -- ------------------------------------------------------- 3. Compute & return
    IF v_total_count = 0 THEN
        RETURN NULL;
    END IF;

    RETURN ROUND((CAST(v_accepted_count AS DECIMAL(10,4)) * 100) / v_total_count, 2);
END$$

DELIMITER ;
