# SQL / API contracts — mỗi người viết phần mình

Mỗi routine cần: tên, chủ sở hữu, mục đích, input/kiểu/default, output/kiểu,
lỗi, quy tắc nghiệp vụ, ví dụ gọi và kết quả kỳ vọng.

| Routine | Chủ sở hữu | Trạng thái |
|---|---|---|
| sp_search_job_postings | M2 | Đã viết, đã có kịch bản test |
| sp_create_job_posting / sp_get_job_posting / sp_list_job_postings / sp_update_job_posting / sp_delete_job_posting | M3 | Đã viết, đã có kịch bản test |
| sp_report_job_applications | M5 | Đã viết, đã test trên MySQL 8.4 |
| sp_change_job_status | M6 | Đã viết, đã có kịch bản test |
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
| `p_to_date` | `DATE` | Có — không giới hạn đầu trên | Lọc `DATE(application.submission_time) <= p_to_date` (lấy trọn đến hết ngày kết thúc, an toàn cả với `'9999-12-31'`) |

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

## M2 — sp_search_job_postings (2.3)

- File: `database/procedures/m2_search_jobs.sql`; test: `database/tests/m2_sp_search_job_postings.sql`.
- Mục đích: tìm kiếm, lọc và sắp xếp danh sách tin tuyển dụng (`job_posting`) kết hợp tên công ty (`company`) và tên danh mục nghề (`job_category`). Dùng cho màn hình danh sách/tìm kiếm tin (mục 3.2).
- Gọi: `CALL sp_search_job_postings(p_keyword VARCHAR(255), p_company_id INT UNSIGNED, p_category_id INT UNSIGNED, p_job_status VARCHAR(25), p_sort_by VARCHAR(30))`.

| Tham số | Kiểu | Cho phép NULL? | Ý nghĩa |
|---|---|---|---|
| `p_keyword` | `VARCHAR(255)` | Có — không lọc từ khóa | Lọc `jp.title LIKE CONCAT('%', p_keyword, '%')` |
| `p_company_id` | `INT UNSIGNED` | Có — mọi công ty | Lọc `jp.company_id = p_company_id` |
| `p_category_id` | `INT UNSIGNED` | Có — mọi danh mục | Lọc `jp.category_id = p_category_id` |
| `p_job_status` | `VARCHAR(25)` | Có — mọi trạng thái | Chỉ nhận `'open'`, `'closed'` hoặc `NULL` |
| `p_sort_by` | `VARCHAR(30)` | Có — mặc định `posted_date DESC, job_posting_id DESC` | Nhận `'title'` (ASC), `'posted_date'` (DESC), `'application_deadline'` (DESC), `'min_salary'` (DESC), `'max_salary'` (DESC), hoặc `NULL` |

- Kết quả: trả các cột `job_posting_id`, `title`, `company_id`, `company_name`, `category_id`, `category_name`, `job_status`, `min_salary`, `max_salary`, `posted_date`, `application_deadline`, `application_count`.
- Lỗi (`SQLSTATE '45000'`):
  - `p_job_status` khác `'open'`, `'closed'` (khi khác `NULL`): `'Job status must be open or closed.'`
  - `p_sort_by` ngoài danh sách hợp lệ (khi khác `NULL`): `'Sort column must be title, posted_date, application_deadline, min_salary, or max_salary.'`
- Ví dụ gọi trên dữ liệu seed gốc:
  - `CALL sp_search_job_postings('Engineer', NULL, NULL, NULL, NULL);` → các tin có từ `Engineer` trong tiêu đề (`701`, `702`, `707`).
  - `CALL sp_search_job_postings(NULL, NULL, NULL, 'closed', NULL);` → tin `703`.

## M3 — Job Posting CRUD (2.1)

