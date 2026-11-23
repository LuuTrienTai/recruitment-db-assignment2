# SQL / API contracts — mỗi người viết phần mình

Mỗi routine cần: tên, chủ sở hữu, mục đích, input/kiểu/default, output/kiểu,
lỗi, quy tắc nghiệp vụ, ví dụ gọi và kết quả kỳ vọng.

| Routine dự kiến | Chủ sở hữu | Trạng thái |
|---|---|---|
| sp_search_job_postings | M2 | Đề xuất |
| sp_create_job_posting / sp_update_job_posting / sp_delete_job_posting | M3 | Đề xuất |
| sp_report_job_applications | M5 | Đã viết, chờ chạy test |
| sp_change_job_status | M6 | Đề xuất |
| fn_candidate_acceptance_rate | M1 | Đề xuất |
| fn_employer_recruitment_budget | M5 | Đã viết, chờ chạy test |

M2 + M6 đối chiếu cách gọi, tên trường, định dạng ngày, NULL, lỗi và HTTP response.

## M5 — sp_report_job_applications (2.3)

- File: `database/procedures/m5_application_report.sql`; test: `database/tests/m5_sp_report_job_applications.sql`.
- Mục đích: thống kê số hồ sơ mỗi tin nhận được trong một khoảng thời gian, phân bố theo trạng thái.
- Gọi: `CALL sp_report_job_applications(p_from_date DATE, p_to_date DATE, p_company_id INT UNSIGNED, p_min_applications INT)`.

| Tham số | NULL | Ý nghĩa |
|---|---|---|
| `p_from_date` | Có — không giới hạn | Lọc `application.submission_time >= from` |
| `p_to_date` | Có — không giới hạn | Lọc `submission_time < to + 1 ngày` (lấy trọn ngày cuối) |
| `p_company_id` | Có — mọi công ty | Lọc `job_posting.company_id` (WHERE) |
| `p_min_applications` | Không — báo lỗi | `HAVING COUNT(application_id) >= min`; 0 = hiện cả tin chưa có hồ sơ |

- Kết quả, mỗi tin một dòng: `job_posting_id, title, company_id, company_name, job_status, posted_date, application_deadline, total_applications, submitted_count, viewed_count, interviewing_count, accepted_count, rejected_count, first_submission, last_submission`. Sắp xếp `total_applications DESC, job_posting_id ASC`.
- Lỗi (SQLSTATE `45000`): `p_min_applications` NULL hoặc âm; `from > to`; `p_company_id` không tồn tại.
- Ví dụ: `CALL sp_report_job_applications('2026-11-01','2026-11-30',NULL,1);`

## M5 — fn_employer_recruitment_budget (2.4)

- File: `database/functions/m5_recruitment_budget.sql`; test: `database/tests/m5_fn_employer_recruitment_budget.sql`.
- Mục đích: tổng ngân sách các recruitment need mà employer khai báo (`declares_recruitment_need`) có `declared_date` trong `[from, to]`.
- Gọi: `SELECT fn_employer_recruitment_budget(p_employer_id INT UNSIGNED, p_from_date DATE, p_to_date DATE)` → `DECIMAL(18,2)` hoặc NULL.
- `p_from_date`/`p_to_date` NULL = không giới hạn đầu đó; `p_employer_id` bắt buộc.

| Trường hợp | Kết quả |
|---|---|
| Không có nhu cầu trong kỳ | `0` |
| Có ít nhất một budget xác định | Tổng các budget khác NULL |
| Có nhu cầu nhưng mọi budget NULL | `NULL` — chưa xác định |

- Lỗi (SQLSTATE `45000`): employer NULL hoặc không tồn tại; `from > to`.
- Backend/frontend: hiển thị NULL là "Chưa xác định", không hiển thị thành 0.
- Ví dụ: `SELECT fn_employer_recruitment_budget(201,'2026-01-01','2026-12-31');`
