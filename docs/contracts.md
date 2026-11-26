# SQL / API contracts — mỗi người viết phần mình

Mỗi routine cần: tên, chủ sở hữu, mục đích, input/kiểu/default, output/kiểu,
lỗi, quy tắc nghiệp vụ, ví dụ gọi và kết quả kỳ vọng.

| Routine dự kiến | Chủ sở hữu | Trạng thái |
|---|---|---|
| sp_search_job_postings | M2 | Đề xuất |
| sp_create_job_posting / sp_update_job_posting / sp_delete_job_posting | M3 | Đề xuất |
| sp_report_job_applications | M5 | Đã viết, đã test trên MySQL 8.4 |
| sp_change_job_status | M6 | Đề xuất |
| fn_candidate_acceptance_rate | M1 | Đã viết, đã có kịch bản test |
| fn_employer_recruitment_budget | M5 | Đã viết, đã test trên MySQL 8.4 |

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

## M5 — sp_report_job_applications (2.3)

- File: `database/procedures/m5_application_report.sql`; test: `database/tests/m5_sp_report_job_applications.sql`.
- Mục đích: thống kê số hồ sơ mỗi tin tuyển dụng nhận được trong một khoảng thời gian nộp hồ sơ, kèm phân bố theo trạng thái. Dùng cho màn hình thống kê của nhà tuyển dụng (mục 3.3).
- Gọi: `CALL sp_report_job_applications(p_from_date DATE, p_to_date DATE, p_company_id BIGINT, p_min_applications INT)`.

| Tham số | Kiểu | Cho phép NULL? | Ý nghĩa |
|---|---|---|---|
| `p_from_date` | `DATE` | Có — không giới hạn đầu dưới | Chỉ đếm hồ sơ có `application.submission_time >= p_from_date` (`00:00:00`) |
| `p_to_date` | `DATE` | Có — không giới hạn đầu trên | Chỉ đếm hồ sơ có `DATE(submission_time) <= p_to_date` (lấy trọn ngày cuối, đúng cả với `9999-12-31`) |
| `p_company_id` | `BIGINT` | Có — mọi công ty | Mệnh đề `WHERE`: chỉ lấy tin của công ty này. `BIGINT` có dấu để `0`/số âm nhận thông báo "không tồn tại" thay vì lỗi tràn kiểu |
| `p_min_applications` | `INT` | Không — báo lỗi | Mệnh đề `HAVING COUNT(a.application_id) >= p_min_applications`; `0` = hiện cả tin chưa có hồ sơ nào trong kỳ |

- Kết quả: mỗi tin một dòng, sắp xếp `total_applications DESC, job_posting_id ASC`.

| Cột | Ý nghĩa |
|---|---|
| `job_posting_id`, `title`, `job_status`, `posted_date`, `application_deadline` | Thông tin tin tuyển dụng |
| `company_id`, `company_name` | Công ty đăng tin |
| `total_applications` | Số hồ sơ nộp trong kỳ (`0` nếu không có) |
| `submitted_count`, `viewed_count`, `interviewing_count`, `accepted_count`, `rejected_count` | Số hồ sơ trong kỳ theo từng trạng thái; cộng lại bằng `total_applications`. Cả 6 cột đếm đều là số nguyên (`COUNT`) |
| `first_submission`, `last_submission` | Thời điểm nộp sớm nhất / muộn nhất trong kỳ; `NULL` khi tin không có hồ sơ |

- Quy tắc nghiệp vụ & kỹ thuật:
  - Lọc theo thời điểm **nộp hồ sơ**, không theo ngày đăng tin.
  - `LEFT JOIN application`, điều kiện thời gian đặt trong `ON` để tin không có hồ sơ trong kỳ vẫn xuất hiện với số đếm `0`.
  - Đếm trực tiếp từ bảng `application`, không đọc cột dẫn xuất `job_posting.application_count` (cột này đếm mọi hồ sơ, không theo kỳ).
- Lỗi (`SQLSTATE '45000'`):
  - `p_min_applications` là `NULL`: `'Số hồ sơ tối thiểu (p_min_applications) là bắt buộc; nhập 0 để hiển thị cả tin chưa có hồ sơ.'`
  - `p_min_applications < 0`: `'Số hồ sơ tối thiểu (p_min_applications) không được âm.'`
  - `p_from_date > p_to_date` (khi cả hai khác `NULL`): `'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).'`
  - `p_company_id` không tồn tại (kể cả `0`, số âm): `'Công ty (p_company_id) không tồn tại.'`
  - Ngày sai định dạng (vd. `'2026-13-01'`) bị MySQL chặn trước khi vào procedure: lỗi `1292 Incorrect date value … for column 'p_from_date'`. UI dùng date picker / backend gửi kiểu `date` thì không xảy ra.
