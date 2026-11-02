# SQL / API contracts — mỗi người viết phần mình

Mỗi routine cần: tên, chủ sở hữu, mục đích, input/kiểu/default, output/kiểu,
lỗi, quy tắc nghiệp vụ, ví dụ gọi và kết quả kỳ vọng.

| Routine dự kiến | Chủ sở hữu | Trạng thái |
|---|---|---|
| sp_search_job_postings | M2 | Đề xuất |
| sp_create_job_posting / sp_update_job_posting / sp_delete_job_posting | M3 | Đề xuất |
| sp_report_job_applications | M5 | Đề xuất |
| sp_change_job_status | M6 | Đề xuất |
| fn_candidate_acceptance_rate | M1 | Đề xuất |
| fn_employer_recruitment_budget | M5 | Đề xuất |

M2 + M6 đối chiếu cách gọi, tên trường, định dạng ngày, NULL, lỗi và HTTP response.
