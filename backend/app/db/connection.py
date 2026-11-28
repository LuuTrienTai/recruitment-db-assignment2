import logging
import os
from contextlib import contextmanager
from pathlib import Path

import mysql.connector
from dotenv import load_dotenv
from fastapi import HTTPException

load_dotenv(Path(__file__).resolve().parents[3] / ".env")
logger = logging.getLogger(__name__)


@contextmanager
def database_cursor(*, write=False):
    connection = None
    try:
        connection = mysql.connector.connect(
            host=os.getenv("DB_HOST", "127.0.0.1"),
            port=int(os.getenv("DB_PORT", "3306")),
            database=os.getenv("DB_NAME", "recruitment_db"),
            user=os.getenv("DB_USER", "recruitment_app"),
            password=os.getenv("DB_PASSWORD", ""),
            connection_timeout=5,
        )
        with connection.cursor(dictionary=True, buffered=True) as cursor:
            yield cursor
        if write:
            connection.commit()
    except mysql.connector.Error as error:
        if error.sqlstate == "45000":
            status = 404 if error.msg in {
                "The job posting does not exist.",
                "The job posting to update does not exist.",
                "The job posting to delete does not exist.",
            } else 422
            raise HTTPException(status, error.msg) from error
        if error.errno == 1451:
            raise HTTPException(409, "This posting is referenced by other records and cannot be deleted.") from error
        if error.errno in {1205, 1213}:
            raise HTTPException(409, "Another database update is in progress. Try again.") from error
        logger.error("MySQL operation failed (%s): %s", error.errno, error.msg)
        if error.errno in {1146, 1305}:
            raise HTTPException(503, "Initialize the database schema and install the job CRUD procedures.") from error
        raise HTTPException(503, "The database operation failed. Check the database connection or backend logs.") from error
    finally:
        if connection is not None:
            # Closing an uncommitted connection rolls back any pending changes.
            connection.close()


def call_procedure(cursor, sql, values=()):
    cursor.execute(sql, values)
    rows = cursor.fetchall() if cursor.with_rows else []
    while cursor.nextset():
        if cursor.with_rows:
            cursor.fetchall()
    return rows
