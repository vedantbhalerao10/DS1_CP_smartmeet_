import 'package:flutter/material.dart';
import '../../services/api_service.dart';

enum CalendarFilter {
  all,
  meetings,
  tasks,
}

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime selectedDate = DateTime.now();

  DateTime displayedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );

  List<Map<String, dynamic>> meetings = [];
  List<Map<String, dynamic>> tasks = [];

  bool isLoading = true;
  String? errorMessage;

  CalendarFilter selectedFilter = CalendarFilter.all;

  @override
  void initState() {
    super.initState();
    loadCalendarData();
  }

  Future<void> loadCalendarData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final results = await Future.wait([
        ApiService.getMeetings(),
        ApiService.getTasks(),
      ]);

      if (!mounted) return;

      setState(() {
        meetings = results[0]
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        tasks = results[1]
            .map((item) => Map<String, dynamic>.from(item as Map))
            .toList();

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  DateTime? parseDate(dynamic value) {
    if (value == null || value.toString().trim().isEmpty) {
      return null;
    }

    return DateTime.tryParse(value.toString().trim());
  }

  DateTime? meetingDate(Map<String, dynamic> meeting) {
    return parseDate(meeting['meeting_date']);
  }

  DateTime? taskDate(Map<String, dynamic> task) {
    return parseDate(task['due_date']);
  }

  bool isSameDate(DateTime? a, DateTime b) {
    return a != null && DateUtils.isSameDay(a, b);
  }

  String formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  

  String formatTime(dynamic value) {
  if (value == null || value.toString().trim().isEmpty) {
    return 'Time not set';
  }

  final text = value.toString().trim();

  int? hour;
  int? minute;

  // Handle time formatted as HH:mm or HH:mm:ss.
  final match = RegExp(r'^(\d{1,2}):(\d{2})(?::\d{2}(?:\.\d+)?)?$')
      .firstMatch(text);

  if (match != null) {
    hour = int.tryParse(match.group(1)!);
    minute = int.tryParse(match.group(2)!);
  } else {
    // Handle seconds since midnight, for example 64800.
    final seconds = int.tryParse(text);

    if (seconds != null && seconds >= 0 && seconds < 86400) {
      final totalMinutes = seconds ~/ 60;
      hour = totalMinutes ~/ 60;
      minute = totalMinutes % 60;
    } else {
      return text;
    }
  }

  if (hour == null ||
      minute == null ||
      hour < 0 ||
      hour > 23 ||
      minute < 0 ||
      minute > 59) {
    return text;
  }

  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour % 12 == 0 ? 12 : hour % 12;

  return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
}

  bool isCancelled(Map<String, dynamic> meeting) {
    return (meeting['status']?.toString().toLowerCase() ?? '') ==
        'cancelled';
  }

  bool isCompleted(Map<String, dynamic> task) {
    return (task['status']?.toString().toLowerCase() ?? '') ==
        'completed';
  }

  bool isOverdue(Map<String, dynamic> task) {
    final date = taskDate(task);

    if (date == null || isCompleted(task)) {
      return false;
    }

    final today = DateUtils.dateOnly(DateTime.now());

    return DateUtils.dateOnly(date).isBefore(today);
  }

  bool isUrgent(Map<String, dynamic> task) {
    final priority = task['priority']?.toString().toLowerCase() ?? '';

    return priority == 'urgent' || priority == 'high';
  }

  List<Map<String, dynamic>> get meetingsForSelectedDate {
    return meetings.where((meeting) {
      return !isCancelled(meeting) &&
          isSameDate(meetingDate(meeting), selectedDate);
    }).toList()
      ..sort((a, b) {
        return (a['start_time']?.toString() ?? '').compareTo(
          b['start_time']?.toString() ?? '',
        );
      });
  }

  List<Map<String, dynamic>> get tasksForSelectedDate {
    return tasks.where((task) {
      return isSameDate(taskDate(task), selectedDate);
    }).toList()
      ..sort((a, b) {
        final timeA = a['due_time']?.toString() ?? '';
        final timeB = b['due_time']?.toString() ?? '';

        return timeA.compareTo(timeB);
      });
  }

  List<Map<String, dynamic>> get visibleUpcomingTasks {
    final today = DateUtils.dateOnly(DateTime.now());

    return tasks.where((task) {
      final date = taskDate(task);

      return date != null &&
          !isCompleted(task) &&
          !DateUtils.dateOnly(date).isBefore(today);
    }).toList()
      ..sort((a, b) {
        final dateA = taskDate(a)!;
        final dateB = taskDate(b)!;

        final comparison = dateA.compareTo(dateB);

        if (comparison != 0) {
          return comparison;
        }

        return (a['due_time']?.toString() ?? '').compareTo(
          b['due_time']?.toString() ?? '',
        );
      });
  }

  int meetingCountOn(DateTime date) {
    return meetings.where((meeting) {
      return !isCancelled(meeting) &&
          isSameDate(meetingDate(meeting), date);
    }).length;
  }

  int taskCountOn(DateTime date) {
    return tasks.where((task) {
      return isSameDate(taskDate(task), date);
    }).length;
  }

  List<Map<String, dynamic>> get overdueTasks {
    return tasks.where(isOverdue).toList();
  }

  void changeMonth(int difference) {
    setState(() {
      displayedMonth = DateTime(
        displayedMonth.year,
        displayedMonth.month + difference,
      );
    });
  }

  void goToToday() {
    setState(() {
      selectedDate = DateUtils.dateOnly(DateTime.now());

      displayedMonth = DateTime(
        selectedDate.year,
        selectedDate.month,
      );
    });
  }

  List<Map<String, dynamic>> get filteredMeetings {
    if (selectedFilter == CalendarFilter.tasks) {
      return [];
    }

    return meetingsForSelectedDate;
  }

  List<Map<String, dynamic>> get filteredTasks {
    if (selectedFilter == CalendarFilter.meetings) {
      return [];
    }

    return tasksForSelectedDate;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'SmartMeet Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh calendar',
            onPressed: isLoading ? null : loadCalendarData,
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: goToToday,
            child: const Text('Today'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: loadCalendarData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSummaryCards(),
              const SizedBox(height: 20),
              _buildCalendarCard(theme),
              const SizedBox(height: 24),
              _buildAgendaHeader(),
              const SizedBox(height: 12),
              _buildFilters(),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (errorMessage != null)
                _buildError()
              else
                _buildDailyAgenda(),
              const SizedBox(height: 28),
              _buildUpcomingDeadlines(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final today = DateUtils.dateOnly(DateTime.now());

    final todayMeetings = meetingCountOn(today);

    final todayTasks = taskCountOn(today);

    final overdue = overdueTasks.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 500;

        final cards = [
          _summaryCard(
            title: "Today's Meetings",
            count: todayMeetings,
            icon: Icons.video_call_outlined,
            color: Colors.blue,
          ),
          _summaryCard(
            title: "Today's Tasks",
            count: todayTasks,
            icon: Icons.task_alt,
            color: Colors.green,
          ),
          _summaryCard(
            title: 'Overdue Tasks',
            count: overdue,
            icon: Icons.warning_amber_rounded,
            color: Colors.red,
          ),
        ];

        if (compact) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Row(
          children: [
            for (int i = 0; i < cards.length; i++) ...[
              Expanded(child: cards[i]),
              if (i != cards.length - 1)
                const SizedBox(width: 12),
            ],
          ],
        );
      },
    );
  }

  Widget _summaryCard({
    required String title,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    final firstDay = DateTime(
      displayedMonth.year,
      displayedMonth.month,
      1,
    );

    final daysInMonth = DateTime(
      displayedMonth.year,
      displayedMonth.month + 1,
      0,
    ).day;

    final startOffset = firstDay.weekday - 1;

    final totalCells = ((startOffset + daysInMonth + 6) ~/ 7) * 7;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: () => changeMonth(-1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    formatMonth(displayedMonth),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: () => changeMonth(1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((day) {
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: totalCells,
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 5,
                crossAxisSpacing: 4,
                mainAxisExtent: 76,
              ),
              itemBuilder: (context, index) {
                final dayNumber = index - startOffset + 1;

                if (dayNumber < 1 || dayNumber > daysInMonth) {
                  return const SizedBox.shrink();
                }

                final date = DateTime(
                  displayedMonth.year,
                  displayedMonth.month,
                  dayNumber,
                );

                return _buildDayCell(date);
              },
            ),
            const SizedBox(height: 16),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _LegendItem(
                  color: Colors.blue,
                  label: 'Meetings',
                ),
                _LegendItem(
                  color: Colors.green,
                  label: 'Tasks',
                ),
                _LegendItem(
                  color: Colors.orange,
                  label: 'Urgent',
                ),
                _LegendItem(
                  color: Colors.red,
                  label: 'Overdue',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String formatMonth(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildDayCell(DateTime date) {
    final isSelected = DateUtils.isSameDay(date, selectedDate);

    final isToday = DateUtils.isSameDay(date, DateTime.now());

    final meetingCount = meetingCountOn(date);
    final taskCount = taskCountOn(date);

    final hasUrgentTask = tasks.any((task) {
      return isSameDate(taskDate(task), date) &&
          !isCompleted(task) &&
          isUrgent(task);
    });

    final hasOverdueTask = tasks.any((task) {
      return isSameDate(taskDate(task), date) && isOverdue(task);
    });

    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        setState(() {
          selectedDate = date;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
          vertical: 5,
          horizontal: 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.12)
              : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : isToday
                    ? theme.colorScheme.primary.withValues(alpha: 0.5)
                    : Colors.grey.withValues(alpha: 0.18),
            width: isSelected || isToday ? 1.5 : 0.7,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              '${date.day}',
              style: TextStyle(
                fontWeight: isSelected || isToday
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : null,
              ),
            ),
            const SizedBox(height: 5),
            if (meetingCount > 0)
              _eventCountLabel(
                'M $meetingCount',
                Colors.blue,
              ),
            if (taskCount > 0)
              _eventCountLabel(
                'T $taskCount',
                hasOverdueTask
                    ? Colors.red
                    : hasUrgentTask
                        ? Colors.orange
                        : Colors.green,
              ),
          ],
        ),
      ),
    );
  }

  Widget _eventCountLabel(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 1,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Agenda',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          formatDate(selectedDate),
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildFilters() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _filterChip(
          label: 'All Events',
          filter: CalendarFilter.all,
          icon: Icons.event_note,
        ),
        _filterChip(
          label: 'Meetings',
          filter: CalendarFilter.meetings,
          icon: Icons.video_call_outlined,
        ),
        _filterChip(
          label: 'Tasks',
          filter: CalendarFilter.tasks,
          icon: Icons.task_alt,
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required CalendarFilter filter,
    required IconData icon,
  }) {
    return FilterChip(
      selected: selectedFilter == filter,
      avatar: Icon(
        icon,
        size: 17,
        color: filter == CalendarFilter.meetings
            ? Colors.blue
            : filter == CalendarFilter.tasks
                ? Colors.green
                : null,
      ),
      label: Text(label),
      onSelected: (_) {
        setState(() {
          selectedFilter = filter;
        });
      },
    );
  }

  Widget _buildError() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off,
              size: 42,
              color: Colors.red,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load calendar data',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: loadCalendarData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyAgenda() {
    final dayMeetings = filteredMeetings;
    final dayTasks = filteredTasks;

    final hasEvents = dayMeetings.isNotEmpty || dayTasks.isNotEmpty;

    if (!hasEvents) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Center(
            child: Column(
              children: [
                const Icon(
                  Icons.event_available,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Nothing scheduled for this date',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Create a meeting or add a task to get started.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/meetings');
                      },
                      icon: const Icon(Icons.video_call),
                      label: const Text('Meetings'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pushNamed(context, '/tasks');
                      },
                      icon: const Icon(Icons.add_task),
                      label: const Text('Tasks'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    final events = <Map<String, dynamic>>[];

    for (final meeting in dayMeetings) {
      events.add({
        'type': 'meeting',
        'data': meeting,
        'time': meeting['start_time']?.toString() ?? '',
      });
    }

    for (final task in dayTasks) {
      events.add({
        'type': 'task',
        'data': task,
        'time': task['due_time']?.toString() ?? '',
      });
    }

    events.sort((a, b) {
      final timeA = a['time'] as String;
      final timeB = b['time'] as String;

      if (timeA.isEmpty && timeB.isNotEmpty) return 1;
      if (timeB.isEmpty && timeA.isNotEmpty) return -1;

      return timeA.compareTo(timeB);
    });

    return Column(
      children: events.map((event) {
        final data = event['data'] as Map<String, dynamic>;
        final type = event['type'] as String;

        if (type == 'meeting') {
          return _meetingCard(data);
        }

        return _taskCard(data);
      }).toList(),
    );
  }

  Widget _meetingCard(Map<String, dynamic> meeting) {
    final title = meeting['title']?.toString() ?? 'Untitled meeting';

    final startTime = formatTime(meeting['start_time']);
    final endTime = formatTime(meeting['end_time']);

    final platform = meeting['platform']?.toString() ?? '';

    final location = meeting['location']?.toString() ?? '';

    final status = meeting['status']?.toString() ?? 'Scheduled';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showMeetingDetails(meeting),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 88,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.video_call_outlined,
                color: Colors.blue,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text('$startTime - $endTime'),
                    if (platform.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        platform,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        location,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                    const SizedBox(height: 8),
                    _statusBadge(status, Colors.blue),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Untitled task';

    final priority = task['priority']?.toString() ?? 'Medium';

    final status = task['status']?.toString() ?? 'Pending';

    final dueTime = formatTime(task['due_time']);

    final overdue = isOverdue(task);

    final completed = isCompleted(task);

    final color = overdue
        ? Colors.red
        : isUrgent(task)
            ? Colors.orange
            : Colors.green;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTaskDetails(task),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 5,
                height: 90,
                decoration: BoxDecoration(
                  color: completed ? Colors.grey : color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                completed
                    ? Icons.task_alt
                    : Icons.assignment_outlined,
                color: completed ? Colors.grey : color,
                size: 26,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        decoration: completed
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text('Due: $dueTime'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _statusBadge(
                          priority,
                          color,
                        ),
                        _statusBadge(
                          overdue ? 'Overdue' : status,
                          overdue ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showMeetingDetails(Map<String, dynamic> meeting) {
    final title = meeting['title']?.toString() ?? 'Meeting';

    final description =
        meeting['description']?.toString() ?? '';

    final link = meeting['meeting_link']?.toString() ?? '';

    final organizer = meeting['organizer']?.toString() ?? '';

    final participants =
        meeting['participants']?.toString() ?? '';

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine(
                  'Date',
                  meeting['meeting_date']?.toString() ?? '',
                ),
                _detailLine(
                  'Start',
                  formatTime(meeting['start_time']),
                ),
                _detailLine(
                  'End',
                  formatTime(meeting['end_time']),
                ),
                _detailLine(
                  'Platform',
                  meeting['platform']?.toString() ?? '',
                ),
                _detailLine('Organizer', organizer),
                _detailLine('Participants', participants),
                _detailLine('Description', description),
                _detailLine('Meeting link', link),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (link.startsWith('http://') ||
                link.startsWith('https://'))
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Open this meeting using its link in the Meetings screen.',
                      ),
                    ),
                  );
                },
                child: const Text('Got it'),
              ),
          ],
        );
      },
    );
  }

  void _showTaskDetails(Map<String, dynamic> task) {
    final title = task['title']?.toString() ?? 'Task';

    final description = task['description']?.toString() ?? '';

    final priority = task['priority']?.toString() ?? 'Medium';

    final status = task['status']?.toString() ?? 'Pending';

    final taskId = int.tryParse(task['id']?.toString() ?? '');

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _detailLine(
                  'Due date',
                  task['due_date']?.toString() ?? 'Not set',
                ),
                _detailLine(
                  'Due time',
                  formatTime(task['due_time']),
                ),
                _detailLine('Priority', priority),
                _detailLine('Status', status),
                _detailLine('Description', description),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
            if (!isCompleted(task) && taskId != null)
              FilledButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  try {
                    await ApiService.completeTask(taskId);

                    if (!mounted) return;

                    await loadCalendarData();

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Task marked as completed.'),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Unable to complete task: $e'),
                      ),
                    );
                  }
                },
                child: const Text('Complete Task'),
              ),
          ],
        );
      },
    );
  }

  Widget _detailLine(String label, String value) {
    if (value.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 3),
          SelectableText(value),
        ],
      ),
    );
  }

  Widget _buildUpcomingDeadlines() {
    final upcoming = visibleUpcomingTasks.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Deadlines',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No pending deadlines with a due date.',
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...upcoming.map((task) {
            final date = taskDate(task)!;

            final overdue = isOverdue(task);

            final color = overdue
                ? Colors.red
                : isUrgent(task)
                    ? Colors.orange
                    : Colors.green;

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(
                    overdue
                        ? Icons.warning_amber
                        : Icons.event_note,
                    color: color,
                  ),
                ),
                title: Text(
                  task['title']?.toString() ?? 'Untitled task',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${formatDate(date)} â€¢ ${formatTime(task['due_time'])}',
                ),
                trailing: _statusBadge(
                  overdue
                      ? 'Overdue'
                      : task['priority']?.toString() ?? 'Medium',
                  color,
                ),
                onTap: () {
                  setState(() {
                    selectedDate = date;
                    displayedMonth = DateTime(date.year, date.month);
                    selectedFilter = CalendarFilter.tasks;
                  });

                  _showTaskDetails(task);
                },
              ),
            );
          }),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}
