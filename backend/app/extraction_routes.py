
import re
from datetime import datetime, timedelta

import dateparser
from fastapi import APIRouter
from pydantic import BaseModel, Field


router = APIRouter(
    prefix="/extraction",
    tags=["Meeting Extraction"]
)


class ExtractionRequest(BaseModel):
    text: str = Field(min_length=5, max_length=20000)


def clean_value(value):
    if not value:
        return None

    value = re.sub(r"\s+", " ", value).strip()
    return value.strip(" \t\r\n\"'*")


def extract_field(text, labels):
    for label in labels:
        pattern = (
            rf"(?im)^\s*{re.escape(label)}\s*:\s*(.*?)\s*$"
        )

        match = re.search(pattern, text)

        if match and match.group(1).strip():
            return match.group(1).strip()

    return None


def extract_link(text):
    pattern = r"https?://[^\s<>\"']+"
    matches = re.findall(pattern, text, re.IGNORECASE)

    if not matches:
        return None

    return matches[0].rstrip(".,;:!?)']}")


def extract_platform(text, link):
    content = (text + " " + (link or "")).lower()

    if "meet.google.com" in content or "google meet" in content:
        return "Google Meet"

    if (
        "teams.microsoft.com" in content
        or "microsoft teams" in content
    ):
        return "Microsoft Teams"

    if "zoom.us" in content or "zoom meeting" in content:
        return "Zoom"

    if "webex.com" in content or "cisco webex" in content:
        return "Cisco Webex"

    value = extract_field(text, ["platform"])

    if value:
        return clean_value(value)

    return "Other"


def convert_time(hour, minute=0, period=None):
    hour = int(hour)
    minute = int(minute)

    if minute < 0 or minute > 59:
        return None

    if period:
        period = period.upper()

        if hour < 1 or hour > 12:
            return None

        if period == "PM" and hour != 12:
            hour += 12
        elif period == "AM" and hour == 12:
            hour = 0

    elif hour < 0 or hour > 23:
        return None

    return f"{hour:02d}:{minute:02d}:00"


def extract_time_range(text):
    pattern = (
        r"(?<!\d)"
        r"(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?"
        r"\s*(?:-|–|—|\bto\b|\buntil\b|\btill\b)\s*"
        r"(\d{1,2})(?::(\d{2}))?\s*(AM|PM)?"
        r"(?!\d)"
    )

    for match in re.finditer(pattern, text, re.IGNORECASE):
        start_hour = int(match.group(1))
        start_minute = int(match.group(2) or 0)
        start_period = match.group(3)

        end_hour = int(match.group(4))
        end_minute = int(match.group(5) or 0)
        end_period = match.group(6)

        if not (
            match.group(2)
            or match.group(5)
            or start_period
            or end_period
        ):
            continue

        if start_period and not end_period:
            end_period = start_period
        elif end_period and not start_period:
            start_period = end_period

        start_time = convert_time(
            start_hour,
            start_minute,
            start_period
        )

        end_time = convert_time(
            end_hour,
            end_minute,
            end_period
        )

        if not start_time or not end_time:
            continue

        start_minutes = (
            int(start_time[:2]) * 60
            + int(start_time[3:5])
        )

        end_minutes = (
            int(end_time[:2]) * 60
            + int(end_time[3:5])
        )

        if end_minutes <= start_minutes:
            continue

        return start_time, end_time

    return None, None


def extract_time(text):
    start_time, end_time = extract_time_range(text)

    if start_time:
        return start_time

    normalized = re.sub(
        r"(\d{1,2})(?::(\d{2}))?\s*(AM|PM)(?=TODAY\b)",
        lambda m: (
            f"{m.group(1)}:{m.group(2) or '00'} "
            f"{m.group(3)} "
        ),
        text,
        flags=re.IGNORECASE
    )

    pattern_12 = (
        r"\b(\d{1,2})(?::(\d{2}))?\s*(AM|PM)\b"
    )

    match = re.search(pattern_12, normalized, re.IGNORECASE)

    if match:
        return convert_time(
            match.group(1),
            match.group(2) or 0,
            match.group(3)
        )

    pattern_24 = r"\b([01]?\d|2[0-3]):([0-5]\d)\b"

    match = re.search(pattern_24, normalized)

    if match:
        return convert_time(
            match.group(1),
            match.group(2)
        )

    return None


def extract_end_time(text, start_time=None):
    labeled = extract_field(
        text,
        ["end time", "ends at", "ending time"]
    )

    if labeled:
        match = re.search(
            r"\b(\d{1,2})(?::(\d{2}))?\s*(AM|PM)\b",
            labeled,
            re.IGNORECASE
        )

        if match:
            return convert_time(
                match.group(1),
                match.group(2) or 0,
                match.group(3)
            )

        match = re.search(
            r"\b([01]?\d|2[0-3]):([0-5]\d)\b",
            labeled
        )

        if match:
            return convert_time(
                match.group(1),
                match.group(2)
            )

    _, end_time = extract_time_range(text)

    return end_time


