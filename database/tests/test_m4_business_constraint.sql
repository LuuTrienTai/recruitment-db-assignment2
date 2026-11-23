-- =============================================================================
-- M4 — Kiểm thử / demo SC15b: không cho Employer có hai Interview scheduled
-- Điều kiện:
--   1. Đã tạo database recruitment_db.
--   2. Đã chạy database/schema/01_schema.sql.
--   3. Đã chạy database/seeds/01_seed.sql.
--   4. Đã chạy database/triggers/m4_business_constraint.sql.
--
-- Cách chạy:
--   PHẦN 0: kiểm tra dữ liệu và trigger.
--   PHẦN A: chạy toàn bộ block trong transaction; cuối block ROLLBACK.
--   PHẦN B: mỗi câu INSERT/UPDATE được đánh dấu EXPECT ERROR phải chạy RIÊNG.
--            Mỗi câu phải báo SQLSTATE 45000. Không bôi đen chạy cả PHẦN B.
--
-- Dữ liệu Interview liên quan có trong seed:
--   901: Employer 202, completed, 2026-11-12 09:00–10:00
--   902: Employer 201, scheduled, 2026-11-20 14:00–15:30
--   903: Employer 203, scheduled, 2026-11-19 10:00–11:00
--   904: Employer 204, scheduled, 2026-11-21 13:30–14:30
--   905: Employer 210, scheduled, 2026-11-23 09:30–10:15
--   906: Employer 209, cancelled, 2026-11-25 09:00–09:45
--
-- Application 802, 803, 805 tồn tại trong seed và được dùng làm FK hợp lệ.
-- =============================================================================

USE recruitment_db;

-- =============================================================== PHẦN 0
-- Kiểm tra đúng database, bảng và trigger đã được tạo.

SELECT DATABASE() AS current_database;

SHOW TRIGGERS
WHERE `Table` = 'interview';

SELECT interview_id, application_id, conducting_employer_id,
       start_time, end_time, interview_status
FROM interview
ORDER BY interview_id;

-- =============================================================== PHẦN A
-- Những trường hợp PHẢI ĐƯỢC CHẤP NHẬN.
-- Toàn bộ dữ liệu thử nghiệm được ROLLBACK ở cuối phần này.

START TRANSACTION;

-- A1. Cùng Employer 201, nhưng lịch mới bắt đầu đúng lúc lịch 902 kết thúc.
--     15:30–16:00 tiếp nối 14:00–15:30 => không overlap, phải INSERT thành công.
INSERT INTO interview
(interview_id, application_id, conducting_employer_id,
 start_time, end_time, interview_mode, venue_or_meeting_link,
 interview_status, feedback, round_type)
VALUES
(9901, 802, 201, '2026-11-20 15:30:00', '2026-11-20 16:00:00',
 'online', 'https://meet.example.test/m4-a1',
 'scheduled', NULL, 'technical');

-- A2. Employer 202 được trùng giờ với Employer 201.
--     Interview 902 của Employer 201 đang diễn ra 14:00–15:30.
--     Employer 202 được phép có lịch 14:30–15:00.
INSERT INTO interview
(interview_id, application_id, conducting_employer_id,
 start_time, end_time, interview_mode, venue_or_meeting_link,
 interview_status, feedback, round_type)
VALUES
(9902, 802, 202, '2026-11-20 14:30:00', '2026-11-20 15:00:00',
 'online', 'https://meet.example.test/m4-a2',
 'scheduled', NULL, 'technical');

-- A3. Một Interview đã completed không chiếm lịch.
--     Employer 202 có Interview 901 completed lúc 09:00–10:00 ngày 12/11.
--     Lịch scheduled cùng khoảng thời gian phải được chấp nhận.
INSERT INTO interview
(interview_id, application_id, conducting_employer_id,
 start_time, end_time, interview_mode, venue_or_meeting_link,
 interview_status, feedback, round_type)
VALUES
(9903, 802, 202, '2026-11-12 09:00:00', '2026-11-12 10:00:00',
 'online', 'https://meet.example.test/m4-a3',
 'scheduled', NULL, 'technical');

-- A4. Một Interview đã cancelled không chiếm lịch.
--     Employer 209 có Interview 906 cancelled lúc 09:00–09:45 ngày 25/11.
INSERT INTO interview
(interview_id, application_id, conducting_employer_id,
 start_time, end_time, interview_mode, venue_or_meeting_link,
 interview_status, feedback, round_type)