- File: `database/procedures/m3_job_crud.sql`; test: `database/tests/m3_job_crud.sql`, `database/tests/m3_job_crud_expected_errors.sql`.
- Các procedure:
  - `sp_validate_job_posting(...)`: helper kiểm tra tính hợp lệ các trường dữ liệu, mức lương dương (`> 0`), `min_salary <= max_salary`, `application_deadline > posted_date`, `contact_detail` bắt buộc khi `application_method = 'external'`, `category_id` thuộc cấp `'specialisation'`, `company_id` tồn tại và khớp với công ty của người tạo `campaign_id`.
  - `sp_create_job_posting(..., OUT p_job_posting_id INT UNSIGNED)`: tạo tin mới với trạng thái mặc định `'open'`; yêu cầu `p_posted_date <= CURRENT_DATE()` và `p_application_deadline >= CURRENT_DATE()`.
  - `sp_get_job_posting(p_job_posting_id INT UNSIGNED)`: trả chi tiết 1 dòng từ `job_posting` (báo lỗi nếu `NULL` hoặc không tồn tại).
  - `sp_list_job_postings()`: trả toàn bộ `job_posting` sắp xếp `posted_date DESC, job_posting_id DESC`.
  - `sp_update_job_posting(p_job_posting_id INT UNSIGNED, ...)`: cập nhật thông tin tin tuyển dụng (không thay đổi `job_status` — phần đổi trạng thái do M6 `sp_change_job_status` phụ trách).
  - `sp_delete_job_posting(p_job_posting_id INT UNSIGNED)`: chỉ cho phép xóa khi tin chưa có bản ghi `application` nào; nếu đã có hồ sơ ứng tuyển thì báo lỗi `'Cannot delete a job posting with applications; close it instead to preserve recruitment history.'` để bảo toàn lịch sử tuyển dụng.
- Lỗi (`SQLSTATE '45000'`): trả thông báo tiếng Anh cụ thể cho từng trường thiếu/sai miền giá trị, sai ngày (`'Application deadline must be later than the posted date.'`), lương không dương (`'Salary values must be positive.'`), sai cấp danh mục, không khớp công ty của campaign, ID không tồn tại hoặc xóa tin đã có hồ sơ.

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

## M6 — sp_change_job_status (2.1)

- SQL: `database/procedures/m6_change_job_status.sql`. Kiểm thử trên dữ liệu seed: `database/tests/m6_change_job_status.sql`.
- Gọi `CALL sp_change_job_status(p_job_posting_id, p_new_status)`. Hai tham số bắt buộc, không có giá trị mặc định.
- `p_job_posting_id INT UNSIGNED` là khóa của `job_posting`, phải lớn hơn 0.
- `p_new_status TEXT` nhận đúng `open` hoặc `closed`. Backend gửi mã trạng thái chữ thường.
- Thành công trả một dòng gồm `job_posting_id` và `job_status`. Gửi lại cùng trạng thái hợp lệ được xử lý như một lần thành công.
- Theo SC12, có thể đóng tin khi còn hạn hoặc đã quá hạn. Có thể mở lại tin nếu `application_deadline >= CURRENT_DATE()` theo múi giờ phiên MySQL. Tin hết hạn vẫn báo lỗi khi yêu cầu `open`, kể cả nếu dữ liệu cũ đang lưu `open`.
- Lỗi dùng `SQLSTATE '45000'` với thông báo cụ thể cho ID thiếu hoặc bằng 0, tin không tồn tại, trạng thái sai, hạn đã qua hoặc thay đổi đồng thời cần thử lại.
- Procedure chỉ cập nhật `job_posting.job_status`. M3 tạo tin với `open` và phụ trách sửa các trường thông tin khác. Backend quản lý transaction nếu gọi cùng các thao tác khác và kiểm tra quyền thao tác của người dùng trước khi gọi.
- Ví dụ trên seed, `CALL sp_change_job_status(701, 'closed');` trả `701, closed`. `CALL sp_change_job_status(703, 'open');` báo đã quá hạn khi ngày hiện tại sau 2026-10-31.
- SC12 còn cần tác vụ định kỳ đóng các tin khi thời gian trôi qua. Procedure này xử lý yêu cầu đổi trạng thái theo từng tin.
