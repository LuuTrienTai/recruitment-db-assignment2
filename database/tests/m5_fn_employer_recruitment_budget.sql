-- =============================================================================
-- M5 — Kiểm thử / demo fn_employer_recruitment_budget
-- =============================================================================
-- Điều kiện: đã chạy schema, seed, functions/m5_recruitment_budget.sql.
-- Dữ liệu bổ sung nằm trong transaction và bị ROLLBACK ở cuối PHẦN A.
--
-- Nhu cầu trong seed (need: employer, declared_date, budget):
--   501: 201, 2026-01-10, 900,000,000     502: 203, 2026-02-12, 480,000,000
--   503: 205, 2026-03-15, 360,000,000     504: 207, 2026-04-18, 240,000,000
--   505: 209, 2026-05-20, NULL            506: 210, 2026-06-22, 0
--   Employer 202, 204, 206, 208: không khai báo nhu cầu nào.
-- =============================================================================

USE recruitment_db;

-- =============================================================== PHẦN A
START TRANSACTION;

INSERT INTO recruitment_need
(need_id, declared_date, professional_position, job_level, number_employee_required, expected_completion_date, budget, budget_source, consultation)
VALUES
(511, '2026-07-01', 'Site Reliability Engineer',    'Senior',      1, NULL,         NULL,      'Engineering department', NULL),
(512, '2026-08-15', 'Backend Engineering Intern',   'Intern',      2, NULL,         0,         'Early-career program',   NULL),
(513, '2026-09-30', 'Platform Engineering Manager', 'Manager',     1, '2027-03-31', 150000000, 'Engineering department', NULL),
(514, '2026-10-05', 'Learning Support Officer',     'Entry-level', 3, NULL,         NULL,      'Annual operating budget', NULL),
(515, '2026-03-01', 'Curriculum Designer',          'Mid-level',   1, '2026-09-30', 120000000, 'Content program',        NULL);

INSERT INTO declares_recruitment_need (need_id, employer_id, company_id) VALUES
(511, 201, 401),
(512, 201, 401),
(513, 201, 401),
(514, 209, 405),
(515, 210, 405);

-- Sau khi thêm, employer 201 có: 501 (900tr), 511 (NULL), 512 (0), 513 (150tr)
--                 employer 209 có: 505 (NULL), 514 (NULL)
--                 employer 210 có: 515 (120tr), 506 (0)

SELECT 'A1 không có nhu cầu nào -> 0'                     AS test_case, fn_employer_recruitment_budget(202, NULL, NULL)                 AS result
UNION ALL
SELECT 'A2 một nhu cầu, budget NULL -> NULL',                        fn_employer_recruitment_budget(209, '2026-05-01', '2026-05-31')
UNION ALL
SELECT 'A3 nhiều nhu cầu, đều NULL -> NULL',                         fn_employer_recruitment_budget(209, NULL, NULL)
UNION ALL
SELECT 'A4 NULL + 0 + dương -> 1050000000.00',                       fn_employer_recruitment_budget(201, '2026-01-01', '2026-12-31')
UNION ALL
SELECT 'A5 chỉ budget 0 -> 0.00',                                    fn_employer_recruitment_budget(201, '2026-08-01', '2026-08-31')
UNION ALL
SELECT 'A6 chỉ cận dưới 2026-07-01 -> 150000000.00',                 fn_employer_recruitment_budget(201, '2026-07-01', NULL)
UNION ALL
SELECT 'A7 chỉ cận trên 2026-06-30 -> 900000000.00',                 fn_employer_recruitment_budget(201, NULL, '2026-06-30')
UNION ALL
SELECT 'A8 có nhu cầu khác kỳ, không có trong kỳ -> 0',              fn_employer_recruitment_budget(201, '2026-02-01', '2026-06-30')
UNION ALL
SELECT 'A9 biên ngày, from = to = declared_date -> 150000000.00',    fn_employer_recruitment_budget(201, '2026-09-30', '2026-09-30')
UNION ALL
SELECT 'A10 dương + 0 -> 120000000.00',                              fn_employer_recruitment_budget(210, NULL, NULL);

-- A11. Demo cho giao diện 3.3: ngân sách năm 2026 của từng employer
--   201: 1050000000.00   202: 0   203: 480000000.00   204: 0   205: 360000000.00
--   206: 0               207: 240000000.00   208: 0   209: NULL   210: 120000000.00
SELECT e.employer_id,
       CONCAT(u.first_name, ' ', u.last_name) AS employer_name,
       c.name                                 AS company_name,
       fn_employer_recruitment_budget(e.employer_id, '2026-01-01', '2026-12-31') AS budget_2026
FROM employer AS e
INNER JOIN user_account AS u ON u.account_id = e.employer_id
INNER JOIN company      AS c ON c.company_id = e.company_id
ORDER BY e.employer_id;

ROLLBACK;

-- =============================================================== PHẦN B
-- Mỗi câu dưới đây PHẢI báo lỗi SQLSTATE 45000. Chạy từng câu.

-- B1. 'Mã employer (p_employer_id) là bắt buộc.'
SELECT fn_employer_recruitment_budget(NULL, NULL, NULL);

-- B2. 'Employer (p_employer_id) không tồn tại.'
SELECT fn_employer_recruitment_budget(999, NULL, NULL);

-- B3. 'Employer (p_employer_id) không tồn tại.' — 101 là candidate, không phải employer
SELECT fn_employer_recruitment_budget(101, NULL, NULL);

-- B4. 'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).'
SELECT fn_employer_recruitment_budget(201, '2026-12-31', '2026-01-01');
