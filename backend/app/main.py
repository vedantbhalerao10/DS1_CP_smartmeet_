from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import get_connection
from .contact_routes import router as contact_router
import subprocess
import json

app = FastAPI(title="DS1CPSmartMeet API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
def home():
    return {
        "message": "DS1CPSmartMeet backend is running"
    }


@app.get("/db-test")
def database_test():
    connection = get_connection()

    cursor = connection.cursor()
    cursor.execute("select database()")

    result = cursor.fetchone()

    cursor.close()
    connection.close()

    return {
        "database": result[0]
    }


def get_contacts_from_database(user_id: int):
    connection = get_connection()

    cursor = connection.cursor(dictionary=True)

    cursor.execute(
        """
        select
            id,
            user_id,
            first_name,
            last_name,
            email,
            phone,
            company,
            job_title,
            category,
            is_favorite,
            notes
        from contacts
        where user_id = %s
        order by id
        """,
        (user_id,)
    )

    contacts = cursor.fetchall()

    cursor.close()
    connection.close()

    return contacts


def run_cpp_engine(request):
    engine_path = (
        r"C:\Users\vedan\OneDrive\Desktop"
        r"\ds1cpsmartmeet\cpp_engine"
        r"\build\Debug\smartmeet_engine_api.exe"
    )

    process = subprocess.run(
        [engine_path],
        input=json.dumps(request),
        text=True,
        capture_output=True
    )

    if process.returncode != 0:
        raise RuntimeError(
            process.stderr or process.stdout
        )

    return json.loads(process.stdout)


@app.get("/contacts/cpp-search")
def cpp_contact_search(
    name: str,
    user_id: int = 1
):
    contacts = get_contacts_from_database(
        user_id
    )

@app.get("/contacts/cpp-category")
def cpp_category_search(
    category: str,
    user_id: int = 1
):
    contacts = get_contacts_from_database(
        user_id
    )

    request = {
        "operation": "search_category",
        "category": category,
        "contacts": contacts
    }

    return run_cpp_engine(request)

    request = {
        "operation": "search_name",
        "prefix": name,
        "contacts": contacts
    }

    return run_cpp_engine(request)

app.include_router(contact_router)
