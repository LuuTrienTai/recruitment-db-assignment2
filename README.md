# Recruitment Database — Assignment 2

Dự án Database Systems (CO2013) — Assignment 2, thực hiện theo phân công 6 thành viên (M1–M6) trên MySQL 8.4.
Hiện tại đã hoàn thiện phần cơ sở dữ liệu (Phần 1 & Phần 2: schema, seed, triggers, stored procedures, functions và kịch bản kiểm thử); phần ứng dụng Backend/Frontend (Phần 3) đang chờ triển khai.

## Cấu trúc

- `database/schema/`: M2 — `CREATE TABLE`, `PK`/`FK`/`UNIQUE`/`CHECK` cho 20 bảng (`01_schema.sql`).
- `database/seeds/`: M3 — dữ liệu mẫu cho toàn bộ 20 bảng, mỗi bảng ≥ 5 dòng (`01_seed.sql`).
- `database/triggers/`: M4 — trigger nghiệp vụ SC15b (`m4_business_constraint.sql`) và thuộc tính dẫn xuất DA01 (`m4_application_count.sql`).
- `database/procedures/`: M2 tìm kiếm (`m2_search_jobs.sql`), M3 CRUD (`m3_job_crud.sql`), M5 thống kê (`m5_application_report.sql`), M6 chuyển trạng thái (`m6_change_job_status.sql`).
- `database/functions/`: M1 tỷ lệ accepted (`m1_candidate_acceptance_rate.sql`), M5 tính ngân sách (`m5_recruitment_budget.sql`).
- `database/tests/`: kịch bản SQL/Python kiểm thử độc lập cho từng thành phần M1–M6.
- `backend/`: M2 — Python 3.12, FastAPI, `mysql-connector-python` (khung thư mục, chưa triển khai).
- `frontend/`: M6 — React, Vite (JavaScript), Bootstrap 5; Node >= 22.12 (khung thư mục, chưa triển khai).
- `docs/`: đề bài, báo cáo Assignment 1, hợp đồng tích hợp, từ điển dữ liệu, bảng quy tắc nghiệp vụ và quyết định thiết kế.

## Bắt đầu nhanh với Database

1. Sao chép `.env.example` thành `.env`, thay các giá trị mật khẩu mẫu.
2. Chạy `docker compose up -d db` tại thư mục gốc, sau khi cài Docker Desktop.
3. Chạy `docker compose ps` để kiểm tra trạng thái MySQL 8.4 (`healthy`).
4. Kết nối bằng DBeaver hoặc `mysql` client (host `127.0.0.1`, port `3306`, database `recruitment_db`, user `recruitment_app` hoặc `root` khi cài function/trigger nếu bật binary log).
5. Nạp SQL và chạy kiểm thử theo thứ tự chuẩn trong [database/README.md](database/README.md).

## Quy ước môi trường & làm việc nhóm

- Database: MySQL 8.4, InnoDB, `utf8mb4`.
- Không commit `.env`, mật khẩu thật, `.venv`, `node_modules`, dữ liệu Docker.
- Volume giữ dữ liệu qua các lần restart; chỉ dùng `docker compose down -v` khi chủ động reset database từ đầu.
- Frontend gọi API; backend gọi stored procedure/function trong database và quản lý `COMMIT`/`ROLLBACK`.
- Nghiệp vụ SQL theo đề phải được thực hiện ở tầng database (`CHECK`, trigger, stored procedure, function).
