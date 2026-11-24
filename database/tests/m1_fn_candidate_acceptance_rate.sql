-- =============================================================================
-- M1 — Kiểm thử & demo fn_candidate_acceptance_rate
-- =============================================================================
-- Điều kiện trước khi chạy:
--   1. Đã chạy database/schema/01_schema.sql
--   2. Đã chạy database/seeds/01_seed.sql
--   3. Đã chạy database/functions/m1_candidate_acceptance_rate.sql
--
-- Dữ liệu hồ sơ có sẵn trong seed (application_id: candidate_id, submission_time, status):
--   801: 101, 2026-10-22 09:00:00, viewed
--   802: 101, 2026-10-30 09:15:00, interviewing
--   803: 102, 2026-10-27 10:30:00, viewed
--   804: 103, 2026-11-04 11:45:00, rejected
--   805: 104, 2026-11-08 14:00:00, submitted
--   806: 105, 2026-11-06 09:20:00, accepted
--   Ứng viên 106, 107: chưa nộp hồ sơ nào (0 application).
--
-- Toàn bộ dữ liệu thêm tạm trong PHẦN A nằm trong TRANSACTION và được ROLLBACK,
-- không làm thay đổi dữ liệu seed sau khi chạy.
-- =============================================================================

USE recruitment_db;

-- =============================================================== 0. KIỂM TRA HÀM TỒN TẠI
SELECT
    ROUTINE_NAME,
    ROUTINE_TYPE,
    DTD_IDENTIFIER AS return_type,
    IF(ROUTINE_NAME = 'fn_candidate_acceptance_rate', 'PASS', 'FAIL') AS test_result
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = DATABASE()
  AND ROUTINE_TYPE = 'FUNCTION'
  AND ROUTINE_NAME = 'fn_candidate_acceptance_rate';

-- =============================================================== PHẦN A: LOGIC & BIÊN (ROLLBACK)
START TRANSACTION;

-- A0. Kiểm tra trực tiếp trên dữ liệu seed gốc trước khi chèn thêm
SELECT
    test_case,
    actual_result,
    expected_result,
    IF(actual_result <=> expected_result, 'PASS', 'FAIL') AS test_result
