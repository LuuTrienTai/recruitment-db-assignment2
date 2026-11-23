# Database — M2 Coordination and M4 Triggers

## General Setup

1. Compare the schema with the final Assignment 1 design.
2. Create the database schema using a local administrative account when DDL privileges are required.
3. Run the SQL files in the order agreed by the team, considering dependencies between schema, seed data, routines, and triggers.
4. Test constraints, CRUD procedures, read-only procedures, functions, and triggers.
5. Do not use the MySQL `root` account for the backend's regular database connection.

## M4 — Semantic Constraints and Derived Attribute

M4 implements one business constraint and one derived attribute using MySQL triggers.

### 1. Business Constraint: SC15b — No Overlapping Interviews

**Rule:** An Employer cannot conduct two `scheduled` Interviews whose time intervals overlap.

Files:

- `database/triggers/m4_business_constraint.sql`
- `database/tests/test_m4_business_constraint.sql`

Triggers:

| Trigger | Event | Purpose |
|---|---|---|
| `trg_interview_no_overlap_before_insert` | BEFORE INSERT | Rejects a new scheduled Interview if it overlaps another scheduled Interview conducted by the same Employer. |
| `trg_interview_no_overlap_before_update` | BEFORE UPDATE | Rejects an update that creates an overlapping scheduled Interview for the same Employer. |

The overlap condition is:

```sql
NEW.start_time < existing.end_time
AND NEW.end_time > existing.start_time
```

Adjacent intervals are allowed. Interviews with statuses other than `scheduled` are not considered conflicts. The UPDATE trigger excludes the row being updated.

**Testing:** Run `database/tests/test_m4_business_constraint.sql`. The tests cover valid non-overlapping and adjacent schedules, different Employers, completed/cancelled Interviews, and INSERT/UPDATE operations that must be rejected. Expected constraint violations return SQLSTATE `45000`.

### 2. Derived Attribute: DA01 — Job Posting Application Count

**Rule:** `job_posting.application_count` stores the number of rows in `application` associated with that Job Posting, regardless of application status.

Files:

- `database/triggers/m4_application_count.sql`
- `database/tests/test_m4_application_count.sql`

Triggers:

| Trigger | Event | Purpose |
|---|---|---|
| `trg_application_count_after_insert` | AFTER INSERT | Increases the count for the related Job Posting. |
| `trg_application_count_after_delete` | AFTER DELETE | Decreases the count for the related Job Posting. |
| `trg_application_count_after_update` | AFTER UPDATE | If `job_posting_id` changes, decreases the old Job Posting count and increases the new one. |

Updates to unrelated Application columns do not change the derived count. The trigger script also synchronizes existing `application_count` values with the current number of Application rows.

**Testing:** Run `database/tests/test_m4_application_count.sql`. It tests INSERT, DELETE, moving an Application to another Job Posting, and updating an unrelated Application attribute. It compares the stored count with `COUNT(*)` from `application` and rolls back test data.

### 3. How to Run M4 SQL Files

Use DBeaver connected to the project database:

1. Open the required `.sql` file in DBeaver.
2. Select the project database connection in the SQL Editor.
3. Use **Execute SQL Script** (`Alt + X`) for the complete file. This is required for scripts that use `DELIMITER`.
4. Run the corresponding test file only after its trigger file has executed successfully.
5. Check the output and result grids for the expected triggers and test results.

Recommended order:

1. Run the final schema.
2. Run the seed data.
3. Run `m4_business_constraint.sql`, then `test_m4_business_constraint.sql`.
4. Run `m4_application_count.sql`, then `test_m4_application_count.sql`.

Run each test script against the same schema and seed version used by the team. Do not rerun a schema script that drops and recreates tables unless a database reset is intended.

### 4. Troubleshooting

#### MySQL Error 1419 — Missing SUPER Privilege

**Symptom:**

```text
SQL Error [1419] [HY000]:
You do not have the SUPER privilege and binary logging is enabled
(you might want to use the less safe log_bin_trust_function_creators variable)
```

**Cause:** Binary logging is enabled, and the application account does not have the administrative privilege required by the current MySQL configuration to create the trigger.

**Development-environment workaround:** Connect to the MySQL container as `root` and enable `log_bin_trust_function_creators`:

```powershell
docker compose exec db mysql -uroot -p
```

Enter the `MYSQL_ROOT_PASSWORD` configured in `.env`. At the `mysql>` prompt, run:

```sql
SET GLOBAL log_bin_trust_function_creators = 1;
SHOW VARIABLES LIKE 'log_bin_trust_function_creators';
```

Confirm that the value is `ON`, then exit:

```sql
EXIT;
```

Return to DBeaver using the regular project database account and execute the trigger script again. Do not grant `SUPER` to the application account. The `SET GLOBAL` setting is runtime-only and may need to be applied again after the MySQL server restarts. Use this workaround only in the local development environment according to the team's database administration policy.

#### DBeaver Warning — UPDATE Without a WHERE Clause

**Symptom:** DBeaver displays a warning similar to:

```text
You are about to execute job_posting statement without a WHERE clause.
Possible data loss. Are you sure?
```

**Cause:** `m4_application_count.sql` contains an intentional synchronization statement that updates `application_count` for every row in `job_posting`, using a correlated `COUNT(*)` query on `application`.

**Action:** Review that the statement is the synchronization UPDATE in `m4_application_count.sql`. It updates the derived count; it does not delete rows. If this is the expected statement, confirm the dialog with **OK**. Do not disable DBeaver's warning globally.

#### Trigger Does Not Appear After Execution

Run:

```sql
SHOW TRIGGERS;
```

Check the trigger name, event, timing, and target table. If a trigger is missing, inspect the SQL execution error before rerunning the script. Do not rerun the schema as a troubleshooting step.

#### Test Statement Returns SQLSTATE 45000

For SC15b, SQLSTATE `45000` is the expected result for test cases that deliberately insert or update an overlapping scheduled Interview for the same Employer. It indicates that the business-constraint trigger rejected the operation. It is not an unexpected failure when running those negative test cases.

## Notes

- Run trigger scripts after the required tables exist.
- Run the seed before M4 trigger tests so the test cases have their expected base records.
- Test scripts use transactions/cleanup to avoid retaining temporary test records. Check the final test output before proceeding.
- Do not use `docker compose down -v` unless the team intentionally wants to delete the MySQL data volume.
