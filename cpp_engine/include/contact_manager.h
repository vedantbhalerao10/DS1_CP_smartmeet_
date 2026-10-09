#ifndef CONTACT_MANAGER_H
#define CONTACT_MANAGER_H

#include "contact.h"
#include "trie.h"

#include <unordered_map>
#include <vector>
#include <string>

class ContactManager {
private:
    std::unordered_map<int, Contact> contacts;
    std::unordered_map<std::string, int> emailIndex;
    std::vector<int> contactOrder;
    std::unordered_map<std::string, std::vector<int>> categoryIndex;
    Trie nameTrie;

    int nextId;

    std::string normalize(const std::string& value);

public:
    ContactManager();

    int addContact(
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
    );

    void loadContact(const Contact& contact);

    bool getContact(int id, Contact& contact);

    bool updateContact(
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
    );

    bool deleteContact(int id);

    bool searchByEmail(
        const std::string& email,
        Contact& contact
    );

    std::vector<Contact> searchByName(
        const std::string& prefix
    );

    std::vector<Contact> getAllContacts();

    std::vector<Contact> getContactsByCategory(
    const std::string& category
);
};

#endif