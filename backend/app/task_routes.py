from datetime import date, time
from typing import Optional, Literal

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, field_validator

from .database import get_connection


router = APIRouter(
    prefix="/tasks",
    tags=["Tasks"]
)


class TaskCreate(BaseModel):
    user_id: int = 1
    meeting_id: Optional[int] = None
    title: str = Field(min_length=1, max_length=200)
    description: Optional[str] = None
    priority: Literal["Low", "Medium", "High", "Urgent"] = "Medium"
    due_date: Optional[date] = None
    due_time: Optional[time] = None
    status: Literal["Pending", "Completed"] = "Pending"

    @field_validator("title", mode="before")
    @classmethod
    def validate_title(cls, value):
        if value is None or not str(value).strip():
            raise ValueError("Task title cannot be empty.")

        return str(value).strip()


@router.get("/")
def get_tasks(
    user_id: int = 1,
    status: Optional[Literal["Pending", "Completed"]] = None,
    priority: Optional[Literal["Low", "Medium", "High", "Urgent"]] = None,
    search: Optional[str] = None
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        query = """
            SELECT *
            FROM tasks
            WHERE user_id = %s
        """

        values = [user_id]

        if status:
            query += " AND status = %s"
            values.append(status)

        if priority:
            query += " AND priority = %s"
            values.append(priority)

        if search and search.strip():
            query += " AND (title LIKE %s OR description LIKE %s)"
            search_value = "%" + search.strip() + "%"
            values.extend([search_value, search_value])

        query += """
            ORDER BY
                CASE status
                    WHEN 'Pending' THEN 0
                    ELSE 1
                END,
                CASE priority
                    WHEN 'Urgent' THEN 0
                    WHEN 'High' THEN 1
                    WHEN 'Medium' THEN 2
                    ELSE 3
                END,
                due_date IS NULL,
                due_date,
                due_time
        """

        cursor.execute(query, tuple(values))

        return cursor.fetchall()

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.get("/{task_id}")
def get_task(
    task_id: int,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT *
            FROM tasks
            WHERE id = %s AND user_id = %s
            """,
            (task_id, user_id)
        )

        task = cursor.fetchone()

        if task is None:
            raise HTTPException(
                status_code=404,
                detail="Task not found."
            )

        return task

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.post("/")
def create_task(task: TaskCreate):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        if task.meeting_id is not None:
            cursor.execute(
                """
                SELECT id
                FROM meetings
                WHERE id = %s AND user_id = %s
                """,
                (task.meeting_id, task.user_id)
            )

            if cursor.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail="Meeting not found for this user."
                )

        cursor.execute(
            """
            INSERT INTO tasks (
                user_id,
                meeting_id,
                title,
                description,
                priority,
                due_date,
                due_time,
                status
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                task.user_id,
                task.meeting_id,
                task.title,
                task.description,
                task.priority,
                task.due_date,
                task.due_time,
                task.status
            )
        )

        task_id = cursor.lastrowid
        connection.commit()

        return {
            "message": "Task created successfully.",
            "id": task_id
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.put("/{task_id}")
def update_task(
    task_id: int,
    task: TaskCreate
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT id
            FROM tasks
            WHERE id = %s AND user_id = %s
            """,
            (task_id, task.user_id)
        )

        if cursor.fetchone() is None:
            raise HTTPException(
                status_code=404,
                detail="Task not found."
            )

        if task.meeting_id is not None:
            cursor.execute(
                """
                SELECT id
                FROM meetings
                WHERE id = %s AND user_id = %s
                """,
                (task.meeting_id, task.user_id)
            )

            if cursor.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail="Meeting not found for this user."
                )

        cursor.execute(
            """
            UPDATE tasks
            SET
                meeting_id = %s,
                title = %s,
                description = %s,
                priority = %s,
                due_date = %s,
                due_time = %s,
                status = %s
            WHERE id = %s AND user_id = %s
            """,
            (
                task.meeting_id,
                task.title,
                task.description,
                task.priority,
                task.due_date,
                task.due_time,
                task.status,
                task_id,
                task.user_id
            )
        )

        connection.commit()

        return {
            "message": "Task updated successfully."
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.patch("/{task_id}/complete")
def complete_task(
    task_id: int,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE tasks
            SET status = 'Completed'
            WHERE id = %s AND user_id = %s
            """,
            (task_id, user_id)
        )

        if cursor.rowcount == 0:
            cursor.execute(
                """
                SELECT id
                FROM tasks
                WHERE id = %s AND user_id = %s
                """,
                (task_id, user_id)
            )

            if cursor.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail="Task not found."
                )

        connection.commit()

        return {
            "message": "Task marked as completed."
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.patch("/{task_id}/pending")
def reopen_task(
    task_id: int,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            UPDATE tasks
            SET status = 'Pending'
            WHERE id = %s AND user_id = %s
            """,
            (task_id, user_id)
        )

        if cursor.rowcount == 0:
            cursor.execute(
                """
                SELECT id
                FROM tasks
                WHERE id = %s AND user_id = %s
                """,
                (task_id, user_id)
            )

            if cursor.fetchone() is None:
                raise HTTPException(
                    status_code=404,
                    detail="Task not found."
                )

        connection.commit()

        return {
            "message": "Task marked as pending."
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.delete("/{task_id}")
def delete_task(
    task_id: int,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            DELETE FROM tasks
            WHERE id = %s AND user_id = %s
            """,
            (task_id, user_id)
        )

        if cursor.rowcount == 0:
            raise HTTPException(
                status_code=404,
                detail="Task not found."
            )

        connection.commit()

        return {
            "message": "Task deleted successfully."
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()