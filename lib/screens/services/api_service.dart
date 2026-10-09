import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static Future<List<dynamic>> getContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contacts/?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load contacts');
    }

    return jsonDecode(response.body);
  }

  static Future<List<dynamic>> searchContacts(
    String name,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/contacts/cpp-search?name=${Uri.encodeComponent(name)}&user_id=1',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to search contacts');
    }

    final data = jsonDecode(response.body);

    return data['results'];
  }
      static Future<List<dynamic>> searchContactsByCategory(
    String category,
  ) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/contacts/cpp-category?category=${Uri.encodeComponent(category)}&user_id=1',
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load contacts by category');
    }

    final data = jsonDecode(response.body);

    return data['results'];
  }


  static Future<void> createContact({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String company,
    required String jobTitle,
    required String category,
    required bool favorite,
    required String notes,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/contacts/'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': 1,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'company': company,
        'job_title': jobTitle,
        'category': category,
        'favorite': favorite,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create contact');
    }
  }

  static Future<void> updateContact({
    required int id,
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String company,
    required String jobTitle,
    required String category,
    required bool favorite,
    required String notes,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/contacts/$id'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'user_id': 1,
        'first_name': firstName,
        'last_name': lastName,
        'email': email,
        'phone': phone,
        'company': company,
        'job_title': jobTitle,
        'category': category,
        'favorite': favorite,
        'notes': notes,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update contact');
    }
  }

  static Future<void> deleteContact(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/contacts/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete contact');
    }
  }
}