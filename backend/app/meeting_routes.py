
from datetime import date, time
from typing import Optional

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field, field_validator
from .database import get_connection


router = APIRouter(
    prefix="/meetings",
    tags=["Meetings"]
)


class Meeting(BaseModel):
    user_id: int = 1
    title: str = Field(default="Untitled Meeting", max_length=200)
    description: Optional[str] = None
    meeting_date: Optional[date] = None
    start_time: Optional[time] = None
    end_time: Optional[time] = None
    platform: str = "Other"
    meeting_link: Optional[str] = None
    location: Optional[str] = None
    organizer: Optional[str] = None
    participants: Optional[str] = None
    status: str = "Scheduled"

    @field_validator("title", mode="before")
    @classmethod
    def validate_title(cls, value):
        if value is None or not str(value).strip():
            return "Untitled Meeting"

        return str(value).strip()

    @field_validator(
        "meeting_date",
        "start_time",
        "end_time",
        mode="before"
    )
    @classmethod
    def empty_date_time_to_none(cls, value):
        if value is None:
            return None

        if isinstance(value, str) and not value.strip():
            return None

        return value


def check_meeting_conflict(
    cursor,
    meeting: Meeting,
    exclude_id: Optional[int] = None
):
    if (
        meeting.start_time is not None
        and meeting.end_time is not None
        and meeting.end_time <= meeting.start_time
    ):
        raise HTTPException(
            status_code=400,
            detail="End time must be later than start time."
        )

    if (
        meeting.meeting_date is None
        or meeting.start_time is None
        or meeting.end_time is None
    ):
        return

    query = """
        SELECT id, title, start_time, end_time
        FROM meetings
        WHERE user_id = %s
          AND meeting_date = %s
          AND status != 'Cancelled'
          AND start_time < %s
          AND end_time > %s
    """

    values = [
        meeting.user_id,
        meeting.meeting_date,
        meeting.end_time,
        meeting.start_time
    ]

    if exclude_id is not None:
        query += " AND id != %s"
        values.append(exclude_id)

    cursor.execute(query, tuple(values))

    conflicts = cursor.fetchall()

    if conflicts:
        conflict = conflicts[0]

        raise HTTPException(
            status_code=409,
            detail={
                "message": "This meeting overlaps with another meeting.",
                "conflicting_meeting": {
                    "id": conflict["id"],
                    "title": conflict["title"],
                    "start_time": str(conflict["start_time"]),
                    "end_time": str(conflict["end_time"])
                }
            }
        )


@router.get("/")
def get_meetings(user_id: int = 1):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT *
            FROM meetings
            WHERE user_id = %s
            ORDER BY meeting_date, start_time
            """,
            (user_id,)
        )

        return cursor.fetchall()

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.get("/search")
def search_meetings(
    title: str,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT *
            FROM meetings
            WHERE user_id = %s
              AND title LIKE %s
            ORDER BY meeting_date, start_time
            """,
            (user_id, "%" + title + "%")
        )

        return cursor.fetchall()

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.get("/{meeting_id}")
def get_meeting(
    meeting_id: int,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT *
            FROM meetings
            WHERE id = %s AND user_id = %s
            """,
            (meeting_id, user_id)
        )

        meeting = cursor.fetchone()

        if meeting is None:
            raise HTTPException(
                status_code=404,
                detail="Meeting not found."
            )

        return meeting

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.post("/")
def create_meeting(meeting: Meeting):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        check_meeting_conflict(cursor, meeting)

        cursor.execute(
            """
            INSERT INTO meetings (
                user_id,
                title,
                description,
                meeting_date,
                start_time,
                end_time,
                platform,
                meeting_link,
                location,
                organizer,
                participants,
                status
            )
            VALUES (
                %s, %s, %s, %s, %s, %s,
                %s, %s, %s, %s, %s, %s
            )
            """,
            (
                meeting.user_id,
                meeting.title,
                meeting.description,
                meeting.meeting_date,
                meeting.start_time,
                meeting.end_time,
                meeting.platform,
                meeting.meeting_link,
                meeting.location,
                meeting.organizer,
                meeting.participants,
                meeting.status
            )
        )

        connection.commit()

        return {
            "message": "Meeting created successfully.",
            "id": cursor.lastrowid
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.put("/{meeting_id}")
def update_meeting(
    meeting_id: int,
    meeting: Meeting
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor(dictionary=True)

        cursor.execute(
            """
            SELECT id
            FROM meetings
            WHERE id = %s AND user_id = %s
            """,
            (meeting_id, meeting.user_id)
        )

        existing = cursor.fetchone()

        if existing is None:
            raise HTTPException(
                status_code=404,
                detail="Meeting not found."
            )

        check_meeting_conflict(
            cursor,
            meeting,
            exclude_id=meeting_id
        )

        cursor.execute(
            """
            UPDATE meetings
            SET
                title = %s,
                description = %s,
                meeting_date = %s,
                start_time = %s,
                end_time = %s,
                platform = %s,
                meeting_link = %s,
                location = %s,
                organizer = %s,
                participants = %s,
                status = %s
            WHERE id = %s AND user_id = %s
            """,
            (
                meeting.title,
                meeting.description,
                meeting.meeting_date,
                meeting.start_time,
                meeting.end_time,
                meeting.platform,
                meeting.meeting_link,
                meeting.location,
                meeting.organizer,
                meeting.participants,
                meeting.status,
                meeting_id,
                meeting.user_id
            )
        )

        connection.commit()

        return {
            "message": "Meeting updated successfully."
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()


@router.delete("/{meeting_id}")
def delete_meeting(
    meeting_id: int,
    user_id: int = 1
):
    connection = get_connection()
    cursor = None

    try:
        cursor = connection.cursor()

        cursor.execute(
            """
            DELETE FROM meetings
            WHERE id = %s AND user_id = %s
            """,
            (meeting_id, user_id)
        )

        if cursor.rowcount == 0:
            raise HTTPException(
                status_code=404,
                detail="Meeting not found."
            )

        connection.commit()

        return {
            "message": "Meeting deleted successfully."
        }

    except Exception:
        connection.rollback()
        raise

    finally:
        if cursor is not None:
            cursor.close()

        connection.close()