- Lưu ý tích hợp Backend (M2) / Frontend (M6):
  - Ô "số hồ sơ tối thiểu" nên có giá trị mặc định `0`; ô ngày để trống thì gửi `NULL`.
  - Với `mysql-connector-python`: `cursor.callproc(...)` rồi đọc `cursor.stored_results()`; lỗi nghiệp vụ là `mysql.connector.Error` có `errno = 1644`, `sqlstate = '45000'`, `msg` = thông báo tiếng Việt ở trên. Ở bản 26.x `stored_results()` báo DeprecationWarning (sẽ thành property) nhưng vẫn chạy.
- Ví dụ gọi trên dữ liệu seed gốc:
  - `CALL sp_report_job_applications('2026-10-01', '2026-11-30', NULL, 1);` → `701` (2), `704` (2), `702` (1), `705` (1)
  - `CALL sp_report_job_applications(NULL, NULL, 401, 0);` → `701` (2), `706` (0), `707` (0)

## M5 — fn_employer_recruitment_budget (2.4)

- File: `database/functions/m5_recruitment_budget.sql`; test: `database/tests/m5_fn_employer_recruitment_budget.sql`.
- Mục đích: tính tổng ngân sách của các nhu cầu tuyển dụng (`recruitment_need`) mà một employer **khai báo** (`declares_recruitment_need.employer_id`) có `declared_date` trong khoảng thời gian. Đây là ngân sách đã cam kết theo ngày khai báo, không phải số tiền chi tiêu trong kỳ.
- Gọi: `SELECT fn_employer_recruitment_budget(p_employer_id BIGINT, p_from_date DATE, p_to_date DATE)` → `DECIMAL(18,2)` (Python: `Decimal`) hoặc `NULL` (Python: `None`).

| Tham số | Kiểu | Cho phép NULL? | Ý nghĩa |
|---|---|---|---|
| `p_employer_id` | `BIGINT` | Không — báo lỗi | Mã employer (phải tồn tại trong bảng `employer`; `0`/số âm báo "không tồn tại") |
| `p_from_date` | `DATE` | Có — không giới hạn đầu dưới | Lọc `recruitment_need.declared_date >= p_from_date` |
| `p_to_date` | `DATE` | Có — không giới hạn đầu trên | Lọc `recruitment_need.declared_date <= p_to_date` |

| Trường hợp | Giá trị trả về |
|---|---|
| Không có nhu cầu nào trong kỳ | `0.00` |
| Có ít nhất một nhu cầu có `budget` xác định | Tổng các `budget` khác `NULL` (nhu cầu có `budget` `NULL` không được cộng) |
| Có nhu cầu nhưng mọi `budget` đều `NULL` | `NULL` (chưa xác định được ngân sách) |

- Quy tắc nghiệp vụ & kỹ thuật:
  - `budget = NULL` nghĩa là chưa xác định; `budget = 0` là ngân sách thật bằng 0. Hai trường hợp không được gộp bằng `IFNULL(budget, 0)`.
  - Duyệt từng nhu cầu bằng `CURSOR` + `LOOP` + `IF` theo yêu cầu mục 2.4: `IF` tách nhu cầu chưa có ngân sách (chỉ đếm) với nhu cầu có ngân sách (cộng dồn).
- Lỗi (`SQLSTATE '45000'`):
  - `p_employer_id` là `NULL`: `'Mã employer (p_employer_id) là bắt buộc.'`
  - `p_employer_id` không tồn tại trong bảng `employer`: `'Employer (p_employer_id) không tồn tại.'`
  - `p_from_date > p_to_date` (khi cả hai khác `NULL`): `'Ngày bắt đầu (p_from_date) phải nhỏ hơn hoặc bằng ngày kết thúc (p_to_date).'`
- Lưu ý tích hợp Backend (M2) / Frontend (M6): khi kết quả là `NULL`, hiển thị `"Chưa xác định"`, không ép thành `0`.
- Ví dụ gọi trên dữ liệu seed gốc:
  - `SELECT fn_employer_recruitment_budget(201, '2026-01-01', '2026-12-31');` → `900000000.00`
  - `SELECT fn_employer_recruitment_budget(210, NULL, NULL);` → `0.00` (nhu cầu 506 có ngân sách bằng 0)
  - `SELECT fn_employer_recruitment_budget(209, NULL, NULL);` → `NULL` (nhu cầu 505 chưa có ngân sách)
  - `SELECT fn_employer_recruitment_budget(202, NULL, NULL);` → `0.00` (không khai báo nhu cầu nào)
