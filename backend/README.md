# Backend — M2

Stack: Python 3.12, FastAPI, Uvicorn, mysql-connector-python.

M2 cần:
- Tạo virtual environment và khóa dependencies trong requirements.txt.
- Tạo entrypoint FastAPI và cấu hình đọc biến môi trường.
- Endpoint /api/health/db thực hiện SELECT 1.
- Lớp gọi stored procedure/function bằng tham số, xử lý result sets.
- Commit/rollback rõ ràng; chuyển lỗi nghiệp vụ thành phản hồi API.
- Cấu hình CORS cho http://localhost:5173.

Cấu trúc đã chuẩn bị: app/api, app/core, app/db, app/services, app/schemas.
Chưa có endpoint hoặc logic ứng dụng triển khai sẵn.
