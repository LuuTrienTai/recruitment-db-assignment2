# Decision log — M1 ghi nhận

Mỗi người phụ trách tìm hiểu và đưa ra một phương án cụ thể trước khi xin góp ý.

| Mã | Vấn đề | Người đề xuất | Phương án/lý do/ảnh hưởng | Người phản hồi | Hạn | Quyết định |
|---|---|---|---|---|---|---|
| D-M1-01 | Mẫu số của `fn_candidate_acceptance_rate` | Tài (M1) | Đếm tổng tất cả `application` đã nộp của `candidate` trong kỳ (`submitted`, `viewed`, `interviewing`, `accepted`, `rejected`). Phản ánh trực tiếp tỷ lệ đơn được nhận trên tổng số lần nộp đơn | Cả nhóm | | Đã chốt |
| D-M1-02 | Cột thời gian và cách lọc biên ngày của `fn_candidate_acceptance_rate` | Tài (M1) | Lọc theo `application.submission_time` (`DATETIME`): `>= TIMESTAMP(p_from_date)` và `< TIMESTAMP(p_to_date + 1 ngày)` để lấy trọn ngày cuối đến `23:59:59`. Cho phép `p_from_date` hoặc `p_to_date` là `NULL` để bỏ giới hạn đầu tương ứng | M2, M5, M6 | | Đã chốt |
| D-M1-03 | Giá trị trả về khi mẫu số = 0 (ứng viên chưa có đơn trong kỳ) | Tài (M1) | Trả về `NULL` thay vì `0.00` để phân biệt rõ ứng viên chưa nộp đơn nào với ứng viên có nộp đơn nhưng `0.00%` được nhận. UI hiển thị `"Chưa có hồ sơ"` khi gặp `NULL` | M2, M6 | | Đã chốt |
| D-M1-04 | Thang đo và kiểu dữ liệu trả về của `fn_candidate_acceptance_rate` | Tài (M1) | Trả về phần trăm `DECIMAL(5,2)` trong đoạn `[0.00, 100.00]`, làm tròn 2 chữ số thập phân (`ROUND((accepted * 100) / total, 2)`) để hiển thị trực tiếp trên UI thống kê | M2, M6 | | Đã chốt |

Stack trong README là phương án đề xuất, chưa phải quyết định đã xác nhận của nhóm.
