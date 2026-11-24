# SQL / API contracts — mỗi người viết phần mình

Mỗi routine cần: tên, chủ sở hữu, mục đích, input/kiểu/default, output/kiểu,
lỗi, quy tắc nghiệp vụ, ví dụ gọi và kết quả kỳ vọng.

| Routine dự kiến | Chủ sở hữu | Trạng thái |
|---|---|---|
| sp_search_job_postings | M2 | Đề xuất |
| sp_create_job_posting / sp_update_job_posting / sp_delete_job_posting | M3 | Đề xuất |
| sp_report_job_applications | M5 | Đề xuất |
| sp_change_job_status | M6 | Đề xuất |
| fn_candidate_acceptance_rate | M1 | Đã viết, đã có kịch bản test |
| fn_employer_recruitment_budget | M5 | Đề xuất |

M2 + M6 đối chiếu cách gọi, tên trường, định dạng ngày, NULL, lỗi và HTTP response.

## M1 — fn_candidate_acceptance_rate (2.4)

- File: `database/functions/m1_candidate_acceptance_rate.sql`; test: `database/tests/m1_fn_candidate_acceptance_rate.sql`.
- Mục đích: tính tỷ lệ phần trăm (`%`) hồ sơ có trạng thái `'accepted'` trên tổng số hồ sơ ứng tuyển (`application`) của một `candidate` trong khoảng thời gian nộp đơn.
- Gọi: `SELECT fn_candidate_acceptance_rate(p_candidate_id INT UNSIGNED, p_from_date DATE, p_to_date DATE)` → `DECIMAL(5,2)` hoặc `NULL`.

| Tham số | Kiểu | Cho phép NULL? | Ý nghĩa |
|---|---|---|---|
| `p_candidate_id` | `INT UNSIGNED` | Không — báo lỗi | Mã ứng viên cần tính tỷ lệ (phải tồn tại trong bảng `candidate`) |
| `p_from_date` | `DATE` | Có — không giới hạn đầu dưới | Lọc `application.submission_time >= TIMESTAMP(p_from_date)` (`00:00:00` ngày bắt đầu) |
| `p_to_date` | `DATE` | Có — không giới hạn đầu trên | Lọc `application.submission_time < TIMESTAMP(p_to_date + 1 ngày)` (lấy trọn đến hết ngày kết thúc) |

| Trường hợp | Giá trị trả về |
|---|---|
| Không có hồ sơ nào trong kỳ (mẫu số = 0) | `NULL` (chưa có dữ liệu ứng tuyển để tính tỷ lệ) |
| Có hồ sơ nhưng không có đơn nào `'accepted'` | `0.00` |
| Có ít nhất một hồ sơ trong kỳ | `ROUND((accepted_count * 100) / total_count, 2)` thuộc `[0.00, 100.00]` (`DECIMAL(5,2)`) |

- Quy tắc nghiệp vụ & kỹ thuật:
  - Mẫu số tính toàn bộ hồ sơ của ứng viên trong kỳ (`submitted`, `viewed`, `interviewing`, `accepted`, `rejected`).
  - Duyệt từng hồ sơ bằng `CURSOR` + `LOOP` + `IF` theo yêu cầu mục 2.4.
- Lỗi (`SQLSTATE '45000'`):
  - `p_candidate_id` là `NULL`: `'Mã ứng viên (p_candidate_id) là bắt buộc.'`
  - `p_candidate_id` không tồn tại trong bảng `candidate`: `'Ứng viên (p_candidate_id) không tồn tại.'`
  - `p_from_date > p_to_date` (khi cả hai khác `NULL`): `'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).'`
- Lưu ý tích hợp Backend (M2) / Frontend (M6):
  - Khi kết quả trả về `NULL`, hiển thị `"Chưa có hồ sơ"` / `"N/A"`, không ép thành `0%`.
  - Khi kết quả khác `NULL`, hiển thị kèm ký hiệu `%` (ví dụ `33.33%`, `100.00%`).
- Ví dụ gọi trên dữ liệu seed gốc:
  - `SELECT fn_candidate_acceptance_rate(105, '2026-01-01', '2026-12-31');` → `100.00`
  - `SELECT fn_candidate_acceptance_rate(101, '2026-01-01', '2026-12-31');` → `0.00`
  - `SELECT fn_candidate_acceptance_rate(106, NULL, NULL);` → `NULL`
