
import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<dynamic> contacts = [];
  List<dynamic> allContacts = [];

  bool isLoading = true;
  String selectedCategory = 'All';

  final TextEditingController searchController = TextEditingController();

  final List<String> categories = [
    'All',
    'Friend',
    'Company Colleague',
    'Student',
    'Family',
    'Organization',
  ];

  @override
  void initState() {
    super.initState();
    loadContacts();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  String getValue(dynamic contact, String key) {
    if (contact is! Map) return '';

    final value = contact[key];
    return value == null ? '' : value.toString();
  }

  int getId(dynamic contact) {
    final value = contact['id'];

    if (value is int) return value;

    return int.tryParse(value.toString()) ?? 0;
  }

  bool getFavorite(dynamic contact) {
    final value = contact['is_favorite'];

    return value == true || value == 1 || value == '1';
  }

  String getFullName(dynamic contact) {
    final firstName = getValue(contact, 'first_name').trim();
    final lastName = getValue(contact, 'last_name').trim();

    return '$firstName $lastName'.trim();
  }

  void showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> loadContacts() async {
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });

    try {
      final result = await ApiService.getContacts();

      if (!mounted) return;

      setState(() {
        allContacts = result;
      });

      applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Failed to load contacts: $e');
    }
  }

  void applyFilters() {
    if (!mounted) return;

    final query = searchController.text.trim().toLowerCase();

    final filteredContacts = allContacts.where((contact) {
      final firstName =
          getValue(contact, 'first_name').toLowerCase();

      final lastName =
          getValue(contact, 'last_name').toLowerCase();

      final fullName = getFullName(contact).toLowerCase();

      final phone =
          getValue(contact, 'phone').toLowerCase();

      final email =
          getValue(contact, 'email').toLowerCase();

      final company =
          getValue(contact, 'company').toLowerCase();

      final category =
          getValue(contact, 'category').toLowerCase();

      final matchesSearch = query.isEmpty ||
          firstName.contains(query) ||
          lastName.contains(query) ||
          fullName.contains(query) ||
          phone.contains(query) ||
          email.contains(query) ||
          company.contains(query);

      final matchesCategory = selectedCategory == 'All' ||
          category == selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();

    setState(() {
      contacts = filteredContacts;
      isLoading = false;
    });
  }

  Future<void> searchContacts(String query) async {
    applyFilters();
  }

  Future<void> searchByCategory(String category) async {
    setState(() {
      selectedCategory = category;
      isLoading = true;
    });

    try {
      final result = await ApiService.getContacts();

      if (!mounted) return;

      allContacts = result;
      applyFilters();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showMessage('Failed to filter contacts: $e');
    }
  }

  Future<void> showContactDialog({dynamic contact}) async {
    final bool isEditing = contact != null;
    final formKey = GlobalKey<FormState>();

    final firstNameController = TextEditingController(
      text: isEditing ? getValue(contact, 'first_name') : '',
    );

    final lastNameController = TextEditingController(
      text: isEditing ? getValue(contact, 'last_name') : '',
    );

    final emailController = TextEditingController(
      text: isEditing ? getValue(contact, 'email') : '',
    );

    final phoneController = TextEditingController(
      text: isEditing ? getValue(contact, 'phone') : '',
    );

    final companyController = TextEditingController(
      text: isEditing ? getValue(contact, 'company') : '',
    );

    final jobTitleController = TextEditingController(
      text: isEditing ? getValue(contact, 'job_title') : '',
    );

    final notesController = TextEditingController(
      text: isEditing ? getValue(contact, 'notes') : '',
    );

    String selectedContactCategory =
        isEditing ? getValue(contact, 'category') : 'Friend';

    if (!categories.contains(selectedContactCategory) ||
        selectedContactCategory == 'All') {
      selectedContactCategory = 'Friend';
    }

    bool favorite = isEditing ? getFavorite(contact) : false;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Edit Contact' : 'Add Contact',
              ),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: firstNameController,
                          decoration: const InputDecoration(
                            labelText: 'First Name *',
                            prefixIcon: Icon(Icons.person),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null ||
                                value.trim().isEmpty) {
                              return 'Enter first name';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: lastNameController,
                          decoration: const InputDecoration(
                            labelText: 'Last Name',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'Mobile Number',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: companyController,
                          decoration: const InputDecoration(
                            labelText: 'Company',
                            prefixIcon: Icon(Icons.business),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: jobTitleController,
                          decoration: const InputDecoration(
                            labelText: 'Job Title',
                            prefixIcon: Icon(Icons.work),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: selectedContactCategory,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            prefixIcon: Icon(Icons.category),
                            border: OutlineInputBorder(),
                          ),
                          items: categories
                              .where((category) => category != 'All')
                              .map((category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setDialogState(() {
                                      selectedContactCategory = value;
                                    });
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: notesController,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            prefixIcon: Icon(Icons.notes),
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Favorite Contact'),
                          value: favorite,
                          controlAffinity:
                              ListTileControlAffinity.leading,
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  setDialogState(() {
                                    favorite = value ?? false;
                                  });
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) {
                            return;
                          }

                          setDialogState(() {
                            isSaving = true;
                          });

                          try {
                            if (isEditing) {
                              await ApiService.updateContact(
                                id: getId(contact),
                                firstName:
                                    firstNameController.text.trim(),
                                lastName:
                                    lastNameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                company:
                                    companyController.text.trim(),
                                jobTitle:
                                    jobTitleController.text.trim(),
                                category: selectedContactCategory,
                                favorite: favorite,
                                notes: notesController.text.trim(),
                              );
                            } else {
                              await ApiService.createContact(
                                firstName:
                                    firstNameController.text.trim(),
                                lastName:
                                    lastNameController.text.trim(),
                                email: emailController.text.trim(),
                                phone: phoneController.text.trim(),
                                company:
                                    companyController.text.trim(),
                                jobTitle:
                                    jobTitleController.text.trim(),
                                category: selectedContactCategory,
                                favorite: favorite,
                                notes: notesController.text.trim(),
                              );
                            }

                            if (!dialogContext.mounted) return;

                            Navigator.of(dialogContext).pop();

                            await loadContacts();

                            if (!mounted) return;

                            showMessage(
                              isEditing
                                  ? 'Contact updated successfully'
                                  : 'Contact added successfully',
                            );
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              isSaving = false;
                            });

                            ScaffoldMessenger.of(dialogContext)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  isEditing
                                      ? 'Failed to update contact: $e'
                                      : 'Failed to create contact: $e',
                                ),
                              ),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : Text(isEditing ? 'Update' : 'Save'),
                ),
              ],
            );
          },
        );
      },
    );

    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    companyController.dispose();
    jobTitleController.dispose();
    notesController.dispose();
  }

  Future<void> deleteContact(dynamic contact) async {
    final contactName = getFullName(contact);
    final id = getId(contact);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Contact'),
          content: Text(
            'Are you sure you want to delete $contactName?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteContact(id);

      if (!mounted) return;

      await loadContacts();

      if (!mounted) return;

      showMessage('Contact deleted successfully');
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to delete contact: $e');
    }
  }

  Future<void> toggleFavorite(dynamic contact) async {
    final id = getId(contact);
    final newFavorite = !getFavorite(contact);

    try {
      await ApiService.updateContact(
        id: id,
        firstName: getValue(contact, 'first_name'),
        lastName: getValue(contact, 'last_name'),
        email: getValue(contact, 'email'),
        phone: getValue(contact, 'phone'),
        company: getValue(contact, 'company'),
        jobTitle: getValue(contact, 'job_title'),
        category: getValue(contact, 'category'),
        favorite: newFavorite,
        notes: getValue(contact, 'notes'),
      );

      if (!mounted) return;

      await loadContacts();
    } catch (e) {
      if (!mounted) return;

      showMessage('Failed to update favorite: $e');
    }
  }

  Widget contactDetail({
    required IconData icon,
    required String value,
  }) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 18,
            color: Colors.blueGrey,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildContactCard(dynamic contact) {
    final fullName = getFullName(contact);
    final phone = getValue(contact, 'phone');
    final email = getValue(contact, 'email');
    final company = getValue(contact, 'company');
    final jobTitle = getValue(contact, 'job_title');
    final category = getValue(contact, 'category');
    final favorite = getFavorite(contact);

    final displayName =
        fullName.isEmpty ? 'Unnamed Contact' : fullName;

    final initials = fullName.isEmpty
        ? '?'
        : fullName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((part) => part.isNotEmpty ? part[0] : '')
            .join()
            .toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  child: Text(initials),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: favorite
                      ? 'Remove from favorites'
                      : 'Add to favorites',
                  onPressed: () => toggleFavorite(contact),
                  icon: Icon(
                    favorite ? Icons.star : Icons.star_border,
                    color: favorite ? Colors.amber : Colors.grey,
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      showContactDialog(contact: contact);
                    } else if (value == 'delete') {
                      deleteContact(contact);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          SizedBox(width: 8),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            contactDetail(
              icon: Icons.phone,
              value: phone,
            ),
            contactDetail(
              icon: Icons.email,
              value: email,
            ),
            contactDetail(
              icon: Icons.business,
              value: company,
            ),
            contactDetail(
              icon: Icons.work,
              value: jobTitle,
            ),
            if (category.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Chip(
                    label: Text(category),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget buildCategoryFilters() {
    return SizedBox(
      height: 54,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(category),
              selected: selectedCategory == category,
              onSelected: (_) {
                searchByCategory(category);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            tooltip: 'Refresh contacts',
            onPressed: loadContacts,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showContactDialog(),
        tooltip: 'Add Contact',
        child: const Icon(Icons.person_add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: searchController,
              onChanged: searchContacts,
              decoration: InputDecoration(
                hintText:
                    'Search by first name, last name, phone, email...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  tooltip: 'Clear search',
                  onPressed: () {
                    searchController.clear();
                    applyFilters();
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          buildCategoryFilters(),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : contacts.isEmpty
                    ? RefreshIndicator(
                        onRefresh: loadContacts,
                        child: ListView(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          children: const [
                            SizedBox(height: 150),
                            Icon(
                              Icons.contacts_outlined,
                              size: 64,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 12),
                            Center(
                              child: Text(
                                'No contacts found',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: loadContacts,
                        child: ListView.builder(
                          physics:
                              const AlwaysScrollableScrollPhysics(),
                          itemCount: contacts.length,
                          itemBuilder: (context, index) {
                            return buildContactCard(
                              contacts[index],
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
