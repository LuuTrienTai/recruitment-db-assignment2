# Data dictionary — M2

Điền theo schema triển khai tại `database/schema/01_schema.sql` (20 bảng, MySQL 8.4).

| Bảng | Cột | Kiểu dữ liệu | NULL? | Khóa / Constraint | Ý nghĩa |
|---|---|---|---|---|---|
| `user_account` | `account_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã định danh tài khoản người dùng |
| `user_account` | `first_name` | `TEXT` | NO | — | Tên |
| `user_account` | `last_name` | `TEXT` | NO | — | Họ |
| `user_account` | `gender` | `VARCHAR(25)` | NO | — | Giới tính |
| `user_account` | `email_address` | `VARCHAR(255)` | NO | `UNIQUE` | Email đăng nhập duy nhất |
| `user_account` | `hashed_password` | `VARCHAR(255)` | YES | `CHECK` bắt buộc khi đăng ký bằng `email` | Mật khẩu đã băm (NULL nếu OAuth) |
| `user_account` | `phone_number` | `VARCHAR(25)` | NO | — | Số điện thoại liên hệ |
| `user_account` | `registration_method` | `VARCHAR(255)` | NO | `CHECK IN ('email','Google','Facebook','LinkedIn')` | Phương thức đăng ký |
| `user_account` | `account_status` | `VARCHAR(10)` | NO | `CHECK IN ('unverified','active','locked')` | Trạng thái tài khoản |
| `user_account` | `created_date` | `DATE` | NO | `DEFAULT (CURRENT_DATE)` | Ngày tạo tài khoản |
| `company` | `company_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã công ty |
| `company` | `sector` | `VARCHAR(255)` | NO | — | Lĩnh vực hoạt động |
| `company` | `address` | `TEXT` | NO | — | Địa chỉ trụ sở |
| `company` | `name` | `VARCHAR(255)` | NO | — | Tên công ty |
| `company` | `company_type` | `VARCHAR(25)` | NO | `CHECK IN ('normal','pro')` | Phân loại công ty |
| `job_category` | `category_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã danh mục nghề nghiệp |
| `job_category` | `parent_category_id` | `INT UNSIGNED` | YES | `FK -> job_category(category_id)` (`ON DELETE SET NULL`), `CHECK` theo cấp | Danh mục cha |
| `job_category` | `name` | `TEXT` | NO | — | Tên danh mục |
| `job_category` | `category_level` | `VARCHAR(25)` | NO | `CHECK IN ('group','profession','specialisation')` | Cấp phân cấp (1..3) |
| `candidate` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> user_account(account_id)` (`ON DELETE CASCADE`) | Mã ứng viên (kế thừa tài khoản) |
| `candidate` | `expected_salary` | `DECIMAL(12,2)` | NO | `CHECK (> 0)` | Mức lương kỳ vọng (VND/tháng) |
| `candidate` | `experience_level` | `VARCHAR(25)` | NO | `CHECK IN ('no_experience','under_1_year','1_3_years','3_5_years','over_5_years')` | Kinh nghiệm làm việc |
| `candidate` | `work_at_other_place` | `BOOLEAN` | NO | `DEFAULT FALSE` | Sẵn sàng làm việc ở nơi khác |
| `candidate` | `receive_suggestion` | `BOOLEAN` | NO | `DEFAULT TRUE` | Nhận gợi ý việc làm AI |
| `candidate` | `receive_promotion` | `BOOLEAN` | NO | `DEFAULT FALSE` | Nhận email khuyến mãi |
| `employer` | `employer_id` | `INT UNSIGNED` | NO | `PK`, `FK -> user_account(account_id)` (`ON DELETE CASCADE`) | Mã nhà tuyển dụng |
| `employer` | `company_id` | `INT UNSIGNED` | NO | `FK -> company(company_id)` (`ON DELETE RESTRICT`) | Công ty mà NTD đại diện |
| `employer` | `job_title` | `VARCHAR(50)` | NO | — | Chức danh tại công ty |
| `administrator` | `admin_id` | `INT UNSIGNED` | NO | `PK`, `FK -> user_account(account_id)` (`ON DELETE CASCADE`) | Mã quản trị viên |
| `administrator` | `administrative_access_level` | `VARCHAR(50)` | NO | `CHECK IN ('reviewer','manager','super_admin')` | Cấp quyền quản trị |
| `cv` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> candidate(candidate_id)` (`ON DELETE CASCADE ON UPDATE CASCADE`) | Mã ứng viên sở hữu CV |
| `cv` | `cv_no` | `INT UNSIGNED` | NO | `PK` (ghép cùng `candidate_id`) | Số thứ tự CV của ứng viên |
| `cv` | `name` | `VARCHAR(255)` | NO | — | Tên tệp CV |
| `cv` | `location` | `VARCHAR(500)` | NO | — | Đường dẫn lưu trữ tệp CV |
| `cv` | `file_format` | `VARCHAR(10)` | NO | `CHECK IN ('pdf','doc','docx')` | Định dạng tệp |
| `cv` | `file_size_bytes` | `INT UNSIGNED` | NO | `CHECK (> 0 AND <= 5242880)` | Dung lượng tệp (tối đa 5 MB) |
| `cv` | `uploaded_date` | `DATETIME` | NO | `DEFAULT CURRENT_TIMESTAMP` | Thời điểm tải lên |
| `job_alert` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> candidate(candidate_id)` (`ON DELETE CASCADE`) | Mã ứng viên tạo thông báo |
| `job_alert` | `alert_no` | `INT UNSIGNED` | NO | `PK` (ghép cùng `candidate_id`) | Số thứ tự thông báo việc làm |
| `job_alert` | `search_keyword` | `VARCHAR(255)` | NO | `CHECK` không rỗng | Từ khóa tìm kiếm |
| `job_alert` | `province_city` | `VARCHAR(50)` | YES | `CHECK` bắt buộc nếu có `district` | Tỉnh/Thành phố |
| `job_alert` | `district` | `VARCHAR(50)` | YES | — | Quận/Huyện |
| `job_alert` | `salary_level` | `VARCHAR(50)` | NO | — | Mức lương lọc |
| `job_alert` | `experience_level` | `VARCHAR(25)` | NO | — | Kinh nghiệm lọc |
| `job_alert` | `professional_role` | `VARCHAR(50)` | NO | — | Vị trí chuyên môn lọc |
| `job_alert` | `employment_type` | `VARCHAR(50)` | NO | — | Hình thức làm việc |
| `job_alert` | `notification_frequency` | `VARCHAR(25)` | NO | `CHECK IN ('daily','weekly')` | Tần suất gửi thông báo |
| `job_alert` | `delivery_channel` | `VARCHAR(50)` | NO | `CHECK IN ('email','app','both')` | Kênh nhận thông báo |
| `job_alert` | `consent_confirmed` | `BOOLEAN` | NO | `CHECK (= TRUE)` | Xác nhận đồng ý dữ liệu cá nhân |
| `job_alert` | `consent_confirmed_at` | `DATETIME` | YES | `DEFAULT CURRENT_TIMESTAMP`, `CHECK NOT NULL` | Thời điểm xác nhận đồng ý |
| `candidate_desired_location` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> candidate(candidate_id)` (`ON DELETE CASCADE`) | Mã ứng viên |
| `candidate_desired_location` | `province_city` | `VARCHAR(100)` | NO | `PK` (ghép cùng `candidate_id`) | Tỉnh/Thành phố mong muốn làm việc |
| `candidate_interest_job_category` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> candidate(candidate_id)` (`ON DELETE CASCADE`) | Mã ứng viên |
| `candidate_interest_job_category` | `category_id` | `INT UNSIGNED` | NO | `PK`, `FK -> job_category(category_id)` (`ON DELETE CASCADE`) | Chuyên môn quan tâm (tối đa 5) |
| `candidate_follow_company` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> candidate(candidate_id)` (`ON DELETE CASCADE`) | Mã ứng viên theo dõi |
| `candidate_follow_company` | `company_id` | `INT UNSIGNED` | NO | `PK`, `FK -> company(company_id)` (`ON DELETE CASCADE`) | Mã công ty được theo dõi |
| `candidate_follow_company` | `followed_date` | `DATETIME` | NO | `DEFAULT CURRENT_TIMESTAMP` | Thời điểm bắt đầu theo dõi |
| `recruitment_need` | `need_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã nhu cầu tuyển dụng |
| `recruitment_need` | `declared_date` | `DATE` | NO | `DEFAULT (CURRENT_DATE)` | Ngày khai báo nhu cầu |
| `recruitment_need` | `professional_position` | `VARCHAR(255)` | NO | — | Vị trí chuyên môn cần tuyển |
| `recruitment_need` | `job_level` | `VARCHAR(25)` | NO | — | Cấp bậc vị trí |
| `recruitment_need` | `number_employee_required` | `INT UNSIGNED` | NO | `CHECK (> 0)` | Số lượng nhân sự cần tuyển |
| `recruitment_need` | `expected_completion_date` | `DATE` | YES | `CHECK (IS NULL OR > declared_date)` | Ngày dự kiến hoàn thành (`NULL` = tuyển liên tục) |
| `recruitment_need` | `budget` | `DECIMAL(15,2)` | YES | `CHECK (IS NULL OR >= 0)` | Ngân sách tuyển dụng dự kiến |
| `recruitment_need` | `budget_source` | `VARCHAR(255)` | YES | — | Nguồn ngân sách |
| `recruitment_need` | `consultation` | `TEXT` | YES | — | Nội dung yêu cầu tư vấn |
| `declares_recruitment_need` | `need_id` | `INT UNSIGNED` | NO | `PK`, `FK -> recruitment_need(need_id)` (`ON DELETE CASCADE`) | Mã nhu cầu được khai báo |
| `declares_recruitment_need` | `employer_id` | `INT UNSIGNED` | NO | `FK -> employer(employer_id)` (`ON DELETE RESTRICT`) | NTD khai báo nhu cầu |
| `declares_recruitment_need` | `company_id` | `INT UNSIGNED` | NO | `FK -> company(company_id)` (`ON DELETE RESTRICT`) | Công ty gắn với khai báo |
| `verification_task` | `task_type` | `VARCHAR(50)` | NO | `PK`, `CHECK IN ('phone_verification','company_information','business_registration','personal_data_agreement')` | Loại bước xác thực |
| `verification_task` | `employer_id` | `INT UNSIGNED` | NO | `PK`, `FK -> employer(employer_id)` (`ON DELETE CASCADE`) | NTD cần xác thực |
| `verification_task` | `admin_id` | `INT UNSIGNED` | YES | `FK -> administrator(admin_id)` (`ON DELETE SET NULL`), `CHECK` theo loại task | Admin duyệt (NULL cho bước tự động) |
| `verification_task` | `task_status` | `VARCHAR(25)` | NO | `DEFAULT 'not_completed'`, `CHECK IN ('not_completed','submitted','approved','rejected')` | Trạng thái xác thực |
| `verification_task` | `submitted_document` | `TEXT` | YES | — | Tài liệu đính kèm |
| `verification_task` | `submitted_at` | `DATE` | YES | `DEFAULT (CURRENT_DATE)` | Ngày nộp |
| `verification_task` | `reviewed_at` | `DATE` | YES | `CHECK (>= submitted_at)`, bắt buộc khi duyệt/từ chối thủ công | Ngày duyệt |
| `recruitment_campaign` | `campaign_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã chiến dịch tuyển dụng |
| `recruitment_campaign` | `created_by_employer_id` | `INT UNSIGNED` | NO | `FK -> employer(employer_id)` (`ON DELETE RESTRICT`) | NTD tạo chiến dịch |
| `recruitment_campaign` | `managed_by_employer_id` | `INT UNSIGNED` | NO | `FK -> employer(employer_id)` (`ON DELETE RESTRICT`) | NTD quản lý chiến dịch |
| `recruitment_campaign` | `recruitment_need_id` | `INT UNSIGNED` | YES | `UNIQUE`, `FK -> recruitment_need(need_id)` (`ON DELETE SET NULL`) | Nhu cầu tuyển dụng tương ứng (1:1 tùy chọn) |
| `recruitment_campaign` | `name` | `TEXT` | NO | — | Tên chiến dịch |
| `recruitment_campaign` | `creation_date` | `DATETIME` | NO | `DEFAULT CURRENT_TIMESTAMP` | Thời điểm tạo chiến dịch |
| `recruitment_campaign` | `campaign_status` | `VARCHAR(20)` | NO | `CHECK IN ('running','stopped')` | Trạng thái chiến dịch |
| `job_posting` | `job_posting_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã tin tuyển dụng |
| `job_posting` | `category_id` | `INT UNSIGNED` | NO | `FK -> job_category(category_id)` (`ON DELETE RESTRICT`) | Chuyên môn của tin |
| `job_posting` | `company_id` | `INT UNSIGNED` | NO | `FK -> company(company_id)` (`ON DELETE RESTRICT`) | Công ty đăng tin |
| `job_posting` | `campaign_id` | `INT UNSIGNED` | NO | `FK -> recruitment_campaign(campaign_id)` (`ON DELETE RESTRICT`) | Chiến dịch chứa tin |
| `job_posting` | `title` | `VARCHAR(255)` | NO | — | Tiêu đề tin tuyển dụng |
| `job_posting` | `description` | `TEXT` | NO | — | Mô tả công việc |
| `job_posting` | `working_hours` | `VARCHAR(100)` | NO | — | Thời gian làm việc |
| `job_posting` | `saturday_work_policy` | `VARCHAR(50)` | NO | `CHECK IN ('working','off','not_specified')` | Chính sách làm thứ 7 |
| `job_posting` | `job_level` | `VARCHAR(50)` | NO | — | Cấp bậc công việc |
| `job_posting` | `required_experience` | `VARCHAR(50)` | NO | `CHECK IN ('no_experience','under_1_year','1_3_years','3_5_years','over_5_years')` | Kinh nghiệm yêu cầu |
| `job_posting` | `job_status` | `VARCHAR(25)` | NO | `CHECK IN ('open','closed')` | Trạng thái tin |
| `job_posting` | `min_salary` | `DECIMAL(12,2)` | YES | `CHECK (IS NULL OR > 0)` | Lương tối thiểu (`NULL` = thỏa thuận) |
| `job_posting` | `max_salary` | `DECIMAL(12,2)` | YES | `CHECK (IS NULL OR > 0)`, `CHECK (max_salary >= min_salary)` | Lương tối đa |
| `job_posting` | `employment_type` | `VARCHAR(25)` | NO | `CHECK IN ('full_time','part_time','contract','internship')` | Hình thức làm việc |
| `job_posting` | `posted_date` | `DATE` | NO | `DEFAULT (CURRENT_DATE)` | Ngày đăng tin |
| `job_posting` | `application_deadline` | `DATE` | NO | `DEFAULT (CURRENT_DATE)`, `CHECK (> posted_date)` | Hạn nộp hồ sơ |
| `job_posting` | `application_method` | `VARCHAR(50)` | NO | `CHECK IN ('on_site','external')` | Cách thức ứng tuyển |
| `job_posting` | `contact_detail` | `VARCHAR(255)` | YES | `CHECK` bắt buộc khi `application_method = 'external'` | Thông tin liên hệ ngoài hệ thống |
| `job_posting` | `employee_responsibilities` | `VARCHAR(255)` | NO | — | Trách nhiệm công việc |
| `job_posting` | `requirements` | `TEXT` | NO | — | Yêu cầu ứng viên |
| `job_posting` | `application_count` | `INT UNSIGNED` | NO | `DEFAULT 0` | Thuộc tính dẫn xuất: tổng số hồ sơ (trigger DA01) |
| `candidate_save_job_posting` | `candidate_id` | `INT UNSIGNED` | NO | `PK`, `FK -> candidate(candidate_id)` (`ON DELETE CASCADE`) | Mã ứng viên lưu tin |
| `candidate_save_job_posting` | `job_posting_id` | `INT UNSIGNED` | NO | `PK`, `FK -> job_posting(job_posting_id)` (`ON DELETE CASCADE`) | Mã tin được lưu |
| `candidate_save_job_posting` | `saved_date` | `DATETIME` | NO | `DEFAULT CURRENT_TIMESTAMP` | Thời điểm lưu tin |
| `work_location` | `job_posting_id` | `INT UNSIGNED` | NO | `PK`, `FK -> job_posting(job_posting_id)` (`ON DELETE CASCADE`) | Mã tin tuyển dụng |
| `work_location` | `province_city` | `VARCHAR(100)` | NO | `PK` (ghép) | Tỉnh/Thành phố làm việc |
| `work_location` | `address` | `VARCHAR(255)` | NO | `PK` (ghép) | Địa chỉ làm việc cụ thể |
| `application` | `application_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã hồ sơ ứng tuyển |
| `application` | `candidate_id` | `INT UNSIGNED` | NO | `FK -> cv(candidate_id, cv_no)` (`ON DELETE RESTRICT`) | Ứng viên nộp đơn |
| `application` | `cv_no` | `INT UNSIGNED` | NO | `FK -> cv(candidate_id, cv_no)` (`ON DELETE RESTRICT`) | Số hiệu CV của chính ứng viên đó |
| `application` | `job_posting_id` | `INT UNSIGNED` | NO | `FK -> job_posting(job_posting_id)` (`ON DELETE RESTRICT`) | Tin tuyển dụng ứng tuyển |
| `application` | `submission_time` | `DATETIME` | NO | `DEFAULT CURRENT_TIMESTAMP` | Thời điểm nộp hồ sơ |
| `application` | `contact_name` | `VARCHAR(255)` | NO | `CHECK` không rỗng | Họ tên liên hệ |
| `application` | `email` | `VARCHAR(255)` | NO | `CHECK` không rỗng | Email liên hệ |
| `application` | `phone_number` | `VARCHAR(255)` | NO | `CHECK` không rỗng | Số điện thoại liên hệ |
| `application` | `work_location` | `VARCHAR(500)` | NO | `CHECK` không rỗng | Địa điểm làm việc mong muốn |
| `application` | `ai_analyze_cv` | `BOOLEAN` | NO | `DEFAULT FALSE` | Cho phép AI phân tích CV |
| `application` | `personal_data_usage_agreed` | `BOOLEAN` | NO | `DEFAULT FALSE`, `CHECK (= TRUE)` | Đồng ý thỏa thuận dữ liệu cá nhân |
| `application` | `application_status` | `VARCHAR(25)` | NO | `CHECK IN ('submitted','viewed','interviewing','accepted','rejected')` | Trạng thái hồ sơ |
| `interview` | `interview_id` | `INT UNSIGNED` | NO | `PK`, `AUTO_INCREMENT` | Mã lịch phỏng vấn |
| `interview` | `application_id` | `INT UNSIGNED` | NO | `FK -> application(application_id)` (`ON DELETE CASCADE`) | Hồ sơ được phỏng vấn |
| `interview` | `conducting_employer_id` | `INT UNSIGNED` | NO | `FK -> employer(employer_id)` (`ON DELETE RESTRICT`) | NTD chủ trì phỏng vấn |
| `interview` | `start_time` | `DATETIME` | NO | — | Thời điểm bắt đầu |
| `interview` | `end_time` | `DATETIME` | NO | `CHECK (> start_time)` | Thời điểm kết thúc |
| `interview` | `interview_mode` | `VARCHAR(25)` | NO | `CHECK IN ('online','in_person')` | Hình thức phỏng vấn |
| `interview` | `venue_or_meeting_link` | `TEXT` | YES | — | Địa điểm hoặc link họp trực tuyến |
| `interview` | `interview_status` | `VARCHAR(25)` | NO | `CHECK IN ('scheduled','completed','cancelled')` | Trạng thái buổi phỏng vấn |
| `interview` | `feedback` | `TEXT` | YES | `CHECK (IS NULL OR interview_status = 'completed')` | Nhận xét sau phỏng vấn |
| `interview` | `round_type` | `VARCHAR(25)` | NO | — | Vòng phỏng vấn (`screening`, `technical`, `final`...) |