def extract_date(text):
    today = datetime.now().date()

    explicit_patterns = [
        r"\b\d{4}-\d{1,2}-\d{1,2}\b",
        r"\b\d{1,2}[/-]\d{1,2}[/-]\d{4}\b",
        (
            r"\b(?:January|February|March|April|May|June|July|"
            r"August|September|October|November|December|"
            r"Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)"
            r"\s+\d{1,2}(?:st|nd|rd|th)?[,]?\s+\d{4}\b"
        ),
        (
            r"\b\d{1,2}(?:st|nd|rd|th)?\s+(?:of\s+)?"
            r"(?:January|February|March|April|May|June|July|"
            r"August|September|October|November|December|"
            r"Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)"
            r"[,]?\s+\d{4}\b"
        )
    ]

    for pattern in explicit_patterns:
        match = re.search(pattern, text, re.IGNORECASE)

        if not match:
            continue

        parsed = dateparser.parse(
            match.group(),
            settings={
                "DATE_ORDER": "DMY",
                "PREFER_DATES_FROM": "current_period"
            }
        )

        if parsed:
            return parsed.date().isoformat()

    month_pattern = (
        r"\b(?:(Monday|Tuesday|Wednesday|Thursday|Friday|"
        r"Saturday|Sunday),?\s+)?"
        r"(January|February|March|April|May|June|July|August|"
        r"September|October|November|December|"
        r"Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Sept|Oct|Nov|Dec)"
        r"\s+(\d{1,2})(?:st|nd|rd|th)?\b"
    )

    match = re.search(month_pattern, text, re.IGNORECASE)

    if match:
        weekday = match.group(1)
        month = match.group(2)
        day = int(match.group(3))

        month_date = dateparser.parse(
            month,
            settings={"PREFER_DATES_FROM": "current_period"}
        )

        if not month_date:
            return None

        month_number = month_date.month

        weekday_numbers = {
            "monday": 0,
            "tuesday": 1,
            "wednesday": 2,
            "thursday": 3,
            "friday": 4,
            "saturday": 5,
            "sunday": 6
        }

        candidates = []

        for year in range(today.year - 2, today.year + 3):
            try:
                candidate = datetime(
                    year,
                    month_number,
                    day
                ).date()
            except ValueError:
                continue

            if weekday:
                if candidate.weekday() != weekday_numbers[
                    weekday.lower()
                ]:
                    continue

            candidates.append(candidate)

        if candidates:
            if weekday:
                future_candidates = [
                    candidate for candidate in candidates
                    if candidate >= today
                ]

                if future_candidates:
                    return min(future_candidates).isoformat()

            return min(
                candidates,
                key=lambda candidate: abs(
                    (candidate - today).days
                )
            ).isoformat()

    relative = re.search(
        r"\b(today|tomorrow|day after tomorrow)\b",
        text,
        re.IGNORECASE
    )

    if relative:
        word = relative.group(1).lower()

        if word == "today":
            return today.isoformat()

        if word == "tomorrow":
            return (today + timedelta(days=1)).isoformat()

        return (today + timedelta(days=2)).isoformat()

    return None


