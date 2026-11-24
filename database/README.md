# Database scripts

The project targets MySQL 8.4. Schema ownership belongs to M2; M3's seed and
CRUD scripts are based on the relational schema in the submitted Assignment 1
PDF and the two later relationship clarifications.

## Fresh-database order

1. M2 implements and runs `schema/01_schema.sql`, including the confirmed
   ternary declaration and campaign-management relationship, and shares the
   final table and column names with M3.
2. Run completed triggers, if present.
3. Run `seeds/01_seed.sql` once. It is intended to insert at least five rows into every table
   and prints a row-count audit. The seed recalculates `job_posting.application_count`
   after loading applications, so the derived count remains correct whether the
   application-count trigger ran during seeding or not.
4. Run `procedures/m3_job_crud.sql` to install the M3 create, read, update, and
   delete procedures.
5. Run `tests/m3_job_crud.sql` to demonstrate the CRUD operations in a
   transaction that is rolled back at the end; its PASS/FAIL results check
   persisted create, update, and delete outcomes. Run each call in
   `tests/m3_job_crud_expected_errors.sql` separately because each intentionally
   raises an error.

Use a fresh database for the seed: its IDs are fixed and it is not intended to
be run repeatedly against populated tables. End-to-end execution is pending M2's
schema implementation and integration; the current schema file remains M2's
placeholder and is intentionally not implemented by M3.

## M3 implementation notes

- `JOB_POSTING` CRUD creates postings as `open`; the update procedure does not
  change status, leaving status transitions and their rules to M6. Read
  procedures return one posting or list postings.
- CRUD procedures validate required values, dates, salary bounds, application
  method, specialisation category, and campaign/company consistency.
- Deletion is disallowed when applications exist, preserving recruitment history;
  close the posting instead. Work locations and saved-job rows are removed by
  their foreign-key cascades when deletion is allowed.
- The Assignment 1 `DECLARE` ternary relationship is stored in
  `declares_recruitment_need` (`EMPLOYER`, `COMPANY`, `RECRUITMENT_NEED`).
- Campaign creation and management remain separate relationships. A campaign
  requires both a creator and a manager; an employer may manage no campaigns.
  `managed_by_employer_id` represents the new 1:N `manage` relationship.
- Seed password digests are demonstration-only and must not be used for real
  authentication.

`procedures/m3_job_crud.sql` uses `DELIMITER`; run it with a MySQL-aware client
such as MySQL Workbench or the `mysql` command-line client.

## M5 — thống kê hồ sơ và ngân sách tuyển dụng

Chạy sau `schema/01_schema.sql` và `seeds/01_seed.sql` (trigger M4 có thể đã
cài hoặc chưa; kết quả M5 không phụ thuộc trigger):

1. `procedures/m5_application_report.sql` — tạo `sp_report_job_applications` (mục 2.3).
2. `functions/m5_recruitment_budget.sql` — tạo `fn_employer_recruitment_budget` (mục 2.4).
   Chạy bằng tài khoản quản trị (root): MySQL 8.4 bật binary log mặc định nên
   `recruitment_app` tạo function sẽ gặp lỗi 1419, giống trigger M4
   (`triggers/README_M4.md`). Sau khi tạo, `recruitment_app` gọi function bình thường.
3. `tests/m5_sp_report_job_applications.sql` và
   `tests/m5_fn_employer_recruitment_budget.sql` — phần A thêm dữ liệu demo trong
   transaction rồi `ROLLBACK`, nên chạy lại nhiều lần được và seed không đổi; kết
   quả kỳ vọng ghi ngay trên mỗi lệnh (test function tự in `PASS`/`FAIL`). Phần B
   là các câu cố ý báo lỗi, chạy từng câu một.

Hợp đồng gọi, lỗi và ví dụ: `docs/contracts.md`; quyết định thiết kế: `docs/decisions.md` (D-M5-01..07).
