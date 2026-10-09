#ifndef CONTACT_H
#define CONTACT_H

#include <string>

struct Contact {
    int id;
    int userId;
    std::string firstName;
    std::string lastName;
    std::string email;
    std::string phone;
    std::string company;
    std::string jobTitle;
    std::string category;
    bool favorite;
    std::string notes;
};

#endif