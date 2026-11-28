# Recruitment Database — Assignment 2

Dự án Database Systems (CO2013) — Assignment 2, thực hiện theo phân công 6 thành viên (M1–M6) trên MySQL 8.4.
Repo có schema, seed và các routine của Phần 1–2. Màn hình CRUD tin tuyển dụng cho mục 3.1 chạy với FastAPI, React và MySQL.

## Cấu trúc

- `database/schema/`: M2 — `CREATE TABLE`, `PK`/`FK`/`UNIQUE`/`CHECK` cho 20 bảng (`01_schema.sql`).
- `database/seeds/`: M3 — dữ liệu mẫu cho toàn bộ 20 bảng, mỗi bảng ≥ 5 dòng (`01_seed.sql`).
- `database/triggers/`: M4 — trigger nghiệp vụ SC15b (`m4_business_constraint.sql`) và thuộc tính dẫn xuất DA01 (`m4_application_count.sql`).
- `database/procedures/`: M2 tìm kiếm (`m2_search_jobs.sql`), M3 CRUD (`m3_job_crud.sql`), M5 thống kê (`m5_application_report.sql`), M6 chuyển trạng thái (`m6_change_job_status.sql`).
- `database/functions/`: M1 tỷ lệ accepted (`m1_candidate_acceptance_rate.sql`), M5 tính ngân sách (`m5_recruitment_budget.sql`).
- `database/tests/`: kịch bản SQL/Python kiểm thử độc lập cho từng thành phần M1–M6.
- `backend/`: M2 — Python 3.12, FastAPI, `mysql-connector-python`.
- `frontend/`: M6 — React, Vite (JavaScript), Bootstrap 5; Node >= 22.12.
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

## Chạy web CRUD mục 3.1

Cần Docker Desktop, Python 3.12 và Node.js từ 22.12. Chạy ở thư mục gốc sau khi giải nén.

### 1. Chuẩn bị database

Tạo `.env` từ `.env.example` nếu chưa có. Đặt `DB_PASSWORD` trùng với
`MYSQL_PASSWORD` và `DB_PORT` trùng với `MYSQL_PORT`.

```bash
docker compose up -d --wait db
```

Với một **database mới, rỗng**, nạp schema, seed, trigger và các procedure CRUD.
Script schema có lệnh `DROP TABLE`. Nếu database hiện có đã nạp đúng schema
và các procedure CRUD, bỏ qua khối nạp này.

```bash
dbsql() {
  docker compose exec -T db sh -c \
    'exec mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'
}

dbsql < database/schema/01_schema.sql &&
dbsql < database/triggers/m2_job_category_no_self_parent.sql &&
dbsql < database/seeds/01_seed.sql &&
dbsql < database/triggers/m4_application_count.sql &&
dbsql < database/triggers/m4_business_constraint.sql &&
dbsql < database/procedures/m3_job_crud.sql
```

Xem [database/README.md](database/README.md) để cài các routine còn lại của Phần 2.

### 2. Chạy API và website

Terminal thứ nhất, từ thư mục gốc:

```bash
cd backend
python3.12 -m venv .venv
source .venv/bin/activate
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --reload
```

Terminal thứ hai, từ thư mục gốc:

```bash
cd frontend
npm ci
npm run dev
```

Mở [website](http://localhost:5173). Kiểm tra kết nối tại
[API health](http://localhost:8000/api/health/db). Swagger UI ở
[API docs](http://localhost:8000/docs).

### 3. Demo

1. Chọn **New posting**. Chọn công ty Lotus Digital, một campaign của công ty,
   một specialisation và điền các trường bắt buộc. Hạn ứng tuyển phải sau ngày
   đăng. Chọn **Create posting** và ghi lại ID mới.
2. Tải lại trang, nhập ID đã ghi và chọn **Load**. Sửa tiêu đề, bấm **Save
   changes**, rồi chọn **Load** để thấy thay đổi đã được lưu.
3. Chọn **Delete posting** và xác nhận. Thử tải lại ID vừa xóa để kiểm tra.
4. Tải tin seed **701**, thử xóa và xem lỗi nghiệp vụ do tin đã có hồ sơ ứng
   tuyển. Bản ghi vẫn hiển thị.

Form hiện dùng ID để mở một bản ghi. Mục 3.2 có thể mở lại màn hình CRUD từ
danh sách của `sp_search_job_postings` và dùng lại [các endpoint CRUD](backend/README.md).
