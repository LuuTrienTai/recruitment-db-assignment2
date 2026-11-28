from datetime import date
from decimal import Decimal
from typing import Annotated, Literal

from pydantic import BaseModel, ConfigDict, Field, field_validator

RecordId = Annotated[int, Field(ge=1, le=4294967295)]
Salary = Annotated[Decimal, Field(max_digits=12, decimal_places=2)]
JobText = Annotated[str, Field(min_length=1, max_length=255)]


class JobPostingInput(BaseModel):
    model_config = ConfigDict(str_strip_whitespace=True, extra="forbid")

    category_id: RecordId
    company_id: RecordId
    campaign_id: RecordId
    title: JobText
    description: Annotated[str, Field(min_length=1)]
    working_hours: Annotated[str, Field(min_length=1, max_length=100)]
    saturday_work_policy: Literal["working", "off", "not_specified"]
    job_level: Annotated[str, Field(min_length=1, max_length=50)]
    required_experience: Literal["no_experience", "under_1_year", "1_3_years", "3_5_years", "over_5_years"]
    min_salary: Salary | None = None
    max_salary: Salary | None = None
    employment_type: Literal["full_time", "part_time", "contract", "internship"]
    posted_date: date
    application_deadline: date
    application_method: Literal["on_site", "external"]
    contact_detail: Annotated[str, Field(max_length=255)] | None = None
    employee_responsibilities: JobText
    requirements: Annotated[str, Field(min_length=1)]

    @field_validator("description", "requirements")
    @classmethod
    def fit_mysql_text(cls, value: str) -> str:
        if len(value.encode("utf-8")) > 65_535:
            raise ValueError("Text must fit within 65,535 UTF-8 bytes.")
        return value
