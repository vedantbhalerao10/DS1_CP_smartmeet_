
import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class MeetingExtractionScreen extends StatefulWidget {
  const MeetingExtractionScreen({super.key});

  @override
  State<MeetingExtractionScreen> createState() =>
      _MeetingExtractionScreenState();
}

class _MeetingExtractionScreenState
    extends State<MeetingExtractionScreen> {
  final TextEditingController messageController =
      TextEditingController();

  final TextEditingController titleController =
      TextEditingController();

  final TextEditingController dateController =
      TextEditingController();

  final TextEditingController startController =
      TextEditingController();

  final TextEditingController endController =
      TextEditingController();

  final TextEditingController platformController =
      TextEditingController();

  final TextEditingController linkController =
      TextEditingController();

  final TextEditingController locationController =
      TextEditingController();

  final TextEditingController organizerController =
      TextEditingController();

  final TextEditingController participantsController =
      TextEditingController();
  final TextEditingController agendaController =
      TextEditingController();


  bool extracting = false;
  bool saving = false;
  bool extracted = false;

  List<dynamic> missingFields = [];

  @override
  void dispose() {
    messageController.dispose();
    titleController.dispose();
    dateController.dispose();
    startController.dispose();
    endController.dispose();
    platformController.dispose();
    linkController.dispose();
    locationController.dispose();
    organizerController.dispose();
    participantsController.dispose();
    agendaController.dispose();

    super.dispose();
  }

  Future<void> extractMeeting() async {
    if (messageController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Paste a meeting message first.'),
        ),
      );
      return;
    }

    setState(() {
      extracting = true;
      extracted = false;
      missingFields = [];
    });

    try {
      final result = await ApiService.extractMeeting(
        messageController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        titleController.text =
            result['title']?.toString() ?? '';

        dateController.text =
            result['meeting_date']?.toString() ?? '';

        startController.text =
            result['start_time']?.toString() ?? '';

        endController.text =
            result['end_time']?.toString() ?? '';

        platformController.text =
            result['platform']?.toString() ?? '';

        linkController.text =
            result['meeting_link']?.toString() ?? '';

        locationController.text =
            result['location']?.toString() ?? '';

        organizerController.text =
            result['organizer']?.toString() ?? '';

        final participants =
            result['participants'];

        participantsController.text =
            participants is List
                ? participants.join(', ')
                : participants?.toString() ?? '';
        final agenda = result['agenda'];

        agendaController.text = agenda is List
            ? agenda.join('\n')
            : agenda?.toString() ?? '';

        missingFields = List<dynamic>.from(
          result['missing_fields'] ?? [],
        );

        extracted = true;
        extracting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Extraction complete. Review the details below.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        extracting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  String? validateDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final date = DateTime.tryParse(value.trim());

    if (date == null ||
        date.year < 2020 ||
        date.year > 2100 ||
        date.toIso8601String().substring(0, 10) !=
            value.trim()) {
      return 'Use YYYY-MM-DD';
    }

    return null;
  }

  String? validateTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final match = RegExp(
      r'^([01]\d|2[0-3]):([0-5]\d)(?::([0-5]\d))?$',
    ).firstMatch(value.trim());

    if (match == null) {
      return 'Use 24-hour format, e.g. 15:30:00';
    }

    return null;
  }

  String normalizeTime(String value) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return '';
    }

    final parts = trimmed.split(':');

    if (parts.length == 2) {
      return '${parts[0]}:${parts[1]}:00';
    }

    return trimmed;
  }

  Future<void> confirmAndSchedule() async {
    final dateError = validateDate(dateController.text);
    final startError = validateTime(startController.text);
    final endError = validateTime(endController.text);

    if (dateError != null ||
        startError != null ||
        endError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            dateError ?? startError ?? endError!,
          ),
        ),
      );
      return;
    }

    final startText = startController.text.trim();
    final endText = endController.text.trim();

    if (startText.isNotEmpty && endText.isNotEmpty) {
      final startParts = startText.split(':');
      final endParts = endText.split(':');

      final startMinutes =
          int.parse(startParts[0]) * 60 +
          int.parse(startParts[1]);

      final endMinutes =
          int.parse(endParts[0]) * 60 +
          int.parse(endParts[1]);

      if (endMinutes <= startMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'End time must be later than start time.',
            ),
          ),
        );
        return;
      }
    }

    final link = linkController.text.trim();

    if (link.isNotEmpty) {
      final uri = Uri.tryParse(link);

      if (uri == null ||
          !uri.hasScheme ||
          !['http', 'https'].contains(uri.scheme) ||
          uri.host.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Enter a valid HTTP or HTTPS meeting link.',
            ),
          ),
        );
        return;
      }
    }

    final title = titleController.text.trim().isEmpty
        ? 'Untitled Meeting'
        : titleController.text.trim();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirm meeting'),
        content: Text(
          'Schedule "$title"?\n\n'
          'Date: ${dateController.text.trim().isEmpty ? 'Not specified' : dateController.text.trim()}\n'
          'Start: ${startText.isEmpty ? 'Not specified' : startText}\n'
          'End: ${endText.isEmpty ? 'Not specified' : endText}\n\n'
          'You can schedule the meeting with incomplete details.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, false),
            child: const Text('Review again'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, true),
            child: const Text('Confirm & Schedule'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      saving = true;
    });

    try {
      await ApiService.createMeeting(
        title: title,
        description: [
          messageController.text.trim(),
          if (agendaController.text.trim().isNotEmpty)
              'Extracted Agenda:\n${agendaController.text.trim()}',
        ].join('\n\n'),
        meetingDate: dateController.text.trim(),
        startTime: normalizeTime(startText),
        endTime: normalizeTime(endText),
        platform: platformController.text.trim().isEmpty
            ? 'Other'
            : platformController.text.trim(),
        meetingLink: link,
        location: locationController.text.trim(),
        organizer: organizerController.text.trim(),
        participants: participantsController.text.trim(),
        status: 'Scheduled',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Meeting scheduled successfully!',
          ),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  Widget textField({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Extraction'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 800,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Extract a Meeting',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Paste an invitation, email, or meeting message. '
                  'Review the extracted details before scheduling.',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: messageController,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    labelText: 'Meeting message',
                    hintText:
                        'Paste the meeting invitation here...',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        extracting ? null : extractMeeting,
                    icon: extracting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      extracting
                          ? 'Extracting...'
                          : 'Extract Meeting Details',
                    ),
                  ),
                ),
                if (extracted) ...[
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),
                  const Text(
                    'Review & Edit Details',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'All fields are optional. Fill in only the '
                    'details you know, then schedule the meeting.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                    ),
                  ),
                  if (missingFields.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(
                          alpha: 0.08,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blueGrey,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Some information was not found',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            missingFields
                                .map((field) => field.toString())
                                .join(', '),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'You can leave these fields empty.',
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Form(
                    child: Column(
                      children: [
                        textField(
                          label: 'Meeting title',
                          controller: titleController,
                        ),
                        textField(
                          label: 'Meeting date',
                          controller: dateController,
                          hint: 'YYYY-MM-DD (optional)',
                          validator: validateDate,
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: textField(
                                label: 'Start time',
                                controller: startController,
                                hint: '15:30:00',
                                validator: validateTime,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: textField(
                                label: 'End time',
                                controller: endController,
                                hint: '16:30:00',
                                validator: validateTime,
                              ),
                            ),
                          ],
                        ),
                        textField(
                          label: 'Platform',
                          controller: platformController,
                          hint: 'Google Meet, Zoom, Teams...',
                        ),
                        textField(
                          label: 'Meeting link',
                          controller: linkController,
                          hint: 'https://... (optional)',
                        ),
                        textField(
                          label: 'Location',
                          controller: locationController,
                        ),
                        textField(
                          label: 'Organizer',
                          controller: organizerController,
                        ),
                        textField(
                          label: 'Participants',
                          controller: participantsController,
                          maxLines: 2,
                        ),
			textField(
                          label: 'Meeting agenda',
                          controller: agendaController,
                          hint: 'One agenda item per line (optional)',
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed:
                          saving ? null : confirmAndSchedule,
                      icon: saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.event_available),
                      label: Text(
                        saving
                            ? 'Scheduling...'
                            : 'Confirm & Schedule Meeting',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
