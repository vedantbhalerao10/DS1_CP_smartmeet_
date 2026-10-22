
import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  // CONTACTS

  static Future<List<dynamic>> getContacts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/contacts/?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load contacts: ${response.body}');
    }

    return List<dynamic>.from(jsonDecode(response.body));
  }

  static Future<List<dynamic>> searchContacts(String name) async {
    final uri = Uri.parse('$baseUrl/contacts/cpp-search').replace(
      queryParameters: {
        'name': name,
        'user_id': '1',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search contacts: ${response.body}');
    }

    final data = jsonDecode(response.body);

    return List<dynamic>.from(data['results'] ?? []);
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
      headers: {'Content-Type': 'application/json'},
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
      throw Exception('Failed to create contact: ${response.body}');
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
      headers: {'Content-Type': 'application/json'},
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
      throw Exception('Failed to update contact: ${response.body}');
    }
  }

  static Future<void> deleteContact(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/contacts/$id'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete contact: ${response.body}');
    }
  }

  static Future<List<dynamic>> searchContactsByCategory(
    String category,
  ) async {
    final uri = Uri.parse('$baseUrl/contacts/cpp-category').replace(
      queryParameters: {
        'category': category,
        'user_id': '1',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to search contacts by category: ${response.body}',
      );
    }

    final data = jsonDecode(response.body);

    return List<dynamic>.from(data['results'] ?? []);
  }

  // MEETINGS

  static Future<List<dynamic>> getMeetings() async {
    final response = await http.get(
      Uri.parse('$baseUrl/meetings/?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load meetings: ${response.body}');
    }

    return List<dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> createMeeting({
    required String title,
    required String description,
    required String meetingDate,
    required String startTime,
    required String endTime,
    required String platform,
    required String meetingLink,
    required String location,
    required String organizer,
    required String participants,
    required String status,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/meetings/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 1,
        'title': title,
        'description': description,
        'meeting_date': meetingDate,
        'start_time': startTime,
        'end_time': endTime,
        'platform': platform,
        'meeting_link': meetingLink,
        'location': location,
        'organizer': organizer,
        'participants': participants,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to create meeting: ${response.body}',
      );
    }
  }

  static Future<void> updateMeeting({
    required int id,
    required String title,
    required String description,
    required String meetingDate,
    required String startTime,
    required String endTime,
    required String platform,
    required String meetingLink,
    required String location,
    required String organizer,
    required String participants,
    required String status,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/meetings/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 1,
        'title': title,
        'description': description,
        'meeting_date': meetingDate,
        'start_time': startTime,
        'end_time': endTime,
        'platform': platform,
        'meeting_link': meetingLink,
        'location': location,
        'organizer': organizer,
        'participants': participants,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update meeting: ${response.body}',
      );
    }
  }

  static Future<void> deleteMeeting(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/meetings/$id?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete meeting: ${response.body}');
    }
  }

  static Future<List<dynamic>> searchMeetings(String title) async {
    final uri = Uri.parse('$baseUrl/meetings/search').replace(
      queryParameters: {
        'title': title,
        'user_id': '1',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to search meetings: ${response.body}');
    }

    return List<dynamic>.from(jsonDecode(response.body));
  }

  // MEETING EXTRACTION

  static Future<Map<String, dynamic>> extractMeeting(
    String text,
  ) async {
    if (text.trim().isEmpty) {
      throw Exception('Please enter meeting details to extract.');
    }

    final response = await http
        .post(
          Uri.parse('$baseUrl/extraction/extract'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'text': text.trim(),
          }),
        )
        .timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception(
              'Meeting extraction timed out. Check whether the backend is running.',
            );
          },
        );

    if (response.statusCode != 200) {
      String message = 'Failed to extract meeting details.';

      try {
        final errorData = jsonDecode(response.body);

        if (errorData is Map<String, dynamic>) {
          message = errorData['detail']?.toString() ??
              errorData['message']?.toString() ??
              message;
        }
      } catch (_) {
        message = response.body.isNotEmpty
            ? response.body
            : message;
      }

      throw Exception(message);
    }

    try {
      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        throw Exception(
          'The extraction server returned an unexpected response.',
        );
      }

      return data;
    } on FormatException {
      throw Exception(
        'The extraction server returned invalid JSON.',
      );
    }
  }

  // TASKS

  static Future<List<dynamic>> getTasks({
    String? status,
    String? priority,
    String? search,
  }) async {
    final parameters = <String, String>{
      'user_id': '1',
    };

    if (status != null && status.isNotEmpty) {
      parameters['status'] = status;
    }

    if (priority != null && priority.isNotEmpty) {
      parameters['priority'] = priority;
    }

    if (search != null && search.trim().isNotEmpty) {
      parameters['search'] = search.trim();
    }

    final uri = Uri.parse('$baseUrl/tasks/').replace(
      queryParameters: parameters,
    );

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Failed to load tasks: ${response.body}');
    }

    return List<dynamic>.from(jsonDecode(response.body));
  }

  static Future<Map<String, dynamic>> getTask(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/tasks/$id?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load task: ${response.body}');
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }

  static Future<void> createTask({
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    required String dueTime,
    int? meetingId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/tasks/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 1,
        'meeting_id': meetingId,
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate.isEmpty ? null : dueDate,
        'due_time': dueTime.isEmpty ? null : dueTime,
        'status': 'Pending',
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to create task: ${response.body}');
    }
  }

  static Future<void> updateTask({
    required int id,
    required String title,
    required String description,
    required String priority,
    required String dueDate,
    required String dueTime,
    required String status,
    int? meetingId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/tasks/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': 1,
        'meeting_id': meetingId,
        'title': title,
        'description': description,
        'priority': priority,
        'due_date': dueDate.isEmpty ? null : dueDate,
        'due_time': dueTime.isEmpty ? null : dueTime,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update task: ${response.body}');
    }
  }

  static Future<void> completeTask(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$id/complete?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to complete task: ${response.body}');
    }
  }

  static Future<void> reopenTask(int id) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/tasks/$id/pending?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to reopen task: ${response.body}');
    }
  }

  static Future<void> deleteTask(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/tasks/$id?user_id=1'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task: ${response.body}');
    }
  }
}
