# Frontend

React, Vite và Bootstrap 5. Màn hình mục 3.1 tạo, mở theo ID, sửa và xóa tin
tuyển dụng. Xem [README gốc](../README.md) để khởi động database, API và web.

`npm ci` cài dependencies theo lockfile. `npm run dev` mở cổng 5173 và
`npm run build` tạo bản build. Nếu API chạy ở URL khác mặc định
`http://localhost:8000`, tạo `frontend/.env` từ `.env.example` và chỉnh
`VITE_API_BASE_URL`; cập nhật `CORS_ORIGINS` cho origin của frontend nếu cần.