FROM (
    SELECT 'S1 Seed: ứng viên 106 chưa có hồ sơ -> NULL' AS test_case,
           fn_candidate_acceptance_rate(106, NULL, NULL)  AS actual_result,
           CAST(NULL AS DECIMAL(5,2))                     AS expected_result
    UNION ALL
    SELECT 'S2 Seed: ứng viên 101 có 2 đơn chưa accepted -> 0.00',
           fn_candidate_acceptance_rate(101, NULL, NULL),
           CAST(0.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'S3 Seed: ứng viên 105 có 1/1 đơn accepted -> 100.00',
           fn_candidate_acceptance_rate(105, NULL, NULL),
           CAST(100.00 AS DECIMAL(5,2))
) AS seed_checks;

-- Bổ sung dữ liệu tạm thời để kiểm thử đủ tỷ lệ lẻ, làm tròn và biên ngày/giờ
INSERT INTO application
(application_id, candidate_id, cv_no, job_posting_id, submission_time, contact_name, email, phone_number, work_location, ai_analyze_cv, personal_data_usage_agreed, application_status)
VALUES
(811, 101, 1, 706, '2026-11-15 16:45:00', 'An Nguyen', 'an.nguyen@example.test',   '0901000101', 'Ho Chi Minh City', TRUE,  TRUE, 'accepted'),
(812, 102, 2, 706, '2026-11-11 10:00:00', 'Binh Tran', 'binh.tran@example.test',   '0901000102', 'Ho Chi Minh City', FALSE, TRUE, 'accepted'),
(813, 102, 1, 707, '2026-11-18 23:59:59', 'Binh Tran', 'binh.tran@example.test',   '0901000102', 'Ho Chi Minh City', TRUE,  TRUE, 'accepted'),
(814, 105, 2, 705, '2026-11-12 11:00:00', 'Ha Vo',     'ha.vo@example.test',       '0901000105', 'Da Nang',          FALSE, TRUE, 'rejected');

-- Sau khi chèn tạm:
--   101: 801 (2026-10-22 viewed), 802 (2026-10-30 interviewing), 811 (2026-11-15 16:45:00 accepted) -> 1/3 = 33.33
--   102: 803 (2026-10-27 viewed), 812 (2026-11-11 accepted),     813 (2026-11-18 23:59:59 accepted) -> 2/3 = 66.67
--   105: 806 (2026-11-06 accepted), 814 (2026-11-12 rejected)                                       -> 1/2 = 50.00
--   107: có CV nhưng 0 application                                                                  -> NULL

SELECT
    test_case,
    actual_result,
    expected_result,
    IF(actual_result <=> expected_result, 'PASS', 'FAIL') AS test_result
FROM (
    SELECT 'A1 Có CV nhưng 0 hồ sơ (107) -> NULL' AS test_case,
           fn_candidate_acceptance_rate(107, NULL, NULL) AS actual_result,
           CAST(NULL AS DECIMAL(5,2))                    AS expected_result
    UNION ALL
    SELECT 'A2 1/3 hồ sơ accepted (làm tròn xuống 33.33)',
           fn_candidate_acceptance_rate(101, NULL, NULL),
           CAST(33.33 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A3 2/3 hồ sơ accepted (làm tròn lên 66.67)',
           fn_candidate_acceptance_rate(102, NULL, NULL),
           CAST(66.67 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A4 1/2 hồ sơ accepted (50.00)',
           fn_candidate_acceptance_rate(105, NULL, NULL),
           CAST(50.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A5 Lọc tháng 10/2026 của 101: 0/2 accepted -> 0.00',
           fn_candidate_acceptance_rate(101, '2026-10-01', '2026-10-31'),
           CAST(0.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A6 Chỉ giới hạn p_from_date (p_to_date = NULL) -> 100.00',
           fn_candidate_acceptance_rate(101, '2026-11-01', NULL),
           CAST(100.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A7 Chỉ giới hạn p_to_date (p_from_date = NULL) -> 0.00',
           fn_candidate_acceptance_rate(101, NULL, '2026-10-31'),
           CAST(0.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A8 Biên 1 ngày p_from_date = p_to_date (lúc 16:45:00) -> 100.00',
           fn_candidate_acceptance_rate(101, '2026-11-15', '2026-11-15'),
           CAST(100.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A9 Biên cuối ngày 23:59:59 của p_to_date -> 100.00',
           fn_candidate_acceptance_rate(102, '2026-11-01', '2026-11-18'),
           CAST(100.00 AS DECIMAL(5,2))
    UNION ALL
    SELECT 'A10 Có hồ sơ kỳ khác nhưng 0 hồ sơ trong kỳ lọc -> NULL',
           fn_candidate_acceptance_rate(101, '2026-01-01', '2026-09-30'),
           CAST(NULL AS DECIMAL(5,2))
) AS logic_checks;

-- A11. Truy vấn demo cho giao diện minh họa function: tỷ lệ accepted năm 2026 của mọi candidate
-- Kỳ vọng (trong ngữ cảnh có dữ liệu tạm):
--   101: 33.33 | 102: 66.67 | 103: 0.00 | 104: 0.00 | 105: 50.00 | 106: NULL | 107: NULL
SELECT
    c.candidate_id,
    CONCAT(u.first_name, ' ', u.last_name) AS candidate_name,
    u.email_address,
    COUNT(a.application_id) AS total_applications_2026,
    SUM(CASE WHEN a.application_status = 'accepted' THEN 1 ELSE 0 END) AS accepted_applications_2026,
    fn_candidate_acceptance_rate(c.candidate_id, '2026-01-01', '2026-12-31') AS acceptance_rate_2026_pct
FROM candidate AS c
INNER JOIN user_account AS u
    ON u.account_id = c.candidate_id
LEFT JOIN application AS a
    ON a.candidate_id = c.candidate_id
   AND a.submission_time >= TIMESTAMP('2026-01-01')
   AND a.submission_time <  TIMESTAMP('2027-01-01')
GROUP BY c.candidate_id, u.account_id
ORDER BY c.candidate_id;

ROLLBACK;

-- Xác nhận dữ liệu tạm đã được hoàn tác sạch
SELECT
    IF(COUNT(*) = 0, 'PASS', 'FAIL') AS rollback_cleanup_check
FROM application
WHERE application_id IN (811, 812, 813, 814);

-- =============================================================== PHẦN B: BẮT LỖI SQLSTATE '45000'
-- Dùng procedure kiểm thử tạm thời để bắt từng lỗi SQLSTATE '45000' tự động,
-- sau đó xóa ngay procedure kiểm thử để không để lại đối tượng thừa trong DB.
DROP PROCEDURE IF EXISTS sp_test_m1_fn_expected_errors;

DELIMITER $$

CREATE PROCEDURE sp_test_m1_fn_expected_errors()
BEGIN
    DECLARE v_caught BOOLEAN DEFAULT FALSE;
    DECLARE v_msg    TEXT    DEFAULT NULL;
    DECLARE v_dummy  DECIMAL(5,2);

    DECLARE v_b1_ok  BOOLEAN DEFAULT FALSE;
    DECLARE v_b1_msg TEXT;
    DECLARE v_b2_ok  BOOLEAN DEFAULT FALSE;
    DECLARE v_b2_msg TEXT;
    DECLARE v_b3_ok  BOOLEAN DEFAULT FALSE;
    DECLARE v_b3_msg TEXT;
    DECLARE v_b4_ok  BOOLEAN DEFAULT FALSE;
    DECLARE v_b4_msg TEXT;

    DECLARE CONTINUE HANDLER FOR SQLSTATE '45000'
    BEGIN
        SET v_caught = TRUE;
        GET DIAGNOSTICS CONDITION 1 v_msg = MESSAGE_TEXT;
    END;

    -- B1: p_candidate_id IS NULL
    SET v_caught = FALSE, v_msg = NULL;
    SET v_dummy = fn_candidate_acceptance_rate(NULL, NULL, NULL);
    SET v_b1_ok = v_caught, v_b1_msg = v_msg;

    -- B2: p_candidate_id không tồn tại (999)
    SET v_caught = FALSE, v_msg = NULL;
    SET v_dummy = fn_candidate_acceptance_rate(999, NULL, NULL);
    SET v_b2_ok = v_caught, v_b2_msg = v_msg;

    -- B3: account_id = 201 là employer, không phải candidate
    SET v_caught = FALSE, v_msg = NULL;
    SET v_dummy = fn_candidate_acceptance_rate(201, NULL, NULL);
    SET v_b3_ok = v_caught, v_b3_msg = v_msg;

    -- B4: p_from_date > p_to_date
    SET v_caught = FALSE, v_msg = NULL;
    SET v_dummy = fn_candidate_acceptance_rate(101, '2026-12-31', '2026-01-01');
    SET v_b4_ok = v_caught, v_b4_msg = v_msg;

    SELECT 'B1 p_candidate_id IS NULL' AS error_test_case,
           v_b1_msg AS actual_error_message,
           IF(v_b1_ok, 'PASS', 'FAIL') AS test_result
    UNION ALL
    SELECT 'B2 p_candidate_id không tồn tại (999)',
           v_b2_msg,
           IF(v_b2_ok, 'PASS', 'FAIL')
    UNION ALL
    SELECT 'B3 account_id = 201 (employer, không phải candidate)',
           v_b3_msg,
           IF(v_b3_ok, 'PASS', 'FAIL')
    UNION ALL
    SELECT 'B4 p_from_date > p_to_date',
           v_b4_msg,
           IF(v_b4_ok, 'PASS', 'FAIL');
END$$

DELIMITER ;

CALL sp_test_m1_fn_expected_errors();
DROP PROCEDURE IF EXISTS sp_test_m1_fn_expected_errors;

-- -----------------------------------------------------------------------------
-- (Tùy chọn) Bôi đen chạy lẻ từng câu dưới đây trong DBeaver nếu muốn xem popup lỗi trực tiếp:
-- SELECT fn_candidate_acceptance_rate(NULL, NULL, NULL);
-- SELECT fn_candidate_acceptance_rate(999, NULL, NULL);
-- SELECT fn_candidate_acceptance_rate(201, NULL, NULL);
-- SELECT fn_candidate_acceptance_rate(101, '2026-12-31', '2026-01-01');
