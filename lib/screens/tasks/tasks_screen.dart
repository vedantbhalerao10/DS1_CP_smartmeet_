import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  List<dynamic> tasks = [];
  List<dynamic> meetings = [];

  bool loading = true;
  String? error;

  String statusFilter = 'All';
  String priorityFilter = 'All';
  String searchText = '';

  final TextEditingController searchController = TextEditingController();

  final List<String> priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    loadTasks();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // Convert HH:mm, HH:mm:ss, or seconds into seconds.
  int? timeToSeconds(String time) {
    if (time.trim().isEmpty) return null;

    final numericValue = int.tryParse(time.trim());

    if (numericValue != null) {
      if (numericValue < 0 || numericValue >= 86400) {
        return null;
      }

      return numericValue;
    }

    final parts = time.split(':');

    if (parts.length < 2 || parts.length > 3) {
      return null;
    }

    final hours = int.tryParse(parts[0]);
    final minutes = int.tryParse(parts[1]);

    final seconds = parts.length == 3 ? int.tryParse(parts[2]) : 0;

    if (hours == null ||
        minutes == null ||
        seconds == null ||
        hours < 0 ||
        hours > 23 ||
        minutes < 0 ||
        minutes > 59 ||
        seconds < 0 ||
        seconds > 59) {
      return null;
    }

    return hours * 3600 + minutes * 60 + seconds;
  }

  // Convert seconds or a time string into HH:mm for display.
  String formatDueTime(String time) {
    final seconds = timeToSeconds(time);

    if (seconds == null) return time;

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }

  // Convert stored time into the value needed by TimeOfDay.
  TimeOfDay parseTimeOfDay(String time) {
    final seconds = timeToSeconds(time);

    if (seconds == null) {
      return TimeOfDay.now();
    }

    return TimeOfDay(hour: seconds ~/ 3600, minute: (seconds % 3600) ~/ 60);
  }

  // Convert a date into YYYY-MM-DD.
  String formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadTasks() async {
    if (!mounted) return;

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final results = await ApiService.getTasks(
        status: statusFilter == 'All' ? null : statusFilter,
        priority: priorityFilter == 'All' ? null : priorityFilter,
        search: searchText,
      );

      if (!mounted) return;

      setState(() {
        tasks = results;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> loadMeetings() async {
    meetings = await ApiService.getMeetings();
  }

  Future<void> openTaskForm({Map<String, dynamic>? task}) async {
    final formKey = GlobalKey<FormState>();

    final titleController = TextEditingController(
      text: task?['title']?.toString() ?? '',
    );

    final descriptionController = TextEditingController(
      text: task?['description']?.toString() ?? '',
    );

    String priority = task?['priority']?.toString() ?? 'Medium';

    String status = task?['status']?.toString() ?? 'Pending';

    String dueDate = task?['due_date']?.toString() ?? '';

    // The stored value may be 64800, 18:00, or 18:00:00.
    String dueTime = task?['due_time']?.toString() ?? '';

    int? meetingId = int.tryParse(task?['meeting_id']?.toString() ?? '');

    try {
      await loadMeetings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load meetings: $e')));
      }

      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    if (!mounted) {
      titleController.dispose();
      descriptionController.dispose();
      return;
    }

    if (!priorities.contains(priority)) {
      priority = 'Medium';
    }

    if (status != 'Pending' && status != 'Completed') {
      status = 'Pending';
    }

    if (meetingId != null &&
        !meetings.any(
          (meeting) => int.tryParse(meeting['id'].toString()) == meetingId,
        )) {
      meetingId = null;
    }

    bool saved = false;

    try {
      final result = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(task == null ? 'Create Task' : 'Edit Task'),
                content: SizedBox(
                  width: 450,
                  child: SingleChildScrollView(
                    child: Form(
                      key: formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: titleController,
                            decoration: const InputDecoration(
                              labelText: 'Task title *',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Enter a task title';
                              }

                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: descriptionController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: priority,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Priority',
                              border: OutlineInputBorder(),
                            ),
                            items: priorities.map((value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setDialogState(() {
                                  priority = value;
                                });
                              }
                            },
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            initialValue: status,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'Pending',
                                child: Text('Pending'),
                              ),
                              DropdownMenuItem(
                                value: 'Completed',
                                child: Text('Completed'),
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
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final parsedDate = DateTime.tryParse(dueDate);

                              final selectedDate = await showDatePicker(
                                context: dialogContext,
                                initialDate: parsedDate ?? DateTime.now(),
                                firstDate: DateTime(2000),
                                lastDate: DateTime(2100),
                              );

                              if (selectedDate != null) {
                                setDialogState(() {
                                  dueDate = formatDate(selectedDate);
                                });
                              }
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              dueDate.isEmpty ? 'Choose due date' : dueDate,
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                dueDate = '';
                              });
                            },
                            child: const Text('Clear due date'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final selectedTime = await showTimePicker(
                                context: dialogContext,
                                initialTime: parseTimeOfDay(dueTime),
                              );

                              if (selectedTime != null) {
                                setDialogState(() {
                                  // Store as seconds internally.
                                  dueTime =
                                      (selectedTime.hour * 3600 +
                                              selectedTime.minute * 60)
                                          .toString();
                                });
                              }
                            },
                            icon: const Icon(Icons.access_time),
                            label: Text(
                              dueTime.isEmpty
                                  ? 'Choose due time'
                                  : formatDueTime(dueTime),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                dueTime = '';
                              });
                            },
                            child: const Text('Clear due time'),
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<int?>(
                            initialValue: meetingId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Related meeting (optional)',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem<int?>(
                                value: null,
                                child: Text('No meeting'),
                              ),
                              ...meetings.map((meeting) {
                                final id = int.tryParse(
                                  meeting['id'].toString(),
                                );

                                if (id == null) return null;

                                return DropdownMenuItem<int?>(
                                  value: id,
                                  child: Text(
                                    meeting['title']?.toString() ??
                                        'Untitled Meeting',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).whereType<DropdownMenuItem<int?>>(),
                            ],
                            onChanged: (value) {
                              setDialogState(() {
                                meetingId = value;
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
                    onPressed: () {
                      Navigator.pop(dialogContext, false);
                    },
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () {
                      if (formKey.currentState!.validate()) {
                        Navigator.pop(dialogContext, true);
                      }
                    },
                    child: Text(task == null ? 'Create' : 'Save'),
                  ),
                ],
              );
            },
          );
        },
      );

      if (result != true || !mounted) return;

      // Send dueTime to the API as seconds, e.g. "64800".
      final dueTimeSeconds = dueTime.isEmpty
          ? ''
          : (timeToSeconds(dueTime)?.toString() ?? '');

      if (dueTime.isNotEmpty && dueTimeSeconds.isEmpty) {
        throw Exception('Invalid due time.');
      }

      if (task == null) {
        await ApiService.createTask(
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          priority: priority,
          dueDate: dueDate,
          dueTime: dueTimeSeconds,
          meetingId: meetingId,
        );

        if (status == 'Completed') {
          final refreshedTasks = await ApiService.getTasks();

          final matchingTasks = refreshedTasks
              .whereType<Map>()
              .where(
                (item) =>
                    item['title']?.toString() == titleController.text.trim(),
              )
              .toList();

          if (matchingTasks.length == 1) {
            await ApiService.completeTask(
              int.parse(matchingTasks.first['id'].toString()),
            );
          }
        }
      } else {
        await ApiService.updateTask(
          id: int.parse(task['id'].toString()),
          title: titleController.text.trim(),
          description: descriptionController.text.trim(),
          priority: priority,
          dueDate: dueDate,
          dueTime: dueTimeSeconds,
          status: status,
          meetingId: meetingId,
        );
      }

      saved = true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      titleController.dispose();
      descriptionController.dispose();
    }

    if (saved && mounted) {
      await loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              task == null
                  ? 'Task created successfully'
                  : 'Task updated successfully',
            ),
          ),
        );
      }
    }
  }

  Future<void> changeTaskStatus(Map<String, dynamic> task) async {
    final id = int.parse(task['id'].toString());
    final isCompleted = task['status'] == 'Completed';

    try {
      if (isCompleted) {
        await ApiService.reopenTask(id);
      } else {
        await ApiService.completeTask(id);
      }

      await loadTasks();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> deleteTask(Map<String, dynamic> task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Delete "${task['title']}" permanently?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await ApiService.deleteTask(int.parse(task['id'].toString()));

      await loadTasks();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Color priorityColor(String priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red;
      case 'High':
        return Colors.deepOrange;
      case 'Medium':
        return Colors.blue;
      default:
        return Colors.green;
    }
  }

  bool isOverdue(Map<String, dynamic> task) {
    if (task['status'] == 'Completed') return false;
    final date = DateTime.tryParse(task['due_date']?.toString() ?? '');
    if (date == null) return false;
    final time = timeToSeconds(task['due_time']?.toString() ?? '');
    final deadline = DateTime(
      date.year,
      date.month,
      date.day,
      time == null ? 23 : time ~/ 3600,
      time == null ? 59 : (time % 3600) ~/ 60,
      time == null ? 59 : time % 60,
    );
    return deadline.isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalCount = tasks.length;
    final pendingCount = tasks
        .where((task) => task['status'] == 'Pending')
        .length;
    final completedCount = tasks
        .where((task) => task['status'] == 'Completed')
        .length;
    final overdueCount = tasks
        .whereType<Map>()
        .where((task) => isOverdue(Map<String, dynamic>.from(task)))
        .length;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        titleSpacing: 24,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks & Reminders',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF172554),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Keep your day organized and on track',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh tasks',
            onPressed: loadTasks,
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 12),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTaskForm(),
        backgroundColor: const Color(0xFF4F46E5),
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'New task',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                children: [
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 620;
                      final cards = [
                        _summaryCard(
                          'Total tasks',
                          totalCount.toString(),
                          Icons.checklist_rounded,
                          const Color(0xFF4F46E5),
                        ),
                        _summaryCard(
                          'Pending',
                          pendingCount.toString(),
                          Icons.pending_actions_rounded,
                          const Color(0xFFD97706),
                        ),
                        _summaryCard(
                          'Completed',
                          completedCount.toString(),
                          Icons.task_alt_rounded,
                          const Color(0xFF16A34A),
                        ),
                        _summaryCard(
                          'Overdue',
                          overdueCount.toString(),
                          Icons.alarm_rounded,
                          const Color(0xFFDC2626),
                        ),
                      ];
                      if (compact) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(child: cards[0]),
                                const SizedBox(width: 10),
                                Expanded(child: cards[1]),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(child: cards[2]),
                                const SizedBox(width: 10),
                                Expanded(child: cards[3]),
                              ],
                            ),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          for (var i = 0; i < cards.length; i++) ...[
                            if (i > 0) const SizedBox(width: 12),
                            Expanded(child: cards[i]),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: searchController,
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      searchText = value.trim();
                      loadTasks();
                    },
                    onSubmitted: (value) {
                      searchText = value.trim();
                      loadTasks();
                    },
                    decoration: InputDecoration(
                      hintText: 'Search tasks by title or description...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF64748B),
                      ),
                      suffixIcon: searchController.text.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              onPressed: () {
                                searchController.clear();
                                searchText = '';
                                loadTasks();
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: Color(0xFF818CF8),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final statusField = DropdownButtonFormField<String>(
                        initialValue: statusFilter,
                        isExpanded: true,
                        decoration: _filterDecoration('Status'),
                        items: const [
                          DropdownMenuItem(
                            value: 'All',
                            child: Text('All statuses'),
                          ),
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'Completed',
                            child: Text('Completed'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => statusFilter = value);
                          loadTasks();
                        },
                      );
                      final priorityField = DropdownButtonFormField<String>(
                        initialValue: priorityFilter,
                        isExpanded: true,
                        decoration: _filterDecoration('Priority'),
                        items: [
                          const DropdownMenuItem(
                            value: 'All',
                            child: Text('All priorities'),
                          ),
                          ...priorities.map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => priorityFilter = value);
                          loadTasks();
                        },
                      );
                      if (constraints.maxWidth < 520) {
                        return Column(
                          children: [
                            statusField,
                            const SizedBox(height: 10),
                            priorityField,
                          ],
                        );
                      }
                      return Row(
                        children: [
                          Expanded(child: statusField),
                          const SizedBox(width: 12),
                          Expanded(child: priorityField),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.cloud_off_rounded,
                              size: 48,
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Could not load tasks',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: loadTasks,
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Try again'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : tasks.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE0E7FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.task_alt_rounded,
                                size: 42,
                                color: Color(0xFF4F46E5),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Nothing on your list yet',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF172554),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Create a task to start organizing your work.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: () => openTaskForm(),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Create your first task'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: loadTasks,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          final task = Map<String, dynamic>.from(
                            tasks[index] as Map,
                          );
                          return _taskCard(task);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _filterDecoration(String label) => InputDecoration(
    labelText: label,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF818CF8), width: 1.5),
    ),
  );

  Widget _summaryCard(String title, String count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  count,
                  style: const TextStyle(
                    fontSize: 24,
                    height: 1.1,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF172554),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final id = int.tryParse(task['id']?.toString() ?? '') ?? 0;
    final title = task['title']?.toString() ?? 'Untitled task';
    final description = task['description']?.toString() ?? '';
    final priority = task['priority']?.toString() ?? 'Medium';
    final status = task['status']?.toString() ?? 'Pending';
    final dueDate = task['due_date']?.toString() ?? '';
    final dueTime = task['due_time']?.toString() ?? '';
    final meetingId = task['meeting_id']?.toString() ?? '';
    final completed = status == 'Completed';
    final overdue = isOverdue(task);
    final pColor = priorityColor(priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: overdue ? const Color(0xFFFECACA) : const Color(0xFFE8ECF4),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x070F172A),
            blurRadius: 12,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: completed,
                  onChanged: (_) => changeTaskStatus(task),
                  activeColor: const Color(0xFF16A34A),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF172554),
                            decoration: completed
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: const Color(0xFF94A3B8),
                          ),
                        ),
                        if (description.trim().isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            description,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Task actions',
                  onSelected: (value) {
                    if (value == 'edit') openTaskForm(task: task);
                    if (value == 'delete') deleteTask(task);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('Edit task'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(
                          Icons.delete_outline,
                          color: Color(0xFFDC2626),
                        ),
                        title: Text('Delete task'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _badge(priority, pColor, Icons.flag_outlined),
                  _badge(
                    status,
                    completed
                        ? const Color(0xFF16A34A)
                        : const Color(0xFF64748B),
                    completed
                        ? Icons.check_circle_outline_rounded
                        : Icons.pending_actions_rounded,
                  ),
                  if (overdue)
                    _badge(
                      'Overdue',
                      const Color(0xFFDC2626),
                      Icons.warning_amber_rounded,
                    ),
                  if (dueDate.isNotEmpty || dueTime.isNotEmpty)
                    _badge(
                      [
                        if (dueDate.isNotEmpty) dueDate,
                        if (dueTime.isNotEmpty) formatDueTime(dueTime),
                      ].join('  ·  '),
                      overdue
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF475569),
                      Icons.calendar_month_rounded,
                    ),
                  if (meetingId.isNotEmpty && meetingId != 'null')
                    _badge(
                      'Meeting #$meetingId',
                      const Color(0xFF4F46E5),
                      Icons.event_outlined,
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 12),
                  child: Text(
                    'TASK-$id',
                    style: const TextStyle(
                      fontSize: 10,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => changeTaskStatus(task),
                  style: TextButton.styleFrom(
                    foregroundColor: completed
                        ? const Color(0xFF64748B)
                        : const Color(0xFF4F46E5),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: Icon(
                    completed
                        ? Icons.undo_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 17,
                  ),
                  label: Text(
                    completed ? 'Reopen' : 'Mark complete',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
