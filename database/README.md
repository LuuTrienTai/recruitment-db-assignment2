# Database scripts

Dự án chạy trên **MySQL 8.4** (`InnoDB`, `utf8mb4`). Schema dựa trên thiết kế Assignment 1 (`docs/Assignment1_Report.pdf`) kèm 2 bổ sung đã chốt cho `declares_recruitment_need` và `recruitment_campaign.managed_by_employer_id`.

## Thứ tự chạy trên database rỗng (M1–M6)

Chạy lần lượt các script dưới đây bằng client hỗ trợ `DELIMITER` (`mysql` CLI hoặc DBeaver *Execute SQL Script*):

1. **Schema (M2):** `schema/01_schema.sql` — tạo toàn bộ 20 bảng, khóa chính, khóa ngoại, `UNIQUE`, và `CHECK` constraints.
2. **Dữ liệu mẫu (M3):** `seeds/01_seed.sql` — nạp dữ liệu mẫu cho 20 bảng (≥ 5 dòng/bảng), tự đối soát `job_posting.application_count` và in bảng kiểm đếm số dòng. *(Chỉ chạy 1 lần trên DB rỗng vì ID là cố định).*
3. **Triggers (M4):**
   - `triggers/m4_application_count.sql` — trigger DA01 (`AFTER INSERT`/`DELETE`/`UPDATE` trên `application`) kèm bước đối soát `application_count`.
   - `triggers/m4_business_constraint.sql` — trigger SC15b (`BEFORE INSERT`/`UPDATE` trên `interview`) chống trùng lịch phỏng vấn của cùng employer.
   *(Nếu MySQL bật binary log và user `recruitment_app` gặp lỗi `1419`, cài trigger/function bằng tài khoản `root` theo hướng dẫn tại `triggers/README_M4.md`).*
4. **Stored Procedures (M2, M3, M5, M6):**
   - `procedures/m2_search_jobs.sql` — `sp_search_job_postings` (mục 2.3).
   - `procedures/m3_job_crud.sql` — `sp_validate_job_posting`, `sp_create_job_posting`, `sp_get_job_posting`, `sp_list_job_postings`, `sp_update_job_posting`, `sp_delete_job_posting` (mục 2.1).
   - `procedures/m6_change_job_status.sql` — `sp_change_job_status` (mục 2.1, bổ sung đổi trạng thái).
   - `procedures/m5_application_report.sql` — `sp_report_job_applications` (mục 2.3).
5. **Functions (M1, M5):** *(nên chạy bằng `root` nếu gặp lỗi 1419; sau khi tạo, `recruitment_app` gọi bình thường)*
   - `functions/m1_candidate_acceptance_rate.sql` — `fn_candidate_acceptance_rate` (mục 2.4).
   - `functions/m5_recruitment_budget.sql` — `fn_employer_recruitment_budget` (mục 2.4).

## Kịch bản kiểm thử (`database/tests/`)

- **M1:** `tests/m1_fn_candidate_acceptance_rate.sql` (Phần A dùng `TRANSACTION` + `ROLLBACK`, Phần B tự bắt `SQLSTATE '45000'`).
- **M2:** `tests/m2_sp_search_job_postings.sql` (Phần A chạy `CALL` kiểm tra lọc/sắp xếp trên seed; Phần B chạy từng câu một để kiểm tra lỗi).
- **M3:** `tests/m3_job_crud.sql` (`TRANSACTION` + `ROLLBACK`); chạy từng câu một trong `tests/m3_job_crud_expected_errors.sql` để kiểm tra thông báo lỗi.
- **M4:** `tests/test_m4_application_count.sql` và `tests/test_m4_business_constraint.sql` (Phần B chạy từng câu một).
- **M5:** `tests/m5_sp_report_job_applications.sql` và `tests/m5_fn_employer_recruitment_budget.sql` (Phần B chạy từng câu một); tùy chọn chạy `python database/tests/m5_verify_random.py` với `mysql-connector-python` và `.env` để đối chiếu ngẫu nhiên.
- **M6:** `tests/m6_change_job_status.sql` (`TRANSACTION` + `ROLLBACK`, in `PASS` khi đạt).

## Ghi chú triển khai

- `JOB_POSTING` được M3 tạo với trạng thái ban đầu `'open'`; `sp_update_job_posting` không sửa `job_status`, việc đóng/mở tin theo quy tắc SC12 do `sp_change_job_status` (M6) phụ trách.
- Không cho phép xóa `job_posting` khi đã có `application` để bảo toàn lịch sử tuyển dụng (đóng tin thay thế). Khi xóa hợp lệ, `work_location` và `candidate_save_job_posting` tự xóa theo `ON DELETE CASCADE`.
- Tài liệu hợp đồng gọi & lỗi chi tiết: `docs/contracts.md`; quyết định thiết kế: `docs/decisions.md`; bảng quy tắc nghiệp vụ: `docs/business_rules.md`.
