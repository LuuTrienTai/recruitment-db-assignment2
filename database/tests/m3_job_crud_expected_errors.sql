-- Run one CALL block at a time after loading the M3 procedures and seed.
-- Each call should raise its documented error and leave existing data unchanged.
USE recruitment_db;

-- Expected: "The job posting to update does not exist."
CALL sp_update_job_posting(
    999999, 4, 401, 601,
    'Missing Posting Update',
    'This update is expected to fail because its ID does not exist.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    20000000,
    30000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Demonstrate the missing-ID validation.',
    'This row must not be inserted.'
);

-- Expected: "The job posting does not exist."
CALL sp_get_job_posting(999999);

-- Expected: "The job posting to delete does not exist."
CALL sp_delete_job_posting(999999);

-- Expected: "The selected job category does not exist."
CALL sp_create_job_posting(
    999999, 401, 601,
    'Invalid Category Demo',
    'This call is expected to fail category validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    20000000,
    30000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Demonstrate category validation.',
    'This row must not be inserted.',
    @invalid_job_posting_id
);

-- Expected: "The selected recruitment campaign does not exist."
CALL sp_create_job_posting(
    4, 401, 999999,
    'Invalid Campaign Demo',
    'This call is expected to fail campaign validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    20000000,
    30000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Demonstrate campaign validation.',
    'This row must not be inserted.',
    @invalid_job_posting_id
);

-- Expected: "Job posting company must match the company of the campaign creator."
CALL sp_create_job_posting(
    4, 402, 601,
    'Mismatched Campaign Company Demo',
    'This call is expected to fail campaign/company consistency validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    20000000,
    30000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Demonstrate campaign/company validation.',
    'This row must not be inserted.',
    @invalid_job_posting_id
);

-- Expected: "Salary values must be positive."
CALL sp_create_job_posting(
    4, 401, 601,
    'Negative Salary Demo',
    'This call is expected to fail salary validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    NULL,
    -1,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Demonstrate salary validation.',
    'This row must not be inserted.',
    @invalid_job_posting_id
);

-- Expected: "Application deadline must be later than the posted date."
CALL sp_update_job_posting(
    701, 4, 401, 601,
    'Invalid Deadline Demo',
    'This update is expected to fail date validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Senior',
    '3_5_years',
    30000000,
    45000000,
    'full_time',
    CURRENT_DATE(),
    DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY),
    'on_site',
    NULL,
    'Demonstrate date validation.',
    'This update must not be applied.'
);

-- Expected: "Contact details are required for an external application."
CALL sp_create_job_posting(
    4, 401, 601,
    'Missing External Contact Demo',
    'This call is expected to fail external-contact validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    20000000,
    30000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'external',
    NULL,
    'Demonstrate external contact validation.',
    'This row must not be inserted.',
    @invalid_job_posting_id
);

-- Expected: "Minimum salary cannot exceed maximum salary."
CALL sp_create_job_posting(
    4, 401, 601,
    'Invalid Salary Range Demo',
    'This call is expected to fail salary-range validation.',
    'Monday-Friday, 09:00-18:00',
    'off',
    'Mid-level',
    '1_3_years',
    40000000,
    20000000,
    'full_time',
    CURRENT_DATE(),
    DATE_ADD(CURRENT_DATE(), INTERVAL 30 DAY),
    'on_site',
    NULL,
    'Demonstrate salary-range validation.',
    'This row must not be inserted.',
    @invalid_job_posting_id
);

-- Expected: "Cannot delete a job posting with applications; close it instead to preserve recruitment history."
CALL sp_delete_job_posting(701);
