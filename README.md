# Recruitment Database — Assignment 2

Bộ khung khởi đầu theo phân công 6 thành viên. Chưa có schema, procedure,
function, trigger hay ứng dụng nghiệp vụ hoàn chỉnh.

## Cấu trúc

- `database/schema/`: M2 — CREATE TABLE, PK/FK/UNIQUE/CHECK.
- `database/seeds/`: M3 — dữ liệu mẫu; mục tiêu ít nhất 5 dòng/bảng.
- `database/procedures/`: M2 tìm kiếm, M3 CRUD, M5 thống kê, M6 chuyển trạng thái.
- `database/functions/`: M1 tỷ lệ accepted, M5 tính ngân sách.
- `database/triggers/`: M4 — nghiệp vụ, thuộc tính dẫn xuất và constraints bổ sung.
- `database/tests/`: mỗi người thêm kịch bản SQL kiểm tra phần mình.
- `backend/`: M2 — Python 3.12, FastAPI, mysql-connector-python.
- `frontend/`: M6 — React, Vite, JavaScript, Bootstrap 5; Node 22 >=22.12.
- `docs/`: thiết kế, hợp đồng tích hợp và quyết định nhóm.

## Bắt đầu

1. Sao chép `.env.example` thành `.env`, thay các giá trị mật khẩu mẫu.
2. Chạy `docker compose up -d db` tại thư mục gốc, sau khi cài Docker Desktop.
3. Chạy `docker compose ps` để xem trạng thái database.
4. Kết nối DBeaver: host `127.0.0.1`, port `3306`, database `recruitment_db`,
   user `recruitment_app`, mật khẩu theo `.env`.
5. M2 triển khai schema từ bản Assignment 1 cuối cùng; chưa có schema tự nạp.
6. M2 dựng backend theo `backend/README.md`; M6 dựng frontend theo `frontend/README.md`.

Compose hiện chỉ chạy MySQL. Backend và frontend chưa được khởi tạo mã nguồn.

## Quy ước môi trường

- Mỗi thành viên chạy database riêng, dùng cùng script trong Git.
- Database đề xuất: MySQL 8.4, InnoDB, utf8mb4.
- `mysql:8.4` là tag khởi đầu; M2 kiểm chứng rồi khóa bản vá hoặc digest cụ thể.
- M2/M6 khóa dependencies backend/frontend sau khi dựng thành công.
- Không commit `.env`, mật khẩu thật, `.venv`, `node_modules`, dữ liệu Docker.
- Volume giữ dữ liệu qua các lần restart. `docker compose down` dừng dịch vụ;
  tùy chọn `-v` sẽ xóa cả volume database, chỉ dùng khi chủ động reset.

## SQL và tích hợp

Các file SQL hiện chỉ là nơi giữ chỗ. M2 ghi thứ tự chạy chính xác vào
`database/README.md` sau khi xác định phụ thuộc schema/routines/triggers/seed.
Không tự động nạp seed trước khi thống nhất cách khởi tạo cột dẫn xuất.

Frontend gọi API; backend gọi procedure/function và quản lý commit/rollback.
Nghiệp vụ SQL theo đề phải được thực hiện ở database.

## Làm việc nhóm

Mỗi người làm branch riêng, procedure/function có file riêng. Thay đổi schema
qua M2; thay đổi seed qua M3. Mỗi người tự viết tài liệu và kiểm thử phần mình.
M1 theo dõi, review và ghi nhận quyết định sau phản hồi của người liên quan.
