#include "../include/contact_manager.h"

#include <algorithm>
#include <cctype>

ContactManager::ContactManager() {
    nextId = 1;
}

void ContactManager::loadContact(
    const Contact& contact
) {
    contacts[contact.id] = contact;

    emailIndex[
        normalize(contact.email)
    ] = contact.id;

    contactOrder.push_back(
        contact.id
    );

    nameTrie.insert(
        normalize(contact.firstName),
        contact.id
    );

    categoryIndex[
         normalize(contact.category)
    ].push_back(
         contact.id
    );

    if (contact.id >= nextId) {
        nextId = contact.id + 1;
    }
}

std::string ContactManager::normalize(
    const std::string& value
) {
    std::string result = value;

    std::transform(
        result.begin(),
        result.end(),
        result.begin(),
        [](unsigned char ch) {
            return static_cast<char>(
                std::tolower(ch)
            );
        }
    );

    return result;
}

int ContactManager::addContact(
    int userId,
    const std::string& firstName,
    const std::string& lastName,
    const std::string& email,
    const std::string& phone,
    const std::string& company,
    const std::string& jobTitle,
    const std::string& category,
    bool favorite,
    const std::string& notes
) {
    std::string normalizedEmail =
        normalize(email);

    if (emailIndex.find(normalizedEmail) !=
        emailIndex.end()) {
        return -1;
    }

    Contact contact;

    contact.id = nextId++;
    contact.userId = userId;
    contact.firstName = firstName;
    contact.lastName = lastName;
    contact.email = email;
    contact.phone = phone;
    contact.company = company;
    contact.jobTitle = jobTitle;
    contact.category = category;
    contact.favorite = favorite;
    contact.notes = notes;

    contacts[contact.id] = contact;

    emailIndex[normalizedEmail] =
        contact.id;

    contactOrder.push_back(contact.id);

    nameTrie.insert(
        normalize(firstName),
        contact.id
    );

    return contact.id;
}

bool ContactManager::getContact(
    int id,
    Contact& contact
) {
    auto it = contacts.find(id);

    if (it == contacts.end()) {
        return false;
    }

    contact = it->second;

    return true;
}

bool ContactManager::updateContact(
    int id,
    const std::string& firstName,
    const std::string& lastName,
    const std::string& email,
    const std::string& phone,
    const std::string& company,
    const std::string& jobTitle,
    const std::string& category,
    bool favorite,
    const std::string& notes
) {
    auto it = contacts.find(id);

    if (it == contacts.end()) {
        return false;
    }

    std::string oldEmail =
        normalize(it->second.email);

    std::string newEmail =
        normalize(email);

    auto emailIt =
        emailIndex.find(newEmail);

    if (emailIt != emailIndex.end() &&
        emailIt->second != id) {
        return false;
    }

    nameTrie.remove(
        normalize(it->second.firstName),
        id
    );

    emailIndex.erase(oldEmail);

    it->second.firstName = firstName;
    it->second.lastName = lastName;
    it->second.email = email;
    it->second.phone = phone;
    it->second.company = company;
    it->second.jobTitle = jobTitle;
    it->second.category = category;
    it->second.favorite = favorite;
    it->second.notes = notes;

    emailIndex[newEmail] = id;

    nameTrie.insert(
        normalize(firstName),
        id
    );

    return true;
}

bool ContactManager::deleteContact(
    int id
) {
    auto it = contacts.find(id);

    if (it == contacts.end()) {
        return false;
    }

    nameTrie.remove(
        normalize(it->second.firstName),
        id
    );

    emailIndex.erase(
        normalize(it->second.email)
    );

    contacts.erase(it);

    contactOrder.erase(
        std::remove(
            contactOrder.begin(),
            contactOrder.end(),
            id
        ),
        contactOrder.end()
    );

    return true;
}

bool ContactManager::searchByEmail(
    const std::string& email,
    Contact& contact
) {
    std::string normalizedEmail =
        normalize(email);

    auto it =
        emailIndex.find(normalizedEmail);

    if (it == emailIndex.end()) {
        return false;
    }

    return getContact(
        it->second,
        contact
    );
}

std::vector<Contact>
ContactManager::searchByName(
    const std::string& prefix
) {
    std::vector<Contact> result;

    std::vector<int> ids =
        nameTrie.searchPrefix(
            normalize(prefix)
        );

    for (int id : ids) {
        Contact contact;

        if (getContact(id, contact)) {
            result.push_back(contact);
        }
    }

    return result;
}

std::vector<Contact>
ContactManager::getAllContacts() {
    std::vector<Contact> result;

    for (int id : contactOrder) {
        Contact contact;

        if (getContact(id, contact)) {
            result.push_back(contact);
        }
    }

    return result;
}
    std::vector<Contact> ContactManager::getContactsByCategory(
    const std::string& category
) {
    std::vector<Contact> results;

    std::string key = normalize(category);

    auto it = categoryIndex.find(key);

    if (it == categoryIndex.end() &&
        key == "friend") {
        it = categoryIndex.find("friends");
    }

    if (it == categoryIndex.end() &&
        key == "friends") {
        it = categoryIndex.find("friend");
    }

    if (it == categoryIndex.end()) {
        return results;
    }

    for (int id : it->second) {
        auto contactIt = contacts.find(id);

        if (contactIt != contacts.end()) {
            results.push_back(
                contactIt->second
            );
        }
    }

    return results;
}