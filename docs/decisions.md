# Decision log — M1 ghi nhận

Mỗi người phụ trách tìm hiểu và đưa ra một phương án cụ thể trước khi xin góp ý.

| Mã | Vấn đề | Người đề xuất | Phương án/lý do/ảnh hưởng | Người phản hồi | Hạn | Quyết định |
|---|---|---|---|---|---|---|
| D-M5-01 | Function 2 gắn employer với recruitment need qua đâu | Nhựt (M5) | `declares_recruitment_need.employer_id`: quan hệ khai báo trực tiếp, mỗi need đúng một người khai báo. Không đi qua `recruitment_campaign` (campaign có người tạo/quản lý khác nhau, `recruitment_need_id` có thể NULL) | | | Đề xuất |
| D-M5-02 | Function 2 lọc kỳ theo cột nào | Nhựt (M5) | `declared_date` (NOT NULL). Ý nghĩa: tổng ngân sách các need **được khai báo** trong kỳ, không phải chi tiêu trong kỳ. Budget không phân bổ theo tháng; lọc theo giao khoảng sẽ cộng trùng khi cộng nhiều kỳ. NULL ngày = không giới hạn | | | Đề xuất |
| D-M5-03 | Function 2 xử lý budget NULL | Nhựt (M5) | NULL = chưa xác định, 0 = ngân sách thật. Không có need → 0; có budget xác định → tổng các budget khác NULL; mọi budget NULL → NULL. Không dùng `IFNULL(budget,0)` (seed: employer 209 ≠ 210) | | | Đề xuất |
| D-M5-04 | Procedure 2.3 lọc thời gian theo cột nào | Nhựt (M5) | `application.submission_time`, cận trên `< to + 1 ngày`. Không lọc theo `posted_date` để không trùng `sp_search_job_postings` | | | Đề xuất |
| D-M5-05 | Procedure 2.3 có hiện tin 0 hồ sơ không | Nhựt (M5) | Có: `LEFT JOIN application`, điều kiện thời gian trong `ON`, đếm `COUNT(a.application_id)` | | | Đề xuất |
| D-M5-06 | Procedure 2.3 có dùng cột `application_count` không | Nhựt (M5) | Không; tự aggregate từ `application`. Cột dẫn xuất do trigger M4 duy trì | | | Đề xuất |
| D-M5-07 | `p_min_applications` NULL | Nhựt (M5) | Báo lỗi; app điền mặc định 0 | | | Đề xuất |

Stack trong README là phương án đề xuất, chưa phải quyết định đã xác nhận của nhóm.
