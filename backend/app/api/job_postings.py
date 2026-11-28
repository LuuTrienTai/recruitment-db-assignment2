from typing import Annotated

from fastapi import APIRouter, HTTPException, Path, Response

from app.db.connection import call_procedure, database_cursor
from app.schemas.job_postings import JobPostingInput

router = APIRouter(prefix="/api/job-postings", tags=["Job postings"])
JobId = Annotated[int, Path(ge=1, le=4294967295)]

# Positional order follows m3_job_crud.sql. Status and application count are
# managed separately by the existing database routines.
FIELDS = (
    "category_id", "company_id", "campaign_id", "title", "description",
    "working_hours", "saturday_work_policy", "job_level", "required_experience",
    "min_salary", "max_salary", "employment_type", "posted_date",
    "application_deadline", "application_method", "contact_detail",
    "employee_responsibilities", "requirements",
)
PLACEHOLDERS = ", ".join(["%s"] * len(FIELDS))


def job_values(job: JobPostingInput):
    data = job.model_dump()
    data["contact_detail"] = data["contact_detail"] or None
    return tuple(data[field] for field in FIELDS)


def read_job(cursor, job_id):
    rows = call_procedure(cursor, "CALL sp_get_job_posting(%s)", (job_id,))
    if not rows:
        raise HTTPException(404, "The job posting does not exist.")
    job = rows[0]
    for field in ("min_salary", "max_salary"):
        if job[field] is not None:
            job[field] = str(job[field])
    return job


@router.get("/form-options")
def get_form_options():
    with database_cursor() as cursor:
        cursor.execute("SELECT CURRENT_DATE() AS today")
        today = cursor.fetchone()["today"]
        cursor.execute("""
            SELECT category_id, name FROM job_category
            WHERE category_level = 'specialisation' ORDER BY name, category_id
        """)
        categories = cursor.fetchall()
        cursor.execute("SELECT company_id, name FROM company ORDER BY name, company_id")
        companies = cursor.fetchall()
        cursor.execute("""
            SELECT rc.campaign_id, rc.name, e.company_id
            FROM recruitment_campaign AS rc
            JOIN employer AS e ON e.employer_id = rc.created_by_employer_id
            ORDER BY rc.name, rc.campaign_id
        """)
        return {
            "today": today, "categories": categories, "companies": companies,
            "campaigns": cursor.fetchall(),
        }


@router.get("/{job_id}")
def get_job_posting(job_id: JobId):
    with database_cursor() as cursor:
        return read_job(cursor, job_id)


@router.post("", status_code=201)
def create_job_posting(job: JobPostingInput):
    with database_cursor(write=True) as cursor:
        call_procedure(
            cursor, f"CALL sp_create_job_posting({PLACEHOLDERS}, @new_job_id)", job_values(job),
        )
        cursor.execute("SELECT @new_job_id AS job_id")
        return read_job(cursor, cursor.fetchone()["job_id"])


@router.put("/{job_id}")
def update_job_posting(job_id: JobId, job: JobPostingInput):
    with database_cursor(write=True) as cursor:
        call_procedure(
            cursor, f"CALL sp_update_job_posting(%s, {PLACEHOLDERS})", (job_id, *job_values(job)),
        )
        return read_job(cursor, job_id)


@router.delete("/{job_id}", status_code=204)
def delete_job_posting(job_id: JobId):
    with database_cursor(write=True) as cursor:
        call_procedure(cursor, "CALL sp_delete_job_posting(%s)", (job_id,))
    return Response(status_code=204)
