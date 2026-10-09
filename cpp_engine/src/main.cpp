#include "../include/contact_manager.h"

#include <iostream>
#include <vector>

void printContact(
    const Contact& contact
) {
    std::cout << contact.id
              << " | "
              << contact.firstName
              << " "
              << contact.lastName
              << " | "
              << contact.email
              << "\n";
}

int main() {
    ContactManager manager;

    Contact c1;

    c1.id = 1;
    c1.userId = 1;
    c1.firstName = "Rahul";
    c1.lastName = "Sharma";
    c1.email = "rahul@gmail.com";
    c1.phone = "9876543210";
    c1.company = "ABC Technologies";
    c1.jobTitle = "Software Engineer";
    c1.category = "Work";
    c1.favorite = true;
    c1.notes = "Project teammate";

    Contact c2;

    c2.id = 2;
    c2.userId = 1;
    c2.firstName = "Priya";
    c2.lastName = "Patil";
    c2.email = "priya@gmail.com";
    c2.phone = "9876501234";
    c2.company = "XYZ Solutions";
    c2.jobTitle = "Product Manager";
    c2.category = "Work";
    c2.favorite = false;
    c2.notes = "Meeting contact";

    Contact c3;

    c3.id = 3;
    c3.userId = 1;
    c3.firstName = "Amit";
    c3.lastName = "Joshi";
    c3.email = "amit@gmail.com";
    c3.phone = "9823456789";
    c3.company = "Tech Systems";
    c3.jobTitle = "Developer";
    c3.category = "Friends";
    c3.favorite = true;
    c3.notes = "College friend";

    Contact c4;

    c4.id = 4;
    c4.userId = 1;
    c4.firstName = "Sneha";
    c4.lastName = "Kulkarni";
    c4.email = "sneha@gmail.com";
    c4.phone = "9876543211";
    c4.company = "Infosys";
    c4.jobTitle = "Software Developer";
    c4.category = "Work";
    c4.favorite = true;
    c4.notes = "Project contact";

    manager.loadContact(c1);
    manager.loadContact(c2);
    manager.loadContact(c3);
    manager.loadContact(c4);

    std::cout << "LOADED CONTACTS\n";
    std::cout << "==========================\n";

    std::vector<Contact> contacts =
        manager.getAllContacts();

    for (const Contact& contact : contacts) {
        printContact(contact);
    }

    std::cout << "\nEMAIL SEARCH\n";
    std::cout << "==========================\n";

    Contact found;

    if (manager.searchByEmail(
        "sneha@gmail.com",
        found
    )) {
        printContact(found);
    }

    std::cout << "\nTRIE PREFIX SEARCH: 'Pr'\n";
    std::cout << "==========================\n";

    std::vector<Contact> results =
        manager.searchByName("Pr");

    for (const Contact& contact : results) {
        printContact(contact);
    }

    return 0;
}