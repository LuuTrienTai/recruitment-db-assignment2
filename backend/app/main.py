import os

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.job_postings import router
from app.db.connection import database_cursor

app = FastAPI(title="Recruitment Database API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        origin.strip().rstrip("/")
        for origin in os.getenv("CORS_ORIGINS", "http://localhost:5173").split(",")
        if origin.strip()
    ],
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["Content-Type"],
)
app.include_router(router)


@app.get("/api/health/db")
def database_health():
    with database_cursor() as cursor:
        cursor.execute("SELECT 1 AS connected")
        return {"connected": cursor.fetchone()["connected"] == 1}
