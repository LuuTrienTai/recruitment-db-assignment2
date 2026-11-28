# Backend

Python 3.12, FastAPI, Uvicorn và mysql-connector-python. Xem [README gốc](../README.md)
để khởi động. API đọc cấu hình `DB_*` và `CORS_ORIGINS` từ `.env` ở thư mục gốc.

| Method | Endpoint | MySQL |
| --- | --- | --- |
| GET | `/api/health/db` | `SELECT 1` |
| GET | `/api/job-postings/form-options` | Đọc công ty, campaign, specialisation và ngày hiện tại |
| GET | `/api/job-postings/{id}` | `CALL sp_get_job_posting` |
| POST | `/api/job-postings` | `CALL sp_create_job_posting`, đọc ID từ tham số OUT |
| PUT | `/api/job-postings/{id}` | `CALL sp_update_job_posting` |
| DELETE | `/api/job-postings/{id}` | `CALL sp_delete_job_posting` |

POST và PUT trả bản ghi đã lưu. Giá trị lương được trả dưới dạng chuỗi thập
phân hoặc `null`. DELETE trả `204`. Lỗi nghiệp vụ từ procedure được trả
qua trường `detail`. API dùng cho môi trường demo local.
