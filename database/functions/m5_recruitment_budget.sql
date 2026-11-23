-- =============================================================================
-- M5 — Assignment 2, mục 2.4: Function 2 — tổng ngân sách nhu cầu tuyển dụng
-- =============================================================================
-- fn_employer_recruitment_budget(p_employer_id, p_from_date, p_to_date)
--
-- Ý nghĩa: tổng ngân sách của các recruitment_need mà employer KHAI BÁO
-- (declares_recruitment_need.employer_id) có declared_date nằm trong [from, to].
-- Đây KHÔNG phải ngân sách chi tiêu trong kỳ: budget không phân bổ theo tháng,
-- nên mỗi nhu cầu được xếp vào đúng một kỳ theo ngày khai báo, tránh cộng trùng
-- khi cộng nhiều kỳ liên tiếp. (docs/decisions.md, D-M5-01..03)
--
-- Chính sách NULL (budget NULL = chưa xác định, 0 = ngân sách thật bằng 0):
--   Không có nhu cầu nào trong kỳ             -> 0
--   Có nhu cầu, ít nhất một budget xác định   -> tổng các budget khác NULL
--   Có nhu cầu nhưng mọi budget đều NULL      -> NULL (chưa xác định)
--
-- Tham số:
--   p_employer_id  INT UNSIGNED  bắt buộc, phải là employer tồn tại
--   p_from_date    DATE          NULL = không giới hạn ngày bắt đầu
--   p_to_date      DATE          NULL = không giới hạn ngày kết thúc
--
-- Lỗi (SQLSTATE 45000):
--   - p_employer_id NULL hoặc không phải employer
--   - p_from_date > p_to_date (khi cả hai khác NULL)
--
-- Cursor + LOOP + IF theo yêu cầu 2.4: duyệt từng nhu cầu, IF tách budget NULL
-- (chỉ đếm) và budget xác định (cộng dồn).
-- =============================================================================

USE recruitment_db;

DROP FUNCTION IF EXISTS fn_employer_recruitment_budget;

DELIMITER $$

CREATE FUNCTION fn_employer_recruitment_budget(
    p_employer_id INT UNSIGNED,
    p_from_date   DATE,
    p_to_date     DATE
)
RETURNS DECIMAL(18,2)
READS SQL DATA
BEGIN
    DECLARE v_budget      DECIMAL(15,2);
    DECLARE v_done        BOOLEAN       DEFAULT FALSE;
    DECLARE v_total       DECIMAL(18,2) DEFAULT 0;
    DECLARE v_need_count  INT           DEFAULT 0;
    DECLARE v_known_count INT           DEFAULT 0;

    DECLARE cur_need CURSOR FOR
        SELECT rn.budget
        FROM recruitment_need AS rn
        INNER JOIN declares_recruitment_need AS d
            ON d.need_id = rn.need_id
        WHERE d.employer_id = p_employer_id
          AND (p_from_date IS NULL OR rn.declared_date >= p_from_date)
          AND (p_to_date   IS NULL OR rn.declared_date <= p_to_date);

    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_done = TRUE;

    -- ---------------------------------------------------------------- validate
    IF p_employer_id IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Mã employer (p_employer_id) là bắt buộc.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM employer WHERE employer_id = p_employer_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Employer (p_employer_id) không tồn tại.';
    END IF;

    IF p_from_date IS NOT NULL AND p_to_date IS NOT NULL AND p_from_date > p_to_date THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).';
    END IF;

    -- ------------------------------------------------------------- calculate
    OPEN cur_need;

    read_loop: LOOP
        FETCH cur_need INTO v_budget;
        IF v_done THEN
            LEAVE read_loop;
        END IF;

        SET v_need_count = v_need_count + 1;

        IF v_budget IS NOT NULL THEN
            SET v_total       = v_total + v_budget;
            SET v_known_count = v_known_count + 1;
        END IF;
    END LOOP read_loop;

    CLOSE cur_need;

    IF v_need_count > 0 AND v_known_count = 0 THEN
        RETURN NULL;   -- có nhu cầu nhưng chưa nhu cầu nào xác định ngân sách
    END IF;

    RETURN v_total;    -- 0 nếu không có nhu cầu trong kỳ
END$$

DELIMITER ;
