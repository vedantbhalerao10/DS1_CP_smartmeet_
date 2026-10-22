
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import 'meeting_extraction_screen.dart';

class MeetingsScreen extends StatefulWidget {
  const MeetingsScreen({super.key});

  @override
  State<MeetingsScreen> createState() => _MeetingsScreenState();
}

class _MeetingsScreenState extends State<MeetingsScreen> {
  List<dynamic> meetings = [];
  bool loading = true;
  String searchText = '';

  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMeetings();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadMeetings({String query = ''}) async {
    if (!mounted) return;

    setState(() => loading = true);

    try {
      final result = query.trim().isEmpty
          ? await ApiService.getMeetings()
          : await ApiService.searchMeetings(query.trim());

      if (!mounted) return;

      setState(() {
        meetings = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to load meetings: $e')),
      );
    }
  }

  Future<void> openMeetingExtraction() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const MeetingExtractionScreen(),
      ),
    );

    if (!mounted) return;

    if (result == true) {
      await loadMeetings(query: searchText);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meeting list refreshed successfully'),
        ),
      );
    }
  }

  Future<void> openMeetingForm({Map<String, dynamic>? meeting}) async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: meeting?['title']?.toString() ?? '',
    );
    final descriptionController = TextEditingController(
      text: meeting?['description']?.toString() ?? '',
    );
    final linkController = TextEditingController(
      text: meeting?['meeting_link']?.toString() ?? '',
    );
    final locationController = TextEditingController(
      text: meeting?['location']?.toString() ?? '',
    );
    final organizerController = TextEditingController(
      text: meeting?['organizer']?.toString() ?? '',
    );
    final participantsController = TextEditingController(
      text: meeting?['participants']?.toString() ?? '',
    );

    DateTime selectedDate = meeting == null
        ? DateTime.now()
        : DateTime.parse(meeting['meeting_date'].toString());

    TimeOfDay selectedStart = meeting == null
        ? const TimeOfDay(hour: 10, minute: 0)
        : _parseTime(meeting['start_time']);

    TimeOfDay selectedEnd = meeting == null
        ? const TimeOfDay(hour: 11, minute: 0)
        : _parseTime(meeting['end_time']);

    const platforms = [
      'Google Meet',
      'Microsoft Teams',
      'Zoom',
      'Other',
    ];

    const statuses = [
      'Scheduled',
      'Completed',
      'Cancelled',
    ];

    String platform = platforms.contains(meeting?['platform']?.toString())
        ? meeting!['platform'].toString()
        : 'Other';

    String status = statuses.contains(meeting?['status']?.toString())
        ? meeting!['status'].toString()
        : 'Scheduled';

    bool saving = false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                meeting == null ? 'Create Meeting' : 'Edit Meeting',
              ),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: titleController,
                          decoration: const InputDecoration(
                            labelText: 'Meeting title *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Enter a meeting title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: descriptionController,
                          maxLines: 2,
                          decoration: const InputDecoration(
                            labelText: 'Description',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Meeting date'),
                          subtitle: Text(
                            '${selectedDate.year}-'
                            '${selectedDate.month.toString().padLeft(2, '0')}-'
                            '${selectedDate.day.toString().padLeft(2, '0')}',
                          ),
                          trailing: const Icon(Icons.calendar_month),
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: selectedDate,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2100),
                            );

                            if (picked != null) {
                              setDialogState(() {
                                selectedDate = picked;
                              });
                            }
                          },
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('Start time'),
                                subtitle: Text(
                                  selectedStart.format(context),
                                ),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedStart,
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedStart = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                            Expanded(
                              child: ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: const Text('End time'),
                                subtitle: Text(selectedEnd.format(context)),
                                onTap: () async {
                                  final picked = await showTimePicker(
                                    context: context,
                                    initialTime: selectedEnd,
                                  );

                                  if (picked != null) {
                                    setDialogState(() {
                                      selectedEnd = picked;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: platform,
                          decoration: const InputDecoration(
                            labelText: 'Platform',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Google Meet',
                              child: Text('Google Meet'),
                            ),
                            DropdownMenuItem(
                              value: 'Microsoft Teams',
                              child: Text('Microsoft Teams'),
                            ),
                            DropdownMenuItem(
                              value: 'Zoom',
                              child: Text('Zoom'),
                            ),
                            DropdownMenuItem(
                              value: 'Other',
                              child: Text('Other'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                platform = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: linkController,
                          decoration: const InputDecoration(
                            labelText: 'Meeting link',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.url,
                          validator: (value) {
                            final link = value?.trim() ?? '';

                            if (link.isEmpty) return null;

                            final uri = Uri.tryParse(link);

                            if (uri == null ||
                                !uri.hasScheme ||
                                !['http', 'https'].contains(uri.scheme)) {
                              return 'Enter a valid HTTP or HTTPS link';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: organizerController,
                          decoration: const InputDecoration(
                            labelText: 'Organizer',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: participantsController,
                          decoration: const InputDecoration(
                            labelText: 'Participants',
                            hintText: 'Names separated by commas',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: status,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Scheduled',
                              child: Text('Scheduled'),
                            ),
                            DropdownMenuItem(
                              value: 'Completed',
                              child: Text('Completed'),
                            ),
                            DropdownMenuItem(
                              value: 'Cancelled',
                              child: Text('Cancelled'),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() {
                                status = value;
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: saving
                      ? null
                      : () async {
                          if (!formKey.currentState!.validate()) return;

                          final startMinutes =
                              selectedStart.hour * 60 +
                              selectedStart.minute;

                          final endMinutes =
                              selectedEnd.hour * 60 +
                              selectedEnd.minute;

                          if (endMinutes <= startMinutes) {
                            ScaffoldMessenger.of(
                              dialogContext,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'End time must be after start time',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            saving = true;
                          });

                          try {
                            final date =
                                '${selectedDate.year}-'
                                '${selectedDate.month.toString().padLeft(2, '0')}-'
                                '${selectedDate.day.toString().padLeft(2, '0')}';

                            final arguments = {
                              'title': titleController.text.trim(),
                              'description':
                                  descriptionController.text.trim(),
                              'meetingDate': date,
                              'startTime': _formatTime(selectedStart),
                              'endTime': _formatTime(selectedEnd),
                              'platform': platform,
                              'meetingLink': linkController.text.trim(),
                              'location': locationController.text.trim(),
                              'organizer': organizerController.text.trim(),
                              'participants':
                                  participantsController.text.trim(),
                              'status': status,
                            };

                            if (meeting == null) {
                              await ApiService.createMeeting(
                                title: arguments['title']!,
                                description: arguments['description']!,
                                meetingDate: arguments['meetingDate']!,
                                startTime: arguments['startTime']!,
                                endTime: arguments['endTime']!,
                                platform: arguments['platform']!,
                                meetingLink: arguments['meetingLink']!,
                                location: arguments['location']!,
                                organizer: arguments['organizer']!,
                                participants: arguments['participants']!,
                                status: arguments['status']!,
                              );
                            } else {
                              await ApiService.updateMeeting(
                                id: meeting['id'] as int,
                                title: arguments['title']!,
                                description: arguments['description']!,
                                meetingDate: arguments['meetingDate']!,
                                startTime: arguments['startTime']!,
                                endTime: arguments['endTime']!,
                                platform: arguments['platform']!,
                                meetingLink: arguments['meetingLink']!,
                                location: arguments['location']!,
                                organizer: arguments['organizer']!,
                                participants: arguments['participants']!,
                                status: arguments['status']!,
                              );
                            }

                            if (dialogContext.mounted) {
                              Navigator.pop(dialogContext, true);
                            }
                          } catch (e) {
                            if (!dialogContext.mounted) return;

                            setDialogState(() {
                              saving = false;
                            });

                            ScaffoldMessenger.of(dialogContext).showSnackBar(
                              SnackBar(
                                content: Text(
                                  e.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
                                ),
                              ),
                            );
                          }
                        },
                  child: Text(saving ? 'Saving...' : 'Save Meeting'),
                ),
              ],
            );
          },
        );
      },
    );

    titleController.dispose();
    descriptionController.dispose();
    linkController.dispose();
    locationController.dispose();
    organizerController.dispose();
    participantsController.dispose();

    if (result == true && mounted) {
      await loadMeetings(query: searchText);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            meeting == null
                ? 'Meeting created successfully'
                : 'Meeting updated successfully',
          ),
        ),
      );
    }
  }

  TimeOfDay _parseTime(dynamic value) {
    if (value == null) {
      return const TimeOfDay(hour: 10, minute: 0);
    }

    final text = value.toString().trim();

    final parts = text.split(':');

    if (parts.length >= 2) {
      final hour = int.tryParse(parts[0]);
      final minute = int.tryParse(parts[1]);

      if (hour != null &&
          minute != null &&
          hour >= 0 &&
          hour <= 23 &&
          minute >= 0 &&
          minute <= 59) {
        return TimeOfDay(hour: hour, minute: minute);
      }
    }

    final seconds = int.tryParse(text);

    if (seconds != null && seconds >= 0 && seconds < 86400) {
      return TimeOfDay(
        hour: seconds ~/ 3600,
        minute: (seconds % 3600) ~/ 60,
      );
    }

    return const TimeOfDay(hour: 10, minute: 0);
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}:00';
  }

  String _displayMeetingTime(dynamic value) {
    if (value == null) {
      return '--:--';
    }

    final text = value.toString().trim();

    final timeMatch = RegExp(
      r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$',
    ).firstMatch(text);

    if (timeMatch != null) {
      final hour = int.parse(timeMatch.group(1)!);
      final minute = int.parse(timeMatch.group(2)!);

      if (hour > 23 || minute > 59) {
        return text;
      }

      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    final seconds = int.tryParse(text);

    if (seconds != null && seconds >= 0 && seconds < 86400) {
      final hour = seconds ~/ 3600;
      final minute = (seconds % 3600) ~/ 60;
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;

      return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
    }

    return text;
  }

  Future<void> deleteMeeting(Map<String, dynamic> meeting) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete meeting?'),
        content: Text('Delete "${meeting['title']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ApiService.deleteMeeting(meeting['id'] as int);

      if (!mounted) return;

      await loadMeetings(query: searchText);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meeting deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to delete meeting: $e')),
      );
    }
  }

  Future<void> openMeetingLink(String value) async {
    final uri = Uri.tryParse(value);

    if (uri == null ||
        !uri.hasScheme ||
        !['http', 'https'].contains(uri.scheme)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a valid HTTP or HTTPS link'),
        ),
      );
      return;
    }

    try {
      final opened = await launchUrl(uri);

      if (!mounted) return;

      if (!opened) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open meeting link'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open link: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheduledCount = meetings
        .where((meeting) => meeting['status'] == 'Scheduled')
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meetings'),
        actions: [
          IconButton(
            tooltip: 'Extract Meeting',
            icon: const Icon(Icons.auto_awesome),
            onPressed: openMeetingExtraction,
          ),
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => loadMeetings(query: searchText),
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openMeetingForm(),
        icon: const Icon(Icons.add),
        label: const Text('New Meeting'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage your schedule',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create meetings, manage participants and track your schedule.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _summaryCard(
                    'Total meetings',
                    meetings.length.toString(),
                    Icons.groups_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _summaryCard(
                    'Scheduled',
                    scheduledCount.toString(),
                    Icons.event_available_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search meetings by title...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  onPressed: () {
                    searchController.clear();
                    searchText = '';
                    loadMeetings();
                  },
                  icon: const Icon(Icons.clear),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                searchText = value;
                loadMeetings(query: value);
              },
            ),
            const SizedBox(height: 20),
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : meetings.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_busy_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'No meetings found',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Create a meeting to get started.',
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => openMeetingForm(),
                                icon: const Icon(Icons.add),
                                label: const Text('Create Meeting'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: meetings.length,
                          itemBuilder: (context, index) {
                            final meeting =
                                Map<String, dynamic>.from(meetings[index]);

                            return _meetingCard(meeting);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(
              icon,
              size: 34,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(title),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _meetingCard(Map<String, dynamic> meeting) {
    final date = meeting['meeting_date']?.toString() ?? '';
    final start = _displayMeetingTime(meeting['start_time']);
    final end = _displayMeetingTime(meeting['end_time']);
    final link = meeting['meeting_link']?.toString() ?? '';
    final status = meeting['status']?.toString() ?? 'Scheduled';

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  child: Icon(
                    _platformIcon(meeting['platform']?.toString()),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meeting['title']?.toString() ?? 'Untitled Meeting',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text('$date  •  $start – $end'),
                      const SizedBox(height: 4),
                      Text(
                        meeting['platform']?.toString() ?? 'Other',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      openMeetingForm(meeting: meeting);
                    } else if (value == 'delete') {
                      deleteMeeting(meeting);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            if ((meeting['description'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(meeting['description'].toString()),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(status),
                  avatar: const Icon(Icons.circle, size: 12),
                ),
                if ((meeting['location'] ?? '').toString().isNotEmpty)
                  Chip(
                    label: Text(meeting['location'].toString()),
                    avatar: const Icon(
                      Icons.location_on_outlined,
                      size: 16,
                    ),
                  ),
                if ((meeting['organizer'] ?? '').toString().isNotEmpty)
                  Chip(
                    label: Text('By ${meeting['organizer']}'),
                    avatar: const Icon(
                      Icons.person_outline,
                      size: 16,
                    ),
                  ),
              ],
            ),
            if (link.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => openMeetingLink(link),
                  icon: const Icon(Icons.video_call_outlined),
                  label: const Text('Join Meeting'),
                ),
              ),
            ],
            if ((meeting['participants'] ?? '').toString().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Participants: ${meeting['participants']}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _platformIcon(String? platform) {
    switch (platform) {
      case 'Google Meet':
        return Icons.video_call_outlined;
      case 'Microsoft Teams':
        return Icons.groups_outlined;
      case 'Zoom':
        return Icons.videocam_outlined;
      default:
        return Icons.event_outlined;
    }
  }
}
