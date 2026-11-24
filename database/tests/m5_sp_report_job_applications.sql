-- =============================================================================
-- M5 — Kiểm thử / demo sp_report_job_applications
-- =============================================================================
-- Điều kiện: đã chạy schema, seed, procedures/m5_application_report.sql.
-- Dữ liệu bổ sung nằm trong transaction và bị ROLLBACK ở cuối PHẦN A,
-- seed chung không thay đổi. Nếu đã cài trigger M4 (DA01), application_count
-- được tăng trong transaction và cũng được ROLLBACK hoàn lại.
-- Phần B (case lỗi) chạy từng câu một.
--
-- Hồ sơ trong seed (tin, công ty: mã hồ sơ, ngày nộp, trạng thái):
--   701, công ty 401: 801 10-22 viewed, 802 10-30 interviewing
--   702, công ty 402: 803 10-27 viewed
--   704, công ty 404: 804 11-04 rejected, 806 11-06 accepted
--   705, công ty 405: 805 11-08 submitted
--   703, 706, 707: chưa có hồ sơ
--
-- Hồ sơ bổ sung tuân thủ SC06/SC07 (docs/business_rules.md): nộp vào tin đang
-- mở, nộp trực tiếp (on_site), trước hạn; địa điểm mong muốn thuộc work_location
-- của tin; đồng ý điều khoản dữ liệu cá nhân; ứng viên có tài khoản active;
-- mỗi ứng viên nộp không quá 3 lần vào cùng một tin.
-- =============================================================================

USE recruitment_db;

-- =============================================================== PHẦN A
START TRANSACTION;

INSERT INTO application
(application_id, candidate_id, cv_no, job_posting_id, submission_time, contact_name, email, phone_number, work_location, ai_analyze_cv, personal_data_usage_agreed, application_status)
VALUES
-- đúng 00:00:00 ngày bắt đầu kỳ tháng 11 -> TRONG kỳ
(811, 102, 2, 701, '2026-11-01 00:00:00', 'Binh Tran', 'binh.tran@example.test', '0901000102', 'Ho Chi Minh City', FALSE, TRUE, 'submitted'),
-- 23:59:59 ngày cuối kỳ -> TRONG kỳ (kiểm tra cận trên < to + 1 ngày)
(812, 103, 1, 701, '2026-11-30 23:59:59', 'Chi Le', 'chi.le@example.test', '0901000103', 'Ho Chi Minh City', TRUE, TRUE, 'accepted'),
-- 00:00:00 ngày sau kỳ -> NGOÀI kỳ
(813, 104, 1, 701, '2026-12-01 00:00:00', 'Duc Pham', 'duc.pham@example.test', '0901000104', 'Da Nang', FALSE, TRUE, 'submitted'),
-- 706 có đúng 1 hồ sơ
(814, 102, 1, 706, '2026-11-15 10:00:00', 'Binh Tran', 'binh.tran@example.test', '0901000102', 'Ho Chi Minh City', TRUE, TRUE, 'viewed'),
-- 23:59:59 ngày trước kỳ -> NGOÀI kỳ; 702 chỉ có hồ sơ ngoài kỳ
(815, 103, 2, 702, '2026-10-31 23:59:59', 'Chi Le', 'chi.le@example.test', '0901000103', 'Hanoi', FALSE, TRUE, 'rejected'),
(816, 105, 2, 705, '2026-11-20 08:00:00', 'Ha Vo', 'ha.vo@example.test', '0901000105', 'Da Nang', TRUE, TRUE, 'interviewing'),
(817, 101, 1, 704, '2026-11-10 09:00:00', 'An Nguyen', 'an.nguyen@example.test', '0901000101', 'Hanoi', TRUE, TRUE, 'viewed');

-- A1. Tháng 11/2026, mọi công ty, min = 0 -> 7 dòng (cả tin 0 hồ sơ)
--   704: 3 (viewed 1, accepted 1, rejected 1)
--   701: 2 (submitted 1 [811], accepted 1 [812]) — 801, 802, 813 bị loại
--   705: 2 (submitted 1, interviewing 1)
--   706: 1 (viewed 1)
--   702: 0  <- có hồ sơ 803, 815 nhưng NGOÀI kỳ: xác nhận LEFT JOIN + điều kiện trong ON
--   703: 0
--   707: 0
CALL sp_report_job_applications('2026-11-01', '2026-11-30', NULL, 0);

-- A2. Như A1, min = 1 -> 704(3), 701(2), 705(2), 706(1)
CALL sp_report_job_applications('2026-11-01', '2026-11-30', NULL, 1);

-- A3. Như A1, min = 3 -> chỉ 704(3)
CALL sp_report_job_applications('2026-11-01', '2026-11-30', NULL, 3);

-- A4. Lọc công ty 401 (Lotus Digital), tháng 11, min = 0 -> 701(2), 706(1), 707(0)
CALL sp_report_job_applications('2026-11-01', '2026-11-30', 401, 0);

-- A5. Không giới hạn thời gian, min = 2
--   701: 5 (801, 802, 811, 812, 813), 704: 3, 702: 2, 705: 2
CALL sp_report_job_applications(NULL, NULL, NULL, 2);

-- A6. Chỉ cận dưới từ 2026-11-15, min = 1
--   701: 2 (812, 813), 705: 1 (816), 706: 1 (814); 704 bị loại (hồ sơ đều trước 11-15)
CALL sp_report_job_applications('2026-11-15', NULL, NULL, 1);

-- A7. Một ngày duy nhất 2026-11-30 -> 701(1: 812)
CALL sp_report_job_applications('2026-11-30', '2026-11-30', NULL, 1);

ROLLBACK;

-- =============================================================== PHẦN B
-- Mỗi câu dưới đây PHẢI báo lỗi SQLSTATE 45000 với thông báo tương ứng.
-- Chạy từng câu (DBeaver: Ctrl+Enter) vì câu lỗi sẽ dừng script.

-- B1. 'Số hồ sơ tối thiểu (p_min_applications) là bắt buộc; ...'
CALL sp_report_job_applications('2026-11-01', '2026-11-30', NULL, NULL);

-- B2. 'Số hồ sơ tối thiểu (p_min_applications) không được âm.'
CALL sp_report_job_applications('2026-11-01', '2026-11-30', NULL, -1);

-- B3. 'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).'
CALL sp_report_job_applications('2026-12-01', '2026-11-01', NULL, 0);

-- B4. 'Công ty (p_company_id) không tồn tại.'
CALL sp_report_job_applications(NULL, NULL, 999, 0);
