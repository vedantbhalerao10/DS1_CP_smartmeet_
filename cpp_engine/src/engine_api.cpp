#include "../include/contact_manager.h"

#include <iostream>
#include <string>
#include <vector>

#include <nlohmann/json.hpp>

using json = nlohmann::json;

Contact contactFromJson(
    const json& data
) {
    Contact contact;

    contact.id = data["id"];
    contact.userId = data["user_id"];
    contact.firstName = data["first_name"];
    contact.lastName = data.value("last_name", "");
    contact.email = data.value("email", "");
    contact.phone = data.value("phone", "");
    contact.company = data.value("company", "");
    contact.jobTitle = data.value("job_title", "");
    contact.category = data.value("category", "");
    contact.favorite = data.value("is_favorite", 0) != 0;
    contact.notes = data.value("notes", "");

    return contact;
}

json contactToJson(
    const Contact& contact
) {
    return {
        {"id", contact.id},
        {"user_id", contact.userId},
        {"first_name", contact.firstName},
        {"last_name", contact.lastName},
        {"email", contact.email},
        {"phone", contact.phone},
        {"company", contact.company},
        {"job_title", contact.jobTitle},
        {"category", contact.category},
        {"is_favorite", contact.favorite},
        {"notes", contact.notes}
    };
}

int main() {
    try {
        std::string input(
            (std::istreambuf_iterator<char>(
                std::cin
            )),
            std::istreambuf_iterator<char>()
        );

        json request = json::parse(input);

        ContactManager manager;

        if (request.contains("contacts")) {
            for (const auto& item :
                 request["contacts"]) {

                Contact contact =
                    contactFromJson(item);

                manager.loadContact(contact);
            }
        }

        std::string operation =
            request.value(
                "operation",
                ""
            );

        if (operation == "search_name") {
            std::string prefix =
                request.value(
                    "prefix",
                    ""
                );

            std::vector<Contact> results =
                manager.searchByName(prefix);

            json output;

            output["success"] = true;
            output["results"] = json::array();

            for (const Contact& contact :
                 results) {
                output["results"].push_back(
                    contactToJson(contact)
                );
            }

            std::cout << output.dump();

            return 0;
        }

         if (operation == "search_category") {
             std::string category =
                request.value(
                  "category",
                  ""
                );

             std::vector<Contact> results =
                 manager.getContactsByCategory(
                    category
                 );

             json output;

             output["success"] = true;
             output["results"] = json::array();

             for (const Contact& contact :
                  results) {
                 output["results"].push_back(
                     contactToJson(contact)
                 );
             }

             std::cout << output.dump();

             return 0;
         }

        if (operation == "search_email") {
            std::string email =
                request.value(
                    "email",
                    ""
                );

            Contact contact;

            if (!manager.searchByEmail(
                email,
                contact
            )) {
                std::cout << json{
                    {"success", false},
                    {"message", "Contact not found"}
                }.dump();

                return 0;
            }

            std::cout << json{
                {"success", true},
                {"contact", contactToJson(contact)}
            }.dump();

            return 0;
        }

        std::cout << json{
            {"success", false},
            {"message", "Unknown operation"}
        }.dump();

        return 1;
    }
    catch (const std::exception& error) {
        std::cout << json{
            {"success", false},
            {"message", error.what()}
        }.dump();

        return 1;
    }
}