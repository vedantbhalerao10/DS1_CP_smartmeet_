from fastapi import APIRouter, HTTPException
from pydantic import BaseModel
from .database import get_connection

router = APIRouter(prefix="/contacts", tags=["Contacts"])


class Contact(BaseModel):
    user_id: int
    first_name: str
    last_name: str = ""
    email: str = ""
    phone: str = ""
    company: str = ""
    job_title: str = ""
    category: str = ""
    favorite: bool = False
    notes: str = ""


@router.get("/")
def get_contacts(user_id: int = 1):
    connection = get_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute(
        "select * from contacts where user_id = %s order by id",
        (user_id,)
    )

    contacts = cursor.fetchall()

    cursor.close()
    connection.close()

    return contacts


@router.get("/{contact_id}")
def get_contact(contact_id: int):
    connection = get_connection()
    cursor = connection.cursor(dictionary=True)

    cursor.execute(
        "select * from contacts where id = %s",
        (contact_id,)
    )

    contact = cursor.fetchone()

    cursor.close()
    connection.close()

    if contact is None:
        raise HTTPException(
            status_code=404,
            detail="Contact not found"
        )

    return contact


@router.post("/")
def create_contact(contact: Contact):
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        insert into contacts
        (
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
        )
        values (%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)
        """,
        (
            contact.user_id,
            contact.first_name,
            contact.last_name,
            contact.email,
            contact.phone,
            contact.company,
            contact.job_title,
            contact.category,
            contact.favorite,
            contact.notes
        )
    )

    connection.commit()

    contact_id = cursor.lastrowid

    cursor.close()
    connection.close()

    return {
        "message": "Contact created",
        "id": contact_id
    }


@router.put("/{contact_id}")
def update_contact(
    contact_id: int,
    contact: Contact
):
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute(
        """
        update contacts
        set
            first_name = %s,
            last_name = %s,
            email = %s,
            phone = %s,
            company = %s,
            job_title = %s,
            category = %s,
            is_favorite = %s,
            notes = %s
        where id = %s
        """,
        (
            contact.first_name,
            contact.last_name,
            contact.email,
            contact.phone,
            contact.company,
            contact.job_title,
            contact.category,
            contact.favorite,
            contact.notes,
            contact_id
        )
    )

    connection.commit()

    if cursor.rowcount == 0:
        cursor.close()
        connection.close()

        raise HTTPException(
            status_code=404,
            detail="Contact not found"
        )

    cursor.close()
    connection.close()

    return {
        "message": "Contact updated"
    }


@router.delete("/{contact_id}")
def delete_contact(contact_id: int):
    connection = get_connection()
    cursor = connection.cursor()

    cursor.execute(
        "delete from contacts where id = %s",
        (contact_id,)
    )

    connection.commit()

    if cursor.rowcount == 0:
        cursor.close()
        connection.close()

        raise HTTPException(
            status_code=404,
            detail="Contact not found"
        )

    cursor.close()
    connection.close()

    return {
        "message": "Contact deleted"
    }


@router.get("/search/name")
def search_contacts(
    name: str,
    user_id: int = 1
):
    connection = get_connection()
    cursor = connection.cursor(dictionary=True)

    search = name + "%"

    cursor.execute(
        """
        select * from contacts
        where user_id = %s
        and (
            first_name like %s
            or last_name like %s
        )
        order by first_name
        """,
        (user_id, search, search)
    )

    contacts = cursor.fetchall()

    cursor.close()
    connection.close()

    return contacts