def extract_title(text):
    explicit = extract_field(
        text,
        ["meeting title", "subject", "title", "topic"]
    )

    if explicit:
        title = clean_value(explicit)

        title = re.sub(
            r"^(?:re|fw|fwd)\s*:\s*",
            "",
            title,
            flags=re.IGNORECASE
        )

        if title and len(title) <= 200:
            return title

    lines = [
        re.sub(r"\s+", " ", line).strip()
        for line in text.splitlines()
        if line.strip()
    ]

    ignored = [
        r"^(hi|hello|dear|good morning|good afternoon)\b",
        r"^(join us|please join|looking forward)\b",
        (
            r"^(date|time|start time|end time|location|venue|"
            r"platform|meeting link|zoom link|organizer|host|"
            r"participants|attendees|invitees|passcode|password|"
            r"time zone|video call link)\s*:"
        ),
        r"^(agenda|regards|thanks|thank you|best regards)\s*:?\s*$",
        r"^(google meet joining info|meeting chat link|online mode)$",
        r"^https?://",
        r"^www\.",
        r"^or dial\b",
        r"^meeting id\s*:",
        r"^for\s+sy\s+students\b",
        r"^\d+[.)]\s"
    ]

    for line in lines:
        if any(
            re.search(pattern, line, re.IGNORECASE)
            for pattern in ignored
        ):
            continue

        if re.search(
            r"\b(?:Monday|Tuesday|Wednesday|Thursday|Friday|"
            r"Saturday|Sunday),?\s+(?:January|February|March|"
            r"April|May|June|July|August|September|October|"
            r"November|December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|"
            r"Sep|Sept|Oct|Nov|Dec)\b",
            line,
            re.IGNORECASE
        ):
            continue

        if re.match(
            r"^\d{1,2}\s+(?:January|February|March|April|May|"
            r"June|July|August|September|October|November|"
            r"December|Jan|Feb|Mar|Apr|Jun|Jul|Aug|Sep|Oct|Nov|Dec)",
            line,
            re.IGNORECASE
        ):
            continue

        if re.search(r"\bhttps?://|www\.", line, re.IGNORECASE):
            continue

        line = re.sub(
            r"\s*[·|]\s*\d{1,2}(?::\d{2})?\s*(?:AM|PM)\b.*$",
            "",
            line,
            flags=re.IGNORECASE
        ).strip()

        line = re.sub(
            r"\s+\d{1,2}(?::\d{2})?\s*(?:AM|PM)\s+on\s*$",
            "",
            line,
            flags=re.IGNORECASE
        ).strip()

        line = re.sub(
            r"\s+at\s+\d{1,2}(?::\d{2})?\s*(?:AM|PM)\b.*$",
            "",
            line,
            flags=re.IGNORECASE
        ).strip()

        line = clean_value(line)

        if not line or len(line) > 200:
            continue

        if line.lower() in {
            "google meet",
            "zoom",
            "microsoft teams",
            "cisco webex"
        }:
            continue

        return line

    return None


def extract_organizer(text):
    value = extract_field(
        text,
        ["organizer", "host", "hosted by", "organized by"]
    )

    if value:
        return clean_value(value)

    patterns = [
        r"\bhosted\s+by\s+([^\n,;]+)",
        r"\borganized\s+by\s+([^\n,;]+)"
    ]

    for pattern in patterns:
        match = re.search(pattern, text, re.IGNORECASE)

        if match:
            return clean_value(match.group(1))[:150]

    return None


def extract_location(text):
    value = extract_field(
        text,
        ["location", "venue", "meeting location"]
    )

    if value:
        return clean_value(value)

    if re.search(r"\bonline mode\b|\bonline\b", text, re.IGNORECASE):
        return "Online"

    return None


def extract_participants(text):
    value = extract_field(
        text,
        ["participants", "attendees", "invitees"]
    )

    if not value:
        return []

    return [
        clean_value(person)
        for person in re.split(r"[,;\n]+", value)
        if clean_value(person)
    ]


def extract_agenda(text):
    agenda = []
    inside_agenda = False

    stop_patterns = [
        r"^\s*(regards|best regards|kind regards|thanks|thank you)\b",
        (
            r"^\s*(organizer|host|participants|attendees|invitees|"
            r"location|venue|platform|meeting link|zoom link|passcode)\s*:"
        ),
        r"^\s*(please join|looking forward)\b"
    ]

    for line in text.splitlines():
        line = line.strip()

        if not line:
            continue

        if re.match(r"^agenda\s*:?\s*$", line, re.IGNORECASE):
            inside_agenda = True
            continue

        if not inside_agenda:
            continue

        if any(
            re.search(pattern, line, re.IGNORECASE)
            for pattern in stop_patterns
        ):
            break

        item = re.sub(
            r"^\s*(?:[-*•]|\d+[.)])\s*",
            "",
            line
        ).strip()

        if item and not re.match(r"^https?://", item):
            agenda.append(item)

    return agenda


@router.post("/extract")
def extract_meeting(request: ExtractionRequest):
    text = request.text.strip()

    link = extract_link(text)
    platform = extract_platform(text, link)

    meeting_date = extract_date(text)

    start_time, range_end_time = extract_time_range(text)

    if not start_time:
        start_time = extract_time(text)

    end_time = extract_end_time(text, start_time)

    if not end_time:
        end_time = range_end_time

    title = extract_title(text)
    organizer = extract_organizer(text)
    location = extract_location(text)
    participants = extract_participants(text)
    agenda = extract_agenda(text)

    missing_fields = []

    if not title:
        missing_fields.append("title")

    if not meeting_date:
        missing_fields.append("meeting_date")

    if not start_time:
        missing_fields.append("start_time")

    if not end_time:
        missing_fields.append("end_time")

    if not link:
        missing_fields.append("meeting_link")

    if not location:
        missing_fields.append("location")

    return {
        "title": title,
        "meeting_date": meeting_date,
        "start_time": start_time,
        "end_time": end_time,
        "platform": platform,
        "meeting_link": link,
        "location": location,
        "organizer": organizer,
        "participants": participants,
        "agenda": agenda,
        "missing_fields": missing_fields,
        "status": "needs_confirmation"
    }