VALUES
(9904, 802, 209, '2026-11-25 09:00:00', '2026-11-25 09:45:00',
 'online', 'https://meet.example.test/m4-a4',
 'scheduled', NULL, 'technical');

-- A5. UPDATE không tạo xung đột: đổi thời gian của 9901 sang 16:00–16:30.
UPDATE interview
SET start_time = '2026-11-20 16:00:00',
    end_time   = '2026-11-20 16:30:00'
WHERE interview_id = 9901;

-- A6. UPDATE bản ghi nhưng chuyển trạng thái khỏi scheduled.
--     Việc chuyển thành cancelled không được trigger chặn.
UPDATE interview
SET interview_status = 'cancelled'
WHERE interview_id = 9902;

-- Xem kết quả các INSERT/UPDATE hợp lệ trước khi rollback.
SELECT interview_id, conducting_employer_id,
       start_time, end_time, interview_status
FROM interview
WHERE interview_id BETWEEN 9901 AND 9904
ORDER BY interview_id;

-- Xóa toàn bộ dữ liệu thử nghiệm A; dữ liệu seed được giữ nguyên.
ROLLBACK;

-- =============================================================== PHẦN B
-- Những trường hợp PHẢI BỊ TỪ CHỐI với SQLSTATE 45000.
--
-- QUAN TRỌNG:
--   Chỉ chạy TỪNG câu INSERT/UPDATE một.
--   Mỗi câu bên dưới là một lệnh độc lập và dự kiến báo lỗi trigger.
--   Nếu muốn tiếp tục sau khi một câu báo lỗi, chọn câu kế tiếp để chạy.
-- ===============================================================

-- B1. INSERT overlap với Interview 902:
--     Employer 201 đã có lịch 14:00–15:30 ngày 20/11.
--     Lịch 14:30–15:00 bị overlap => EXPECT ERROR.
INSERT INTO interview
(application_id, conducting_employer_id,
 start_time, end_time, interview_mode, venue_or_meeting_link,
 interview_status, feedback, round_type)
VALUES
(802, 201, '2026-11-20 14:30:00', '2026-11-20 15:00:00',
 'online', 'https://meet.example.test/m4-b1',
 'scheduled', NULL, 'technical');

-- B2. UPDATE làm phát sinh overlap:
--     Bước 1: chạy riêng INSERT bên dưới để tạo Interview 9905 hợp lệ
--             cho Employer 203 vào 11:30–12:00 ngày 19/11.
--     Bước 2: chạy riêng UPDATE tiếp theo, đổi sang 10:30–10:45.
--             Interview 903 của Employer 203 đang là 10:00–11:00,
--             nên UPDATE phải bị từ chối.
--     B3. Sau khi kiểm thử, xóa 9905 nếu INSERT bước 1 thành công.

-- B2 - Step 1: EXPECT SUCCESS (chạy riêng)
INSERT INTO interview
(interview_id, application_id, conducting_employer_id,
 start_time, end_time, interview_mode, venue_or_meeting_link,
 interview_status, feedback, round_type)
VALUES
(9905, 803, 203, '2026-11-19 11:30:00', '2026-11-19 12:00:00',
 'online', 'https://meet.example.test/m4-b2',
 'scheduled', NULL, 'technical');

-- B2 - Step 2: EXPECT ERROR (chạy riêng sau khi Step 1 thành công)
UPDATE interview
SET start_time = '2026-11-19 10:30:00',
    end_time   = '2026-11-19 10:45:00'
WHERE interview_id = 9905;

-- B3. Dọn bản ghi kiểm thử 9905 sau khi hoàn thành B2.
--     Chạy riêng; DELETE không thể tạo ra xung đột lịch.
DELETE FROM interview
WHERE interview_id = 9905;

-- =============================================================== PHẦN C
-- Kiểm tra lại dữ liệu seed sau khi kiểm thử.
-- Không có Interview ID 9901–9905 nào còn tồn tại.
SELECT interview_id, conducting_employer_id,
       start_time, end_time, interview_status
FROM interview
ORDER BY interview_id;

SELECT COUNT(*) AS remaining_test_rows
FROM interview
WHERE interview_id BETWEEN 9901 AND 9905;
-- Kết quả mong đợi: 0
