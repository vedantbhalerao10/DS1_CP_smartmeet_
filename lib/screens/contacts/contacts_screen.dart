import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<dynamic> contacts = [];
  bool loading = true;
  String error = '';
  String selectedCategory = 'All';

  final TextEditingController searchController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  Future<void> loadContacts() async {
    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result = await ApiService.getContacts();

      setState(() {
        contacts = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not load contacts';
        loading = false;
      });
    }
  }

  Future<void> searchContacts(String value) async {
    if (value.trim().isEmpty) {
      await loadContacts();
      return;
    }

    setState(() {
      loading = true;
      error = '';
    });

    try {
      final result =
          await ApiService.searchContacts(value.trim());

      setState(() {
        contacts = result;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = 'Could not search contacts';
        loading = false;
      });
    }
  }
    
   
  Future<void> searchByCategory(String category) async {
  setState(() {
    selectedCategory = category;
  });

  if (category == 'All') {
    await loadContacts();
    return;
  }

  try {
    final results =
        await ApiService.searchContactsByCategory(category);

    setState(() {
      contacts = results;
    });
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load contacts by category'),
        ),
      );
    }
  }
}

  void showAddContactDialog() {
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final companyController = TextEditingController();
    final jobTitleController = TextEditingController();
    final categoryController = TextEditingController();
    final notesController = TextEditingController();

    bool favorite = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Contact'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                      ),
                      TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                        ),
                      ),
                      TextField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company',
                        ),
                      ),
                      TextField(
                        controller: jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Title',
                        ),
                      ),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                        ),
                        maxLines: 3,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Favorite'),
                        value: favorite,
                        onChanged: (value) {
                          setDialogState(() {
                            favorite = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (firstNameController.text.trim().isEmpty) {
                      return;
                    }

                    try {
                      await ApiService.createContact(
                        firstName:
                            firstNameController.text.trim(),
                        lastName:
                            lastNameController.text.trim(),
                        email:
                            emailController.text.trim(),
                        phone:
                            phoneController.text.trim(),
                        company:
                            companyController.text.trim(),
                        jobTitle:
                            jobTitleController.text.trim(),
                        category:
                            categoryController.text.trim(),
                        favorite: favorite,
                        notes:
                            notesController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      await loadContacts();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                                Text('Failed to create contact'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

    Future<void> deleteContact(
    Map<String, dynamic> contact,
  ) async {
    final firstName = contact['first_name'] ?? '';
    final lastName = contact['last_name'] ?? '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text(
            'Are you sure you want to delete $firstName $lastName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await ApiService.deleteContact(contact['id']);

      await loadContacts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Contact deleted'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete contact'),
          ),
        );
      }
    }
  }

  void showEditContactDialog(
    Map<String, dynamic> contact,
  ) {
    final firstNameController =
        TextEditingController(
      text: contact['first_name'] ?? '',
    );

    final lastNameController =
        TextEditingController(
      text: contact['last_name'] ?? '',
    );

    final emailController =
        TextEditingController(
      text: contact['email'] ?? '',
    );

    final phoneController =
        TextEditingController(
      text: contact['phone'] ?? '',
    );

    final companyController =
        TextEditingController(
      text: contact['company'] ?? '',
    );

    final jobTitleController =
        TextEditingController(
      text: contact['job_title'] ?? '',
    );

    final categoryController =
        TextEditingController(
      text: contact['category'] ?? '',
    );

    final notesController =
        TextEditingController(
      text: contact['notes'] ?? '',
    );

    bool favorite =
        contact['is_favorite'] == true ||
        contact['is_favorite'] == 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Contact'),
              content: SizedBox(
                width: 450,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration: const InputDecoration(
                          labelText: 'First Name',
                        ),
                      ),
                      TextField(
                        controller: lastNameController,
                        decoration: const InputDecoration(
                          labelText: 'Last Name',
                        ),
                      ),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                        ),
                      ),
                      TextField(
                        controller: companyController,
                        decoration: const InputDecoration(
                          labelText: 'Company',
                        ),
                      ),
                      TextField(
                        controller: jobTitleController,
                        decoration: const InputDecoration(
                          labelText: 'Job Title',
                        ),
                      ),
                      TextField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                      ),
                      TextField(
                        controller: notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                        ),
                        maxLines: 3,
                      ),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Favorite'),
                        value: favorite,
                        onChanged: (value) {
                          setDialogState(() {
                            favorite = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (firstNameController.text.trim().isEmpty) {
                      return;
                    }

                    try {
                      await ApiService.updateContact(
                        id: contact['id'],
                        firstName:
                            firstNameController.text.trim(),
                        lastName:
                            lastNameController.text.trim(),
                        email:
                            emailController.text.trim(),
                        phone:
                            phoneController.text.trim(),
                        company:
                            companyController.text.trim(),
                        jobTitle:
                            jobTitleController.text.trim(),
                        category:
                            categoryController.text.trim(),
                        favorite: favorite,
                        notes:
                            notesController.text.trim(),
                      );

                      if (context.mounted) {
                        Navigator.pop(context);
                      }

                      await loadContacts();
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content:
                                Text('Failed to update contact'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            onPressed: showAddContactDialog,
            icon: const Icon(Icons.person_add),
            tooltip: 'Add Contact',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    searchController.clear();
                    loadContacts();
                  },
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: searchContacts,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : error.isNotEmpty
                      ? Center(
                          child: Text(error),
                        )
                      : contacts.isEmpty
                          ? const Center(
                              child: Text('No contacts found'),
                            )
                          : ListView.builder(
                              itemCount: contacts.length,
                              itemBuilder: (context, index) {
                                final contact =
                                    Map<String, dynamic>.from(
                                  contacts[index],
                                );

                                final firstName =
                                    contact['first_name'] ?? '';

                                final lastName =
                                    contact['last_name'] ?? '';

                                final email =
                                    contact['email'] ?? '';

                                final company =
                                    contact['company'] ?? '';

                                final favorite =
                                    contact['is_favorite'] ==
                                        true ||
                                    contact['is_favorite'] == 1;

                                return Card(
                                  margin:
                                      const EdgeInsets.only(
                                    bottom: 12,
                                  ),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        firstName.isNotEmpty
                                            ? firstName[0]
                                                .toUpperCase()
                                            : '?',
                                      ),
                                    ),
                                    title: Text(
                                      '$firstName $lastName',
                                    ),
                                    subtitle: Text(
                                      company.isNotEmpty
                                          ? '$email\n$company'
                                          : email,
                                    ),
                                    isThreeLine:
                                        company.isNotEmpty,
                                    trailing: Row(
                                      mainAxisSize:
                                          MainAxisSize.min,
                                      children: [
                                        if (favorite)
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                          ),
                                        IconButton(
                                          onPressed: () {
                                            showEditContactDialog(
                                              contact,
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.edit,
                                          ),
                                          tooltip: 'Edit',
                                        ),
                                        IconButton(
                                          onPressed: () {
                                            deleteContact(contact);
                                          },
                                          icon: const Icon(
                                            Icons.delete_outline,
                                          ),
                                          tooltip: 'Delete',
                                        
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}